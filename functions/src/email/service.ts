import { firestore } from "../config/firebaseAdmin";
import { RESEND_BCC_EMAIL, RESEND_FROM_EMAIL } from "../constant/constant";
import { renderTemplate } from "../utils/renderEmailTemplate";
import { wrapInEmailShell } from "../utils/emailShell";
import { logger } from "firebase-functions";
import {
  GiftEmailParams,
  SendEmailParams,
  SendInvoiceSchema,
  SendOTPSchema,
  SendReferralEmailSchema,
} from "./schema";
import { AppUser } from "../user/interface";
import { EmailTemplate } from "./interface";
import { formatNzDate, formatNzTime, nowNZ } from "../utils/nz_time";
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
    birthday: formatNzDate(user.birthday) ?? "",
    suburb: user.suburb ?? "",
    city: user.city ?? "",
    preferred_store_id: user.preferredStoreId ?? "",
    credit_available: user.creditAvailable ?? 0,
    created_at: formatNzDate(user.createdAt) ?? "",
    email_verified: user.emailVerified ?? false,
    get_purchase_info_by_mail: user.getPurchaseInfoByMail ?? false,
    get_promotions: user.getPromotions ?? false,
    allow_win_a_coffee: user.allowWinACoffee ?? false,
    last_login: formatNzDate(user.lastLogin) ?? "",
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

    const userVariables = buildUserVariables(
      userSnap?.exists ? (userSnap.data() as AppUser) : null,
      params.email,
    );
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

  // send gift notification email
  async sendGift(params: GiftEmailParams): Promise<void> {
    await this.send({
      email: params.to,
      documentId: "GIFT",
      userId: params.userId,
      variables: {
        gift_amount: params.amount.toFixed(2),
        transaction_number: params.transactionNumber ?? "",
      },
    });
  }

  async sendInvoice(
    params: Omit<SendInvoiceSchema, "invoice"> & { invoiceHtml: string },
  ): Promise<void> {
    await this.send({
      email: params.to,
      documentId: "COFFIX_CREDIT_INVOICE",
      userId: params.userId,
      variables: {
        store_name: params.storeName,
        transaction_number: params.transactionNumber,
      },
      htmlContent: params.invoiceHtml,
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
    });
  }

  async sendReferralEmail(params: SendReferralEmailSchema): Promise<void> {
    await this.send({
      email: params.to,
      subject: "You received a referral code from a friend!",
      documentId: "REFERRAL",
      userId: params.userId,
      variables: {
        referee_name: params.referee_name,
      },
    });
  }

  async sendCreditTransactions(customerId: string): Promise<void> {
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
      .where("paymentMethod", "==", "coffixCredit")
      .where("status", "in", ["paid", "approved", "completed"])
      .orderBy("createdAt", "asc")
      .get();

    const transactions = snap.docs.map((d) => d.data());

    let runningBalance = 0;
    const rows = transactions.map((tx) => {
      const type = (tx.type as string | undefined) ?? "order";
      const amount = (tx.amount as number | undefined) ?? 0;
      const totalAmount = (tx.totalAmount as number | undefined) ?? amount;
      if (type === "topup" || type === "gift") {
        runningBalance += totalAmount;
      } else {
        runningBalance -= amount;
      }
      return {
        time: formatNzTime(toDate(tx.createdAt)),
        transaction: `#${tx.transactionNumber ?? ""} ${type.charAt(0).toUpperCase() + type.slice(1)}`,
        amount: `$${amount.toFixed(2)}`,
        balance: `$${runningBalance.toFixed(2)}`,
      };
    });

    rows.reverse();

    const tableRows = rows
      .map(
        (r) => `<tr>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.time}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.transaction}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.amount}</td>
          <td style="padding:8px 12px;border:1px solid #e0e0e0;">${r.balance}</td>
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
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:left;">Amount</th>
            <th style="padding:8px 12px;border:1px solid #e0e0e0;text-align:left;">Balance</th>
          </tr>
        </thead>
        <tbody>
          ${tableRows || '<tr><td colspan="4" style="padding:8px 12px;border:1px solid #e0e0e0;text-align:center;">No transactions found.</td></tr>'}
        </tbody>
      </table>
    `;

    await this.sendInvoice({
      to: customerEmail,
      userId: customerId,
      invoiceHtml: content,
      storeName: "Coffix",
      transactionNumber: "credit-history",
    });
  }
}
