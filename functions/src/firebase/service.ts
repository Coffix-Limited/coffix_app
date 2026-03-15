import { firestore, printerFirestore } from "../config/firebaseAdmin";
import { generateOrderNumber } from "../utils/generate_order_number";
import { createOrderBodySchema, CreateOrderBodySchema } from "./schema";

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

  async createNewOrder(body: CreateOrderBodySchema): Promise<string> {
    const validation = createOrderBodySchema.safeParse(body);
    if (!validation.success) {
      throw new Error("Invalid body");
    }
    const orderRef = firestore.collection("orders").doc();
    // [StoreCode][YYMMDD][RunningNumber]
    const orderNumber = await generateOrderNumber(validation.data.storeId);
    await orderRef.set({
      docId: orderRef.id,
      orderNumber,
      amount: validation.data.amount,
      customerId: validation.data.customerId,
      storeId: validation.data.storeId,
      items: validation.data.items,
      createdAt: new Date(),
      status: "pending_payment",
      duration: validation.data.duration,
      paymentMethod: validation.data.paymentMethod,
    });

    return orderRef.id;
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
}

export default FirebaseService;
