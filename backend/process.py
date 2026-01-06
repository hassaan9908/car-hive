"""
Backend service for processing 360° car rotation videos.
Converts video → stabilized frames → resampled → smooth 360 sequence.
"""

import os
import cv2
import numpy as np
import ffmpeg
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import shutil
import uuid
from pathlib import Path
import requests
import base64

app = FastAPI()

# CORS middleware to allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directory structure
BASE_DIR = Path(__file__).parent.parent
UPLOAD_DIR = BASE_DIR / "uploads"
EXTRACT_DIR = BASE_DIR / "extracted"
STABILIZED_DIR = BASE_DIR / "stabilized"
OUTPUT_DIR = BASE_DIR / "output"

# Create directories if they don't exist
for directory in [UPLOAD_DIR, EXTRACT_DIR, STABILIZED_DIR, OUTPUT_DIR]:
    directory.mkdir(parents=True, exist_ok=True)

# Cloudinary configuration
CLOUDINARY_CLOUD_NAME = "dkcpilqiq"
CLOUDINARY_UPLOAD_PRESET = "unsigned_preset"
CLOUDINARY_UPLOAD_URL = f"https://api.cloudinary.com/v1_1/{CLOUDINARY_CLOUD_NAME}/image/upload"

# FFmpeg configuration
# If FFmpeg is not in PATH, specify the full path here
# Example: FFMPEG_PATH = r"C:\ffmpeg\bin\ffmpeg.exe"
FFMPEG_PATH = r"C:\Users\Administrator\AppData\Local\ffmpeg-2025-12-04-git-d6458f6a8b-essentials_build\bin\ffmpeg.exe"  # Direct path to FFmpeg executable
# Alternative: Set environment variable FFMPEG_PATH and use: FFMPEG_PATH = os.getenv('FFMPEG_PATH', None)


def extract_frames(video_path, output_dir):
    """Extract frames from video using FFmpeg."""
    import subprocess
    import shutil
    
    # Ensure paths are absolute and directories exist
    video_path = os.path.abspath(str(video_path))
    output_dir = os.path.abspath(str(output_dir))
    os.makedirs(output_dir, exist_ok=True)
    
    # Verify video file exists
    if not os.path.exists(video_path):
        raise Exception(f"Video file not found: {video_path}")
    
    # Check file size
    file_size = os.path.getsize(video_path)
    if file_size == 0:
        raise Exception(f"Video file is empty: {video_path}")
    
    # Find FFmpeg executable
    # Python's subprocess may not have the same PATH as your terminal
    ffmpeg_exe = None
    
    # First, check if FFMPEG_PATH is set (environment variable or config)
    if FFMPEG_PATH and os.path.exists(FFMPEG_PATH):
        ffmpeg_exe = FFMPEG_PATH
        print(f"Using FFmpeg from FFMPEG_PATH: {ffmpeg_exe}")
    else:
        # Try to find in PATH
        ffmpeg_exe = shutil.which('ffmpeg')
        if ffmpeg_exe:
            print(f"Found FFmpeg in PATH: {ffmpeg_exe}")
    
    if not ffmpeg_exe:
        # Try common Windows locations
        username = os.getenv('USERNAME', '')
        common_paths = [
            r'C:\ffmpeg\bin\ffmpeg.exe',
            r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
            r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
            r'C:\tools\ffmpeg\bin\ffmpeg.exe',
            rf'C:\Users\{username}\ffmpeg\bin\ffmpeg.exe' if username else None,
            rf'C:\Users\{username}\AppData\Local\ffmpeg\bin\ffmpeg.exe' if username else None,
        ]
        # Filter out None values
        common_paths = [p for p in common_paths if p]
        
        for path in common_paths:
            if os.path.exists(path):
                ffmpeg_exe = path
                print(f"Found FFmpeg at: {ffmpeg_exe}")
                break
    
    if not ffmpeg_exe:
        # Try to get PATH from environment and search
        path_env = os.getenv('PATH', '')
        path_dirs = path_env.split(os.pathsep)
        for path_dir in path_dirs:
            potential_ffmpeg = os.path.join(path_dir, 'ffmpeg.exe')
            if os.path.exists(potential_ffmpeg):
                ffmpeg_exe = potential_ffmpeg
                print(f"Found FFmpeg in PATH: {ffmpeg_exe}")
                break
    
    if not ffmpeg_exe:
        raise Exception(
            "FFmpeg not found. Even though 'ffmpeg -version' works in your terminal, "
            "Python cannot find it. This usually means:\n"
            "1. FFmpeg is in your user PATH but not system PATH\n"
            "2. The terminal where FFmpeg works has a different PATH than Python\n\n"
            "Solution: Add FFmpeg to SYSTEM PATH (not just user PATH):\n"
            "1. Win+R → sysdm.cpl → Advanced → Environment Variables\n"
            "2. Under 'System variables', edit 'Path'\n"
            "3. Add the directory containing ffmpeg.exe (e.g., C:\\ffmpeg\\bin)\n"
            "4. Restart your backend server"
        )
    
    try:
        # Use subprocess directly for better error handling
        output_pattern = os.path.join(output_dir, "frame_%04d.jpg")
        
        # Build FFmpeg command - use full path to FFmpeg
        cmd = [
            ffmpeg_exe,
            '-i', video_path,
            '-vf', 'fps=30',
            '-qscale:v', '2',
            '-y',  # Overwrite output files
            output_pattern
        ]
        
        # Run FFmpeg
        print(f"Running FFmpeg command: {' '.join(cmd)}")
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            error_msg = result.stderr or result.stdout or "Unknown FFmpeg error"
            print(f"FFmpeg error output: {error_msg}")
            print(f"FFmpeg return code: {result.returncode}")
            raise Exception(f"FFmpeg failed (code {result.returncode}): {error_msg[:500]}")
        
        # Verify frames were extracted
        extracted_frames = [f for f in os.listdir(output_dir) if f.startswith('frame_') and f.endswith('.jpg')]
        if not extracted_frames:
            raise Exception(f"No frames extracted. FFmpeg output: {result.stderr}")
        
    except FileNotFoundError as e:
        print(f"FFmpeg FileNotFoundError: {str(e)}")
        raise Exception("FFmpeg not found. Please install FFmpeg and add it to your PATH. Run 'ffmpeg -version' to verify.")
    except subprocess.CalledProcessError as e:
        print(f"FFmpeg CalledProcessError: {str(e)}")
        raise Exception(f"FFmpeg process failed: {str(e)}")
    except Exception as e:
        print(f"Extract frames error: {str(e)}")
        raise Exception(f"Failed to extract frames: {str(e)}")


