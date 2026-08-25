import { firestore } from "../config/firebaseAdmin";
import { RESEND_BCC_EMAIL, RESEND_FROM_EMAIL } from "../constant/constant";
import { renderTemplate } from "../utils/renderEmailTemplate";
import { wrapInEmailShell } from "../utils/emailShell";
import { logger } from "firebase-functions";
import {
  GiftFromEmailParams,
  GiftToEmailParams,
  SendBuiltInvoiceParams,
  SendCouponEmailSchema,
  SendEmailParams,
  SendOTPSchema,
  SendReferralEmailSchema,
  SendRefundEmailParams,
} from "./schema";
import { AppUser } from "../user/interface";
import { EmailTemplate } from "./interface";
import { formatNzDate, formatNzTime, nowNZ } from "../utils/nz_time";
import { invoiceEmailTemplate } from "../utils/templates/invoice_email_template";
import { giftEmailTemplate } from "../utils/templates/gift_email_template";
import * as admin from "firebase-admin";

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

function buildUserVariables(
  user: AppUser | null,
  fallbackEmail?: string,
): Record<string, string | number | boolean> {
  if (!user) return fallbackEmail ? { email: fallbackEmail } : {};
  return {
    first_name: user.firstName ?? "",
    last_name: user.lastName ?? "",
    nick_name: user.nickName ?? "",
    email: user.email ?? "",
    mobile: user.mobile ?? "",
    birthday: user.birthday ? formatNzDate(toDate(user.birthday)) : "",
    suburb: user.suburb ?? "",
    city: user.city ?? "",
    preferred_store_id: user.preferredStoreId ?? "",
    credit_available: user.creditAvailable ?? 0,
    created_at: user.createdAt ? formatNzDate(toDate(user.createdAt)) : "",
    email_verified: user.emailVerified ?? false,
    get_purchase_info_by_mail: user.getPurchaseInfoByMail ?? false,
    get_promotions: user.getPromotions ?? false,
    allow_win_a_coffee: user.allowWinACoffee ?? false,
    last_login: user.lastLogin ? formatNzDate(toDate(user.lastLogin)) : "",
    disabled: user.disabled ?? false,
    qr_id: user.qrId ?? "",
    fcm_token: user.fcmToken ?? "",
    doc_id: user.docId ?? "",
  };
}

