import express from "express";
import { otpRouter } from "./otp/router";
import referralsRouter from "./referrals/router";
import windcaveRouter from "./windcave/router";
import firebaseRouter from "./firebase/router";
import webhookRouter from "./webhook/router";
import coffixCreditRouter from "./coffixCredit/router";
import authRouter from "./auth/route";
import orderRouter from "./order/router";
import notificationRouter from "./notification/router";
import emailRouter from "./email/router";
import { globalLimiter } from "./middleware/rateLimiter";

export const api = express();
// Global middleware
api.use(express.json());
api.use(globalLimiter);


api.use("/health", (request, response) => {
  response.send("OK");
});

// Mount routers
api.use("/otp", otpRouter);
api.use("/payment", windcaveRouter);
api.use("/firebase", firebaseRouter);
api.use("/webhook", webhookRouter);
api.use("/credit", coffixCreditRouter);
api.use("/auth", authRouter);
api.use("/order", orderRouter);
api.use("/notification", notificationRouter);
api.use("/referrals", referralsRouter);
api.use("/email", emailRouter);
