import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              isScrollable: false,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              labelColor: colorScheme.primary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                textBaseline: TextBaseline.alphabetic,
                inherit: false,
              ),
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
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
          const SizedBox(height: 8),
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
            errorDetails = 'Please contact support to set up the database properly.';
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
                Text(errorMessage, style: TextStyle(
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
                Text('No cars available', style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  textBaseline: TextBaseline.alphabetic,
                  inherit: false,
                )),
                SizedBox(height: 8),
                Text('Check back later for new listings', style: TextStyle(
                  color: Colors.grey,
                  textBaseline: TextBaseline.alphabetic,
                  inherit: false,
                )),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: ads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdListItem(context, ad);
          },
        );
      },
    );
  }

  Widget _buildAdListItem(BuildContext context, AdModel ad) {
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
                    // Trust row
                    _buildTrustRow(context, ad.userId, ad.id),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price
              Text(
                'PKR ${ad.price}',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w700),
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

    Future<Map<String, dynamic>> load() async {
      // Fetch user trust
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userSnap.data() ?? {};
      final String level = (userData['trustLevel'] ?? 'Bronze').toString();

      // Compute per-ad average rating
      double avg = 0.0;
      int count = 0;
      if (adId != null && adId.isNotEmpty) {
        final reviewsSnap = await FirebaseFirestore.instance
            .collection('reviews')
            .where('adId', isEqualTo: adId)
            .get();
        if (reviewsSnap.docs.isNotEmpty) {
          int sum = 0;
          for (final d in reviewsSnap.docs) {
            final r = d.data()['rating'];
            if (r is int) {
              sum += r;
              count += 1;
            } else if (r is num) {
              sum += r.toInt();
              count += 1;
            }
          }
          if (count > 0) avg = sum / count;
        }
      }

      return {'level': level, 'avg': avg, 'count': count};
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 0);
        final level = (snapshot.data!['level'] as String?) ?? 'Bronze';
        final avgRating = ((snapshot.data!['avg'] ?? 0) as num).toDouble();
        final ratingCount = (snapshot.data!['count'] ?? 0) as int;
        final Color levelColor = _levelColor(level, cs);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: levelColor.withOpacity(0.3)),
              ),
              child: Text(
                level,
                style: TextStyle(color: levelColor, fontSize: 11, fontWeight: FontWeight.w600),
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