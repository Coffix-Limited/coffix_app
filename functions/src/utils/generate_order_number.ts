import { firestore } from "../config/firebaseAdmin";
import { nzDateKey } from "./nz_time";

// Format: {storeId}{YYMMDD}{runningNumber} e.g. {atdqdUXR8HQjRyBUJjEx}{260224}{000001}
export async function generateOrderNumber(storeId: string): Promise<string> {
  const dateKey = nzDateKey();

  return await firestore.runTransaction(async (tx) => {
    const counterRef = firestore
      .collection("stores")
      .doc(storeId)
      .collection("dailyCounters")
      .doc(dateKey);

    const counterSnap = await tx.get(counterRef);

    let nextNumber = 1;
    if (counterSnap.exists) {
      nextNumber = (counterSnap.data()?.lastRunningNumber ?? 0) + 1;
    }

    tx.set(counterRef, { lastRunningNumber: nextNumber }, { merge: true });

    const runningNumber = nextNumber.toString().padStart(6, "0");
    return `${storeId}${dateKey}${runningNumber}`;
  });
}
