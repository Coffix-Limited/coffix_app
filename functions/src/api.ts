import express from "express";
import { otpRouter } from "./otp/router";
import windcaveRouter from "./windcave/router";
import firebaseRouter from "./firebase/router";
import webhookRouter from "./webhook/router";
import coffixCreditRouter from "./coffixCredit/router";
import authRouter from "./auth/route";
import orderRouter from "./order/router";

export const api = express();
// Global middleware
api.use(express.json());

api.use("/hello-world", (request, response) => {
  response.send("Hello World");
});

// Mount routers
api.use("/otp", otpRouter);
api.use("/payment", windcaveRouter);
api.use("/firebase", firebaseRouter);
api.use("/webhook", webhookRouter);
api.use("/credit", coffixCreditRouter);
api.use("/auth", authRouter);
api.use("/order", orderRouter);
