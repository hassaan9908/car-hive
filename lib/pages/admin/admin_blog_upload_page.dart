import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blog_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/content_provider.dart';

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
  
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submitBlog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        final adminProvider = context.read<AdminProvider>();
        final contentProvider = context.read<ContentProvider>();
        
        // Get current admin info
        final admin = adminProvider.currentAdmin;
        if (admin == null) {
          throw Exception('Admin not found');
        }

        // Parse tags
        List<String> tags = [];
        if (_tagsController.text.isNotEmpty) {
          tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
        }

        // Create blog model
        final blog = BlogModel(
          title: _titleController.text,
          content: _contentController.text,
          author: admin.displayName ?? admin.email ?? 'Unknown',
          authorId: admin.id,
          tags: tags,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Upload blog
        final success = await contentProvider.uploadBlog(blog);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Blog uploaded successfully!')),
            );
            
            // Clear form
            _titleController.clear();
            _contentController.clear();
            _tagsController.clear();
          }
        } else {
          if (mounted) {
            final errorMessage = contentProvider.errorMessage ?? 'Failed to upload blog';
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
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Blog'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Blog Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Blog Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter blog content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                  helperText: 'Example: car, maintenance, tips',
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitBlog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            SizedBox(width: 16),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Blog'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}