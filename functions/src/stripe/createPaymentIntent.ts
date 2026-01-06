import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stripe } from './config';

const db = admin.firestore();

interface CreatePaymentIntentData {
  amount: number; // Amount in USD (converted from PKR on client side)
  currency?: string; // Should be 'usd' for Stripe
  userId: string;
  vehicleInvestmentId?: string;
  investmentId?: string;
  transactionId?: string;
  type?: string; // 'investment', 'share_purchase'
  description?: string;
  originalAmountPkr?: number; // Original PKR amount before conversion (for reference)
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

    const { amount, currency = 'usd', userId, vehicleInvestmentId, investmentId, transactionId, type, description, originalAmountPkr } = data;

    // Validate inputs
    if (!amount || amount <= 0) {
      return { success: false, error: 'Invalid amount' };
    }

    if (context.auth.uid !== userId) {
      return { success: false, error: 'User ID mismatch' };
    }

    // Convert amount to smallest currency unit (cents for USD)
    // Stripe requires amount in smallest currency unit
    // Amount is already in USD (converted from PKR on client side)
    const amountInSmallestUnit = Math.round(amount * 100);

    // Create metadata for tracking
    const metadata: Record<string, string> = {
      userId,
      type: type || 'investment',
    };

    // Store original PKR amount if provided (for reference)
    if (originalAmountPkr) {
      metadata.originalAmountPkr = originalAmountPkr.toString();
    }

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

