import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../components/custom_textfield.dart';
import '../components/car_tabs.dart';
import '../components/custom_bottom_nav.dart';
import '../providers/search_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Homepage extends StatefulWidget {
  final int initialTab;

  const Homepage({super.key, this.initialTab = 0});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    // Initialize search provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().initializeAds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const int _selectedIndex = 0;
  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
          context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<SearchProvider>(
      builder: (context, searchProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'CarHive',          
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            // Prevent showing a back arrow when arriving from auth flow
            automaticallyImplyLeading: false,
            actions: [
              // Admin Panel button (web only)
              if (kIsWeb)
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Admin Panel',
                ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/map-view');
                },
                icon: const Icon(Icons.map),
                tooltip: 'Map View',
              ),
              IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  icon: const Icon(Icons.chat)),
            ],
          ),
          body: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CustomTextField(
                    controller: _searchController,
                    hintText: 'Search cars, brands, models...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              searchProvider.clearSearch();
                              setState(() {
                                _isSearchActive = false;
                              });
                            },
                          )
                        : null,
                    onChanged: (value) {
                      setState(() {
                        _isSearchActive = value.isNotEmpty;
                      });
                      searchProvider.updateSearchQuery(value);
                    },
                  ),
                ),

                // Search Results or Car Tabs
                Expanded(
                  child: _isSearchActive
                      ? _buildSearchResults(searchProvider)
                      : CarTabs(initialTab: widget.initialTab),
                ),
              ],
            ),
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) => _onTabSelected(context, index),
            onFabPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacementNamed(context, _navRoutes[2]);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (searchProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Error loading search results',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              searchProvider.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!searchProvider.hasSearchResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: searchProvider.filteredAds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ad = searchProvider.filteredAds[index];
        return _buildAdListItem(context, ad);
      },
    );
  }

  Widget _buildAdListItem(BuildContext context, dynamic ad) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/car-details',
          arguments: ad,
        );
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 100,
                  height: 64,
                  color: colorScheme.surfaceVariant,
                  child: (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                      ? Image.network(
                          ad.imageUrls![0],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/Retro.gif',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/Retro.gif',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ad.year,
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      (ad.title.isNotEmpty
                          ? ad.title
                          : (ad.carBrand != null && ad.carBrand!.isNotEmpty
                              ? ad.carBrand!
                              : 'Car')),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildTrustRow(context, ad.userId, ad.id),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PKR ${ad.price}',
                style: TextStyle(
                    color: colorScheme.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustRow(BuildContext context, String? userId, String? adId) {
    final cs = Theme.of(context).colorScheme;
    if (userId == null || userId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 0);

        final userData =
            userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String level = (userData['trustLevel'] ?? 'Bronze').toString();

        return StreamBuilder<QuerySnapshot>(
          stream: adId != null && adId.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('reviews')
                  .where('adId', isEqualTo: adId)
                  .snapshots()
              : null,
          builder: (context, reviewSnapshot) {
            double avg = 0.0;
            int count = 0;

            if (reviewSnapshot.hasData &&
                reviewSnapshot.data!.docs.isNotEmpty) {
              int sum = 0;
              for (final d in reviewSnapshot.data!.docs) {
                final r = d.data() as Map<String, dynamic>;
                final rating = r['rating'];
                if (rating is int) {
                  sum += rating;
                  count += 1;
                } else if (rating is num) {
                  sum += rating.toInt();
                  count += 1;
                }
              }
              if (count > 0) avg = sum / count;
            }

            final avgRating = avg;
            final ratingCount = count;
            final Color levelColor = _levelColor(level, cs);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: levelColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                        color: levelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.star, size: 14, color: Colors.amber[600]),
                const SizedBox(width: 2),
                Text(
                  '${avgRating.toStringAsFixed(1)} (${ratingCount})',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _levelColor(String level, ColorScheme cs) {
    switch (level.toLowerCase()) {
      case 'gold':
        return const Color(0xFFFFC107);
      case 'silver':
        return const Color(0xFFB0BEC5);
      default:
        return cs.primary;
    }
  }
}
