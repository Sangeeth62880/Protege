import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/learning_repository.dart';
import '../data/models/learning_path_model.dart';
import '../data/models/resource_model.dart';
import 'auth_provider.dart';
import 'api_provider.dart'; // Import shared api provider

// Imports for user repository and dashboard updates
import 'user_provider.dart';
import 'dashboard_provider.dart';
import '../data/models/dashboard_models.dart';

/// Learning repository provider
final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return LearningRepository(
    firebaseService: firebaseService,
    apiService: apiService,
  );
});

/// User's learning paths provider
final userLearningPathsProvider =
    FutureProvider<List<LearningPathModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getUserLearningPaths(currentUser.uid);
});

/// Learning paths stream for real-time updates
final learningPathsStreamProvider =
    StreamProvider<List<LearningPathModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return Stream.value([]);
  }

  final learningRepo = ref.watch(learningRepositoryProvider);
  return learningRepo.streamUserLearningPaths(currentUser.uid);
});

/// Single learning path provider
final learningPathProvider =
    FutureProvider.family<LearningPathModel?, String>((ref, pathId) async {
  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getLearningPath(pathId);
});

/// Learning path generation state (Two Step: Generate -> Preview -> Save)
class SyllabusGeneratorNotifier extends StateNotifier<AsyncValue<SyllabusModel?>> {
  final LearningRepository _learningRepository;

  SyllabusGeneratorNotifier(this._learningRepository)
      : super(const AsyncValue.data(null));

