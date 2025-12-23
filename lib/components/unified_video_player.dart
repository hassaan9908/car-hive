import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class UnifiedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? thumbnailUrl;
  final bool autoPlay;
  final bool looping;
  final double aspectRatio;
  final Duration? startPosition;

  const UnifiedVideoPlayer({
    super.key,
    required this.videoUrl,
    this.title,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    this.startPosition,
  });

  @override
  State<UnifiedVideoPlayer> createState() => _UnifiedVideoPlayerState();
}

enum _QualityOption { auto, p1080, p720, p480 }

class _UnifiedVideoPlayerState extends State<UnifiedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _resolvedUrl;
  bool _loading = true;
  String? _error;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  _QualityOption _quality = _QualityOption.auto;
  // Using Chewie's default speeds via controller configuration; no local list needed.

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant UnifiedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await _disposeControllers();
    try {
      final resolved =
          await _resolvePlayableUrlForQuality(widget.videoUrl, _quality);
      _resolvedUrl = resolved;

      final controller = VideoPlayerController.networkUrl(Uri.parse(resolved));
      await controller.initialize();
      await controller.setVolume(_volume);
      await controller.setPlaybackSpeed(_playbackSpeed);

      if (widget.startPosition != null) {
        await controller.seekTo(widget.startPosition!);
      }

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: widget.aspectRatio,
        allowMuting: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        showControls: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFFF9100),
          handleColor: const Color(0xFFFFB74D),
          backgroundColor: Colors.white12,
          bufferedColor: Colors.white24,
        ),
      );

      setState(() {
        _videoController = controller;
        _chewieController = chewie;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<String> _resolvePlayableUrlForQuality(
      String input, _QualityOption quality) async {
    final candidates = _candidateUrlsForQuality(input, quality);

    for (final url in candidates) {
      try {
        final res =
            await http.head(Uri.parse(url)).timeout(const Duration(seconds: 6));
        if (res.statusCode >= 200 && res.statusCode < 400) {
          return url;
        }
      } catch (_) {
        // Continue to next candidate
      }
    }

    // As a last resort, just return the input.
    return input;
  }

  List<String> _candidateUrlsForQuality(String url, _QualityOption quality) {
    // Normalize Cloudinary image->video resource path, if needed
    String normalized = url
        .replaceFirst('/image/upload/', '/video/upload/')
        .replaceAll(' ', '%20');

    if (!normalized.contains('/upload/')) {
      return [normalized];
    }

    final parts = normalized.split('/upload/');
    if (parts.length < 2) return [normalized];
    final prefix = '${parts[0]}/upload/';
    final suffix = parts.sublist(1).join('/upload/');

    if (quality == _QualityOption.auto) {
      final hls =
          prefix + 'sp_auto,f_auto,q_auto/' + _withExtension(suffix, 'm3u8');
      final mp4 = prefix + 'q_auto,f_mp4/' + _withExtension(suffix, 'mp4');
      return [hls, mp4, normalized];
    }

    // Build MP4 scaled variants
    final width = switch (quality) {
      _QualityOption.p1080 => 1920,
      _QualityOption.p720 => 1280,
      _QualityOption.p480 => 854,
      _ => 1280,
    };
    final mp4Scaled = prefix +
        'c_scale,w_$width,q_auto,f_mp4/' +
        _withExtension(suffix, 'mp4');
    // Try direct mp4 first then fallback to raw
    return [mp4Scaled, normalized];
  }

  String _withExtension(String pathAndQuery, String ext) {
    final idx = pathAndQuery.indexOf('?');
    final path = idx == -1 ? pathAndQuery : pathAndQuery.substring(0, idx);
    final query = idx == -1 ? '' : pathAndQuery.substring(idx);

    final dot = path.lastIndexOf('.');
    final base = dot == -1 ? path : path.substring(0, dot);
    return '$base.$ext$query';
  }

  Future<void> _disposeControllers() async {
    final chewie = _chewieController;
    final video = _videoController;
    _chewieController = null;
    _videoController = null;
    try {
      chewie?.dispose(); // ChewieController.dispose() is synchronous
    } catch (_) {}
    if (video != null) {
      try {
        await video.dispose(); // VideoPlayerController.dispose() returns Future
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // Skip forward/backward helper
  Future<void> _skip(Duration delta) async {
    final c = _videoController;
    if (c == null) return;
    final dur = c.value.duration;
    var target = c.value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    try {
      await c.seekTo(target);
    } catch (_) {}
  }

  // No standalone overlay buttons now; using unified bottom bar.

  // No custom speed/skip controls; rely on Chewie defaults.

  // Quality chip and switching removed per request.

  // Mini player removed per request.

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    // Auto-rotate to fullscreen: enter on landscape, exit on portrait
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final media = MediaQuery.of(context);
      if (_chewieController == null) return;
      final isLandscape = media.orientation == Orientation.landscape;
      final isFs = _chewieController!.isFullScreen;
      if (isLandscape && !isFs) {
        _chewieController!.enterFullScreen();
      } else if (!isLandscape && isFs) {
        _chewieController!.exitFullScreen();
      }
    });

    Widget buildBody() {
      if (_loading) {
        return const Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        );
      }
      if (_error != null) {
        return _ErrorView(
          error: _error!,
          url: _resolvedUrl ?? widget.videoUrl,
          onRetry: _initialize,
        );
      }
      if (_chewieController == null) {
        return const SizedBox.shrink();
      }

      final player = Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: Colors.white),
          // Avoid dialogTheme type mismatch across Flutter versions
        ),
        child: Chewie(controller: _chewieController!),
      );
      // Custom bottom controls bar combining skip and speed on same line
      return Stack(children: [
        Positioned.fill(child: player),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _UnifiedControlsBar(
            video: _videoController!,
            chewie: _chewieController!,
            getSpeed: () => _playbackSpeed,
            setSpeed: (s) async {
              setState(() => _playbackSpeed = s);
              try {
                await _videoController?.setPlaybackSpeed(s);
              } catch (_) {}
            },
            skip: _skip,
          ),
        ),
      ]);
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          color: const Color(0xFF0B0E14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.thumbnailUrl != null && _loading)
                Image.network(
                  widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                ),
              buildBody(),
              // Subtle border
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: radius,
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
}

