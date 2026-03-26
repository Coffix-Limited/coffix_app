import { firestore, printerFirestore } from "../config/firebaseAdmin";
import { generateOrderNumber } from "../utils/generate_order_number";
import { createOrderBodySchema, CreateOrderBodySchema } from "./schema";
import { InsufficientCreditError } from "../coffixCredit/service";
import { scheduledAtNZ } from "../utils/nz_time";

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
    if (!storeDoc) throw new Error(`Store not found: ${validation.data.storeId}`);

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
      items: validation.data.items,
      createdAt: new Date(),
      status: "pending_payment",
      duration: validation.data.duration,
      paymentMethod: validation.data.paymentMethod,
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
  }: {
    customerId: string;
    orderId: string;
    amount: number;
    sessionId: string;
  }): Promise<string> {
    const transactionRef = firestore.collection("transactions").doc();
    await transactionRef.set({
      docId: transactionRef.id,
      customerId,
      orderId,
      amount,
      status: "created",
      createdAt: new Date(),
      sessionId,
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
  }: {
    customerId: string;
    amount: number;
    sessionId: string;
  }): Promise<string> {
    const transactionRef = firestore.collection("transactions").doc();
    await transactionRef.set({
      docId: transactionRef.id,
      customerId,
      amount,
      status: "created",
      createdAt: new Date(),
      sessionId,
      type: "topup",
    });
    return transactionRef.id;
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

  async findStoreByStoreId(storeId: string) {
    const storeRef = await firestore.collection("stores").doc(storeId).get();
    if (!storeRef.exists) {
      return null;
    }
    return storeRef.data();
  }

  async findUserByCustomerId(customerId: string) {
    const userRef = await firestore
      .collection("customers")
      .doc(customerId)
      .get();
    if (!userRef.exists) {
      return null;
    }
    return userRef.data();
  }
}

export default FirebaseService;