def stabilize_frames(input_dir, output_dir):
    """Stabilize frames using optical flow."""
    os.makedirs(output_dir, exist_ok=True)
    
    frames = sorted([f for f in os.listdir(input_dir) if f.endswith('.jpg')])
    if not frames:
        raise Exception("No frames found to stabilize")
    
    prev = cv2.imread(os.path.join(input_dir, frames[0]))
    if prev is None:
        raise Exception(f"Failed to read first frame: {frames[0]}")
    
    prev_gray = cv2.cvtColor(prev, cv2.COLOR_BGR2GRAY)
    
    transforms = []
    
    # Calculate optical flow between consecutive frames
    for idx in range(1, len(frames)):
        curr = cv2.imread(os.path.join(input_dir, frames[idx]))
        if curr is None:
            continue
        
        curr_gray = cv2.cvtColor(curr, cv2.COLOR_BGR2GRAY)
        
        # Use Lucas-Kanade optical flow
        # Detect corners in previous frame
        corners = cv2.goodFeaturesToTrack(
            prev_gray,
            maxCorners=100,
            qualityLevel=0.3,
            minDistance=7,
            blockSize=7
        )
        
        if corners is not None and len(corners) > 0:
            # Calculate optical flow
            next_pts, status, err = cv2.calcOpticalFlowPyrLK(
                prev_gray, curr_gray, corners, None,
                winSize=(15, 15),
                maxLevel=2,
                criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03)
            )
            
            # Filter valid points
            good_old = corners[status == 1]
            good_new = next_pts[status == 1]
            
            if len(good_old) > 0:
                # Calculate average displacement
                dx = np.mean(good_new[:, 0] - good_old[:, 0])
                dy = np.mean(good_new[:, 1] - good_old[:, 1])
                transforms.append((dx, dy))
            else:
                transforms.append((0.0, 0.0))
        else:
            transforms.append((0.0, 0.0))
        
        prev_gray = curr_gray
    
    # Smooth transforms (reduce jitter)
    if len(transforms) > 0:
        smoothed = []
        for i, (dx, dy) in enumerate(transforms):
            # Apply exponential smoothing
            if i == 0:
                smoothed.append((dx * 0.1, dy * 0.1))
            else:
                prev_dx, prev_dy = smoothed[i - 1]
                smoothed.append((
                    prev_dx * 0.9 + dx * 0.1,
                    prev_dy * 0.9 + dy * 0.1
                ))
    else:
        smoothed = [(0.0, 0.0)] * len(transforms)
    
    # Apply stabilization
    cumulative_dx = 0.0
    cumulative_dy = 0.0
    
    for idx, frame in enumerate(frames):
        img = cv2.imread(os.path.join(input_dir, frame))
        if img is None:
            continue
        
        if idx > 0:
            dx, dy = smoothed[idx - 1]
            cumulative_dx += dx
            cumulative_dy += dy
            
            # Create transformation matrix
            M = np.float32([[1, 0, -cumulative_dx], [0, 1, -cumulative_dy]])
            img = cv2.warpAffine(img, M, (img.shape[1], img.shape[0]))
        
        cv2.imwrite(os.path.join(output_dir, frame), img)


