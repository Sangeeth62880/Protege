import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

/// Uppercase colored category label (e.g., "LEARNING PATH • 8 MODULES").
class CategoryLabel extends StatelessWidget {
  final String text;
  final Color color;

  const CategoryLabel({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelCategory.copyWith(color: color),
    );
  }
}
