import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';

class Mutualinvestment extends StatelessWidget {
  const Mutualinvestment({super.key});

  static const int _selectedIndex = 3;
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
        appBar: AppBar(
              title: Text(
                'Mutual Investment',
                style: TextStyle(
                  color: Colors.white
                ),
                ),
              backgroundColor: Color.fromARGB(255, 132, 33, 156),
              centerTitle: true,
            ),
        body: Center(
          child: Text('Mutual Investment'),
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
}