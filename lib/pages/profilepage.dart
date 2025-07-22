import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  static const int _selectedIndex = 4;
  static const List<String> _navRoutes = [
    '/', '/myads', '/upload', '/investment', '/profile'
  ];

  void _onTabSelected(BuildContext context, int index) {
    if (_selectedIndex == index) return;
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, _navRoutes[0], (route) => false);
    } else {
      Navigator.pushReplacementNamed(context, _navRoutes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return false;
      },
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Gradient header with button
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 96, 24, 114),
                    Color.fromARGB(255, 132, 33, 156),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  height: 45,
                  margin: EdgeInsets.only(left: 17, right: 17, top: 70),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Log in / Sign up',
                      style: TextStyle(
                        color: Color.fromARGB(255, 132, 33, 156),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Section: Personal
            _sectionHeader("Personal"),
            _profileTile(Icons.settings, "Theme"),
            _profileTile(Icons.language, "Choose Language"),
            Divider(),
            // Section: Products
            _sectionHeader("Products"),
            _profileTile(Icons.directions_car, "Sell My Car"),
            _profileTile(Icons.directions_car_filled, "Buy Used Car"),
            _profileTile(Icons.car_rental, "Buy New Car"),
            Divider(),
            // Section: Explore
            _sectionHeader("Explore"),
            _profileTile(Icons.article, "Blog"),
            _profileTile(Icons.ondemand_video, "Videos"),
            _profileTile(Icons.directions_car, "Cool Rides"),
          ],
        ),
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: _selectedIndex,
          onTabSelected: (index) => _onTabSelected(context, index),
          onFabPressed: () {
            if (_selectedIndex != 2) {
              Navigator.pushReplacementNamed(context, _navRoutes[2]);
            }
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 0, 6),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      );

  Widget _profileTile(IconData icon, String title) => ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: TextStyle(fontSize: 16)),
        onTap: () {},
        dense: true,
      );
}