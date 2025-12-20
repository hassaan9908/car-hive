import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carhive/services/backend_360_service.dart';
import 'package:carhive/360_viewer.dart';

/// Screen for capturing video for 360° car rotation
class VideoCapture360Screen extends StatefulWidget {
  /// Callback when processing is complete with frame URLs
  final Function(List<String> frameUrls)? onComplete;

  const VideoCapture360Screen({
    super.key,
    this.onComplete,
  });

  @override
  State<VideoCapture360Screen> createState() => _VideoCapture360ScreenState();
}

class _VideoCapture360ScreenState extends State<VideoCapture360Screen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordedVideoPath;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  double _processingProgress = 0.0;
  String _processingMessage = '';
  List<String>? _processedFrameUrls;
  final Backend360Service _backendService = Backend360Service();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _webVideoBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock to landscape immediately
    _lockLandscapeOrientation();
    // Also ensure it's locked after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockLandscapeOrientation();
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    _unlockOrientation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock orientation when app resumes
    if (state == AppLifecycleState.resumed) {
      _lockLandscapeOrientation();
    }
  }

  /// Lock screen orientation to landscape
  void _lockLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Unlock orientation
  void _unlockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Pick video from file (for web)
  Future<void> _pickVideoFromFile() async {
    try {
      final pickedVideo = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (pickedVideo != null) {
        if (kIsWeb) {
          // Web: Get bytes
          final bytes = await pickedVideo.readAsBytes();
          setState(() {
            _webVideoBytes = bytes;
            _recordedVideoPath = 'web_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
          });
        } else {
          // Mobile: Use file path
          setState(() {
            _recordedVideoPath = pickedVideo.path;
            _webVideoBytes = null;
          });
        }
        
        // Auto-process
        await _processVideo();
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      // Web: Camera not available, but file upload is
      setState(() {
        _isCameraInitialized = false;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      // Ensure landscape orientation is locked after camera initialization
      _lockLandscapeOrientation();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Lock again after state update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _lockLandscapeOrientation();
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  /// Start recording video
  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    if (_isRecording) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/360_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      // Start timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds = timer.tick;
          });
          
          // Auto-stop at 20 seconds
          if (_recordingSeconds >= 20) {
            _stopRecording(videoPath);
          }
        }
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Stop recording video
  Future<void> _stopRecording(String? videoPath) async {
    if (!_isRecording) return;

    _recordingTimer?.cancel();

    try {
      final file = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _recordedVideoPath = file.path;
      });

      // Auto-upload and process
      if (_recordedVideoPath != null) {
        await _processVideo();
      }
    } catch (e) {
      _showError('Failed to stop recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Process video through backend
  Future<void> _processVideo() async {
    if (_recordedVideoPath == null && _webVideoBytes == null) return;

    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
      _processingMessage = 'Uploading video...';
    });

    try {
      Process360Result result;
      
      if (kIsWeb && _webVideoBytes != null) {
        // Web: Pass bytes directly (no file system access needed)
        result = await _backendService.processVideo(
          videoBytes: _webVideoBytes,
          filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
          onProgress: (current, total, message) {
            if (mounted) {
              setState(() {
                _processingProgress = current / total;
                _processingMessage = message;
              });
            }
          },
        );
      } else if (_recordedVideoPath != null) {
        // Mobile: Use file path
        final videoFile = File(_recordedVideoPath!);
        result = await _backendService.processVideo(
          videoFile: videoFile,
          onProgress: (current, total, message) {
            if (mounted) {
              setState(() {
                _processingProgress = current / total;
                _processingMessage = message;
              });
            }
          },
        );
      } else {
        throw Exception('No video file available');
      }

      if (result.success) {
        setState(() {
          _processedFrameUrls = result.frameUrls;
          _isProcessing = false;
        });

        // Show completion dialog
        _showCompletionDialog(result.frameUrls);
      } else {
        throw Exception('Processing failed');
      }
    } catch (e) {
      _showError('Failed to process video: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Show completion dialog
  void _showCompletionDialog(List<String> frameUrls) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Processing Complete!'),
          ],
        ),
        content: Text(
          'Successfully generated ${frameUrls.length} frames for 360° rotation.\n\n'
          'You can now preview the rotation or save it.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _preview360();
            },
            child: const Text('Preview'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onComplete?.call(frameUrls);
              Navigator.pop(context, frameUrls);
            },
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  /// Preview 360 rotation
  void _preview360() {
    if (_processedFrameUrls == null || _processedFrameUrls!.isEmpty) {
      _showError('No frames available for preview');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Viewer360Screen(
          frameUrls: _processedFrameUrls!,
        ),
      ),
    );
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Ensure landscape is locked every time build is called
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockLandscapeOrientation();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('360° Video Capture'),
        actions: [
          if (_processedFrameUrls != null)
            IconButton(
              icon: const Icon(Icons.preview),
              onPressed: _preview360,
              tooltip: 'Preview 360°',
            ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            // Force landscape orientation - if not landscape, lock it
            if (orientation != Orientation.landscape) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _lockLandscapeOrientation();
              });
            }
            
            return _isProcessing
                ? _buildProcessingView()
                : _buildCaptureView(theme);
          },
        ),
      ),
    );
  }

  /// Build processing view
  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _processingProgress > 0 ? _processingProgress : null,
          ),
          const SizedBox(height: 24),
          Text(
            _processingMessage,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_processingProgress > 0)
            Text(
              '${(_processingProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
        ],
      ),
    );
  }

  /// Build capture view
  Widget _buildCaptureView(ThemeData theme) {
    return Row(
      children: [
        // Camera preview
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: _buildCameraPreview(),
          ),
        ),
        // Controls
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Instructions
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf48c25).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFf48c25), width: 1),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFf48c25),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Walk slowly around the car',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep the car centered in frame',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Record for 15-20 seconds',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Recording timer
                if (_isRecording)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recording: ${_recordingSeconds}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Record button (mobile) or Upload button (web)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: kIsWeb
                      ? FilledButton.icon(
                          onPressed: _pickVideoFromFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Video'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _isRecording
                              ? () => _stopRecording(null)
                              : _startRecording,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isRecording ? Colors.red : Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop : Icons.videocam,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                ),

                // Status
                if (_recordedVideoPath != null && !_isProcessing)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Video recorded!',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _processVideo,
                          icon: const Icon(Icons.upload),
                          label: const Text('Process Video'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build camera preview
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    final aspectRatio = _cameraController!.value.aspectRatio;
    final landscapeAspectRatio = aspectRatio > 1 ? aspectRatio : 1 / aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: landscapeAspectRatio,
            child: CameraPreview(_cameraController!),
          ),
          // Center guide
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

