import '../services/api_service.dart';
import '../models/quiz_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Repository for quiz operations
class QuizRepository {
  final ApiService _apiService;

  QuizRepository({required ApiService apiService}) : _apiService = apiService;

  /// Generate a quiz for a lesson
  Future<QuizModel> generateQuiz({
    required String lessonId,
    required String topic,
    required String difficulty,
    int? questionCount,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.quizGenerate,
        data: {
          'topic': topic,
          'difficulty': difficulty,
          'lesson_id': lessonId,
        },
      );
      
      final quiz = QuizModel.fromJson(response.data!);
      AppLogger.success('Quiz generated for: $topic', tag: 'QuizRepo');
      return quiz;
    } catch (e) {
      AppLogger.error('Failed to generate quiz', tag: 'QuizRepo', error: e);
      rethrow;
    }
  }

  /// Submit quiz answers and get results
  Future<QuizResultModel> submitQuiz({
    required String quizId,
    required String userId,
    required List<AnswerModel> answers,
    required Duration timeTaken,
  }) async {
    try {
      // First, get the result from the server
      final resultResponse = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.quizSubmit,
        data: {
          'quiz_id': quizId,
          'answers': answers.map((a) => a.toJson()).toList(),
          'time_taken_seconds': timeTaken.inSeconds,
        },
      );
      
      final result = QuizResultModel.fromJson(resultResponse.data!);
      AppLogger.success(
        'Quiz submitted - Score: ${result.score}/${result.totalPoints}',
        tag: 'QuizRepo',
      );
      return result;
    } catch (e) {
      AppLogger.error('Failed to submit quiz', tag: 'QuizRepo', error: e);
      rethrow;
    }
  }

  /// Get quiz by ID
  Future<QuizModel?> getQuiz(String quizId) async {
    try {
      final response = await _apiService.get('${ApiConstants.quizGenerate}/$quizId');
      return QuizModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Failed to get quiz', tag: 'QuizRepo', error: e);
      return null;
    }
  }

  /// Check answer locally (for immediate feedback)
  bool checkAnswer(QuestionModel question, String userAnswer) {
    return question.correctAnswer.toLowerCase().trim() ==
        userAnswer.toLowerCase().trim();
  }
}
