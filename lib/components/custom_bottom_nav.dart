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
    final Color selectedColor = Color.fromARGB(255, 94, 98, 135);
    final Color unselectedColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
    final Color fabColor = Color.fromARGB(255, 35, 38, 68);
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
                _buildNavItem(context, Icons.home, "Home", 0, selectedColor, unselectedColor),
                _buildNavItem(context, Icons.campaign, "My Ads", 1, selectedColor, unselectedColor),
                const SizedBox(width: 48), // space for FAB
                _buildNavItem(context, Icons.shop, "Investment", 3, selectedColor, unselectedColor),
                _buildNavItem(context, Icons.menu, "Profile", 4, selectedColor, unselectedColor),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          child: FloatingActionButton(
            onPressed: onFabPressed,
            backgroundColor: fabColor,
            child: const Icon(Icons.add, size: 32, color: Colors.white,),
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, Color selectedColor, Color unselectedColor) => GestureDetector(
        onTap: () => onTabSelected(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selectedIndex == index ? selectedColor : unselectedColor,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selectedIndex == index ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      );
} 