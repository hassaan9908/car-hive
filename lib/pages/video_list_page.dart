import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import '../providers/content_provider.dart';
import 'video_detail_page.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    final contentProvider = context.read<ContentProvider>();
    await contentProvider.loadAllVideos();
  }

  List<dynamic> _getFilteredVideos(List<dynamic> videos) {
    if (_searchQuery.isEmpty) return videos;
    return videos.where((video) {
      final titleMatch =
          video.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final descMatch =
          video.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final authorMatch =
          video.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final tagMatch = video.tags != null &&
          (video.tags as List).any((tag) => tag
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()));
      return titleMatch || descMatch || authorMatch || tagMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      backgroundColor:
          isDark ? const Color(0xFF0D1117) : const Color(0xFFFAFAFA),
      body: Consumer<ContentProvider>(
        builder: (context, contentProvider, child) {
          if (contentProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (contentProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    contentProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadVideos,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final videos = contentProvider.videos;

          if (videos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined,
                      size: 64,
                      color: colorScheme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No videos available',
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          final filteredVideos = _getFilteredVideos(videos);

          return CustomScrollView(
            slivers: [
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search videos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF161B22) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              if (filteredVideos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 56,
                            color: colorScheme.primary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No videos match your search',
                            style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final video = filteredVideos[index];
                        final computedThumb = (video.thumbnailUrl != null &&
                                video.thumbnailUrl!.isNotEmpty)
                            ? video.thumbnailUrl!
                            : CloudinaryService().buildVideoThumbnailUrl(
                                video.videoUrl,
                                second: 1);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VideoDetailPage(video: video),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161B22)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.3 : 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail with play icon
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                        child: Image.network(
                                          computedThumb,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(16)),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.video_library,
                                                  size: 56,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Gradient overlay + play button
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black26,
                                              ],
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Video details
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          video.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: colorScheme.onSurface,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),

                                        // Author + Date row
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: 14,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                video.author,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (video.createdAt != null) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 13,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                video.createdAt!
                                                    .toString()
                                                    .split(' ')
                                                    .first,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // Tags if available
                                        if (video.tags != null &&
                                            video.tags!.isNotEmpty) ...[
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: List<Widget>.from(
                                              video.tags!.take(3).map((tag) {
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary
                                                        .withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    tag,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],

                                        // Description
                                        Text(
                                          video.description.length > 100
                                              ? '${video.description.substring(0, 100)}...'
                                              : video.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.75),
                                            height: 1.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredVideos.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
