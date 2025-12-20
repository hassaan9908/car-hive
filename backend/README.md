# 360° Video Processing Backend

This backend service processes uploaded videos to generate smooth 360° car rotation sequences.

## Setup

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Ensure FFmpeg is installed on your system:
   - Windows: Download from https://ffmpeg.org/download.html
   - macOS: `brew install ffmpeg`
   - Linux: `sudo apt-get install ffmpeg`

3. Run the server:
```bash
python process.py
```

Or using uvicorn directly:
```bash
uvicorn process:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### POST /process360
Upload a video file (MP4) for processing.

**Request:**
- Content-Type: multipart/form-data
- Body: `file` (video file)

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
Retrieve a processed frame image.

### GET /health
Health check endpoint.

## Processing Pipeline

1. **Extract frames**: Uses FFmpeg to extract frames at 30 FPS
2. **Stabilize frames**: Uses OpenCV optical flow to stabilize camera movement
3. **Compute rotation**: Calculates rotation positions from frame motion
4. **Resample**: Resamples to 90 frames for smooth 360° rotation
5. **Export**: Saves final frames as `360_000.jpg` through `360_089.jpg`

## Configuration

Update the `baseUrl` in `lib/services/backend_360_service.dart` to match your backend URL.

For production, update CORS settings in `process.py` to restrict origins.


