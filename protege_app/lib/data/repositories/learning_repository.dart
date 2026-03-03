import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';
import '../models/learning_path_model.dart';
import '../models/resource_model.dart';
import '../models/dashboard_models.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Repository for learning path operations
class LearningRepository {
  final FirebaseService _firebaseService;
  final ApiService _apiService;

  LearningRepository({
    required FirebaseService firebaseService,
    required ApiService apiService,
  })  : _firebaseService = firebaseService,
        _apiService = apiService;

  /// Generate a syllabus (Preview) from Backend
  Future<SyllabusModel> generateSyllabus({
    required String topic,
    required String goal,
    required String difficulty,
    required int duration,
  }) async {
    try {
      print('DEBUG_SYLLABUS: [Repo] Sending request to /api/v1/learning/generate-syllabus-test');
      print('DEBUG_SYLLABUS: [Repo] Data: topic=$topic, goal=$goal, level=$difficulty');
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/learning/generate-syllabus-test', // TEMPORARY DEBUG: Bypass Auth
        data: {
          'topic': topic,
          'goal': goal,
          'experience_level': difficulty,
          'daily_time_minutes': duration,
        },
      );
      
      print('DEBUG_SYLLABUS: [Repo] Response status: ${response.statusCode}');
      
      return SyllabusModel.fromJson(response.data!);
    } catch (e) {
      print('DEBUG_SYLLABUS: [Repo] Error: $e');
      AppLogger.error('Failed to generate syllabus', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Save a syllabus as a permanent Learning Path
  Future<LearningPathModel> saveLearningPath(SyllabusModel syllabus) async {
    try {
      // We send the Syllabus JSON to the backend to be processed/saved
      // Note: Backend expects Syllabus structure
      // We need to convert SyllabusModel back to JSON
      final data = {
        'topic': syllabus.topic,
        'description': syllabus.description,
        'total_duration_hours': syllabus.totalDurationHours,
        'difficulty': syllabus.difficulty,
        'prerequisites': syllabus.prerequisites,
        'modules': syllabus.modules.map((m) => m.toJson()).toList(),
        'capstone_project': syllabus.capstoneProject?.toJson(),
      };

      final response = await _apiService.post<Map<String, dynamic>>(
         ApiConstants.savePathTest, // TEMPORARY DEBUG: Bypass Auth
         data: data,
      );
      
      final pathId = response.data!['id'];
      
      
      AppLogger.success('Learning path saved: $pathId', tag: 'LearningRepo');
      
      return LearningPathModel(
        id: pathId,
        userId: _firebaseService.currentUser?.uid ?? '',
        topic: syllabus.topic,
        description: syllabus.description,
        difficulty: syllabus.difficulty,
        modules: syllabus.modules,
        capstoneProject: syllabus.capstoneProject,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
    } catch (e) {
      AppLogger.error('Failed to save learning path', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Get learning paths for a user
  Future<List<LearningPathModel>> getUserLearningPaths(String userId) async {
    try {
      // Backend Endpoint for paths
      // Note: Using Backend API instead of direct Firestore is better if we want to abstract it
      // But Phase 1 used direct Firestore?
      // The current file code uses `_firebaseService.queryCollection`.
      // I will stick to Firebase Service if that's the Phase 1 pattern, 
      // BUT `LearningPathModel.fromJson` now expects snake_case from backend or camelCase?
      // My refactored Model handles both! Safe.
      
      final snapshot = await _firebaseService.queryCollection(
        'learning_paths',
        filters: [
          QueryFilter(field: 'user_id', isEqualTo: userId), // Backend saves as user_id (snake)
        ],
        orderBy: 'created_at',
        descending: true,
      );
      
      return snapshot.docs
          .map((doc) => LearningPathModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      // Fallback: try querying 'userId' (camelCase) if schema mixed
       try {
        final snapshot = await _firebaseService.queryCollection(
          'learning_paths',
          filters: [QueryFilter(field: 'userId', isEqualTo: userId)],
          orderBy: 'createdAt',
          descending: true,
        );
        return snapshot.docs.map((doc) => LearningPathModel.fromJson(doc.data())).toList();
      } catch (e2) {
        AppLogger.error('Failed to get learning paths', tag: 'LearningRepo', error: e);
        rethrow;
      }
    }
  }

  /// Get a specific learning path
  Future<LearningPathModel?> getLearningPath(String pathId) async {
    try {
      final doc = await _firebaseService.getDoc('learning_paths/$pathId');
      if (doc.exists && doc.data() != null) {
        return LearningPathModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get learning path', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Update learning path progress
  Future<void> updateProgress(String pathId, double progress) async {
    try {
      await _firebaseService.updateDoc('learning_paths/$pathId', {
        'progress': progress,
        'updated_at': DateTime.now(), // snake_case
        'is_completed': progress >= 1.0,
      });
      AppLogger.info('Progress updated: $pathId -> ${(progress * 100).toInt()}%', tag: 'LearningRepo');
    } catch (e) {
      AppLogger.error('Failed to update progress', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

   /// Mark a lesson as complete
  Future<Map<String, dynamic>> completeLessonViaApi({
    required String pathId,
    required int moduleNumber,
    required int lessonNumber,
    required String userId,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.completeLesson}',
        data: {
          'path_id': pathId,
          'module_number': moduleNumber,
          'lesson_number': lessonNumber,
          'user_id': userId,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      AppLogger.error('Failed to complete lesson via API', tag: 'LearningRepo', error: e);
      // Fallback to client-side completion
      await completeLesson(pathId, lessonNumber, moduleNumber);
      return {'status': 'completed_locally'};
    }
  }

  /// Mark a lesson as complete
  Future<void> completeLesson(String pathId, int lessonNumber, int moduleNumber) async {
    // Note: With Nested Modules, finding the lesson is harder.
    // We need to read, update in memory, and write back.
    try {
       // Logic to update nested array in Firestore is complex (dot notation).
       // Easiest is read -> modify -> write.
       
       final path = await getLearningPath(pathId);
       if (path != null) {
         // Modify
         final updatedModules = path.modules.map((m) {
           if (m.moduleNumber == moduleNumber) {
             final updatedLessons = m.lessons.map((l) {
               if (l.lessonNumber == lessonNumber) {
                 return l.copyWith(isCompleted: true);
               }
               return l;
             }).toList();
             return ModuleModel(
                moduleNumber: m.moduleNumber,
                title: m.title,
                description: m.description,
                durationHours: m.durationHours,
                lessons: updatedLessons,
                isCompleted: updatedLessons.every((l) => l.isCompleted)
             );
           }
           return m;
         }).toList();
         
         // Calculate Progress
         final allLessons = updatedModules.expand((m) => m.lessons).toList();
         final completedCount = allLessons.where((l) => l.isCompleted).length;
         final progress = allLessons.isNotEmpty ? completedCount / allLessons.length : 0.0;
         
         await _firebaseService.updateDoc('learning_paths/$pathId', {
           'modules': updatedModules.map((m) => m.toJson()).toList(),
           'progress': progress,
           'updated_at': DateTime.now(),
           'is_completed': progress >= 1.0,
         });
       }
    } catch (e) {
      AppLogger.error('Failed to complete lesson', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Generate AI lesson content via backend
  Future<Map<String, dynamic>> generateLessonContent({
    required String topic,
    required String moduleTitle,
    required String lessonTitle,
    String lessonDescription = '',
    List<String> keyConcepts = const [],
    String difficulty = 'beginner',
    String pathId = '',
    int moduleNumber = 0,
    int lessonNumber = 0,
  }) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.baseUrl}${ApiConstants.lessonContent}',
        data: {
          'topic': topic,
          'module_title': moduleTitle,
          'lesson_title': lessonTitle,
          'lesson_description': lessonDescription,
          'key_concepts': keyConcepts,
          'difficulty': difficulty,
          'path_id': pathId,
          'module_number': moduleNumber,
          'lesson_number': lessonNumber,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e) {
      AppLogger.error('Failed to generate lesson content', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Search resources from API
  Future<List<ResourceModel>> searchResources({
    required String query,
    String? source,
  }) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.resources,
        queryParameters: {
          'q': query,
          if (source != null) 'source': source,
        },
      );
      
      final List<dynamic> results = response.data!['results'] ?? [];
      return results.map((e) => ResourceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Failed to search resources', tag: 'LearningRepo', error: e);
      rethrow;
    }
  }

  /// Stream learning paths for real-time updates
  Stream<List<LearningPathModel>> streamUserLearningPaths(String userId) {
    return _firebaseService
        .collection('learning_paths')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningPathModel.fromJson(doc.data()))
            .toList());
  }

  // ============ DASHBOARD DATA ============

  /// Log an activity event to the user's activity subcollection
  Future<void> logActivity(String userId, ActivityEvent event) async {
    try {
      await _firebaseService.collection('user_activity')
          .doc(userId)
          .collection('events')
          .add(event.toJson());
    } catch (e) {
      AppLogger.error('Failed to log activity', tag: 'LearningRepo', error: e);
      // Non-critical: don't rethrow
    }
  }

  /// Get recent activity events for the Home feed
  Future<List<ActivityEvent>> getRecentActivity(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firebaseService.collection('user_activity')
          .doc(userId)
          .collection('events')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get recent activity', tag: 'LearningRepo', error: e);
      return [];
    }
  }

  /// Get in-progress learning paths for "Continue Learning" section
  Future<List<ContinueLearningItem>> getContinueLearningPaths(String userId, {int limit = 3}) async {
    try {
      final paths = await getUserLearningPaths(userId);

      // Filter to in-progress paths (started but not complete)
      final inProgress = paths.where((p) => p.progress > 0 && p.progress < 1.0).toList();

      // Sort by most-recently-updated first
      inProgress.sort((a, b) {
        final aTime = a.updatedAt ?? a.createdAt;
        final bTime = b.updatedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      final results = <ContinueLearningItem>[];
      for (final path in inProgress.take(limit)) {
        final allLessons = path.lessons;
        final completedCount = allLessons.where((l) => l.isCompleted).length;
        final nextLesson = allLessons.where((l) => !l.isCompleted).firstOrNull;

        results.add(ContinueLearningItem(
          pathId: path.id,
          title: path.topic,
          difficulty: path.difficulty,
          nextLessonTitle: nextLesson?.title,
          nextLessonIndex: nextLesson?.lessonNumber ?? 0,
          percentComplete: path.progress,
          lastActivityAt: path.updatedAt,
          totalLessons: allLessons.length,
          completedLessons: completedCount,
        ));
      }

      // If no in-progress, show newest not-started paths
      if (results.isEmpty) {
        final notStarted = paths.where((p) => p.progress == 0).take(limit).toList();
        for (final path in notStarted) {
          results.add(ContinueLearningItem(
            pathId: path.id,
            title: path.topic,
            difficulty: path.difficulty,
            nextLessonTitle: path.lessons.isNotEmpty ? path.lessons.first.title : null,
            nextLessonIndex: 1,
            percentComplete: 0,
            lastActivityAt: path.createdAt,
            totalLessons: path.lessons.length,
            completedLessons: 0,
          ));
        }
      }

      return results;
    } catch (e) {
      AppLogger.error('Failed to get continue learning', tag: 'LearningRepo', error: e);
      return [];
    }
  }

  /// Get all path progress summaries for the Progress screen
  Future<List<PathProgressSummary>> getPathProgressSummaries(String userId) async {
    try {
      final paths = await getUserLearningPaths(userId);
      return paths.map((path) {
        final allLessons = path.lessons;
        final completedCount = allLessons.where((l) => l.isCompleted).length;
        return PathProgressSummary(
          pathId: path.id,
          title: path.topic,
          percentComplete: path.progress,
          lessonsCompleted: completedCount,
          totalLessons: allLessons.length,
          lastActivityAt: path.updatedAt,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('Failed to get path summaries', tag: 'LearningRepo', error: e);
      return [];
    }
  }

  /// Get activity events for the current week (for weekly chart)
  Future<List<ActivityEvent>> getWeeklyActivityEvents(String userId) async {
    try {
      final now = DateTime.now();
      // Start of this week (Monday)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final snapshot = await _firebaseService.collection('user_activity')
          .doc(userId)
          .collection('events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDate))
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get weekly activity', tag: 'LearningRepo', error: e);
      return [];
    }
  }

  /// Get activity events for a specific month (for calendar heatmap)
  Future<List<ActivityEvent>> getMonthlyActivityEvents(String userId, int year, int month) async {
    try {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

      final snapshot = await _firebaseService.collection('user_activity')
          .doc(userId)
          .collection('events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to get monthly activity', tag: 'LearningRepo', error: e);
      return [];
    }
  }
}
