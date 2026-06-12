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

  /**
   * Returns the list of sign-in provider IDs linked to the account for this
   * email (e.g. ["password", "google.com"]). Empty array when no account
   * exists. Lets the client distinguish an SSO-only account from a genuine
   * password typo.
   */
  async getProvidersForEmail({ email }: { email: string }): Promise<string[]> {
    try {
      const user = await getAuth().getUserByEmail(email);
      return user.providerData.map((p) => p.providerId);
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        return [];
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

  async generateResetToken({
    email,
  }: {
    email: string;
  }): Promise<string | null> {
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

  async verifyResetToken(
    token: string,
  ): Promise<
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

    // Federated providers (e.g. google.com, apple.com) resolve a future SSO
    // sign-in back to this uid. Unlink them so the next sign-in with the same
    // provider creates a brand-new account, mirroring how a freed email lets a
    // password account re-register. The "password" provider is kept so the
    // disabled+obfuscated record stays intact for audit.
    const providersToUnlink = user.providerData
      .map((p) => p.providerId)
      .filter((providerId) => providerId !== "password");

    await getAuth().updateUser(uid, { disabled: true, email: obfuscatedEmail });

    if (providersToUnlink.length > 0) {
      await getAuth().updateUser(uid, { providersToUnlink });
    }

    await firestore
      .collection("customers")
      .doc(uid)
      .set({ email: obfuscatedEmail, disabled: true }, { merge: true });
  }
}
