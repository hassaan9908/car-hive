# Check API Restrictions for Maps SDK

## Current Status
✅ **Application restrictions**: Set to "None" - This is correct!
⚠️ **API restrictions**: Set to "Restrict key" - Need to verify which APIs are enabled

## Next Steps

### 1. Check Which APIs Are Enabled

In the Google Cloud Console, under "API restrictions" → "Restrict key":
1. Click on the dropdown or list to see which APIs are selected
2. **Verify these APIs are enabled:**
   - ✅ **Maps SDK for Android** (REQUIRED for Android)
   - ✅ **Maps JavaScript API** (for web - already working)
   - ✅ **Maps SDK for iOS** (if you plan to support iOS)

### 2. If Maps SDK for Android is Missing

If "Maps SDK for Android" is NOT in the list:
1. Click "Select APIs" or the edit button
2. Search for "Maps SDK for Android"
3. Check the box to enable it
4. Click "Save"

### 3. Verify Maps SDK for Android is Enabled in Project

Even if it's in the API restrictions, you need to enable it in your project:

1. Go to: https://console.cloud.google.com/apis/library
2. Search for **"Maps SDK for Android"**
3. Check if it shows **"Enabled"** (green checkmark)
4. If not, click **"Enable"**

### 4. Common Issues

#### Issue: Maps SDK for Android not in API restrictions list
- **Fix**: Enable "Maps SDK for Android" in your project first (step 3)
- Then add it to the API restrictions

#### Issue: API shows "Enabled" but map still doesn't work
- **Fix**: Wait 5-10 minutes for changes to propagate
- **Fix**: Uninstall app and reinstall
- **Fix**: Clean rebuild: `flutter clean && flutter pub get && cd android && ./gradlew clean`

## Quick Test

After making changes, test by:
1. Uninstalling the app from your device
2. Running: `flutter clean && flutter pub get && flutter run`
3. Check logcat for errors: `adb logcat | grep -i "maps\|api"`

## Expected Result

Once "Maps SDK for Android" is:
- ✅ Enabled in your Google Cloud project
- ✅ Added to API restrictions
- ✅ API key has "None" for application restrictions (already done)

The map should work on your Android device!

