export interface Log {
  docId?: string;
  page?: string;
  customerId?: string;

  /**
   * AppError, WebError, App, Web, etc.
   */
  category?: string;

  /**
   * 1 - low level: login, forgot password, etc.
   * 3 or 5 - mid level: errors, payment decline, etc.
   * 9 - high level: financial transactions, kept long term
   */
  severityLevel?: string;

  /**
   * Used for admin controlling staff, not customers in web app
   */
  userId?: string;

  /**
   * purchase, gift, topup, referral, draft, credit,
   * invoice request, login, etc.
   */
  action?: string;

  /**
   * English description with reference, e.g. order number
   */
  notes?: string;

  /**
   * Timestamp
   */
  time?: Date;
}