def compute_rotation_positions(stabilized_dir):
    """Compute rotation positions from stabilized frames."""
    files = sorted([f for f in os.listdir(stabilized_dir) if f.endswith('.jpg')])
    if not files:
        raise Exception("No stabilized frames found")
    
    positions = [0.0]
    
    prev = cv2.imread(os.path.join(stabilized_dir, files[0]))
    if prev is None:
        raise Exception("Failed to read first stabilized frame")
    
    prev_gray = cv2.cvtColor(prev, cv2.COLOR_BGR2GRAY)
    
    for f in files[1:]:
        curr = cv2.imread(os.path.join(stabilized_dir, f))
        if curr is None:
            positions.append(positions[-1])
            continue
        
        curr_gray = cv2.cvtColor(curr, cv2.COLOR_BGR2GRAY)
        
        # Detect corners and calculate optical flow
        corners = cv2.goodFeaturesToTrack(
            prev_gray,
            maxCorners=100,
            qualityLevel=0.3,
            minDistance=7,
            blockSize=7
        )
        
        if corners is not None and len(corners) > 0:
            next_pts, status, err = cv2.calcOpticalFlowPyrLK(
                prev_gray, curr_gray, corners, None,
                winSize=(15, 15),
                maxLevel=2,
                criteria=(cv2.TERM_CRITERIA_EPS | cv2.TERM_CRITERIA_COUNT, 10, 0.03)
            )
            
            good_old = corners[status == 1]
            good_new = next_pts[status == 1]
            
            if len(good_old) > 0:
                # Calculate horizontal movement (rotation around car)
                # Use absolute value to track rotation progress
                movement = np.mean(good_new[:, 0] - good_old[:, 0])
                positions.append(positions[-1] + abs(movement))
            else:
                positions.append(positions[-1])
        else:
            positions.append(positions[-1])
        
        prev_gray = curr_gray
    
    # Normalize to 0 → 1 rotation loop
    if len(positions) > 1:
        max_pos = positions[-1]
        if max_pos > 0:
            norm = [p / max_pos for p in positions]
        else:
            norm = [i / len(positions) for i in range(len(positions))]
    else:
        norm = [0.0]
    
    return files, norm


def resample_to_360(files, positions, target_frames=90):
    """Resample frames to target number for smooth 360 rotation."""
    positions = np.array(positions)
    desired = np.linspace(0, 1, target_frames)
    
    index_map = np.searchsorted(positions, desired, side='left')
    
    output_files = []
    for idx in index_map:
        # Clamp index to valid range
        clamped_idx = min(idx, len(files) - 1)
        output_files.append(files[clamped_idx])
    
    return output_files


def export_frames(stabilized_dir, output_files, output_dir, session_id):
    """Export final 360 frames."""
    os.makedirs(output_dir, exist_ok=True)
    
    exported_files = []
    for i, fname in enumerate(output_files):
        src = os.path.join(stabilized_dir, fname)
        if not os.path.exists(src):
            continue
        
        dst = os.path.join(output_dir, f"360_{i:03d}.jpg")
        img = cv2.imread(src)
        if img is not None:
            cv2.imwrite(dst, img)
            exported_files.append(f"360_{i:03d}.jpg")
    
    return exported_files


