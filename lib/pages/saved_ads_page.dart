import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/auth_provider.dart';
import '../models/ad_model.dart';
import '../services/save_service.dart';

class SavedAdsPage extends StatefulWidget {
  const SavedAdsPage({super.key});

  @override
  State<SavedAdsPage> createState() => _SavedAdsPageState();
}

class _SavedAdsPageState extends State<SavedAdsPage> {
  final SaveService _saveService = SaveService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Ads'),
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Login to view saved ads',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Ads'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<List<String>>(
        stream: _saveService.getSavedAdIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading saved ads',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final savedAdIds = snapshot.data ?? [];

          if (savedAdIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved ads yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark cars you like to save them here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Fetch the actual ads
          return FutureBuilder<List<AdModel>>(
            future: _fetchAds(savedAdIds),
            builder: (context, adsSnapshot) {
              if (adsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (adsSnapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading ads',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                );
              }

              final ads = adsSnapshot.data ?? [];

              if (ads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 60,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Some saved ads may no longer be available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  return _buildAdCard(ads[index], colorScheme);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<AdModel>> _fetchAds(List<String> adIds) async {
    if (adIds.isEmpty) return [];

    final List<AdModel> ads = [];

    for (String adId in adIds) {
      try {
        final doc =
            await FirebaseFirestore.instance.collection('ads').doc(adId).get();

        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            ads.add(AdModel.fromFirestore(data, doc.id));
          }
        }
      } catch (e) {
        print('Error fetching ad $adId: $e');
      }
    }

    return ads;
  }

  Widget _buildAdCard(AdModel ad, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/car-details',
          arguments: ad,
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 100,
                  height: 80,
                  color: colorScheme.surfaceContainerHighest,
                  child: (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                      ? Image.network(
                          ad.imageUrls!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.directions_car_filled,
                              size: 40,
                              color: colorScheme.onSurfaceVariant,
                            );
                          },
                        )
                      : Icon(
                          Icons.directions_car_filled,
                          size: 40,
                          color: colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.title.isNotEmpty ? ad.title : (ad.carBrand ?? 'Car'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ad.year}  •  ${ad.mileage} km',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ad.location,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bookmark,
                      color: Color(0xFFFF6B35),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PKR ${ad.price}',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
