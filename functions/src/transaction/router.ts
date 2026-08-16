import express, { Request, Response } from "express";
import { requirePost } from "../middleware/method";
import { EmailService } from "../email/service";
import FirebaseService from "../firebase/service";

import {
  createTransactionSchema,
  invoiceTransactionSchema,
  refundTransactionSchema,
  reprintTransactionSchema,
} from "./schema";
import { logger } from "firebase-functions";
import {
  buildAndSendGiftInvoice,
  buildAndSendOrderInvoice,
  buildAndSendTopupInvoice,
} from "../order/router";
import { ReceiptService } from "../receipt/service";
import { getPaymentMethod } from "../order/service";
import { formatNzTime } from "../utils/nz_time";
import { generateTransactionNumber } from "../utils/generate_order_number";
import { LogService } from "../log/service";

const router = express.Router();
const logService = new LogService();

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
          customerId,
        );
      } else if (type === "refund") {
        const customer = await firebaseService.findUserByCustomerId(customerId);
        if (!customer?.email) {
          return response
            .status(404)
            .json({ success: false, message: "Customer not found" });
        }
        await emailService.sendRefundInvoice({
          to: customer.email,
          userId: customerId,
          transactionNumber,
          originalTransactionNumber:
            (transaction.originalTransactionNumber as string) ?? "",
          amount: (transaction.amount as number) ?? 0,
          storeInvoiceText: transaction.storeInvoiceText as string | undefined,
          isCoffixCredit:
            (transaction.paymentMethod as string) === "coffixCredit",
        });
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

router.post(
  "/reprint",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = reprintTransactionSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const { printerId, transactionNumber } = validation.data;
      const firebaseService = new FirebaseService();
      const receiptService = new ReceiptService();

      const orderDoc =
        await firebaseService.findOrderByTransactionNumber(transactionNumber);
      if (!orderDoc) {
        return response
          .status(404)
          .json({ success: false, message: "Order not found" });
      }

      const [storeDoc, customer] = await Promise.all([
        firebaseService.findStoreByStoreId(orderDoc.storeId),
        firebaseService.findUserByCustomerId(orderDoc.customerId),
      ]);

      const customerName =
        [customer?.firstName, customer?.lastName].filter(Boolean).join(" ") ||
        "Guest";
      const formattedPaymentMethod = getPaymentMethod(
        orderDoc.paymentMethod as string,
        (orderDoc.card as any)?.cardNumber ?? null,
      );
      const createdAt = orderDoc.createdAt?.toDate?.() ?? new Date();
      const scheduledAt = orderDoc.scheduledAt?.toDate?.() ?? createdAt;

      await receiptService.createPrintQueue({
        receiptData: {
          printerId,
          storeName: storeDoc?.name ?? "",
          storeAddress: storeDoc?.address ?? "",
          transactionNumber: orderDoc.transactionNumber ?? "",
          orders: (orderDoc.items ?? [])
            .map((item: any) => {
              const itemModifiers = (item.modifiers ?? [])
                .map((m: any) => m.name)
                .join(", ");
              return `<b>${item.quantity}x ${item.productName}</b> | ${itemModifiers} | <b>$${item.price.toFixed(2)}</b>`;
            })
            .join("\n"),
          total: Number((orderDoc.amount ?? 0).toFixed(2)),
          customer: customerName,
          baristaName: "John Doe",
          duration: 0,
          paymentMethod: formattedPaymentMethod,
          orderTime: formatNzTime(createdAt),
          serviceTime: formatNzTime(scheduledAt),
        },
      });

      return response
        .status(200)
        .json({ success: true, message: "Print queue created" });
    } catch (e: any) {
      logger.error("Failed to create print queue:", e);
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to create print queue",
      });
    }
  },
);

router.post(
  "/refund",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = refundTransactionSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const { transactionNumber } = validation.data;
      const firebaseService = new FirebaseService();
      const emailService = new EmailService();

      const transaction =
        await firebaseService.findTransactionByTransactionNumber(
          transactionNumber,
        );
      if (!transaction) {
        return response
          .status(404)
          .json({ success: false, message: "Transaction not found" });
      }

      if (transaction.type !== "order") {
        return response.status(400).json({
          success: false,
          message: "Only order transactions can be refunded",
        });
      }

      const existingRefund =
        await firebaseService.findRefundByOriginalTransactionNumber(
          transactionNumber,
        );
      if (existingRefund) {
        return response.status(400).json({
          success: false,
          message: "This transaction has already been refunded",
        });
      }

      const customerId = transaction.customerId as string;
      const customer = await firebaseService.findUserByCustomerId(customerId);
      if (!customer?.email) {
        return response
          .status(404)
          .json({ success: false, message: "Customer not found" });
      }

      const amount = (transaction.amount as number) ?? 0;
      const originalTransactionNumber =
        (transaction.transactionNumber as string) ?? transactionNumber;
      const refundTransactionNumber = await generateTransactionNumber();

      const refundTransactionId = await firebaseService.createRefundTransaction(
        {
          customerId,
          originalTransactionNumber,
          amount,
          storeInvoiceText: transaction.storeInvoiceText as string | undefined,
          storeId: transaction.storeId as string | undefined,
          transactionNumber: refundTransactionNumber,
        },
      );

      await emailService.sendRefundInvoice({
        to: customer.email,
        userId: customerId,
        transactionNumber: refundTransactionNumber,
        originalTransactionNumber,
        amount,
        storeInvoiceText: transaction.storeInvoiceText as string | undefined,
        isCoffixCredit:
          (transaction.paymentMethod as string) === "coffixCredit",
      });

      await logService.log({
        customerId,
        category: "refund",
        severityLevel: 3,
        action: "Refund processed",
        notes: `Refunded ${amount} for transaction ${transactionNumber}`,
      });

      return response.status(200).json({
        success: true,
        message: "Refund processed",
        refundTransactionId,
      });
    } catch (e: any) {
      logger.error("Failed to process refund:", e);
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to process refund",
      });
    }
  },
);

router.post(
  "/create",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = createTransactionSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const { userId, transactionType, paymentMethod, amount, notes } =
        validation.data;
      const firebaseService = new FirebaseService();

      const customer = await firebaseService.findUserByCustomerId(userId);
      if (!customer) {
        return response
          .status(404)
          .json({ success: false, message: "Customer not found" });
      }

      const transactionNumber = await generateTransactionNumber();

      const transactionId = await firebaseService.createManualTransaction({
        customerId: userId,
        transactionType,
        paymentMethod,
        amount,
        transactionNumber,
        notes,
      });

      await logService.log({
        customerId: userId,
        category: "transaction",
        severityLevel: 5,
        action: "Manual transaction created",
        page: "Transaction",
        notes: `${transactionType}/${paymentMethod} ${amount}`,
      });

      return response.status(200).json({
        success: true,
        message: "Transaction created",
        transactionId,
        transactionNumber,
      });
    } catch (e: any) {
      logger.error("Failed to create transaction:", e);
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to create transaction",
      });
    }
  },
);

export default router;
