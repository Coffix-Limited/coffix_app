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
import { formatNzDate, nowNZ } from "../utils/nz_time";

function buildUserVariables(
  user: AppUser | null,
): Record<string, string | number | boolean> {
  if (!user) return {};
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
      html = params.htmlContent;
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
      documentId: "INVOICE",
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
}
