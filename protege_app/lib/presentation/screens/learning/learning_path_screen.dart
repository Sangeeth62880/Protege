import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/learning_provider.dart';
import '../../../data/models/learning_path_model.dart';

/// Learning path detail screen — shows modules, lessons, progress
class LearningPathScreen extends ConsumerWidget {
  final String learningPathId;

  const LearningPathScreen({super.key, required this.learningPathId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathAsync = ref.watch(learningPathProvider(learningPathId));

    return Scaffold(
      body: pathAsync.when(
        data: (path) {
          if (path == null) {
            return const Center(child: Text('Learning path not found'));
          }
          return _PathContent(path: path);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: pathAsync.valueOrNull != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 4),
              child: FloatingActionButton.extended(
                onPressed: () {
                  final path = pathAsync.valueOrNull!;
                  final allConcepts = path.lessons
                      .expand((l) => l.keyConcepts)
                      .toSet()
                      .toList();

                  context.push(
                    '/tutor',
                    extra: {
                      'topic': path.topic,
                      'lessonTitle': 'General Help',
                      'keyConcepts': allConcepts,
                      'experienceLevel': path.difficulty,
                    },
                  );
                },
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('AI Tutor'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            )
          : null,
    );
  }
}

class _PathContent extends StatelessWidget {
  final LearningPathModel path;

  const _PathContent({required this.path});

  int get _totalLessons => path.lessons.length;
  int get _completedLessons => path.lessons.where((l) => l.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              path.topic,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.warmGradient,
              ),
              child: SafeArea(
                child: Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Overall progress section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar with count
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_completedLessons of $_totalLessons lessons completed',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _totalLessons > 0
                                  ? _completedLessons / _totalLessons
                                  : 0,
                              minHeight: 8,
                              backgroundColor:
                                  AppColors.textLight.withValues(alpha: 0.2),
                              valueColor:
                                  const AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(_totalLessons > 0 ? (_completedLessons / _totalLessons * 100) : 0).toInt()}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  path.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    path.difficulty[0].toUpperCase() +
                        path.difficulty.substring(1),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.accent),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),

        // Modules with lessons grouped
        ...path.modules.expand((module) => [
              // Module header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _ModuleHeader(module: module),
                ),
              ),
              // Lessons in this module
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final lesson = module.lessons[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LessonTile(
                          lesson: lesson,
                          module: module,
                          path: path,
                        ),
                      );
                    },
                    childCount: module.lessons.length,
                  ),
                ),
              ),
            ]),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

/// Module section header with progress
class _ModuleHeader extends StatelessWidget {
  final ModuleModel module;

  const _ModuleHeader({required this.module});

  int get _completedInModule =>
      module.lessons.where((l) => l.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final allDone = _completedInModule == module.lessons.length &&
        module.lessons.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: allDone
            ? AppColors.successLight
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allDone
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: allDone ? AppColors.success : AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: allDone
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${module.moduleNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_completedInModule / ${module.lessons.length} lessons',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // Mini progress indicator
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: module.lessons.isNotEmpty
                  ? _completedInModule / module.lessons.length
                  : 0,
              strokeWidth: 3,
              backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(
                allDone ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual lesson tile with completion indicator
class _LessonTile extends StatelessWidget {
  final LessonModel lesson;
  final ModuleModel module;
  final LearningPathModel path;

  const _LessonTile({
    required this.lesson,
    required this.module,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          '/learn/${path.id}/module/${module.moduleNumber}/lesson/${lesson.lessonNumber}',
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lesson.isCompleted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              // Completion indicator
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: lesson.isCompleted
                      ? AppColors.success
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: lesson.isCompleted
                        ? AppColors.success
                        : AppColors.textTertiary,
                    width: 2,
                  ),
                ),
                child: lesson.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Center(
                        child: Text(
                          '${lesson.lessonNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Title & description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            decoration: lesson.isCompleted
                                ? TextDecoration.none
                                : null,
                          ),
                    ),
                    if (lesson.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Duration badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lesson.durationMinutes} min',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
