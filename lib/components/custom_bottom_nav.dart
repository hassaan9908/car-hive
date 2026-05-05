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
    final Color unselectedColor = isDark ? Colors.white54 : Colors.black38;
    final Color barBackground =
        isDark ? const Color(0xFF1C1C1E) : Colors.white;

    // The pill-shaped floating bar from the reference image
    return SizedBox(
        height: 64,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Pill-shaped bar ──────────────────────────────────────────
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: barBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Left two tabs
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

                  // Centre gap for the raised FAB
                  const SizedBox(width: 72),

                  // Right two tabs
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
                      Icons.person,
                      "Profile",
                      4,
                      selectedColor,
                      unselectedColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── Raised FAB — sits above the bar, centred ─────────────────
            Positioned(
              top: -18, // raises the button above the bar
              child: _RaisedFab(onPressed: onFabPressed),
            ),
          ],
        ),
      );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    Color selectedColor,
    Color unselectedColor,
  ) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Raised circular FAB that matches the reference image:
// solid blue circle with a white "+" and a soft outer glow ring.
// ─────────────────────────────────────────────────────────────────────────────
class _RaisedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  const _RaisedFab({this.onPressed});

  @override
  Widget build(BuildContext context) {
    const double size = 56;
    

    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft outer glow ring (the light halo visible in the reference)
          Container(
            width: size + 16,
            height: size + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 243, 103, 52).withValues(alpha: 0.18),
            ),
          ),

          // Main circle button
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromARGB(255, 243, 103, 52),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 243, 103, 52).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}