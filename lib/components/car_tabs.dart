import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';

class CarTabs extends StatelessWidget {
  const CarTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const TabBar(
              indicator: BoxDecoration(), // Removes the underline/white line
              labelColor: Color.fromARGB(255, 35, 38, 68),
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelColor: Colors.grey,
              unselectedLabelStyle:
                  TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
              tabs: [
                Tab(text: 'Used Cars'),
                Tab(text: 'New Cars'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400, // Increased height for better content display
            child: TabBarView(
              children: [
                _UsedCarsTab(),
                const Center(child: Text('New Cars List Placeholder')),
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
      stream: GlobalAdStore().getAllAds(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(errorMessage,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (errorDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      errorDetails,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.car_rental, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No cars available',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Check back later for new listings',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(context, ad);
          },
        );
      },
    );
  }

  Widget _buildAdCard(BuildContext context, AdModel ad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image placeholder
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(Icons.car_rental, size: 48, color: Colors.grey[400]),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'PKR ${ad.price}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      ad.location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Car details
                Row(
                  children: [
                    _buildDetailChip(ad.year, Icons.calendar_today),
                    const SizedBox(width: 8),
                    _buildDetailChip('${ad.mileage} km', Icons.speed),
                    const SizedBox(width: 8),
                    _buildDetailChip(ad.fuel, Icons.local_gas_station),
                  ],
                ),

                if (ad.carBrand != null && ad.carBrand!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Brand: ${ad.carBrand}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],

                if (ad.description != null && ad.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    ad.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Contact button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement contact functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Contact feature coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Contact Seller'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
