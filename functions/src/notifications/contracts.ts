import * as admin from 'firebase-admin';

export type NotificationType = 'chat' | 'ad_live' | 'ad_saved';

export interface NotificationPayload {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  read: boolean;
  createdAt: admin.firestore.FieldValue;
  idempotencyKey: string;
  data: Record<string, string>;
}

export function buildNotificationPayload(params: {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  idempotencyKey: string;
  data: Record<string, string>;
}): NotificationPayload {
  return {
    userId: params.userId,
    type: params.type,
    title: params.title,
    message: params.message,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    idempotencyKey: params.idempotencyKey,
    data: params.data,
  };
}
