import 'package:flutter/material.dart';
import '../components/search_bar.dart' as custom;
import '../components/car_tabs.dart';
import '../components/custom_bottom_nav.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  static const int _selectedIndex = 0;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CarHive',
          style: TextStyle(
            color: Colors.white
          ),
          ),
        backgroundColor: Color.fromARGB(255, 132, 33, 156),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: (){
              Navigator.pushNamed(context, '/notifications');
            },
             icon: Icon(
              Icons.notifications,
              color: Colors.white,
              ))
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          custom.SearchBar(),
          SizedBox(height: 16),
          CarTabs(),
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
    );
  }
}
