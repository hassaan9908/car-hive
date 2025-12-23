import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Import Stripe functions
import { createPaymentIntent } from './stripe/createPaymentIntent';
import { confirmPayment } from './stripe/confirmPayment';
import { createPayout } from './stripe/createPayout';
import { handleWebhook } from './stripe/webhookHandler';

// Export Cloud Functions
export const stripeCreatePaymentIntent = functions.https.onCall(createPaymentIntent);
export const stripeConfirmPayment = functions.https.onCall(confirmPayment);
export const stripeCreatePayout = functions.https.onCall(createPayout);
export const stripeWebhook = functions.https.onRequest(handleWebhook);

