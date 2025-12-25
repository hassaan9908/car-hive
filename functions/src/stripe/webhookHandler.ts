import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { stripe, webhookSecret } from './config';

const db = admin.firestore();

export const handleWebhook = async (
  req: functions.https.Request,
  res: functions.Response
): Promise<void> => {
  const sig = req.headers['stripe-signature'];

  if (!sig) {
    res.status(400).send('No signature');
    return;
  }

  let event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig as string,
      webhookSecret || functions.config().stripe?.webhook_secret || ''
    );
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  try {
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentIntentSucceeded(event.data.object as any);
        break;

      case 'payment_intent.payment_failed':
        await handlePaymentIntentFailed(event.data.object as any);
        break;

      case 'payment_intent.canceled':
        await handlePaymentIntentCanceled(event.data.object as any);
        break;

      case 'payout.paid':
        await handlePayoutPaid(event.data.object as any);
        break;

      case 'payout.failed':
        await handlePayoutFailed(event.data.object as any);
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
  } catch (error: any) {
    console.error('Error handling webhook:', error);
    res.status(500).send(`Webhook handler error: ${error.message}`);
  }
};

async function handlePaymentIntentSucceeded(paymentIntent: any) {
  const { id, metadata, amount } = paymentIntent;

  console.log(`Payment intent succeeded: ${id}`);

  // Find transaction by payment intent ID
  const transactionsSnapshot = await db
    .collection('investment_transactions')
    .where('stripePaymentIntentId', '==', id)
    .limit(1)
    .get();

  if (transactionsSnapshot.empty) {
    console.log(`No transaction found for payment intent: ${id}`);
    return;
  }

  const transactionDoc = transactionsSnapshot.docs[0];
  const transactionId = transactionDoc.id;

  // Update transaction status
  await db.collection('investment_transactions').doc(transactionId).update({
    status: 'completed',
    paymentReference: id,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Handle different transaction types
  if (metadata.type === 'investment' && metadata.investmentId) {
    // Activate investment
    await db.collection('investments').doc(metadata.investmentId).update({
      status: 'active',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update vehicle current investment
    if (metadata.vehicleInvestmentId) {
      const vehicleDoc = await db
        .collection('investment_vehicles')
        .doc(metadata.vehicleInvestmentId)
        .get();

      if (vehicleDoc.exists) {
        const vehicleData = vehicleDoc.data();
        const currentInvestment = (vehicleData?.currentInvestment || 0) + amount / 100;
        const totalInvestmentGoal = vehicleData?.totalInvestmentGoal || 0;

        await db
          .collection('investment_vehicles')
          .doc(metadata.vehicleInvestmentId)
          .update({
            currentInvestment,
            fundingProgress: (currentInvestment / totalInvestmentGoal) * 100,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        // Check if funding is complete
        if (currentInvestment >= totalInvestmentGoal) {
          await db
            .collection('investment_vehicles')
            .doc(metadata.vehicleInvestmentId)
            .update({
              investmentStatus: 'funded',
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
      }
    }
  } else if (metadata.type === 'share_purchase' && metadata.investmentId) {
    // Handle share purchase
    // Transfer investment ownership
    await db.collection('investments').doc(metadata.investmentId).update({
      userId: metadata.userId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Mark marketplace listing as sold
    const listingsSnapshot = await db
      .collection('share_marketplace')
      .where('investmentId', '==', metadata.investmentId)
      .where('status', '==', 'active')
      .limit(1)
      .get();

    if (!listingsSnapshot.empty) {
      await db
        .collection('share_marketplace')
        .doc(listingsSnapshot.docs[0].id)
        .update({
          status: 'sold',
          buyerUserId: metadata.userId,
          soldAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  }

  // Send notification
  if (metadata.userId) {
    await db.collection('investment_notifications').add({
      userId: metadata.userId,
      type: 'payment_success',
      title: 'Payment Successful',
      message: `Your payment of ${(amount / 100).toFixed(2)} PKR has been processed successfully.`,
      relatedId: transactionId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentIntentFailed(paymentIntent: any) {
  const { id, metadata } = paymentIntent;

  console.log(`Payment intent failed: ${id}`);

  const transactionsSnapshot = await db
    .collection('investment_transactions')
    .where('stripePaymentIntentId', '==', id)
    .limit(1)
    .get();

  if (transactionsSnapshot.empty) {
    return;
  }

  const transactionId = transactionsSnapshot.docs[0].id;

  await db.collection('investment_transactions').doc(transactionId).update({
    status: 'failed',
    paymentReference: id,
    notes: 'Payment failed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send notification
  if (metadata.userId) {
    await db.collection('investment_notifications').add({
      userId: metadata.userId,
      type: 'payment_failed',
      title: 'Payment Failed',
      message: 'Your payment could not be processed. Please try again.',
      relatedId: transactionId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePaymentIntentCanceled(paymentIntent: any) {
  const { id } = paymentIntent;

  console.log(`Payment intent canceled: ${id}`);

  const transactionsSnapshot = await db
    .collection('investment_transactions')
    .where('stripePaymentIntentId', '==', id)
    .limit(1)
    .get();

  if (transactionsSnapshot.empty) {
    return;
  }

  const transactionId = transactionsSnapshot.docs[0].id;

  await db.collection('investment_transactions').doc(transactionId).update({
    status: 'failed',
    paymentReference: id,
    notes: 'Payment canceled',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function handlePayoutPaid(payout: any) {
  const { id, metadata } = payout;

  console.log(`Payout paid: ${id}`);

  const transactionsSnapshot = await db
    .collection('investment_transactions')
    .where('stripePayoutId', '==', id)
    .limit(1)
    .get();

  if (transactionsSnapshot.empty) {
    return;
  }

  const transactionId = transactionsSnapshot.docs[0].id;

  await db.collection('investment_transactions').doc(transactionId).update({
    status: 'completed',
    payoutStatus: 'paid',
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send notification
  if (metadata.userId) {
    await db.collection('investment_notifications').add({
      userId: metadata.userId,
      type: 'payout_success',
      title: 'Payout Successful',
      message: `Your profit payout has been processed successfully.`,
      relatedId: transactionId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

async function handlePayoutFailed(payout: any) {
  const { id, metadata } = payout;

  console.log(`Payout failed: ${id}`);

  const transactionsSnapshot = await db
    .collection('investment_transactions')
    .where('stripePayoutId', '==', id)
    .limit(1)
    .get();

  if (transactionsSnapshot.empty) {
    return;
  }

  const transactionId = transactionsSnapshot.docs[0].id;

  await db.collection('investment_transactions').doc(transactionId).update({
    payoutStatus: 'failed',
    notes: 'Payout failed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Send notification
  if (metadata.userId) {
    await db.collection('investment_notifications').add({
      userId: metadata.userId,
      type: 'payout_failed',
      title: 'Payout Failed',
      message: 'Your profit payout could not be processed. Please contact support.',
      relatedId: transactionId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

