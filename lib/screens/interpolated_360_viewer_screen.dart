import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:carhive/widgets/smooth_image_blend.dart';
import 'package:carhive/controllers/advanced_360_controller.dart';
import 'package:carhive/services/url_interpolation_service.dart';

/// Enhanced 360° viewer that automatically uses 64 interpolated frames
class Interpolated360ViewerScreen extends StatefulWidget {
  /// Fallback: List of image URLs (16 frames)
  final List<String>? imageUrls;
  
  /// Fallback: List of image files (16 frames)
  final List<File?>? imageFiles;
  
  /// Fallback: List of image bytes (16 frames)
  final List<Uint8List?>? imageBytes;
  
  /// Title
  final String title;
  
  /// Initial frame index (0-63)
  final int initialIndex;

  const Interpolated360ViewerScreen({
    super.key,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.title = '360° View',
    this.initialIndex = 0,
  });

  @override
  State<Interpolated360ViewerScreen> createState() => _Interpolated360ViewerScreenState();
}

class _Interpolated360ViewerScreenState extends State<Interpolated360ViewerScreen>
    with TickerProviderStateMixin {
  late Advanced360Controller _controller;
  
  // Drag sensitivity
  final double _sensitivity = 40.0; // More sensitive for 64 frames
  
  // Full screen mode
  bool _isFullScreen = false;
  
  // Loaded frames
  List<Uint8List?> _loadedFrames = [];
  bool _isLoading = true;
  String? _loadingError;
  
  // Total number of frames (64 if interpolated, 16 if raw)
  int _totalFrames = 64;

  @override
  void initState() {
    super.initState();
    _controller = Advanced360Controller();
    _controller.initialize(this);
    _loadFrames();
  }

  /// Load frames - prioritize interpolated frames, fallback to raw/images
  Future<void> _loadFrames() async {
    setState(() {
      _isLoading = true;
      _loadingError = null;
    });

    try {
      // Use provided image URLs, files, or bytes directly
      // Video-based capture already provides smooth frames, no interpolation needed
      if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
        // Load frames from URLs using the service
        final frames = await UrlInterpolationService.generateFromUrls(
          imageUrls: widget.imageUrls!,
        );
        if (mounted) {
          setState(() {
            _loadedFrames = frames;
            _totalFrames = frames.length;
            _isLoading = false;
          });
          _controller.setIndex(widget.initialIndex.clamp(0, _totalFrames - 1), smooth: false);
        }
        return;
      }

      // Fallback: Use provided image bytes
      if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _loadedFrames = widget.imageBytes!;
            _totalFrames = widget.imageBytes!.length;
            _isLoading = false;
          });
          _controller.setIndex(widget.initialIndex.clamp(0, _totalFrames - 1), smooth: false);
        }
        return;
      }

      // Final fallback: No frames available
      throw Exception('No frames available. Please provide image URLs or bytes.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Toggle full screen
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Build smooth blended viewer with 64 frames
  Widget _buildSmoothBlendedViewer() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final currentIndex = _controller.currentIndex.clamp(0, _loadedFrames.length - 1);
        final previousIndex = _controller.previousIndex.clamp(0, _loadedFrames.length - 1);
        final blendProgress = _controller.blendProgress;

        return XGestureDetector(
          onMoveUpdate: (event) {
            // Adjust sensitivity based on total frames
            final adjustedSensitivity = _sensitivity * (16.0 / _totalFrames);
            _controller.onDragUpdate(event.delta.dx, adjustedSensitivity);
          },
          onMoveStart: (event) {
            _controller.onDragStart();
          },
          onMoveEnd: (event) {
            // Calculate velocity from event delta
            final velocity = event.delta.dx * 60;
            _controller.onDragEnd(velocity);
          },
          child: SmoothImageBlend(
            previousFrameIndex: previousIndex,
            nextFrameIndex: currentIndex,
            blendProgress: blendProgress,
            imageBytes: _loadedFrames,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading 360° view...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadingError != null || _loadedFrames.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _loadingError ?? 'No frames available',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadFrames,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: Icon(_controller.autoRotate ? Icons.pause : Icons.play_arrow),
                  onPressed: () => _controller.toggleAutoRotate(),
                  tooltip: 'Auto Rotate',
                ),
                IconButton(
                  icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
                  onPressed: _toggleFullScreen,
                  tooltip: 'Full Screen',
                ),
              ],
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Main viewer with 64 interpolated frames
          _buildSmoothBlendedViewer(),
          
          // Drag to rotate hint at bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swipe, color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Drag to rotate ($_totalFrames frames)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


