import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { buildNotificationPayload } from './contracts';
import { sendPushToUser, writeNotificationDoc } from './sendToUser';

const db = admin.firestore();

type ChatMessageDoc = {
  senderId?: string;
  receiverId?: string;
  message?: string;
  conversationId?: string;
};

export const notifyOnChatMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data() as ChatMessageDoc;
    const senderId = data.senderId ?? '';
    const receiverId = data.receiverId ?? '';
    const conversationId = context.params.conversationId;
    const messageId = context.params.messageId;

    if (!senderId || !receiverId || senderId === receiverId) {
      return;
    }

    const senderDoc = await db.collection('users').doc(senderId).get();
    const senderName =
      (senderDoc.data()?.displayName as string | undefined) ??
      (senderDoc.data()?.fullName as string | undefined) ??
      'Someone';

    const preview = (data.message ?? '').trim();
    const body = preview.length > 80 ? `${preview.substring(0, 77)}...` : preview;
    const idempotencyKey = `chat_${conversationId}_${messageId}_${receiverId}`;

    const notification = buildNotificationPayload({
      userId: receiverId,
      type: 'chat',
      title: senderName,
      message: body.length === 0 ? 'Sent you a message' : body,
      idempotencyKey,
      data: {
        type: 'chat',
        conversationId,
        messageId,
        otherUserId: senderId,
        otherUserName: senderName,
      },
    });

    await writeNotificationDoc(idempotencyKey, notification);
    await sendPushToUser(receiverId, notification.title, notification.message, notification.data);
  });
