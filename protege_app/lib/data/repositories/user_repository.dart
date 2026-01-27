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
