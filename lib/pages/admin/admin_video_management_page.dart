import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/video_model.dart';
import '../../providers/content_provider.dart';

class AdminVideoManagementPage extends StatefulWidget {
  const AdminVideoManagementPage({super.key});

  @override
  State<AdminVideoManagementPage> createState() =>
      _AdminVideoManagementPageState();
}

class _AdminVideoManagementPageState extends State<AdminVideoManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, oldest, title
  bool _selectionMode = false;
  final Set<String> _selectedVideoIds = <String>{};
  bool _isLoading = false;

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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unknown';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Today';
    }
  }

  List<VideoModel> _applyFilters(List<VideoModel> videos) {
    var filtered = videos.where((video) {
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              video.author.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return a.createdAt?.compareTo(b.createdAt ?? DateTime.now()) ?? 0;
        case 'title':
          return a.title.compareTo(b.title);
        case 'newest':
        default:
          return b.createdAt?.compareTo(a.createdAt ?? DateTime.now()) ?? 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFFF48C25);
    final cardGradient = LinearGradient(
      colors: isDark
          ? [const Color(0xFF111827), const Color(0xFF0B1220)]
          : [Colors.grey.shade100, Colors.grey.shade200],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final borderColor =
        isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade400;
    final pageBackground = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0B1220), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Manage Videos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: pageBackground),
        child: Consumer<ContentProvider>(
          builder: (context, contentProvider, child) {
            if (contentProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (contentProvider.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      contentProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade400),
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
            final filtered = _applyFilters(videos);

            if (videos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 64,
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No videos found',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildSearchAndFilters(
                    cardGradient, borderColor, isDark, accent),
                if (_selectionMode)
                  _buildBulkActionsBar(
                      cardGradient, borderColor, isDark, accent),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No videos match your search',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final video = filtered[index];
                            final isSelected =
                                _selectedVideoIds.contains(video.id);
                            return _buildVideoCard(
                              video,
                              isSelected,
                              cardGradient,
                              borderColor,
                              isDark,
                              accent,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(LinearGradient cardGradient, Color borderColor,
      bool isDark, Color accent) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search videos by title or author...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close,
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600,
                            size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                filled: false,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
        // Filters and Sort
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accent, width: 1.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'title', child: Text('Title')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Divider(
          thickness: 0.8,
          height: 1,
          indent: 20,
          endIndent: 20,
        ),
      ],
    );
  }

  Widget _buildBulkActionsBar(LinearGradient cardGradient, Color borderColor,
      bool isDark, Color accent) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedVideoIds.length} selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedVideoIds.isEmpty ? null : _bulkDelete,
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
      VideoModel video,
      bool isSelected,
      LinearGradient cardGradient,
      Color borderColor,
      bool isDark,
      Color accent) {
    final descriptionPreview = video.description.length > 120
        ? '${video.description.substring(0, 120)}...'
        : video.description;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _selectionMode = true;
          _selectedVideoIds.add(video.id!);
        });
      },
      onTap: _selectionMode
          ? () {
              setState(() {
                if (_selectedVideoIds.contains(video.id)) {
                  _selectedVideoIds.remove(video.id);
                } else {
                  _selectedVideoIds.add(video.id!);
                }
                if (_selectedVideoIds.isEmpty) _selectionMode = false;
              });
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent.withOpacity(0.4) : borderColor,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: accent.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (video.thumbnailUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      video.thumbnailUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Play icon overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 56,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                  // Selection checkbox
                  if (_selectionMode)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedVideoIds.add(video.id!);
                              } else {
                                _selectedVideoIds.remove(video.id);
                                if (_selectedVideoIds.isEmpty)
                                  _selectionMode = false;
                              }
                            });
                          },
                          fillColor: MaterialStateProperty.resolveWith(
                            (states) => isSelected
                                ? accent
                                : Colors.white.withOpacity(0.4),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? accent
                                : Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Author and metadata
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        video.author,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time,
                          size: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(video.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Description preview
                  Text(
                    descriptionPreview,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? Colors.white.withOpacity(0.75)
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Tags
                  if (video.tags?.isNotEmpty ?? false)
                    SizedBox(
                      height: 24,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: video.tags?.length ?? 0,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            video.tags?[i] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.8)
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Action buttons
                  if (!_selectionMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDeleteVideo(video);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      size: 18, color: Colors.red.shade400),
                                  const SizedBox(width: 12),
                                  const Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(Icons.more_vert,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.grey.shade600),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteVideo(VideoModel video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: Text('Are you sure you want to delete "${video.title}"?'),
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
                _deleteVideo(video.id!);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bulkDelete() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Videos'),
          content: Text(
              'Are you sure you want to delete ${_selectedVideoIds.length} video(s)?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isLoading = true);
                final contentProvider = context.read<ContentProvider>();
                for (final id in _selectedVideoIds) {
                  await contentProvider.deleteVideo(id);
                }
                setState(() {
                  _isLoading = false;
                  _selectionMode = false;
                  _selectedVideoIds.clear();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Videos deleted successfully!')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideo(String videoId) async {
    final contentProvider = context.read<ContentProvider>();
    final success = await contentProvider.deleteVideo(videoId);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete video')),
        );
      }
    }
  }
}
