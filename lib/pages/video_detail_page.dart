import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../components/unified_video_player.dart';

class VideoDetailPage extends StatefulWidget {
  final VideoModel video;

  const VideoDetailPage({super.key, required this.video});

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor:
            isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: CustomScrollView(
        slivers: [
          // Player section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UnifiedVideoPlayer(
                videoUrl: widget.video.videoUrl,
                title: widget.video.title,
                thumbnailUrl: widget.video.thumbnailUrl,
                autoPlay: true,
                looping: false,
                aspectRatio: 16 / 9,
              ),
            ),
          ),

          // Info section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.video.title,
                      style: TextStyle(
                        fontSize: 24,
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
                                widget.video.author,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (widget.video.createdAt != null)
                                Text(
                                  _formatDate(widget.video.createdAt!),
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

                    const SizedBox(height: 20),

                    // Divider
                    Divider(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      thickness: 1,
                    ),

                    const SizedBox(height: 20),

                    // Description
                    if (widget.video.description.isNotEmpty)
                      Text(
                        widget.video.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                          letterSpacing: 0.3,
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
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
