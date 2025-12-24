import 'dart:async';
import 'package:flutter/material.dart';

/// Advanced controller for 360° viewer with momentum physics and smooth interpolation
class Advanced360Controller extends ChangeNotifier {
  // Current frame index
  int _currentIndex = 0;
  
  // Total number of frames (configurable)
  int _totalFrames = 64;
  
  // Current blend progress (0.0 to 1.0) for smooth interpolation
  double _blendProgress = 0.0;
  
  // Previous frame index for blending
  int _previousIndex = 0;
  
  // Whether user is currently dragging
  bool _isDragging = false;
  
  // Whether momentum animation is active
  bool _isMomentumActive = false;
  
  // Auto-rotate enabled
  bool _autoRotate = false;
  
  // Idle timer for auto-rotate
  Timer? _idleTimer;
  
  // Momentum timer
  Timer? _momentumTimer;
  
  // Blend animation controller
  AnimationController? _blendController;
  
  // Friction constant (0.95 = 5% reduction per frame)
  static const double _friction = 0.95;
  
  // Minimum velocity to continue momentum
  static const double _minVelocity = 50.0;
  
  // Maximum momentum speed (frames per second)
  static const double _maxMomentumSpeed = 8.0;
  
  // Blend duration (80-120ms)
  static const Duration _blendDuration = Duration(milliseconds: 100);
  
  // Idle timeout before auto-rotate (2 seconds)
  static const Duration _idleTimeout = Duration(seconds: 2);
  
  // Auto-rotate speed (frames per second)
  static const double _autoRotateSpeed = 2.0;

  int get currentIndex => _currentIndex;
  double get blendProgress => _blendProgress;
  int get previousIndex => _previousIndex;
  bool get isDragging => _isDragging;
  bool get isMomentumActive => _isMomentumActive;
  bool get autoRotate => _autoRotate;
  int get totalFrames => _totalFrames;
  
  /// Set maximum number of frames
  void setMaxFrames(int frames) {
    _totalFrames = frames;
  }

  /// Initialize with animation controller
  void initialize(TickerProvider vsync) {
    _blendController = AnimationController(
      vsync: vsync,
      duration: _blendDuration,
    );
    
    _blendController!.addListener(() {
      _blendProgress = _blendController!.value;
      notifyListeners();
    });
    
    _startIdleTimer();
  }

  /// Dispose resources
  @override
  void dispose() {
    _idleTimer?.cancel();
    _momentumTimer?.cancel();
    _blendController?.dispose();
    super.dispose();
  }

  /// Set current index (with smooth transition)
  void setIndex(int index, {bool smooth = true}) {
    if (index < 0 || index >= _totalFrames) return;
    
    final clampedIndex = index % _totalFrames;
    
    if (clampedIndex == _currentIndex) return;
    
    _previousIndex = _currentIndex;
    
    if (smooth && _blendController != null) {
      _blendController!.forward(from: 0.0);
    } else {
      _blendProgress = 1.0;
    }
    
    _currentIndex = clampedIndex;
    notifyListeners();
  }

  /// Handle drag start
  void onDragStart() {
    _isDragging = true;
    _dragAccumulator = 0.0; // Reset accumulator
    _stopMomentum();
    _stopAutoRotate();
    notifyListeners();
  }

  // Accumulated drag distance for smoother frame switching
  double _dragAccumulator = 0.0;
  
  /// Handle drag update
  void onDragUpdate(double deltaX, double sensitivity) {
    if (!_isDragging) return;
    
    // Accumulate drag distance for smoother transitions
    _dragAccumulator += deltaX;
    
    // Check if we should change frames (using accumulated distance)
    if (_dragAccumulator.abs() > sensitivity) {
      final direction = _dragAccumulator > 0 ? 1 : -1;
      final nextIndex = (_currentIndex + direction + _totalFrames) % _totalFrames;
      setIndex(nextIndex, smooth: true);
      // Reset accumulator but keep remainder for next frame
      _dragAccumulator = _dragAccumulator % sensitivity;
    }
  }

  /// Handle drag end with velocity
  void onDragEnd(double velocity) {
    _isDragging = false;
    
    // Clamp velocity to max momentum speed
    final clampedVelocity = velocity.clamp(
      -_maxMomentumSpeed * 100, // Convert to pixels per second
      _maxMomentumSpeed * 100,
    );
    
    if (clampedVelocity.abs() > _minVelocity) {
      _startMomentum(clampedVelocity);
    } else {
      _startIdleTimer();
    }
    
    notifyListeners();
  }

  /// Start momentum animation
  void _startMomentum(double initialVelocity) {
    _stopMomentum();
    _isMomentumActive = true;
    
    double currentVelocity = initialVelocity;
    const frameTime = 16.0; // ~60fps
    
    _momentumTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        if (!_isMomentumActive || currentVelocity.abs() < _minVelocity) {
          _stopMomentum();
          _startIdleTimer();
          return;
        }
        
        // Convert velocity to frame change
        // Assuming sensitivity of 50 pixels per frame
        const sensitivity = 50.0;
        final frameDelta = (currentVelocity * frameTime / 1000.0) / sensitivity;
        
        if (frameDelta.abs() >= 1.0) {
          final direction = frameDelta > 0 ? 1 : -1;
          final nextIndex = (_currentIndex + direction + _totalFrames) % _totalFrames;
          setIndex(nextIndex, smooth: true);
        }
        
        // Apply friction
        currentVelocity *= _friction;
      },
    );
    
    notifyListeners();
  }

  /// Stop momentum animation
  void _stopMomentum() {
    _momentumTimer?.cancel();
    _momentumTimer = null;
    _isMomentumActive = false;
    notifyListeners();
  }

  /// Start idle timer for auto-rotate
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, () {
      if (!_isDragging && !_isMomentumActive && _autoRotate) {
        _startAutoRotate();
      }
    });
  }

  /// Start auto-rotate
  void _startAutoRotate() {
    if (!_autoRotate) return;
    
    final interval = (1000 / _autoRotateSpeed).round();
    
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(
      Duration(milliseconds: interval),
      (timer) {
        if (_isDragging || _isMomentumActive || !_autoRotate) {
          timer.cancel();
          return;
        }
        
        final nextIndex = (_currentIndex + 1) % _totalFrames;
        setIndex(nextIndex, smooth: true);
      },
    );
  }

  /// Stop auto-rotate
  void _stopAutoRotate() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Toggle auto-rotate
  void toggleAutoRotate() {
    _autoRotate = !_autoRotate;
    
    if (_autoRotate) {
      _startIdleTimer();
    } else {
      _stopAutoRotate();
    }
    
    notifyListeners();
  }

  /// Set auto-rotate
  void setAutoRotate(bool enabled) {
    if (_autoRotate == enabled) return;
    
    _autoRotate = enabled;
    
    if (_autoRotate) {
      _startIdleTimer();
    } else {
      _stopAutoRotate();
    }
    
    notifyListeners();
  }

  /// Reset to initial state
  void reset() {
    _stopMomentum();
    _stopAutoRotate();
    _isDragging = false;
    _blendProgress = 0.0;
    _startIdleTimer();
    notifyListeners();
  }
}

