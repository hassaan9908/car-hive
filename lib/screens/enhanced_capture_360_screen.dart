import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:carhive/models/car_360_set.dart';
import 'package:carhive/utils/360_file_handler.dart';
import 'package:carhive/widgets/angle_guide.dart';
import 'package:carhive/services/interpolation_service.dart';
import 'package:carhive/widgets/interpolation_progress_dialog.dart';
import 'package:carhive/screens/interpolated_360_viewer_screen.dart';

/// Enhanced capture screen with circular progress UI and 16 guided angles
class EnhancedCapture360Screen extends StatefulWidget {
  /// Callback when capture is complete
  final Function(Car360Set)? onCaptureComplete;

  const EnhancedCapture360Screen({
    super.key,
    this.onCaptureComplete,
  });

  @override
  State<EnhancedCapture360Screen> createState() => _EnhancedCapture360ScreenState();
}

class _EnhancedCapture360ScreenState extends State<EnhancedCapture360Screen>
    with WidgetsBindingObserver {
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMessage = '';

  // Capture state
  int _currentAngleIndex = 0; // 0-15, but we display as 1-16
  bool _isCapturing = false;
  final List<bool> _capturedAngles = List.filled(16, false);
  final List<Uint8List?> _capturedImageBytes = List.filled(16, null);

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lockLandscapeOrientation();
    _initializeCamera();
    _loadExistingImages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _unlockOrientation();
    super.dispose();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _lockLandscapeOrientation();
      _initializeCamera();
    }
  }

  /// Load existing captured images
  Future<void> _loadExistingImages() async {
    if (kIsWeb) return;

    try {
      final imageBytes = await Car360FileHandler.loadAllImagesAsBytes();
      setState(() {
        for (int i = 0; i < 16; i++) {
          if (imageBytes[i] != null) {
            _capturedAngles[i] = true;
            _capturedImageBytes[i] = imageBytes[i];
          }
        }
      });
    } catch (e) {
      print('Error loading existing images: $e');
    }
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      setState(() {
        _isCameraError = true;
        _cameraErrorMessage = 'Camera not supported on web. Use gallery picker.';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMessage = 'No cameras available';
        });
        return;
      }

      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraError = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCameraError = true;
        _cameraErrorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  /// Capture photo
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile image = await _cameraController!.takePicture();
        final processedImage = await _processImageForLandscape(image);
        await _saveImage(processedImage);
      } else {
        await _pickFromGallery();
      }
    } catch (e) {
      _showError('Failed to capture: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  /// Process image for landscape orientation
  Future<XFile> _processImageForLandscape(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return imageFile;
      }

      final isPortrait = image.height > image.width;
      
      if (isPortrait) {
        final rotatedImage = img.copyRotate(image, angle: -90);
        final rotatedBytes = img.encodeJpg(rotatedImage, quality: 90);
        
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final tempDir = Directory('${directory.path}/360_temp');
          if (!await tempDir.exists()) {
            await tempDir.create(recursive: true);
          }
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempFile = File('${tempDir.path}/rotated_$timestamp.jpg');
          await tempFile.writeAsBytes(rotatedBytes);
          
          return XFile(tempFile.path);
        }
      }
      
      return imageFile;
    } catch (e) {
      print('Error processing image: $e');
      return imageFile;
    }
  }

  /// Pick from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        final processedImage = await _processImageForLandscape(image);
        await _saveImage(processedImage);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Save image
  Future<void> _saveImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final angleNumber = _currentAngleIndex + 1; // 1-16

      if (!kIsWeb) {
        await Car360FileHandler.saveRawImage(angleNumber, bytes);
      }

      setState(() {
        _capturedAngles[_currentAngleIndex] = true;
        _capturedImageBytes[_currentAngleIndex] = bytes;
      });

      // Move to next uncaptured angle
      _moveToNextAngle();
    } catch (e) {
      _showError('Failed to save image: $e');
    }
  }

  /// Move to next uncaptured angle
  void _moveToNextAngle() {
    for (int i = 0; i < 16; i++) {
      final nextIndex = (_currentAngleIndex + 1 + i) % 16;
      if (!_capturedAngles[nextIndex]) {
        setState(() {
          _currentAngleIndex = nextIndex;
        });
        return;
      }
    }

    // All angles captured
    _showCompletionDialog();
  }

  /// Show completion dialog
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Capture Complete!'),
          ],
        ),
        content: const Text(
          'All 16 angles have been captured successfully.\n\n'
          'Generating smooth 360° view with AI interpolation...',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAndView360();
            },
            child: const Text('Generate 360° View'),
          ),
        ],
      ),
    );
  }

  /// Generate interpolated frames and navigate to viewer
  Future<void> _generateAndView360() async {
    // Show interpolation progress
    InterpolationProgressDialog.show(
      context,
      current: 0,
      total: 64,
      message: 'Starting interpolation...',
    );

    try {
      // Generate interpolated frames
      await InterpolationService.generateInterpolatedFrames(
        onProgress: (current, total, message) {
          InterpolationProgressDialog.update(
            context,
            current: (current / 100 * 64).round(),
            total: 64,
            message: message,
          );
        },
      );

      // Close progress dialog
      InterpolationProgressDialog.hide(context);

      // Navigate directly to interpolated viewer
      if (mounted) {
        InterpolationProgressDialog.hide(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Interpolated360ViewerScreen(
              title: '360° View',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        InterpolationProgressDialog.hide(context);
        _showError('Failed to generate 360° view: $e');
      }
    }
  }

  /// Navigate to preview grid (fallback)
  Future<void> _navigateToPreview() async {
    try {
      // Check if interpolated frames exist and navigate directly to viewer
      final interpolatedExist = await InterpolationService.interpolatedFramesExist();
      
      if (interpolatedExist) {
        // Navigate directly to interpolated viewer
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Interpolated360ViewerScreen(
                title: '360° View',
              ),
            ),
          );
          return;
        }
      }

      // Fallback: Return to caller with raw images
      final car360Set = Car360Set(
        imageBytes: _capturedImageBytes,
        sessionId: 'capture_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (widget.onCaptureComplete != null) {
        widget.onCaptureComplete!(car360Set);
      }

      if (mounted) {
        Navigator.pop(context, car360Set);
      }
    } catch (e) {
      // Final fallback
      final car360Set = Car360Set(
        imageBytes: _capturedImageBytes,
        sessionId: 'capture_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (widget.onCaptureComplete != null) {
        widget.onCaptureComplete!(car360Set);
      }

      if (mounted) {
        Navigator.pop(context, car360Set);
      }
    }
  }

  /// Retake photo for specific angle
  void _retakePhoto(int index) {
    setState(() {
      _currentAngleIndex = index;
      _capturedAngles[index] = false;
      _capturedImageBytes[index] = null;
    });

    if (!kIsWeb) {
      Car360FileHandler.deleteImage(index + 1);
    }
  }

  /// Show error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Build camera preview
  Widget _buildCameraPreview() {
    if (_isCameraError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _cameraErrorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
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
          // Ghost circle overlay for car alignment
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build circular progress UI with 16 markers
  Widget _buildCircularProgress() {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle with 16 markers
          CustomPaint(
            size: const Size(300, 300),
            painter: _CircularProgressPainter(
              currentAngle: _currentAngleIndex,
              capturedAngles: _capturedAngles,
            ),
          ),
          // Center indicator
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Angle ${_currentAngleIndex + 1}/16',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Car360Set.getAngleName(_currentAngleIndex),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${Car360Set.getAngleDegrees(_currentAngleIndex).toStringAsFixed(1)}°',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capturedCount = _capturedAngles.where((c) => c).length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('360° Capture'),
        actions: [
          if (capturedCount == 16)
            TextButton(
              onPressed: _navigateToPreview,
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            // Left: Camera preview
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: _buildCameraPreview(),
              ),
            ),
            // Right: Controls and progress
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular progress UI
                      _buildCircularProgress(),
                      const SizedBox(height: 24),
                      // Linear progress
                      CaptureProgressIndicator(
                        currentStep: _currentAngleIndex,
                        totalSteps: 16,
                        capturedAngles: _capturedAngles,
                      ),
                      const SizedBox(height: 24),
                      // Angle guide
                      AngleGuide(
                        currentAngleIndex: _currentAngleIndex,
                        capturedAngles: _capturedAngles,
                        size: 200,
                        onAngleTap: _retakePhoto,
                      ),
                      const SizedBox(height: 24),
                      // Capture button
                      FloatingActionButton.extended(
                        onPressed: _isCapturing ? null : _capturePhoto,
                        icon: _isCapturing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(_isCapturing ? 'Capturing...' : 'Capture'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      // Gallery button
                      OutlinedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Pick from Gallery'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for circular progress with 16 markers
class _CircularProgressPainter extends CustomPainter {
  final int currentAngle;
  final List<bool> capturedAngles;

  _CircularProgressPainter({
    required this.currentAngle,
    required this.capturedAngles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Draw background circle
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Draw progress arc
    final progress = capturedAngles.where((c) => c).length / 16;
    final progressPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * 3.14159 / 180,
      2 * 3.14159 * progress,
      false,
      progressPaint,
    );

    // Draw 16 markers
    for (int i = 0; i < 16; i++) {
      final angleRad = (i * 22.5 - 90) * math.pi / 180;
      final markerX = center.dx + radius * math.cos(angleRad);
      final markerY = center.dy + radius * math.sin(angleRad);

      final isCurrent = i == currentAngle;
      final isCaptured = capturedAngles[i];

      final markerPaint = Paint()
        ..color = isCurrent
            ? Colors.orange
            : isCaptured
                ? Colors.green
                : Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(markerX, markerY),
        isCurrent ? 8 : 6,
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return currentAngle != oldDelegate.currentAngle ||
        capturedAngles != oldDelegate.capturedAngles;
  }
}

