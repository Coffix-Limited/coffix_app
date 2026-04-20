import { firestore, printerFirestore } from "../config/firebaseAdmin";
import {
  generateOrderNumber,
  generateTransactionNumber,
} from "../utils/generate_order_number";
import { createOrderBodySchema, CreateOrderBodySchema } from "./schema";
import { InsufficientCreditError } from "../coffixCredit/errors";
import { scheduledAtNZ } from "../utils/nz_time";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";
import { AppUser } from "../user/interface";
import { GLOBAL_COLLECTION_ID } from "../constant/constant";
import { logger } from "firebase-functions";

class FirebaseService {
  /**
   * This will mark the order as paid and update the paidAt field
   * @param orderId - The ID of the order to mark as paid
   */
  async markOrderAsPaid(orderId: string) {
    const orderRef = firestore.collection("orders").doc(orderId);
    await orderRef.set(
      {
        status: "paid",
        paidAt: new Date(),
      },
      { merge: true },
    );
  }

  async updateOrder(orderId: string, data: any) {
    const orderRef = firestore.collection("orders").doc(orderId);
    await orderRef.set(data, { merge: true });
  }

  async createReceipt(orderId: string) {
    const receiptRef = printerFirestore.collection("receipts").doc();
    await receiptRef.set({
      orderId: orderId,
      createdAt: new Date(),
    });
  }

  async getGlobal() {
    const globalRef = firestore.collection("global").doc(GLOBAL_COLLECTION_ID);
    const globalSnap = await globalRef.get();
    if (!globalSnap.exists) {
      throw new Error("Global not found");
    }
    logger.info("Global", { global: globalSnap.data() });
    return globalSnap.data();
  }

  // Order Status	Meaning
  // draft	Saved but not paying yet
  // pending_payment	Waiting for payment
  // paid	Payment confirmed
  // preparing	Barista is making it
  // ready	Ready for pickup
  // completed	Picked up
  // cancelled	Cancelled
  // expired	Payment not completed in time

  async createNewOrder(
    body: CreateOrderBodySchema,
  ): Promise<{ orderId: string; orderData: Record<string, any> }> {
    const validation = createOrderBodySchema.safeParse(body);
    if (!validation.success) {
      throw new Error("Invalid body");
    }
    const storeDoc = await this.findStoreByStoreId(validation.data.storeId);
    if (!storeDoc)
      throw new Error(`Store not found: ${validation.data.storeId}`);

    const orderRef = firestore.collection("orders").doc();
    // [StoreCode][YYMMDD][RunningNumber]
    const orderNumber = await generateOrderNumber(validation.data.storeId);
    const orderData: Record<string, any> = {
      docId: orderRef.id,
      orderNumber,
      amount: validation.data.amount,
      customerId: validation.data.customerId,
      storeId: validation.data.storeId,
      storeName: storeDoc.name,
      storeAddress: storeDoc.address,
      storeGst: storeDoc.gstNumber,
      items: validation.data.items,
      createdAt: new Date(),
      status: "pending_payment",
      duration: validation.data.duration,
      paymentMethod: validation.data.paymentMethod,
      transactionNumber: validation.data.transactionNumber,
      scheduledAt: scheduledAtNZ(validation.data.duration),
    };
    await orderRef.set(orderData);

    return { orderId: orderRef.id, orderData };
  }

  async createTransactionAndMarkOrderPaid({
    customerId,
    orderId,
    amount,
    duration,
    orderNumber,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    duration: number;
    orderNumber: string;
  }): Promise<string> {
    const transactionRef = firestore.collection("transactions").doc();
    const orderRef = firestore.collection("orders").doc(orderId);
    const paidAt = new Date();
    const scheduledAt = new Date(Date.now() + duration * 60_000);

    const batch = firestore.batch();
    batch.set(transactionRef, {
      docId: transactionRef.id,
      customerId,
      orderId,
      amount,
      status: "approved",
      createdAt: paidAt,
      paymentTime: paidAt,
      paymentMethod: "coffixCredit",
      sessionId: "coffixCredit",
      orderNumber,
    });
    batch.set(
      orderRef,
      { status: "paid", paidAt, scheduledAt },
      { merge: true },
    );
    await batch.commit();

    return transactionRef.id;
  }

  async deductCreditAndMarkOrderPaid({
    customerId,
    orderId,
    amount,
    duration,
    orderNumber,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    duration: number;
    orderNumber: string;
  }): Promise<{ paidAt: Date; scheduledAt: Date }> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const orderRef = firestore.collection("orders").doc(orderId);
    const transactionRef = firestore.collection("transactions").doc();

