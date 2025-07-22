import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onFabPressed;

  const CustomBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onFabPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "Home", 0),
                _buildNavItem(Icons.campaign, "My Ads", 1),
                const SizedBox(width: 48), // space for FAB
                _buildNavItem(Icons.shop, "Investment", 3),
                _buildNavItem(Icons.menu, "Profile", 4),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          child: FloatingActionButton(
            onPressed: onFabPressed,
            backgroundColor: const Color.fromARGB(255, 161, 41, 191),
            child: const Icon(Icons.add, size: 32),
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) => GestureDetector(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selectedIndex == index
                  ? const Color.fromARGB(255, 161, 41, 191)
                  : Colors.black54,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selectedIndex == index
                    ? const Color.fromARGB(255, 161, 41, 191)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      );
} 