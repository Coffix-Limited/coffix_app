import express, { Response } from "express";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { requirePost } from "../middleware/method";
import { invoiceSchema } from "./schema";
import { invoiceEmailTemplate } from "../utils/templates/invoice_email_template";
import { topupEmailTemplate } from "../utils/templates/topup_email_template";
import { EmailService } from "../email/service";
import { wrapInEmailShell } from "../utils/emailShell";
import { formatNzTime } from "../utils/nz_time";
import * as admin from "firebase-admin";
import FirebaseService from "../firebase/service";
import { getPaymentMethod } from "./service";

const router = express.Router();

function buildItemsHtml(items: Array<Record<string, any>>): string {
  return items
    .map((item) => {
      const modifiers = (item.modifiers ?? []) as Array<{
        modifierId: string;
        name: string;
      }>;
      const modifierHtml =
        modifiers.length > 0
          ? `<div class="item-modifiers">${modifiers.map((m) => m.name).join(", ")}</div>`
          : "";
      return `<div class="item-row">
            <div class="item-left">
              <div class="item-name">${item.productName} (${item.quantity}x)</div>
              ${modifierHtml}
            </div>
            <div class="item-right">$${((item.price as number) * (item.quantity as number)).toFixed(2)}</div>
          </div>`;
    })
    .join("\n");
}

function toDate(value: unknown): Date {
  if (value instanceof Date) return value;
  if (
    value !== null &&
    typeof value === "object" &&
    typeof (value as admin.firestore.Timestamp).toDate === "function"
  ) {
    return (value as admin.firestore.Timestamp).toDate();
  }
  return new Date(value as string);
}

const r = (s: string) => () => s;

export async function buildAndSendOrderInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  customerId: string,
  transactionNumber: string,
): Promise<void> {
  const order =
    await firebaseService.findOrderByTransactionNumber(transactionNumber);
  if (!order)
    throw new Error(`Order not found for transaction: ${transactionNumber}`);

  const [transaction, customer] = await Promise.all([
    firebaseService.findTransactionByTransactionNumber(transactionNumber),
    firebaseService.findUserByCustomerId(customerId),
  ]);

  const createdAt = formatNzTime(toDate(order.createdAt));
  const itemsHtml = buildItemsHtml(
    (order.items ?? []) as Array<Record<string, any>>,
  );
  const serviceTimeLine = order.scheduledAt
    ? `<p class="meta-line">Service Time: ${formatNzTime(toDate(order.scheduledAt))} ${order.storeName}</p>`
    : `<p class="meta-line">Service Time: ${createdAt} ${order.storeName}</p>`;

  const gst = (transaction?.gst as number) ?? 15;
  const gstAmount = (transaction?.gstAmount as number) ?? 0;

  const isCoffixCredit = (order.paymentMethod as string) === "coffixCredit";
  const invoiceLabel = isCoffixCredit ? "Coffix Credit Claim" : "Tax Invoice";
  const displayGstNumberLine = isCoffixCredit
    ? ""
    : `<p class="store-gst">GST: ${(transaction?.gstNumber as string) ?? ""}</p>`;
  const displayGstLineSection = isCoffixCredit
    ? ""
    : `<span class="gst-text">${gst}% GST Included in the total: $${gstAmount.toFixed(2)}</span>`;

  const paymentMethod = getPaymentMethod(
    order.paymentMethod as string,
    (transaction?.card as any)?.cardNumber ?? null,
  );
  const invoice = invoiceEmailTemplate
    .replace("{{invoiceText}}", r((order.storeInvoiceText as string) ?? ""))
    .replace("{{gstNumberLine}}", r(displayGstNumberLine))
    .replace("{{invoiceLabel}}", r(invoiceLabel))
    .replace("{{transactionNumber}}", r(order.transactionNumber as string))
    .replace("{{items}}", r(itemsHtml))
    .replace("{{total}}", r(`$${(order.amount as number).toFixed(2)}`))
    .replace("{{gstLineSection}}", r(displayGstLineSection))
    .replace("{{paymentMethod}}", r(paymentMethod))
    .replace("{{createdAt}}", r(createdAt))
    .replace("{{serviceTimeLine}}", r(serviceTimeLine));

  await emailService.sendInvoice({
    to: customer?.email as string,
    userId: order.customerId as string,
    invoiceHtml: invoice,
    storeName: order.storeName as string,
    transactionNumber: order.transactionNumber as string,
  });
}

async function sendOrderInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  customerId: string,
  transactionNumber: string,
  response: Response,
) {
  const order =
    await firebaseService.findOrderByTransactionNumber(transactionNumber);
  if (!order) {
    return response
      .status(404)
      .json({ success: false, message: "Order not found" });
  }
  await buildAndSendOrderInvoice(
    firebaseService,
    emailService,
    customerId,
    transactionNumber,
  );
  return response.status(200).json({ success: true, message: "Invoice sent" });
}

export async function buildAndSendGiftInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  transactionNumber: string,
  customerId: string,
): Promise<void> {
  const transaction =
    await firebaseService.findTransactionByTransactionNumber(transactionNumber);
  if (!transaction)
    throw new Error(`Transaction not found: ${transactionNumber}`);

  const sender = await firebaseService.findUserByCustomerId(customerId);

  await emailService.sendGift({
    to: sender?.email as string,
    userId: customerId,
    amount: transaction.amount as number,
    transactionNumber: transaction.transactionNumber as string,
    recipientFullName: transaction.recipientFullName as string,
    storeInvoiceText: transaction.storeInvoiceText as string | undefined,
  });
}

