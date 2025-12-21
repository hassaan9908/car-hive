# How to Access the 360° Video Feature

## ✅ The Feature is Now Accessible!

I've added the video capture option to your app. Here's where to find it:

## 📍 Location in App

### Method 1: From Post Ad Screen (Recommended)

1. **Open the app**
2. **Navigate to "Sell Your Car" / Post Ad screen**
3. **Scroll down to "360° View Photos" section**
4. **You'll see TWO options:**
   - **Photo Capture (16 angles)** - Original method
   - **Video Capture (90 frames) NEW** - New video-based method ⭐

5. **Tap "Video Capture (90 frames)"** to start!

### Method 2: Using Routes (For Testing)

You can also access it directly using routes:

```dart
// Navigate to video capture
Navigator.pushNamed(context, '/video-360-capture');

// Or navigate to debug screen
Navigator.pushNamed(context, '/debug-360');
```

### Method 3: Debug Screen

1. Navigate to: `/debug-360`
2. Tap "Capture 360° Video"

---

## 🎯 What You'll See

When you tap "Video Capture (90 frames) NEW":

1. **Video Capture Screen opens**
   - **On Mobile**: Camera preview with record button
   - **On Web**: File upload button (since camera doesn't work on web)

2. **Record Video:**
   - Tap record button
   - Walk slowly around car (15-20 seconds)
   - Keep car centered in frame

3. **Processing:**
   - Video uploads automatically
   - Backend processes it (30-60 seconds)
   - Progress bar shows status

4. **Result:**
   - 90 smooth frames generated
   - Preview 360° viewer opens
   - Drag to rotate with smooth momentum!

---

## 🔧 If You Don't See It

### Check These:

1. **Restart the app:**
   ```bash
   flutter run
   ```

2. **Hot reload might not be enough:**
   - Stop the app
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run `flutter run`

3. **Check the route is added:**
   - Open `lib/main.dart`
   - Look for `/video-360-capture` in routes

4. **Verify backend is running:**
   - Backend must be running on `http://localhost:8000`
   - Check: `http://localhost:8000/health`

---

## 📱 Screenshot Guide

**In Post Ad Screen:**
```
┌─────────────────────────────────┐
│  360° View Photos              │
│  ─────────────────────────────  │
│                                 │
│  [📷] Photo Capture (16 angles)│
│      Take 16 photos around car  │
│                                 │
│  [🎥] Video Capture (90 frames)│
│      Record 15-20 sec video     │
│      [NEW]                      │
└─────────────────────────────────┘
```

---

## 🚀 Quick Test

1. **Start backend** (Terminal 1):
   ```bash
   cd backend
   python process.py
   ```

2. **Run app** (Terminal 2):
   ```bash
   flutter run
   ```

3. **Navigate:**
   - Go to Post Ad screen
   - Scroll to 360° section
   - Tap "Video Capture (90 frames) NEW"

4. **Test:**
   - Record a video
   - Wait for processing
   - View 360° rotation!

---

## 💡 Tips

- **Mobile**: Use camera to record directly
- **Web**: Upload a pre-recorded video file
- **Best Results**: Walk slowly, keep car centered
- **Duration**: 15-20 seconds is optimal

---

**The feature is ready to use!** 🎉


