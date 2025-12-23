# PowerShell script to get SHA-1 fingerprint for Firebase
# Run this script to get your debug keystore SHA-1 fingerprint

Write-Host "Getting SHA-1 fingerprint for debug keystore..." -ForegroundColor Green

# Default debug keystore location
$debugKeystore = "$env:USERPROFILE\.android\debug.keystore"

if (Test-Path $debugKeystore) {
    Write-Host "Found debug keystore at: $debugKeystore" -ForegroundColor Yellow
    Write-Host "`nSHA-1 Fingerprint:" -ForegroundColor Cyan
    
    # Get SHA-1 fingerprint
    keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
    
    Write-Host "`nCopy the SHA-1 value (without colons) and add it to Firebase Console:" -ForegroundColor Green
    Write-Host "1. Go to Firebase Console > Project Settings > Your Android App" -ForegroundColor White
    Write-Host "2. Click 'Add fingerprint'" -ForegroundColor White
    Write-Host "3. Paste the SHA-1 value (remove colons if present)" -ForegroundColor White
    Write-Host "4. Download the updated google-services.json" -ForegroundColor White
    Write-Host "5. Replace android/app/google-services.json with the new file" -ForegroundColor White
} else {
    Write-Host "Debug keystore not found at: $debugKeystore" -ForegroundColor Red
    Write-Host "Creating debug keystore..." -ForegroundColor Yellow
    
    # Create debug keystore if it doesn't exist
    $androidDir = Split-Path $debugKeystore
    if (-not (Test-Path $androidDir)) {
        New-Item -ItemType Directory -Path $androidDir -Force | Out-Null
    }
    
    keytool -genkey -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if (Test-Path $debugKeystore) {
        Write-Host "`nSHA-1 Fingerprint:" -ForegroundColor Cyan
        keytool -list -v -keystore $debugKeystore -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1"
    }
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

