import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';

// Simple cache for trust levels to persist across account switches
class TrustLevelCache {
  static final Map<String, String> _cache = {};

  static void setTrustLevel(String userId, String trustLevel) {
    _cache[userId] = trustLevel;
  }

  static String? getTrustLevel(String userId) {
    return _cache[userId];
  }

  static void clearCache() {
    _cache.clear();
  }
}

class CarTabs extends StatelessWidget {
  final int initialTab;

  const CarTabs({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 3,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: colorScheme.primary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                textBaseline: TextBaseline.alphabetic,
                inherit: false,
              ),
              unselectedLabelColor: Colors.white,
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
                textBaseline: TextBaseline.alphabetic,
                inherit: false,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Used Cars'),
                Tab(text: 'New Cars'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _UsedCarsTab(),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.car_rental,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'New Cars Coming Soon',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stay tuned for new car listings',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UsedCarsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getAllActiveAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          String errorMessage = 'Error loading ads';
          String errorDetails = '';

          if (snapshot.error.toString().contains('failed-precondition')) {
            errorMessage = 'Database configuration required';
            errorDetails =
                'Please contact support to set up the database properly.';
          } else if (snapshot.error.toString().contains('permission-denied')) {
            errorMessage = 'Access denied';
            errorDetails = 'You may not have permission to view ads.';
          } else {
            errorDetails = snapshot.error.toString();
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(errorMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic,
                      inherit: false,
                    )),
                SizedBox(height: 8),
                if (errorDetails.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorDetails,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        textBaseline: TextBaseline.alphabetic,
                        inherit: false,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.car_rental, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No cars available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      textBaseline: TextBaseline.alphabetic,
                      inherit: false,
                    )),
                SizedBox(height: 8),
                Text('Check back later for new listings',
                    style: TextStyle(
                      color: Colors.grey,
                      textBaseline: TextBaseline.alphabetic,
                      inherit: false,
                    )),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildAdCard(context, ad),
            );
          },
        );
      },
    );
  }

  Widget _buildAdCard(BuildContext context, AdModel ad) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        // Navigate to detailed car page
        Navigator.pushNamed(
          context,
          '/car-details',
          arguments: ad,
        );
      },
      child: Stack(
        children: [
          Card(
            elevation: 2,
            color: colorScheme.surfaceVariant,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Car image placeholder (left side)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.car_rental,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Car details (right side)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Year
                        Text(
                          '${ad.year}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                        ),

                        const SizedBox(height: 4),

                        // Car model/title
                        Text(
                          ad.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Price
                        Text(
                          'PKR ${ad.price}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Trust badge positioned in top-right corner
          if (ad.userId != null && ad.userId!.isNotEmpty)
            Positioned(
              right: 8,
              top: 8,
              child: _buildTrustBadge(ad.userId!),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(String userId) {
    final badgeTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    // Check cache first
    final cachedLevel = TrustLevelCache.getTrustLevel(userId);
    if (cachedLevel != null &&
        ['Bronze', 'Silver', 'Gold'].contains(cachedLevel)) {
      return _buildBadgeWidget(cachedLevel, badgeTextStyle);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle error state - try to use cached value if available
        if (snapshot.hasError) {
          print('Trust badge error for user $userId: ${snapshot.error}');
          final cachedLevel = TrustLevelCache.getTrustLevel(userId);
          if (cachedLevel != null &&
              ['Bronze', 'Silver', 'Gold'].contains(cachedLevel)) {
            return _buildBadgeWidget(cachedLevel, badgeTextStyle);
          }
          return const SizedBox.shrink();
        }

        // Handle loading state - show a subtle loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        // Only show badge if we have valid trust level data
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() ?? {};
        final fetched = (data['trustLevel'] ?? '').toString();

        // Don't show badge if trustLevel is empty or invalid
        if (fetched.isEmpty ||
            !['Bronze', 'Silver', 'Gold'].contains(fetched)) {
          return const SizedBox.shrink();
        }

        // Cache the trust level for future use
        TrustLevelCache.setTrustLevel(userId, fetched);

        return _buildBadgeWidget(fetched, badgeTextStyle);
      },
    );
  }

  Widget _buildBadgeWidget(String level, TextStyle badgeTextStyle) {
    Color bg;
    switch (level) {
      case 'Gold':
        bg = Colors.amber[700] ?? Colors.amber;
        break;
      case 'Silver':
        bg = Colors.blueGrey[400] ?? Colors.blueGrey;
        break;
      case 'Bronze':
      default:
        bg = Colors.brown[400] ?? Colors.brown;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            level.toUpperCase(),
            style: badgeTextStyle.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
