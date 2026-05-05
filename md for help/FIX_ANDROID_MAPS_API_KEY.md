# Fix Google Maps on Android Physical Device

## Problem
Google Maps works on web but shows blank screen on Android physical device.

## Root Causes
1. **Maps SDK for Android not enabled** in Google Cloud Console
2. **API key restrictions** - key might be restricted to web only
3. **API key not configured** for Android package name

## Solution Steps

### Step 1: Enable Maps SDK for Android

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **carhive-bf048** (or the project associated with your API key)
3. Navigate to **APIs & Services** → **Library**
4. Search for **"Maps SDK for Android"**
5. Click on it and click **Enable**
6. Also enable **"Maps SDK for iOS"** if you plan to support iOS

### Step 2: Check API Key Restrictions

1. Go to **APIs & Services** → **Credentials**
2. Find your API key: `AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk`
3. Click on the key to edit it
4. Check **Application restrictions**:
   - If set to **"HTTP referrers (web sites)"**, this is the problem!
   - Change it to **"Android apps"** or **"None"** (for development)
5. If using **"Android apps"** restriction:
   - Click **Add an item**
   - Package name: `com.example.carhive`
   - SHA-1 certificate fingerprint: `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`
6. Under **API restrictions**:
   - Make sure **"Maps SDK for Android"** is enabled
   - Also enable **"Maps SDK for iOS"** if needed
   - Enable **"Maps JavaScript API"** (for web)
7. Click **Save**

### Step 3: Verify API Key in AndroidManifest

Your `android/app/src/main/AndroidManifest.xml` should have:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAeUhpVe19ldAQV23mUXLRJopBih8X2qEk" />
```

✅ This is already correct in your project.

### Step 4: Clean Rebuild

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Step 5: Check Logcat for Errors

Run the app and check logcat for specific errors:
```bash
adb logcat | grep -i "maps\|google\|api"
```

Look for errors like:
- `API key not valid`
- `This API project is not authorized to use this API`
- `Maps SDK for Android not enabled`

## Alternative: Create Separate API Keys

If you want to keep web and Android keys separate:

1. **For Web**: Create a key restricted to HTTP referrers
2. **For Android**: Create a key restricted to Android apps with:
   - Package name: `com.example.carhive`
   - SHA-1: `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`

Then use the Android key in `AndroidManifest.xml` and the web key in `web/index.html`.

## Verify Fix

After making changes:
1. Wait 5-10 minutes for changes to propagate
2. Uninstall the app from your device
3. Rebuild and reinstall
4. The map should now display on Android

## Common Issues

### Issue: "API key not valid"
- **Fix**: Check API key restrictions in Google Cloud Console
- Ensure Maps SDK for Android is enabled

### Issue: "This API project is not authorized"
- **Fix**: Enable Maps SDK for Android in Google Cloud Console
- Check billing is enabled (required for Maps API)

### Issue: Map still blank after fixes
- **Fix**: 
  - Check internet connection on device
  - Verify Google Play Services is up to date
  - Check logcat for specific error messages
  - Try creating a new API key without restrictions (for testing)