    const paidAt = new Date();
    const scheduledAt = scheduledAtNZ(duration);

    await firestore.runTransaction(async (tx) => {
      // READ phase (all reads before writes — Firestore requirement)
      const customerSnap = await tx.get(customerRef);

      if (!customerSnap.exists) {
        throw new Error("Customer not found");
      }

      const data = customerSnap.data();
      const creditAvailable = (data?.creditAvailable ?? 0) as number;

      if (creditAvailable < amount) {
        throw new InsufficientCreditError(creditAvailable, amount);
      }

      // WRITE phase
      tx.update(customerRef, { creditAvailable: creditAvailable - amount });

      tx.set(transactionRef, {
        docId: transactionRef.id,
        customerId,
        orderId,
        amount,
        status: "approved",
        createdAt: paidAt,
        paymentTime: paidAt,
        paymentMethod: "coffixCredit",
        sessionId: "coffixCredit",
        orderNumber,
      });

      tx.set(
        orderRef,
        { status: "paid", paidAt, scheduledAt },
        { merge: true },
      );
    });

    return { paidAt, scheduledAt };
  }

  /**
   * Deducts eligible coupons first, then Coffix Credit for the remainder.
   * Eligible coupons: assigned to this user, not expired, not used, usageCount < usageLimit.
   * All writes are atomic in a single Firestore transaction.
   */
  async deductCouponsThenCreditAndMarkOrderPaid({
    customerId,
    orderId,
    amount,
    duration,
    orderNumber,
    transactionNumber,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    duration: number;
    orderNumber: string;
    transactionNumber: string;
  }): Promise<{ paidAt: Date; scheduledAt: Date }> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const orderRef = firestore.collection("orders").doc(orderId);
    const transactionRef = firestore.collection("transactions").doc();

    const paidAt = new Date();
    const scheduledAt = scheduledAtNZ(duration);
    const now = new Date();

    const [globalDoc, orderSnap] = await Promise.all([
      this.getGlobal(),
      firestore.collection("orders").doc(orderId).get(),
    ]);
    const gst = (globalDoc.GST ?? 0) as number;
    const gstNumber = (orderSnap.data()?.storeGst as string) ?? "";
    const gstAmount = (gst / 100) * amount;

    // Fetch eligible coupons outside the transaction (reads before transaction opens)
    const couponSnap = await firestore
      .collection("coupons")
      .where("userIds", "array-contains", customerId)
      .get();

    const eligibleCouponRefs = couponSnap.docs
      .filter((doc) => {
        const c = doc.data() as Record<string, any>;
        const notExpired =
          !c.expiryDate ||
          (c.expiryDate as admin.firestore.Timestamp).toDate() > now;
        const notUsed = c.isUsed !== true;
        const hasUsage =
          c.usageLimit == null ||
          c.usageCount == null ||
          (c.usageCount as number) < (c.usageLimit as number);
        return notExpired && notUsed && hasUsage;
      })
      .map((doc) => doc.ref);

    await firestore.runTransaction(async (tx) => {
      // READ phase
      const customerSnap = await tx.get(customerRef);
      if (!customerSnap.exists) throw new Error("Customer not found");

      // Re-read each coupon inside the transaction to guard against races
      const couponSnaps = await Promise.all(
        eligibleCouponRefs.map((ref) => tx.get(ref)),
      );

      const data = customerSnap.data()!;
      const creditAvailable = (data.creditAvailable ?? 0) as number;

      // Determine which coupons to consume and how much credit to deduct
      let remaining = amount;
      const couponsToConsume: Array<{
        ref: admin.firestore.DocumentReference;
        couponId: string;
        amountUsed: number;
        newUsageCount: number;
      }> = [];

      for (const snap of couponSnaps) {
        if (!snap.exists || remaining <= 0) continue;
        const cd = snap.data()!;
        // Re-validate inside transaction
        const notExpired =
          !cd.expiryDate ||
          (cd.expiryDate as admin.firestore.Timestamp).toDate() > now;
        const notUsed = cd.isUsed !== true;
        const hasUsage =
          cd.usageLimit == null ||
          cd.usageCount == null ||
          (cd.usageCount as number) < (cd.usageLimit as number);
        if (!notExpired || !notUsed || !hasUsage) continue;

        const couponAmount = (cd.amount ?? 0) as number;
        const amountUsed = Math.min(couponAmount, remaining);
        remaining -= amountUsed;
        couponsToConsume.push({
          ref: snap.ref,
          couponId: snap.id,
          amountUsed,
          newUsageCount: ((cd.usageCount ?? 0) as number) + 1,
        });
      }

      const totalBalance =
        creditAvailable +
        couponsToConsume.reduce((s, c) => s + c.amountUsed, 0);
      if (totalBalance < amount) {
        throw new InsufficientCreditError(totalBalance, amount);
      }

      // WRITE phase
      // Mark each consumed coupon as used
      for (const c of couponsToConsume) {
        tx.update(c.ref, {
          isUsed: true,
          usageCount: c.newUsageCount,
        });
      }

      // Deduct remaining from creditAvailable (may be 0 if coupons covered it all)
      if (remaining > 0) {
        tx.update(customerRef, {
          creditAvailable: creditAvailable - remaining,
        });
      }

      tx.set(transactionRef, {
        docId: transactionRef.id,
        customerId,
        orderId,
        amount,
        couponIds: couponsToConsume.map((c) => c.couponId),
        couponDiscount: amount - remaining,
        status: "approved",
        createdAt: paidAt,
        paymentTime: paidAt,
        paymentMethod: "coffixCredit",
        sessionId: "",
        orderNumber,
        transactionNumber,
        type: "order",
        gst,
        gstNumber,
        gstAmount,
      });

      tx.set(
        orderRef,
        { status: "paid", paidAt, scheduledAt },
        { merge: true },
      );
    });

    return { paidAt, scheduledAt };
  }

  // Transaction Status	Meaning
  // created	Session created
  // pending	User on HPP
  // authorised	Approved
  // declined	Bank declined
  // cancelled	User cancelled
  // error	Gateway error
  async createNewTransaction({
    customerId,
    orderId,
    amount,
    sessionId,
    transactionNumber,
    type,
    gstNumber,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    sessionId: string;
    transactionNumber: string;
    type: string;
    gstNumber: string;
  }): Promise<string> {
    const transactionRef = firestore.collection("transactions").doc();

    const global = await this.getGlobal();
    logger.info("Global Gst", { global: global.gst });
    const gst = global.GST ?? 0;
    const gstAmount = (gst / 100) * amount;
    await transactionRef.set({
      docId: transactionRef.id,
      customerId,
      orderId,
      amount,
      status: "created",
      createdAt: new Date(),
      sessionId,
      transactionNumber,
      type,
      gst,
      gstNumber,
      gstAmount,
    });
    return transactionRef.id;
  }

  async updateTransaction(transactionId: string, data: any) {
    const transactionRef = firestore
      .collection("transactions")
      .doc(transactionId);
    await transactionRef.set(data, { merge: true });
  }

  async createTopupTransaction({
    customerId,
    amount,
    sessionId,
    transactionNumber,
  }: {
    customerId: string;
    amount: number;
    sessionId: string;
    transactionNumber: string;
  }): Promise<Record<string, any>> {
    const transactionRef = firestore.collection("transactions").doc();
    const transactionDoc = {
      docId: transactionRef.id,
      customerId,
      amount,
      status: "created",
      createdAt: new Date(),
      sessionId,
      type: "topup",
      transactionNumber,
    };
    await transactionRef.set(transactionDoc, { merge: true });
    return transactionDoc;
  }

  async findTransactionByTransactionNumber(
    transactionNumber: string,
  ): Promise<Record<string, any> | null> {
    const snap = await firestore
      .collection("transactions")
      .where("transactionNumber", "==", transactionNumber)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].data();
  }

  async findTransactionBySessionId(sessionId: string) {
    const transactionRef = await firestore
      .collection("transactions")
      .where("sessionId", "==", sessionId)
      .get();
    if (transactionRef.empty) {
      return null;
    }
    return transactionRef.docs[0].data();
  }

  async findOrderByOrderId(orderId: string) {
    const orderRef = await firestore.collection("orders").doc(orderId).get();
    if (!orderRef.exists) {
      return null;
    }
    return orderRef.data();
  }

  async findOrderByTransactionNumber(
    transactionNumber: string,
  ): Promise<Record<string, any> | null> {
    const snap = await firestore
      .collection("orders")
      .where("transactionNumber", "==", transactionNumber)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].data();
  }

  async findStoreByStoreId(storeId: string) {
    const storeRef = await firestore.collection("stores").doc(storeId).get();
    if (!storeRef.exists) {
      return null;
    }
    return storeRef.data();
  }

  async findUserByCustomerId(customerId: string): Promise<AppUser | null> {
    const userRef = await firestore
      .collection("customers")
      .doc(customerId)
      .get();
    if (!userRef.exists) {
      return null;
    }
    return userRef.data() as AppUser;
  }

  async findCustomerByEmail(email: string): Promise<{
    customerId: string;
    data: admin.firestore.DocumentData;
  } | null> {
    const snap = await firestore
      .collection("customers")
      .where("email", "==", email.toLowerCase())
      .limit(1)
      .get();
    if (snap.empty) return null;
    const doc = snap.docs[0];
    return { customerId: doc.id, data: doc.data() };
  }

  createGiftTransaction(
    tx: admin.firestore.Transaction,
    {
      senderId,
      senderFirstName,
      senderLastName,
      recipientEmail,
      recipientFullName,
      recipientCustomerId,
      amount,
      transactionNumber,
    }: {
      senderId: string;
      senderFirstName: string;
      senderLastName: string;
      recipientEmail: string;
      recipientFullName: string;
      recipientCustomerId?: string;
      amount: number;
      transactionNumber: string;
    },
  ): void {
    const transactionRef = firestore.collection("transactions").doc();
    const doc: Record<string, any> = {
      docId: transactionRef.id,
      customerId: senderId,
      type: "gift",
      paymentMethod: "coffixCredit",
      senderFirstName,
      senderLastName,
      recipientEmail: recipientEmail.toLowerCase(),
      recipientFullName,
      amount,
      status: "completed",
      createdAt: new Date(),
      transactionNumber,
    };
    if (recipientCustomerId !== undefined) {
      doc.recipientCustomerId = recipientCustomerId;
    }
    tx.set(transactionRef, doc);
  }

  async applyPendingGifts(newUserId: string, email: string): Promise<void> {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const snap = await firestore
      .collection("transactions")
      .where("type", "==", "gift")
      .where("recipientEmail", "==", email.toLowerCase())
      .where("createdAt", ">=", thirtyDaysAgo)
      .get();

    const pending = snap.docs.filter((d) => !d.data().recipientCustomerId);
    if (pending.length === 0) return;

    const totalAmount = pending.reduce(
      (sum, d) => sum + ((d.data().amount as number) ?? 0),
      0,
    );

    const customerRef = firestore.collection("customers").doc(newUserId);
    await firestore.runTransaction(async (tx) => {
      const customerSnap = await tx.get(customerRef);
      const current = customerSnap.exists
        ? ((customerSnap.data()?.creditAvailable ?? 0) as number)
        : 0;
      tx.set(
        customerRef,
        { creditAvailable: current + totalAmount },
        { merge: true },
      );
      for (const doc of pending) {
        tx.update(doc.ref, { recipientCustomerId: newUserId });
      }
    });
  }

  async expireCredits(): Promise<{ expiredCount: number }> {
    const customersSnap = await firestore
      .collection("customers")
      .where("creditAvailable", ">", 0)
      .get();

    const toNZDateString = (date: Date): string =>
      new Intl.DateTimeFormat("en-CA", {
        timeZone: "Pacific/Auckland",
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
      }).format(date);

    const todayNZ = toNZDateString(new Date());

    let expiredCount = 0;

    for (const doc of customersSnap.docs) {
      const data = doc.data();
      const creditExpiryRaw = data.creditExpiry;
      const creditAvailable: number = data.creditAvailable ?? 0;

      if (!creditExpiryRaw || creditAvailable <= 0) continue;

      // creditExpiry is stored as a Firestore Timestamp — convert to NZ date string
      const expiryDate: Date =
        creditExpiryRaw instanceof Timestamp
          ? creditExpiryRaw.toDate()
          : new Date(creditExpiryRaw);
      const expiryNZ = toNZDateString(expiryDate);

      // Only expire when today is strictly after the expiry date
      if (expiryNZ >= todayNZ) continue;

      const transactionNumber = await generateTransactionNumber();
      const transactionRef = firestore.collection("transactions").doc();
      const batch = firestore.batch();

      batch.update(doc.ref, { creditAvailable: 0 });
      batch.set(transactionRef, {
        docId: transactionRef.id,
        customerId: doc.id,
        amount: 0,
        type: "expired",
        status: "expired",
        createdAt: new Date(),
        transactionNumber,
      });

      await batch.commit();
      expiredCount++;
    }

    return { expiredCount };
  }
}

export default FirebaseService;
