import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/lesson_content_model.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/auth_provider.dart';
import 'tabs/learn_tab.dart';
import 'tabs/videos_tab.dart';
import 'tabs/articles_tab.dart';
import 'tabs/practice_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/more_resources_tab.dart';

/// Lesson detail screen with structured Tab-based layout
class LessonScreen extends ConsumerStatefulWidget {
  final String pathId;
  final int moduleId;  // Module number
  final int lessonId;  // Lesson number within the module

  const LessonScreen({
    super.key,
    required this.pathId,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
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
          final queries = <String, String>{};
          if (lesson.searchQueries != null) {
            queries.addAll(lesson.searchQueries!);
          } else {
            queries['youtube'] = '${path.topic} ${lesson.title} tutorial';
            queries['articles'] = '${path.topic} ${lesson.title} guide explained';
            queries['github'] = '${path.topic} ${lesson.title} examples code';
          }
          ref.read(resourceProvider('${path.topic}_${lesson.title}').notifier).loadResources(
            topic: path.topic,
            searchQueries: queries,
          );
        }
      }
    });
  }

  ModuleModel? _findModule(LearningPathModel path) {
    try {
      return path.modules.firstWhere((m) => m.moduleNumber == widget.moduleId);
    } catch (_) {
      return null;
    }
  }

  LessonModel? _findLesson(LearningPathModel path) {
    final module = _findModule(path);
    if (module == null) return null;
    try {
      return module.lessons.firstWhere((l) => l.lessonNumber == widget.lessonId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _completeLesson(LearningPathModel path, LessonModel lesson) async {
    if (_isCompleting || lesson.isCompleted) return;
    setState(() => _isCompleting = true);

    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.uid ?? '';

      final repo = ref.read(learningRepositoryProvider);
      await repo.completeLessonViaApi(
        pathId: widget.pathId,
        moduleNumber: widget.moduleId,
        lessonNumber: widget.lessonId,
        userId: userId,
      );

      // Invalidate the path provider so it refetches with updated completion state
      ref.invalidate(learningPathProvider(widget.pathId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${lesson.title} completed! +50 XP'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark complete: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathAsync = ref.watch(learningPathProvider(widget.pathId));

    return pathAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (path) {
        if (path == null) return const Scaffold(body: Center(child: Text('Path not found')));
        
        final module = _findModule(path);
        final lesson = _findLesson(path);
        if (lesson == null || module == null) {
          return const Scaffold(body: Center(child: Text('Lesson not found')));
        }

        final resourceState = ref.watch(resourceProvider('${path.topic}_${lesson.title}'));

        // Build the lesson content params for AI generation
        final contentParams = LessonContentParams(
          pathId: widget.pathId,
          topic: path.topic,
          moduleTitle: module.title,
          lessonTitle: lesson.title,
          lessonDescription: lesson.description,
          keyConcepts: lesson.keyConcepts,
          difficulty: path.difficulty,
          moduleNumber: widget.moduleId,
          lessonNumber: widget.lessonId,
        );

        final lessonContentAsync = ref.watch(lessonContentProvider(contentParams));

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (path.topic.isNotEmpty)
                    Text(
                      '${path.topic} · Module ${module.moduleNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: 'Learn'),
                  Tab(text: 'Videos'),
                  Tab(text: 'Articles'),
                  Tab(text: 'Practice'),
                  Tab(text: 'Notes'),
                  Tab(text: 'More'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'quiz') {
                       context.push(
                        '/quiz/${lesson.id}',
                        extra: {
                          'topic': path.topic,
                          'lessonTitle': lesson.title,
                        }
                      );
                    } else if (value == 'teach') {
                       context.push('/teaching/${lesson.id}');
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'quiz',
                        child: Row(
                          children: [
                            Icon(Icons.quiz_outlined, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text('Take Quiz'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'teach',
                        child: Row(
                          children: [
                            Icon(Icons.psychology_outlined, color: AppColors.textPrimary),
                            SizedBox(width: 8),
                            Text('Teach Mode'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            body: TabBarView(
              children: [
                // Learn Tab — uses AI-generated content
                lessonContentAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating lesson content...'),
                        SizedBox(height: 8),
                        Text(
                          'This may take a moment',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Failed to load: $err', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(lessonContentProvider(contentParams)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (contentJson) {
                    final explanation = LessonExplanation.fromJson(contentJson);
                    return LearnTab(
                      explanation: explanation,
                      wikipedia: resourceState.resources?.wikipedia,
                    );
                  },
                ),

                // Videos Tab
                resourceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : VideosTab(videos: resourceState.resources?.videos ?? []),

                // Articles Tab
                resourceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ArticlesTab(articles: resourceState.resources?.articles ?? []),

                // Practice Tab
                resourceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PracticeTab(repositories: resourceState.resources?.repositories ?? []),

                // Notes Tab
                NotesTab(
                  pathId: widget.pathId,
                  moduleId: widget.moduleId,
                  lessonId: widget.lessonId,
                ),

                // More Resources Tab
                resourceState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : MoreResourcesTab(
                        books: resourceState.resources?.books ?? [],
                        questions: resourceState.resources?.questions ?? [],
                        courses: resourceState.resources?.courses ?? [],
                        docs: resourceState.resources?.docs ?? [],
                      ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                         context.push(
                          '/quiz/${lesson.id}',
                          extra: {
                            'topic': path.topic,
                            'lessonTitle': lesson.title,
                          }
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Take Quiz'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: lesson.isCompleted || _isCompleting
                          ? null
                          : () => _completeLesson(path, lesson),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lesson.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.success.withValues(alpha: 0.8),
                        disabledForegroundColor: Colors.white,
                      ),
                      child: _isCompleting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              lesson.isCompleted
                                  ? '✓ Completed'
                                  : 'Complete Lesson',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
