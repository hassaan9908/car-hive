import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';
import '../services/cloudinary_service.dart';
import '../providers/content_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({super.key});

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  File? _videoFile;
  Uint8List? _webVideoBytes;
  String? _videoThumbnailUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final pickedVideo = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (pickedVideo != null) {
        setState(() {
          if (kIsWeb) {
            pickedVideo.readAsBytes().then((value) {
              setState(() {
                _webVideoBytes = value;
                _videoFile = null;
              });
            });
          } else {
            _videoFile = File(pickedVideo.path);
            _webVideoBytes = null;
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick video: $e';
      });
    }
  }

  Future<void> _uploadVideo() async {
    if (_formKey.currentState!.validate()) {
      if ((_videoFile == null && _webVideoBytes == null)) {
        setState(() {
          _errorMessage = 'Please select a video first';
        });
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _errorMessage = null;
      });

      try {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User not authenticated');
        }

        // Upload video to Cloudinary
        String videoUrl = '';
        
        if (kIsWeb && _webVideoBytes != null) {
          videoUrl = await _cloudinaryService.uploadVideoBytes(
            videoBytes: _webVideoBytes!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        } else if (!kIsWeb && _videoFile != null) {
          videoUrl = await _cloudinaryService.uploadVideo(
            videoFile: _videoFile!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
        }

        // Parse tags
        List<String> tags = [];
        if (_tagsController.text.isNotEmpty) {
          tags = _tagsController.text.split(',').map((tag) => tag.trim()).toList();
        }

        // Get user info
        String userName = user.displayName ?? user.email ?? 'Unknown User';
        
        // Create video model
        final video = VideoModel(
          title: _titleController.text,
          description: _descriptionController.text,
          author: userName,
          authorId: user.uid,
          videoUrl: videoUrl,
          thumbnailUrl: _videoThumbnailUrl,
          tags: tags.isNotEmpty ? tags : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Upload video metadata to Firestore
        final contentProvider = context.read<ContentProvider>();
        final success = await contentProvider.uploadVideo(video);
        
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video uploaded successfully!')),
            );
            
            // Clear form
            _titleController.clear();
            _descriptionController.clear();
            _tagsController.clear();
            setState(() {
              _videoFile = null;
              _webVideoBytes = null;
              _videoThumbnailUrl = null;
            });
            
            // Navigate back
            Navigator.of(context).pop();
          }
        } else {
          if (mounted) {
            final errorMessage = contentProvider.errorMessage ?? 'Failed to upload video metadata';
            setState(() {
              _errorMessage = errorMessage;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error uploading video: $e';
          });
        }
      } finally {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
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
                  labelText: 'Video Title',
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
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
                  helperText: 'Example: tutorial, car, maintenance',
                ),
              ),
              const SizedBox(height: 16),
              // Video picker section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Select Video',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_videoFile != null || _webVideoBytes != null)
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            size: 48,
                            color: Colors.blue,
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.video_library,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Pick Video from Gallery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    if (_videoFile != null || _webVideoBytes != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Video selected'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_isUploading)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text('Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadVideo,
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
                      : const Text('Upload Video'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}