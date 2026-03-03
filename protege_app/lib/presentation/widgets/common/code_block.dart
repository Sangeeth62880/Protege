import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Dark code display widget with language badge and copy button.
class CodeBlock extends StatelessWidget {
  final String code;
  final String language;

  const CodeBlock({
    super.key,
    required this.code,
    this.language = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: language badge + copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusMedium),
                topRight: Radius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                if (language.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      language.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              code,
              style: AppTypography.codeLarge,
            ),
          ),
        ],
      ),
    );
  }
}
