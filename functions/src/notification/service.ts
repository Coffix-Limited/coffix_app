import * as admin from "firebase-admin";
import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions";
import { firestore } from "../config/firebaseAdmin";
import { Notification } from "./interface";
import { AppUser } from "../user/interface";

const BATCH_LIMIT = 500;

export class NotificationService {
  async sendNotification({
    customerId,
    title,
    message,
    metadata,
  }: {
    customerId: string;
    title: string;
    message: string;
    metadata?: Record<string, any>;
  }): Promise<void> {
    const customerSnap = await firestore
      .collection("customers")
      .doc(customerId)
      .get();
    const user = customerSnap.exists ? (customerSnap.data() as AppUser) : null;
    const fcmToken = user?.fcmToken as string | undefined;

    if (user?.allowNotifications === false) {
      logger.warn(
        `User ${customerId} has notifications disabled, skipping push send`,
      );
      return;
    }

    if (!fcmToken) {
      logger.warn(
        `No FCM token for customer ${customerId}, skipping push send`,
      );
    } else {
      logger.info(`Sending notification to customer ${customerId}:`, {
        fcmToken,
        title,
        message,
        metadata,
      });
      try {
        await getMessaging(admin.app()).send({
          token: fcmToken,
          notification: { title, body: message },
        });
      } catch (err) {
        logger.error(`FCM send failed for customer ${customerId}:`, err);
      }
    }

    const ref = firestore.collection("notifications").doc();
    const now = new Date();
    const notificationDoc: Notification = {
      docId: ref.id,
      customerId,
      title,
      message,
      metadata: metadata ?? {},
      createdAt: now,
      updatedAt: now,
    };
    await ref.set(notificationDoc);
  }

  async sendBatchNotifications(
    notifications: Array<{
      customerId: string;
      title: string;
      message: string;
      metadata?: Record<string, any>;
    }>,
  ): Promise<void> {
    if (notifications.length === 0) return;

    const customerSnaps = await Promise.all(
      notifications.map((n) =>
        firestore.collection("customers").doc(n.customerId).get(),
      ),
    );

    const now = new Date();
    const firestoreWrites: Array<{
      ref: FirebaseFirestore.DocumentReference;
      doc: Notification;
    }> = [];
    const messagingPayloads: Array<{
      token: string;
      notification: { title: string; body: string };
    }> = [];

    for (let i = 0; i < notifications.length; i++) {
      const { customerId, title, message, metadata } = notifications[i];
      const fcmToken = customerSnaps[i].data()?.fcmToken as string | undefined;

      const ref = firestore.collection("notifications").doc();
      firestoreWrites.push({
        ref,
        doc: {
          docId: ref.id,
          customerId,
          title,
          message,
          metadata: metadata ?? {},
          createdAt: now,
          updatedAt: now,
        },
      });

      if (!fcmToken) {
        logger.warn(
          `No FCM token for customer ${customerId}, skipping push send`,
        );
      } else {
        messagingPayloads.push({
          token: fcmToken,
          notification: { title, body: message },
        });
      }
    }

    for (let i = 0; i < messagingPayloads.length; i += BATCH_LIMIT) {
      const chunk = messagingPayloads.slice(i, i + BATCH_LIMIT);
      const batchResponse = await getMessaging(admin.app()).sendEach(chunk);
      batchResponse.responses.forEach((r, idx) => {
        if (!r.success) {
          logger.error(`FCM batch send failed for index ${i + idx}:`, r.error);
        }
      });
    }

    for (let i = 0; i < firestoreWrites.length; i += BATCH_LIMIT) {
      const chunk = firestoreWrites.slice(i, i + BATCH_LIMIT);
      const batch = firestore.batch();
      for (const { ref, doc } of chunk) {
        batch.set(ref, doc);
      }
      await batch.commit();
    }
  }
}

export const notificationService = new NotificationService();
