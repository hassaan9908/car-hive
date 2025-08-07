import 'package:carhive/models/ad_model.dart';
import 'package:carhive/store/global_ads.dart';
import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

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

  /// Replace with actual counts later
  // final List<int> _counts = [0, 0, 0]; =====-=-=-

  List<AdModel> _activeAds = [];
  List<AdModel> _pendingAds = [];
  List<AdModel> _removedAds = [];
  List<int> _counts = [];

  @override
  void initState() {
    super.initState();

    final store = GlobalAdStore();
    _activeAds = store.getByStatus('active');
    _pendingAds = store.getByStatus('pending');
    _removedAds = store.getByStatus('removed');

    _counts = [
      _activeAds.length,
      _pendingAds.length,
      _removedAds.length,
    ];
  }

  // Default Active Ads = 0

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

  @override
  Widget build(BuildContext context) {
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
            Expanded(child: _buildTabContent()),
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
                    '${_tabs[index]} (${_counts[index]})',
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

  Widget _buildTabContent() {
    List<AdModel> ads;
    switch (_selectedTabIndex) {
      case 0:
        ads = GlobalAdStore().getByStatus('active');
        break;
      case 1:
        ads = GlobalAdStore().getByStatus('pending');
        break;
      case 2:
        ads = GlobalAdStore().getByStatus('removed');
        break;
      default:
        ads = [];
    }

    if (ads.isEmpty) {
      return _buildAdPlaceholder(
        'No ${_tabs[_selectedTabIndex]} Ads',
        'You haven’t posted anything yet.',
      );
    }

    return ListView.builder(
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return _buildAdCard(ad);
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
            leading: Image.asset('assets/no_image.png', width: 50),
            title: Text(ad.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${ad.location}\n${ad.year} | ${ad.mileage} | ${ad.fuel}',
              style: const TextStyle(height: 1.5),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Edit') {
                  // TODO: Navigate to edit screen 
                } else if (value == 'Remove') {
                  setState(() {
                    ad.status = 'removed';
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'Edit', child: Text('Edit')),
                const PopupMenuItem(value: 'Remove', child: Text('Remove')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Feature logic (optional)
              },
              icon: const Icon(Icons.star, size: 18),
              label: const Text('Feature This Ad'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Text('Ad will expire in 28 days',
                style: TextStyle(color: Colors.grey[600])),
          )
        ],
      ),
    );
  }

  Widget _buildAdPlaceholder(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_list_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
