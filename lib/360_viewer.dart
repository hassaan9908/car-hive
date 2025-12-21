import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Smooth 360° viewer with inertia and momentum
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
  
  int _currentFrameIndex = 0;
  double _dragOffset = 0.0;
  double _velocity = 0.0;
  bool _isDragging = false;
  
  // Momentum parameters
  static const double _friction = 0.95; // Friction coefficient
  static const double _minVelocity = 0.1; // Minimum velocity to continue momentum
  Timer? _momentumTimer;
  
  // Frame cache
  final Map<int, ImageProvider> _frameCache = {};

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
    
    _momentumController.addListener(_updateMomentum);
    
    // Pre-cache first few frames
    _precacheFrames();
    
    // Auto-rotate if enabled
    if (widget.autoRotateSpeed != 0.0) {
      _startAutoRotate();
    }
  }

  @override
  void dispose() {
    _momentumTimer?.cancel();
    _animationController.dispose();
    _momentumController.dispose();
    super.dispose();
  }

  /// Pre-cache frames for smooth playback
  void _precacheFrames() {
    final framesToCache = widget.frameUrls.length;
    for (int i = 0; i < framesToCache && i < 10; i++) {
      _loadFrame(i);
    }
  }

  /// Load frame into cache
  Future<void> _loadFrame(int index) async {
    if (_frameCache.containsKey(index)) return;
    
    final frameUrl = widget.frameUrls[index];
    ImageProvider? provider;
    
    try {
      if (frameUrl.startsWith('http://') || frameUrl.startsWith('https://')) {
        // Network image
        provider = CachedNetworkImageProvider(frameUrl);
      } else if (File(frameUrl).existsSync()) {
        // Local file
        provider = FileImage(File(frameUrl));
      }
      
      if (provider != null) {
        _frameCache[index] = provider;
        // Precache the image
        await precacheImage(provider, context);
      }
    } catch (e) {
      print('Error loading frame $index: $e');
    }
  }

  /// Get image provider for frame
  ImageProvider? _getFrameProvider(int index) {
    if (index < 0 || index >= widget.frameUrls.length) return null;
    
    if (!_frameCache.containsKey(index)) {
      _loadFrame(index);
    }
    
    return _frameCache[index];
  }

  /// Start auto-rotation
  void _startAutoRotate() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _isDragging) return;
      
      setState(() {
        _currentFrameIndex = (_currentFrameIndex + (widget.autoRotateSpeed * 0.5).round()) % widget.frameUrls.length;
        if (_currentFrameIndex < 0) {
          _currentFrameIndex = widget.frameUrls.length + _currentFrameIndex;
        }
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
      
      final newIndex = (_currentFrameIndex + offsetFrames.round()) % framesPer360;
      if (newIndex != _currentFrameIndex) {
        _currentFrameIndex = newIndex >= 0 ? newIndex : framesPer360 + newIndex;
        _dragOffset = 0.0;
        _loadFrame(_currentFrameIndex);
        _loadFrame((_currentFrameIndex + 1) % framesPer360);
        _loadFrame((_currentFrameIndex - 1 + framesPer360) % framesPer360);
      }
    });
  }

  /// Handle drag start
  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _velocity = 0.0;
    _momentumTimer?.cancel();
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
      final sensitivity = 3.0; // Adjust for sensitivity
      final frameDelta = (_dragOffset / sensitivity).round();
      
      if (frameDelta.abs() >= 1) {
        final newIndex = (_currentFrameIndex + frameDelta) % framesPer360;
        _currentFrameIndex = newIndex >= 0 ? newIndex : framesPer360 + newIndex;
        _dragOffset = 0.0;
        
        // Pre-load adjacent frames
        _loadFrame(_currentFrameIndex);
        _loadFrame((_currentFrameIndex + 1) % framesPer360);
        _loadFrame((_currentFrameIndex - 1 + framesPer360) % framesPer360);
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

  /// Get current frame image
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
    
    if (provider == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Image(
      image: provider,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error, color: Colors.red, size: 48),
        );
      },
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('360° Viewer'),
                  content: const Text(
                    'Drag horizontally to rotate the car.\n\n'
                    'The rotation has smooth momentum and inertia.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Center(
          child: _buildCurrentFrame(),
        ),
      ),
    );
  }
}

