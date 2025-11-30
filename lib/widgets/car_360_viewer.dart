import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carhive/models/car_360_set.dart';

/// A drag-to-rotate 360° car viewer widget using sprite-based frame rotation
/// 
/// This widget displays 16 images in sequence and changes frames based on
/// horizontal drag gestures, creating a smooth 360° rotation effect.
class Car360Viewer extends StatefulWidget {
  /// List of 16 image URLs (from Cloudinary)
  final List<String>? imageUrls;

  /// List of 16 local files (for preview before upload)
  final List<File?>? imageFiles;

  /// List of 16 image bytes (for web or memory preview)
  final List<Uint8List?>? imageBytes;

  /// Initial frame index (0-15)
  final int initialIndex;

  /// Sensitivity: pixels per frame switch (lower = more sensitive)
  final double sensitivity;

  /// Whether to enable auto-rotation
  final bool autoRotate;

  /// Auto-rotation speed (frames per second)
  final double autoRotateSpeed;

  /// Whether to show angle indicator
  final bool showAngleIndicator;

  /// Whether to show thumbnail navigation
  final bool showThumbnails;

  /// Callback when frame changes
  final Function(int)? onFrameChanged;

  /// Background color
  final Color? backgroundColor;

  /// Placeholder widget while loading
  final Widget? placeholder;

  /// Error widget
  final Widget? errorWidget;

