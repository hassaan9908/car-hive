import 'package:flutter/material.dart';
import '../components/unified_video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: UnifiedVideoPlayer(
            videoUrl: widget.videoUrl,
            title: widget.title,
            autoPlay: true,
            aspectRatio: 16 / 9,
          ),
        ),
      ),
    );
  }
}
