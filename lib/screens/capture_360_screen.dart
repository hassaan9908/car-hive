import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:carhive/models/car_360_set.dart';
import 'package:carhive/widgets/angle_guide.dart';

/// Screen for capturing 16 angles of a car for 360° view
class Capture360Screen extends StatefulWidget {
  /// Callback when capture is complete with all 16 images
  final Function(Car360Set) onCaptureComplete;

  /// Optional existing Car360Set to continue editing
  final Car360Set? existingSet;

  const Capture360Screen({
    super.key,
    required this.onCaptureComplete,
    this.existingSet,
  });

  @override
  State<Capture360Screen> createState() => _Capture360ScreenState();
}

class _Capture360ScreenState extends State<Capture360Screen>
    with WidgetsBindingObserver {
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMessage = '';

  // Capture state
  late Car360Set _car360Set;
  int _currentAngleIndex = 0;
  bool _isCapturing = false;

  // Image picker for fallback
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _car360Set = widget.existingSet ?? Car360Set();
    _currentAngleIndex = _car360Set.getNextAngleToCapture() ?? 0;
    // Lock orientation to landscape
    _lockLandscapeOrientation();
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    // Restore orientation preferences
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

  /// Unlock orientation to allow all orientations
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
      // Re-lock orientation when app resumes
      _lockLandscapeOrientation();
      _initializeCamera();
    } else if (state == AppLifecycleState.paused) {
      // Optionally unlock when paused (when user switches apps)
      // But keep locked for better UX
    }
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    if (kIsWeb) {
      // Web doesn't support camera package well, use image picker instead
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

      // Use back camera
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

  /// Capture photo from camera
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        // Capture from camera
        final XFile image = await _cameraController!.takePicture();

        // Process image to ensure landscape orientation
        final processedImage = await _processImageForLandscape(image);

        // Save to local storage
        await _saveImage(processedImage);
      } else {
        // Fallback to image picker
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

  /// Process image to ensure it's in landscape orientation
  Future<XFile> _processImageForLandscape(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return imageFile; // Return original if decoding fails
      }

      // Check if image is in portrait (height > width)
      final isPortrait = image.height > image.width;
      
      if (isPortrait) {
        // Rotate 90 degrees clockwise to make it landscape
        // Note: copyRotate uses counter-clockwise, so we use -90 for clockwise
        final rotatedImage = img.copyRotate(image, angle: -90);
        final rotatedBytes = img.encodeJpg(rotatedImage, quality: 90);
        
        // Save rotated image
        if (kIsWeb) {
          // For web, we need to create a new XFile with rotated bytes
          // Since we can't easily modify XFile on web, we'll return original
          // The orientation lock should prevent portrait captures anyway
          return imageFile;
        } else {
          // Create temporary file with rotated image
          final directory = await getApplicationDocumentsDirectory();
          final tempDir = Directory('${directory.path}/360_temp');
          if (!await tempDir.exists()) {
            await tempDir.create(recursive: true);
          }
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final tempFile = File('${tempDir.path}/rotated_$timestamp.jpg');
          await tempFile.writeAsBytes(rotatedBytes);
          
          // Delete original temp file if it exists
          try {
            if (imageFile.path.contains('_rotated')) {
              final originalFile = File(imageFile.path);
              if (await originalFile.exists()) {
                await originalFile.delete();
              }
            }
          } catch (_) {
            // Ignore deletion errors
          }
          
          return XFile(tempFile.path);
        }
      }
      
      return imageFile; // Already landscape, return original
    } catch (e) {
      print('Error processing image for landscape: $e');
      return imageFile; // Return original on error
    }
  }

  /// Pick image from gallery (fallback or web)
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        // Process image to ensure landscape orientation
        final processedImage = await _processImageForLandscape(image);
        await _saveImage(processedImage);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  /// Save captured image to local storage and update state
  Future<void> _saveImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName = Car360Set.getFileName(_currentAngleIndex);

      if (kIsWeb) {
        // Web: store in memory
        final newImageBytes = List<Uint8List?>.from(_car360Set.imageBytes);
        newImageBytes[_currentAngleIndex] = bytes;

        _car360Set = _car360Set.copyWith(imageBytes: newImageBytes);
      } else {
        // Mobile: save to file system
        final directory = await getApplicationDocumentsDirectory();
        final sessionDir = Directory('${directory.path}/360_captures/${_car360Set.sessionId}');

        if (!await sessionDir.exists()) {
          await sessionDir.create(recursive: true);
        }

        final file = File('${sessionDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        final newImages = List<File?>.from(_car360Set.images);
        newImages[_currentAngleIndex] = file;

        // Also store bytes for preview
        final newImageBytes = List<Uint8List?>.from(_car360Set.imageBytes);
        newImageBytes[_currentAngleIndex] = bytes;

        _car360Set = _car360Set.copyWith(
          images: newImages,
          imageBytes: newImageBytes,
        );
      }

      // Move to next angle or complete
      _moveToNextAngle();
    } catch (e) {
      _showError('Failed to save image: $e');
    }
  }

  /// Move to the next uncaptured angle
  void _moveToNextAngle() {
    final nextAngle = _car360Set.getNextAngleToCapture();

    setState(() {
      if (nextAngle != null) {
        _currentAngleIndex = nextAngle;
      } else {
        // All angles captured
        _showCompletionDialog();
      }
    });
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
          'You can preview and retake any angle, or proceed to save.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCaptureComplete(_car360Set);
              Navigator.pop(this.context, _car360Set);
            },
            child: const Text('Save & Continue'),
          ),
        ],
      ),
    );
  }

  /// Retake photo for specific angle
  void _retakePhoto(int index) {
    setState(() {
      _currentAngleIndex = index;
    });
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

  /// Build camera preview widget
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

    // Get camera aspect ratio and ensure landscape
    final aspectRatio = _cameraController!.value.aspectRatio;
    // For landscape, aspect ratio should be > 1 (width > height)
    final landscapeAspectRatio = aspectRatio > 1 ? aspectRatio : 1 / aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera preview - forced to landscape aspect ratio
          AspectRatio(
            aspectRatio: landscapeAspectRatio,
            child: CameraPreview(_cameraController!),
          ),
          // Grid overlay for alignment
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Center crosshair
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build landscape-optimized layout
  Widget _buildLandscapeLayout(ThemeData theme, List<bool> capturedAngles) {
    return Row(
      children: [
        // Left side: Camera preview
        Expanded(
          flex: 3,
            child: Container(
            padding: const EdgeInsets.all(12),
            child: _buildCameraPreview(),
          ),
        ),
        // Right side: Controls and info
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CaptureProgressIndicator(
                    currentStep: _currentAngleIndex,
                    totalSteps: 16,
                    capturedAngles: capturedAngles,
                  ),
                ),

                // Current angle info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
              ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rotate_90_degrees_ccw,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${Car360Set.getAngleDegrees(_currentAngleIndex).toStringAsFixed(1)}°',
                              style: const TextStyle(
                                color: Colors.white,
                              fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Car360Set.getAngleName(_currentAngleIndex),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Landscape orientation reminder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf48c25).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFf48c25), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_rotation, color: Color(0xFFf48c25), size: 20),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Please keep device in landscape mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
            ),
                ),

                // Angle guide
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AngleGuide(
                    currentAngleIndex: _currentAngleIndex,
                    capturedAngles: capturedAngles,
                    size: 140,
                    onAngleTap: _retakePhoto,
                  ),
                ),

                // Thumbnail strip
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildThumbnailStrip(),
                ),

                // Capture controls
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      // Capture button
                      GestureDetector(
                        onTap: _isCapturing ? null : _capturePhoto,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCapturing
                                  ? Colors.grey
                                  : theme.colorScheme.primary,
                            ),
                            child: _isCapturing
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                      ),
                      // Skip button
                      IconButton(
              onPressed: () {
                          final nextIndex = (_currentAngleIndex + 1) % 16;
                          setState(() {
                            _currentAngleIndex = nextIndex;
                          });
              },
                        icon: const Icon(Icons.skip_next),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
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

  /// Build portrait layout (fallback when device is rotated)
  Widget _buildPortraitLayout(
      ThemeData theme, List<bool> capturedAngles, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
              // Landscape orientation reminder
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.screen_rotation, color: Colors.orange, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Please rotate your device to landscape mode for best 360° capture experience',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                      // Progress indicator
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CaptureProgressIndicator(
                          currentStep: _currentAngleIndex,
                          totalSteps: 16,
                          capturedAngles: capturedAngles,
                        ),
                      ),

                      // Current angle info
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.rotate_90_degrees_ccw,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${Car360Set.getAngleDegrees(_currentAngleIndex).toStringAsFixed(1)}°',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                Car360Set.getAngleName(_currentAngleIndex),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

              // Camera preview
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: _buildCameraPreview(),
                        ),
                      ),

              // Angle guide
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: AngleGuide(
                          currentAngleIndex: _currentAngleIndex,
                          capturedAngles: capturedAngles,
                  size: 120,
                          onAngleTap: _retakePhoto,
                        ),
                      ),

                      // Thumbnail strip
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _buildThumbnailStrip(),
                      ),

                      // Capture controls
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery button
                            IconButton(
                              onPressed: _pickFromGallery,
                              icon: const Icon(Icons.photo_library),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                            // Capture button
                            GestureDetector(
                              onTap: _isCapturing ? null : _capturePhoto,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isCapturing
                                        ? Colors.grey
                                        : theme.colorScheme.primary,
                                  ),
                                  child: _isCapturing
                                      ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                ),
                              ),
                            ),
                            // Skip button
                            IconButton(
                              onPressed: () {
                                final nextIndex = (_currentAngleIndex + 1) % 16;
                                setState(() {
                                  _currentAngleIndex = nextIndex;
                                });
                              },
                              icon: const Icon(Icons.skip_next),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
  }

  /// Build thumbnail strip of captured images
  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: 50, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 16,
        itemBuilder: (context, index) {
          final isCaputred = _car360Set.isAngleCaptured(index);
          final isCurrent = index == _currentAngleIndex;
          final bytes = _car360Set.imageBytes[index];

          return GestureDetector(
            onTap: () => _retakePhoto(index),
            child: Container(
              width: 40, // Reduced width
              height: 40, // Reduced height
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : isCaputred
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isCaputred && bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // Smaller font
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capturedAngles = List.generate(
      16,
      (index) => _car360Set.isAngleCaptured(index),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('360° Capture'),
        actions: [
          if (_car360Set.isComplete)
            TextButton(
              onPressed: () {
                widget.onCaptureComplete(_car360Set);
                Navigator.pop(context, _car360Set);
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use landscape-optimized layout
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            
            return isLandscape
                ? _buildLandscapeLayout(theme, capturedAngles)
                : _buildPortraitLayout(theme, capturedAngles, constraints);
          },
        ),
      ),
    );
  }
}

/// Grid painter for camera preview alignment
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Vertical lines (rule of thirds)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Horizontal lines (rule of thirds)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

