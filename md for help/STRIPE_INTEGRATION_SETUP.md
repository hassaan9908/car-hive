# Stripe Integration Setup Guide

This guide explains how to set up and deploy the Stripe integration for the CarHive mutual investment feature.

## Prerequisites

1. Firebase project with Cloud Functions enabled
2. Stripe account (test or production)
3. Node.js 18+ installed
4. Firebase CLI installed

## Step 1: Install Dependencies

### Flutter Dependencies

The Flutter dependencies are already added to `pubspec.yaml`:
- `flutter_stripe: ^11.1.0`
- `cloud_functions: ^5.1.4`

Run:
```bash
flutter pub get
```

### Cloud Functions Dependencies

Navigate to the `functions` directory and install dependencies:

```bash
cd functions
npm install
```

## Step 2: Configure Stripe Keys

### Flutter (Client-Side)

The publishable key is already configured in `lib/config/stripe_config.dart`:
```dart
static const String publishableKey = 'pk_test_...';
```

**Important**: The publishable key is safe to expose in client code.

### Cloud Functions (Server-Side)

The secret key is configured in `functions/src/stripe/config.ts`. For production, set it via Firebase config:

```bash
firebase functions:config:set stripe.secret_key="sk_live_..."
firebase functions:config:set stripe.webhook_secret="whsec_..."
```

Or set environment variables:
```bash
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
```

## Step 3: Build and Deploy Cloud Functions

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

## Step 4: Set Up Stripe Webhook

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
2. Click "Add endpoint"
3. Enter your webhook URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook`
4. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `payout.paid`
   - `payout.failed`
5. Copy the webhook signing secret and set it in Firebase config (see Step 2)

## Step 5: Test the Integration

### Test Payment Flow

1. Open the app and navigate to Mutual Investment
2. Select an investment opportunity
3. Choose "Debit/Credit Card (Stripe)" as payment method
4. Enter test card details:
   - Card: `4242 4242 4242 4242`
   - Expiry: Any future date
   - CVC: Any 3 digits
   - ZIP: Any 5 digits

### Test Payout Flow

1. Complete an investment vehicle sale
2. Trigger profit distribution
3. Verify payouts are created in Stripe Dashboard

## Cloud Functions Overview

### Available Functions

1. **stripeCreatePaymentIntent**
   - Creates a Stripe payment intent
   - Called from Flutter app
   - Returns client secret for payment sheet

2. **stripeConfirmPayment**
   - Confirms payment after user completes payment sheet
   - Updates Firestore transaction status

3. **stripeCreatePayout**
   - Creates Stripe payout for profit distribution
   - Called when distributing profits to investors

4. **stripeWebhook**
   - Handles Stripe webhook events
   - Updates Firestore based on payment/payout status
   - Automatically activates investments and transfers shares

## Payment Flow

1. User selects investment amount and Stripe payment method
2. Flutter app calls `stripeCreatePaymentIntent` Cloud Function
3. Cloud Function creates payment intent and returns client secret
4. Flutter presents Stripe payment sheet
5. User completes payment
6. Flutter calls `stripeConfirmPayment` Cloud Function
7. Stripe sends webhook event to `stripeWebhook`
8. Webhook updates Firestore and activates investment

## Payout Flow

1. Investment vehicle is sold
2. Profit distribution service calculates profits
3. For each investor, `stripeCreatePayout` is called
4. Stripe processes payout
5. Webhook updates transaction status when payout completes

## Security Notes

- **Never commit secret keys to git**
- Use Firebase config or environment variables for secrets
- Publishable key is safe in client code
- All payment processing happens server-side
- Webhook signature verification prevents unauthorized requests

## Troubleshooting

### Payment Sheet Not Appearing

- Check Stripe publishable key is correct
- Verify Stripe is initialized in `main.dart`
- Check network connectivity

### Webhook Not Receiving Events

- Verify webhook URL is correct in Stripe Dashboard
- Check webhook secret is set correctly
- Review Cloud Functions logs: `firebase functions:log`

### Payment Intent Creation Fails

- Verify secret key is set in Firebase config
- Check Cloud Functions are deployed
- Review function logs for errors

## Production Checklist

- [ ] Switch to production Stripe keys
- [ ] Update publishable key in `stripe_config.dart`
- [ ] Set production secret key in Firebase config
- [ ] Configure production webhook endpoint
- [ ] Test with real payment (small amount)
- [ ] Set up Stripe Dashboard alerts
- [ ] Review and update Firestore security rules
- [ ] Enable Cloud Functions monitoring

## Support

For Stripe-specific issues, refer to:
- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Flutter SDK](https://pub.dev/packages/flutter_stripe)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)

