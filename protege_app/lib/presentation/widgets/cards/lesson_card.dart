import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/learning_path_model.dart';

/// Lesson card widget with consistent layout and accessible touch targets
class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onQuizTap;
  final VoidCallback? onTeachTap;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.index,
    required this.onTap,
    this.onQuizTap,
    this.onTeachTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: const Color(0x0F000000), // rgba(0,0,0,0.06) blur 8
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: lesson.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index badge — 44×44 touch target
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: lesson.isCompleted
                          ? AppColors.success
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: lesson.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '$index',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title + description — takes remaining width
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: lesson.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron — trailing aligned
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.chevron_right, size: 24, color: AppColors.textTertiary),
                  ),
                ],
              ),
              // Action buttons
              if (lesson.isCompleted || onQuizTap != null || onTeachTap != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (lesson.videoResourceIds.isNotEmpty || lesson.articleResourceIds.isNotEmpty)
                      _ActionChip(
                        icon: Icons.link,
                        label: '${lesson.videoResourceIds.length + lesson.articleResourceIds.length} resources',
                        onTap: onTap,
                      ),
                    if (onQuizTap != null)
                      _ActionChip(
                        icon: Icons.quiz_outlined,
                        label: 'Quiz',
                        onTap: onQuizTap!,
                        color: AppColors.info,
                      ),
                    if (onTeachTap != null)
                      _ActionChip(
                        icon: Icons.psychology_outlined,
                        label: 'Teach',
                        onTap: onTeachTap!,
                        color: AppColors.accent,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: chipColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: chipColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
