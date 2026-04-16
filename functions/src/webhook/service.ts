import FirebaseService from "../firebase/service";
import { WindcaveError } from "../utils/windcave.error";
import { WindcaveService } from "../windcave/service";
import { CoffixCreditService } from "../coffixCredit/service";
import {
  parseTopupMerchantReference,
  parseOrderMerchantReference,
  TOPUP_PREFIX,
} from "../coffixCredit/utils";
import { logger } from "firebase-functions";
import { ReceiptService } from "../receipt/service";
import { NotificationService } from "../notification/service";
import { ReferralService } from "../referrals/service";
import { firestore } from "../config/firebaseAdmin";
export class WebhookService {
  private readonly windcaveService: WindcaveService;
  private readonly firebaseService: FirebaseService;
  private readonly receiptService: ReceiptService;
  private readonly coffixCreditService: CoffixCreditService;
  private readonly notificationService: NotificationService;
  private readonly referralService: ReferralService;

  constructor() {
    this.windcaveService = new WindcaveService();
    this.firebaseService = new FirebaseService();
    this.coffixCreditService = new CoffixCreditService();
    this.receiptService = new ReceiptService();
    this.notificationService = new NotificationService();
    this.referralService = new ReferralService();
  }

  /**
   * This will verify if the webhook is valid and then update the order in the database
   * @param sessionId - The session ID to handle the webhook for
   */
  async handleWebhook(sessionId: string) {
    // 1) Query windcave session
    const windcaveSession = await this.windcaveService.getSession(sessionId);
    //   {
    //     "id": "0000050000173579050ea491c10a3e56",
    //     "state": "complete",
    //     "type": "purchase",
    //     "amount": "55.00",
    //     "currency": "NZD",
    //     "currencyNumeric": 554,
    //     "merchantReference": "topup:Fw02HJSXPygbhGViUudCjQTO04D3",
    //     "methods": [
    //         "card",
    //         "applepay"
    //     ],
    //     "expires": "2026-03-18T18:11:01Z",
    //     "callbackUrls": {
    //         "approved": "https://www.coffix.co.nz/payment/successful",
    //         "declined": "https://www.coffix.co.nz/payment/failed",
    //         "cancelled": "https://www.coffix.co.nz/payment/cancelled"
    //     },
    //     "notificationUrl": "https://doom-saint-away-cottage.trycloudflare.com/coffix-app-dev/us-central1/v1/webhook",
    //     "customer": {
    //         "firstName": "",
    //         "lastName": "",
    //         "email": "pajunar0@gmail.com",
    //         "phoneNumber": "",
    //         "homePhoneNumber": "",
    //         "account": ""
    //     },
    //     "storeCard": false,
    //     "clientType": "internet",
    //     "links": [
    //         {
    //             "href": "https://uat.windcave.com/api/v1/sessions/0000050000173579050ea491c10a3e56",
    //             "rel": "self",
    //             "method": "GET"
    //         },
    //         {
    //             "href": "https://uat.windcave.com/api/v1/transactions/00000005000b8ef8",
    //             "rel": "transaction",
    //             "method": "GET"
    //         }
    //     ],
    //     "transactions": [
    //         {
    //             "id": "00000005000b8ef8",
    //             "username": "MetroRetailLtd_dev",
    //             "authorised": true,
    //             "allowRetry": false,
    //             "retryIndicator": "",
    //             "reCo": "00",
    //             "responseText": "APPROVED",
    //             "authCode": "025485",
    //             "acquirer": {
    //                 "name": "Undefined",
    //                 "mid": "10000000",
    //                 "tid": "10001126",
    //                 "reCo": "00",
    //                 "responseText": "APPROVED"
    //             },
    //             "type": "purchase",
    //             "method": "card",
    //             "localTimeZone": "NZT",
    //             "dateTimeUtc": "2026-03-15T18:11:31Z",
    //             "dateTimeLocal": "2026-03-16T07:11:31+13:00",
    //             "settlementDate": "2026-03-16",
    //             "amount": "55.00",
    //             "balanceAmount": "0.00",
    //             "currency": "NZD",
    //             "currencyNumeric": 554,
    //             "clientType": "internet",
    //             "merchantReference": "topup:Fw02HJSXPygbhGViUudCjQTO04D3",
    //             "card": {
    //                 "cardHolderName": "CHOI",
    //                 "cardNumber": "411111........11",
    //                 "dateExpiryMonth": "09",
    //                 "dateExpiryYear": "33",
    //                 "type": "visa"
    //             },
    //             "cvc2ResultCode": "U",
    //             "traceId": "012345678912345___",
    //             "storedCardIndicator": "single",
    //             "notificationUrl": "https://doom-saint-away-cottage.trycloudflare.com/coffix-app-dev/us-central1/v1/webhook",
    //             "customer": {
    //                "firstName": "Choih",
    //                "lastName": "",
    //                "email": "pajunar0@gmail.com",
    //                "phoneNumber": "",
    //                "homePhoneNumber": "",
    //                "account": ""
    //             },
    //             "sessionId": "0000050000173579050ea491c10a3e56",
    //             "browser": {
    //                 "ipAddress": "112.205.95.235",
    //                 "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
    //             },
    //             "isSurcharge": false,
    //             "amountTotal": "55.00",
    //             "liabilityIndicator": "standard",
    //             "links": [
    //                 {
    //                     "href": "https://uat.windcave.com/api/v1/transactions/00000005000b8ef8",
    //                     "rel": "self",
    //                     "method": "GET"
    //                 },
    //                 {
    //                     "href": "https://uat.windcave.com/api/v1/sessions/0000050000173579050ea491c10a3e56",
    //                     "rel": "session",
    //                     "method": "GET"
    //                 },
    //                 {
    //                     "href": "https://uat.windcave.com/api/v1/transactions",
    //                     "rel": "refund",
    //                     "method": "POST"
    //                 }
    //             ]
    //         }
    //     ]
    // }
    const transactions = windcaveSession.transactions;
    if (transactions.length === 0) {
      throw new WindcaveError(400, {
        error: `No transactions found for session: ${sessionId}`,
      });
    }

    // Pick the latest transaction
    const transaction = transactions[0];

    const merchantReference = transaction.merchantReference;
    if (!merchantReference) {
      throw new WindcaveError(400, {
        error: `No merchant reference for transaction: ${sessionId}`,
      });
    }

    const transactionDoc =
      await this.firebaseService.findTransactionBySessionId(sessionId);
    if (!transactionDoc) {
      throw new WindcaveError(400, {
        error: `No transaction found for session: ${sessionId}`,
      });
    }

    logger.info(`Transaction Document: ${JSON.stringify(transactionDoc)}`);

    // Atomically claim processing: set status to "processing" only if still "pending".
    // This prevents duplicate webhook executions (Windcave retry or concurrent calls)
    // from both passing the idempotency check before either writes the final status.
    const claimed = await firestore.runTransaction(async (t) => {
      const ref = firestore
        .collection("transactions")
        .doc(transactionDoc.docId);
      const snap = await t.get(ref);
      const current = snap.data()?.status;
      if (
        ["approved", "declined", "cancelled", "processing"].includes(current)
      ) {
        return false;
      }
      t.update(ref, { status: "processing", updatedAt: new Date() });
      return true;
    });
    if (!claimed) {
      logger.info(
        `Webhook already processed or in-flight for session: ${sessionId}`,
      );
      return;
    }

    const authorised = transaction.authorised === true;
    const amount = Number(transaction.amount ?? 0) || transactionDoc.amount;
    const paymentMethod = transaction.method ?? transaction.cardType ?? "card";

    // MERCHANT REFERENCE IF TOPUP: topup:<customerId>
    // MERCHANT REFERENCE IF ORDER: order:<customerId>:<orderId>
    if (merchantReference.startsWith(TOPUP_PREFIX)) {
      const customerId = parseTopupMerchantReference(merchantReference);
      logger.info("customerId", customerId);
      this.handleTopUp({
        customerId: customerId ?? "",
        amount,
        sessionId,
        transactionDoc,
        transaction,
        paymentMethod,
        responseText: transaction.responseText,
        authorised,
      });
    } else {
      // if the user buys a product this function will be called
      const parsed = parseOrderMerchantReference(merchantReference);
      const customerId = parsed?.customerId ?? "";
      const orderId = parsed?.orderId ?? merchantReference;
      const orderDoc = await this.firebaseService.findOrderByOrderId(orderId);
      const storeDoc = await this.firebaseService.findStoreByStoreId(
        orderDoc?.storeId,
      );

      if (authorised) {
        if (!orderDoc) {
          throw new WindcaveError(400, {
            error: `No order found for orderId: ${orderId}`,
          });
        }
        logger.info("orderDoc", orderId);
        const paidAt = new Date();
        await this.firebaseService.updateOrder(orderDoc.docId, {
          status: "paid",
          paidAt,
          paymentMethod,
          scheduledAt: new Date(
            Date.now() + (orderDoc?.duration ?? 0) * 60_000,
          ),
        });
        await this.firebaseService.updateTransaction(transactionDoc.docId, {
          status: "approved",
          updatedAt: new Date(),
          paymentTime: new Date(),
          paymentMethod,
          sessionId,
          paymentId: transaction.id,
          responseText: transaction.responseText,
          orderNumber: orderDoc?.orderNumber,
        });

        // CREATE RECEIPT PRINT QUEUE
        await this.receiptService.createPrintQueue({
          receiptData: {
            printerId: storeDoc?.printerId ?? "TRY",
            storeName: storeDoc?.name ?? "",
            storeAddress: storeDoc?.address ?? "",
            orderNumber: orderDoc?.transactionNumber ?? "",
            orders: (orderDoc.items ?? [])
              .map(
                (item: any) =>
                  `${item.quantity}x ${item.productName} | $${item.price.toFixed(2)}`,
              )
              .join("\n"),
            total: Number((orderDoc.amount ?? 0).toFixed(2)),
            customer: transaction.customer.firstName ?? "",
            baristaName: "John Doe",
            duration: orderDoc?.duration ?? 0,
            paymentMethod: "Credit Card",
          },
        });

        this.notificationService
          .sendNotification({
            customerId: customerId ?? "",
            title: "Order Payment Successful",
            message: `A payment for order #${orderDoc?.transactionNumber} has been accepted`,
          })
          .catch((err) => logger.error("Notification failed:", err));
        this.referralService
          .handleFirstPurchase({
            customerId: customerId ?? "",
            orderId,
            paidAt,
          })
          .catch((err) =>
            logger.error("Referral first-purchase check failed:", err),
          );
        return;
      } else {
        await this.firebaseService.updateTransaction(transactionDoc.docId, {
          status: "declined",
          updatedAt: new Date(),
          paymentMethod,
          sessionId,
          responseText: transaction.responseText,
          orderNumber: orderDoc?.orderNumber,
        });

        await this.firebaseService.updateOrder(orderId, {
          status: "payment_failed",
          failedAt: new Date(),
        });
        this.notificationService
          .sendNotification({
            customerId: customerId ?? "",
            title: "Order Failed",
            message: "Your order has been failed",
          })
          .catch((err) => logger.error("Notification failed:", err));
      }
    }
  }

