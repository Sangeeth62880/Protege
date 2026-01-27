import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/tutor_models.dart';
import 'api_service.dart';

class TutorApiService {
  final ApiService _apiService;

  TutorApiService(this._apiService);

  Future<Map<String, dynamic>> askQuestion({
    required String sessionId,
    required String question,
    required String topic,
    required String lessonTitle,
    required List<String> keyConcepts,
    required String experienceLevel,
  }) async {
    try {
      // Use test endpoint for now as requested in requirements for UI building
      // Or use the real one if we have auth. Let's use the real one if auth available, 
      // but fallback to test if issues.
      // Actually, let's stick to the structure:
      
      final response = await _apiService.post<Map<String, dynamic>>(
        '/api/v1/tutor/ask-test', // Using Test/Bypass for reliability during dev
        data: {
          'session_id': sessionId,
          'question': question,
          'topic': topic,
          'lesson_title': lessonTitle,
          'key_concepts': keyConcepts,
          'experience_level': experienceLevel,
        },
      );

      return response.data!;
    } catch (e) {
      AppLogger.error('Failed to ask tutor', tag: 'TutorApi', error: e);
      rethrow;
    }
  }

  Future<List<TutorMessage>> getHistory(String sessionId) async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/v1/tutor/history/$sessionId',
      );
      
      final List<dynamic> messages = response.data!['messages'] ?? [];
      
      return messages.map((m) {
        return TutorMessage(
          id: DateTime.now().toString(), // No ID from backend yet
          content: m['content'],
          role: m['role'] == 'user' ? MessageRole.user : MessageRole.ai,
          timestamp: DateTime.now(), // No timestamp from backend yet
        );
      }).toList();
      
    } catch (e) {
      AppLogger.error('Failed to get history', tag: 'TutorApi', error: e);
      return [];
    }
  }
  
  Future<void> clearHistory(String sessionId) async {
    try {
      await _apiService.delete('/api/v1/tutor/history/$sessionId');
    } catch (e) {
      AppLogger.error('Failed to clear history', tag: 'TutorApi', error: e);
    }
  }
}
