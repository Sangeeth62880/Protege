import '../services/firebase_service.dart';
import '../services/api_service.dart';
import '../models/learning_path_model.dart';
import '../models/resource_model.dart';
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
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/learning/generate-syllabus-test', // TEMPORARY DEBUG: Bypass Auth
        data: {
          'topic': topic,
          'goal': goal,
          'experience_level': difficulty,
          'daily_time_minutes': duration,
        },
      );
      
      return SyllabusModel.fromJson(response.data!);
    } catch (e) {
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
         ApiConstants.savePath, 
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
}
