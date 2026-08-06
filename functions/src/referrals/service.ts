import { firestore } from "../config/firebaseAdmin";
import { GLOBAL_COLLECTION_ID } from "../constant/constant";
import { logger } from "firebase-functions/v1";
import { endOfDayNZ } from "../utils/nz_time";
import { generateTransactionNumber } from "../utils/generate_order_number";
import { TransactionStatus } from "../transaction/interface";
import FirebaseService from "../firebase/service";

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

    const referrerDocRef = firestore.collection("referrals").doc();
    const refereeDocRef = firestore.collection("referrals").doc();
    const groupId = referrerDocRef.id;
    const refereeEmail = referee.email.toLowerCase();

    const batch = firestore.batch();

    batch.set(referrerDocRef, {
      docId: referrerDocRef.id,
      groupId,
      role: "referrer",
      ownerUid: referrerUid,
      counterpartUid: null,
      referralTime,
      referrer: referrerUid,
      referee: refereeEmail,
      refereeUid: null,
      signupTime: null,
      validTime,
      couponId: null,
      status: "pending",
    });

    batch.set(refereeDocRef, {
      docId: refereeDocRef.id,
      groupId,
      role: "referee",
      ownerUid: null,
      counterpartUid: referrerUid,
      referralTime,
      referrer: referrerUid,
      referee: refereeEmail,
      refereeUid: null,
      signupTime: null,
      validTime,
      couponId: null,
      status: "pending",
    });

    await batch.commit();

    logger.info(
      `Referral created for referrer: ${referrerUid} and referee: ${referee.email}`,
    );
  }

  async activateReferral(refereeUid: string, email: string): Promise<void> {
    const snap = await firestore
      .collection("referrals")
      .where("referee", "==", email.toLowerCase())
      .where("status", "==", "pending")
      .where("role", "==", "referee")
      .limit(1)
      .get();

    if (snap.empty) {
      logger.info(`No pending referral found for referee: ${refereeUid}`);
      return;
    }

    const refereeDoc = snap.docs[0];
    const refereeData = refereeDoc.data();

    const referrerDocSnap = await firestore
      .collection("referrals")
      .doc(refereeData.groupId)
      .get();

    if (
      !referrerDocSnap.exists ||
      referrerDocSnap.data()?.status !== "pending"
    ) {
      logger.info(
        `Referrer referral doc missing or inconsistent for referee: ${refereeUid}`,
      );
      return;
    }

    const signupTime = new Date();

    const validTime: Date =
      refereeData.validTime?.toDate?.() ?? refereeData.validTime;

    if (signupTime > validTime) {
      const batch = firestore.batch();
      batch.update(refereeDoc.ref, { status: "expired" });
      batch.update(referrerDocSnap.ref, { status: "expired" });
      await batch.commit();
      logger.info(`Referral expired for referee: ${refereeUid}`);
      return;
    }

    const batch = firestore.batch();
    batch.update(refereeDoc.ref, {
      ownerUid: refereeUid,
      refereeUid,
      signupTime,
      status: "active",
    });
    batch.update(referrerDocSnap.ref, {
      counterpartUid: refereeUid,
      refereeUid,
      signupTime,
      status: "active",
    });
    await batch.commit();

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
      .where("role", "==", "referee")
      .limit(1)
      .get();

    if (referralSnap.empty) return;

    const refereeDoc = referralSnap.docs[0];
    const referral = refereeDoc.data();

    const referrerDocSnap = await firestore
      .collection("referrals")
      .doc(referral.groupId)
      .get();

    if (
      !referrerDocSnap.exists ||
      referrerDocSnap.data()?.status !== "active"
    ) {
      logger.info(
        `Referrer referral doc missing or inconsistent for referee: ${customerId}`,
      );
      return;
    }

    // 2. Ensure this is the first approved topup
    const topupSnap = await firestore
      .collection("transactions")
      .where("customerId", "==", customerId)
      .where("type", "==", "topup")
      .where("status", "==", "approved")
      .limit(2)
      .get();

    if (topupSnap.size > 1) return;

    // 3. Fetch referrer/referee profiles for personalized notes
    const firebaseService = new FirebaseService();
    const [referrerUser, refereeUser] = await Promise.all([
      firebaseService.findUserByCustomerId(referral.referrer),
      firebaseService.findUserByCustomerId(customerId),
    ]);
    const referrerFullName =
      `${referrerUser?.firstName ?? ""} ${referrerUser?.lastName ?? ""}`.trim();
    const refereeFullName =
      `${refereeUser?.firstName ?? ""} ${refereeUser?.lastName ?? ""}`.trim();

    // 4. Read coupon config from globals
    const globalSnap = await firestore
      .collection("global")
      .doc(GLOBAL_COLLECTION_ID)
      .get();
    const couponAmount = (globalSnap.data()?.couponDefaultAmount ??
      5) as number;
    const couponExpiryDays = (globalSnap.data()?.couponExpiryDays ??
      30) as number;

    // 5. Prepare coupon docs
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
      remainingAmount: couponAmount,
      referralId: referral.groupId,
      isUsed: false,
      expiryDate: couponExpiry,
      storeId: null,
      notes: `Referral reward - $${couponAmount} off your next order`,
    };

    // 6. Transaction ledger entries + logs, mirroring CouponService.createCoupon
    const referrerTxRef = firestore.collection("transactions").doc();
    const refereeTxRef = firestore.collection("transactions").doc();
    const referrerLogRef = firestore.collection("logs").doc();
    const refereeLogRef = firestore.collection("logs").doc();

    const referrerTxNumber = await generateTransactionNumber();
    const refereeTxNumber = await generateTransactionNumber();

    // 7. Batch write both coupons + txns + logs + referral update atomically
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
      notes: `Thank you for Referring ${refereeFullName} (${refereeUser?.email ?? ""})`,
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
      notes: `Referral Coupon from ${referrerFullName} (${referrerUser?.email ?? ""})`,
      storeId: null,
    });

    batch.set(referrerLogRef, {
      docId: referrerLogRef.id,
      action: "coupon",
      category: "API",
      severityLevel: 5,
      notes: `Referral coupon issued to ${referral.referrer} worth $${couponAmount}`,
      customerId: referral.referrer,
      time: now,
    });

    batch.set(refereeLogRef, {
      docId: refereeLogRef.id,
      action: "coupon",
      category: "API",
      severityLevel: 5,
      notes: `Referral coupon issued to ${customerId} worth $${couponAmount}`,
      customerId,
      time: now,
    });

    batch.update(refereeDoc.ref, {
      status: "rewarded",
      couponId: refereeCouponRef.id,
    });

    batch.update(referrerDocSnap.ref, {
      status: "rewarded",
      couponId: referrerCouponRef.id,
    });

    await batch.commit();

    logger.info(
      `Referral rewarded. Referrer: ${referral.referrer}, Referee: ${customerId}`,
    );
  }
}
