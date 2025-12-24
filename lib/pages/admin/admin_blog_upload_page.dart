import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/blog_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/content_provider.dart';
import '../../services/cloudinary_service.dart';

class AdminBlogUploadPage extends StatefulWidget {
  const AdminBlogUploadPage({super.key});

  @override
  State<AdminBlogUploadPage> createState() => _AdminBlogUploadPageState();
}

class _AdminBlogUploadPageState extends State<AdminBlogUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  bool _showTitleError = false;
  bool _showContentError = false;
  List<String> _selectedTags = [];

  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _submitBlog() async {
    setState(() {
      _showTitleError = _titleController.text.isEmpty;
      _showContentError = _contentController.text.isEmpty;
    });

    if (_formKey.currentState!.validate() &&
        !_showTitleError &&
        !_showContentError) {
      setState(() {
        _isUploading = true;
      });

      try {
        final adminProvider = context.read<AdminProvider>();
        final contentProvider = context.read<ContentProvider>();

        final admin = adminProvider.currentAdmin;
        if (admin == null) {
          throw Exception('Admin not found');
        }

        // Upload featured image if selected
        String? featuredImageUrl;
        if (_selectedImage != null || _selectedImageBytes != null) {
          try {
            if (kIsWeb && _selectedImageBytes != null) {
              featuredImageUrl = await _cloudinaryService.uploadImageBytes(
                imageBytes: _selectedImageBytes!,
              );
            } else if (!kIsWeb && _selectedImage != null) {
              featuredImageUrl = await _cloudinaryService.uploadImage(
                imageFile: _selectedImage!,
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error uploading featured image: $e')),
              );
            }
          }
        }

        final blog = BlogModel(
          title: _titleController.text,
          content: _contentController.text,
          author: admin.displayName ?? admin.email ?? 'Unknown',
          authorId: admin.id,
          tags: _selectedTags.isNotEmpty ? _selectedTags : null,
          imageUrl: featuredImageUrl,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final success = await contentProvider.uploadBlog(blog);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Blog uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          _titleController.clear();
          _contentController.clear();
          _tagsController.clear();
          setState(() {
            _selectedImage = null;
            _selectedImageBytes = null;
            _selectedTags.clear();
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        } else if (mounted) {
          final errorMessage =
              contentProvider.errorMessage ?? 'Failed to upload blog';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('✗ $errorMessage'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✗ Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFFf48c25);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Upload Blog',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? accentColor : Colors.black),
        titleTextStyle: TextStyle(
          color: isDark ? accentColor : Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input Card
              _buildFormCard(
                title: 'Blog Title',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() => _showTitleError = false),
                      maxLength: 100,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter an engaging blog title',
                        prefixIcon:
                            Icon(Icons.title, color: accentColor, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _showTitleError
                                ? Colors.red
                                : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _showTitleError
                                ? Colors.red
                                : (isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: accentColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        counterStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    if (_showTitleError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Title is required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content Input Card
              _buildFormCard(
                title: 'Blog Content',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      onChanged: (_) =>
                          setState(() => _showContentError = false),
                      maxLines: 12,
                      maxLength: 5000,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Write your detailed blog content here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _showContentError
                                ? Colors.red
                                : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                            width: 1.2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _showContentError
                                ? Colors.red
                                : (isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300),
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: accentColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        counterStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                    if (_showContentError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Content is required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Featured Image Card
              _buildFormCard(
                title: 'Featured Image (Optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: accentColor.withOpacity(0.08),
                        ),
                        child: _selectedImage != null ||
                                _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb && _selectedImageBytes != null
                                    ? Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined,
                                      size: 48, color: accentColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap to select featured image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Image selected',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedImage = null),
                              style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero),
                              child: Text(
                                'Remove',
                                style:
                                    TextStyle(color: accentColor, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tags Card
              _buildFormCard(
                title: 'Tags (Optional)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagsController,
                            onSubmitted: (value) => _addTag(value),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Add tag and press enter',
                              prefixIcon: Icon(Icons.label_outline,
                                  color: accentColor, size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: accentColor, width: 1.5),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => _addTag(_tagsController.text),
                            icon: const Icon(Icons.add, color: Colors.white),
                            constraints: const BoxConstraints(
                                minWidth: 44, minHeight: 44),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedTags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accentColor.withOpacity(0.15),
                                  accentColor.withOpacity(0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: accentColor.withOpacity(0.4),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _removeTag(tag),
                                  child: Icon(Icons.close,
                                      color: accentColor, size: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, const Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitBlog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Uploading blog...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              const Text(
                                'Publish Blog',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
