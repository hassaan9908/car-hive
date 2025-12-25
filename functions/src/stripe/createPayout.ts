import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stripe } from './config';

const db = admin.firestore();

interface CreatePayoutData {
  amount: number;
  currency?: string;
  userId: string;
  transactionId: string;
  vehicleInvestmentId: string;
  investmentId?: string;
  description?: string;
  destinationAccountId?: string; // Stripe connected account ID (if using Connect)
}

export const createPayout = async (
  data: CreatePayoutData,
  context: functions.https.CallableContext
): Promise<{ success: boolean; payoutId?: string; error?: string }> => {
  try {
    // Verify authentication (admin only for payouts)
    if (!context.auth) {
      return { success: false, error: 'Unauthorized' };
    }

    // Check if user is admin (you may want to implement proper admin check)
    // For now, we'll allow the user to create payouts for their own transactions
    const { amount, currency = 'pkr', userId, transactionId, vehicleInvestmentId, investmentId, description } = data;

    // Validate inputs
    if (!amount || amount <= 0) {
      return { success: false, error: 'Invalid amount' };
    }

    // Get transaction to verify ownership
    const transactionDoc = await db.collection('investment_transactions').doc(transactionId).get();
    if (!transactionDoc.exists) {
      return { success: false, error: 'Transaction not found' };
    }

    const transactionData = transactionDoc.data();
    if (transactionData?.userId !== userId && context.auth.uid !== userId) {
      return { success: false, error: 'Unauthorized' };
    }

    // Convert amount to smallest currency unit
    const amountInSmallestUnit = Math.round(amount * 100);

    // Create payout metadata
    const metadata: Record<string, string> = {
      userId,
      transactionId,
      vehicleInvestmentId,
      type: 'profit_distribution',
    };

    if (investmentId) {
      metadata.investmentId = investmentId;
    }

    // Note: For payouts, you typically need a connected Stripe account
    // This is a simplified version. In production, you'd use Stripe Connect
    // For now, we'll create a transfer to the user's default payment method
    // or you can use Stripe Express accounts for marketplace payouts

    // If using Stripe Connect (recommended for marketplace):
    // const transfer = await stripe.transfers.create({
    //   amount: amountInSmallestUnit,
    //   currency: currency.toLowerCase(),
    //   destination: destinationAccountId,
    //   metadata,
    // });

    // For now, we'll create a payout record and mark it as pending
    // In production, integrate with Stripe Connect or use bank account details
    const payout = await stripe.payouts.create({
      amount: amountInSmallestUnit,
      currency: currency.toLowerCase(),
      metadata,
      description: description || 'Profit distribution payout',
      // method: 'standard', // or 'instant' (requires Stripe Instant Payouts)
    });

    // Update transaction with payout ID
    await db.collection('investment_transactions').doc(transactionId).update({
      stripePayoutId: payout.id,
      payoutStatus: payout.status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      payoutId: payout.id,
    };
  } catch (error: any) {
    console.error('Error creating payout:', error);
    return {
      success: false,
      error: error.message || 'Failed to create payout',
    };
  }
};

