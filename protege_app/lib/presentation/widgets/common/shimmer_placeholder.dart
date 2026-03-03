import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_spacing.dart';

/// Shimmer loading placeholder — replaces CircularProgressIndicator for loading states.
class ShimmerPlaceholder extends StatelessWidget {
  final int lineCount;
  final double height;

  const ShimmerPlaceholder({
    super.key,
    this.lineCount = 3,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lineCount, (index) {
          final widthFraction = index == 0 ? 0.8 : (index == lineCount - 1 ? 0.4 : 0.6);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 14,
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * widthFraction,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Card-shaped shimmer placeholder matching typical card layouts.
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF0F0F0),
      highlightColor: const Color(0xFFFAFAFA),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
      ),
    );
  }
}
