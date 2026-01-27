import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/quiz_repository.dart';
import '../data/models/quiz_model.dart';
// import '../data/models/quiz_result_model.dart'; // Removed: defined in quiz_model.dart
import 'auth_provider.dart';
// import 'learning_provider.dart'; // Unused
import 'api_provider.dart';

/// Quiz repository provider
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return QuizRepository(apiService: apiService);
});

/// Quiz state
class QuizState {
  final QuizModel? quiz;
  final int currentQuestionIndex;
  final List<String> userAnswers;
  final bool isSubmitting;
  final QuizResultModel? result;

  const QuizState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.userAnswers = const [],
    this.isSubmitting = false,
    this.result,
  });

  QuizState copyWith({
    QuizModel? quiz,
    int? currentQuestionIndex,
    List<String>? userAnswers,
    bool? isSubmitting,
    QuizResultModel? result,
  }) {
    return QuizState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: result ?? this.result,
    );
  }

  QuestionModel? get currentQuestion =>
      quiz != null && currentQuestionIndex < quiz!.questions.length
          ? quiz!.questions[currentQuestionIndex]
          : null;

  bool get isLastQuestion =>
      quiz != null && currentQuestionIndex >= quiz!.questions.length - 1;

  double get progress => quiz != null && quiz!.questions.isNotEmpty
      ? (currentQuestionIndex + 1) / quiz!.questions.length
      : 0;
}

/// Quiz notifier
class QuizNotifier extends StateNotifier<AsyncValue<QuizState>> {
  final QuizRepository _quizRepository;
  final String? _userId;
  DateTime? _startTime;

  QuizNotifier(this._quizRepository, this._userId)
      : super(const AsyncValue.data(QuizState()));

  Future<void> generateQuiz({
    required String lessonId,
    required String topic,
    required String difficulty,
    int? questionCount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final quiz = await _quizRepository.generateQuiz(
        lessonId: lessonId,
        topic: topic,
        difficulty: difficulty,
        questionCount: questionCount,
      );
      _startTime = DateTime.now();
      state = AsyncValue.data(QuizState(
        quiz: quiz,
        userAnswers: List.filled(quiz.questions.length, ''),
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void answerQuestion(String answer) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedAnswers = List<String>.from(currentState.userAnswers);
    updatedAnswers[currentState.currentQuestionIndex] = answer;

    state = AsyncValue.data(currentState.copyWith(userAnswers: updatedAnswers));
  }

  void nextQuestion() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLastQuestion) return;

    state = AsyncValue.data(currentState.copyWith(
      currentQuestionIndex: currentState.currentQuestionIndex + 1,
    ));
  }

  void previousQuestion() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.currentQuestionIndex <= 0) return;

    state = AsyncValue.data(currentState.copyWith(
      currentQuestionIndex: currentState.currentQuestionIndex - 1,
    ));
  }

  Future<QuizResultModel?> submitQuiz() async {
    final currentState = state.valueOrNull;
    if (currentState?.quiz == null || _userId == null) return null;

    state = AsyncValue.data(currentState!.copyWith(isSubmitting: true));

    try {
      final timeTaken = _startTime != null
          ? DateTime.now().difference(_startTime!)
          : const Duration(minutes: 5);

      final answers = currentState.quiz!.questions
          .asMap()
          .entries
          .map((entry) => AnswerModel(
                questionId: entry.value.id,
                userAnswer: currentState.userAnswers[entry.key],
                isCorrect: _quizRepository.checkAnswer(
                  entry.value,
                  currentState.userAnswers[entry.key],
                ),
              ))
          .toList();

      final result = await _quizRepository.submitQuiz(
        quizId: currentState.quiz!.id,
        userId: _userId!,
        answers: answers,
        timeTaken: timeTaken,
      );

      state = AsyncValue.data(currentState.copyWith(
        isSubmitting: false,
        result: result,
      ));

      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    _startTime = null;
    state = const AsyncValue.data(QuizState());
  }
}

/// Quiz provider
final quizProvider =
    StateNotifierProvider<QuizNotifier, AsyncValue<QuizState>>((ref) {
  final quizRepo = ref.watch(quizRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  return QuizNotifier(quizRepo, currentUser?.uid);
});
