import { firestore } from "../config/firebaseAdmin";
import { GLOBAL_COLLECTION_ID } from "../constant/constant";
import { logger } from "firebase-functions/v1";
import { endOfDayNZ } from "../utils/nz_time";
import { generateTransactionNumber } from "../utils/generate_order_number";
import { TransactionStatus } from "../transaction/interface";

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
    const validTime = endOfDayNZ(referralExpiryDays);

    logger.info(
      `Creating referral for referrer: ${referrerUid} and referee: ${referee.email}`,
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

    logger.info(
      `Referral created for referrer: ${referrerUid} and referee: ${referee.email}`,
    );
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

    // 4. Prepare coupon docs
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
      referralId: referralDoc.id,
      isUsed: false,
      expiryDate: couponExpiry,
      storeId: null,
      notes: `Referral reward - $${couponAmount} off your next order`,
    };

    // 5. Transaction ledger entries + logs, mirroring CouponService.createCoupon
    const referrerTxRef = firestore.collection("transactions").doc();
    const refereeTxRef = firestore.collection("transactions").doc();
    const referrerLogRef = firestore.collection("logs").doc();
    const refereeLogRef = firestore.collection("logs").doc();

    const referrerTxNumber = await generateTransactionNumber();
    const refereeTxNumber = await generateTransactionNumber();

    // 6. Batch write both coupons + txns + logs + referral update atomically
    const batch = firestore.batch();

    batch.set(referrerCouponRef, {
      ...baseCoupon,
      docId: referrerCouponRef.id,
      userId: referral.referrer,
    });

    batch.set(refereeCouponRef, {
      ...baseCoupon,
      docId: refereeCouponRef.id,
      userId: customerId,
    });

    batch.set(referrerTxRef, {
      docId: referrerTxRef.id,
      customerId: referral.referrer,
      amount: couponAmount,
      type: "coupon",
      paymentMethod: "coffixCredit",
      transactionNumber: referrerTxNumber,
      status: TransactionStatus.Approved,
      createdAt: now,
      notes: `Referral coupon issued - $${couponAmount}`,
      storeId: null,
    });

    batch.set(refereeTxRef, {
      docId: refereeTxRef.id,
      customerId,
      amount: couponAmount,
      type: "coupon",
      paymentMethod: "coffixCredit",
      transactionNumber: refereeTxNumber,
      status: TransactionStatus.Approved,
      createdAt: now,
      notes: `Referral coupon issued - $${couponAmount}`,
      storeId: null,
    });

    batch.set(referrerLogRef, {
      docId: referrerLogRef.id,
      action: "coupon",
      category: "API",
      severityLevel: 5,
      notes: `Referral coupon ${referrerCouponRef.id} issued to ${referral.referrer} - $${couponAmount}`,
      customerId: referral.referrer,
      time: now,
    });

    batch.set(refereeLogRef, {
      docId: refereeLogRef.id,
      action: "coupon",
      category: "API",
      severityLevel: 5,
      notes: `Referral coupon ${refereeCouponRef.id} issued to ${customerId} - $${couponAmount}`,
      customerId,
      time: now,
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
}
