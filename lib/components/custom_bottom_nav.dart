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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color selectedColor = Color(0xFFf48c25);
    final Color unselectedColor = isDark
        ? Colors.white70
        : Colors.black54;
    final Color fabColor = Color(0xFFf48c25);
    final Color bottomNavBackground = isDark 
        ? const Color.fromARGB(255, 15, 15, 15) 
        : Colors.grey.shade200;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        BottomAppBar(
          color: bottomNavBackground, // Use theme-appropriate background
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home, "Home", 0, selectedColor,
                    unselectedColor),
                _buildNavItem(context, Icons.campaign, "My Ads", 1,
                    selectedColor, unselectedColor),
                const SizedBox(width: 48), // space for FAB
                _buildNavItem(context, Icons.shop, "Investment", 3,
                    selectedColor, unselectedColor),
                _buildNavItem(context, Icons.menu, "Profile", 4, selectedColor,
                    unselectedColor),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          
            child: 
          FloatingActionButton(
            onPressed: onFabPressed,
            backgroundColor: Color.fromARGB(255, 243, 103, 52),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
            shape: const CircleBorder(),
          ),
        ),
        
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
          int index, Color selectedColor, Color unselectedColor) =>
      GestureDetector(
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
