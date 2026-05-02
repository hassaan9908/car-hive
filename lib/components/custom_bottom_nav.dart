import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onFabPressed;

  // ignore: use_super_parameters
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

    const Color selectedColor = Color(0xFFf48c25);
    final Color unselectedColor = isDark ? Colors.white70 : Colors.black54;
    final Color bottomNavBackground =
        isDark ? const Color.fromARGB(255, 15, 15, 15) : Colors.grey.shade200;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        BottomAppBar(
          color: bottomNavBackground,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    context,
                    Icons.home,
                    "Home",
                    0,
                    selectedColor,
                    unselectedColor,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    Icons.campaign,
                    "My Ads",
                    1,
                    selectedColor,
                    unselectedColor,
                  ),
                ),
                const SizedBox(width: 52),
                Expanded(
                  child: _buildNavItem(
                    context,
                    Icons.shop,
                    "Investment",
                    3,
                    selectedColor,
                    unselectedColor,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    context,
                    Icons.menu,
                    "Profile",
                    4,
                    selectedColor,
                    unselectedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          child: FloatingActionButton(
            onPressed: onFabPressed,
            backgroundColor: const Color.fromARGB(255, 243, 103, 52),
            shape: const CircleBorder(),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
          int index, Color selectedColor, Color unselectedColor) =>
      GestureDetector(
        onTap: () => onTabSelected(index),
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selectedIndex == index ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      selectedIndex == index ? selectedColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      );
}
