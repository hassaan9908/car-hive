import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';
import '../services/save_service.dart';
import '../store/global_ads.dart';
import 'car_details_page.dart';

class SavedAdsPage extends StatefulWidget {
  const SavedAdsPage({super.key});

  @override
  State<SavedAdsPage> createState() => _SavedAdsPageState();
}

class _SavedAdsPageState extends State<SavedAdsPage> {
  final SaveService _saveService = SaveService();
  final GlobalAdStore _adStore = GlobalAdStore();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved Ads'),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[400],
              height: 1,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please login to view saved ads',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              Container(
                width: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, 'loginscreen');
                  },
                  child: const Text('Login'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[400],
            height: 1,
          ),
        ),
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
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading saved ads',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                  const Icon(Icons.bookmark_border,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Saved Ads',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start saving ads you like!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedAdIds.length,
            itemBuilder: (context, index) {
              final adId = savedAdIds[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('ads')
                    .doc(adId)
                    .get(),
                builder: (context, adSnapshot) {
                  if (!adSnapshot.hasData || !adSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final adData =
                      adSnapshot.data!.data() as Map<String, dynamic>;
                  final ad = AdModel.fromFirestore(adData, adSnapshot.data!.id);

                  return _buildSavedAdCard(ad, colorScheme);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSavedAdCard(AdModel ad, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarDetailsPage(ad: ad),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                    ? Image.network(
                        ad.imageUrls!.first,
                        width: 96,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 96,
                            height: 72,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.directions_car_filled,
                                size: 32, color: colorScheme.onSurfaceVariant),
                          );
                        },
                      )
                    : Container(
                        width: 96,
                        height: 72,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.directions_car_filled,
                            size: 32, color: colorScheme.onSurfaceVariant),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ad.year}  •  ${ad.mileage} km',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PKR ${ad.price}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Unsave button
              IconButton(
                icon: const Icon(Icons.bookmark),
                color: colorScheme.primary,
                onPressed: () async {
                  try {
                    await _saveService.toggleSave(ad.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ad removed from saved')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
