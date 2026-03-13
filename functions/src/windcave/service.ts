import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import {
  WINDCAVE_CANCELLED_URL,
  WINDCAVE_FAILED_URL,
  WINDCAVE_SUCCESS_URL,
} from "../constant/constant";
import { Product } from "../firebase/interface";
import { WindcaveError } from "../utils/windcave.error";

function getWindcaveApiSecret(
  windcaveApiUsername: string,
  windcaveApiKey: string,
) {
  return Buffer.from(`${windcaveApiUsername}:${windcaveApiKey}`).toString(
    "base64",
  );
}

export class WindcaveService {
  private readonly windcaveApiKey: string;
  private readonly windcaveApiUrl: string;
  private readonly windcaveApiUsername: string;
  private readonly windcaveApiSecret: string;

  constructor() {
    this.windcaveApiKey = process.env.WINDCAVE_API_KEY ?? "";
    this.windcaveApiUrl = process.env.WINDCAVE_API_BASE_URL ?? "";
    this.windcaveApiUsername = process.env.WINDCAVE_API_USERNAME ?? "";

    this.windcaveApiSecret = getWindcaveApiSecret(
      this.windcaveApiUsername,
      this.windcaveApiKey,
    );
    if (
      !this.windcaveApiUsername ||
      !this.windcaveApiKey ||
      !this.windcaveApiUrl
    ) {
      throw new Error("Missing Windcave API credentials");
    }
  }

  /**
   * Create a payment session with Windcave
   * @param amount - The amount to charge the customer
   *
   * @returns - The URL to redirect the customer to for payment
   */
  async createPaymentSession({
    amount,
    orderId,
    customerEmail,
  }: {
    amount: number;
    orderId: string;
    customerEmail: string;
  }) {
    const response = await fetch(`${this.windcaveApiUrl}/api/v1/sessions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${this.windcaveApiSecret}`,
      },
      body: JSON.stringify({
        amount: amount,
        currency: "NZD",
        merchantReference: orderId,
        type: "purchase",
        callbackUrls: {
          approved: WINDCAVE_SUCCESS_URL,
          declined: WINDCAVE_FAILED_URL,
          cancelled: WINDCAVE_CANCELLED_URL,
        },
        notificationUrl: `${process.env.BASE_URL}/webhook`,
        customer: {
          email: customerEmail,
        },
      }),
    });

    const responseData = await response.json();
    if (!response.ok) {
      throw new WindcaveError(response.status, responseData);
    }

    const hppLink = responseData.links.find((link: any) => link.rel === "hpp");
    if (!hppLink) {
      throw new WindcaveError(
        response.status,
        responseData,
        "HPP link not found",
      );
    }
    return {
      paymentSessionUrl: hppLink.href,
      sessionId: responseData.id,
    };
  }

  async computeOrderTotal({
    items,
  }: {
    items: Array<{
      productId: string;
      quantity: number;
      selectedModifiers: Record<string, string>;
    }>;
  }) {
    let total = 0;

    for (const item of items) {
      if (item.quantity <= 0) {
        throw new Error("Quantity must be greater than 0");
      }

      // 1. Fetch product
      const productSnap = await firestore
        .collection("products")
        .doc(item.productId)
        .get();
      if (!productSnap.exists) {
        throw new Error("Product not found");
      }

      const product = productSnap.data() as Product;
      const basePrice = product.price;
      logger.info("Product:", product);

      // OPTIONAL: validate product availability for store here if you store that on product
      // e.g. productData.availableToStores includes storeId

      // 2) Validate modifier groups are allowed by the product
      // This depends on how you store it. If productData.modifiers is list of allowed group IDs/codes:
      //   const allowedGroups = new Set<string>(productData.modifiers ?? []);
      //   for (const groupId of Object.keys(item.selectedModifiers ?? {})) {
      //     if (allowedGroups.size > 0 && !allowedGroups.has(groupId)) {
      //       throw new Error(
      //         `Modifier group not allowed for product ${item.productId}: ${groupId}`,
      //       );
      //     }
      //   }

      // 3. Fetch modifiers selected by the customer (batched)
      const modifierIds = Object.values(item.selectedModifiers ?? {}).filter(
        Boolean,
      );

      console.log(modifierIds);

      let extra = 0;

      if (modifierIds.length > 0) {
        // Firestore "in" supports up to 10 values
        // If you can exceed 10, chunk it
        const chunks: string[][] = [];
        for (let i = 0; i < modifierIds.length; i += 10) {
          chunks.push(modifierIds.slice(i, i + 10));
        }

        console.log("Chunks", chunks);

        const modifierDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];

        for (const chunk of chunks) {
          const qSnap = await firestore
            .collection("modifiers")
            .where("docId", "in", chunk)
            .get();

          modifierDocs.push(...qSnap.docs);
        }

        // 4. Validate all requested modifier IDs exist
        const found = new Map(
          modifierDocs.map((doc) => [doc.id, doc.data() as any]),
        );
        for (const modifierId of modifierIds) {
          if (!found.has(modifierId)) {
            throw new Error(`Modifier not found: ${modifierId}`);
          }
        }

        console.log("Found", found);

        // 5. Validate each modifier matched the group it claims to be in
        for (const [groupId, modifierId] of Object.entries(
          item.selectedModifiers ?? {},
        )) {
          const m = found.get(modifierId);
          const mGroupdId = String(m.modifierGroupIds ?? "");
          if (mGroupdId && groupId && mGroupdId !== groupId) {
            throw new Error(
              `Modifier ${modifierId} does not match group ${groupId}`,
            );
          }

          const extraPrice = Number(m.priceDelta ?? 0);
          if (!Number.isFinite(extraPrice)) {
            throw new Error(`Invalid modifier price: ${modifierId}`);
          }

          extra += extraPrice;
        }

        logger.info("Extra:", extra);
      }

      // 6. Line total
      const unitPrice = basePrice + extra;
      const lineTotal = unitPrice * item.quantity;

      total += lineTotal;
    }
    return total;
  }

  async getSession(sessionId: string) {
    const response = await fetch(
      `${this.windcaveApiUrl}/api/v1/sessions/${sessionId}`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${this.windcaveApiSecret}`,
        },
      },
    );
    if (!response.ok) {
      throw new Error(`Failed to get session: ${response.statusText}`);
    }
    return response.json();
  }
}
