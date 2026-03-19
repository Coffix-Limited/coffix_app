import express, { Response } from "express";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { requirePost } from "../middleware/method";
import { createPaymentSessionBodySchema } from "./schema";

import { WindcaveService } from "./service";
import { logger } from "firebase-functions";
import { WindcaveError } from "../utils/windcave.error";
import FirebaseService from "../firebase/service";
import {
  CoffixCreditService,
  InsufficientCreditError,
} from "../coffixCredit/service";
import { serializeForJson } from "../utils/serialize";

const router = express.Router();

router.post(
  "/session",
  requirePost,
  requiredAuth,
  async (request: AuthenticatedRequest, response: Response) => {
    const firebaseService = new FirebaseService();
    const windcaveService = new WindcaveService();
    const coffixCreditService = new CoffixCreditService();
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
      });

      // handle coffix credit payment
      if (validation.data.paymentMethod === "coffixCredit") {
        await coffixCreditService.deductCredit(customerId, totalAmount);

        const duration = validation.data.duration ?? 0;
        await firebaseService.createTransactionAndMarkOrderPaid({
          customerId,
          orderId,
          amount: totalAmount,
          duration,
          orderNumber: orderData.orderNumber,
        });

        const paidAt = new Date();
        const finalOrderData = {
          ...orderData,
          status: "paid",
          paidAt,
          scheduledAt: new Date(Date.now() + duration * 60_000),
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

      const { paymentSessionUrl, sessionId } =
        await windcaveService.createPaymentSession({
          amount: totalAmount,
          orderId,
          userDoc,
        });

      await firebaseService.createNewTransaction({
        customerId,
        orderId,
        amount: totalAmount,
        sessionId,
      });

      return response.status(200).json({
        success: true,
        data: { order: serializeForJson(orderData), paymentSessionUrl },
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
        return response
          .status(error.status)
          .json({ success: false, message: error.message, data: error.data });
      }
      logger.error("Error creating payment session:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
