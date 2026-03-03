import 'api_service.dart';
import '../models/resource_models.dart';

class ResourceApiService {
  final ApiService _apiService;

  ResourceApiService(this._apiService);

  Future<LessonResources> curateResources({
    required String topic,
    required String lessonTitle,
    required Map<String, String> searchQueries,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/v1/resources/curate',
        data: {
          'topic': topic,
          'lesson_title': lessonTitle,
          'search_queries': searchQueries,
          'max_videos': 3,
          'max_articles': 3,
          'max_repos': 2,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return LessonResources.fromJson(response.data);
      } else {
        throw Exception('Failed to load resources: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching resources: $e');
    }
  }

  // Development endpoint to test without auth if needed
  Future<LessonResources> curateResourcesTest({
    required String topic,
    required String lessonTitle,
    required Map<String, String> searchQueries,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/v1/resources/curate-test',
        data: {
          'topic': topic,
          'lesson_title': lessonTitle,
          'search_queries': searchQueries,
        },
      );

      return LessonResources.fromJson(response.data);
    } catch (e) {
      throw Exception('Error fetching resources (test): $e');
    }
  }
}