async function sendGiftInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  transactionNumber: string,
  customerId: string,
  response: Response,
) {
  const transaction =
    await firebaseService.findTransactionByTransactionNumber(transactionNumber);
  if (!transaction) {
    return response
      .status(404)
      .json({ success: false, message: "Transaction not found" });
  }
  await buildAndSendGiftInvoice(
    firebaseService,
    emailService,
    transactionNumber,
    customerId,
  );
  return response.status(200).json({ success: true, message: "Invoice sent" });
}

export async function buildAndSendTopupInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  customerId: string,
  transactionNumber: string,
): Promise<void> {
  const [transaction, customer] = await Promise.all([
    firebaseService.findTransactionByTransactionNumber(transactionNumber),
    firebaseService.findUserByCustomerId(customerId),
  ]);
  if (!transaction)
    throw new Error(`Transaction not found: ${transactionNumber}`);
  if (!customer?.email)
    throw new Error(`Customer email not found for: ${customerId}`);

  const createdAt = formatNzTime(toDate(transaction.createdAt));
  const amount = transaction.amount as number;
  const gst = (transaction.gst as number) ?? 0;
  const gstNumber = (transaction.gstNumber as string) ?? "";
  const gstAmount = (transaction.gstAmount as number) ?? 0;
  const gstLine = `${gst}% GST Included in the total: $${gstAmount.toFixed(2)}`;
  const cardNumber = (transaction.card as any)?.cardNumber ?? null;
  const paymentMethod = cardNumber
    ? `Credit Card ${cardNumber.slice(-4)}`
    : "Credit Card";
  const totalAmountWithBonus = (transaction.totalAmount as number) ?? amount;
  const bonusAmount = totalAmountWithBonus - amount;

  const invoice = topupEmailTemplate
    .replace("{{invoiceText}}", r(""))
    .replace("{{gst}}", r(gstNumber))
    .replace("{{transactionNumber}}", r(transactionNumber))
    .replace("{{amount}}", r(`$${amount.toFixed(2)}`))
    .replace("{{total}}", r(`$${amount.toFixed(2)}`))
    .replace("{{gstLine}}", r(gstLine))
    .replace("{{paymentMethod}}", r(paymentMethod))
    .replace("{{createdAt}}", r(createdAt))
    .replace("{{bonusAmount}}", r(`$${bonusAmount.toFixed(2)}`))
    .replace("{{totalCoffixCredit}}", r(`$${totalAmountWithBonus.toFixed(2)}`));

  await emailService.sendInvoice({
    to: customer.email,
    userId: customerId,
    invoiceHtml: invoice,
    storeName: "Coffix",
    transactionNumber,
  });
}

async function sendTopupInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  customerId: string,
  transactionNumber: string,
  response: Response,
) {
  const transaction =
    await firebaseService.findTransactionByTransactionNumber(transactionNumber);
  if (!transaction) {
    return response
      .status(404)
      .json({ success: false, message: "Transaction not found" });
  }
  await buildAndSendTopupInvoice(
    firebaseService,
    emailService,
    customerId,
    transactionNumber,
  );
  return response.status(200).json({ success: true, message: "Invoice sent" });
}

async function sendRefundInvoice(
  firebaseService: FirebaseService,
  emailService: EmailService,
  customerId: string,
  transactionNumber: string,
  response: Response,
) {
  const transaction =
    await firebaseService.findTransactionByTransactionNumber(transactionNumber);
  if (!transaction) {
    return response
      .status(404)
      .json({ success: false, message: "Transaction not found" });
  }

  const customer = await firebaseService.findUserByCustomerId(customerId);
  if (!customer?.email) {
    return response
      .status(404)
      .json({ success: false, message: "Customer not found" });
  }

  await emailService.sendRefundInvoice({
    to: customer.email,
    userId: customerId,
    transactionNumber: transaction.transactionNumber as string,
    originalTransactionNumber: transaction.originalTransactionNumber as string,
    amount: transaction.amount as number,
    storeInvoiceText: transaction.storeInvoiceText as string | undefined,
    gst: transaction.gst as number | undefined,
    gstAmount: transaction.gstAmount as number | undefined,
    gstNumber: transaction.gstNumber as string | undefined,
    isCoffixCredit: true,
  });

  return response.status(200).json({ success: true, message: "Invoice sent" });
}

router.post(
  "/invoice",
  requirePost,
  requiredAuth,
  async (request: AuthenticatedRequest, response) => {
    const validation = invoiceSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      const customerId = request.user?.uid;
      if (!customerId) {
        return response
          .status(401)
          .json({ success: false, message: "Unauthorized" });
      }

      const firebaseService = new FirebaseService();
      const emailService = new EmailService();
      const { transactionNumber } = validation.data;

      const transaction =
        await firebaseService.findTransactionByTransactionNumber(
          transactionNumber,
        );
      const type = transaction?.type as string | undefined;

      if (type === "gift") {
        return sendGiftInvoice(
          firebaseService,
          emailService,
          transactionNumber,
          customerId,
          response,
        );
      }

      if (type === "topup") {
        return sendTopupInvoice(
          firebaseService,
          emailService,
          customerId,
          transactionNumber,
          response,
        );
      }

      if (type === "refund") {
        return sendRefundInvoice(
          firebaseService,
          emailService,
          customerId,
          transactionNumber,
          response,
        );
      }

      return sendOrderInvoice(
        firebaseService,
        emailService,
        customerId,
        transactionNumber,
        response,
      );
    } catch (e: any) {
      return response.status(500).json({
        success: false,
        message: e.message ?? "Failed to send invoice",
      });
    }
  },
);

export default router;
