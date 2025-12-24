import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:carhive/models/car_360_set.dart';
import 'package:carhive/screens/advanced_360_viewer_screen.dart';
import 'package:carhive/utils/360_file_handler.dart';

/// Preview grid screen showing all 16 captured images
class Car360PreviewGridScreen extends StatefulWidget {
  /// List of image URLs
  final List<String>? imageUrls;
  
  /// List of image files
  final List<File?>? imageFiles;
  
  /// List of image bytes
  final List<Uint8List?>? imageBytes;
  
  /// Title
  final String title;

  const Car360PreviewGridScreen({
    super.key,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.title = '360° Preview',
  });

  @override
  State<Car360PreviewGridScreen> createState() => _Car360PreviewGridScreenState();
}

class _Car360PreviewGridScreenState extends State<Car360PreviewGridScreen> {
  /// Load images from file system if not provided
  Future<List<Uint8List?>> _loadImages() async {
    if (widget.imageBytes != null) {
      return widget.imageBytes!;
    }
    
    if (widget.imageFiles != null) {
      final List<Uint8List?> bytes = [];
      for (final file in widget.imageFiles!) {
        if (file != null) {
          bytes.add(await file.readAsBytes());
        } else {
          bytes.add(null);
        }
      }
      return bytes;
    }
    
    // Try loading from file system
    try {
      return await Car360FileHandler.loadAllImagesAsBytes();
    } catch (e) {
      print('Error loading images: $e');
      return List.filled(16, null);
    }
  }

  /// Build image widget for grid item
  Widget _buildImageWidget(int index, Uint8List? bytes) {
    if (widget.imageUrls != null && index < widget.imageUrls!.length) {
      return Image.network(
        widget.imageUrls![index],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildPlaceholder(index),
      );
    }
    
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildPlaceholder(index),
      );
    }
    
    if (widget.imageFiles != null &&
        index < widget.imageFiles!.length &&
        widget.imageFiles![index] != null) {
      return Image.file(
        widget.imageFiles![index]!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildPlaceholder(index),
      );
    }
    
    return _buildPlaceholder(index);
  }

  /// Build placeholder for missing image
  Widget _buildPlaceholder(int index) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[600],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '${index + 1}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to 360° viewer
  void _navigateToViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Advanced360ViewerScreen(
          imageUrls: widget.imageUrls,
          imageFiles: widget.imageFiles,
          imageBytes: widget.imageBytes,
          title: widget.title,
          initialIndex: initialIndex,
        ),
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
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.threesixty),
            onPressed: () => _navigateToViewer(0),
            tooltip: 'View 360°',
          ),
        ],
      ),
      body: FutureBuilder<List<Uint8List?>>(
        future: _loadImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final images = snapshot.data ?? List.filled(16, null);
          final hasImages = images.any((img) => img != null) ||
              widget.imageUrls != null ||
              widget.imageFiles != null;

          if (!hasImages) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No 360° images found',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final bytes = index < images.length ? images[index] : null;
              final angle = Car360Set.getAngleDegrees(index);

              return GestureDetector(
                onTap: () => _navigateToViewer(index),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: bytes != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800]!,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        _buildImageWidget(index, bytes),
                        // Overlay with angle info
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${index + 1}/16',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${angle.toStringAsFixed(0)}°',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Checkmark for captured images
                        if (bytes != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

