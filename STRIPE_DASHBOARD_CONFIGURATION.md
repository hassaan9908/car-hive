# Stripe Dashboard Configuration Guide

This guide will walk you through configuring your Stripe Dashboard for the CarHive application.

## Table of Contents
1. [Getting Your Stripe API Keys](#1-getting-your-stripe-api-keys)
2. [Configuring Webhooks](#2-configuring-webhooks)
3. [Setting Up Firebase Configuration](#3-setting-up-firebase-configuration)
4. [Important Stripe Dashboard Settings](#4-important-stripe-dashboard-settings)
5. [Testing Your Configuration](#5-testing-your-configuration)
6. [Troubleshooting](#6-troubleshooting)

---

## 1. Getting Your Stripe API Keys

### Step 1.1: Access Stripe Dashboard
1. Go to [https://dashboard.stripe.com](https://dashboard.stripe.com)
2. Log in to your Stripe account (or create one if you don't have it)

### Step 1.2: Get Your Test API Keys (For Development)
1. Make sure you're in **Test mode** (toggle in the top right of the dashboard)
2. Click on **"Developers"** in the left sidebar
3. Click on **"API keys"**
4. You'll see two keys:
   - **Publishable key** (starts with `pk_test_...`) - This is safe to use in your Flutter app
   - **Secret key** (starts with `sk_test_...`) - This must be kept secret and only used server-side

### Step 1.3: Update Your Flutter App with Publishable Key
1. Open `lib/config/stripe_config.dart`
2. Replace the existing publishable key with your test publishable key:
   ```dart
   static const String publishableKey = 'pk_test_YOUR_ACTUAL_KEY_HERE';
   ```

### Step 1.4: Get Production Keys (For Live App)
1. Switch to **Live mode** in Stripe Dashboard (toggle in top right)
2. Follow the same steps as above to get your production keys
3. **Important**: Only use production keys when your app is ready for real payments

---

## 2. Configuring Webhooks

Webhooks allow Stripe to notify your app when payment events occur (payment succeeded, failed, etc.).

### Step 2.1: Deploy Your Cloud Functions First
Before setting up webhooks, you need to deploy your Firebase Cloud Functions:

```bash
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions
```

After deployment, note your webhook URL. It will be in the format:
```
https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook
```

**For your project (carhive-bf048):**
- If no region is specified, the default is `us-central1`
- Your webhook URL will likely be: `https://us-central1-carhive-bf048.cloudfunctions.net/stripeWebhook`

To find your exact URL:
1. After deployment, check the Firebase Console
2. Go to **Functions** section
3. Look for `stripeWebhook` function
4. Copy the HTTPS trigger URL (it will be displayed there)

### Step 2.2: Add Webhook Endpoint in Stripe Dashboard
1. In Stripe Dashboard, go to **"Developers"** → **"Webhooks"**
2. Click **"Add endpoint"** button
3. Enter your webhook URL:
   ```
   https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/stripeWebhook
   ```
   Replace `YOUR_REGION` and `YOUR_PROJECT_ID` with your actual values.

4. **Select events to listen for:**
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `payout.paid`
   - `payout.failed`

5. Click **"Add endpoint"**

### Step 2.3: Get Webhook Signing Secret
1. After creating the webhook endpoint, click on it
2. In the **"Signing secret"** section, click **"Reveal"**
3. Copy the secret (starts with `whsec_...`)
4. You'll need this for Firebase configuration (see Step 3)

### Step 2.4: Test Webhook (Optional but Recommended)
1. In the webhook endpoint page, click **"Send test webhook"**
2. Select an event type (e.g., `payment_intent.succeeded`)
3. Click **"Send test webhook"**
4. Check your Firebase Functions logs to verify it was received:
   ```bash
   firebase functions:log --only stripeWebhook
   ```

---

## 3. Setting Up Firebase Configuration

You need to configure Firebase with your Stripe secret key and webhook secret.

### Step 3.1: Install Firebase CLI (If Not Already Installed)
```bash
npm install -g firebase-tools
```

### Step 3.2: Login to Firebase
```bash
firebase login
```

### Step 3.3: Set Stripe Configuration in Firebase
Run these commands (replace with your actual keys):

**For Test Mode:**
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

**For Production Mode:**
```bash
firebase functions:config:set stripe.secret_key="sk_live_YOUR_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

### Step 3.4: Redeploy Functions
After setting the configuration, redeploy your functions:
```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

### Alternative: Using Environment Variables (For Local Development)
If you're testing locally, you can set environment variables:

**Windows (PowerShell):**
```powershell
$env:STRIPE_SECRET_KEY="sk_test_YOUR_SECRET_KEY"
$env:STRIPE_WEBHOOK_SECRET="whsec_YOUR_WEBHOOK_SECRET"
```

**Mac/Linux:**
```bash
export STRIPE_SECRET_KEY="sk_test_YOUR_SECRET_KEY"
export STRIPE_WEBHOOK_SECRET="whsec_YOUR_WEBHOOK_SECRET"
```

---

## 4. Important Stripe Dashboard Settings

### 4.1: Business Information
1. Go to **"Settings"** → **"Business settings"**
2. Fill in your business information:
   - Business name
   - Business type
   - Address
   - Tax ID (if applicable)

### 4.2: Payment Methods
1. Go to **"Settings"** → **"Payment methods"**
2. Enable the payment methods you want to accept:
   - Credit and debit cards (usually enabled by default)
   - Other payment methods if needed

### 4.3: Currency Settings
1. Go to **"Settings"** → **"Business settings"**
2. Under **"Customer billing"**, set your default currency
3. **⚠️ IMPORTANT - Currency Issue:**
   - Your app is currently configured to use **PKR** (Pakistani Rupee) in `stripe_config.dart`
   - **Stripe does NOT support PKR** as a currency
   - You MUST change the currency to a supported one (e.g., USD, EUR, GBP)
   - Update `lib/config/stripe_config.dart`:
     ```dart
     static const String currency = 'usd'; // Change from 'pkr' to 'usd'
     ```
   - Check Stripe's supported currencies: [https://stripe.com/docs/currencies](https://stripe.com/docs/currencies)
   - If you need to show PKR amounts to users, convert them to USD before sending to Stripe

### 4.4: Payout Settings (For Profit Distribution)
1. Go to **"Settings"** → **"Payouts"**
2. Add your bank account details where you want to receive payouts
3. Complete the verification process
4. **Important**: For payouts to work, you need:
   - A verified bank account
   - Completed business verification
   - Stripe account in good standing

### 4.5: API Settings
1. Go to **"Developers"** → **"API settings"**
2. Review your API version (should be `2023-10-16` or later)
3. Check rate limits and usage

### 4.6: Email Notifications
1. Go to **"Settings"** → **"Notifications"**
2. Configure email notifications for:
   - Payment failures
   - Payouts
   - Disputes
   - Webhook failures

---

## 5. Testing Your Configuration

### Step 5.1: Test Payment Flow
1. Make sure you're in **Test mode** in Stripe Dashboard
2. Open your Flutter app
3. Navigate to an investment opportunity
4. Select "Debit/Credit Card (Stripe)" as payment method
5. Use Stripe test card:
   - **Card number**: `4242 4242 4242 4242`
   - **Expiry**: Any future date (e.g., `12/25`)
   - **CVC**: Any 3 digits (e.g., `123`)
   - **ZIP**: Any 5 digits (e.g., `12345`)

### Step 5.2: Test Other Scenarios
Use different test cards for different scenarios:

**Successful Payment:**
- Card: `4242 4242 4242 4242`

**Payment Requires Authentication (3D Secure):**
- Card: `4000 0025 0000 3155`

**Payment Declined:**
- Card: `4000 0000 0000 0002`

**Insufficient Funds:**
- Card: `4000 0000 0000 9995`

Full list: [Stripe Test Cards](https://stripe.com/docs/testing)

### Step 5.3: Verify Webhook Events
1. After making a test payment, go to Stripe Dashboard
2. Navigate to **"Developers"** → **"Webhooks"**
3. Click on your webhook endpoint
4. Check the **"Events"** tab to see if events were received
5. Verify in Firebase Functions logs:
   ```bash
   firebase functions:log --only stripeWebhook
   ```

### Step 5.4: Check Firestore Updates
1. Open Firebase Console
2. Go to **Firestore Database**
3. Check `investment_transactions` collection
4. Verify that transaction status was updated after payment

---

## 6. Troubleshooting

### Issue: Webhook Not Receiving Events

**Symptoms:**
- Payments complete but Firestore doesn't update
- No events showing in webhook logs

**Solutions:**
1. **Verify webhook URL is correct:**
   - Check the URL in Stripe Dashboard matches your deployed function URL
   - Ensure there are no typos

2. **Check webhook secret:**
   - Verify the webhook secret in Firebase config matches the one in Stripe Dashboard
   - Re-copy the secret from Stripe Dashboard if unsure

3. **Check Firebase Functions logs:**
   ```bash
   firebase functions:log --only stripeWebhook
   ```
   Look for errors or signature verification failures

4. **Test webhook manually:**
   - Use Stripe Dashboard's "Send test webhook" feature
   - Check if it reaches your function

### Issue: Payment Intent Creation Fails

**Symptoms:**
- Error when trying to make payment
- "Failed to create payment intent" error

**Solutions:**
1. **Verify secret key is set:**
   ```bash
   firebase functions:config:get
   ```
   Check that `stripe.secret_key` is present

2. **Check key is correct:**
   - Ensure you're using test keys in test mode
   - Ensure you're using live keys in live mode
   - Keys must match the mode you're in

3. **Check Cloud Functions are deployed:**
   ```bash
   firebase functions:list
   ```
   Verify `stripeCreatePaymentIntent` is listed

### Issue: Payout Creation Fails

**Symptoms:**
- Error when trying to create payout
- "Payout failed" error

**Solutions:**
1. **Verify bank account is added:**
   - Go to Stripe Dashboard → Settings → Payouts
   - Ensure bank account is added and verified

2. **Check account status:**
   - Ensure your Stripe account is fully activated
   - Complete any required verification steps

3. **Check currency support:**
   - Verify the currency you're using is supported for payouts
   - PKR may not be supported - check Stripe's documentation

4. **Review payout requirements:**
   - Some countries have restrictions on payouts
   - Check Stripe's payout documentation for your region

### Issue: Payment Sheet Not Appearing

**Symptoms:**
- Payment button doesn't do anything
- No payment sheet shows up

**Solutions:**
1. **Check publishable key:**
   - Verify the key in `stripe_config.dart` is correct
   - Ensure it matches your Stripe account

2. **Check Stripe initialization:**
   - Review `lib/main.dart` to ensure Stripe is initialized
   - Check console for initialization errors

3. **Check network connectivity:**
   - Ensure device has internet connection
   - Check if Stripe API is accessible

### Issue: Currency Not Supported

**Symptoms:**
- Error about currency not being supported
- PKR not working

**Solutions:**
1. **Check supported currencies:**
   - Visit [Stripe Supported Currencies](https://stripe.com/docs/currencies)
   - PKR (Pakistani Rupee) may not be supported

2. **Use alternative currency:**
   - Consider using USD or another supported currency
   - Update `stripe_config.dart`:
     ```dart
     static const String currency = 'usd'; // or another supported currency
     ```

3. **Handle currency conversion:**
   - Convert PKR amounts to supported currency before sending to Stripe
   - Display amounts in both currencies to users

---

## Quick Checklist

Before going live, ensure:

- [ ] Test API keys configured in development
- [ ] Production API keys ready (but not deployed yet)
- [ ] Webhook endpoint configured in Stripe Dashboard
- [ ] Webhook secret added to Firebase config
- [ ] Firebase Functions deployed
- [ ] Test payments working with test cards
- [ ] Webhook events being received
- [ ] Firestore updates working correctly
- [ ] Bank account added for payouts
- [ ] Business information completed
- [ ] Email notifications configured
- [ ] Tested all payment scenarios (success, failure, 3D Secure)
- [ ] Reviewed Stripe Dashboard for any warnings

---

## Additional Resources

- [Stripe Dashboard](https://dashboard.stripe.com)
- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Test Cards](https://stripe.com/docs/testing)
- [Stripe Webhooks Guide](https://stripe.com/docs/webhooks)
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Flutter Stripe Package](https://pub.dev/packages/flutter_stripe)

---

## Need Help?

If you encounter issues not covered in this guide:

1. Check Stripe Dashboard logs and events
2. Review Firebase Functions logs
3. Check Firestore for transaction records
4. Review the main setup guide: `STRIPE_INTEGRATION_SETUP.md`
5. Consult Stripe support or documentation

