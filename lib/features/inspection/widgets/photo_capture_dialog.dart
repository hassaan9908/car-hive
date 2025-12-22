import 'package:flutter/material.dart';
import 'dart:io';
import '../services/photo_service.dart';

class PhotoCaptureDialog extends StatelessWidget {
  final BuildContext parentContext;
  final PhotoService photoService;
  final Function(List<String>) onPhotosSelected;
  final String inspectionId;
  final String itemId;

  const PhotoCaptureDialog({
    super.key,
    required this.parentContext,
    required this.photoService,
    required this.onPhotosSelected,
    required this.inspectionId,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Photos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onTap: () => _handleCameraCapture(context),
                  colorScheme: colorScheme,
                ),
                _buildOption(
                  context,
                  icon: Icons.image,
                  label: 'From Gallery',
                  onTap: () => _handleGalleryPick(context),
                  colorScheme: colorScheme,
                ),
                _buildOption(
                  context,
                  icon: Icons.collections,
                  label: 'Multiple Photos',
                  onTap: () => _handleMultiplePhotos(context),
                  colorScheme: colorScheme,
                ),
                _buildOption(
                  context,
                  icon: Icons.close,
                  label: 'Cancel',
                  onTap: () => Navigator.pop(context),
                  colorScheme: colorScheme,
                  isCancel: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isCancel = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isCancel
              ? Colors.red.withValues(alpha: 0.1)
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCancel
                ? Colors.red.withValues(alpha: 0.3)
                : colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isCancel ? Colors.red : colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCancel ? Colors.red : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCameraCapture(BuildContext context) async {
    // Close just the options dialog
    Navigator.of(context).pop();

    try {
      final photoFile = await photoService.capturePhoto();
      if (photoFile != null && context.mounted) {
        await _uploadAndNotify(parentContext, [photoFile]);
      }
    } catch (e) {
      _showErrorDialog(parentContext, 'Failed to capture photo: $e');
    }
  }

  Future<void> _handleGalleryPick(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      final photoFile = await photoService.pickPhotoFromGallery();
      if (photoFile != null && context.mounted) {
        await _uploadAndNotify(parentContext, [photoFile]);
      }
    } catch (e) {
      _showErrorDialog(parentContext, 'Failed to pick photo: $e');
    }
  }

  Future<void> _handleMultiplePhotos(BuildContext context) async {
    Navigator.of(context).pop();

    try {
      final photoFiles = await photoService.pickMultiplePhotos();
      if (photoFiles.isNotEmpty && context.mounted) {
        await _uploadAndNotify(parentContext, photoFiles);
      }
    } catch (e) {
      _showErrorDialog(parentContext, 'Failed to pick photos: $e');
    }
  }

  Future<void> _uploadAndNotify(
      BuildContext context, List<dynamic> photoFiles) async {
    _showLoadingDialog(
      context,
      message: 'Uploading photos...',
      showProgress: true,
    );

    try {
      // Cast dynamic list to File list
      final fileList = photoFiles.cast<File>();
      final uploadedUrls = await photoService.uploadMultiplePhotos(
        fileList,
        inspectionId: inspectionId,
        itemId: itemId,
      );

      try {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Close loading dialog
      } catch (_) {}
      onPhotosSelected(uploadedUrls);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${uploadedUrls.length} photo(s) uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      try {
        Navigator.of(context, rootNavigator: true)
            .pop(); // Ensure dialog closes
      } catch (_) {}
      _showErrorDialog(context, 'Failed to upload photos: $e');
    } finally {
      // Guarantee the loading dialog is closed even if something unexpected happens
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }
  }

  void _showLoadingDialog(
    BuildContext context, {
    String message = 'Processing...',
    bool showProgress = false,
  }) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
