import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/animated_pressable.dart';

/// YouTube video card with thumbnail, play icon overlay, and metadata.
class VideoCard extends StatelessWidget {
  final String title;
  final String? thumbnailUrl;
  final String? channelName;
  final String? duration;
  final String? viewCount;
  final String? videoUrl;

  const VideoCard({
    super.key,
    required this.title,
    this.thumbnailUrl,
    this.channelName,
    this.duration,
    this.viewCount,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: () {
        if (videoUrl != null) {
          launchUrl(Uri.parse(videoUrl!), mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with play overlay
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                image: thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  // Play icon overlay
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(217),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                  // Duration pill
                  if (duration != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground.withAlpha(200),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Text(
                          duration!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Title
          Text(
            title,
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Channel + views
          Row(
            children: [
              if (channelName != null)
                Flexible(
                  child: Text(
                    channelName!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (viewCount != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.visibility_rounded, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 3),
                Text(viewCount!, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
