import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../../core/utils/logger.dart';

/// Repository for user data operations
class UserRepository {
  final FirebaseService _firebaseService;

  UserRepository({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firebaseService.getDoc('users/$userId');
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user', tag: 'UserRepo', error: e);
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUser(UserModel user) async {
    try {
      await _firebaseService.updateDoc('users/${user.id}', user.toJson());
      AppLogger.success('User updated: ${user.id}', tag: 'UserRepo');
    } catch (e) {
      AppLogger.error('Failed to update user', tag: 'UserRepo', error: e);
      rethrow;
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firebaseService.updateDoc('users/$userId', {
        'preferences': preferences,
      });
      AppLogger.success('Preferences updated for user: $userId', tag: 'UserRepo');
    } catch (e) {
      AppLogger.error('Failed to update preferences', tag: 'UserRepo', error: e);
      rethrow;
    }
  }

  /// Add learning path to user
  Future<void> addLearningPath(String userId, String pathId) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final updatedPaths = [...user.learningPathIds, pathId];
        await _firebaseService.updateDoc('users/$userId', {
          'learningPathIds': updatedPaths,
        });
        AppLogger.success('Learning path added: $pathId', tag: 'UserRepo');
      }
    } catch (e) {
      AppLogger.error('Failed to add learning path', tag: 'UserRepo', error: e);
      rethrow;
    }
  }

  /// Atomically increment user stats counters
  Future<void> incrementStats(
    String userId, {
    int lessonsCompleted = 0,
    int totalMinutes = 0,
    int teachSessions = 0,
    int quizzesPassed = 0,
    int xp = 0,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastActivityAt': Timestamp.fromDate(DateTime.now()),
      };

      if (lessonsCompleted > 0) {
        updates['lessonsCompleted'] = FieldValue.increment(lessonsCompleted);
      }
      if (totalMinutes > 0) {
        updates['totalLearningMinutes'] = FieldValue.increment(totalMinutes);
      }
      if (teachSessions > 0) {
        updates['teachSessions'] = FieldValue.increment(teachSessions);
      }
      if (quizzesPassed > 0) {
        updates['quizzesPassed'] = FieldValue.increment(quizzesPassed);
      }
      if (xp > 0) {
        updates['totalXp'] = FieldValue.increment(xp);
      }

      await _firebaseService.updateDoc('users/$userId', updates);
    } catch (e) {
      AppLogger.error('Failed to increment stats', tag: 'UserRepo', error: e);
      // Don't rethrow — stats update is non-critical
    }
  }

  /// Update the user's streak based on current activity
  Future<void> updateStreak(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActivity = user.lastActivityAt;

      int newStreak = user.currentStreak;

      if (lastActivity == null) {
        newStreak = 1;
      } else {
        final lastDay = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
        final daysDiff = today.difference(lastDay).inDays;

        if (daysDiff == 0) {
          // Same day — streak already counted
          return;
        } else if (daysDiff == 1) {
          newStreak = user.currentStreak + 1;
        } else {
          newStreak = 1; // Streak broken
        }
      }

      await _firebaseService.updateDoc('users/$userId', {
        'currentStreak': newStreak,
      });
    } catch (e) {
      AppLogger.error('Failed to update streak', tag: 'UserRepo', error: e);
    }
  }

  /// Add a badge to the user's collection
  Future<void> addBadge(String userId, Map<String, dynamic> badge) async {
    try {
      await _firebaseService.updateDoc('users/$userId', {
        'badges': FieldValue.arrayUnion([badge]),
      });
    } catch (e) {
      AppLogger.error('Failed to add badge', tag: 'UserRepo', error: e);
    }
  }

  /// Stream user data
  Stream<UserModel?> streamUser(String userId) {
    return _firebaseService.streamDoc('users/$userId').map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    });
  }
}
