import { firestore } from "../config/firebaseAdmin";
import { GLOBAL_COLLECTION_LOG_ID } from "../constant/constant";
import { Log } from "./interface";
import { LogSettings } from "./log_settings/interface";

export class LogService {
  async getLogSettings(): Promise<LogSettings | null> {
    const snap = await firestore
      .collection("global")
      .doc(GLOBAL_COLLECTION_LOG_ID)
      .get();
    if (!snap.exists) return null;
    return snap.data() as LogSettings;
  }

  /**
   * Deletes logs older than `retentionDays` whose `severityLevel` is in `levels`,
   * based on the LogSettings document. The website edits the settings doc directly
   * in Firestore; this runs from a cron to enforce the retention policy.
   */
  async cleanupLogs(): Promise<{ deletedCount: number; skipped?: string }> {
    const settings = await this.getLogSettings();

    if (!settings) return { deletedCount: 0, skipped: "no settings" };
    if (settings.enabled === false)
      return { deletedCount: 0, skipped: "disabled" };
    if (!settings.levels || settings.levels.length === 0)
      return { deletedCount: 0, skipped: "no levels" };
    if (!settings.retentionDays || settings.retentionDays <= 0)
      return { deletedCount: 0, skipped: "invalid retentionDays" };

    const cutoff = new Date(
      Date.now() - settings.retentionDays * 24 * 60 * 60 * 1000,
    );

    // Chunk writes to stay under Firestore's 500-write-per-batch limit.
    const CHUNK_SIZE = 450;
    let deletedCount = 0;

    for (const level of settings.levels) {
      const snap = await firestore
        .collection("logs")
        .where("severityLevel", "==", level)
        .where("time", "<", cutoff)
        .get();

      for (let i = 0; i < snap.docs.length; i += CHUNK_SIZE) {
        const chunk = snap.docs.slice(i, i + CHUNK_SIZE);
        const batch = firestore.batch();
        for (const doc of chunk) {
          batch.delete(doc.ref);
        }
        await batch.commit();
        deletedCount += chunk.length;
      }
    }

    return { deletedCount };
  }

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
