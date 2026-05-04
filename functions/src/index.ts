import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Import Stripe functions
import { createPaymentIntent } from './stripe/createPaymentIntent';
import { confirmPayment } from './stripe/confirmPayment';
import { createPayout } from './stripe/createPayout';
import { handleWebhook } from './stripe/webhookHandler';
import { notifyOnChatMessage } from './notifications/chatMessageTrigger';
import { notifyOnAdLive } from './notifications/adStatusTrigger';
import { notifyOnAdSaved } from './notifications/adSavedTrigger';

// Export Cloud Functions
export const stripeCreatePaymentIntent = functions.https.onCall(createPaymentIntent);
export const stripeConfirmPayment = functions.https.onCall(confirmPayment);
export const stripeCreatePayout = functions.https.onCall(createPayout);
export const stripeWebhook = functions.https.onRequest(handleWebhook);
export { notifyOnChatMessage, notifyOnAdLive, notifyOnAdSaved };

