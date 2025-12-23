import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Myads extends StatefulWidget {
  const Myads({super.key});

  static const List<String> _navRoutes = [
    '/',
    '/myads',
    '/upload',
    '/investment',
    '/profile'
  ];

  @override
  State<Myads> createState() => _MyadsState();
}

class _MyadsState extends State<Myads> {
  int _selectedTabIndex = 0; // 0 = Active, 1 = Sold, 2 = Removed
  final int _selectedIndex = 1;

  final List<String> _tabs = ['Ads', 'Sold', 'Removed'];

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
              title: Text(
                'My Ads',
                ),
              backgroundColor: Colors.transparent,
              centerTitle: true,
            ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Please login to view your ads', style: TextStyle(fontSize: 18)),
                SizedBox(height: 24),
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
                    child: 
                ElevatedButton(
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
                  child: Text('Login'),
                ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            selectedIndex: _selectedIndex,
            onTabSelected: (index) => _onTabSelected(context, index),
            onFabPressed: () {
              if (_selectedIndex != 2) {
                Navigator.pushReplacementNamed(context, Myads._navRoutes[2]);
              }
            },
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My Ads',
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildTopTabs(),
            Expanded(child: _buildTabContent(currentUser.uid)),
          ],
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, Myads._navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Myads._navRoutes[0],
        (route) => false,
      );
    } else {
      Navigator.pushReplacementNamed(context, Myads._navRoutes[index]);
    }
  }

  void _onTopTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Widget _buildTopTabs() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color topTabs_color = isDark 
        ? const Color.fromARGB(255, 15, 15, 15) 
        : Colors.grey.shade200;

    return Container(
      color: topTabs_color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return GestureDetector(
            onTap: () => _onTopTabChanged(index),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 10,
                  ),
                  child: Text(
                    _tabs[index],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(String userId) {
    switch (_selectedTabIndex) {
      case 0:
        // Active tab shows both active and pending ads
        return _buildActiveTabContent(userId);
      case 1:
        // Sold tab shows sold ads
        return _buildSoldTabContent(userId);
      case 2:
        // Removed tab shows removed ads
        return _buildRemovedTabContent(userId);
      default:
        return _buildActiveTabContent(userId);
    }
  }

  Widget _buildActiveTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'active'),
      builder: (context, activeSnapshot) {
        return StreamBuilder<List<AdModel>>(
          stream: GlobalAdStore().getUserAdsByStatus(userId, 'pending'),
          builder: (context, pendingSnapshot) {
            if (activeSnapshot.connectionState == ConnectionState.waiting || 
                pendingSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (activeSnapshot.hasError || pendingSnapshot.hasError) {
              return _buildErrorWidget(activeSnapshot.error ?? pendingSnapshot.error);
            }

            final activeAds = activeSnapshot.data ?? [];
            final pendingAds = pendingSnapshot.data ?? [];
            final allAds = [...activeAds, ...pendingAds];

            if (allAds.isEmpty) {
              return _buildAdPlaceholder(
                'No Active Ads',
                'You don\'t have any active or pending ads.',
              );
            }

            return ListView.builder(
              itemCount: allAds.length,
              itemBuilder: (context, index) {
                final ad = allAds[index];
                return _buildAdCard(ad);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSoldTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'sold'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return _buildAdPlaceholder(
            'No Sold Ads',
            'You haven\'t sold any cars yet.',
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildRemovedTabContent(String userId) {
    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, 'removed'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error);
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return _buildAdPlaceholder(
            'No Removed Ads',
            'You don\'t have any removed ads.',
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) {
            final ad = ads[index];
            return _buildAdCard(ad);
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    String errorMessage = 'Error loading ads';
    String errorDetails = '';
    
    if (error.toString().contains('failed-precondition')) {
      errorMessage = 'Database configuration required';
      errorDetails = 'Please contact support to set up the database properly.';
    } else if (error.toString().contains('permission-denied')) {
      errorMessage = 'Access denied';
      errorDetails = 'You may not have permission to view ads.';
    } else {
      errorDetails = error.toString();
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(errorMessage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          if (errorDetails.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
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

  Widget _buildAdCard(AdModel ad) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (ad.status) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.amber[700]!;
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_bottom;
        break;
      case 'sold':
        statusColor = Colors.blue;
        statusLabel = 'Sold';
        statusIcon = Icons.sell;
        break;
      case 'removed':
        statusColor = Colors.red;
        statusLabel = 'Expired';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = cs.onSurfaceVariant;
        statusLabel = ad.status;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 1,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top content row (thumbnail + details + price)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 96,
                    height: 64,
                    color: cs.surfaceVariant,
                    child: (ad.imageUrls != null && ad.imageUrls!.isNotEmpty)
                        ? Image.network(
                            ad.imageUrls![0],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
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
                Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      Text(
                        (ad.title.isNotEmpty
                            ? ad.title
                            : (ad.carBrand ?? 'Car')),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ad.year}  •  ${ad.mileage} km',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PKR ${ad.price}',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom action row (status + actions)
            Row(
              children: [
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Edit and Delete buttons (not shown for sold ads)
                if (ad.status != 'sold') ...[
                  // Edit icon
                  _roundIconButton(
                    icon: Icons.edit,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit feature coming soon!')),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  // Delete or Remove depending on status
                  _roundIconButton(
                    icon: ad.status == 'removed' ? Icons.delete_forever : Icons.delete,
                    onPressed: () async {
                      if (ad.status == 'removed') {
                        // Permanently delete removed ads
                        try {
                          await GlobalAdStore().deleteAd(ad.id!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ad deleted permanently')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete ad: $e')),
                          );
                        }
                      } else if (ad.status == 'active') {
                        // Show popup for active ads asking if sold or removed
                        _showDeleteActiveAdDialog(ad);
                      } else if (ad.status == 'pending') {
                        // Pending ads can only be removed
                        try {
                          await GlobalAdStore().updateAdStatus(ad.id!, 'removed');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ad moved to removed')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to remove ad: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                ],

                // Promote / Relist CTA
                if (ad.status != 'sold') // Sold ads don't show action buttons
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (ad.status == 'removed') {
                          try {
                            // Use the actual previousStatus from the ad, fallback to 'active' if not available
                            final previousStatus = ad.previousStatus ?? 'active';
                            await GlobalAdStore().reactivateAd(ad.id!, previousStatus: previousStatus);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ad relisted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to relist ad: $e')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Promote functionality coming soon!')),
                          );
                        }
                      },
                      icon: Icon(ad.status == 'removed' ? Icons.refresh : Icons.rocket_launch, size: 16),
                      label: Text(ad.status == 'removed' ? 'Relist' : 'Promote'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback onPressed}) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildAdPlaceholder(String title, String subtitle) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.car_rental, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showDeleteActiveAdDialog(AdModel ad) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Ad'),
          content: const Text('What would you like to do with this ad?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use markSold method which handles sales count and trust rank updates
                  await GlobalAdStore().markSold(ad.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad marked as sold')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark as sold: $e')),
                  );
                }
              },
              child: const Text(
                'Mark as Sold',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  // Use markRemoved method which handles previousStatus properly
                  await GlobalAdStore().markRemoved(ad.id!, previousStatus: ad.status);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad moved to removed')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove ad: $e')),
                  );
                }
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}