  async handleTopUp({
    customerId,
    amount,
    sessionId,
    transactionDoc,
    transaction,
    paymentMethod,
    responseText,
    authorised,
  }: {
    customerId: string;
    amount: number;
    sessionId: string;
    transactionDoc: any;
    transaction: any;
    paymentMethod: string;
    responseText: string;
    authorised: boolean;
  }) {
    if (authorised) {
      const totalAmount = await this.coffixCreditService.addCredit(
        customerId,
        amount,
      );
      await this.firebaseService.updateTransaction(transactionDoc.docId, {
        status: "approved",
        updatedAt: new Date(),
        paymentTime: new Date(),
        paymentMethod,
        sessionId,
        paymentId: transaction.id,
        responseText: transaction.responseText,
        totalAmount,
      });
      this.notificationService
        .sendNotification({
          customerId,
          title: "Top-up Payment Successful",
          message: `A payment for top-up #${transactionDoc?.transactionNumber} has been accepted`,
        })
        .catch((err) => logger.error("Notification failed:", err));
      return;
    } else {
      await this.firebaseService.updateTransaction(transactionDoc.docId, {
        status: "declined",
        updatedAt: new Date(),
        paymentMethod,
        sessionId,
        responseText: transaction.responseText,
      });
      this.notificationService
        .sendNotification({
          customerId,
          title: "Top-up Failed",
          message: "Your top-up has been failed",
        })
        .catch((err) => logger.error("Notification failed:", err));
    }
    return;
  }
}
