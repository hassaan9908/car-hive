# 360° Video-to-Frames Implementation Guide

This document describes the complete implementation of the Glo3D-style smooth 360° car rotation feature using video-to-frames processing.

## Overview

The system converts a 15-20 second video of walking around a car into 90 smooth frames for a draggable 360° viewer with inertia and momentum.

## Architecture

### Frontend (Flutter)
- **Video Capture**: Records 15-20 second video with guiding UI
- **Backend Service**: Handles video upload and frame download
- **360 Viewer**: Smooth draggable viewer with momentum

### Backend (Python/FastAPI)
- **Frame Extraction**: Uses FFmpeg to extract frames at 30 FPS
- **Stabilization**: Uses OpenCV optical flow to stabilize camera movement
- **Rotation Calculation**: Tracks rotation positions from frame motion
- **Resampling**: Resamples to 90 frames for smooth 360° rotation
- **Frame Export**: Saves final frames as `360_000.jpg` through `360_089.jpg`

## Setup Instructions

### 1. Backend Setup

```bash
cd backend
pip install -r requirements.txt
```

**Requirements:**
- Python 3.8+
- FFmpeg installed on system
- OpenCV, NumPy, FastAPI, etc. (see `requirements.txt`)

**Start Server:**
```bash
python process.py
# Or
uvicorn process:app --host 0.0.0.0 --port 8000 --reload
```

The server will run on `http://localhost:8000`

### 2. Flutter Setup

The required packages are already added to `pubspec.yaml`:
- `camera` - Video recording
- `video_player` - Video playback (if needed)
- `path_provider` - File system access
- `gesture_x_detector` - Gesture detection (already included)
- `flutter_cache_manager` - Frame caching

Run:
```bash
flutter pub get
```

### 3. Configuration

Update the backend URL in `lib/services/backend_360_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000'; // Change for production
```

## Usage

### From Flutter App

1. **Navigate to Video Capture Screen:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => VideoCapture360Screen(
      onComplete: (frameUrls) {
        // Handle completion
      },
    ),
  ),
);
```

2. **Record Video:**
   - Tap the record button
   - Walk slowly around the car (15-20 seconds)
   - Keep the car centered in frame
   - Video auto-stops at 20 seconds or tap stop

3. **Processing:**
   - Video uploads automatically
   - Backend processes: extract → stabilize → resample
   - Progress shown in UI

4. **View Result:**
   - Preview button opens 360° viewer
   - Drag horizontally to rotate
   - Smooth momentum and inertia

### Debug Screen

Access the debug screen for testing:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const Debug360Screen(),
  ),
);
```

Features:
- Backend health check
- Direct video capture access
- Test viewer

## File Structure

```
carhive/
├── backend/
│   ├── process.py              # FastAPI backend server
│   ├── requirements.txt        # Python dependencies
│   ├── README.md               # Backend documentation
│   ├── run_backend.bat        # Windows startup script
│   └── run_backend.sh          # Linux/Mac startup script
│
├── lib/
│   ├── screens/
│   │   ├── video_capture_360_screen.dart  # Video recording UI
│   │   └── debug_360_screen.dart          # Debug/testing tools
│   ├── services/
│   │   └── backend_360_service.dart      # Backend API client
│   └── 360_viewer.dart                    # Smooth 360° viewer
│
└── pubspec.yaml                # Flutter dependencies
```

## API Endpoints

### POST /process360
Upload and process video file.

**Request:**
- `file`: MP4 video file (multipart/form-data)

**Response:**
```json
{
  "success": true,
  "session_id": "uuid",
  "frame_count": 90,
  "frame_urls": [
    "http://localhost:8000/frames/{session_id}/360_000.jpg",
    ...
  ]
}
```

### GET /frames/{session_id}/{filename}
Retrieve processed frame image.

### GET /health
Health check endpoint.

## Processing Pipeline Details

1. **Extract Frames** (FFmpeg)
   - Input: MP4 video
   - Output: `frame_0001.jpg`, `frame_0002.jpg`, ...
   - FPS: 30

2. **Stabilize Frames** (OpenCV)
   - Uses Lucas-Kanade optical flow
   - Tracks feature points between frames
   - Applies smoothing to reduce jitter
   - Output: Stabilized frames

3. **Compute Rotation** (OpenCV)
   - Calculates horizontal movement from optical flow
   - Tracks cumulative rotation position
   - Normalizes to 0 → 1 range

4. **Resample** (NumPy)
   - Maps rotation positions to 90 target frames
   - Ensures smooth distribution around 360°

5. **Export** (OpenCV)
   - Saves final frames: `360_000.jpg` → `360_089.jpg`
   - Ready for viewer

## 360 Viewer Features

- **Smooth Dragging**: Horizontal drag to rotate
- **Momentum/Inertia**: Continues rotation after drag ends
- **Frame Caching**: Pre-loads adjacent frames
- **Smooth Transitions**: Animated frame switching
- **Continuous Loop**: Wraps around seamlessly

## Integration with Existing Code

The new video capture can be used alongside the existing photo-based `Capture360Screen`:

```dart
// Option 1: Photo-based (existing)
Capture360Screen(...)

// Option 2: Video-based (new)
VideoCapture360Screen(...)
```

Both can be integrated into `postadcar.dart` or other upload flows.

## Troubleshooting

### Backend Not Responding
- Check if server is running: `http://localhost:8000/health`
- Verify FFmpeg is installed: `ffmpeg -version`
- Check Python dependencies: `pip list`

### Video Processing Fails
- Ensure video is MP4 format
- Check video duration (15-20 seconds recommended)
- Verify sufficient disk space for frames

### Viewer Not Smooth
- Check frame URLs are accessible
- Verify all 90 frames were generated
- Check network connection for remote frames

### Camera Not Working
- Verify camera permissions
- Check if device supports video recording
- Web platform doesn't support camera (use mobile)

## Performance Notes

- **Video Size**: Keep videos under 100MB for faster upload
- **Frame Count**: 90 frames provides smooth rotation
- **Processing Time**: ~30-60 seconds for 20-second video
- **Cache**: Frames are cached locally after download

## Future Enhancements

- Auto-rotation mode in viewer
- Frame interpolation for even smoother rotation
- Cloud storage integration
- Batch processing
- Progress indicators during processing
- Error recovery and retry logic


