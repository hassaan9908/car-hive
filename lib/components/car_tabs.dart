import 'package:flutter/material.dart';
import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';

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

  // removed old grid detail chip as UI switched to list layout
} 