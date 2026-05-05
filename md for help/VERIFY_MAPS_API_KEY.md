# Verify Maps SDK for Android API Key Configuration

## Your API Key
`AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk`

## Step-by-Step Verification

### 1. Check API Key Restrictions

Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)

1. Find your API key: `AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk`
2. Click on it to edit

**Check "Application restrictions":**
- ✅ **Should be**: "Android apps" or "None" (for development)
- ❌ **Problem if**: "HTTP referrers (web sites)" - this only allows web, not Android

**If using "Android apps" restriction, verify:**
- Package name: `com.example.carhive`
- SHA-1 certificate fingerprint: `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`

**Check "API restrictions":**
- ✅ Must include: **"Maps SDK for Android"**
- ✅ Should also include: **"Maps JavaScript API"** (for web)
- ✅ Optional: **"Maps SDK for iOS"** (if supporting iOS)

### 2. Verify Maps SDK for Android is Enabled

Go to [Google Cloud Console - APIs & Services - Library](https://console.cloud.google.com/apis/library)

1. Search for **"Maps SDK for Android"**
2. Check if it shows **"Enabled"** (green checkmark)
3. If not enabled, click **"Enable"**

Also verify these are enabled:
- ✅ Maps SDK for Android
- ✅ Maps JavaScript API (for web)
- ✅ Maps SDK for iOS (if needed)

### 3. Check Billing

Google Maps requires billing to be enabled:
1. Go to [Google Cloud Console - Billing](https://console.cloud.google.com/billing)
2. Ensure billing account is linked to your project
3. Google provides $200 free credit per month for Maps API

### 4. Test API Key

You can test if the API key works for Android by checking the response:

**Test URL (replace YOUR_API_KEY):**
```
https://maps.googleapis.com/maps/api/geocode/json?address=Karachi&key=AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk
```

If you get a response, the key is valid. If you get an error about restrictions, the key is restricted.

### 5. Common Issues and Fixes

#### Issue: "API key not valid. Please pass a valid API key."
- **Fix**: Check API key is correct in AndroidManifest.xml
- **Fix**: Ensure Maps SDK for Android is enabled

#### Issue: "This API project is not authorized to use this API"
- **Fix**: Enable Maps SDK for Android in Google Cloud Console
- **Fix**: Check API restrictions include "Maps SDK for Android"

#### Issue: "This IP, site or mobile application is not authorized to use this API key"
- **Fix**: Change Application restrictions from "HTTP referrers" to "Android apps"
- **Fix**: Add package name and SHA-1 fingerprint

#### Issue: Map works on web but blank on Android
- **Fix**: API key is likely restricted to web only
- **Fix**: Change Application restrictions to "Android apps" or "None"
- **Fix**: Add Android package name and SHA-1

### 6. Quick Fix for Development

For quick testing, you can temporarily:
1. Set Application restrictions to **"None"**
2. Set API restrictions to **"Don't restrict key"**
3. This allows the key to work everywhere (less secure, but good for testing)
4. Once confirmed working, add proper restrictions

### 7. After Making Changes

1. **Wait 5-10 minutes** for changes to propagate
2. **Uninstall the app** from your device
3. **Clean rebuild**:
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

## Current Configuration in Your Project

✅ **AndroidManifest.xml** - API key is correctly configured:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk" />
```

✅ **Package name**: `com.example.carhive`

✅ **SHA-1 fingerprint**: `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`

## Next Steps

1. Verify the API key restrictions in Google Cloud Console
2. Ensure Maps SDK for Android is enabled
3. Add Android app restriction with package name and SHA-1
4. Rebuild and test

