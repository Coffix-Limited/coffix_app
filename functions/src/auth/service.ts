import * as crypto from "crypto";
import { getAuth } from "firebase-admin/auth";
import { firestore } from "../config/firebaseAdmin";
import { logger } from "firebase-functions/v1";
import { OTP } from "../otp/interface";

export class AuthService {
  async customerHasAccount({ email }: { email: string }) {
    try {
      // verify if the user is already registered
      const user = await getAuth().getUserByEmail(email);
      return !!user;
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        return false;
      }
      throw error;
    }
  }

  async blackListCustomer({ email }: { email: string }) {
    const blacklistedEmails = await firestore
      .collection("blacklistedEmails")
      .get();

    logger.info(`Checking if email ${email} is blacklisted`, {
      email,
      blacklistedEmails: blacklistedEmails.docs.map((doc) => doc.data().email),
    });
    return blacklistedEmails.docs.some((doc) => doc.data().email === email);
  }

  async generateResetToken({ email }: { email: string }): Promise<string | null> {
    try {
      const user = await getAuth().getUserByEmail(email);
      const token = crypto.randomBytes(32).toString("hex");
      const now = new Date();
      const ref = firestore.collection("otp").doc();
      const doc: OTP = {
        docId: ref.id,
        type: "forgotPassword",
        token,
        status: "pending",
        createdAt: now,
        expirationDate: new Date(now.getTime() + 60 * 60 * 1000),
        to: email,
        userId: user.uid,
      };
      await ref.set(doc);
      return token;
    } catch (error: any) {
      if (error.code === "auth/user-not-found") return null;
      throw error;
    }
  }

  async verifyResetToken(token: string): Promise<
    | { valid: true; uid: string; docId: string }
    | { valid: false; reason: "not_found" | "used" | "expired" }
  > {
    const snap = await firestore
      .collection("otp")
      .where("type", "==", "forgotPassword")
      .where("token", "==", token)
      .limit(1)
      .get();
    if (snap.empty) return { valid: false, reason: "not_found" };
    const doc = snap.docs[0];
    const data = doc.data() as OTP;
    if (data.status === "verified") return { valid: false, reason: "used" };
    const expiresAt: Date =
      typeof (data.expirationDate as any).toDate === "function"
        ? (data.expirationDate as any).toDate()
        : new Date(data.expirationDate);
    if (expiresAt < new Date()) return { valid: false, reason: "expired" };
    return { valid: true, uid: data.userId, docId: doc.id };
  }

  async consumeResetToken(docId: string): Promise<void> {
    await firestore.collection("otp").doc(docId).update({ status: "verified" });
  }

  async updatePassword(uid: string, password: string): Promise<void> {
    await getAuth().updateUser(uid, { password });
  }

  async deleteAccount(uid: string): Promise<void> {
    const user = await getAuth().getUser(uid);
    const originalEmail = user.email!;
    const now = new Date();
    const pad = (n: number) => String(n).padStart(2, "0");
    const timestamp =
      `${now.getUTCFullYear()}` +
      `${pad(now.getUTCMonth() + 1)}` +
      `${pad(now.getUTCDate())}` +
      `${pad(now.getUTCHours())}` +
      `${pad(now.getUTCMinutes())}` +
      `${pad(now.getUTCSeconds())}`;
    const obfuscatedEmail = `${timestamp}-${originalEmail}`;

    await getAuth().updateUser(uid, { disabled: true, email: obfuscatedEmail });

    await firestore
      .collection("customers")
      .doc(uid)
      .set({ email: obfuscatedEmail, disabled: true }, { merge: true });
  }
}
