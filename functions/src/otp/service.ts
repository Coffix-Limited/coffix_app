import { firestore } from "../config/firebaseAdmin";
import * as admin from "firebase-admin";
import { OTP } from "./interface";

export async function createOTPDocumentWithTransaction({
  transaction,
  otp,
  to,
  userId,
}: {
  transaction: admin.firestore.Transaction;
  otp: string;
  to: string;
  userId: string;
}): Promise<OTP> {
  const otpRef = firestore.collection("otp").doc();
  const otpRefId = otpRef.id;

  const otpDocument: OTP = {
    docId: otpRefId,
    otp: otp,
    status: "pending",
    createdAt: new Date(),
    expirationDate: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
    to: to,
    userId: userId,
  };

  transaction.set(otpRef, otpDocument);

  return otpDocument;
}
