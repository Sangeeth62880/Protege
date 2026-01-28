import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/quiz_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/quiz/question_card.dart';
import '../../widgets/quiz/quiz_timer.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String? topic;
  final String? lessonTitle;
  final String? lessonId;

  const QuizScreen({
    super.key,
    this.topic,
    this.lessonTitle,
    this.lessonId, // Optional, can be null
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    // Generate quiz on load if not already loaded or if different
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Logic to prevent regeneration if already active could be added here
      ref.read(quizProvider.notifier).generateQuiz(
        topic: widget.topic ?? "General Knowledge",
        lessonTitle: widget.lessonTitle ?? "Quick Quiz",
        keyConcepts: [], // Extract or pass
        difficulty: "medium", // Default
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.lessonTitle ?? 'Quiz',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
             // Confirm exit dialog?
            context.pop();
          },
        ),
        actions: [
          if (quizState.currentQuiz != null && quizState.quizResult == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: QuizTimer(
                  onTick: (seconds) {
                    ref.read(quizProvider.notifier).updateTimer(seconds);
                  },
                ),
              ),
            ),
        ],
      ),
      body: quizState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : quizState.error != null
              ? Center(child: Text("Error: ${quizState.error}"))
              : quizState.quizResult != null
                  ? QuizResultScreen(
                      result: quizState.quizResult!,
                      onReset: () {
                        ref.read(quizProvider.notifier).reset();
                        // context.pop() is handled inside result screen if needed, 
                        // or we can let result screen handle navigation
                      },
                    )
                  : quizState.currentQuiz != null
                      ? _buildQuizContent(context, quizState)
                      : const Center(child: Text("Preparing your quiz...")),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizState state) {
    final quiz = state.currentQuiz!;
    final currentQ = quiz.questions[state.currentQuestionIndex];
    final progress = (state.currentQuestionIndex + 1) / quiz.questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: QuestionCard(
              question: currentQ,
              userAnswer: state.userAnswers[currentQ.questionNumber]?.toString(), // Mapping question number
              onAnswerSelected: (answer) {
                ref.read(quizProvider.notifier).selectAnswer(currentQ.questionNumber, answer);
              },
            ),
          ),
        ),
        _buildBottomBar(context, state, quiz),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, QuizState state, QuizModel quiz) {
    final isLast = state.currentQuestionIndex == quiz.questions.length - 1;
    final hasAnswer = state.userAnswers.containsKey(
      quiz.questions[state.currentQuestionIndex].questionNumber
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(quizProvider.notifier).prevQuestion();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous', style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
          if (state.currentQuestionIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              text: isLast ? 'Submit Quiz' : 'Next Question',
              onPressed: hasAnswer
                  ? () {
                      if (isLast) {
                        ref.read(quizProvider.notifier).submitQuiz();
                      } else {
                        ref.read(quizProvider.notifier).nextQuestion();
                      }
                    }
                  : null, // Disable if no answer? Or allow skip? Requirements say "Answers questions", usually implies mandatory.
            ),
          ),
        ],
      ),
    );
  }

  // Result view methods removed as they are moved to QuizResultScreen
}
