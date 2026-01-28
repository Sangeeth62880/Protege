import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/quiz_model.dart';
import '../data/services/quiz_api_service.dart';

// Service Provider
final quizApiServiceProvider = Provider<QuizApiService>((ref) {
  return QuizApiService();
});

// State
class QuizState {
  final bool isLoading;
  final QuizModel? currentQuiz;
  final int currentQuestionIndex;
  final Map<int, String> userAnswers; // questionNumber -> answer
  final QuizResultModel? quizResult;
  final String? error;
  final int timeElapsed; // for timer

  const QuizState({
    this.isLoading = false,
    this.currentQuiz,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.quizResult,
    this.error,
    this.timeElapsed = 0,
  });

  QuizState copyWith({
    bool? isLoading,
    QuizModel? currentQuiz,
    int? currentQuestionIndex,
    Map<int, String>? userAnswers,
    QuizResultModel? quizResult,
    String? error,
    int? timeElapsed,
  }) {
    return QuizState(
      isLoading: isLoading ?? this.isLoading,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      quizResult: quizResult ?? this.quizResult,
      error: error, // if null passed, error is cleared? or keep? 
                    // Usually we want to clear error if not provided explicitly or logic dictates
                    // Here I'll assume if it's passed as null it stays null unless I use a nullable wrapper.
                    // Simplified: error is cleared if I pass null explicitly? 
                    // Let's rely on constructor defaults or explicit updates.
      timeElapsed: timeElapsed ?? this.timeElapsed,
    );
  }

  // Clear error convenience
  QuizState clearError() => QuizState(
    isLoading: isLoading,
    currentQuiz: currentQuiz,
    currentQuestionIndex: currentQuestionIndex,
    userAnswers: userAnswers,
    quizResult: quizResult,
    error: null,
    timeElapsed: timeElapsed,
  );
}

// Notifier
class QuizNotifier extends StateNotifier<QuizState> {
  final QuizApiService _apiService;

  QuizNotifier(this._apiService) : super(const QuizState());

  Future<void> generateQuiz({
    required String topic,
    required String lessonTitle,
    required List<String> keyConcepts,
    String difficulty = "mixed",
  }) async {
    state = state.copyWith(isLoading: true, error: null, quizResult: null, currentQuestionIndex: 0, userAnswers: {});
    try {
      final quiz = await _apiService.generateQuiz(
        topic: topic, 
        lessonTitle: lessonTitle, 
        keyConcepts: keyConcepts,
        difficulty: difficulty,
      );
      state = state.copyWith(isLoading: false, currentQuiz: quiz);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectAnswer(int questionNumber, String answer) {
    final newAnswers = Map<int, String>.from(state.userAnswers);
    newAnswers[questionNumber] = answer;
    state = state.copyWith(userAnswers: newAnswers);
  }

  void nextQuestion() {
    if (state.currentQuiz != null && state.currentQuestionIndex < state.currentQuiz!.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void prevQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  Future<void> submitQuiz() async {
    if (state.currentQuiz == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _apiService.submitQuiz(
        quizId: state.currentQuiz!.quizId ?? "",
        answers: state.userAnswers,
        timeTakenSeconds: state.timeElapsed, // Assuming managed externally or updated
      );
      state = state.copyWith(isLoading: false, quizResult: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  
  void updateTimer(int seconds) {
    state = state.copyWith(timeElapsed: seconds);
  }

  void reset() {
    state = const QuizState();
  }
}

// Provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final apiService = ref.watch(quizApiServiceProvider);
  return QuizNotifier(apiService);
});
