import express from "express";
import cors from "cors";
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
import transactionRouter from "./transaction/router";
import logRouter from "./log/router";
import backupRouter from "./backup/router";
import couponRouter from "./coupon/router";
import staffsRouter from "./staffs/router";
import importRouter from "./import/router";
import { globalLimiter } from "./middleware/rateLimiter";
import { app } from "firebase-functions";

export const api = express();

const allowedOrigins = [
  "https://dev.appmgr.coffix.co.nz",
  "https://appmgr.coffix.co.nz",
  "http://localhost:3000",
];

const corsOptions = {
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(null, false);
    }
  },
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true,
};

api.use(cors(corsOptions));

api.use(express.json());
api.use(globalLimiter);

api.use("/health", (request, response) => {
  response.send("OKKKKK!!");
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
api.use("/transaction", transactionRouter);
api.use("/log", logRouter);
api.use("/backup", backupRouter);
api.use("/coupon", couponRouter);
api.use("/staffs", staffsRouter);
api.use("/import", importRouter);
