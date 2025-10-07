import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../components/custom_textfield.dart';
import '../components/car_tabs.dart';
import '../components/custom_bottom_nav.dart';
import '../providers/search_provider.dart';

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
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                textBaseline: TextBaseline.alphabetic,
                inherit: false,
              ),
            ),
            backgroundColor: colorScheme.primary,
            centerTitle: true,
            actions: [
              // Admin Panel button (web only)
              if (kIsWeb)
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin');
                  },
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                  ),
                  tooltip: 'Admin Panel',
                ),
              IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.white,
                  )),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.background,
                  colorScheme.surfaceVariant,
                ],
              ),
            ),
            child: Column(
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
                  child: Image.asset(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text(ad.year, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
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
                    Text(
                      'PKR ${ad.price}',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

}
