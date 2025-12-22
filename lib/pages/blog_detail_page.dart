import 'package:flutter/material.dart';
import '../models/blog_model.dart';

class BlogDetailPage extends StatelessWidget {
  final BlogModel blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(blog.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image
            if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
              Image.network(
                blog.imageUrl!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 250,
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    blog.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Author & Date Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.author,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (blog.createdAt != null)
                              Text(
                                _formatDate(blog.createdAt!),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Tags
                  if (blog.tags != null && blog.tags!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: blog.tags!.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Divider
                  Divider(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    thickness: 1,
                  ),

                  const SizedBox(height: 24),

                  // Content
                  Text(
                    blog.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: colorScheme.onSurface.withValues(alpha: 0.9),
                      letterSpacing: 0.3,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
