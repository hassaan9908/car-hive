# Install FFmpeg on Windows - Step by Step

## The Problem
Your backend is showing: `FileNotFoundError: [WinError 2] The system cannot find the file specified`

This means **FFmpeg is not installed** or **not in your PATH**.

## Solution: Install FFmpeg

### Method 1: Direct Download (Recommended)

1. **Download FFmpeg:**
   - Go to: https://www.gyan.dev/ffmpeg/builds/
   - Click "Download Build" (full build recommended)
   - Or direct link: https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip

2. **Extract FFmpeg:**
   - Extract the ZIP file to: `C:\ffmpeg`
   - You should have: `C:\ffmpeg\bin\ffmpeg.exe`

3. **Add to PATH:**
   - Press `Win + R`
   - Type: `sysdm.cpl` and press Enter
   - Go to "Advanced" tab
   - Click "Environment Variables"
   - Under "System variables", find "Path" → Click "Edit"
   - Click "New"
   - Add: `C:\ffmpeg\bin`
   - Click OK on all dialogs

4. **Restart Terminal:**
   - Close ALL terminal/PowerShell windows
   - Open a NEW terminal
   - Test: `ffmpeg -version`
   - Should show FFmpeg version info

5. **Restart Backend:**
   - Stop backend (Ctrl+C)
   - Start again: `python process.py`

### Method 2: Using Chocolatey (If you have it)

```powershell
choco install ffmpeg
```

### Method 3: Using Scoop (If you have it)

```powershell
scoop install ffmpeg
```

## Verify Installation

After installing, test in a NEW terminal:

```bash
ffmpeg -version
```

You should see:
```
ffmpeg version [version number]
...
```

## After Installation

1. **Restart your backend server:**
   ```bash
   cd backend
   python process.py
   ```

2. **Try uploading a video again**

3. **Check backend terminal** - you should see:
   ```
   Running FFmpeg command: ffmpeg -i ...
   ```

## Still Not Working?

1. **Verify PATH:**
   - Open NEW terminal
   - Run: `echo %PATH%`
   - Look for `C:\ffmpeg\bin` in the output

2. **Test FFmpeg directly:**
   ```bash
   C:\ffmpeg\bin\ffmpeg.exe -version
   ```

3. **If that works but `ffmpeg -version` doesn't:**
   - PATH is not set correctly
   - Restart your computer after setting PATH
   - Or use full path in backend code (not recommended)

## Quick Test

After installation, test with a video file:

```bash
ffmpeg -i test_video.mp4 -vf fps=30 output_%04d.jpg
```

If this works, FFmpeg is installed correctly!


