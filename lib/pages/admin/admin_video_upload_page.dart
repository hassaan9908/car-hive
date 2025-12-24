import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/video_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/content_provider.dart';
import '../../services/cloudinary_service.dart';

class AdminVideoUploadPage extends StatefulWidget {
  const AdminVideoUploadPage({super.key});

  @override
  State<AdminVideoUploadPage> createState() => _AdminVideoUploadPageState();
}

class _AdminVideoUploadPageState extends State<AdminVideoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagInputController = TextEditingController();

  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _videoFile;
  Uint8List? _webVideoBytes;
  String? _videoName;
  int? _videoBytesLength;

  File? _thumbnailFile;
  Uint8List? _webThumbnailBytes;
  String? _thumbnailName;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  bool _showTitleError = false;
  bool _showDescriptionError = false;
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    final precision = size < 10 ? 2 : 1;
    return '${size.toStringAsFixed(precision)} ${suffixes[i]}';
  }

  Future<void> _pickVideo() async {
    try {
      final pickedVideo =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        if (kIsWeb) {
          final bytes = await pickedVideo.readAsBytes();
          setState(() {
            _webVideoBytes = bytes;
            _videoBytesLength = bytes.lengthInBytes;
            _videoFile = null;
            _videoName = pickedVideo.name;
          });
        } else {
          final file = File(pickedVideo.path);
          setState(() {
            _videoFile = file;
            _webVideoBytes = null;
            _videoBytesLength = file.lengthSync();
            _videoName = pickedVideo.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: $e')),
        );
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        if (kIsWeb) {
          final bytes = await pickedImage.readAsBytes();
          setState(() {
            _webThumbnailBytes = bytes;
            _thumbnailFile = null;
            _thumbnailName = pickedImage.name;
          });
        } else {
          final file = File(pickedImage.path);
          setState(() {
            _thumbnailFile = file;
            _webThumbnailBytes = null;
            _thumbnailName = pickedImage.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick thumbnail: $e')),
        );
      }
    }
  }

  void _clearVideoSelection() {
    setState(() {
      _videoFile = null;
      _webVideoBytes = null;
      _videoName = null;
      _videoBytesLength = null;
    });
  }

  void _clearThumbnailSelection() {
    setState(() {
      _thumbnailFile = null;
      _webThumbnailBytes = null;
      _thumbnailName = null;
    });
  }

  void _addTag(String tag) {
    final cleaned = tag.trim();
    if (cleaned.isEmpty) return;
    if (_selectedTags.contains(cleaned.toLowerCase())) return;
    setState(() {
      _selectedTags.add(cleaned.toLowerCase());
      _tagInputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _uploadVideoFromDevice() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      String videoUrl = '';

      if (kIsWeb && _webVideoBytes != null) {
        videoUrl = await _cloudinaryService.uploadVideoBytes(
          videoBytes: _webVideoBytes!,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress * 0.7;
            });
          },
        );
      } else if (!kIsWeb && _videoFile != null) {
        videoUrl = await _cloudinaryService.uploadVideo(
          videoFile: _videoFile!,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = progress * 0.7;
            });
          },
        );
      }

      String? thumbnailUrl;
      if (_thumbnailFile != null || _webThumbnailBytes != null) {
        if (kIsWeb && _webThumbnailBytes != null) {
          thumbnailUrl = await _cloudinaryService.uploadImageBytes(
            imageBytes: _webThumbnailBytes!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = 0.7 + (progress * 0.3);
              });
            },
          );
        } else if (!kIsWeb && _thumbnailFile != null) {
          thumbnailUrl = await _cloudinaryService.uploadImage(
            imageFile: _thumbnailFile!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = 0.7 + (progress * 0.3);
              });
            },
          );
        }
      }

      thumbnailUrl ??= _cloudinaryService.buildVideoThumbnailUrl(
        videoUrl,
        second: 1,
      );

      await _saveVideoMetadata(videoUrl, thumbnailUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<void> _saveVideoMetadata(String videoUrl, String? thumbnailUrl) async {
    try {
      final adminProvider = context.read<AdminProvider>();
      final contentProvider = context.read<ContentProvider>();

      final admin = adminProvider.currentAdmin;
      if (admin == null) {
        throw Exception('Admin not found');
      }

      final authorName =
          (admin.displayName != null && admin.displayName!.isNotEmpty)
              ? admin.displayName!
              : admin.email;

      final video = VideoModel(
        title: _titleController.text,
        description: _descriptionController.text,
        author: authorName,
        authorId: admin.id,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        tags: List<String>.from(_selectedTags),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await contentProvider.uploadVideo(video);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video uploaded successfully!')),
          );

          _titleController.clear();
          _descriptionController.clear();
          _tagInputController.clear();
          setState(() {
            _selectedTags.clear();
            _videoFile = null;
            _webVideoBytes = null;
            _videoName = null;
            _videoBytesLength = null;
            _thumbnailFile = null;
            _webThumbnailBytes = null;
            _thumbnailName = null;
          });
        }
      } else {
        if (mounted) {
          final errorMessage =
              contentProvider.errorMessage ?? 'Failed to upload video';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _submitVideo() async {
    setState(() {
      _showTitleError = _titleController.text.trim().isEmpty;
      _showDescriptionError = _descriptionController.text.trim().isEmpty;
    });

    if (_formKey.currentState!.validate()) {
      if (_videoFile != null || _webVideoBytes != null) {
        await _uploadVideoFromDevice();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video file')),
          );
        }
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    bool showError = false,
  }) {
    final accent = const Color(0xFFF48C25);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseFill =
        isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50;
    final labelColor = showError
        ? Colors.red.shade300
        : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1F2937));
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: accent),
      filled: true,
      fillColor: baseFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.4),
      ),
      errorStyle: TextStyle(color: Colors.red.shade300),
      labelStyle: TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildFormCard(
      {required String label, Widget? subtitle, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            subtitle,
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildUploadArea({
    required VoidCallback onPick,
    required IconData icon,
    required String label,
    String? name,
    String? sizeLabel,
    VoidCallback? onRemove,
  }) {
    final accent = const Color(0xFFF48C25);
    final isSelected = name != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBorder =
        isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300;
    final titleColor =
        isDark ? Colors.white.withOpacity(0.86) : const Color(0xFF1F2937);
    final surface =
        isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50;
    final chipTextColor =
        isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1F2937);
    final chipMetaColor =
        isDark ? Colors.white.withOpacity(0.7) : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isUploading ? null : onPick,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? accent.withOpacity(0.6) : baseBorder,
                width: isSelected ? 1.6 : 1.1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 42,
                    color: isSelected
                        ? accent
                        : (isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600)),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          name!,
                          style: TextStyle(
                            color: chipTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sizeLabel != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            sizeLabel,
                            style: TextStyle(
                              color: chipMetaColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                label: 'Pick from Gallery',
                icon: Icons.folder_open,
                onPressed: _isUploading ? null : onPick,
              ),
            ),
            if (isSelected && onRemove != null) ...[
              const SizedBox(width: 12),
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.white.withOpacity(0.9)
                        : const Color(0xFF1F2937),
                    side: BorderSide(
                        color: isDark
                            ? Colors.white.withOpacity(0.25)
                            : Colors.grey.shade300),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final accent = const Color(0xFFF48C25);
    return SizedBox(
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, const Color(0xFFFFB56B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, size: 18),
          label: Text(
            loading ? 'Processing' : label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChips() {
    if (_selectedTags.isEmpty) {
      return Text(
        'No tags added yet',
        style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.6)
                : Colors.grey.shade600),
      );
    }

    final accent = const Color(0xFFF48C25);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1F2937);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedTags
          .map(
            (tag) => Chip(
              backgroundColor: accent.withOpacity(isDark ? 0.14 : 0.18),
              label: Text(
                tag,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              deleteIcon: Icon(Icons.close,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF1F2937)),
              onDeleted: _isUploading ? null : () => _removeTag(tag),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFFF48C25);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormCard(
                label: 'Video Title',
                child: TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    label: 'Video Title',
                    hint: 'Enter an engaging title',
                    icon: Icons.movie_outlined,
                    showError: _showTitleError,
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              _buildFormCard(
                label: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(
                    label: 'Description',
                    hint: 'Describe the video content...',
                    icon: Icons.description_outlined,
                    showError: _showDescriptionError,
                  ),
                  maxLines: 6,
                  maxLength: 5000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ),
              _buildFormCard(
                label: 'Video File',
                subtitle: Text(
                  'MP4 or MOV up to 500MB. A preview frame will auto-generate if no thumbnail is provided.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUploadArea(
                      onPick: _pickVideo,
                      icon: Icons.video_library_outlined,
                      label: 'Select video from your device',
                      name: _videoName,
                      sizeLabel: _videoBytesLength != null
                          ? _formatBytes(_videoBytesLength!)
                          : null,
                      onRemove: _clearVideoSelection,
                    ),
                    if (_isUploading) ...[
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ],
                ),
              ),
              _buildFormCard(
                label: 'Thumbnail (optional)',
                subtitle: Text(
                  'Upload a custom thumbnail or we will grab a frame from the video.',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUploadArea(
                      onPick: _pickThumbnail,
                      icon: Icons.image_outlined,
                      label: 'Add a custom thumbnail',
                      name: _thumbnailName,
                      onRemove: _clearThumbnailSelection,
                    ),
                    const SizedBox(height: 12),
                    if (_thumbnailFile != null || _webThumbnailBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb && _webThumbnailBytes != null
                            ? Image.memory(
                                _webThumbnailBytes!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : (!kIsWeb && _thumbnailFile != null)
                                ? Image.file(
                                    _thumbnailFile!,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              _buildFormCard(
                label: 'Tags',
                subtitle: Text(
                  'Add tags to improve discovery (press Enter to add).',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagInputController,
                            onSubmitted: _isUploading ? null : _addTag,
                            decoration: InputDecoration(
                              hintText: 'e.g. tutorial, maintenance',
                              prefixIcon: Icon(Icons.tag, color: accent),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.08)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: accent, width: 1.6),
                              ),
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: _buildPrimaryButton(
                            label: 'Add',
                            icon: Icons.add,
                            onPressed: _isUploading
                                ? null
                                : () => _addTag(_tagInputController.text),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTagChips(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildPrimaryButton(
                label: _isUploading ? 'Uploading...' : 'Upload Video',
                icon: Icons.cloud_upload_outlined,
                onPressed: _isUploading ? null : _submitVideo,
                loading: _isUploading,
              ),
              const SizedBox(height: 12),
              Text(
                'Make sure your video respects content guidelines before publishing.',
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withOpacity(0.65)
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
