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

  private calculateTopUp(amount: number): number {
    let totalAmount = amount;

    if (amount < 50) {
      return totalAmount;
    } else if (amount <= 250) {
      totalAmount += amount * 0.1;
    } else if (amount <= 500) {
      totalAmount += amount * 0.15;
    } else {
      totalAmount += amount * 0.2;
    }

    return totalAmount;
  }

  async addCredit(customerId: string, amount: number): Promise<void> {
    const customerRef = firestore.collection("customers").doc(customerId);

    await firestore.runTransaction(async (tx) => {
      const customerSnap = await tx.get(customerRef);
      const current = customerSnap.exists
        ? ((customerSnap.data()?.creditAvailable ?? 0) as number)
        : 0;

      const totalAmount = this.calculateTopUp(amount);
      tx.set(
        customerRef,
        { creditAvailable: current + totalAmount },
        { merge: true },
      );
    });
  }
}
