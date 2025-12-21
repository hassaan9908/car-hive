# Quick Start Guide - 360° Video Feature

## 🚀 Fast Setup (5 Minutes)

### 1. Backend (Terminal 1)

```bash
# Navigate to backend
cd F:\flutter_workspace\FYP\carhive\backend

# Install dependencies
pip install -r requirements.txt

# Start server
python process.py
```

✅ **Verify:** Open browser → `http://localhost:8000/health` → Should show `{"status":"ok"}`

### 2. Flutter App (Terminal 2)

```bash
# Navigate to project root
cd F:\flutter_workspace\FYP\carhive

# Install packages
flutter pub get

# Run app
flutter run
```

### 3. Test Feature

1. Open app on device/emulator
2. Navigate to video capture screen
3. Record 15-20 second video
4. Wait for processing
5. View 360° rotation!

---

## ⚠️ Prerequisites

- **FFmpeg** must be installed
  - Windows: Download from https://ffmpeg.org/download.html
  - macOS: `brew install ffmpeg`
  - Linux: `sudo apt-get install ffmpeg`

- **Python 3.8+** installed
- **Flutter SDK** installed
- **Mobile device/emulator** (camera doesn't work on web)

---

## 🔧 Common Issues

**Backend won't start?**
- Check FFmpeg: `ffmpeg -version`
- Check Python: `python --version`
- Install dependencies: `pip install -r requirements.txt`

**Flutter errors?**
- Run: `flutter clean && flutter pub get`
- Check device: `flutter devices`

**Connection refused?**
- Verify backend is running: `http://localhost:8000/health`
- Check backend URL in `lib/services/backend_360_service.dart`

---

## 📖 Full Guide

See `RUN_APPLICATION_GUIDE.md` for detailed instructions.

---

## 🎯 What You'll See

1. **Video Capture Screen:**
   - Record button
   - Timer (0-20 seconds)
   - Instructions: "Walk slowly around the car"

2. **Processing:**
   - Progress bar
   - "Uploading video..." → "Processing video..."

3. **360° Viewer:**
   - Drag horizontally to rotate
   - Smooth momentum/inertia
   - 90 frames for smooth rotation

---

**Need help?** Check `RUN_APPLICATION_GUIDE.md` for troubleshooting!


