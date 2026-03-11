import express from "express";
import { requirePost } from "../middleware/method";
import { customerHasAccountSchema } from "./schema";
import { AuthService } from "./service";

const router = express.Router();

router.post("/verify", requirePost, async (request, response) => {
  try {
    const validation = customerHasAccountSchema.safeParse(request.body);

    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    const { email } = validation.data;
    const hasAccount = await new AuthService().customerHasAccount({ email });
    return response.status(200).json({
      success: true,
      data: {
        hasAccount,
      },
    });
  } catch (error) {
    console.error("Error checking if customer has account:", error);
    return response
      .status(500)
      .json({ success: false, message: "Internal server error" });
  }
});

export default router;
