export interface Log {
  docId?: string | null;
  page?: string | null;
  customerId?: string | null;
  category?: string | null; // refund, purchase, referral, info update, bonus
  severityLevel?: string | null; // error, warning, info, success
  // used for admin controlling staff not customers in web app
  userId?: string | null;
  action?: string | null;
  notes?: string | null;
  time?: Date | string | null;
}
