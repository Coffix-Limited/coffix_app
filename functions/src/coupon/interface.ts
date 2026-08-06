export interface Coupon {
  docId?: string;
  amount?: number;
  expiryDate?: Date;
  storeId?: string | null;
  createdAt?: Date;
  customerEmail?: string;
  notes?: string;
  type?: string; // referral | admin | fixed
  userId?: string;
  referralId?: string;
  isUsed?: boolean;
  remainingAmount?: number;
}
