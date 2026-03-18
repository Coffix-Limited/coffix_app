import FirebaseService from "../firebase/service";
import { WindcaveError } from "../utils/windcave.error";
import { WindcaveService } from "../windcave/service";
import { CoffixCreditService } from "../coffixCredit/service";
import { parseTopupMerchantReference } from "../coffixCredit/utils";
import { logger } from "firebase-functions";
import { ReceiptService } from "../receipt/service";

export class WebhookService {
  private readonly windcaveService: WindcaveService;
  private readonly firebaseService: FirebaseService;
  private readonly receiptService: ReceiptService;
  private readonly coffixCreditService: CoffixCreditService;

  constructor() {
    this.windcaveService = new WindcaveService();
    this.firebaseService = new FirebaseService();
    this.coffixCreditService = new CoffixCreditService();
    this.receiptService = new ReceiptService();
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

    if (["approved", "declined", "cancelled"].includes(transactionDoc.status)) {
      return;
    }

    const authorised = transaction.authorised === true;
    const amount = Number(transaction.amount ?? 0) || transactionDoc.amount;
    const paymentMethod = transaction.method ?? transaction.cardType ?? "card";

    const customerId = parseTopupMerchantReference(merchantReference);
    // If the user tops up this function will be called
    logger.info("customerId", customerId);
    if (customerId) {
      if (authorised) {
        await this.coffixCreditService.addCredit(customerId, amount);
        await this.firebaseService.updateTransaction(transactionDoc.docId, {
          status: "approved",
          updatedAt: new Date(),
          paymentTime: new Date(),
          paymentMethod,
          sessionId,
          paymentId: transaction.id,
          responseText: transaction.responseText,
        });
        return;
      } else {
        await this.firebaseService.updateTransaction(transactionDoc.docId, {
          status: "declined",
          updatedAt: new Date(),
          paymentMethod,
          sessionId,
          responseText: transaction.responseText,
        });
      }
      return;
    }

    // if the user buys a product this function will be called
    const orderId = merchantReference;
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
      await this.firebaseService.updateOrder(orderDoc.docId, {
        status: "paid",
        paidAt: new Date(),
        paymentMethod,
        scheduledAt: new Date(Date.now() + (orderDoc?.duration ?? 0) * 60_000),
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
          storeName: storeDoc?.name ?? "",
          storeAddress: storeDoc?.address ?? "",
          orderNumber: orderDoc?.orderNumber.toString() ?? "",
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
        },
      });
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
    }
  }
}
