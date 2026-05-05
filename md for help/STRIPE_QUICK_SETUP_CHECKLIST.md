# Stripe Quick Setup Checklist

Use this checklist to quickly configure Stripe for your CarHive app.

## 🔑 Step 1: Get API Keys (5 minutes)

- [ ] Go to [Stripe Dashboard](https://dashboard.stripe.com)
- [ ] Switch to **Test mode** (toggle top right)
- [ ] Navigate to **Developers** → **API keys**
- [ ] Copy **Publishable key** (`pk_test_...`)
- [ ] Copy **Secret key** (`sk_test_...`)
- [ ] Update `lib/config/stripe_config.dart` with publishable key

## 🔗 Step 2: Deploy Cloud Functions (10 minutes)

- [ ] Open terminal in project root
- [ ] Run: `cd functions && npm install`
- [ ] Run: `npm run build`
- [ ] Run: `cd .. && firebase deploy --only functions`
- [ ] Copy the `stripeWebhook` function URL from Firebase Console

## 📡 Step 3: Configure Webhook (5 minutes)

- [ ] In Stripe Dashboard, go to **Developers** → **Webhooks**
- [ ] Click **Add endpoint**
- [ ] Paste your webhook URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook`
- [ ] Select these events:
  - ✅ `payment_intent.succeeded`
  - ✅ `payment_intent.payment_failed`
  - ✅ `payment_intent.canceled`
  - ✅ `payout.paid`
  - ✅ `payout.failed`
- [ ] Click **Add endpoint**
- [ ] Copy the **Signing secret** (`whsec_...`)

## ⚙️ Step 4: Configure Firebase (5 minutes)

- [ ] Open terminal
- [ ] Run: `firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"`
- [ ] Run: `firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"`
- [ ] Run: `cd functions && npm run build && cd ..`
- [ ] Run: `firebase deploy --only functions`

## ✅ Step 5: Test (5 minutes)

- [ ] Open your Flutter app
- [ ] Navigate to investment page
- [ ] Select "Debit/Credit Card (Stripe)"
- [ ] Use test card: `4242 4242 4242 4242`
- [ ] Complete payment
- [ ] Check Stripe Dashboard → **Payments** to see the payment
- [ ] Check Stripe Dashboard → **Webhooks** → Your endpoint → **Events** to see webhook events
- [ ] Check Firebase Console → **Firestore** → `investment_transactions` to see updated transaction

## 🏦 Step 6: Configure Payouts (For Profit Distribution)

- [ ] In Stripe Dashboard, go to **Settings** → **Payouts**
- [ ] Add your bank account
- [ ] Complete verification process
- [ ] **Note**: PKR may not be supported - check Stripe's currency support

## 📋 Important Notes

- **Test Mode**: Use test keys (`pk_test_...`, `sk_test_...`) for development
- **Live Mode**: Switch to live keys only when ready for production
- **⚠️ Currency Issue**: Your app uses PKR, but Stripe does NOT support PKR. You MUST change to USD or another supported currency in `stripe_config.dart`
- **Webhook URL**: For your project, it will be: `https://us-central1-carhive-bf048.cloudfunctions.net/stripeWebhook` (verify after deployment)
- **Webhook URL**: Must be publicly accessible (Firebase Functions are automatically public)

## 🐛 Common Issues

| Issue | Quick Fix |
|-------|-----------|
| Webhook not receiving events | Check URL is correct, verify webhook secret matches |
| Payment fails | Verify secret key is set in Firebase config |
| Payment sheet doesn't appear | Check publishable key in `stripe_config.dart` |
| Payout fails | Add and verify bank account in Stripe Dashboard |

## 📚 Full Documentation

For detailed instructions, see: `STRIPE_DASHBOARD_CONFIGURATION.md`

