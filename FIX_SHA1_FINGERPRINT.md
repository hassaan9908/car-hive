# Fix Google Play Services Error - SHA-1 Fingerprint Issue

## Problem
The app crashes with this error when navigating to chat screen:
```
E/GoogleApiManager: Failed to get service from broker.
java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'
```

This happens because the SHA-1 fingerprint of your app doesn't match what's registered in Firebase Console.

## Solution

### Step 1: Get Your SHA-1 Fingerprint

**On Windows (PowerShell):**
```powershell
cd android
.\get_sha1.ps1
```

**On macOS/Linux:**
```bash
cd android
chmod +x get_sha1.sh
./get_sha1.sh
```

**Or manually:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA1** line and copy the fingerprint (it will look like: `AA:BB:CC:DD:EE:FF:...`)

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **carhive-bf048**
3. Click the gear icon ⚙️ next to "Project Overview"
4. Select **Project Settings**
5. Scroll down to **Your apps** section
6. Find your Android app (`com.example.carhive`)
7. Click **Add fingerprint**
8. Paste your SHA-1 fingerprint (you can remove the colons or keep them)
9. Click **Save**

### Step 3: Download Updated google-services.json

1. In the same Firebase Console page, scroll to **Your apps** section
2. Click the **Download google-services.json** button
3. Replace `android/app/google-services.json` with the new file

### Step 4: Rebuild the App

```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## For Release Builds

If you're building a release version, you'll also need to add the release keystore SHA-1:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

Add this SHA-1 fingerprint to Firebase Console as well.

## Temporary Fix (Already Applied)

I've commented out Firebase Analytics in `android/app/build.gradle` to prevent the crash. However, you should still add the SHA-1 fingerprint for proper Google Sign-In and other Firebase features to work correctly.

## Verify Fix

After adding the SHA-1 fingerprint and rebuilding:
1. Navigate to the chat screen
2. The error should no longer appear in logs
3. Google Sign-In should work properly

