export interface OTP {
  docId: string;
  type?: "emailOtp" | "forgotPassword";
  otp?: string;
  token?: string;
  status: "pending" | "verified" | "superseded";
  createdAt: Date;
  expirationDate: Date;
  to: string;
  userId: string;
}
