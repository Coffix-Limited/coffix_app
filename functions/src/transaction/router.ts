import express, { Request, Response } from "express";
import { requirePost } from "../middleware/method";
import { EmailService } from "../email/service";
import FirebaseService from "../firebase/service";

import { invoiceTransactionSchema } from "./schema";
import { logger } from "firebase-functions";
import {
  buildAndSendGiftInvoice,
  buildAndSendOrderInvoice,
  buildAndSendTopupInvoice,
} from "../order/router";

const router = express.Router();

router.post(
  "/invoice",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = invoiceTransactionSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const { transactionId } = validation.data;
      const firebaseService = new FirebaseService();
      const emailService = new EmailService();

      const transaction =
        await firebaseService.findTransactionById(transactionId);
      if (!transaction) {
        return response
          .status(404)
          .json({ success: false, message: "Transaction not found" });
      }

      const customerId = transaction.customerId as string;
      const transactionNumber = transaction.transactionNumber as string;
      const type = transaction.type as string | undefined;

      if (type === "topup") {
        await buildAndSendTopupInvoice(
          firebaseService,
          emailService,
          customerId,
          transactionNumber,
        );
      } else if (type === "gift") {
        await buildAndSendGiftInvoice(
          firebaseService,
          emailService,
          transactionNumber,
        );
      } else {
        await buildAndSendOrderInvoice(
          firebaseService,
          emailService,
          customerId,
          transactionNumber,
        );
      }

      return response
        .status(200)
        .json({ success: true, message: "Invoice sent" });
    } catch (e: any) {
      logger.error("Failed to send invoice:", e);
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to send invoice",
      });
    }
  },
);

export default router;
