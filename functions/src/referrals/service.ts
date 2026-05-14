import { firestore } from "../config/firebaseAdmin";
import { GLOBAL_COLLECTION_ID } from "../constant/constant";
import { logger } from "firebase-functions/v1";
import { generateCouponCode } from "../utils/generateCouponCode";

export class ReferralService {
  async createReferral({
    referrerUid,
    referee,
  }: {
    referrerUid: string;
    referee: { email: string; name: string };
  }): Promise<void> {
    const globalSnap = await firestore
      .collection("global")
      .doc(GLOBAL_COLLECTION_ID)
      .get();
    const referralExpiryDays = (globalSnap.data()?.referralExpiryDays ??
      7) as number;

    const referralTime = new Date();
    const validTime = new Date(
      referralTime.getTime() + referralExpiryDays * 24 * 60 * 60 * 1000,
    );

    const referralRef = firestore.collection("referrals").doc();
    await referralRef.set({
      docId: referralRef.id,
      referralTime,
      referrer: referrerUid,
      referee: referee.email.toLowerCase(),
      refereeUid: null,
      signupTime: null,
      validTime,
      couponId: null,
      refereeCouponId: null,
      status: "pending",
    });
  }

  async activateReferral(refereeUid: string, email: string): Promise<void> {
    const snap = await firestore
      .collection("referrals")
      .where("referee", "==", email.toLowerCase())
      .where("status", "==", "pending")
      .limit(1)
      .get();

    if (snap.empty) {
      logger.info(`No pending referral found for referee: ${refereeUid}`);
      return;
    }

    const referralDoc = snap.docs[0];
    const signupTime = new Date();

    const validTime: Date =
      referralDoc.data().validTime?.toDate?.() ?? referralDoc.data().validTime;

    if (signupTime > validTime) {
      await referralDoc.ref.update({ status: "expired" });
      logger.info(`Referral expired for referee: ${refereeUid}`);
      return;
    }

    await referralDoc.ref.update({
      refereeUid,
      signupTime,
      status: "active",
    });

    logger.info(`Referral activated for referee: ${refereeUid}`);
  }

  // this function is called when a customer makes their first topUp
  async handleFirstPurchase({
    customerId,
  }: {
    customerId: string;
  }): Promise<void> {
    logger.info(`Handling first purchase for customer: ${customerId}`);
    // 1. Find active referral for this referee
    const referralSnap = await firestore
      .collection("referrals")
      .where("refereeUid", "==", customerId)
      .where("status", "==", "active")
      .limit(1)
      .get();

    if (referralSnap.empty) return;

    const referralDoc = referralSnap.docs[0];
    const referral = referralDoc.data();

    // 2. Ensure this is the first approved topup
    const topupSnap = await firestore
      .collection("transactions")
      .where("customerId", "==", customerId)
      .where("type", "==", "topup")
      .where("status", "==", "approved")
      .limit(2)
      .get();

    if (topupSnap.size > 1) return;

    // 3. Read coupon config from globals
    const globalSnap = await firestore
      .collection("global")
      .doc(GLOBAL_COLLECTION_ID)
      .get();
    const couponAmount = (globalSnap.data()?.couponDefaultAmount ??
      5) as number;
    const couponExpiryDays = (globalSnap.data()?.couponExpiryDays ??
      30) as number;

    // 4. Generate unique coupon codes
    const referrerCode = await this.generateUniqueCode();
    const refereeCode = await this.generateUniqueCode();

    const now = new Date();
    const couponExpiry = new Date(
      now.getTime() + couponExpiryDays * 24 * 60 * 60 * 1000,
    );

    const referrerCouponRef = firestore.collection("coupons").doc();
    const refereeCouponRef = firestore.collection("coupons").doc();

    const baseCoupon = {
      createdAt: now,
      type: "fixed",
      amount: couponAmount,
      usageLimit: 1,
      usageCount: 0,
      source: "referral",
      referralId: referralDoc.id,
      isUsed: false,
      expiryDate: couponExpiry,
      storeId: null,
      notes: `Referral reward - $${couponAmount} off your next order`,
    };

    // 5. Batch write both coupons + update referral atomically
    const batch = firestore.batch();

    batch.set(referrerCouponRef, {
      ...baseCoupon,
      docId: referrerCouponRef.id,
      code: referrerCode,
      userIds: [referral.referrer],
    });

    batch.set(refereeCouponRef, {
      ...baseCoupon,
      docId: refereeCouponRef.id,
      code: refereeCode,
      userIds: [customerId],
    });

    batch.update(referralDoc.ref, {
      status: "rewarded",
      couponId: referrerCouponRef.id,
      refereeCouponId: refereeCouponRef.id,
    });

    await batch.commit();

    logger.info(
      `Referral rewarded. Referrer: ${referral.referrer}, Referee: ${customerId}`,
    );
  }

  private async generateUniqueCode(): Promise<string> {
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = generateCouponCode();
      const existing = await firestore
        .collection("coupons")
        .where("code", "==", code)
        .limit(1)
        .get();
      if (existing.empty) return code;
    }
    throw new Error("Failed to generate a unique coupon code after 5 attempts");
  }
}
