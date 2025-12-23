import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stripe } from './config';

const db = admin.firestore();

interface CreatePaymentIntentData {
  amount: number;
  currency?: string;
  userId: string;
  vehicleInvestmentId?: string;
  investmentId?: string;
  transactionId?: string;
  type?: string; // 'investment', 'share_purchase'
  description?: string;
}

export const createPaymentIntent = async (
  data: CreatePaymentIntentData,
  context: functions.https.CallableContext
): Promise<{ success: boolean; clientSecret?: string; error?: string }> => {
  try {
    // Verify authentication
    if (!context.auth) {
      return { success: false, error: 'Unauthorized' };
    }

    const { amount, currency = 'pkr', userId, vehicleInvestmentId, investmentId, transactionId, type, description } = data;

    // Validate inputs
    if (!amount || amount <= 0) {
      return { success: false, error: 'Invalid amount' };
    }

    if (context.auth.uid !== userId) {
      return { success: false, error: 'User ID mismatch' };
    }

    // Convert amount to smallest currency unit (cents for USD, but PKR doesn't have cents)
    // Stripe requires amount in smallest currency unit
    // For PKR, we'll use paisa (1 PKR = 100 paisa)
    const amountInSmallestUnit = Math.round(amount * 100);

    // Create metadata for tracking
    const metadata: Record<string, string> = {
      userId,
      type: type || 'investment',
    };

    if (vehicleInvestmentId) {
      metadata.vehicleInvestmentId = vehicleInvestmentId;
    }
    if (investmentId) {
      metadata.investmentId = investmentId;
    }
    if (transactionId) {
      metadata.transactionId = transactionId;
    }

    // Create Payment Intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInSmallestUnit,
      currency: currency.toLowerCase(),
      metadata,
      description: description || `Payment for ${type || 'investment'}`,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Store payment intent ID in Firestore transaction if transactionId provided
    if (transactionId) {
      await db.collection('investment_transactions').doc(transactionId).update({
        stripePaymentIntentId: paymentIntent.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      clientSecret: paymentIntent.client_secret || undefined,
    };
  } catch (error: any) {
    console.error('Error creating payment intent:', error);
    return {
      success: false,
      error: error.message || 'Failed to create payment intent',
    };
  }
};

