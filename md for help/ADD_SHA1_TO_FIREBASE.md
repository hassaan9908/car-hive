# Add Correct SHA-1 and SHA-256 to Firebase Console

## Current Situation

**Firebase Console shows:** `da:39:a3:ee:5e:6b:4b:0d:32:55:bf:ef:95:60:18:90:af:d8:07:09` (This is incorrect - it's the hash of an empty string)

**Your actual debug keystore fingerprints:**
- **SHA-1:** `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`
- **SHA-256:** `D3:B6:47:EE:71:B6:63:1D:2B:09:0E:EB:8C:9B:15:2A:84:02:10:33:89:EE:7F:61:16:04:D0:B6:8E:40:2B:0B`

## Steps to Fix

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project: **carhive-bf048**

2. **Navigate to Project Settings:**
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select **Project Settings**

3. **Find Your Android App:**
   - Scroll down to **Your apps** section
   - Find the app with package name: `com.example.carhive`

4. **Add the Correct SHA-1:**
   - Click **Add fingerprint** button
   - Paste this SHA-1: `8E:52:EB:31:49:B6:29:44:D8:A7:EE:3F:03:0B:59:8E:BF:07:E0:41`
   - You can paste it with or without colons (Firebase accepts both formats)
   - Click **Save**

5. **Add the SHA-256 (Important for Google Play Services):**
   - Click **Add fingerprint** button again
   - Paste this SHA-256: `D3:B6:47:EE:71:B6:63:1D:2B:09:0E:EB:8C:9B:15:2A:84:02:10:33:89:EE:7F:61:16:04:D0:B6:8E:40:2B:0B`
   - You can paste it with or without colons (Firebase accepts both formats)
   - Click **Save**

6. **Remove the Incorrect SHA-1 (Optional but Recommended):**
   - Click the trash icon next to the incorrect SHA-1: `da:39:a3:ee:5e:6b:4b:0d:32:55:bf:ef:95:60:18:90:af:d8:07:09`
   - Confirm deletion

7. **Download Updated google-services.json:**
   - In the same page, scroll to **Your apps** section
   - Click **Download google-services.json** button
   - Replace `android/app/google-services.json` with the new file

8. **Rebuild the App:**
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   flutter run
   ```

## After Adding SHA-1 and SHA-256

Once you add both fingerprints:
- ✅ Google Play Services errors will be resolved
- ✅ Google Sign-In will work properly
- ✅ Phone number verification will work
- ✅ The chat screen will no longer crash
- ✅ Google Maps will load correctly (no more blank white screen)
- ✅ Firebase services will authenticate correctly

## Why Both SHA-1 and SHA-256?

- **SHA-1** is required for Firebase Authentication and Google Sign-In
- **SHA-256** is required for Google Play Integrity (used by Google Play Services)
- Modern Android apps require SHA-256 for Play Integrity checks
- Both are needed for full functionality

## Note

The SHA-1 `da:39:a3:ee:5e:6b:4b:0d:32:55:bf:ef:95:60:18:90:af:d8:07:09` is the SHA-1 hash of an empty string, which is why Google Play Services is rejecting it. This is likely a placeholder that was never updated with the actual keystore fingerprint.

