import { firestore } from "../config/firebaseAdmin";

export class InsufficientCreditError extends Error {
  constructor(
    public creditAvailable: number,
    public required: number,
  ) {
    super(
      `Insufficient credit. Available: ${creditAvailable}, required: ${required}`,
    );
  }
}

export class CoffixCreditService {
  async getCreditAvailable(customerId: string): Promise<number> {
    const snap = await firestore.collection("customers").doc(customerId).get();
    if (!snap.exists) return 0;
    return (snap.data()?.creditAvailable ?? 0) as number;
  }

  async deductCredit(customerId: string, amount: number): Promise<void> {
    const customerRef = firestore.collection("customers").doc(customerId);

    await firestore.runTransaction(async (tx) => {
      const customerSnap = await tx.get(customerRef);
      if (!customerSnap.exists) {
        throw new Error("Customer not found");
      }

      const data = customerSnap.data();
      const creditAvailable = (data?.creditAvailable ?? 0) as number;

      if (creditAvailable < amount) {
        throw new InsufficientCreditError(creditAvailable, amount);
      }

      tx.update(customerRef, {
        creditAvailable: creditAvailable - amount,
      });
    });
  }

  async addCredit(customerId: string, amount: number): Promise<void> {
    const customerRef = firestore.collection("customers").doc(customerId);
    const globals = await firestore
      .collection("global")
      .doc("EQ0i4V6H47Ra7yMCdG7B")
      .get();
    if (!globals.exists) {
      throw new Error("Global not found");
    }
    const globalData = globals.data();
    if (!globalData) {
      throw new Error("Global data not found");
    }

    const minTopUp = (globalData.minTopUp ?? 0) as number;
    const basicDiscount = (globalData.basicDiscount ?? 0) as number;
    const discountLevel2 = (globalData.discountLevel2 ?? 0) as number;
    const discountLevel3 = (globalData.discountLevel3 ?? 0) as number;
    const topupLevel2 = (globalData.topupLevel2 ?? Infinity) as number;
    const topupLevel3 = (globalData.topupLevel3 ?? Infinity) as number;

    if (amount < minTopUp) {
      throw new Error(`Top-up amount is below the minimum of ${minTopUp}`);
    }

    let bonus: number;
    if (amount < topupLevel2) {
      bonus = amount * basicDiscount;
    } else if (amount < topupLevel3) {
      bonus = amount * discountLevel2;
    } else {
      bonus = amount * discountLevel3;
    }
    const totalAmount = amount + bonus;

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
    });
  }
}
