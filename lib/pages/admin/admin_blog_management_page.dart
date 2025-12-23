import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/blog_model.dart';
import '../../providers/content_provider.dart';

class AdminBlogManagementPage extends StatefulWidget {
  const AdminBlogManagementPage({super.key});

  @override
  State<AdminBlogManagementPage> createState() =>
      _AdminBlogManagementPageState();
}

class _AdminBlogManagementPageState extends State<AdminBlogManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, published, draft
  String _sortBy = 'newest'; // newest, oldest, title
  bool _selectionMode = false;
  final Set<String> _selectedBlogIds = <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlogs() async {
    final contentProvider = context.read<ContentProvider>();
    await contentProvider.loadAllBlogs();
  }

  int _getReadTime(String content) {
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil(); // Average 200 words per minute
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

  List<BlogModel> _applyFilters(List<BlogModel> blogs) {
    var filtered = blogs.where((blog) {
      final matchesSearch = _searchQuery.isEmpty
          ? true
          : blog.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              blog.author.toLowerCase().contains(_searchQuery.toLowerCase());

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
          'Manage Blogs',
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
                      onPressed: _loadBlogs,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final blogs = contentProvider.blogs;
            final filtered = _applyFilters(blogs);

            if (blogs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No blogs found',
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
                            'No blogs match your search',
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
                            final blog = filtered[index];
                            final isSelected =
                                _selectedBlogIds.contains(blog.id);
                            return _buildBlogCard(
                              blog,
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
                hintText: 'Search blogs by title or author...',
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
            '${_selectedBlogIds.length} selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedBlogIds.isEmpty ? null : _bulkDelete,
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

  Widget _buildBlogCard(
      BlogModel blog,
      bool isSelected,
      LinearGradient cardGradient,
      Color borderColor,
      bool isDark,
      Color accent) {
    final readTime = _getReadTime(blog.content);
    final contentPreview = blog.content.length > 120
        ? '${blog.content.substring(0, 120)}...'
        : blog.content;

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _selectionMode = true;
          _selectedBlogIds.add(blog.id!);
        });
      },
      onTap: _selectionMode
          ? () {
              setState(() {
                if (_selectedBlogIds.contains(blog.id)) {
                  _selectedBlogIds.remove(blog.id);
                } else {
                  _selectedBlogIds.add(blog.id!);
                }
                if (_selectedBlogIds.isEmpty) _selectionMode = false;
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
        child: Row(
          children: [
            // Selection checkbox
            if (_selectionMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedBlogIds.add(blog.id!);
                        } else {
                          _selectedBlogIds.remove(blog.id);
                          if (_selectedBlogIds.isEmpty) _selectionMode = false;
                        }
                      });
                    },
                    fillColor: MaterialStateProperty.resolveWith(
                      (states) => isSelected ? accent : Colors.transparent,
                    ),
                    side: BorderSide(
                      color:
                          isSelected ? accent : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _selectionMode ? 0 : 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      blog.title,
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
                          blog.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.schedule,
                            size: 14,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '$readTime min read',
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
                          _formatDate(blog.createdAt),
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
                    // Content preview
                    Text(
                      contentPreview,
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
                    if (blog.tags?.isNotEmpty ?? false)
                      SizedBox(
                        height: 24,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: blog.tags?.length ?? 0,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              blog.tags?[i] ?? '',
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
                  ],
                ),
              ),
            ),
            // Action buttons
            if (!_selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteBlog(blog);
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
              ),
          ],
        ),
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

  Future<void> _bulkDelete() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Blogs'),
          content: Text(
              'Are you sure you want to delete ${_selectedBlogIds.length} blog(s)?'),
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
                for (final id in _selectedBlogIds) {
                  await contentProvider.deleteBlog(id);
                }
                setState(() {
                  _isLoading = false;
                  _selectionMode = false;
                  _selectedBlogIds.clear();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Blogs deleted successfully!')),
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
