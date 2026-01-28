import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/quiz_model.dart';

class QuizApiService {
  final String baseUrl;

  QuizApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<QuizModel> generateQuiz({
    required String topic,
    required String lessonTitle,
    required List<String> keyConcepts,
    String difficulty = "mixed",
    int numQuestions = 5,
    String? lessonId,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.quizGenerate}');
    
    final body = {
      'topic': topic,
      'lesson_title': lessonTitle,
      'key_concepts': keyConcepts,
      'difficulty': difficulty,
      'num_questions': numQuestions,
      'lesson_id': lessonId,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return QuizModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to generate quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error generating quiz: $e');
    }
  }

  Future<QuizResultModel> submitQuiz({
    required String quizId,
    required Map<int, String> answers,
    required int timeTakenSeconds,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.quizSubmit}');
    
    // Map<int, String> needs keys to be strings for JSON usually, 
    // but backend expects Dict[int, str].
    // jsonEncode will encode integer keys as string keys in JSON objects anyway?
    // Actually standard JSON keys must be strings. 
    // Let's verify if FastAPI pydantic Dict[int, str] handles stringified int keys automatically. Yes it does.
    
    final body = {
      'quiz_id': quizId,
      'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      'time_taken_seconds': timeTakenSeconds,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return QuizResultModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to submit quiz: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error submitting quiz: $e');
    }
  }

  Future<List<QuizResultModel>> getQuizHistory(String userId) async {
    // Assuming history endpoint is /api/v1/quiz/history/{userId}
    // ApiConstants doesn't explicitly have history, so constructing it relative to generate or manually
    final uri = Uri.parse('$baseUrl/api/v1/quiz/history/$userId');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((e) => QuizResultModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to get history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }
}
