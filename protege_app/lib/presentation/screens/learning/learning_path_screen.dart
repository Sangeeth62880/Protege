import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/learning_provider.dart';
import '../../../data/models/learning_path_model.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/animated_progress_bar.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Learning path screen — shows modules and lessons
class LearningPathScreen extends ConsumerWidget {
  final String pathId;
  const LearningPathScreen({super.key, required this.pathId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathFuture = ref.watch(learningPathProvider(pathId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(), size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: pathFuture.when(
        data: (path) {
          if (path == null) {
            return Center(child: Text('Path not found', style: AppTypography.bodyMd));
          }
          return _PathContent(path: path);
        },
        loading: () => Padding(
          padding: AppSpacing.screenH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 20),
              ShimmerLine(width: 200, height: 24),
              SizedBox(height: 12),
              ShimmerLine(width: 300, height: 16),
              SizedBox(height: 32),
              ShimmerCard(height: 80),
              SizedBox(height: 12),
              ShimmerCard(height: 80),
            ],
          ),
        ),
        error: (e, __) => Center(child: Text('Error: $e', style: AppTypography.bodyMd)),
      ),
    );
  }
}

class _PathContent extends StatelessWidget {
  final LearningPathModel path;
  const _PathContent({required this.path});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: AppSpacing.screenH.copyWith(top: 0, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          StaggeredItem(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(path.topic, style: AppTypography.displaySm),
                const SizedBox(height: AppSpacing.sm),
                Text(path.difficulty, style: AppTypography.labelSm.copyWith(color: AppColors.brand)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress
          StaggeredItem(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadow.sm,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: AppTypography.headingSm),
                      Text(
                        '${(path.progress * 100).toInt()}%',
                        style: AppTypography.headingSm.copyWith(color: AppColors.brand),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AnimatedProgressBar(progress: path.progress, fillColor: AppColors.brand),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          // Modules
          ...path.modules.asMap().entries.map((entry) {
            return StaggeredItem(
              index: 2 + entry.key,
              child: _ModuleSection(
                module: entry.value,
                pathId: path.id,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.navbarClearance),
        ],
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  final ModuleModel module;
  final String pathId;
  const _ModuleSection({required this.module, required this.pathId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: module.isCompleted ? AppColors.successLight : AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: module.isCompleted
                      ? PhosphorIcon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 14, color: AppColors.success)
                      : Text(
                          '${module.moduleNumber}',
                          style: AppTypography.headingSm.copyWith(fontSize: 13, color: AppColors.brand),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(module.title, style: AppTypography.headingMd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Lessons
          ...module.lessons.map((lesson) {
            return AnimatedPressable(
              onTap: () => context.push(
                '/learn/$pathId/module/${module.moduleNumber}/lesson/${lesson.lessonNumber}',
              ),
              child: Container(
                margin: const EdgeInsets.only(left: 40, bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: lesson.isCompleted ? AppColors.success.withAlpha(60) : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    PhosphorIcon(
                      lesson.isCompleted
                          ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                          : PhosphorIcons.playCircle(),
                      size: 20,
                      color: lesson.isCompleted ? AppColors.success : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        lesson.title,
                        style: AppTypography.bodyMd.copyWith(
                          color: lesson.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    PhosphorIcon(PhosphorIcons.caretRight(), size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
