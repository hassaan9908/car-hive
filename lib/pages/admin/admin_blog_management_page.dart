import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blog_model.dart';
import '../../providers/content_provider.dart';

class AdminBlogManagementPage extends StatefulWidget {
  const AdminBlogManagementPage({super.key});

  @override
  State<AdminBlogManagementPage> createState() => _AdminBlogManagementPageState();
}

class _AdminBlogManagementPageState extends State<AdminBlogManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogs();
    });
  }

  Future<void> _loadBlogs() async {
    final contentProvider = context.read<ContentProvider>();
    await contentProvider.loadAllBlogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Blogs'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, contentProvider, child) {
          if (contentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error message if there is one
          if (contentProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    contentProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBlogs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final blogs = contentProvider.blogs;

          if (blogs.isEmpty) {
            return const Center(
              child: Text('No blogs found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blog.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blog.author,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blog.content.length > 100
                            ? '${blog.content.substring(0, 100)}...'
                            : blog.content,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            blog.createdAt != null
                                ? 'Created: ${blog.createdAt!.toString().split(' ').first}'
                                : 'Date unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _confirmDeleteBlog(blog);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteBlog(BlogModel blog) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Blog'),
          content: Text('Are you sure you want to delete "${blog.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBlog(blog.id!);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBlog(String blogId) async {
    final contentProvider = context.read<ContentProvider>();
    final success = await contentProvider.deleteBlog(blogId);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blog deleted successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete blog')),
        );
      }
    }
  }
}