import * as admin from 'firebase-admin';
import { NotificationPayload } from './contracts';

const db = admin.firestore();

type UserDoc = {
  fcmTokens?: unknown;
};

function getTokenList(data: UserDoc): string[] {
  if (!Array.isArray(data.fcmTokens)) {
    return [];
  }

  return data.fcmTokens.filter((token): token is string =>
    typeof token === 'string' && token.trim().length > 0
  );
}

function isInvalidTokenError(code?: string): boolean {
  return (
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/invalid-registration-token'
  );
}

export async function writeNotificationDoc(
  notificationId: string,
  payload: NotificationPayload
): Promise<void> {
  await db.collection('notifications').doc(notificationId).set(payload, { merge: false });
}

export async function sendPushToUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    console.log(`User doc not found for notification userId=${userId}`);
    return;
  }

  const userData = userDoc.data() as UserDoc;
  const tokens = getTokenList(userData);
  if (tokens.length === 0) {
    console.log(`No FCM tokens registered for userId=${userId}`);
    return;
  }

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: 'high',
      notification: {
        channelId: 'carhive_alerts',
      },
    },
  });

  const invalidTokens: string[] = [];
  response.responses.forEach((item, index) => {
    const code = item.error?.code;
    if (code && isInvalidTokenError(code)) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await db.collection('users').doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      fcmTokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  if (response.failureCount > 0) {
    console.error(
      `FCM send partial failure userId=${userId} success=${response.successCount} failure=${response.failureCount}`
    );
  }
}