def upload_frames_to_cloudinary(output_dir, frame_files, session_id):
    """Upload frames to Cloudinary using HTTP requests (unsigned upload with preset)."""
    import json
    
    cloudinary_urls = []
    
    for i, frame_file in enumerate(frame_files):
        frame_path = os.path.join(output_dir, frame_file)
        
        if not os.path.exists(frame_path):
            print(f"Warning: Frame file not found: {frame_path}")
            continue
        
        try:
            # Read image file
            with open(frame_path, 'rb') as f:
                image_data = f.read()
            
            # Prepare form data for multipart upload (same as Flutter app)
            files = {
                'file': (frame_file, image_data, 'image/jpeg')
            }
            data = {
                'upload_preset': CLOUDINARY_UPLOAD_PRESET,
                'folder': f'360_frames/{session_id}',
                'public_id': f'frame_{i:03d}',
                'quality': 'auto:good',
                'fetch_format': 'auto',
            }
            
            # Upload to Cloudinary using HTTP POST
            response = requests.post(CLOUDINARY_UPLOAD_URL, files=files, data=data)
            
            if response.status_code == 200:
                upload_result = response.json()
                secure_url = upload_result.get('secure_url')
                if secure_url:
                    cloudinary_urls.append(secure_url)
                    print(f"✅ Uploaded frame {i+1}/{len(frame_files)} to Cloudinary")
                else:
                    print(f"⚠️ Warning: No secure_url in Cloudinary response for frame {i+1}")
                    print(f"Response: {upload_result}")
            else:
                print(f"❌ Error uploading frame {i+1}: HTTP {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Error uploading frame {i+1} to Cloudinary: {str(e)}")
            import traceback
            traceback.print_exc()
            # Continue with other frames even if one fails
            continue
    
    if len(cloudinary_urls) != len(frame_files):
        print(f"⚠️ Warning: Only {len(cloudinary_urls)}/{len(frame_files)} frames uploaded successfully")
    
    return cloudinary_urls


@app.post("/process360")
async def process_360_video(file: UploadFile = File(...)):
    """Process uploaded video and return 360 frame URLs."""
    session_id = str(uuid.uuid4())
    
    try:
        # Ensure upload directory exists
        UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
        
        # Save uploaded video
        video_path = UPLOAD_DIR / f"{session_id}.mp4"
        
        # Read file content
        contents = await file.read()
        
        # Verify file was received
        if len(contents) == 0:
            raise HTTPException(status_code=400, detail="Empty file uploaded")
        
        # Write to disk
        with open(video_path, "wb") as buffer:
            buffer.write(contents)
        
        # Verify file was written
        if not video_path.exists():
            raise HTTPException(status_code=500, detail="Failed to save uploaded file")
        
        # Verify file size
        if video_path.stat().st_size == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty")
        
        # Create session-specific directories
        extract_session_dir = EXTRACT_DIR / session_id
        stabilized_session_dir = STABILIZED_DIR / session_id
        output_session_dir = OUTPUT_DIR / session_id
        
        # Step 1: Extract frames
        # Use absolute paths to avoid path issues
        video_path_abs = os.path.abspath(str(video_path))
        extract_dir_abs = os.path.abspath(str(extract_session_dir))
        print(f"Extracting frames from: {video_path_abs}")
        print(f"Output directory: {extract_dir_abs}")
        extract_frames(video_path_abs, extract_dir_abs)
        
        # Step 2: Stabilize frames
        stabilize_frames(str(extract_session_dir), str(stabilized_session_dir))
        
        # Step 3: Compute rotation positions
        files, positions = compute_rotation_positions(str(stabilized_session_dir))
        
        # Step 4: Resample to 90 frames
        output_files = resample_to_360(files, positions, target_frames=90)
        
        # Step 5: Export final frames
        exported_files = export_frames(
            str(stabilized_session_dir),
            output_files,
            str(output_session_dir),
            session_id
        )
        
        # Step 6: Upload frames to Cloudinary
        print(f"Uploading {len(exported_files)} frames to Cloudinary...")
        frame_urls = upload_frames_to_cloudinary(
            str(output_session_dir),
            exported_files,
            session_id
        )
        
        print(f"Successfully uploaded {len(frame_urls)} frames to Cloudinary")
        
        return JSONResponse({
            "success": True,
            "session_id": session_id,
            "frame_count": len(frame_urls),
            "frame_urls": frame_urls,
        })
    
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        print(f"Processing error: {str(e)}")
        print(f"Full traceback:\n{error_trace}")
        raise HTTPException(status_code=500, detail=f"Processing failed: {str(e)}")
    
    finally:
        # Cleanup uploaded video (optional - keep for debugging)
        # if video_path.exists():
        #     video_path.unlink()
        pass


@app.get("/frames/{session_id}/{filename}")
async def get_frame(session_id: str, filename: str):
    """Serve processed frames."""
    from fastapi.responses import FileResponse
    
    frame_path = OUTPUT_DIR / session_id / filename
    if not frame_path.exists():
        raise HTTPException(status_code=404, detail="Frame not found")
    
    return FileResponse(frame_path)


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

