import { printerFirestore } from "../config/firebaseAdmin";
import { createReceiptBodySchema, CreateReceiptBodySchema } from "./schema";
import { nowNZ } from "../utils/nz_time";

export class ReceiptService {
  // create a print document to the printer database
  async createPrintQueue({
    receiptData,
  }: {
    receiptData: CreateReceiptBodySchema;
  }) {
    const validation = createReceiptBodySchema.safeParse(receiptData);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      throw new Error(errors);
    }
    const printQueueRef = printerFirestore.collection("printQueue").doc();
    const orderNumber = validation.data.orderNumber.substring(
      validation.data.orderNumber.length - 6,
      validation.data.orderNumber.length,
    );

    const now = nowNZ();
    const { duration } = validation.data;
    const printTime =
      duration > 0 ? new Date(Date.now() + duration * 60_000) : null;
    const gst = validation.data.total * 0.15;
    await printQueueRef.set({
      printerId: "TRY",
      status: duration > 0 ? "scheduled" : "pending",
      printTime,
      lines: [
        validation.data.storeName,
        validation.data.storeAddress,
        "GST",
        `Order #${orderNumber}`,
        "",
        validation.data.orders,
        `Total: $${validation.data.total.toFixed(2)}`,
        `15% GST Included in the total: $${gst.toFixed(2)}`,
        "",
        "Paid by: Credit Card...",
        `Customer: ${validation.data.customer}`,
        // format it 'MM.dd.yyyy HH:mm aa'
        `Time: ${printTime ? printTime.toLocaleString("en-NZ", { timeZone: "Pacific/Auckland", month: "2-digit", day: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit", hour12: true }) : now}`,
        `By: ${validation.data.baristaName}`,
        "coffix.co.nz",
      ],
    });
  }
}
