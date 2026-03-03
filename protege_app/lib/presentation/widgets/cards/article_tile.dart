import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';

/// Article list item with thumbnail, title, source, and reading time.
class ArticleTile extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final String? sourceName;
  final String? readingTime;
  final String? articleUrl;

  const ArticleTile({
    super.key,
    required this.title,
    this.thumbnailUrl,
    this.sourceName,
    this.readingTime,
    this.articleUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: () {
        if (articleUrl != null) {
          launchUrl(Uri.parse(articleUrl!), mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                image: thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: thumbnailUrl == null
                  ? const Center(
                      child: Icon(
                        Icons.article_rounded,
                        color: AppColors.blue,
                        size: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (sourceName != null)
                        Flexible(
                          child: Text(
                            sourceName!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (readingTime != null) ...[
                        if (sourceName != null)
                          Text(' · ', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                        const Icon(Icons.schedule_rounded, size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Text(readingTime!, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
