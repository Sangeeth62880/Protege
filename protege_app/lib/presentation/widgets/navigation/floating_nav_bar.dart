import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../common/bottom_nav_bar.dart'; // Re-use BottomNavItem data structure if needed, or define locally
import '../common/glass_container.dart';

/// iOS 26 Liquid Glass inspired floating navigation bar
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Determine nav bar width — either intrinsic or fixed percentage
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = (screenWidth * 0.9).clamp(280.0, 400.0);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.0),
        ),
      ),
      child: Container(
        width: navWidth,
        constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: AppRadius.full,
        backgroundColor: Colors.white,
        opacity: 0.15,
        blurSigma: 25.0,
        borderOpacity: 0.2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            children: [
              // Sliding Active Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                left: _calculateIndicatorLeft(navWidth - 16, items.length, currentIndex),
                top: 18,
                child: Container(
                  width: 56,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.brandLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              // Nav Items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isActive = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(index),
                      child: Container(
                        height: 64,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(opacity: animation, child: child),
                              child: PhosphorIcon(
                                isActive ? item.selectedIcon : item.icon,
                                key: ValueKey(isActive),
                                size: 24,
                                color: isActive ? AppColors.brand : AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 10,
                                  color: isActive ? AppColors.brand : AppColors.textTertiary,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                ),
                                child: Text(item.label),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  double _calculateIndicatorLeft(double availableWidth, int itemCount, int currentIndex) {
    if (itemCount == 0) return 0;
    final itemWidth = availableWidth / itemCount;
    // Center the 56px indicator within the item's width
    return (currentIndex * itemWidth) + (itemWidth / 2) - 28;
  }
}
