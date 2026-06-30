import express from "express";
import { requirePost } from "../middleware/method";
import { AuthenticatedRequest, requiredAuth } from "../middleware/auth";
import { logger } from "firebase-functions/v1";
import { CouponService } from "./service";
import { EmailService } from "../email/service";
import { createCouponSchema } from "./schema";

const couponRouter = express.Router();
couponRouter.use(express.json());

couponRouter.post(
  "/",
  requirePost,
  //   requiredAuth,
  async (request: AuthenticatedRequest, response) => {
    const validation = createCouponSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    const { type, amount, expiryDate, storeId, notes, customerEmail } =
      validation.data;

    try {
      const couponService = new CouponService();
      const emailService = new EmailService();

      const docIds = await Promise.all(
        customerEmail.map(async (email) => {
          const coupon = await couponService.createCoupon({
            type,
            amount,
            expiryDate,
            storeId,
            notes,
            customerEmail: email,
          });
          await emailService.sendCouponEmail({
            to: email,
            amount,
            expiryDate,
          });
          return coupon.docId;
        }),
      );

      return response.status(200).json({
        success: true,
        message: "Coupon(s) created",
        data: { docIds },
      });
    } catch (e) {
      logger.error("Error creating coupon:", e);
      return response.status(500).json({
        success: false,
        message: "Internal server error",
        error: e,
      });
    }
  },
);

export default couponRouter;
