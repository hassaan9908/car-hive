import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Smooth 360° viewer with inertia, momentum, and zoom functionality
class Viewer360Screen extends StatefulWidget {
  /// List of frame URLs (local paths or URLs)
  final List<String> frameUrls;

  /// Auto-rotate speed (0 = disabled, positive = clockwise, negative = counter-clockwise)
  final double autoRotateSpeed;

  const Viewer360Screen({
    super.key,
    required this.frameUrls,
    this.autoRotateSpeed = 0.0,
  });

  @override
  State<Viewer360Screen> createState() => _Viewer360ScreenState();
}

class _Viewer360ScreenState extends State<Viewer360Screen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _momentumController;
  late AnimationController _zoomController;

  int _currentFrameIndex = 0;
  double _dragOffset = 0.0;
  double _velocity = 0.0;
  bool _isDragging = false;

  // Zoom parameters
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _isZooming = false;
  static const double _minScale = 1.0;
  static const double _maxScale = 3.0;

  // Momentum parameters
  static const double _friction = 0.95; // Friction coefficient
  static const double _minVelocity =
      0.1; // Minimum velocity to continue momentum
  Timer? _autoRotateTimer;

  // Frame cache - stores loaded image providers
  final Map<int, ImageProvider> _frameCache = {};
  // Track which frames are currently being loaded
  final Set<int> _loadingFrames = {};
  // Track which frames are fully loaded and ready
  final Set<int> _loadedFrames = {};
  // Track if initial precaching is complete
  bool _initialPrecacheComplete = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _momentumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _momentumController.addListener(_updateMomentum);

    // Pre-cache all frames aggressively before showing viewer
    _precacheAllFramesAggressively();

    // Auto-rotate if enabled
    if (widget.autoRotateSpeed != 0.0) {
      _startAutoRotate();
    }
  }

  @override
  void dispose() {
    _autoRotateTimer?.cancel();
    _animationController.dispose();
    _momentumController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  /// Aggressively pre-cache all frames for smooth playback
  Future<void> _precacheAllFramesAggressively() async {
    if (widget.frameUrls.isEmpty || !mounted) return;

    // Priority 1: Load first 10 frames and last frame synchronously for smooth initial viewing
    final priorityFrames = <int>[];
    final framesToPreload = widget.frameUrls.length < 10 ? widget.frameUrls.length : 10;
    for (int i = 0; i < framesToPreload; i++) {
      priorityFrames.add(i);
    }
    // Also load the last frame for wrap-around
    if (widget.frameUrls.length > framesToPreload) {
      priorityFrames.add(widget.frameUrls.length - 1);
    }
    
    // Load priority frames synchronously
    for (int index in priorityFrames) {
      if (index >= 0 && index < widget.frameUrls.length && mounted) {
        await _loadFrameSync(index);
      }
    }

    // Mark initial precache complete after priority frames
    if (mounted) {
      setState(() {
        _initialPrecacheComplete = true;
      });
    }

    // Priority 2: Load remaining frames in batches (non-blocking, but aggressive)
    // Load in batches of 20 for better parallel loading performance
    const batchSize = 20;
    for (int batchStart = 0; batchStart < widget.frameUrls.length; batchStart += batchSize) {
      if (!mounted) break;
      
      final batch = <Future<void>>[];
      for (int i = batchStart; i < batchStart + batchSize && i < widget.frameUrls.length; i++) {
        // Skip already loaded priority frames
        if (!priorityFrames.contains(i)) {
          batch.add(_loadFrameAsync(i));
        }
      }
      
      // Wait for batch to complete before starting next batch
      await Future.wait(batch, eagerError: false);
    }
  }

  /// Load frame synchronously (waits for completion)
  Future<void> _loadFrameSync(int index) async {
    if (index < 0 || index >= widget.frameUrls.length) return;
    if (_frameCache.containsKey(index) || _loadingFrames.contains(index)) {
      return;
    }

    _loadingFrames.add(index);
    final frameUrl = widget.frameUrls[index];
    ImageProvider? provider;

    try {
      if (frameUrl.startsWith('http://') || frameUrl.startsWith('https://')) {
        provider = CachedNetworkImageProvider(frameUrl);
      } else if (File(frameUrl).existsSync()) {
        provider = FileImage(File(frameUrl));
      }

      if (provider != null && mounted) {
        _frameCache[index] = provider;
        // Wait for precache to complete
        await precacheImage(provider, context);
        if (mounted) {
          _loadedFrames.add(index);
        }
      }
    } catch (e) {
      print('Error loading frame $index: $e');
    } finally {
      _loadingFrames.remove(index);
    }
  }

  /// Load frame asynchronously (non-blocking)
  Future<void> _loadFrameAsync(int index) async {
    if (index < 0 || index >= widget.frameUrls.length) return;
    if (_frameCache.containsKey(index) || _loadingFrames.contains(index)) {
      return;
    }

    _loadingFrames.add(index);
    final frameUrl = widget.frameUrls[index];
    ImageProvider? provider;

    try {
      if (frameUrl.startsWith('http://') || frameUrl.startsWith('https://')) {
        provider = CachedNetworkImageProvider(frameUrl);
      } else if (File(frameUrl).existsSync()) {
        provider = FileImage(File(frameUrl));
      }

      if (provider != null && mounted) {
        _frameCache[index] = provider;
        // Precache in background
        await precacheImage(provider, context);
        if (mounted) {
          _loadedFrames.add(index);
        }
      }
    } catch (e) {
      print('Error loading frame $index: $e');
    } finally {
      _loadingFrames.remove(index);
    }
  }

  /// Load frame into cache with priority (fallback method)
  Future<void> _loadFrame(int index, {bool priority = false}) async {
    if (priority) {
      await _loadFrameSync(index);
    } else {
      await _loadFrameAsync(index);
    }
  }
  
  /// Preload frames around current index for smooth transitions
  void _preloadAdjacentFrames(int centerIndex, {int radius = 5}) {
    for (int i = -radius; i <= radius; i++) {
      final index = (centerIndex + i) % widget.frameUrls.length;
      if (index < 0) {
        final adjustedIndex = widget.frameUrls.length + index;
        _loadFrame(adjustedIndex, priority: i.abs() <= 2);
      } else {
        _loadFrame(index, priority: i.abs() <= 2);
      }
    }
  }

  /// Get image provider for frame
  ImageProvider? _getFrameProvider(int index) {
    if (index < 0 || index >= widget.frameUrls.length) return null;

    // Load frame if not cached
    if (!_frameCache.containsKey(index)) {
      _loadFrame(index, priority: true);
    }

    return _frameCache[index];
  }

  /// Start auto-rotation
  void _startAutoRotate() {
    _autoRotateTimer?.cancel();
    _autoRotateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _isDragging || widget.frameUrls.isEmpty) return;
      final frames = widget.frameUrls.length;
      final step = (widget.autoRotateSpeed * 0.5).round().clamp(-2, 2);
      if (step == 0) return;
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + step) % frames;
        if (_currentFrameIndex < 0) _currentFrameIndex += frames;
        _preloadAdjacentFrames(_currentFrameIndex, radius: 5);
      });
    });
  }

  /// Update momentum animation
  void _updateMomentum() {
    if (!mounted) return;

    setState(() {
      _velocity *= _friction;

      if (_velocity.abs() < _minVelocity) {
        _velocity = 0.0;
        _momentumController.stop();
        return;
      }

      _dragOffset += _velocity;

      // Update frame index based on drag offset
      final framesPer360 = widget.frameUrls.length;
      final offsetFrames = _dragOffset / 100.0; // Adjust sensitivity

      final newIndex =
          (_currentFrameIndex + offsetFrames.round()) % framesPer360;
      if (newIndex != _currentFrameIndex) {
        _currentFrameIndex = newIndex >= 0 ? newIndex : framesPer360 + newIndex;
        _dragOffset = 0.0;
        // Preload adjacent frames for smooth transitions
        _preloadAdjacentFrames(_currentFrameIndex, radius: 5);
      }
    });
  }

  /// Handle drag start
  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _velocity = 0.0;
    _momentumController.stop();
  }

  /// Handle drag update
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragOffset += details.delta.dx;
      _velocity = details.delta.dx;

      // Update frame index
      final framesPer360 = widget.frameUrls.length;
      const sensitivity = 3.0; // Adjust for sensitivity
      final frameDelta = (_dragOffset / sensitivity).round();

      if (frameDelta.abs() >= 1) {
        final newIndex = (_currentFrameIndex + frameDelta) % framesPer360;
        _currentFrameIndex = newIndex >= 0 ? newIndex : framesPer360 + newIndex;
        _dragOffset = 0.0;

        // Preload adjacent frames for smooth transitions
        _preloadAdjacentFrames(_currentFrameIndex, radius: 5);
      }
    });
  }

  /// Handle drag end
  void _onDragEnd(DragEndDetails details) {
    _isDragging = false;

    // Apply momentum
    if (_velocity.abs() > _minVelocity) {
      _momentumController.repeat();
    } else {
      _velocity = 0.0;
    }
  }

  /// Handle scale start
  void _onScaleStart(ScaleStartDetails details) {
    _isZooming = true;
    _baseScale = _scale;
  }

  /// Handle scale update
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (!_isZooming) return;

    setState(() {
      _scale = (_baseScale * details.scale).clamp(_minScale, _maxScale);
    });
  }

  /// Handle scale end
  void _onScaleEnd(ScaleEndDetails details) {
    _isZooming = false;
    // Animate to nearest valid scale if needed
    if (_scale < _minScale) {
      _animateZoom(_minScale);
    } else if (_scale > _maxScale) {
      _animateZoom(_maxScale);
    }
  }

  /// Animate zoom to target scale
  void _animateZoom(double targetScale) {
    _zoomController.reset();
    final zoomAnimation = Tween<double>(begin: _scale, end: targetScale)
        .animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    ));

    zoomAnimation.addListener(() {
      if (mounted) {
        setState(() {
          _scale = zoomAnimation.value;
        });
      }
    });

    _zoomController.forward();
  }

  /// Reset zoom
  void _resetZoom() {
    _animateZoom(_minScale);
  }

  /// Get current frame image with zoom
  Widget _buildCurrentFrame() {
    if (widget.frameUrls.isEmpty) {
      return const Center(
        child: Text(
          'No frames available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final provider = _getFrameProvider(_currentFrameIndex);
    final isLoaded = _loadedFrames.contains(_currentFrameIndex);

    // Use CachedNetworkImage for better caching and smoother loading
    if (widget.frameUrls[_currentFrameIndex].startsWith('http://') || 
        widget.frameUrls[_currentFrameIndex].startsWith('https://')) {
      return Transform.scale(
        scale: _scale,
        alignment: Alignment.center,  // Scale from center to prevent shifting
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.frameUrls[_currentFrameIndex],
            fit: BoxFit.contain,
            alignment: Alignment.center,  // Center the image content
            // Optimize caching for smooth playback
            memCacheWidth: 1920,  // Limit memory cache size for performance
            memCacheHeight: 1080,
            maxWidthDiskCache: 1920,  // Limit disk cache size
            maxHeightDiskCache: 1080,
            // Faster fade for smoother transitions
            fadeInDuration: const Duration(milliseconds: 50),
            fadeOutDuration: const Duration(milliseconds: 30),
            // Show minimal loading indicator only if frame not in cache
            placeholder: (context, url) {
              // If frame is already loaded or initial precache is complete, show black background
              if (_loadedFrames.contains(_currentFrameIndex) || _initialPrecacheComplete) {
                return Container(color: Colors.black);
              }
              // Only show loading indicator during initial load
              return Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70),
            ),
          ),
        ),
      );
    }

    // Fallback for local files
    if (provider == null) {
      // Show loading only if initial precache not complete
      if (!_initialPrecacheComplete) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      // Otherwise show black background while loading
      return Container(color: Colors.black);
    }

      return Transform.scale(
        scale: _scale,
        alignment: Alignment.center,  // Scale from center to prevent shifting
        child: Image(
          image: provider,
          fit: BoxFit.contain,
          alignment: Alignment.center,  // Center the image content
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            // Show image if loaded, or if initial precache is complete (will show cached version)
            if (wasSynchronouslyLoaded || frame != null || isLoaded || _initialPrecacheComplete) {
              return child;
            }
            // Only show loading indicator during initial load
            return Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image, color: Colors.white70)),
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('360° Viewer'),
        actions: [
          // Zoom reset button
          if (_scale > _minScale)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetZoom,
              tooltip: 'Reset Zoom',
            ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Center(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRect(
                  child: _buildCurrentFrame(),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: _scale > _minScale
                  ? () {
                      setState(() {
                        _scale = (_scale - 0.2).clamp(_minScale, _maxScale);
                      });
                    }
                  : null,
              tooltip: 'Zoom Out',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${(_scale * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _scale < _maxScale
                  ? () {
                      setState(() {
                        _scale = (_scale + 0.2).clamp(_minScale, _maxScale);
                      });
                    }
                  : null,
              tooltip: 'Zoom In',
            ),
            const SizedBox(width: 16),
            const Text(
              'Pinch to zoom',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
