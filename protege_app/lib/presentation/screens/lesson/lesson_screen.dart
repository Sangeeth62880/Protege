import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/learning_path_model.dart';
import '../../../data/models/lesson_content_model.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import 'tabs/learn_tab.dart';
import 'tabs/videos_tab.dart';
import 'tabs/articles_tab.dart';
import 'tabs/practice_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/more_resources_tab.dart';

/// Lesson detail screen with structured Tab-based layout
class LessonScreen extends ConsumerStatefulWidget {
  final String pathId;
  final int moduleId;
  final int lessonId;

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
    _loadResourcesIfReady();
  }

  void _loadResourcesIfReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pathAsync = ref.read(learningPathProvider(widget.pathId));
      pathAsync.whenData((path) {
        if (path == null) return;
        final lesson = _findLesson(path);
        if (lesson != null) {
          final query = '${path.topic}_${lesson.title}';
          final searchQueries = lesson.searchQueries ?? {
            'youtube': '${path.topic} ${lesson.title} tutorial',
            'articles': '${path.topic} ${lesson.title} explained',
            'github': '${path.topic} ${lesson.title} examples',
          };
          ref.read(resourceProvider(query).notifier).loadResources(
            topic: path.topic,
            searchQueries: searchQueries,
          );
        }
      });
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

  /// Enhanced complete lesson — delegates to learningProgressProvider
  Future<void> _completeLesson(LearningPathModel path, LessonModel lesson) async {
    if (_isCompleting || lesson.isCompleted) return;
    setState(() => _isCompleting = true);

    try {
      final user = ref.read(currentUserProvider);
      final userId = user?.uid ?? '';

      await ref.read(learningProgressProvider.notifier).completeLesson(
        widget.pathId,
        widget.lessonId,
        widget.moduleId,
        userId,
      );

      if (mounted) {
        _showCelebrationOverlay(path, lesson);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark complete: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  _NextLessonInfo? _getNextLesson(LearningPathModel path, LessonModel currentLesson) {
    bool foundCurrent = false;
    for (var module in path.modules) {
      for (var lesson in module.lessons) {
        if (foundCurrent) {
          return _NextLessonInfo(module.moduleNumber, lesson.lessonNumber, lesson.title);
        }
        if (lesson.lessonNumber == currentLesson.lessonNumber && module.moduleNumber == widget.moduleId) {
          foundCurrent = true;
        }
      }
    }
    return null;
  }

  void _showCelebrationOverlay(LearningPathModel path, LessonModel currentLesson) {
    final nextLesson = _getNextLesson(path, currentLesson);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LessonCompleteCelebration(
        xpEarned: 50,
        nextLessonTitle: nextLesson?.title,
        onNext: () {
          Navigator.pop(context); // close sheet
          if (nextLesson != null) {
            context.go('/learn/${widget.pathId}/module/${nextLesson.moduleId}/lesson/${nextLesson.lessonId}');
          } else {
            context.go('/learn/${widget.pathId}');
          }
        },
        onBackToPath: () {
          Navigator.pop(context);
          context.go('/learn/${widget.pathId}');
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final pathAsync = ref.watch(learningPathProvider(widget.pathId));

    return pathAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.brand),
              const SizedBox(height: AppSpacing.lg),
              Text('Loading lesson...', style: AppTypography.bodyMd),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: $err', style: AppTypography.bodyMd)),
      ),
      data: (path) {
        if (path == null) return Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('Path not found', style: AppTypography.bodyMd)));

        final module = _findModule(path);
        final lesson = _findLesson(path);
        if (lesson == null || module == null) {
          return Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('Lesson not found', style: AppTypography.bodyMd)));
        }

        final resourceState = ref.watch(resourceProvider('${path.topic}_${lesson.title}'));
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


          final nextLesson = _getNextLesson(path, lesson);

          return DefaultTabController(
            length: 6,
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                leading: IconButton(
                  icon: PhosphorIcon(PhosphorIcons.arrowLeft(), size: 22),
                  onPressed: () => context.pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: AppTypography.headingSm),
                    Text(
                      '${path.topic} · Module ${module.moduleNumber}',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
                bottom: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.brand,
                  labelColor: AppColors.brand,
                  unselectedLabelColor: AppColors.textTertiary,
                  labelStyle: AppTypography.headingSm.copyWith(fontSize: 14),
                  unselectedLabelStyle: AppTypography.bodyMd.copyWith(fontSize: 14),
                  tabs: const [
                    Tab(text: 'Learn'),
                    Tab(text: 'Videos'),
                    Tab(text: 'Articles'),
                    Tab(text: 'Practice'),
                    Tab(text: 'Notes'),
                    Tab(text: 'More'),
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: PhosphorIcon(PhosphorIcons.dotsThreeVertical(), size: 22),
                    onSelected: (value) {
                      if (value == 'quiz') {
                        context.push('/quiz/${lesson.id}', extra: {
                          'topic': path.topic,
                          'lessonTitle': lesson.title,
                        });
                      } else if (value == 'teach') {
                        context.push('/teaching/${lesson.id}');
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'quiz',
                        child: Row(children: [
                          PhosphorIcon(PhosphorIcons.exam(), size: 18),
                          const SizedBox(width: 8),
                          const Text('Take Quiz'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'teach',
                        child: Row(children: [
                          PhosphorIcon(PhosphorIcons.brain(), size: 18),
                          const SizedBox(width: 8),
                          const Text('Teach Mode'),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  // Learn Tab
                  lessonContentAsync.when(
                    loading: () => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.brand),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Generating lesson...', style: AppTypography.bodyMd),
                          const SizedBox(height: AppSpacing.sm),
                          Text('This may take a moment', style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PhosphorIcon(PhosphorIcons.warning(), size: 48, color: AppColors.error),
                          const SizedBox(height: AppSpacing.lg),
                          Text('Failed to load: $err', textAlign: TextAlign.center, style: AppTypography.bodyMd),
                          const SizedBox(height: AppSpacing.lg),
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
                      ? Center(child: CircularProgressIndicator(color: AppColors.brand))
                      : VideosTab(videos: resourceState.resources?.videos ?? []),
                  // Articles Tab
                  resourceState.isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.brand))
                      : ArticlesTab(articles: resourceState.resources?.articles ?? []),
                  // Practice Tab
                  resourceState.isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.brand))
                      : PracticeTab(repositories: resourceState.resources?.repositories ?? []),
                  // Notes Tab
                  NotesTab(pathId: widget.pathId, moduleId: widget.moduleId, lessonId: widget.lessonId),
                  // More Resources Tab
                  resourceState.isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.brand))
                      : MoreResourcesTab(
                          textbooks: resourceState.resources?.textbooks ?? [],
                          books: resourceState.resources?.books ?? [],
                          questions: resourceState.resources?.questions ?? [],
                          courses: resourceState.resources?.courses ?? [],
                          docs: resourceState.resources?.docs ?? [],
                        ),
                ],
              ),
              bottomNavigationBar: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg + AppSpacing.navbarClearance,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Take Quiz',
                          onPressed: () => context.push('/quiz/${lesson.id}', extra: {
                            'topic': path.topic,
                            'lessonTitle': lesson.title,
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: lesson.isCompleted 
                              ? (nextLesson != null ? 'Next: ${nextLesson.title}' : 'Path Complete') 
                              : 'Complete Lesson',
                          onPressed: lesson.isCompleted 
                              ? () {
                                  if (nextLesson != null) {
                                    context.go('/learn/${widget.pathId}/module/${nextLesson.moduleId}/lesson/${nextLesson.lessonId}');
                                  } else {
                                    context.go('/learn/${widget.pathId}');
                                  }
                                }
                              : () => _completeLesson(path, lesson),
                          isLoading: _isCompleting,
                          isDisabled: false,
                          icon: lesson.isCompleted ? PhosphorIcons.arrowRight(PhosphorIconsStyle.bold) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
}

class _NextLessonInfo {
  final int moduleId;
  final int lessonId;
  final String title;
  _NextLessonInfo(this.moduleId, this.lessonId, this.title);
}

class _LessonCompleteCelebration extends StatelessWidget {
  final int xpEarned;
  final String? nextLessonTitle;
  final VoidCallback onNext;
  final VoidCallback onBackToPath;

  const _LessonCompleteCelebration({
    required this.xpEarned,
    this.nextLessonTitle,
    required this.onNext,
    required this.onBackToPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xxl),
          topRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                  color: AppColors.success,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Lesson Completed!',
              style: AppTypography.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '+$xpEarned XP earned for your progress',
              style: AppTypography.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            PrimaryButton(
              label: nextLessonTitle != null ? 'Next: $nextLessonTitle' : 'Path Complete',
              onPressed: onNext,
              icon: nextLessonTitle != null ? PhosphorIcons.arrowRight(PhosphorIconsStyle.bold) : PhosphorIcons.flag(PhosphorIconsStyle.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Back to Learning Path',
              onPressed: onBackToPath,
            ),
          ],
        ),
      ),
    );
  }
}