// ---- Helpers ----

class _ErrorView extends StatelessWidget {
  final String error;
  final String url;
  final FutureOr<void> Function() onRetry;

  const _ErrorView({
    required this.error,
    required this.url,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_rounded,
                color: Colors.orangeAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              'Cannot play this video',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () => onRetry(),
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Best-effort open: use url_launcher if available at call site.
                    // Expose raw URL for now.
                    final snack = SnackBar(content: Text(url));
                    ScaffoldMessenger.of(context).showSnackBar(snack);
                  },
                  child: const Text('Copy URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom bottom controls bar that lives on the same line as
// volume, pause, time, settings, and fullscreen equivalents.
class _UnifiedControlsBar extends StatefulWidget {
  final VideoPlayerController video;
  final ChewieController chewie;
  final double Function() getSpeed;
  final Future<void> Function(double) setSpeed;
  final Future<void> Function(Duration) skip;

  const _UnifiedControlsBar({
    required this.video,
    required this.chewie,
    required this.getSpeed,
    required this.setSpeed,
    required this.skip,
  });

  @override
  State<_UnifiedControlsBar> createState() => _UnifiedControlsBarState();
}

class _UnifiedControlsBarState extends State<_UnifiedControlsBar> {
  late VoidCallback _listener;
  bool _muted = false;
  bool _visible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _muted = widget.video.value.volume == 0;
    _listener = () {
      if (!mounted) return;
      setState(() {});
    };
    widget.video.addListener(_listener);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.video.removeListener(_listener);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    setState(() => _visible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.video.value.isPlaying) {
        setState(() => _visible = false);
      }
    });
  }

  void _toggleVisibility() {
    if (_visible) {
      setState(() => _visible = false);
      _hideTimer?.cancel();
    } else {
      _startHideTimer();
    }
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video.value;
    final position = v.position;
    final duration =
        v.duration == Duration.zero ? const Duration(seconds: 1) : v.duration;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleVisibility,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Container(
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 6, top: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x88000000)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar on top
                GestureDetector(
                  onTapDown: (_) => _startHideTimer(),
                  child: VideoProgressIndicator(
                    widget.video,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFFFF9100),
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
                const SizedBox(height: 6),
                // Single line of controls
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          v.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white),
                      onPressed: () {
                        v.isPlaying
                            ? widget.video.pause()
                            : widget.video.play();
                        _startHideTimer();
                      },
                    ),
                    IconButton(
                      icon: Icon(
                          _muted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white),
                      onPressed: () async {
                        _muted = !_muted;
                        await widget.video.setVolume(_muted ? 0 : 1);
                        setState(() {});
                        _startHideTimer();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () {
                        widget.skip(const Duration(seconds: -10));
                        _startHideTimer();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () {
                        widget.skip(const Duration(seconds: 10));
                        _startHideTimer();
                      },
                    ),

                    const SizedBox(width: 8),
                    Text('${_format(position)} / ${_format(duration)}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),

                    const Spacer(),

                    // Speed selector, compact
                    PopupMenuButton<double>(
                      tooltip: 'Speed',
                      initialValue: widget.getSpeed(),
                      color: const Color(0xFF111111),
                      itemBuilder: (context) =>
                          const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
                              .map((s) => PopupMenuItem<double>(
                                    value: s,
                                    child: Text('${s}x',
                                        style: TextStyle(color: Colors.white)),
                                  ))
                              .toList(),
                      onSelected: (s) {
                        widget.setSpeed(s);
                        _startHideTimer();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text('${widget.getSpeed()}x',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        widget.chewie.isFullScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (widget.chewie.isFullScreen) {
                          widget.chewie.exitFullScreen();
                        } else {
                          widget.chewie.enterFullScreen();
                        }
                        _startHideTimer();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}