# Fix Phone Authentication - Add SHA Fingerprints to Firebase

## ⚠️ Error You're Getting
"This app is not authorized to use Firebase Authentication. Please verify that the correct package name, SHA-1, and SHA-256 are configured in the Firebase Console."

## ✅ Solution: Add These Fingerprints to Firebase

### Your Current SHA Fingerprints:
- **SHA-1:** `26:63:EB:67:69:BB:DF:8C:15:7D:FE:22:B8:27:5E:B0:9F:06:39:E4`
- **SHA-256:** `52:62:00:67:92:FA:C5:68:DB:55:A3:FD:D8:3B:6E:36:60:12:30:1F:E1:3D:A6:E4:73:15:96:F3:DB:EF:A0:C0`

## 📋 Step-by-Step Instructions

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com/
2. Select your project: **carhive-bf048**

### Step 2: Navigate to Project Settings
1. Click the **gear icon ⚙️** next to "Project Overview"
2. Click **Project Settings**

### Step 3: Find Your Android App
1. Scroll down to the **Your apps** section
2. Look for the Android app with package name: `com.example.carhive`

### Step 4: Add SHA-1 Fingerprint
1. In your Android app section, find **SHA certificate fingerprints**
2. Click **Add fingerprint**
3. Paste: `26:63:EB:67:69:BB:DF:8C:15:7D:FE:22:B8:27:5E:B0:9F:06:39:E4`
4. Click **Save**

### Step 5: Add SHA-256 Fingerprint
1. Click **Add fingerprint** again
2. Paste: `52:62:00:67:92:FA:C5:68:DB:55:A3:FD:D8:3B:6E:36:60:12:30:1F:E1:3D:A6:E4:73:15:96:F3:DB:EF:A0:C0`
3. Click **Save**

### Step 6: Download Updated google-services.json
1. In the same Android app section, click **Download google-services.json**
2. Replace the file at: `android/app/google-services.json` with the newly downloaded file

### Step 7: Rebuild Your App
```bash
flutter clean
flutter pub get
flutter run
```

## ⏱️ Wait Time
After adding the fingerprints, **wait 5-10 minutes** for Firebase to propagate the changes, then try phone authentication again.

## ✅ What This Fixes
- ✅ Phone number verification will work
- ✅ SMS codes will be sent properly
- ✅ Firebase Authentication will be authorized
- ✅ Google Sign-In will work (if configured)
- ✅ All Firebase services will authenticate correctly

## 🔍 To Verify It's Working
1. Restart your app completely
2. Try phone number verification again
3. You should receive the SMS code without errors

## 📝 Note About Multiple Fingerprints
- Debug keystore fingerprint (what we just got) - for development/testing
- Release keystore fingerprint - needed when you publish to Play Store
- You'll need to add release fingerprints later when you create a release build

## ❓ Still Having Issues?
If you still see the error after following these steps:
1. Make sure you downloaded and replaced the google-services.json file
2. Wait a full 10 minutes after adding fingerprints
3. Run `flutter clean` and rebuild
4. Check that the package name in Firebase matches: `com.example.carhive`
