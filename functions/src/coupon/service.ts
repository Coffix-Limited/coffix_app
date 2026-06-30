import { firestore } from "../config/firebaseAdmin";
import { logger } from "firebase-functions/v1";
import { Coupon } from "./interface";
import FirebaseService from "../firebase/service";

export class CouponService {
  async createCoupon({
    type,
    amount,
    expiryDate,
    storeId,
    notes,
    customerEmail,
  }: {
    type: string;
    amount: number;
    expiryDate: Date;
    storeId?: string;
    notes?: string;
    customerEmail: string;
  }): Promise<Coupon> {
    const ref = firestore.collection("coupons").doc();

    const firebaseService = new FirebaseService();
    const customer = await firebaseService.findCustomerByEmail(customerEmail);

    const coupon: Coupon = {
      docId: ref.id,
      amount,
      expiryDate,
      createdAt: new Date(),
      customerEmail: customerEmail.toLowerCase(),
      type,
    };
    if (storeId !== undefined) coupon.storeId = storeId;
    if (notes !== undefined) coupon.notes = notes;
    if (customer) coupon.userId = customer.customerId;

    await ref.set(coupon);

    logger.info(`Coupon ${ref.id} created for ${customerEmail}`);

    return coupon;
  }
}
