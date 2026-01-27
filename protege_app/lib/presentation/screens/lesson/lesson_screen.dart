import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/resource_models.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/resource_provider.dart';
import '../../widgets/resources/video_resource_card.dart';
import '../../widgets/resources/article_resource_card.dart';
import '../../widgets/resources/github_resource_card.dart';
import '../../widgets/common/loading_indicator.dart'; // Assume exists or use CircularProgressIndicator
import '../../widgets/common/error_display.dart'; // Assume exists or use Text

/// Lesson detail screen with Curated Resources
class LessonScreen extends ConsumerStatefulWidget {
  final String pathId;
  final int lessonId; // Mapped to lessonNumber

  const LessonScreen({
    super.key,
    required this.pathId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    // Defer resource loading until we have the lesson details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResourcesIfReady();
    });
  }

  void _loadResourcesIfReady() {
    final pathAsync = ref.read(learningPathProvider(widget.pathId));
    pathAsync.whenData((path) {
      if (path != null) {
        final lesson = _findLesson(path);
        if (lesson != null) {
          // Trigger resource loading
          final queries = <String, String>{};
          
          if (lesson.searchQueries != null) {
            queries.addAll(lesson.searchQueries!);
          } else {
             // Fallback generation if no queries
             queries['youtube'] = '${lesson.title} tutorial beginner';
             queries['articles'] = '${lesson.title} explained';
             queries['github'] = '${lesson.title} examples';
          }

          ref.read(resourceProvider(lesson.title).notifier).loadResources(
            searchQueries: queries,
          );
        }
      }
    });
  }

  LessonModel? _findLesson(LearningPathModel path) {
    try {
      return path.lessons.firstWhere((l) => l.lessonNumber == widget.lessonId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathAsync = ref.watch(learningPathProvider(widget.pathId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: pathAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (path) {
          if (path == null) return const Center(child: Text('Path not found'));
          
          final lesson = _findLesson(path);
          if (lesson == null) return const Center(child: Text('Lesson not found'));

          final resourceState = ref.watch(resourceProvider(lesson.title));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lesson Header
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Key Concepts
                if (lesson.keyConcepts.isNotEmpty) ...[
                  Text(
                    'Key Concepts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lesson.keyConcepts.map((concept) => Chip(
                      label: Text(concept),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: AppColors.primary),
                      side: BorderSide.none,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Resources Section
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Curated Resources',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Resources Content
                if (resourceState.isLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ))
                else if (resourceState.error != null)
                  Center(child: Text('Could not load resources: ${resourceState.error}'))
                else if (resourceState.resources != null)
                  _buildResourceList(resourceState.resources!)
                else
                  // Trigger load if state is empty but no error/loading (should imply init triggered it)
                  const Center(child: CircularProgressIndicator()), // Or 'No resources found'
                  
                const SizedBox(height: 40),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: lesson.quizId != null 
                            ? () => context.push('/quiz/${lesson.quizId}') 
                            : null, // Disable if no quiz
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text('Take Quiz'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                           // Navigate to Teach Mode
                           context.push('/teaching/${lesson.id}'); // ID compatibility?
                        },
                        icon: const Icon(Icons.psychology_rounded),
                        label: const Text('Teach Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResourceList(LessonResources resources) {
    if (resources.totalCount == 0 && resources.wikipedia == null) {
      return const Center(child: Text('No external resources found for this lesson.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wikipedia Summary (Foundation)
        if (resources.wikipedia != null) ...[
          Card(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, size: 20, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(
                        resources.wikipedia!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resources.wikipedia!.description, // Actually 'extract' in model? 
                    // Model maps json['extract'] to description. Correct.
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Videos
        if (resources.videos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Videos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...resources.videos.map((v) => VideoResourceCard(video: v)),
          const SizedBox(height: 16),
        ],

        // Articles
        if (resources.articles.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...resources.articles.map((a) => ArticleResourceCard(article: a)),
          const SizedBox(height: 16),
        ],

        // Repositories
        if (resources.repositories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Code Examples', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...resources.repositories.map((r) => GithubResourceCard(repo: r)),
        ],
      ],
    );
  }
}
