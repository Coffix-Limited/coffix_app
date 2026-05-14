import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import {
  WINDCAVE_CANCELLED_URL,
  WINDCAVE_FAILED_URL,
  WINDCAVE_SUCCESS_URL,
} from "../constant/constant";
import {
  EnrichedOrderItem,
  Product,
  SnapshotModifier,
} from "../firebase/interface";
import { WindcaveError } from "../utils/windcave.error";
import { DocumentData } from "firebase-admin/firestore";

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
    merchantReference,
    userDoc,
  }: {
    amount: number;
    merchantReference: string;
    userDoc: DocumentData;
  }) {
    const customerEmail = userDoc.email;
    const firstName = userDoc.firstName;
    const lastName = userDoc.lastName;
    const response = await fetch(`${this.windcaveApiUrl}/api/v1/sessions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Basic ${this.windcaveApiSecret}`,
      },
      body: JSON.stringify({
        amount: amount,
        currency: "NZD",
        // MERCHANT REFERENCE IF TOPUP: topup:<customerId>
        // MERCHANT REFERENCE IF ORDER: order:<customerId>:<orderId>
        merchantReference: merchantReference,
        type: "purchase",
        callbackUrls: {
          approved: WINDCAVE_SUCCESS_URL,
          declined: WINDCAVE_FAILED_URL,
          cancelled: WINDCAVE_CANCELLED_URL,
        },
        notificationUrl: `${process.env.BASE_URL}/webhook`,
        customer: {
          firstName: firstName ?? "",
          lastName: lastName ?? "",
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
  }): Promise<{ total: number; enrichedItems: EnrichedOrderItem[] }> {
    const results = await Promise.all(
      items.map(async (item) => {
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

        // 2. Fetch modifiers selected by the customer (batched, parallel chunks)
        const modifierIds = Object.values(item.selectedModifiers ?? {}).filter(
          Boolean,
        );

        let extra = 0;
        let found = new Map<string, any>();

        if (modifierIds.length > 0) {
          const chunks: string[][] = [];
          for (let i = 0; i < modifierIds.length; i += 10) {
            chunks.push(modifierIds.slice(i, i + 10));
          }

          const chunkSnaps = await Promise.all(
            chunks.map((chunk) =>
              firestore
                .collection("modifiers")
                .where("docId", "in", chunk)
                .get(),
            ),
          );

          const modifierDocs = chunkSnaps.flatMap((snap) => snap.docs);

          // 3. Validate all requested modifier IDs exist
          found = new Map(
            modifierDocs.map((doc) => [doc.id, doc.data() as any]),
          );
          for (const modifierId of modifierIds) {
            if (!found.has(modifierId)) {
              throw new Error(`Modifier not found: ${modifierId}`);
            }
          }

          // 4. Validate each modifier matched the group it claims to be in
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

        // 5. Line total
        const unitPrice = basePrice + extra;

        const modifiersSnapshot: SnapshotModifier[] = Object.entries(
          item.selectedModifiers ?? {},
        ).map(([_groupId, modifierId]) => {
          const m = found.get(modifierId);
          return {
            modifierId,
            name: m?.label ?? "",
            priceDelta: Number(m?.priceDelta ?? 0),
          };
        });

        const enrichedItem: EnrichedOrderItem = {
          productId: item.productId,
          productName: product.name,
          productImageUrl: product.imageUrl,
          price: unitPrice,
          basePrice: basePrice,
          quantity: item.quantity,
          selectedModifiers: item.selectedModifiers,
          modifiers: modifiersSnapshot,
        };

        return { lineTotal: unitPrice * item.quantity, enrichedItem };
      }),
    );

    const total = results.reduce((sum, r) => sum + r.lineTotal, 0);
    const enrichedItems = results.map((r) => r.enrichedItem);
    return { total, enrichedItems };
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

    const data = await response.json();
    logger.info("Response:", data);
    return data;
  }
}
