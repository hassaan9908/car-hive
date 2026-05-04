import * as functions from 'firebase-functions';
import { buildNotificationPayload } from './contracts';
import { sendPushToUser, writeNotificationDoc } from './sendToUser';

type AdDoc = {
  userId?: string;
  status?: string;
  approvedAt?: FirebaseFirestore.Timestamp;
};

export const notifyOnAdLive = functions.firestore
  .document('ads/{adId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() as AdDoc;
    const after = change.after.data() as AdDoc;
    const adId = context.params.adId;

    if (before.status === after.status) {
      return;
    }

    if (after.status !== 'active') {
      return;
    }

    const ownerUserId = after.userId ?? '';
    if (!ownerUserId) {
      return;
    }

    const marker = after.approvedAt?.toMillis()?.toString() ?? Date.now().toString();
    const idempotencyKey = `ad_status_${adId}_active_${marker}`;

    const notification = buildNotificationPayload({
      userId: ownerUserId,
      type: 'ad_live',
      title: 'Your ad is live',
      message: 'Your listing is now active and visible to buyers.',
      idempotencyKey,
      data: {
        type: 'ad_live',
        adId,
        oldStatus: before.status ?? 'unknown',
        newStatus: after.status ?? 'active',
      },
    });

    await writeNotificationDoc(idempotencyKey, notification);
    await sendPushToUser(ownerUserId, notification.title, notification.message, notification.data);
  });
