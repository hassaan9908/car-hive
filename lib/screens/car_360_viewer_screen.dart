import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carhive/widgets/car_360_viewer.dart';
import 'package:carhive/models/car_360_set.dart';

/// Full-screen 360° car viewer with controls
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

class _Car360ViewerScreenState extends State<Car360ViewerScreen> {
  // Current frame index
  int _currentIndex = 0;

  // Auto-rotate toggle
  bool _autoRotate = false;

  // Show thumbnails toggle
  bool _showThumbnails = false;

  // Sensitivity value
  double _sensitivity = 10.0;

  // Full screen mode
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Build the settings panel
  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
              _autoRotate ? 'Rotating automatically' : 'Drag to rotate',
              style: const TextStyle(color: Colors.white54),
            ),
            value: _autoRotate,
            onChanged: (value) {
              setState(() {
                _autoRotate = value;
              });
              Navigator.pop(context);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          // Show thumbnails toggle
          SwitchListTile(
            title: const Text(
              'Show Thumbnails',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Display thumbnail navigation',
              style: TextStyle(color: Colors.white54),
            ),
            value: _showThumbnails,
            onChanged: (value) {
              setState(() {
                _showThumbnails = value;
              });
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
                  value: _sensitivity,
                  min: 5.0,
                  max: 30.0,
                  divisions: 5,
                  label: _sensitivity.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _sensitivity = value;
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
    final angle = Car360Set.getAngleDegrees(_currentIndex);
    final angleName = Car360Set.getAngleName(_currentIndex);

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
      body: GestureDetector(
        onDoubleTap: _toggleFullScreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 360° Viewer
            Car360Viewer(
              imageUrls: widget.imageUrls,
              imageFiles: widget.imageFiles,
              imageBytes: widget.imageBytes,
              initialIndex: _currentIndex,
              sensitivity: _sensitivity,
              autoRotate: _autoRotate,
              showAngleIndicator: !_isFullScreen,
              showThumbnails: _showThumbnails,
              onFrameChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.black,
            ),

            // Bottom info panel (only when not in full screen)
            if (!_isFullScreen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Angle info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${angle.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              angleName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Previous frame
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              color: Colors.white,
                              iconSize: 32,
                              onPressed: () {
                                setState(() {
                                  _currentIndex = (_currentIndex - 1 + 16) % 16;
                                });
                              },
                            ),

                            // Auto-rotate toggle
                            IconButton(
                              icon: Icon(
                                _autoRotate
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                              ),
                              color: _autoRotate
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white,
                              iconSize: 48,
                              onPressed: () {
                                setState(() {
                                  _autoRotate = !_autoRotate;
                                });
                              },
                            ),

                            // Next frame
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              color: Colors.white,
                              iconSize: 32,
                              onPressed: () {
                                setState(() {
                                  _currentIndex = (_currentIndex + 1) % 16;
                                });
                              },
                            ),
                          ],
                        ),

                        // Frame indicator
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(16, (index) {
                            final isSelected = index == _currentIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              child: Container(
                                width: isSelected ? 12 : 8,
                                height: isSelected ? 12 : 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white38,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Full screen exit hint
            if (_isFullScreen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  color: Colors.white54,
                  onPressed: _toggleFullScreen,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

