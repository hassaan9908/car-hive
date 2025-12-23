import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:carhive/widgets/smooth_image_blend.dart';
import 'package:carhive/controllers/advanced_360_controller.dart';

/// Advanced 360° viewer with drag rotation, momentum physics, smooth interpolation, and zoom
class Advanced360ViewerScreen extends StatefulWidget {
  /// List of image URLs
  final List<String>? imageUrls;
  
  /// List of image files
  final List<File?>? imageFiles;
  
  /// List of image bytes
  final List<Uint8List?>? imageBytes;
  
  /// Title
  final String title;
  
  /// Initial frame index
  final int initialIndex;

  const Advanced360ViewerScreen({
    super.key,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.title = '360° View',
    this.initialIndex = 0,
  });

  @override
  State<Advanced360ViewerScreen> createState() => _Advanced360ViewerScreenState();
}

class _Advanced360ViewerScreenState extends State<Advanced360ViewerScreen>
    with TickerProviderStateMixin {
  late Advanced360Controller _controller;
  
  // Drag sensitivity
  final double _sensitivity = 50.0;
  
  // Full screen mode
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = Advanced360Controller();
    _controller.initialize(this);
    _controller.setIndex(widget.initialIndex, smooth: false);
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

  /// Reset zoom (placeholder for future zoom implementation)
  void _resetZoom() {
    // Zoom will be implemented with InteractiveViewer or similar
  }

  /// Build smooth blended viewer (alternative implementation)
  Widget _buildSmoothBlendedViewer() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final currentIndex = _controller.currentIndex;
        final previousIndex = _controller.previousIndex;
        final blendProgress = _controller.blendProgress;

        return XGestureDetector(
          onMoveUpdate: (event) {
            _controller.onDragUpdate(event.delta.dx, _sensitivity);
          },
          onMoveStart: (event) {
            _controller.onDragStart();
          },
          onMoveEnd: (event) {
            // Calculate velocity from event delta
            // Approximate velocity: delta * 60 (assuming 60fps)
            final velocity = event.delta.dx * 60;
            _controller.onDragEnd(velocity);
          },
          child: SmoothImageBlend(
            previousFrameIndex: previousIndex,
            nextFrameIndex: currentIndex,
            blendProgress: blendProgress,
            imageUrls: widget.imageUrls,
            imageFiles: widget.imageFiles,
            imageBytes: widget.imageBytes,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

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
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetZoom,
                  tooltip: 'Reset Zoom',
                ),
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
          // Main viewer
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swipe, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Drag to rotate',
                      style: TextStyle(
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

