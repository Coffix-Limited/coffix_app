import { firestore } from "../config/firebaseAdmin";
import { logger } from "firebase-functions/v1";
import { Coupon } from "./interface";
import FirebaseService from "../firebase/service";
import { TransactionStatus } from "../transaction/interface";
import { generateTransactionNumber } from "../utils/generate_order_number";

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
    const txRef = firestore.collection("transactions").doc();
    const logRef = firestore.collection("logs").doc();

    const firebaseService = new FirebaseService();
    const customer = await firebaseService.findCustomerByEmail(customerEmail);
    const customerId = customer?.customerId ?? null;

    const transactionNumber = await generateTransactionNumber();

    const now = new Date();

    const coupon: Coupon = {
      docId: ref.id,
      amount,
      // amount is the issued face value and stays fixed; spending draws down
      // remainingAmount so the original worth is preserved as history.
      remainingAmount: amount,
      isUsed: false,
      expiryDate,
      createdAt: now,
      customerEmail: customerEmail.toLowerCase(),
      type,
    };
    if (storeId !== undefined) coupon.storeId = storeId;
    if (notes !== undefined) coupon.notes = notes;
    if (customer) coupon.userId = customer.customerId;

    // Coupon + transaction ledger entry + log written atomically.
    const batch = firestore.batch();

    batch.set(ref, coupon);

    batch.set(txRef, {
      docId: txRef.id,
      customerId,
      amount,
      type: "coupon",
      paymentMethod: "coffixCredit",
      transactionNumber,
      status: TransactionStatus.Approved,
      createdAt: now,
      notes: notes ?? `Coupon issued - $${amount}`,
      storeId: storeId ?? null,
    });

    batch.set(logRef, {
      docId: logRef.id,
      action: "coupon",
      category: "API",
      severityLevel: 5,
      notes: `Coupon issued to ${customerEmail} worth $${amount}`,
      customerId,
      time: now,
    });

    await batch.commit();

    logger.info(`Coupon ${ref.id} created for ${customerEmail}`);

    return coupon;
  }
}
