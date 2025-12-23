import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:carhive/services/car_brand_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarTabs extends StatelessWidget {
  final int initialTab;
  final String? selectedBrandId; // For brand filtering

  const CarTabs({Key? key, this.initialTab = 0, this.selectedBrandId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simplified - just show Used Cars tab content
    return _UsedCarsTab(selectedBrandId: selectedBrandId);
  }
}

class _UsedCarsTab extends StatelessWidget {
  final String? selectedBrandId;

  const _UsedCarsTab({this.selectedBrandId});

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

        var ads = snapshot.data ?? [];

        // Filter by brand if selected
        if (selectedBrandId != null && selectedBrandId!.isNotEmpty) {
          // Get brand display name from ID
          final brandService = CarBrandService();
          final brand = brandService.getBrandById(selectedBrandId!);
          final brandName = brand?.displayName ?? selectedBrandId!;
          
          ads = ads.where((ad) {
            if (ad.carBrand == null) return false;
            // Match by brand display name (case-insensitive)
            final adBrandLower = ad.carBrand!.toLowerCase();
            final selectedBrandLower = brandName.toLowerCase();
            return adBrandLower == selectedBrandLower ||
                adBrandLower.contains(selectedBrandLower) ||
                selectedBrandLower.contains(adBrandLower);
          }).toList();
        }

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

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color card_color = isDark 
        ? const Color.fromARGB(255, 15, 15, 15) 
        : Colors.grey.shade200;
    
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
        color: card_color,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 120,
                  height: 100,
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
                      _getCarDisplayName(ad),
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

  String _getCarDisplayName(AdModel ad) {
    // Prefer title if available
    if (ad.title.isNotEmpty) {
      return ad.title;
    }
    
    // Otherwise, combine brand + name
    final brand = ad.carBrand ?? '';
    final name = ad.carName ?? '';
    
    if (brand.isNotEmpty && name.isNotEmpty) {
      return '$brand $name';
    } else if (brand.isNotEmpty) {
      return brand;
    } else if (name.isNotEmpty) {
      return name;
    }
    
    return 'Car';
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
