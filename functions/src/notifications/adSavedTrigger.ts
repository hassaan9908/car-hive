import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { buildNotificationPayload } from './contracts';
import { sendPushToUser, writeNotificationDoc } from './sendToUser';

const db = admin.firestore();

type AdDoc = {
  userId?: string;
};

type UserDoc = {
  displayName?: string;
  fullName?: string;
};

export const notifyOnAdSaved = functions.firestore
  .document('users/{saverUserId}/savedAds/{adId}')
  .onCreate(async (snapshot, context) => {
    const saverUserId = context.params.saverUserId;
    const adId = context.params.adId;
    const saveData = snapshot.data() as { savedAt?: FirebaseFirestore.Timestamp };
    void saveData;

    const adDoc = await db.collection('ads').doc(adId).get();
    if (!adDoc.exists) {
      return;
    }

    const ad = adDoc.data() as AdDoc;
    const ownerUserId = ad.userId ?? '';
    if (!ownerUserId || ownerUserId === saverUserId) {
      return;
    }

    const saverDoc = await db.collection('users').doc(saverUserId).get();
    const saver = (saverDoc.data() ?? {}) as UserDoc;
    const saverName = saver.displayName ?? saver.fullName ?? 'Someone';
    const idempotencyKey = `save_${adId}_${saverUserId}`;

    const notification = buildNotificationPayload({
      userId: ownerUserId,
      type: 'ad_saved',
      title: 'Someone saved your ad',
      message: `${saverName} saved your listing.`,
      idempotencyKey,
      data: {
        type: 'ad_saved',
        adId,
        savedByUserId: saverUserId,
      },
    });

    await writeNotificationDoc(idempotencyKey, notification);
    await sendPushToUser(ownerUserId, notification.title, notification.message, notification.data);
  });
