# ⚠️ Critical Stripe Configuration Issues

## 🚨 Issue #1: Currency Not Supported

### Problem
Your app is configured to use **PKR (Pakistani Rupee)** in `lib/config/stripe_config.dart`, but **Stripe does NOT support PKR**.

### Impact
- Payment intents will fail when created
- Users cannot complete payments
- Error: "Currency 'pkr' is not supported"

### Solution
**You MUST change the currency to a supported one:**

1. Open `lib/config/stripe_config.dart`
2. Change line 11 from:
   ```dart
   static const String currency = 'pkr';
   ```
   To:
   ```dart
   static const String currency = 'usd'; // or 'eur', 'gbp', etc.
   ```

3. **If you need to show PKR to users:**
   - Convert PKR amounts to USD before sending to Stripe
   - Display both PKR and USD amounts to users
   - Use a conversion rate (e.g., 1 USD = ~280 PKR)

### Supported Currencies
Check Stripe's supported currencies: [https://stripe.com/docs/currencies](https://stripe.com/docs/currencies)

Common options:
- **USD** (US Dollar) - Most widely supported
- **EUR** (Euro)
- **GBP** (British Pound)
- **AED** (UAE Dirham) - If targeting Middle East

---

## 🔧 Issue #2: Missing Firebase Configuration

### Problem
Your Stripe secret key and webhook secret are not configured in Firebase.

### Impact
- Cloud Functions cannot create payment intents
- Webhooks will fail signature verification
- Payments will not work

### Solution
1. Get your Stripe secret key from Stripe Dashboard (Developers → API keys)
2. Get your webhook secret (after setting up webhook endpoint)
3. Configure Firebase:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_test_YOUR_KEY"
   firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"
   ```
4. Redeploy functions:
   ```bash
   cd functions
   npm run build
   cd ..
   firebase deploy --only functions
   ```

---

## 📡 Issue #3: Webhook Not Configured

### Problem
Stripe webhook endpoint is not set up in Stripe Dashboard.

### Impact
- Payment status updates won't reach your app
- Firestore won't update automatically
- Investments won't activate after payment

### Solution
1. Deploy your Cloud Functions first (see Issue #2)
2. Get your webhook URL from Firebase Console (Functions section)
3. In Stripe Dashboard:
   - Go to Developers → Webhooks
   - Click "Add endpoint"
   - Enter your webhook URL: `https://us-central1-carhive-bf048.cloudfunctions.net/stripeWebhook`
   - Select events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `payment_intent.canceled`, `payout.paid`, `payout.failed`
   - Copy the signing secret and add it to Firebase config

---

## ✅ Quick Fix Checklist

Before testing payments, ensure:

- [ ] **Currency changed from PKR to USD** in `stripe_config.dart`
- [ ] **Stripe secret key** added to Firebase config
- [ ] **Webhook endpoint** created in Stripe Dashboard
- [ ] **Webhook secret** added to Firebase config
- [ ] **Cloud Functions deployed** after configuration
- [ ] **Test payment** completed successfully

---

## 📚 Next Steps

1. **Fix the currency issue first** (most critical)
2. **Follow the setup guide**: `STRIPE_DASHBOARD_CONFIGURATION.md`
3. **Use the quick checklist**: `STRIPE_QUICK_SETUP_CHECKLIST.md`

---

## 🆘 Need Help?

If you're still having issues:
1. Check Firebase Functions logs: `firebase functions:log`
2. Check Stripe Dashboard → Developers → Logs
3. Review webhook events in Stripe Dashboard
4. Verify all keys are correct and match (test/test or live/live)

