import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int _selectedTabIndex = 0; // 0 = Active, 1 = Pending, 2 = Sold, 3 = Removed
  final int _selectedIndex = 1;

  final List<String> _tabs = ['Active', 'Pending', 'Sold', 'Removed'];

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
            title: const Text(
              'My Ads',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.login, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Please login to view your ads',
                    style: TextStyle(fontSize: 18)),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'loginscreen');
                  },
                  child: Text('Login'),
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
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
    return Container(
      color: Theme.of(context).colorScheme.surface,
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
    String status;
    switch (_selectedTabIndex) {
      case 0:
        status = 'active';
        break;
      case 1:
        status = 'pending';
        break;
      case 2:
        status = 'sold';
        break;
      case 3:
        status = 'removed';
        break;
      default:
        status = 'active';
    }

    final stream = GlobalAdStore().getUserAdsByStatus(userId, status);

    return StreamBuilder<List<AdModel>>(
      stream: stream,
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return _buildAdPlaceholder(
            'No ${_tabs[_selectedTabIndex]} Ads',
            'You haven\'t posted anything yet.',
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
                    child: Icon(Icons.directions_car_filled,
                        size: 32, color: cs.onSurfaceVariant),
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
                    } else {
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

                // Promote / Relist CTA
                ElevatedButton.icon(
                  onPressed: () async {
                    if (ad.status == 'removed') {
                      try {
                        await GlobalAdStore().updateAdStatus(ad.id!, 'active');
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
                    backgroundColor: ad.status == 'removed' ? Colors.green : cs.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey)),
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

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        // Handle error state - show nothing if there's an error
        if (snapshot.hasError) {
          print('Trust badge error for user $userId: ${snapshot.error}');
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

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() ?? {};
        final String level = (data['trustLevel'] ?? '').toString();
        if (level.isEmpty) return const SizedBox.shrink();

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(level.toUpperCase(), style: badgeTextStyle),
            ],
          ),
        );
      },
    );
  }
}
