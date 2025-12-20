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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified player at top with consistent look & feel
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: UnifiedVideoPlayer(
              videoUrl: widget.video.videoUrl,
              title: widget.video.title,
              thumbnailUrl: widget.video.thumbnailUrl,
              autoPlay: true,
              looping: false,
              aspectRatio: 16 / 9,
            ),
          ),

          // Video information
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.video.description.isNotEmpty)
                    Text(
                      widget.video.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
