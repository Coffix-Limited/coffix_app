import express, { Response } from "express";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { requirePost } from "../middleware/method";
import { createPaymentSessionBodySchema } from "./schema";

import { WindcaveService } from "./service";
import { logger } from "firebase-functions";
import { WindcaveError } from "../utils/windcave.error";
import { InsufficientCreditError } from "../coffixCredit/service";
import { serializeForJson } from "../utils/serialize";
import { ReceiptService } from "../receipt/service";
import { NotificationService } from "../notification/service";
import { getOrderMerchantReference } from "../coffixCredit/utils";
import FirebaseService from "../firebase/service";
import { generateTransactionNumber } from "../utils/generate_order_number";
import { paymentLimiter } from "../middleware/rateLimiter";
import { formatNzTime } from "../utils/nz_time";
import { buildAndSendOrderInvoice } from "../order/router";
import { EmailService } from "../email/service";

const router = express.Router();

router.post(
  "/session",
  requirePost,
  paymentLimiter,
  requiredAuth,
  async (request: AuthenticatedRequest, response: Response) => {
    const firebaseService = new FirebaseService();
    const windcaveService = new WindcaveService();
    const receiptService = new ReceiptService();
    const notificationService = new NotificationService();
    const customerId = request.user?.uid;

    if (!customerId) {
      return response
        .status(401)
        .json({ success: false, message: "Unauthorized" });
    }

    try {
      const validation = createPaymentSessionBodySchema.safeParse(request.body);
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        return response.status(400).json({ success: false, errors });
      }

      const userDoc = await firebaseService.findUserByCustomerId(customerId);
      if (!userDoc) {
        return response
          .status(401)
          .json({ success: false, message: "Unauthorized" });
      }

      const { total: totalAmount, enrichedItems } =
        await windcaveService.computeOrderTotal({
          items: validation.data.items,
        });

      const storeDoc = await firebaseService.findStoreByStoreId(
        validation.data.storeId,
      );
      if (!storeDoc) {
        return response
          .status(400)
          .json({ success: false, message: "Store not found" });
      }

      const transactionNumber = await generateTransactionNumber();

      // create order
      const { orderId, orderData } = await firebaseService.createNewOrder({
        amount: totalAmount,
        customerId,
        storeId: validation.data.storeId,
        storeName: storeDoc.name,
        storeAddress: storeDoc.address,
        items: enrichedItems,
        duration: validation.data.duration,
        paymentMethod: validation.data.paymentMethod,
        transactionNumber,
      });

      const customerName = `${userDoc.firstName} ${userDoc.lastName}`;

      // handle coffix credit payment
      // if the payment user is using [coffixCredit] then we need to deduct the credit from the user
      if (validation.data.paymentMethod === "coffixCredit") {
        const duration = validation.data.duration ?? 0;

        // Single atomic transaction: deduct credit + create transaction doc + mark order paid
        const { paidAt, scheduledAt } =
          await firebaseService.deductCouponsThenCreditAndMarkOrderPaid({
            customerId,
            orderId,
            amount: totalAmount,
            duration,
            orderNumber: orderData.orderNumber,
            transactionNumber,
          });

        // Non-critical path: don't block response
        void receiptService
          .createPrintQueue({
            receiptData: {
              printerId: storeDoc.printerId,
              storeName: storeDoc.name,
              storeAddress: storeDoc.address,
              transactionNumber: orderData.transactionNumber,
              orders: (orderData.items ?? [])
                .map((item: any) => {
                  const itemModifiers = (item.modifiers ?? [])
                    .map((m: any) => m.modifierId)
                    .join(", ");
                  return `${item.quantity}x ${item.productName} | ${itemModifiers} | $${item.price.toFixed(2)}`;
                })
                .join("\n"),
              total: totalAmount,
              customer: customerName,
              baristaName: "John Doe",
              duration,
              paymentMethod: "Coffix Credit",
              orderTime: formatNzTime(orderData.createdAt),
              serviceTime: formatNzTime(scheduledAt),
            },
          })
          .catch((error) => {
            logger.error("Failed to enqueue receipt print", {
              orderId,
              customerId,
              error,
            });
          });

        notificationService
          .sendNotification({
            customerId,
            title: "Order Payment Successful",
            message: `A payment for order #${orderData?.transactionNumber} has been made from Coffix Credit`,
          })
          .catch((error) => {
            logger.error("Failed to send notification", { customerId, error });
          });

        firebaseService
          .findUserByCustomerId(customerId)
          .then((customer) => {
            if (!customer?.allowWinACoffee) return;
            return buildAndSendOrderInvoice(
              firebaseService,
              new EmailService(),
              customerId,
              orderData.transactionNumber as string,
            );
          })
          .catch((err) => logger.error("Invoice email failed:", err));

        const finalOrderData = {
          ...orderData,
          status: "paid",
          paidAt,
          scheduledAt,
        };

        return response.status(200).json({
          success: true,
          data: {
            order: serializeForJson(finalOrderData),
            paymentSessionUrl: null,
          },
        });
      }

      // handle card payment
      logger.info("Total amount:", totalAmount);

      const merchantReference = getOrderMerchantReference(customerId, orderId);

      const { paymentSessionUrl, sessionId } =
        await windcaveService.createPaymentSession({
          amount: totalAmount,
          merchantReference,
          userDoc,
        });

      await firebaseService.createNewTransaction({
        customerId,
        orderId,
        amount: totalAmount,
        sessionId,
        transactionNumber,
        type: "order",
        gstNumber: orderData.storeGst,
      });

      return response.status(200).json({
        success: true,
        data: {
          order: serializeForJson(orderData),
          paymentSessionUrl,
          baseUrl: process.env.BASE_URL,
        },
      });
    } catch (error) {
      if (error instanceof InsufficientCreditError) {
        return response.status(400).json({
          success: false,
          message: error.message,
          data: {
            creditAvailable: error.creditAvailable,
            required: error.required,
          },
        });
      }
      if (error instanceof WindcaveError) {
        return response.status(error.status).json({
          success: false,
          message: error.message,
          data: error.data,
        });
      }
      logger.error("Error creating payment session:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
