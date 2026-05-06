"""
Backend service for processing 360° car rotation videos.
Extracts evenly-spaced frames for smooth 360° rotation viewer.
"""
import sys
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

import os
import cv2
import numpy as np
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uuid
from pathlib import Path
import requests
import imageio_ffmpeg

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("/tmp/uploads")
OUTPUT_DIR  = Path("/tmp/output")

for directory in [UPLOAD_DIR, OUTPUT_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

CLOUDINARY_CLOUD_NAME = "dkcpilqiq"
CLOUDINARY_UPLOAD_PRESET = "unsigned_preset"
CLOUDINARY_UPLOAD_URL = f"https://api.cloudinary.com/v1_1/{CLOUDINARY_CLOUD_NAME}/image/upload"

TARGET_FRAMES = 24          # Final number of frames uploaded
OUTPUT_WIDTH  = 720         # All frames resized to this width
OUTPUT_HEIGHT = 480         # All frames resized to this height


def extract_evenly_spaced_frames(video_path: str, output_dir: str, target: int = TARGET_FRAMES) -> list[str]:
    """
    Open the video with OpenCV and pick exactly `target` evenly-spaced frames.
    No stabilization — the camera movement is intentional for a 360° capture.
    Returns list of saved filenames.
    """
    os.makedirs(output_dir, exist_ok=True)

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise Exception(f"Cannot open video: {video_path}")

    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if total <= 0:
        cap.release()
        raise Exception("Video reports 0 frames — file may be corrupt or in an unsupported format.")

    print(f"Video has {total} frames; extracting {target} evenly-spaced frames")

    # Evenly-spaced indices across the full video
    indices = np.linspace(0, total - 1, target, dtype=int)

    saved = []
    for i, idx in enumerate(indices):
        frame = _read_frame_at(cap, int(idx), total)
        if frame is None:
            print(f"⚠️  Could not read frame at index {idx}, skipping")
            continue

        frame = _clean_frame(frame)
        filename = f"360_{i:03d}.jpg"
        path = os.path.join(output_dir, filename)
        cv2.imwrite(path, frame, [cv2.IMWRITE_JPEG_QUALITY, 88])
        saved.append(filename)
        print(f"  Saved frame {i+1}/{target} (video idx {idx})")

    cap.release()

    if not saved:
        raise Exception("No frames could be extracted from the video.")

    print(f"Extracted {len(saved)} frames successfully")
    return saved


def _read_frame_at(cap: cv2.VideoCapture, idx: int, total: int):
    """Seek to `idx` and read. Tries a few offsets if the seek misses."""
    for offset in [0, 1, -1, 2, -2, 3]:
        target_idx = min(max(0, idx + offset), total - 1)
        cap.set(cv2.CAP_PROP_POS_FRAMES, target_idx)
        ret, frame = cap.read()
        if ret and frame is not None:
            return frame
    return None


def _clean_frame(img: np.ndarray) -> np.ndarray:
    """
    1. Crop any solid black borders introduced by encoding or camera.
    2. Resize to a consistent OUTPUT_WIDTH × OUTPUT_HEIGHT.
    Returns a clean, uniformly-sized frame.
    """
    img = _crop_black_borders(img)
    img = cv2.resize(img, (OUTPUT_WIDTH, OUTPUT_HEIGHT), interpolation=cv2.INTER_AREA)
    return img


def _crop_black_borders(img: np.ndarray, threshold: int = 15) -> np.ndarray:
    """
    Detect and remove solid black borders around the image.
    Uses a conservative threshold so we don't crop legitimate dark content.
    Falls back to the original image if no non-black content is found.
    """
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, mask = cv2.threshold(gray, threshold, 255, cv2.THRESH_BINARY)

    coords = cv2.findNonZero(mask)
    if coords is None:
        return img  # Entire frame is black — return as-is

    x, y, w, h = cv2.boundingRect(coords)

    # Require at least 40% of the frame to be non-black before cropping
    frame_area = img.shape[0] * img.shape[1]
    content_area = w * h
    if content_area < frame_area * 0.4:
        return img  # Cropping would remove too much — skip

    # Add a small margin so we don't cut right to the edge
    margin = 4
    x = max(0, x - margin)
    y = max(0, y - margin)
    x2 = min(img.shape[1], x + w + 2 * margin)
    y2 = min(img.shape[0], y + h + 2 * margin)

    return img[y:y2, x:x2]


def upload_frames_to_cloudinary(output_dir: str, frame_files: list[str], session_id: str) -> list[str]:
    """Upload frames to Cloudinary and return their secure URLs."""
    urls = []

    for i, filename in enumerate(frame_files):
        frame_path = os.path.join(output_dir, filename)
        if not os.path.exists(frame_path):
            print(f"Warning: frame file not found: {frame_path}")
            continue

        try:
            with open(frame_path, 'rb') as f:
                image_data = f.read()

            response = requests.post(
                CLOUDINARY_UPLOAD_URL,
                files={'file': (filename, image_data, 'image/jpeg')},
                data={
                    'upload_preset': CLOUDINARY_UPLOAD_PRESET,
                    'folder': f'360_frames/{session_id}',
                    'public_id': f'frame_{i:03d}',
                    'quality': 'auto:good',
                    'fetch_format': 'auto',
                },
                timeout=30,
            )

            if response.status_code == 200:
                url = response.json().get('secure_url')
                if url:
                    urls.append(url)
                    print(f"Uploaded frame {i+1}/{len(frame_files)}")
                else:
                    print(f"No secure_url in Cloudinary response for frame {i+1}")
            else:
                print(f"Cloudinary error for frame {i+1}: HTTP {response.status_code}")

        except Exception as e:
            print(f"Upload error for frame {i+1}: {e}")
            continue

    if len(urls) != len(frame_files):
        print(f"Warning: uploaded {len(urls)}/{len(frame_files)} frames")

    return urls


@app.post("/process360")
async def process_360_video(file: UploadFile = File(...)):
    """Receive a video, extract 24 clean evenly-spaced frames, upload to Cloudinary."""
    session_id = str(uuid.uuid4())
    video_path = UPLOAD_DIR / f"{session_id}.mp4"
    output_dir = str(OUTPUT_DIR / session_id)

    try:
        # Save uploaded video
        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail="Empty file uploaded")

        with open(video_path, "wb") as f:
            f.write(contents)

        print(f"Saved video ({len(contents)//1024} KB) → {video_path}")

        # Extract frames
        frame_files = extract_evenly_spaced_frames(
            str(video_path), output_dir, target=TARGET_FRAMES
        )

        # Upload to Cloudinary
        print(f"Uploading {len(frame_files)} frames to Cloudinary...")
        frame_urls = upload_frames_to_cloudinary(output_dir, frame_files, session_id)

        if not frame_urls:
            raise Exception("No frames were uploaded successfully")

        print(f"Done: {len(frame_urls)} frames uploaded")

        return JSONResponse({
            "success": True,
            "session_id": session_id,
            "frame_count": len(frame_urls),
            "frame_urls": frame_urls,
        })

    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"Processing error: {e}")
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")

    finally:
        # Clean up uploaded video to save disk space
        try:
            if video_path.exists():
                video_path.unlink()
        except Exception:
            pass


@app.get("/health")
async def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