  /// Generate a syllabus preview
  Future<SyllabusModel?> generateSyllabus({
    required String topic,
    required String goal,
    required String difficulty,
    required int dailyMinutes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final syllabus = await _learningRepository.generateSyllabus(
        topic: topic,
        goal: goal,
        difficulty: difficulty,
        duration: dailyMinutes,
      );
      print('[SyllabusGenerator] Success: ${syllabus.topic}');
      state = AsyncValue.data(syllabus);
      return syllabus;
    } catch (e, st) {
      print('[SyllabusGenerator] Error: $e');
      print(st);
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Syllabus generator provider
final syllabusGeneratorProvider = StateNotifierProvider<
    SyllabusGeneratorNotifier, AsyncValue<SyllabusModel?>>((ref) {
  final learningRepo = ref.watch(learningRepositoryProvider);
  return SyllabusGeneratorNotifier(learningRepo);
});

/// Save syllabus and convert to LearningPath
class SaveSyllabusNotifier extends StateNotifier<AsyncValue<LearningPathModel?>> {
  final LearningRepository _learningRepository;

  SaveSyllabusNotifier(this._learningRepository)
      : super(const AsyncValue.data(null));

  Future<LearningPathModel?> save(SyllabusModel syllabus) async {
    state = const AsyncValue.loading();
    try {
      final path = await _learningRepository.saveLearningPath(syllabus);
      state = AsyncValue.data(path);
      return path;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Save syllabus provider
final saveSyllabusProvider = StateNotifierProvider<
    SaveSyllabusNotifier, AsyncValue<LearningPathModel?>>((ref) {
  final learningRepo = ref.watch(learningRepositoryProvider);
  return SaveSyllabusNotifier(learningRepo);
});

// Legacy provider for backward compatibility (calls the new flow internally)
class LearningPathGeneratorNotifier
    extends StateNotifier<AsyncValue<LearningPathModel?>> {
  final LearningRepository _learningRepository;
  final String? _userId;

  LearningPathGeneratorNotifier(this._learningRepository, this._userId)
      : super(const AsyncValue.data(null));

  // Deprecated: Use syllabusGeneratorProvider + saveSyllabusProvider instead
  Future<LearningPathModel?> generatePath({
    required String topic,
    required String difficulty,
  }) async {
    if (_userId == null) return null;
    state = const AsyncValue.loading();
    try {
      // Generate syllabus first
      final syllabus = await _learningRepository.generateSyllabus(
        topic: topic,
        goal: "Learn $topic", // Default goal
        difficulty: difficulty,
        duration: 30, // Default 30 minutes
      );
      // Then save immediately
      final path = await _learningRepository.saveLearningPath(syllabus);
      state = AsyncValue.data(path);
      return path;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Legacy learning path generator provider
final learningPathGeneratorProvider = StateNotifierProvider<
    LearningPathGeneratorNotifier, AsyncValue<LearningPathModel?>>((ref) {
  final learningRepo = ref.watch(learningRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return LearningPathGeneratorNotifier(learningRepo, currentUser?.uid);
});

/// Resource search state
class ResourceSearchNotifier
    extends StateNotifier<AsyncValue<List<ResourceModel>>> {
  final LearningRepository _learningRepository;

  ResourceSearchNotifier(this._learningRepository)
      : super(const AsyncValue.data([]));

  Future<void> search(String query, {String? source}) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final resources = await _learningRepository.searchResources(
        query: query,
        source: source,
      );
      state = AsyncValue.data(resources);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

/// Resource search provider
final resourceSearchProvider =
    StateNotifierProvider<ResourceSearchNotifier, AsyncValue<List<ResourceModel>>>(
        (ref) {
  final learningRepo = ref.watch(learningRepositoryProvider);
  return ResourceSearchNotifier(learningRepo);
});

/// Learning progress updater
class LearningProgressNotifier extends StateNotifier<bool> {
  final Ref _ref;

  LearningProgressNotifier(this._ref) : super(false);

  Future<void> completeLesson(
    String pathId,
    int lessonNumber,
    int moduleNumber,
    String userId,
  ) async {
    state = true;
    try {
      final learningRepo = _ref.read(learningRepositoryProvider);
      final userRepo = _ref.read(userRepositoryProvider);

      // 1. Mark lesson as completed in path
      final updatedPath = await learningRepo.completeLesson(pathId, lessonNumber, moduleNumber);

      if (updatedPath != null) {
        // Find the completed lesson title for the activity log
        String lessonTitle = 'a lesson';
        String moduleTitle = 'Module';
        for (var m in updatedPath.modules) {
          if (m.moduleNumber == moduleNumber) {
            moduleTitle = m.title;
            for (var l in m.lessons) {
              if (l.lessonNumber == lessonNumber) {
                lessonTitle = l.title;
                break;
              }
            }
            break;
          }
        }

        // 2. Increment user stats (XP + Lessons Completed)
        await userRepo.incrementStats(
          userId,
          lessonsCompleted: 1,
          xp: 50,
        );

        // 3. Update the user streak
        await userRepo.updateStreak(userId);

        // 4. Log the activity event
        final activityEvent = ActivityEvent(
          id: '', // Generated by Firestore
          type: 'lesson_completed',
          title: '$lessonTitle',
          pathId: pathId,
          lessonId: lessonNumber.toString(),
          timestamp: DateTime.now(),
          meta: {
            'module_title': moduleTitle,
            'path_title': updatedPath.topic,
            'xp': 50,
          },
        );
        await learningRepo.logActivity(userId, activityEvent);

        // 5. Invalidate dependent providers to force UI refresh
        _ref.invalidate(learningPathProvider(pathId));
        _ref.invalidate(userStreamProvider);
        _ref.invalidate(userDataProvider);
        _ref.invalidate(continueLearningProvider);
        _ref.invalidate(recentActivityProvider);
        _ref.invalidate(pathProgressProvider);
        _ref.invalidate(weeklyStatsProvider);
      }
    } finally {
      state = false;
    }
  }

  Future<void> updateProgress(String pathId, double progress) async {
    state = true;
    try {
      await _ref.read(learningRepositoryProvider).updateProgress(pathId, progress);
    } finally {
      state = false;
    }
  }
}

/// Learning progress provider
final learningProgressProvider =
    StateNotifierProvider<LearningProgressNotifier, bool>((ref) {
  return LearningProgressNotifier(ref);
});

// ─── Lesson Content Provider ─────────────────────────────────────────────

/// Params for lesson content generation
class LessonContentParams {
  final String pathId;
  final String topic;
  final String moduleTitle;
  final String lessonTitle;
  final String lessonDescription;
  final List<String> keyConcepts;
  final String difficulty;
  final int moduleNumber;
  final int lessonNumber;

  const LessonContentParams({
    required this.pathId,
    required this.topic,
    required this.moduleTitle,
    required this.lessonTitle,
    this.lessonDescription = '',
    this.keyConcepts = const [],
    this.difficulty = 'beginner',
    required this.moduleNumber,
    required this.lessonNumber,
  });

  /// Unique key for provider caching
  String get key => '${pathId}_${moduleNumber}_$lessonNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonContentParams && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Provider that fetches AI-generated lesson content (with Firestore cache on backend)
final lessonContentProvider = FutureProvider.family<Map<String, dynamic>, LessonContentParams>(
  (ref, params) async {
    final learningRepo = ref.watch(learningRepositoryProvider);
    return await learningRepo.generateLessonContent(
      topic: params.topic,
      moduleTitle: params.moduleTitle,
      lessonTitle: params.lessonTitle,
      lessonDescription: params.lessonDescription,
      keyConcepts: params.keyConcepts,
      difficulty: params.difficulty,
      pathId: params.pathId,
      moduleNumber: params.moduleNumber,
      lessonNumber: params.lessonNumber,
    );
  },
);