export class EmailService {
  private async resendSend({
    to,
    subject,
    html,
  }: {
    to: string;
    subject: string;
    html: string;
  }): Promise<void> {
    const RESEND_API_KEY = process.env.RESEND_API_KEY;
    if (!RESEND_API_KEY) throw new Error("RESEND_API_KEY not configured");

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: RESEND_FROM_EMAIL,
        to: [to],
        bcc: [RESEND_BCC_EMAIL],
        subject,
        html,
      }),
    });

    if (!res.ok) {
      const err = await res.json();
      logger.error("Resend API error", {
        resendStatus: res.status,
        resendError: err,
      });
      throw new Error(`Resend ${res.status}: ${JSON.stringify(err)}`);
    }
  }

  // send email to a single recipient
  async send(params: SendEmailParams): Promise<void> {
    let subject: string;
    let html: string;

    const [templateSnap, userSnap] = await Promise.all([
      firestore.collection("emails").doc(params.documentId).get(),
      params.userId
        ? firestore.collection("customers").doc(params.userId).get()
        : Promise.resolve(null),
    ]);

    const user = userSnap?.exists ? (userSnap.data() as AppUser) : null;

    const userVariables = buildUserVariables(user, params.email);
    if (user?.getPurchaseInfoByMail === false && !params.forceSend) {
      logger.warn(
        `User ${params.userId} has purchase info mail disabled, skipping email send`,
      );
      return;
    }
    const now = nowNZ();
    const templateData = templateSnap.data() as EmailTemplate;
    const variables = {
      ...userVariables,
      ...params.variables,
      date: now,
    };

    if (params.htmlContent) {
      subject = renderTemplate(
        templateData.subject ?? params.subject ?? "",
        variables,
      );
      html = wrapInEmailShell(params.htmlContent);
    } else {
      subject = renderTemplate(
        templateData.subject ?? params.subject ?? "",
        variables,
      );
      html = wrapInEmailShell(
        renderTemplate(templateData.content ?? "", variables),
      );
    }

    await this.resendSend({ to: params.email, subject, html });
  }

  // gift notification email for the sender (the user who shared credit)
  async sendGiftToSender(params: GiftFromEmailParams): Promise<void> {
    const giftLabel = `Gift to ${params.recipientFullName ?? ""}`;

    const invoiceHtml = renderTemplate(giftEmailTemplate, {
      transaction_number: params.transactionNumber ?? "",
      gift_label: giftLabel,
      gift_amount: params.amount.toFixed(2),
      date: nowNZ(),
      invoice_text: params.storeInvoiceText ?? "",
    });
    await this.send({
      email: params.to,
      documentId: "GIFT_FROM",
      userId: params.userId,
      variables: {
        gift_amount: params.amount.toFixed(2),
        transaction_number: params.transactionNumber ?? "",
        gift_label: giftLabel,
        invoice: invoiceHtml,
        name: params.recipientFullName ?? "",
      },
    });
  }

  // gift notification email for the recipient (the user who received credit)
  async sendGiftToRecipient(params: GiftToEmailParams): Promise<void> {
    const giftLabel = `${params.senderFullName ?? ""} gave you a gift`;

    const invoiceHtml = renderTemplate(giftEmailTemplate, {
      transaction_number: params.transactionNumber ?? "",
      gift_label: giftLabel,
      gift_amount: params.amount.toFixed(2),
      date: nowNZ(),
      invoice_text: params.storeInvoiceText ?? "",
    });
    await this.send({
      email: params.to,
      documentId: "GIFT_TO",
      userId: params.userId,
      variables: {
        gift_amount: params.amount.toFixed(2),
        transaction_number: params.transactionNumber ?? "",
        gift_label: giftLabel,
        invoice: invoiceHtml,
        name: params.senderFullName ?? "",
      },
    });
  }

  // top-up paid by credit card
  async sendTopUpInvoice(params: SendBuiltInvoiceParams): Promise<void> {
    await this.send({
      email: params.to,
      subject: "Your Coffix top-up receipt",
      documentId: "TOP_UP",
      userId: params.userId,
      variables: {
        store_name: params.storeName,
        transaction_number: params.transactionNumber,
      },
      htmlContent: params.invoiceHtml,
    });
  }

  // order paid with Coffix Credit
  async sendOrderCoffixCreditInvoice(
    params: SendBuiltInvoiceParams,
  ): Promise<void> {
    await this.send({
      email: params.to,
      subject: "Your Coffix Credit claim",
      documentId: "ORDER_COFFIX_CREDIT",
      userId: params.userId,
      variables: {
        store_name: params.storeName,
        transaction_number: params.transactionNumber,
      },
      htmlContent: params.invoiceHtml,
    });
  }

  // order paid with credit card
  async sendOrderCreditCardInvoice(
    params: SendBuiltInvoiceParams,
  ): Promise<void> {
    await this.send({
      email: params.to,
      subject: "Your Coffix tax invoice",
      documentId: "ORDER_CREDIT_CARD",
      userId: params.userId,
      variables: {
        store_name: params.storeName,
        transaction_number: params.transactionNumber,
      },
      htmlContent: params.invoiceHtml,
    });
  }

  // top-up payment failed / declined
  async sendTopUpFailed(params: SendBuiltInvoiceParams): Promise<void> {
    await this.send({
      email: params.to,
      subject: "Your Coffix top-up could not be completed",
      documentId: "TOP_UP_FAILED",
      userId: params.userId,
      variables: {
        store_name: params.storeName,
        transaction_number: params.transactionNumber,
      },
      htmlContent: params.invoiceHtml,
    });
  }

  async sendRefundInvoice(params: SendRefundEmailParams): Promise<void> {
    const {
      to,
      userId,
      transactionNumber,
      originalTransactionNumber,
      amount,
      storeInvoiceText,
      isCoffixCredit,
      gst,
      gstAmount,
      gstNumber,
    } = params;

    const itemsHtml = `<div class="item-row">
            <div class="item-left">
              <div class="item-name">Refund for order #${originalTransactionNumber}</div>
            </div>
            <div class="item-right">$${amount.toFixed(2)}</div>
          </div>`;

    const gstNumberLine = isCoffixCredit
      ? ""
      : `<p class="store-gst">GST: ${gstNumber ?? ""}</p>`;
    const gstLineSection = isCoffixCredit
      ? ""
      : `<span class="gst-text">${gst ?? 15}% GST Included in the total: $${(gstAmount ?? 0).toFixed(2)}</span>`;

    const r = (s: string) => () => s;
    const invoice = invoiceEmailTemplate
      .replace("{{invoiceText}}", r(storeInvoiceText ?? ""))
      .replace("{{invoiceLabel}}", r("Refund"))
      .replace("{{gstNumberLine}}", r(gstNumberLine))
      .replace("{{transactionNumber}}", r(transactionNumber))
      .replace("{{items}}", r(itemsHtml))
      .replace("{{total}}", r(`$${amount.toFixed(2)}`))
      .replace("{{gstLineSection}}", r(gstLineSection))
      .replace("{{paymentMethod}}", r("Coffix Credit"))
      .replace("{{createdAt}}", r(nowNZ()))
      .replace("{{serviceTimeLine}}", r(""));

    await this.send({
      email: to,
      documentId: "REFUND",
      userId,
      variables: {
        transaction_number: transactionNumber,
      },
      htmlContent: invoice,
    });
  }

  async sendOTP(params: SendOTPSchema): Promise<void> {
    await this.send({
      email: params.to,
      subject: "Your OTP code for Coffix",
      documentId: "OTP",
      userId: params.userId,
      variables: {
        otp_code: params.otp,
      },
      forceSend: true,
    });
  }

  async sendReferralEmail(params: SendReferralEmailSchema): Promise<void> {
    logger.info(`Sending referral email to ${params.to}`);
    await this.send({
      email: params.to,
      subject: "You received a referral code from a friend!",
      documentId: "REFERRAL",
      userId: params.userId,
      variables: {
        referee_name: params.referee_name,
      },
      forceSend: true,
    });
  }

  async sendCouponEmail(params: SendCouponEmailSchema): Promise<void> {
    logger.info(`Sending coupon email to ${params.to}`);
    await this.send({
      email: params.to,
      subject: "You've received a Coffix coupon!",
      documentId: "COUPON",
      variables: {
        amount: params.amount.toFixed(2),
        expiry_date: formatNzDate(params.expiryDate),
      },
      forceSend: true,
    });
  }

  async sendCreditTransactions(customerId: string): Promise<void> {
    logger.info(`Sending credit transactions to customer: ${customerId}`);
    const customerSnap = await firestore
      .collection("customers")
      .doc(customerId)
      .get();
    if (!customerSnap.exists) throw new Error("Customer not found");

    const customer = customerSnap.data()!;
    const customerEmail = customer.email as string;
    const customerName =
      [customer.firstName, customer.lastName].filter(Boolean).join(" ") ||
      "Customer";

    const snap = await firestore
      .collection("transactions")
      .where("customerId", "==", customerId)
      .orderBy("createdAt", "asc")
      .get();

    const transactions = snap.docs
      .map((d) => d.data())
      .filter((tx) => {
        const type = (tx.type as string | undefined) ?? "";
        const status = (tx.status as string | undefined) ?? "";
        const paymentMethod = (tx.paymentMethod as string | undefined) ?? "";
        if (type === "topup") return status === "approved";
        if (type === "gift" && paymentMethod === "coffixCredit")
          return (
            status === "sent" || status === "claimed" || status === "completed"
          );
        if (type === "order" && paymentMethod === "coffixCredit")
          return (
            status === "approved" || status === "paid" || status === "completed"
          );
        if (type === "refund") return status === "approved";
        return false;
      });

    let runningBalance = 0;
    const rows = transactions.map((tx) => {
      const type = (tx.type as string | undefined) ?? "order";
      const status = (tx.status as string | undefined) ?? "";
      const amount = (tx.amount as number | undefined) ?? 0;
      const totalAmount = (tx.totalAmount as number | undefined) ?? amount;
      const isCredit =
        (type === "topup" && status === "approved") ||
        (type === "gift" && status === "claimed") ||
        (type === "refund" && status === "approved");
      if (isCredit) {
        runningBalance += totalAmount;
      } else {
        runningBalance -= amount;
      }
      let transactionLabel: string;
      if (type === "gift") {
        const isReceiving = status === "claimed";
        const counterparty = isReceiving
          ? ((tx.senderFullName as string | undefined) ?? "Someone")
          : ((tx.recipientFullName as string | undefined) ?? "Someone");
        transactionLabel = `#${tx.transactionNumber ?? ""} ${isReceiving ? "Gift from" : "Gift to"} ${counterparty}`;
      } else {
        transactionLabel = `#${tx.transactionNumber ?? ""} ${type.charAt(0).toUpperCase() + type.slice(1)}`;
      }

      return {
        time: formatNzTime(toDate(tx.createdAt)),
        transaction: transactionLabel,
        amount: isCredit
          ? `$${totalAmount.toFixed(2)}`
          : `-$${amount.toFixed(2)}`,
        balance: `$${runningBalance.toFixed(2)}`,
      };
    });

    rows.reverse();

    const tableRows = rows
      .map(
        (r) => `<tr>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.time}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.transaction}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;text-align:right;">${r.amount}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;text-align:right;">${r.balance}</td>
        </tr>`,
      )
      .join("\n");

    const content = `
      <h2 style="margin:0 0 16px;font-size:18px;text-align:center;">Coffix Credit Transactions</h2>
      <p style="margin:0 0 16px;">Hi ${customerName}, here is your Coffix Credit transaction history.</p>
      <table width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;font-size:13px;">
        <thead>
          <tr style="background-color:#f5f5f5;">
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:left;">Time</th>
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:left;">Transaction</th>
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:right;">Amount</th>
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:right;">Balance</th>
          </tr>
        </thead>
        <tbody>
          ${tableRows || '<tr><td colspan="4" style="padding:8px 12px;border:1px solid #e0e0e0;text-align:center;">No transactions found.</td></tr>'}
        </tbody>
      </table>
    `;

    await this.send({
      email: customerEmail,
      subject: "Your Coffix Credit transactions",
      documentId: "CREDIT_HISTORY",
      userId: customerId,
      variables: {
        store_name: "Coffix",
        transaction_number: "credit-history",
      },
      htmlContent: content,
    });
  }
}
