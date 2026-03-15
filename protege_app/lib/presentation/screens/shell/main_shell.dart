import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../widgets/common/bottom_nav_bar.dart'; // For BottomNavItem
import '../../widgets/navigation/floating_nav_bar.dart';

/// Main application shell with bottom navigation
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow content to flow behind safe area
      body: Stack(
        children: [
          // The current active branch screen
          navigationShell,
          
          // Floating Liquid Glass Navigation Bar
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingNavBar(
                currentIndex: navigationShell.currentIndex,
                onTap: _onTap,
                items: [
                  BottomNavItem(
                    icon: PhosphorIcons.house(),
                    selectedIcon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                    label: 'Home',
                  ),
                  BottomNavItem(
                    icon: PhosphorIcons.compass(),
                    selectedIcon: PhosphorIcons.compass(PhosphorIconsStyle.fill),
                    label: 'Explore',
                  ),
                  BottomNavItem(
                    icon: PhosphorIcons.chartLineUp(),
                    selectedIcon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.fill),
                    label: 'Progress',
                  ),
                  BottomNavItem(
                    icon: PhosphorIcons.brain(),
                    selectedIcon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
                    label: 'Teach',
                  ),
                  BottomNavItem(
                    icon: PhosphorIcons.userCircle(),
                    selectedIcon: PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
