# Backend Troubleshooting Guide

## Common Errors and Solutions

### Error: "[WinError 2] The system cannot find the file specified"

This error usually means **FFmpeg cannot find the video file** or **FFmpeg is not installed**.

#### Solution 1: Verify FFmpeg is Installed

**Windows:**
```bash
ffmpeg -version
```

If you get "command not found":
1. Download FFmpeg from: https://ffmpeg.org/download.html
2. Extract to a folder (e.g., `C:\ffmpeg`)
3. Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" variable
   - Add: `C:\ffmpeg\bin`
4. Restart terminal and verify: `ffmpeg -version`

**macOS:**
```bash
brew install ffmpeg
```

**Linux:**
```bash
sudo apt-get install ffmpeg
```

#### Solution 2: Check File Paths

The backend now uses absolute paths. Check the backend terminal output for:
```
Extracting frames from: [path]
Output directory: [path]
```

Verify these paths exist and are correct.

#### Solution 3: Check File Permissions

Ensure the backend has write permissions to:
- `backend/uploads/`
- `backend/extracted/`
- `backend/stabilized/`
- `backend/output/`

#### Solution 4: Verify Video File is Saved

Check if the uploaded file exists:
- Look in `backend/uploads/` directory
- File should be named like `[uuid].mp4`
- File size should be > 0 bytes

### Error: "FFmpeg not found"

**Solution:** Install FFmpeg and add to PATH (see Solution 1 above)

### Error: "No frames extracted"

**Possible causes:**
1. Video file is corrupted
2. Video format not supported
3. FFmpeg command failed silently

**Solution:**
- Check backend terminal for FFmpeg error messages
- Try a different video file
- Ensure video is MP4 format
- Check video file size (should be > 0)

### Error: "Empty file uploaded"

**Solution:**
- Check video file size before uploading
- Ensure file upload completed successfully
- Check network connection

### Error: "Processing failed: [other error]"

**Solution:**
1. Check backend terminal for detailed error
2. Verify all Python packages are installed: `pip install -r requirements.txt`
3. Check disk space
4. Verify OpenCV is working: `python -c "import cv2; print(cv2.__version__)"`

## Debug Steps

1. **Check Backend Logs:**
   - Look at terminal where backend is running
   - Error messages will show what failed

2. **Test FFmpeg Manually:**
   ```bash
   ffmpeg -i test_video.mp4 -vf fps=30 output_%04d.jpg
   ```

3. **Test Backend Health:**
   ```bash
   curl http://localhost:8000/health
   ```
   Should return: `{"status":"ok"}`

4. **Check Directory Structure:**
   ```
   backend/
   ├── uploads/        (should exist)
   ├── extracted/      (created automatically)
   ├── stabilized/     (created automatically)
   └── output/         (created automatically)
   ```

5. **Verify File Upload:**
   - Upload a small test video
   - Check `backend/uploads/` for the file
   - Verify file size matches uploaded file

## Quick Fixes

### Restart Backend
```bash
# Stop backend (Ctrl+C)
# Restart
cd backend
python process.py
```

### Clear Cache
```bash
# Delete temporary files
rm -rf backend/uploads/*
rm -rf backend/extracted/*
rm -rf backend/stabilized/*
rm -rf backend/output/*
```

### Reinstall Dependencies
```bash
cd backend
pip install --upgrade -r requirements.txt
```

## Still Having Issues?

1. Check backend terminal for full error stack trace
2. Verify FFmpeg is in PATH: `ffmpeg -version`
3. Test with a small MP4 video file
4. Check Python version: `python --version` (should be 3.8+)
5. Verify all directories are writable


