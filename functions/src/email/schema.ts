import { z } from "zod";

export const sendGiftEmailSchema = z.object({
  to: z.email(),
  userId: z.string().min(1),
  amount: z.number().positive(),
  recipientFirstName: z.string().optional(),
});

export const sendInvoiceSchema = z.object({
  to: z.email(),
  userId: z.string().min(1),
  invoice: z.string().min(1),
  storeName: z.string().min(1),
  transactionNumber: z.string().min(1),
});

export const sendOTPSchema = z.object({
  to: z.email(),
  userId: z.string().min(1),
  otp: z.string().min(1),
});

export const sendReferralEmailSchema = z.object({
  to: z.email(),
  userId: z.string().min(1),
  referee_name: z.string().min(1),
});


export interface SendEmailParams {
  email: string;
  subject?: string;
  documentId: string;
  variables: Record<string, string | number>;
  userId?: string;
  htmlContent?: string;
}

export interface GiftEmailParams {
  to: string;
  userId: string;
  amount: number;
  recipientFullName?: string;
  senderFullName?: string;
  isSender?: boolean;
  transactionNumber?: string;
  storeInvoiceText?: string;
}

export interface SendRefundEmailParams {
  to: string;
  userId: string;
  transactionNumber: string;
  originalTransactionNumber: string;
  amount: number;
  storeInvoiceText?: string;
  gst?: number;
  gstAmount?: number;
  gstNumber?: string;
  isCoffixCredit: boolean;
}



export type SendGiftEmailSchema = z.infer<typeof sendGiftEmailSchema>;
export type SendInvoiceSchema = z.infer<typeof sendInvoiceSchema>;
export type SendOTPSchema = z.infer<typeof sendOTPSchema>;
export type SendReferralEmailSchema = z.infer<typeof sendReferralEmailSchema>;
