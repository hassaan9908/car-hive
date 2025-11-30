import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/video_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/content_provider.dart';
import '../../services/cloudinary_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminVideoUploadPage extends StatefulWidget {
  const AdminVideoUploadPage({super.key});

  @override
  State<AdminVideoUploadPage> createState() => _AdminVideoUploadPageState();
}

class _AdminVideoUploadPageState extends State<AdminVideoUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _videoFile;
  Uint8List? _webVideoBytes;
  File? _thumbnailFile;
  Uint8List? _webThumbnailBytes;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final pickedVideo =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
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
        });
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
        setState(() {
          if (kIsWeb) {
            pickedImage.readAsBytes().then((value) {
              setState(() {
                _webThumbnailBytes = value;
                _thumbnailFile = null;
              });
            });
          } else {
            _thumbnailFile = File(pickedImage.path);
            _webThumbnailBytes = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick thumbnail: $e')),
        );
      }
    }
  }

  Future<void> _uploadVideoFromDevice() async {
    if (_formKey.currentState!.validate()) {
      if ((_videoFile == null && _webVideoBytes == null)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a video first')),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        // Upload video to Cloudinary
        String videoUrl = '';

        if (kIsWeb && _webVideoBytes != null) {
          videoUrl = await _cloudinaryService.uploadVideoBytes(
            videoBytes: _webVideoBytes!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress * 0.7; // 70% for video
              });
            },
          );
        } else if (!kIsWeb && _videoFile != null) {
          videoUrl = await _cloudinaryService.uploadVideo(
            videoFile: _videoFile!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress * 0.7; // 70% for video
              });
            },
          );
        }

        // Upload thumbnail to Cloudinary if selected
        String? thumbnailUrl;
        if (_thumbnailFile != null || _webThumbnailBytes != null) {
          if (kIsWeb && _webThumbnailBytes != null) {
            thumbnailUrl = await _cloudinaryService.uploadImageBytes(
              imageBytes: _webThumbnailBytes!,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = 0.7 + (progress * 0.3); // 30% for thumbnail
                });
              },
            );
          } else if (!kIsWeb && _thumbnailFile != null) {
            thumbnailUrl = await _cloudinaryService.uploadImage(
              imageFile: _thumbnailFile!,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = 0.7 + (progress * 0.3); // 30% for thumbnail
                });
              },
            );
          }
        }

        // Proceed with saving video metadata
        await _saveVideoMetadata(videoUrl, thumbnailUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading video: $e')),
          );
        }
      } finally {
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

      // Get current admin info
      final admin = adminProvider.currentAdmin;
      if (admin == null) {
        throw Exception('Admin not found');
      }

      // Parse tags
      List<String> tags = [];
      if (_tagsController.text.isNotEmpty) {
        tags =
            _tagsController.text.split(',').map((tag) => tag.trim()).toList();
      }

      // Create video model
      final video = VideoModel(
        title: _titleController.text,
        description: _descriptionController.text,
        author: admin.displayName ?? admin.email ?? 'Unknown',
        authorId: admin.id,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Upload video
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
            _thumbnailFile = null;
            _webThumbnailBytes = null;
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
    if (_formKey.currentState!.validate()) {
      // Video file must be selected
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Video'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                        'Select Video from Device',
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
                      if (_isUploading)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            LinearProgressIndicator(value: _uploadProgress),
                            const SizedBox(height: 8),
                            Text(
                                'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Thumbnail picker section
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
                        'Select Thumbnail (optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_thumbnailFile != null || _webThumbnailBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb && _webThumbnailBytes != null
                              ? Image.memory(
                                  _webThumbnailBytes!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : (!kIsWeb && _thumbnailFile != null)
                                  ? Image.file(
                                      _thumbnailFile!,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                        )
                      else
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickThumbnail,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Thumbnail from Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_thumbnailFile != null || _webThumbnailBytes != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('Thumbnail selected'),
                        ),
                    ],
                  ),
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
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              SizedBox(width: 16),
                              Text('Uploading...'),
                            ],
                          )
                        : const Text('Upload Video'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
