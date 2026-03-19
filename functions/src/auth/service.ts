import { getAuth } from "firebase-admin/auth";
import { firestore } from "../config/firebaseAdmin";
import { logger } from "firebase-functions/v1";

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
}
