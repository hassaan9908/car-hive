import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stripe } from './config';

const db = admin.firestore();

interface ConfirmPaymentData {
  paymentIntentId: string;
  transactionId: string;
  userId: string;
}

export const confirmPayment = async (
  data: ConfirmPaymentData,
  context: functions.https.CallableContext
): Promise<{ success: boolean; error?: string }> => {
  try {
    // Verify authentication
    if (!context.auth) {
      return { success: false, error: 'Unauthorized' };
    }

    const { paymentIntentId, transactionId, userId } = data;

    if (context.auth.uid !== userId) {
      return { success: false, error: 'User ID mismatch' };
    }

    // Retrieve payment intent from Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    // Get transaction from Firestore
    const transactionDoc = await db.collection('investment_transactions').doc(transactionId).get();
    if (!transactionDoc.exists) {
      return { success: false, error: 'Transaction not found' };
    }

    const transactionData = transactionDoc.data();
    if (transactionData?.userId !== userId) {
      return { success: false, error: 'Transaction ownership mismatch' };
    }

    // Update transaction based on payment intent status
    if (paymentIntent.status === 'succeeded') {
      await db.collection('investment_transactions').doc(transactionId).update({
        status: 'completed',
        paymentReference: paymentIntentId,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true };
    } else if (paymentIntent.status === 'requires_payment_method' || 
               paymentIntent.status === 'canceled') {
      await db.collection('investment_transactions').doc(transactionId).update({
        status: 'failed',
        paymentReference: paymentIntentId,
        notes: `Payment failed: ${paymentIntent.status}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: false, error: `Payment ${paymentIntent.status}` };
    } else {
      // Payment is still processing (requires_confirmation, requires_action, processing, requires_capture)
      return { success: false, error: `Payment status: ${paymentIntent.status}` };
    }
  } catch (error: any) {
    console.error('Error confirming payment:', error);
    return {
      success: false,
      error: error.message || 'Failed to confirm payment',
    };
  }
};

