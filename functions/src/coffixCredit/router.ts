import express, { Response } from "express";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { requirePost } from "../middleware/method";
import { topupBodySchema } from "./schema";
import FirebaseService from "../firebase/service";
import { WindcaveService } from "../windcave/service";
import { WindcaveError } from "../utils/windcave.error";
import { logger } from "firebase-functions";
import { getTopupMerchantReference } from "./utils";

const router = express.Router();

router.post(
  "/topup",
  requirePost,
  requiredAuth,
  async (request: AuthenticatedRequest, response: Response) => {
    const customerId = request.user?.uid;
    if (!customerId) {
      return response
        .status(401)
        .json({ success: false, message: "Unauthorized" });
    }

    const firebaseService = new FirebaseService();
    const windcaveService = new WindcaveService();

    try {
      const validation = topupBodySchema.safeParse(request.body);
      if (!validation.success) {
        const errors = validation.error.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join(", ");
        return response.status(400).json({ success: false, errors });
      }

      const userDoc = await firebaseService.findUserByCustomerId(customerId);
      if (!userDoc) {
        return response
          .status(401)
          .json({ success: false, message: "Unauthorized" });
      }

      const { amount } = validation.data;
      const merchantReference = getTopupMerchantReference(customerId);

      const { paymentSessionUrl, sessionId } =
        await windcaveService.createPaymentSession({
          amount,
          orderId: merchantReference,
          userDoc: userDoc,
        });

      await firebaseService.createTopupTransaction({
        customerId,
        amount,
        sessionId,
      });

      return response.status(200).json({
        success: true,
        data: { paymentSessionUrl },
      });
    } catch (error) {
      if (error instanceof WindcaveError) {
        return response
          .status(error.status)
          .json({ success: false, message: error.message, data: error.data });
      }
      logger.error("Error creating topup session:", error);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

// router.post(
//   "/share",
//   requiredAuth,
//   requirePost,
//   async (request: AuthenticatedRequest, response: Response) => {
//     const customerId = request.user?.uid;
//     if (!customerId) {
//       return response
//         .status(401)
//         .json({ success: false, message: "Unauthorized" });
//     }
//   },
// );

export default router;
