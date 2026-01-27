import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/learning_repository.dart';
import '../data/models/learning_path_model.dart';
import '../data/models/resource_model.dart';
import 'auth_provider.dart';
import 'api_provider.dart'; // Import shared api provider

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
  final LearningRepository _learningRepository;

  LearningProgressNotifier(this._learningRepository) : super(false);

  Future<void> completeLesson(String pathId, int lessonNumber, int moduleNumber) async {
    state = true;
    try {
      await _learningRepository.completeLesson(pathId, lessonNumber, moduleNumber);
    } finally {
      state = false;
    }
  }

  Future<void> updateProgress(String pathId, double progress) async {
    state = true;
    try {
      await _learningRepository.updateProgress(pathId, progress);
    } finally {
      state = false;
    }
  }
}

/// Learning progress provider
final learningProgressProvider =
    StateNotifierProvider<LearningProgressNotifier, bool>((ref) {
  final learningRepo = ref.watch(learningRepositoryProvider);
  return LearningProgressNotifier(learningRepo);
});
