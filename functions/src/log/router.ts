import express, { Request, Response } from "express";
import { z } from "zod";
import { requirePost } from "../middleware/method";
import createLogSchema from "./schema";
import { LogService } from "./service";

const router = express.Router();
const logService = new LogService();

router.post(
  "/create",
  requirePost,
  async (request: Request, response: Response) => {
    const validation = createLogSchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    try {
      await logService.log({
        ...validation.data,
        time: new Date(),
      });

      return response.status(200).json({ success: true });
    } catch (e) {
      console.error("[log/create] error:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error" });
    }
  },
);

export default router;
