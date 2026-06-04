import express, { Request, Response } from "express";
import { z } from "zod";
import { requirePost } from "../middleware/method";
import createLogSchema from "./schema";
import { LogService } from "./service";
import { logger } from "firebase-functions";

const router = express.Router();
const logService = new LogService();

router.post(
  "/create",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = createLogSchema.safeParse(request.body);
    logger.info(validation.data);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      await logService.log(validation.data);

      return response.status(200).json({ success: true });
    } catch (e) {
      logger.error("[log/create] error:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
