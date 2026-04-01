import express, { Response } from "express";
import { requiredAuth, type AuthenticatedRequest } from "../middleware/auth";
import { requirePost } from "../middleware/method";
import { sendReceiptBodySchema } from "./schema";
import FirebaseService from "../firebase/service";
import { orderEmailTemplate } from "../utils/templates/order_email_template";
import { RESEND_FROM_EMAIL } from "../constant/constant";

const router = express.Router();

function formatCurrency(amount: number): string {
  return `$${amount.toFixed(2)}`;
}

function formatDate(value: any): string {
  try {
    const date: Date =
      value && typeof value.toDate === "function"
        ? value.toDate()
        : new Date(value);
    return date.toLocaleString("en-NZ", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    });
  } catch {
    return String(value);
  }
}

function buildItemRows(items: any[]): string {
  if (!Array.isArray(items) || items.length === 0) {
    return `<tr><td colspan="4" style="padding:12px 0;color:#888;font-size:14px;">No items</td></tr>`;
  }

  return items
    .map((item) => {
      const name = item.name ?? item.productName ?? "Item";
      const qty = item.quantity ?? item.qty ?? 1;
      const unitPrice = item.price ?? item.unitPrice ?? 0;
      const subtotal = qty * unitPrice;

      const modifiers: string[] = [];
      if (Array.isArray(item.modifiers)) {
        item.modifiers.forEach((mod: any) => {
          if (typeof mod === "string") modifiers.push(mod);
          else if (mod.name) modifiers.push(mod.name);
        });
      }
      const modifierHtml =
        modifiers.length > 0
          ? `<div class="item-modifiers">${modifiers.join(", ")}</div>`
          : "";

      return `
        <tr>
          <td>
            <div class="item-name">${name}</div>
            ${modifierHtml}
          </td>
          <td class="right">${qty}</td>
          <td class="right">${formatCurrency(unitPrice)}</td>
          <td class="right">${formatCurrency(subtotal)}</td>
        </tr>`;
    })
    .join("");
}

router.post(
  "/send-receipt",
  requiredAuth,
  requirePost,
  async (request: AuthenticatedRequest, response: Response) => {
    const customerId = request.user?.uid;
    if (!customerId) {
      return response
        .status(401)
        .json({ success: false, message: "Unauthorized" });
    }

    const validation = sendReceiptBodySchema.safeParse(request.body);
    if (!validation.success) {
      const errors = validation.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join(", ");
      return response.status(400).json({ success: false, errors });
    }

    const { orderId, email } = validation.data;

    try {
      const RESEND_API_KEY = process.env.RESEND_API_KEY;
      if (!RESEND_API_KEY) {
        return response.status(500).json({
          success: false,
          message: "Server email configuration missing",
        });
      }

      const firebaseService = new FirebaseService();
      const order = await firebaseService.findOrderByOrderId(orderId);

      if (!order) {
        return response
          .status(404)
          .json({ success: false, message: "Order not found" });
      }

      if (order.customerId !== customerId) {
        return response
          .status(403)
          .json({ success: false, message: "Forbidden" });
      }

      let html = orderEmailTemplate;

      const itemsHtml = buildItemRows(order.items ?? []);

      const rawOrderNumber: string = order.orderNumber ?? orderId;
      const shortOrderNumber = rawOrderNumber.substring(
        Math.max(0, rawOrderNumber.length - 6),
        rawOrderNumber.length,
      );

      html = html
        .replace(/{{orderNumber}}/g, shortOrderNumber)
        .replace(/{{storeName}}/g, String(order.storeName ?? ""))
        .replace(/{{storeAddress}}/g, String(order.storeAddress ?? ""))
        .replace(/{{createdAt}}/g, formatDate(order.createdAt))
        .replace(/{{total}}/g, formatCurrency(Number(order.amount ?? 0)))
        .replace(/{{paymentMethod}}/g, String(order.paymentMethod ?? ""))
        .replace(/{{items}}/g, itemsHtml);

      const orderNumber = rawOrderNumber;

      const resendRes = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          from: RESEND_FROM_EMAIL,
          to: [email],
          subject: `Your Coffix Order Receipt #${orderNumber}`,
          html,
        }),
      });

      const resendResult = await resendRes.json();

      if (!resendRes.ok) {
        console.error("Resend API error:", resendResult);
        return response
          .status(500)
          .json({ success: false, message: "Failed to send receipt email" });
      }

      return response
        .status(200)
        .json({ success: true, message: "Receipt sent" });
    } catch (e) {
      console.error("Error sending receipt:", e);
      return response
        .status(500)
        .json({ success: false, message: "Internal server error", error: e });
    }
  },
);

export default router;
