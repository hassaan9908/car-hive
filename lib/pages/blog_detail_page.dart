import 'package:flutter/material.dart';
import '../models/blog_model.dart';

class BlogDetailPage extends StatelessWidget {
  final BlogModel blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(blog.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blog.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By ${blog.author}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            if (blog.createdAt != null)
              Text(
                'Published: ${blog.createdAt!.toString().split(' ').first}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 24),
            if (blog.tags != null && blog.tags!.isNotEmpty)
              Wrap(
                spacing: 8,
                children: blog.tags!.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue.shade100,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            Text(
              blog.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}