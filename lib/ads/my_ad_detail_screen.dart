import 'package:carhive/ads/postadcar.dart'; // Import the PostAdCar screen
import 'package:carhive/ads/tresxtview.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for authentication

// Reusable component for ad promotion section
class AdPromotionSection extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const AdPromotionSection({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.5; // 50% of screen width, adjustable
    final buttonHeight =
        screenWidth * 0.08; // 8% of screen width for height, adjustable

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle()), // Removed bold styling
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.star, color: Colors.white),
            label: Text(
              buttonText.toUpperCase(), // Uppercase text like PakWheels
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16, // Slightly larger for emphasis
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: Size(buttonWidth, buttonHeight), // Responsive size
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero, // No rounded corners
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final String feature;
  final IconData icon;

  const FeatureItem({
    super.key,
    required this.feature,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        Text(feature),
      ],
    );
  }
}

class MyAdDetailScreen extends StatefulWidget {
  final String adId;

  const MyAdDetailScreen({super.key, required this.adId});

  @override
  State<MyAdDetailScreen> createState() => _MyAdDetailScreenState();
}

class _MyAdDetailScreenState extends State<MyAdDetailScreen> {
  late Future<AdModel> _adFuture;

  @override
  void initState() {
    super.initState();
    _adFuture = _fetchAd();
  }

  Future<AdModel> _fetchAd() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Nothing here'); // Return "Nothing here" if no user
    }
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('ads')
        .doc(widget.adId)
        .get();
    if (!doc.exists) {
      throw Exception('Ad not found');
    }
    return AdModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth =
        screenWidth * 0.25; // 25% of screen width for action buttons
    final buttonHeight = screenWidth * 0.08; // 8% of screen width for height

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<AdModel>(
          future: _adFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading...');
            }
            if (snapshot.hasError) {
              return const Text('Nothing here'); // Display if no user or ad
            }
            if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            }
            return const Text('Loading...');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: FutureBuilder<AdModel>(
        future: _adFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Nothing here')); // Display if no user or ad
          }
          final ad = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported, size: 100),
                      Text('No Image Available'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad.title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(ad.price,
                          style: const TextStyle(
                              color: Colors.green, fontSize: 18)),
                      Text(ad.location),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(ad.year),
                      Text(ad.mileage),
                      Text(ad.fuel),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center alignment to remove extra space
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PostAdCar(
                                  // adId: widget.adId
                                  ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                              buttonWidth, buttonHeight), // Responsive size
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.zero, // No rounded corners
                          ),
                        ),
                        child: const Text(
                          'EDIT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Slightly larger for emphasis
                            letterSpacing: 1.0, // Spacing like PakWheels
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Small gap between buttons
                      ElevatedButton(
                        onPressed: () {
                          // Implement remove functionality
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                              buttonWidth, buttonHeight), // Responsive size
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.zero, // No rounded corners
                          ),
                        ),
                        child: const Text(
                          'REMOVE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Slightly larger for emphasis
                            letterSpacing: 1.0, // Spacing like PakWheels
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // Small gap between buttons
                      ElevatedButton(
                        onPressed: () {
                          // Implement share
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                              buttonWidth, buttonHeight), // Responsive size
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.zero, // No rounded corners
                          ),
                        ),
                        child: const Text(
                          'SHARE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Slightly larger for emphasis
                            letterSpacing: 1.0, // Spacing like PakWheels
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Implement report
                    },
                    child: const Text('Report Spam Caller'),
                  ),
                ),
                AdPromotionSection(
                  title: 'Get Your Ad Featured',
                  description:
                      'Get more attention, and calls by featuring your ad at the top!',
                  buttonText: 'FEATURE MY AD',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Feature functionality coming soon!')),
                    );
                  },
                ),
                AdPromotionSection(
                  title: 'Boost Your Ad',
                  description:
                      'Move your ad higher in listing and get noticed faster',
                  buttonText: 'TAKE ME TO THE TOP',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Boost functionality coming soon!')),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ad.registeredIn != null)
                        DetailRow(
                            label: 'Registered In', value: ad.registeredIn!),
                      if (ad.bodyColor != null)
                        DetailRow(
                            label: 'Exterior Color', value: ad.bodyColor!),
                      if (ad.kmsDriven != null)
                        DetailRow(label: 'Kms Driven', value: ad.kmsDriven!),
                      DetailRow(label: 'Year', value: ad.year),
                      DetailRow(label: 'Ad ID', value: ad.id ?? ''),
                      if (ad.createdAt != null)
                        DetailRow(
                          label: 'Posted On',
                          value:
                              '${ad.createdAt!.day} ${ad.createdAt!.month} ${ad.createdAt!.year}',
                        ),
                      if ([
                            ad.registeredIn,
                            ad.bodyColor,
                            ad.kmsDriven,
                            ad.createdAt,
                          ].where((feature) => feature != null).length >
                          4)
                        TextButton(
                          onPressed: () {
                            // Implement show more functionality
                          },
                          child: const Text('Show More'),
                        ),
                    ],
                  ),
                ),
                if (ad.description != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(ad.description!),

                        // 360 view for car 
                        // 360 Car View Section
if (ad.carImages360 != null && ad.carImages360!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '360° View',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250, // adjust as needed
          child: Car360View(carImages: ad.carImages360!),
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
        },
      ),
    );
  }
}
