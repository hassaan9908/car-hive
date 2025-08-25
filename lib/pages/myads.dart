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
  int _selectedTabIndex = 0; // 0 = Active, 1 = Pending, 2 = Removed
  final int _selectedIndex = 1;

  final List<String> _tabs = ['Active', 'Pending', 'Removed'];

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
            backgroundColor: const Color.fromARGB(255, 132, 33, 156),
            centerTitle: true,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Please login to view your ads',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'loginscreen');
                  },
                  child: const Text('Login'),
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
          backgroundColor: const Color.fromARGB(255, 132, 33, 156),
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
        status = 'removed';
        break;
      default:
        status = 'active';
    }

    return StreamBuilder<List<AdModel>>(
      stream: GlobalAdStore().getUserAdsByStatus(userId, status),
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
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
<<<<<<< HEAD
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
=======
            leading: (ad.photos.isNotEmpty)
                ? Image.network(ad.photos.first,
                    width: 50, height: 50, fit: BoxFit.cover)
                : Image.asset('assets/no_image.png', width: 50, height: 50),
            title: Text(
              '${ad.brand} ${ad.carModel}', // ⟵ new model: no `title`
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
>>>>>>> home-feature
            subtitle: Text(
              '${ad.location}\n${ad.year} | ${ad.kmsDriven} kms | ${ad.fuel}', // ⟵ `kmsDriven` (not mileage)
              style: const TextStyle(height: 1.5),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'Edit') {
                  // TODO: Navigate to edit screen
<<<<<<< HEAD
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon!')),
                  );
                } else if (value == 'Remove') {
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
                } else if (value == 'Delete') {
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
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                const PopupMenuItem(value: 'Remove', child: Text('Remove')),
                const PopupMenuItem(
                    value: 'Delete', child: Text('Delete Permanently')),
=======
                } else if (value == 'Remove') {
                  // Status is final—update via store, then refresh lists
                  final store = GlobalAdStore();
                  store.updateStatus(
                      ad.id, 'removed'); // ⟵ add this method below
                  setState(() {
                    _activeAds = store.getByStatus('active');
                    _pendingAds = store.getByStatus('pending');
                    _removedAds = store.getByStatus('removed');
                    _counts = [
                      _activeAds.length,
                      _pendingAds.length,
                      _removedAds.length
                    ];
                  });
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Edit', child: Text('Edit')),
                PopupMenuItem(value: 'Remove', child: Text('Remove')),
>>>>>>> home-feature
              ],
            ),
          )

          // ---------=====-=-=
          // ListTile(
          //   leading: Image.asset('assets/no_image.png', width: 50),
          //   title: Text(ad.title,
          //       style: const TextStyle(fontWeight: FontWeight.bold)),
          //   subtitle: Text(
          //     '${ad.location}\n${ad.year} | ${ad.mileage} | ${ad.fuel}',
          //     style: const TextStyle(height: 1.5),
          //   ),
          //   trailing: PopupMenuButton<String>(
          //     onSelected: (value) {
          //       if (value == 'Edit') {
          //         // TODO: Navigate to edit screen
          //       } else if (value == 'Remove') {
          //         setState(() {
          //           ad.status = 'removed';
          //         });
          //       }
          //     },
          //     itemBuilder: (context) => [
          //       const PopupMenuItem(value: 'Edit', child: Text('Edit')),
          //       const PopupMenuItem(value: 'Remove', child: Text('Remove')),
          //     ],
          //   ),
          // ),
          ,
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
                ElevatedButton.icon(
                  onPressed: () {
                    // Feature logic (optional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Feature ad functionality coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Feature This Ad'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.car_rental, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
