import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:carhive/widgets/smooth_image_blend.dart';
import 'package:carhive/controllers/advanced_360_controller.dart';
import 'package:carhive/services/url_interpolation_service.dart';
import 'package:carhive/widgets/interpolation_progress_dialog.dart';

/// Full-screen 360° car viewer with smooth blending and momentum physics
class Car360ViewerScreen extends StatefulWidget {
  /// List of image URLs (from Cloudinary)
  final List<String>? imageUrls;

  /// List of local image files
  final List<File?>? imageFiles;

  /// List of image bytes (for preview)
  final List<Uint8List?>? imageBytes;

  /// Title to display in app bar
  final String title;

  /// Initial frame index
  final int initialIndex;

  const Car360ViewerScreen({
    super.key,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.title = '360° View',
    this.initialIndex = 0,
  });

  @override
  State<Car360ViewerScreen> createState() => _Car360ViewerScreenState();
}

class _Car360ViewerScreenState extends State<Car360ViewerScreen>
    with TickerProviderStateMixin {
  late Advanced360Controller _controller;
  
  // Drag sensitivity (adjusted for number of frames)
  double _sensitivity = 15.0;
  
  // Full screen mode
  bool _isFullScreen = false;
  
  // Number of frames
  int _totalFrames = 16;
  
  // Loaded frames (for interpolated frames from URLs)
  List<Uint8List?>? _interpolatedFrames;
  bool _isGeneratingFrames = false;
  bool _useInterpolatedFrames = false;
  bool _shouldGenerateFrames = false;
  bool _hasGenerated = false;

  @override
  void initState() {
    super.initState();
    _controller = Advanced360Controller();
    _controller.initialize(this);
    
    // Determine total frames
    if (widget.imageUrls != null) {
      _totalFrames = widget.imageUrls!.length;
      // Mark that we should generate frames (will do in didChangeDependencies)
      if (_totalFrames == 16) {
        _shouldGenerateFrames = true;
      }
    } else if (widget.imageFiles != null) {
      _totalFrames = widget.imageFiles!.length;
    } else if (widget.imageBytes != null) {
      _totalFrames = widget.imageBytes!.length;
    }
    
    // Adjust controller for actual frame count
    _controller.setMaxFrames(_totalFrames);
    _controller.setIndex(widget.initialIndex.clamp(0, _totalFrames - 1), smooth: false);
    
    // Reset sensitivity if out of valid slider range (prevents errors from hot reload)
    if (_sensitivity < 5.0 || _sensitivity > 30.0) {
      _sensitivity = 15.0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Generate frames after dependencies are ready (can use context now)
    // Only do this once after the first build
    if (_shouldGenerateFrames && !_isGeneratingFrames && !_hasGenerated && mounted) {
      _hasGenerated = true;
      _shouldGenerateFrames = false;
      // Use double post-frame callback to ensure widget tree is fully built with all inherited widgets
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isGeneratingFrames) {
            _generateInterpolatedFramesFromUrls();
          }
        });
      });
    }
  }
  
  /// Generate 64 interpolated frames from 16 URL images
  Future<void> _generateInterpolatedFramesFromUrls() async {
    if (widget.imageUrls == null || widget.imageUrls!.length != 16) return;
    if (_isGeneratingFrames) return;
    if (!mounted) return;
    
    setState(() {
      _isGeneratingFrames = true;
    });
    
    // Wait a frame to ensure context is fully available
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) {
      setState(() {
        _isGeneratingFrames = false;
      });
      return;
    }
    
    // Show progress dialog
    InterpolationProgressDialog.show(
      context,
      current: 0,
      total: 100,
      message: 'Generating smooth 360° view...',
    );
    
    try {
      final frames = await UrlInterpolationService.generateFromUrls(
        imageUrls: widget.imageUrls!,
        onProgress: (current, total, message) {
          if (mounted) {
            InterpolationProgressDialog.update(
              context,
              current: current,
              total: total,
              message: message,
            );
          }
        },
      );
      
      if (mounted) {
        InterpolationProgressDialog.hide(context);
        
        setState(() {
          _interpolatedFrames = frames;
          _totalFrames = 64;
          _useInterpolatedFrames = true;
          _isGeneratingFrames = false;
        });
        
        // Update controller for 64 frames
        _controller.setMaxFrames(64);
        _controller.setIndex(0, smooth: false);
      }
    } catch (e) {
      if (mounted) {
        InterpolationProgressDialog.hide(context);
        setState(() {
          _isGeneratingFrames = false;
        });
        
        // Show error but continue with 16 frames
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using 16 frames. Smooth view generation failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Toggle full screen mode
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

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Build the settings panel
  Widget _buildSettingsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Viewer Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          // Auto-rotate toggle
          SwitchListTile(
            title: const Text(
              'Auto Rotate',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _controller.autoRotate ? 'Rotating automatically' : 'Drag to rotate',
              style: const TextStyle(color: Colors.white54),
            ),
            value: _controller.autoRotate,
            onChanged: (value) {
              _controller.setAutoRotate(value);
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          // Sensitivity slider
          ListTile(
            title: const Text(
              'Drag Sensitivity',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pixels per frame change',
                  style: TextStyle(color: Colors.white54),
                ),
                Slider(
                  value: _sensitivity.clamp(5.0, 30.0),
                  min: 5.0,
                  max: 30.0,
                  divisions: 5,
                  label: _sensitivity.clamp(5.0, 30.0).round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _sensitivity = value.clamp(5.0, 30.0);
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sensitive',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Smooth',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
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

  /// Show settings bottom sheet
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsPanel(),
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
                // Settings button
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: _showSettings,
                  tooltip: 'Settings',
                ),
                // Full screen toggle
                IconButton(
                  icon: Icon(
                    _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                  onPressed: _toggleFullScreen,
                  tooltip: 'Full Screen',
                ),
              ],
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Smooth blended 360° Viewer
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final currentIndex = _controller.currentIndex.clamp(0, _totalFrames - 1);
              final previousIndex = _controller.previousIndex.clamp(0, _totalFrames - 1);
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
                  final velocity = event.delta.dx * 60;
                  _controller.onDragEnd(velocity);
                },
                child: SmoothImageBlend(
                  previousFrameIndex: previousIndex,
                  nextFrameIndex: currentIndex,
                  blendProgress: blendProgress,
                  imageUrls: _useInterpolatedFrames ? null : widget.imageUrls,
                  imageFiles: widget.imageFiles,
                  imageBytes: _useInterpolatedFrames ? _interpolatedFrames : widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
          
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
                      'Drag to rotate (${_totalFrames} frames)',
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

