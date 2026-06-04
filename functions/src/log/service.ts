import { firestore } from "../config/firebaseAdmin";
import { Log } from "./interface";

export class LogService {
  async log(log: Log): Promise<Log> {
    const logDocRef = firestore.collection("logs").doc();

    const logDoc: Log = {
      ...log,
      docId: logDocRef.id,
      time: new Date(),
    };

    await logDocRef.set(logDoc);

    return logDoc;
  }

  // AUTH
  async otp(customerId: string, email: string, otp: string) {
    const log: Log = {
      action: "otp",
      category: "API",
      severityLevel: 1,
      notes: `OTP sent to ${email} with OTP ${otp}`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async verifyOtpSuccess(customerId: string, email: string) {
    const log: Log = {
      action: "verifyOtp",
      category: "API",
      severityLevel: 1,
      notes: `OTP verified successfully for ${email}`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async verifyOtpFailed(customerId: string) {
    const log: Log = {
      action: "verifyOtp",
      category: "API",
      severityLevel: 3,
      notes: `OTP verification failed`,
      customerId: customerId,
    };
    await this.log(log);
  }

  // PAYMENT
  async createTopUpPaymentSessionSuccess(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 5,
      notes: `Payment session created for topup successfully with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async createOrderPaymentSessionSuccess(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 5,
      notes: `Payment session created for order successfully with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async createPaymentSessionFailed(customerId: string) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 3,
      notes: `Payment session failed for ${customerId}`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async handleTopUpPaymentSuccess(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 5,
      notes: `Topup payment successful with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async handleTopUpPaymentFailed(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 3,
      notes: `Topup payment failed with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async handleOrderPaymentSuccess(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 5,
      notes: `Order payment successful with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }

  async handleOrderPaymentFailed(customerId: string, amount: number) {
    const log: Log = {
      action: "payment",
      category: "API",
      severityLevel: 3,
      notes: `Order payment failed with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }
  // TRANSACTIONS
  async createTransactionSuccess(customerId: string, amount: number) {
    const log: Log = {
      action: "transaction",
      category: "API",
      severityLevel: 5,
      notes: `Transaction created and approved with amount ${amount} NZD`,
      customerId: customerId,
    };
    await this.log(log);
  }
}
