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
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      logger.error("createNewOrder: invalid body", { errors });
      throw new Error(`Invalid order body: ${errors}`);
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
      storeInvoiceText: storeDoc.invoiceText,
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
    scheduledAt,
    storeId,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    duration: number;
    orderNumber: string;
    transactionNumber: string;
    scheduledAt: Date;
    storeId?: string;
  }): Promise<{ paidAt: Date }> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const orderRef = firestore.collection("orders").doc(orderId);
    const transactionRef = firestore.collection("transactions").doc();

    const paidAt = new Date();
    const now = new Date();

    // const gst = (globalDoc.GST ?? 0) as number;
    // const gstNumber = (orderSnap.data()?.storeGst as string) ?? "";
    // const gstAmount = amount - amount / (1 + gst / 100);

    // Spendable balance of a coupon. Coupons issued before remainingAmount
    // existed only carry amount, so fall back to it for those.
    const couponBalance = (c: Record<string, any>): number =>
      (c.remainingAmount ?? c.amount ?? 0) as number;

    // Fetch eligible coupons outside the transaction (reads before transaction opens)
    const couponSnap = await firestore
      .collection("coupons")
      .where("userId", "==", customerId)
      .get();

    const eligibleCouponRefs = couponSnap.docs
      .filter((doc) => {
        const c = doc.data() as Record<string, any>;
        const notExpired =
          !c.expiryDate ||
          (c.expiryDate as admin.firestore.Timestamp).toDate() > now;
        return notExpired && couponBalance(c) > 0;
      })
      .sort((a, b) => {
        const aExpiry = a.data().expiryDate
          ? (a.data().expiryDate as admin.firestore.Timestamp)
              .toDate()
              .getTime()
          : Infinity;
        const bExpiry = b.data().expiryDate
          ? (b.data().expiryDate as admin.firestore.Timestamp)
              .toDate()
              .getTime()
          : Infinity;
        return aExpiry - bExpiry;
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
        balanceBefore: number;
      }> = [];

      for (const snap of couponSnaps) {
        if (!snap.exists || remaining <= 0) continue;
        const cd = snap.data()!;
        // Re-validate inside transaction
        const notExpired =
          !cd.expiryDate ||
          (cd.expiryDate as admin.firestore.Timestamp).toDate() > now;
        const balanceBefore = couponBalance(cd);
        if (!notExpired || balanceBefore <= 0) continue;

        const amountUsed = Math.min(balanceBefore, remaining);
        remaining -= amountUsed;
        couponsToConsume.push({
          ref: snap.ref,
          couponId: snap.id,
          amountUsed,
          balanceBefore,
        });
      }

      const totalBalance =
        creditAvailable +
        couponsToConsume.reduce((s, c) => s + c.amountUsed, 0);
      if (totalBalance < amount) {
        throw new InsufficientCreditError(totalBalance, amount);
      }

      // WRITE phase
      // Draw down remainingAmount and leave amount (the issued face value)
      // untouched. Written explicitly rather than via increment because legacy
      // coupons may not have the field yet.
      for (const c of couponsToConsume) {
        const newRemaining = c.balanceBefore - c.amountUsed;
        tx.update(c.ref, {
          remainingAmount: newRemaining,
          ...(newRemaining <= 0 ? { isUsed: true } : {}),
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
        // gst,
        // gstNumber,
        // gstAmount,
        storeId: storeId ?? "",
      });

      tx.set(
        orderRef,
        { status: "paid", paidAt, scheduledAt },
        { merge: true },
      );
    });

    return { paidAt };
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
    paymentMethod,
    storeId,
    expiresAt,
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    sessionId: string;
    transactionNumber: string;
    type: string;
    gstNumber: string;
    paymentMethod: string;
    storeId?: string;
    expiresAt?: Date;
  }): Promise<string> {
    const transactionRef = firestore.collection("transactions").doc();

    const global = await this.getGlobal();
    logger.info("Global Gst", { global: global.gst });
    const gst = global.GST ?? 0;
    const gstAmount = amount - amount / (1 + gst / 100);
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
      paymentMethod,
      storeId: storeId ?? "",
      ...(expiresAt ? { expiresAt } : {}),
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
    expiresAt,
  }: {
    customerId: string;
    amount: number;
    sessionId: string;
    transactionNumber: string;
    expiresAt?: Date;
  }): Promise<Record<string, any>> {
    const transactionRef = firestore.collection("transactions").doc();
    const [globalDoc, userDoc] = await Promise.all([
      this.getGlobal(),
      this.findUserByCustomerId(customerId),
    ]);
    const storeDoc = userDoc?.preferredStoreId
      ? await this.findStoreByStoreId(userDoc.preferredStoreId)
      : null;
    const gst = (globalDoc?.GST ?? 0) as number;
    const gstNumber = (storeDoc?.gstNumber ?? "") as string;
    const storeInvoiceText = (storeDoc?.invoiceText ?? "") as string;
    const gstAmount = amount - amount / (1 + gst / 100);
    const transactionDoc = {
      docId: transactionRef.id,
      customerId,
      amount,
      status: "created",
      createdAt: new Date(),
      sessionId,
      type: "topup",
      paymentMethod: "coffixCredit",
      transactionNumber,
      gst,
      gstNumber,
      gstAmount,
      storeInvoiceText,
      ...(expiresAt ? { expiresAt } : {}),
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

  async findTransactionById(
    transactionId: string,
  ): Promise<Record<string, any> | null> {
    const snap = await firestore
      .collection("transactions")
      .doc(transactionId)
      .get();
    if (!snap.exists) return null;
    return snap.data() ?? null;
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

  async findActiveStoreByStoreId(storeId: string) {
    const storeRef = await firestore
      .collection("stores")
      .where("disable", "==", false)
      .where("isDeleted", "==", false)
      .where("docId", "==", storeId)
      .limit(1)
      .get();
    if (storeRef.empty) {
      return null;
    }
    return storeRef.docs[0].data();
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
      senderFullName,
      senderEmail,
      recipientEmail,
      recipientFullName,
      recipientCustomerId,
      amount,
      transactionNumber,
      storeInvoiceText,
      storeId,
      printerId,
    }: {
      senderId: string;
      senderFullName: string;
      senderEmail: string;
      recipientEmail: string;
      recipientFullName: string;
      recipientCustomerId?: string;
      amount: number;
      transactionNumber: string;
      storeInvoiceText?: string;
      storeId?: string;
      printerId?: string;
    },
  ): void {
    const now = new Date();
    const baseFields = {
      type: "gift",
      paymentMethod: "coffixCredit",
      senderFullName,
      senderEmail,
      recipientEmail: recipientEmail.toLowerCase(),
      recipientFullName,
      amount,
      transactionNumber,
      createdAt: now,
      storeInvoiceText: storeInvoiceText ?? "",
      storeId: storeId ?? "",
      printerId: printerId ?? "",
    };

    const senderTxRef = firestore.collection("transactions").doc();
    tx.set(senderTxRef, {
      ...baseFields,
      docId: senderTxRef.id,
      customerId: senderId,
      role: "sender",
      status: "sent",
    });

    const recipientTxRef = firestore.collection("transactions").doc();
    const recipientStatus =
      recipientCustomerId !== undefined ? "claimed" : "pending";
    const recipientDoc: Record<string, any> = {
      ...baseFields,
      docId: recipientTxRef.id,
      role: "recipient",
      status: recipientStatus,
      recipientCustomerId: recipientCustomerId ?? null,
    };
    if (recipientCustomerId !== undefined) {
      recipientDoc.customerId = recipientCustomerId;
    }
    tx.set(recipientTxRef, recipientDoc);
  }

  async applyPendingGifts(newUserId: string, email: string): Promise<void> {
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const snap = await firestore
      .collection("transactions")
      .where("type", "==", "gift")
      .where("recipientEmail", "==", email.toLowerCase())
      .where("createdAt", ">=", thirtyDaysAgo)
      .get();

    const pending = snap.docs.filter(
      (d) => d.data().recipientCustomerId === null,
    );
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
        tx.update(doc.ref, {
          recipientCustomerId: newUserId,
          customerId: newUserId,
          status: "claimed",
        });
      }
    });
  }

  async findRefundByOriginalTransactionNumber(
    originalTransactionNumber: string,
  ): Promise<Record<string, any> | null> {
    const snap = await firestore
      .collection("transactions")
      .where("originalTransactionNumber", "==", originalTransactionNumber)
      .where("type", "==", "refund")
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].data();
  }

  async createRefundTransaction({
    customerId,
    originalTransactionNumber,
    amount,
    storeInvoiceText,
    storeId,
    transactionNumber,
  }: {
    customerId: string;
    originalTransactionNumber: string;
    amount: number;
    storeInvoiceText?: string;
    storeId?: string;
    transactionNumber: string;
  }): Promise<string> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const refundRef = firestore.collection("transactions").doc();
    const now = new Date();

    await firestore.runTransaction(async (tx) => {
      const customerSnap = await tx.get(customerRef);
      const current = (customerSnap.data()?.creditAvailable ?? 0) as number;
      tx.set(
        customerRef,
        { creditAvailable: current + amount },
        { merge: true },
      );
      tx.set(refundRef, {
        docId: refundRef.id,
        customerId,
        originalTransactionNumber,
        amount,
        type: "refund",
        status: "approved",
        paymentMethod: "coffixCredit",
        createdAt: now,
        transactionNumber,
        storeInvoiceText: storeInvoiceText ?? "",
        storeId: storeId ?? "",
      });
    });

    return refundRef.id;
  }

  async createManualTransaction({
    customerId,
    transactionType,
    paymentMethod,
    amount,
    transactionNumber,
    notes,
  }: {
    customerId: string;
    transactionType: "order" | "gift" | "refund";
    paymentMethod: "coffixCredit" | "cash";
    amount: number;
    transactionNumber: string;
    notes?: string;
  }): Promise<string> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const txRef = firestore.collection("transactions").doc();
    const now = new Date();

    const isCash = paymentMethod === "cash";
    const isGift =
      paymentMethod === "coffixCredit" && transactionType === "gift";

    // GST is recorded for all cash transactions.
    let gst = 0;
    let gstAmount = 0;
    if (isCash) {
      const global = await this.getGlobal();
      gst = (global.GST ?? 0) as number;
      gstAmount = amount - amount / (1 + gst / 100);
    }

    // For a manual gift, the userId is the recipient. Resolve their name,
    // email and preferred-store context so the written doc matches the shape
    // of a received gift (see createGiftTransaction). No sender / no
    // deduction — this is a system gift.
    let recipientFullName = "";
    let recipientEmail = "";
    if (isGift) {
      const userDoc = await this.findUserByCustomerId(customerId);
      recipientFullName =
        [userDoc?.firstName, userDoc?.lastName].filter(Boolean).join(" ") || "";
      recipientEmail = (userDoc?.email ?? "") as string;
    }

    // creditAvailable delta:
    //   order/coffixCredit  => -amount (deduct)
    //   gift/coffixCredit   => +amount (add to recipient userId)
    //   refund/coffixCredit => +amount (add)
    //   refund/cash         =>  0      (no credit movement)
    let delta = 0;
    if (paymentMethod === "coffixCredit") {
      delta = transactionType === "order" ? -amount : amount;
    }

    await firestore.runTransaction(async (tx) => {
      if (delta !== 0) {
        const snap = await tx.get(customerRef);
        const current = (snap.data()?.creditAvailable ?? 0) as number;
        tx.set(
          customerRef,
          { creditAvailable: current + delta },
          { merge: true },
        );
      }

      if (isGift) {
        // Recipient-side gift doc, matching a received gift's shape.
        tx.set(txRef, {
          docId: txRef.id,
          type: "gift",
          paymentMethod: "coffixCredit",
          role: "recipient",
          status: "claimed",
          customerId,
          recipientCustomerId: customerId,
          recipientEmail: recipientEmail.toLowerCase(),
          recipientFullName,
          senderFullName: "Administrator",
          senderEmail: "admin@coffix.co.nz",
          amount,
          transactionNumber,
          createdAt: now,
          notes: notes ?? "",
          isManual: true,
        });
        return;
      }

      tx.set(txRef, {
        docId: txRef.id,
        customerId,
        amount,
        type: transactionType,
        paymentMethod,
        status: "approved",
        createdAt: now,
        transactionNumber,
        notes: notes ?? "",
        isManual: true,
        ...(isCash ? { gst, gstAmount } : {}),
      });
    });

    return txRef.id;
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

  /**
   * Marks any still-pending card transactions whose payment session has lapsed
   * as "expired". A transaction is eligible when its status is "created" and its
   * expiresAt is at or before now. Only card/order transactions carry an
   * expiresAt, so coffixCredit (status "approved") and topup transactions are
   * naturally excluded.
   */
  async expireTransactions(): Promise<{ expiredCount: number }> {
    const now = new Date();
    const snap = await firestore
      .collection("transactions")
      .where("status", "==", "created")
      .where("expiresAt", "<=", now)
      .get();

    if (snap.empty) return { expiredCount: 0 };

    // Chunk writes to stay under Firestore's 500-write-per-batch limit.
    const CHUNK_SIZE = 450;
    let expiredCount = 0;

    for (let i = 0; i < snap.docs.length; i += CHUNK_SIZE) {
      const chunk = snap.docs.slice(i, i + CHUNK_SIZE);
      const batch = firestore.batch();
      for (const doc of chunk) {
        batch.update(doc.ref, { status: "expired" });
      }
      await batch.commit();
      expiredCount += chunk.length;
    }

    return { expiredCount };
  }
}

export default FirebaseService;
