# Step-by-Step Guide: Running the 360° Video Feature

This guide will walk you through setting up and running both the backend server and Flutter app.

## Prerequisites

Before starting, ensure you have:
- ✅ Python 3.8 or higher installed
- ✅ FFmpeg installed on your system
- ✅ Flutter SDK installed
- ✅ A mobile device or emulator for testing (camera doesn't work on web)

---

## Part 1: Backend Setup

### Step 1: Install FFmpeg

**Windows:**
1. Download FFmpeg from: https://ffmpeg.org/download.html
2. Extract to a folder (e.g., `C:\ffmpeg`)
3. Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\ffmpeg\bin`
4. Verify: Open Command Prompt and run:
   ```bash
   ffmpeg -version
   ```

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install ffmpeg
```

### Step 2: Navigate to Backend Directory

Open terminal/command prompt and navigate to the backend folder:

```bash
cd F:\flutter_workspace\FYP\carhive\backend
```

### Step 3: Create Virtual Environment (Recommended)

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### Step 4: Install Python Dependencies

```bash
pip install -r requirements.txt
```

This will install:
- fastapi
- uvicorn
- opencv-python
- ffmpeg-python
- scikit-image
- numpy
- python-multipart

### Step 5: Start the Backend Server

**Option A: Using Python directly**
```bash
python process.py
```

**Option B: Using uvicorn (with auto-reload)**
```bash
uvicorn process:app --host 0.0.0.0 --port 8000 --reload
```

**Option C: Using the provided scripts**

Windows:
```bash
run_backend.bat
```

macOS/Linux:
```bash
chmod +x run_backend.sh
./run_backend.sh
```

### Step 6: Verify Backend is Running

Open your browser and go to:
```
http://localhost:8000/health
```

You should see:
```json
{"status":"ok"}
```

**✅ Backend is now running!** Keep this terminal window open.

---

## Part 2: Flutter App Setup

### Step 1: Navigate to Project Root

Open a **new** terminal/command prompt:

```bash
cd F:\flutter_workspace\FYP\carhive
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

This will install all packages including the newly added `flutter_cache_manager`.

### Step 3: Check Flutter Setup

```bash
flutter doctor
```

Ensure everything is properly configured.

### Step 4: Connect Device or Start Emulator

**For Physical Device:**
- Connect your Android/iOS device via USB
- Enable USB debugging (Android) or trust computer (iOS)
- Verify connection:
  ```bash
  flutter devices
  ```

**For Emulator:**
- Start Android Studio Emulator or iOS Simulator
- Verify it's running:
  ```bash
  flutter devices
  ```

**⚠️ Important:** Camera/video recording doesn't work on web, so use a mobile device or emulator.

### Step 5: Run the Flutter App

```bash
flutter run
```

Or specify a device:
```bash
flutter run -d <device-id>
```

The app will build and launch on your device.

---

## Part 3: Testing the 360° Video Feature

### Method 1: Using Debug Screen

1. **Navigate to Debug Screen:**
   - In the app, you can add a route or button to access:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => const Debug360Screen(),
     ),
   );
   ```

2. **Test Backend Connection:**
   - Tap "Backend Health Check"
   - Should show "Backend is healthy! ✓"

3. **Capture Video:**
   - Tap "Capture 360° Video"
   - Follow the on-screen instructions
   - Record 15-20 seconds walking around a car

### Method 2: Direct Integration

If you've integrated it into your upload flow:

1. Go to the car posting/upload screen
2. Look for "360° Video Capture" option
3. Tap to start recording

### Step-by-Step Video Capture:

1. **Start Recording:**
   - Tap the red record button
   - Timer starts counting (0s, 1s, 2s...)

2. **Record Video:**
   - Walk slowly around the car
   - Keep the car centered in the frame
   - Record for 15-20 seconds
   - Auto-stops at 20 seconds, or tap stop manually

3. **Processing:**
   - Video uploads automatically
   - Progress bar shows: "Uploading video..." → "Processing video..."
   - Wait for completion (30-60 seconds)

4. **View Result:**
   - Tap "Preview" to see 360° rotation
   - Drag horizontally to rotate
   - Experience smooth momentum/inertia

---

## Part 4: Configuration (If Needed)

### Change Backend URL

If your backend is running on a different machine or port:

1. Open: `lib/services/backend_360_service.dart`
2. Find line:
   ```dart
   static const String baseUrl = 'http://localhost:8000';
   ```
3. Change to your backend URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8000'; // Example: your computer's IP
   ```

### For Network Access (Mobile Device)

If testing on a physical device:

1. **Find your computer's IP address:**
   - Windows: `ipconfig` (look for IPv4 Address)
   - macOS/Linux: `ifconfig` or `ip addr`

2. **Update backend URL** in `backend_360_service.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000';
   ```

3. **Allow firewall access:**
   - Windows: Allow Python/uvicorn through firewall
   - macOS: System Preferences → Security → Firewall

4. **Update CORS in backend** (if needed):
   - Open `backend/process.py`
   - Modify CORS settings if you get connection errors

---

## Troubleshooting

### Backend Issues

**Problem: "Module not found"**
```bash
# Solution: Reinstall dependencies
pip install -r requirements.txt
```

**Problem: "FFmpeg not found"**
```bash
# Verify FFmpeg is installed
ffmpeg -version

# If not found, add to PATH or reinstall
```

**Problem: "Port 8000 already in use"**
```bash
# Option 1: Kill process using port 8000
# Windows:
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Option 2: Use different port
uvicorn process:app --port 8001
# Then update baseUrl in Flutter
```

**Problem: "Connection refused"**
- Check backend is running: `http://localhost:8000/health`
- Verify firewall settings
- Check if using correct IP address for mobile device

### Flutter Issues

**Problem: "Package not found"**
```bash
flutter clean
flutter pub get
```

**Problem: "Camera not working"**
- Ensure you're using a physical device or emulator (not web)
- Check camera permissions in device settings
- Restart the app

**Problem: "Video upload fails"**
- Check backend is running
- Verify network connection
- Check backend URL is correct
- Look at backend terminal for error messages

**Problem: "Processing takes too long"**
- Normal: 30-60 seconds for 20-second video
- Check backend terminal for progress
- Ensure sufficient disk space

### Video Processing Issues

**Problem: "No frames generated"**
- Check video format (should be MP4)
- Verify video duration (15-20 seconds recommended)
- Check backend terminal for errors
- Ensure FFmpeg is working correctly

**Problem: "Frames are blurry/jumpy"**
- Walk slower around the car
- Keep camera steady
- Ensure good lighting
- Keep car centered in frame

---

## Quick Start Checklist

- [ ] FFmpeg installed and in PATH
- [ ] Python dependencies installed (`pip install -r requirements.txt`)
- [ ] Backend server running (`python process.py`)
- [ ] Backend health check passes (`http://localhost:8000/health`)
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] Device/emulator connected (`flutter devices`)
- [ ] App running (`flutter run`)
- [ ] Backend URL configured correctly (if using network)

---

## Testing Workflow

1. **Start Backend** (Terminal 1)
   ```bash
   cd backend
   python process.py
   ```

2. **Start Flutter App** (Terminal 2)
   ```bash
   cd F:\flutter_workspace\FYP\carhive
   flutter run
   ```

3. **Test Feature**
   - Open app
   - Navigate to video capture
   - Record video
   - Wait for processing
   - View 360° rotation

---

## Next Steps

Once everything is working:

1. **Integrate into your app:**
   - Add `VideoCapture360Screen` to your upload flow
   - Update `postadcar.dart` or similar files

2. **Customize:**
   - Adjust frame count (default: 90)
   - Modify processing parameters
   - Customize UI colors/styles

3. **Deploy:**
   - Deploy backend to cloud (Heroku, AWS, etc.)
   - Update backend URL in Flutter
   - Build release version of app

---

## Support

If you encounter issues:

1. Check backend terminal for error messages
2. Check Flutter console for errors
3. Verify all prerequisites are installed
4. Review the `360_IMPLEMENTATION.md` for technical details
5. Check `backend/README.md` for API documentation

---

**Happy coding! 🚗✨**

