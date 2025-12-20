import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget that smoothly blends between two frames for seamless 360° rotation
/// 
/// This creates the illusion of more frames by interpolating between the 16
/// actual frames using opacity blending over 80-120ms transitions.
class SmoothImageBlend extends StatefulWidget {
  /// Previous frame index
  final int previousFrameIndex;
  
  /// Next frame index
  final int nextFrameIndex;
  
  /// Blend progress (0.0 = previous, 1.0 = next)
  final double blendProgress;
  
  /// List of image URLs
  final List<String>? imageUrls;
  
  /// List of image files
  final List<File?>? imageFiles;
  
  /// List of image bytes
  final List<Uint8List?>? imageBytes;
  
  /// Box fit for images
  final BoxFit fit;
  
  /// Placeholder widget
  final Widget? placeholder;
  
  /// Error widget
  final Widget? errorWidget;

  const SmoothImageBlend({
    super.key,
    required this.previousFrameIndex,
    required this.nextFrameIndex,
    required this.blendProgress,
    this.imageUrls,
    this.imageFiles,
    this.imageBytes,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SmoothImageBlend> createState() => _SmoothImageBlendState();
}

class _SmoothImageBlendState extends State<SmoothImageBlend> {
  /// Build image widget for a given index
  Widget _buildImage(int index) {
    // Priority: URLs > Files > Bytes
    if (widget.imageUrls != null && index < widget.imageUrls!.length) {
      return CachedNetworkImage(
        imageUrl: widget.imageUrls![index],
        fit: widget.fit,
        placeholder: (context, url) =>
            widget.placeholder ??
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            widget.errorWidget ??
            const Center(child: Icon(Icons.error_outline)),
      );
    }

    if (widget.imageFiles != null &&
        index < widget.imageFiles!.length &&
        widget.imageFiles![index] != null) {
      return Image.file(
        widget.imageFiles![index]!,
        fit: widget.fit,
        errorBuilder: (context, error, stack) =>
            widget.errorWidget ??
            const Center(child: Icon(Icons.error_outline)),
      );
    }

    if (widget.imageBytes != null &&
        index < widget.imageBytes!.length &&
        widget.imageBytes![index] != null) {
      return Image.memory(
        widget.imageBytes![index]!,
        fit: widget.fit,
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

  @override
  Widget build(BuildContext context) {
    // Clamp blend progress between 0 and 1
    final progress = widget.blendProgress.clamp(0.0, 1.0);
    
    // If progress is 0, show only previous frame
    if (progress == 0.0) {
      return _buildImage(widget.previousFrameIndex);
    }
    
    // If progress is 1, show only next frame
    if (progress == 1.0) {
      return _buildImage(widget.nextFrameIndex);
    }
    
    // Otherwise, blend between the two frames
    return Stack(
      fit: StackFit.expand,
      children: [
        // Previous frame (fading out)
        Opacity(
          opacity: 1.0 - progress,
          child: _buildImage(widget.previousFrameIndex),
        ),
        // Next frame (fading in)
        Opacity(
          opacity: progress,
          child: _buildImage(widget.nextFrameIndex),
        ),
      ],
    );
  }
}

