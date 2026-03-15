import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';

/// Bottom navigation bar item data
class BottomNavItem {
  final PhosphorIconData icon;
  final PhosphorIconData selectedIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Premium bottom navigation bar with Phosphor icons
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        isActive ? item.selectedIcon : item.icon,
                        size: 24,
                        color: isActive ? AppColors.brand : AppColors.textTertiary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTypography.bodySm.copyWith(
                          fontSize: 10,
                          color: isActive ? AppColors.brand : AppColors.textTertiary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Active dot indicator
                      AnimatedContainer(
                        duration: AppMotion.normal,
                        width: isActive ? 4 : 0,
                        height: isActive ? 4 : 0,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
