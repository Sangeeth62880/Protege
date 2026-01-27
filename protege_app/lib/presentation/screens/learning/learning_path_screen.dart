import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/learning_provider.dart';
import '../../../data/models/learning_path_model.dart';
import '../../widgets/cards/lesson_card.dart';

/// Learning path detail screen
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
          ? FloatingActionButton.extended(
              onPressed: () {
                final path = pathAsync.valueOrNull!;
                // Collect all key concepts
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
            )
          : null,
    );
  }
}

class _PathContent extends StatelessWidget {
  final LearningPathModel path;

  const _PathContent({required this.path});

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
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              path.topic,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
        // Progress section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: path.progress,
                              minHeight: 8,
                              backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(path.progress * 100).toInt()}%',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Description
                Text(
                  path.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                // Lessons header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lessons (${path.lessons.length})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Chip(
                      label: Text(
                        path.difficulty[0].toUpperCase() + path.difficulty.substring(1),
                      ),
                      backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Lessons list
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lesson = path.lessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LessonCard(
                    lesson: lesson,
                    index: index + 1,
                    onTap: () => context.push('/learn/${path.id}/lesson/${lesson.lessonNumber}'),
                    onQuizTap: lesson.quizId != null
                        ? () => context.push('/quiz/${lesson.quizId}')
                        : null,
                    onTeachTap: () => context.push('/teaching/${lesson.id}'),
                  ),
                );
              },
              childCount: path.lessons.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}
