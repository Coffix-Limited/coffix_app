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
    const customerEmail = request.user?.email;

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

      const totalAmount = await windcaveService.computeOrderTotal({
        items: validation.data.items,
      });

      if (validation.data.paymentMethod === "coffixCredit") {
        const creditAvailable =
          await coffixCreditService.getCreditAvailable(customerId);
        if (creditAvailable < totalAmount) {
          return response.status(400).json({
            success: false,
            message: "Insufficient credit",
            data: { creditAvailable, required: totalAmount },
          });
        }

        const orderId = await firebaseService.createNewOrder({
          amount: totalAmount,
          customerId,
          storeId: validation.data.storeId,
          items: validation.data.items,
          duration: validation.data.duration,
          paymentMethod: validation.data.paymentMethod,
        });

        await coffixCreditService.deductCredit(customerId, totalAmount);

        const transactionId = await firebaseService.createNewTransaction({
          customerId,
          orderId,
          amount: totalAmount,
          sessionId: "coffixCredit",
        });
        await firebaseService.updateTransaction(transactionId, {
          status: "approved",
          paymentTime: new Date(),
          paymentMethod: "coffixCredit",
        });

        const duration = validation.data.duration ?? 0;
        await firebaseService.updateOrder(orderId, {
          status: "paid",
          paidAt: new Date(),
          scheduledAt: new Date(Date.now() + duration * 60_000),
        });

        const orderData = await firebaseService.findOrderByOrderId(orderId);
        return response.status(200).json({
          success: true,
          data: { order: serializeForJson(orderData) },
        });
      }

      const orderId = await firebaseService.createNewOrder({
        amount: totalAmount,
        customerId,
        storeId: validation.data.storeId,
        items: validation.data.items,
        duration: validation.data.duration,
        paymentMethod: validation.data.paymentMethod,
      });

      logger.info("Total amount:", totalAmount);

      const { paymentSessionUrl, sessionId } =
        await windcaveService.createPaymentSession({
          amount: totalAmount,
          orderId,
          customerEmail: customerEmail ?? "",
        });

      await firebaseService.createNewTransaction({
        customerId,
        orderId,
        amount: totalAmount,
        sessionId,
      });

      return response
        .status(200)
        .json({ success: true, data: { paymentSessionUrl } });
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
