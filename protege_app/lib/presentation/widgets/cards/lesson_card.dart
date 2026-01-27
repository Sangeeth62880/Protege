import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/learning_path_model.dart';

/// Lesson card widget
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: lesson.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.textLight.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Lesson number
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: lesson.isCompleted
                          ? AppColors.success
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: lesson.isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '$index',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Lesson info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: lesson.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              // Action buttons
              if (lesson.isCompleted || onQuizTap != null || onTeachTap != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (lesson.videoResourceIds.isNotEmpty || lesson.articleResourceIds.isNotEmpty)
                      _ActionChip(
                        icon: Icons.link,
                        label: '${lesson.videoResourceIds.length + lesson.articleResourceIds.length} resources',
                        onTap: onTap,
                      ),
                    const SizedBox(width: 8),
                    if (onQuizTap != null)
                      _ActionChip(
                        icon: Icons.quiz_outlined,
                        label: 'Quiz',
                        onTap: onQuizTap!,
                        color: AppColors.info,
                      ),
                    const SizedBox(width: 8),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: chipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
