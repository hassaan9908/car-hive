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
      color: Colors.white,
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.transparent,
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
    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.car_rental, color: Colors.grey[400]),
                ),
                title: Text(ad.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${ad.location}\n${ad.year} | ${ad.mileage} | ${ad.fuel}',
                  style: const TextStyle(height: 1.5),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'Edit') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit feature coming soon!')),
                      );
                    } else if (value == 'SoldOrRemove') {
                      // Only valid for active
                      _showSoldOrRemoveDialog(ad);
                    } else if (value == 'RemoveOnly') {
                      // For pending: direct remove with previousStatus tracking
                      try {
                        await GlobalAdStore()
                            .markRemoved(ad.id!, previousStatus: ad.status);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ad moved to removed')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to remove ad: $e')),
                        );
                      }
                    } else if (value == 'Delete') {
                      try {
                        await GlobalAdStore().deleteAd(ad.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ad deleted permanently')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete ad: $e')),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) {
                    final List<PopupMenuEntry<String>> items = [];
                    items.add(const PopupMenuItem(
                        value: 'Edit', child: Text('Edit')));
                    if (ad.status == 'active') {
                      items.add(const PopupMenuItem(
                          value: 'SoldOrRemove', child: Text('Sold / Remove')));
                    } else if (ad.status == 'pending') {
                      items.add(const PopupMenuItem(
                          value: 'RemoveOnly', child: Text('Remove')));
                    }
                    items.add(const PopupMenuItem(
                        value: 'Delete', child: Text('Delete Permanently')));
                    return items;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PKR ${ad.price}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    if (ad.status == 'removed')
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final previous = ad.previousStatus ?? 'active';
                            await GlobalAdStore()
                                .reactivateAd(ad.id!, previousStatus: previous);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ad reactivated')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to reactivate ad: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.replay, size: 18),
                        label: const Text('Reactivate'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if ((ad.userId ?? '').isNotEmpty)
          Positioned(
            right: 20,
            top: 8,
            child: _buildTrustBadge(ad.userId!),
          ),
      ],
    );
  }

  void _showSoldOrRemoveDialog(AdModel ad) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark as Sold or Remove?'),
          content: const Text('Choose an option for this ad.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await GlobalAdStore()
                      .markRemoved(ad.id!, previousStatus: ad.status);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ad moved to removed')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove ad: $e')),
                  );
                }
              },
              child: const Text('Remove'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await GlobalAdStore().markSold(ad.id!);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ad marked as sold')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to mark sold: $e')),
                  );
                }
              },
              child: const Text('Sold'),
            ),
          ],
        );
      },
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
