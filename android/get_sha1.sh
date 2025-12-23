#!/bin/bash
# Bash script to get SHA-1 fingerprint for Firebase
# Run this script to get your debug keystore SHA-1 fingerprint

echo "Getting SHA-1 fingerprint for debug keystore..."

# Default debug keystore location
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "Found debug keystore at: $DEBUG_KEYSTORE"
    echo ""
    echo "SHA-1 Fingerprint:"
    
    # Get SHA-1 fingerprint
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep SHA1
    
    echo ""
    echo "Copy the SHA-1 value (without colons) and add it to Firebase Console:"
    echo "1. Go to Firebase Console > Project Settings > Your Android App"
    echo "2. Click 'Add fingerprint'"
    echo "3. Paste the SHA-1 value (remove colons if present)"
    echo "4. Download the updated google-services.json"
    echo "5. Replace android/app/google-services.json with the new file"
else
    echo "Debug keystore not found at: $DEBUG_KEYSTORE"
    echo "Creating debug keystore..."
    
    # Create debug keystore if it doesn't exist
    mkdir -p "$(dirname "$DEBUG_KEYSTORE")"
    
    keytool -genkey -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if [ -f "$DEBUG_KEYSTORE" ]; then
        echo ""
        echo "SHA-1 Fingerprint:"
        keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep SHA1
    fi
fi

