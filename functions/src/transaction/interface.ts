export enum TransactionStatus {
  Created = "created",
  Paid = "paid",
  Failed = "failed",
  Approved = "approved",
  Declined = "declined",
  Completed = "completed",
  Expired = "expired",
  Sent = "sent",
  Claimed = "claimed",
}

export interface Transaction {
  docId?: string | null;
  orderId?: string | null;
  customerId?: string | null;
  amount?: number | null;
  createdAt?: Date | string | null;
  status?: TransactionStatus | null;
  paymentMethod?: string | null;
  paymentId?: string | null;
  paymentTime?: Date | string | null;
  orderNumber?: string | null;
  type?: string | null;

  recipientCustomerId?: string | null;
  recipientEmail?: string | null;
  recipientFullName?: string | null;
  senderFullName?: string | null;
  senderEmail?: string | null;
  transactionNumber?: string | null;
  totalAmount?: number | null;
  gst?: number | null;
  gstAmount?: number | null;
  gstNumber?: string | null;
}