  const Car360Viewer({
    super.key,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.initialIndex = 0,
    this.sensitivity = 10.0,
    this.autoRotate = false,
    this.autoRotateSpeed = 8.0,
    this.showAngleIndicator = true,
    this.showThumbnails = false,
    this.onFrameChanged,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<Car360Viewer> createState() => _Car360ViewerState();
}

class _Car360ViewerState extends State<Car360Viewer>
    with SingleTickerProviderStateMixin {
  // Current frame index (0-15)
  late int _currentIndex;

  // Accumulated drag distance for frame switching
  double _rotationAccumulator = 0.0;

  // Timer for auto-rotation
  Timer? _autoRotateTimer;

  // Timer for inertial deceleration
  Timer? _inertiaTimer;

  // Whether user is currently dragging
  bool _isDragging = false;

  // Animation controller for smooth transitions
  late AnimationController _animationController;

  // Preloaded images for smooth viewing
  final Map<int, ImageProvider> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 15);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Preload images
    _preloadImages();

    // Start auto-rotation if enabled
    if (widget.autoRotate) {
      _startAutoRotation();
    }
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _inertiaTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Car360Viewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.autoRotate != oldWidget.autoRotate) {
      if (widget.autoRotate) {
        _startAutoRotation();
      } else {
        _stopAutoRotation();
      }
    }
  }

  /// Preload all 16 images for smooth viewing
  void _preloadImages() {
    if (widget.imageUrls != null) {
      for (int i = 0; i < widget.imageUrls!.length && i < 16; i++) {
        _imageCache[i] = CachedNetworkImageProvider(widget.imageUrls![i]);
        // Precache the image
        if (mounted) {
          precacheImage(_imageCache[i]!, context);
        }
      }
    }
  }

  /// Start auto-rotation animation
  void _startAutoRotation() {
    _autoRotateTimer?.cancel();
    final interval = (1000 / widget.autoRotateSpeed).round();
    _autoRotateTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (_) {
        if (!_isDragging && mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % 16;
          });
          widget.onFrameChanged?.call(_currentIndex);
        }
      },
    );
  }

  /// Stop auto-rotation
  void _stopAutoRotation() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = null;
  }

  /// Handle pan start
  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _inertiaTimer?.cancel();
    _rotationAccumulator = 0.0;
  }

  /// Handle pan update - core rotation logic
  void _onPanUpdate(DragUpdateDetails details) {
    // Accumulate horizontal drag distance
    _rotationAccumulator += details.delta.dx;

    // Check if accumulated distance exceeds sensitivity threshold
    if (_rotationAccumulator.abs() > widget.sensitivity) {
      setState(() {
        if (_rotationAccumulator > 0) {
          // Dragging right -> rotate clockwise (increase index)
          _currentIndex = (_currentIndex + 1) % 16;
        } else {
          // Dragging left -> rotate counter-clockwise (decrease index)
          _currentIndex = (_currentIndex - 1 + 16) % 16;
        }
      });

      // Reset accumulator
      _rotationAccumulator = 0.0;

      // Notify listener
      widget.onFrameChanged?.call(_currentIndex);
    }
  }

  /// Handle pan end - apply inertia
  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;

    // Apply inertial rotation based on velocity
    final velocity = details.velocity.pixelsPerSecond.dx;
    if (velocity.abs() > 100) {
      _applyInertia(velocity);
    }
  }

  /// Apply inertial rotation after drag ends
  void _applyInertia(double initialVelocity) {
    double currentVelocity = initialVelocity;
    const friction = 0.95; // Deceleration factor
    const minVelocity = 50.0; // Stop when velocity drops below this

    _inertiaTimer?.cancel();
    _inertiaTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60fps
      (timer) {
        if (!mounted || currentVelocity.abs() < minVelocity) {
          timer.cancel();
          return;
        }

        // Accumulate based on velocity
        _rotationAccumulator += currentVelocity * 0.016; // dt = 16ms

        if (_rotationAccumulator.abs() > widget.sensitivity * 2) {
          setState(() {
            if (_rotationAccumulator > 0) {
              _currentIndex = (_currentIndex + 1) % 16;
            } else {
              _currentIndex = (_currentIndex - 1 + 16) % 16;
            }
          });
          _rotationAccumulator = 0.0;
          widget.onFrameChanged?.call(_currentIndex);
        }

        // Apply friction
        currentVelocity *= friction;
      },
    );
  }

  /// Build the current frame image
  Widget _buildCurrentFrame() {
    // Priority: URLs > Files > Bytes
    if (widget.imageUrls != null &&
        _currentIndex < widget.imageUrls!.length) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrls![_currentIndex],
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            widget.placeholder ??
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            widget.errorWidget ??
            const Center(child: Icon(Icons.error_outline)),
      );
    }

    if (widget.imageFiles != null &&
        _currentIndex < widget.imageFiles!.length &&
        widget.imageFiles![_currentIndex] != null) {
      return Image.file(
        widget.imageFiles![_currentIndex]!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) =>
            widget.errorWidget ??
            const Center(child: Icon(Icons.error_outline)),
      );
    }

    if (widget.imageBytes != null &&
        _currentIndex < widget.imageBytes!.length &&
        widget.imageBytes![_currentIndex] != null) {
      return Image.memory(
        widget.imageBytes![_currentIndex]!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) =>
            widget.errorWidget ??
            const Center(child: Icon(Icons.error_outline)),
      );
    }

    return widget.placeholder ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'No image',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        );
  }

  /// Build angle indicator overlay
  Widget _buildAngleIndicator() {
    if (!widget.showAngleIndicator) return const SizedBox.shrink();

    final angle = Car360Set.getAngleDegrees(_currentIndex);

    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.rotate_90_degrees_ccw,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${angle.toStringAsFixed(1)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_currentIndex + 1}/16)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build drag hint overlay
  Widget _buildDragHint() {
    return Positioned(
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
    );
  }

  /// Build thumbnail navigation strip
  Widget _buildThumbnails() {
    if (!widget.showThumbnails) return const SizedBox.shrink();

    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 16,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final isSelected = index == _currentIndex;

            Widget thumbnail;
            if (widget.imageUrls != null && index < widget.imageUrls!.length) {
              thumbnail = CachedNetworkImage(
                imageUrl: widget.imageUrls![index],
                fit: BoxFit.cover,
              );
            } else if (widget.imageBytes != null &&
                index < widget.imageBytes!.length &&
                widget.imageBytes![index] != null) {
              thumbnail = Image.memory(
                widget.imageBytes![index]!,
                fit: BoxFit.cover,
              );
            } else {
              thumbnail = Container(
                color: Colors.grey[800],
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
                widget.onFrameChanged?.call(index);
              },
              child: Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.6,
                    child: thumbnail,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Colors.black,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image
            Center(child: _buildCurrentFrame()),

            // Angle indicator
            _buildAngleIndicator(),

            // Drag hint
            _buildDragHint(),

            // Thumbnails
            _buildThumbnails(),
          ],
        ),
      ),
    );
  }
}

/// A compact 360° preview widget with play button overlay
class Car360PreviewWidget extends StatefulWidget {
  /// List of image URLs
  final List<String> imageUrls;

  /// Size of the preview
  final double size;

  /// Callback when tapped
  final VoidCallback? onTap;

  const Car360PreviewWidget({
    super.key,
    required this.imageUrls,
    this.size = 120,
    this.onTap,
  });

  @override
  State<Car360PreviewWidget> createState() => _Car360PreviewWidgetState();
}

class _Car360PreviewWidgetState extends State<Car360PreviewWidget> {
  int _previewIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();
    // Animate through frames slowly for preview
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) {
        if (mounted) {
          setState(() {
            _previewIndex = (_previewIndex + 1) % widget.imageUrls.length;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: Text('No 360° images')),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated preview image
              CachedNetworkImage(
                imageUrl: widget.imageUrls[_previewIndex],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),

              // 360° badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.threesixty, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '360°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Play/View overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

