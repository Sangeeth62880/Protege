import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/quiz_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
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
    this.lessonId,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).generateQuiz(
        topic: widget.topic ?? 'General Knowledge',
        lessonTitle: widget.lessonTitle ?? 'Quick Quiz',
        keyConcepts: [],
        difficulty: 'medium',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(widget.lessonTitle ?? 'Quiz', style: AppTypography.headingSm),
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.x(), size: 22),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (quizState.currentQuiz != null && quizState.quizResult == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: QuizTimer(
                  onTick: (seconds) => ref.read(quizProvider.notifier).updateTimer(seconds),
                ),
              ),
            ),
        ],
      ),
      body: quizState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.brand),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Generating quiz...', style: AppTypography.bodyMd),
                ],
              ),
            )
          : quizState.error != null
              ? Center(child: Text('Error: ${quizState.error}', style: AppTypography.bodyMd))
              : quizState.quizResult != null
                  ? QuizResultScreen(
                      result: quizState.quizResult!,
                      onReset: () => ref.read(quizProvider.notifier).reset(),
                    )
                  : quizState.currentQuiz != null
                      ? _buildQuizContent(context, quizState)
                      : Center(child: Text('Preparing your quiz...', style: AppTypography.bodyMd)),
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizState state) {
    final quiz = state.currentQuiz!;
    final currentQ = quiz.questions[state.currentQuestionIndex];
    final progress = (state.currentQuestionIndex + 1) / quiz.questions.length;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.borderLight,
          valueColor: const AlwaysStoppedAnimation(AppColors.brand),
          minHeight: 4,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: QuestionCard(
              question: currentQ,
              userAnswer: state.userAnswers[currentQ.questionNumber]?.toString(),
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
      quiz.questions[state.currentQuestionIndex].questionNumber,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + AppSpacing.navbarClearance,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (state.currentQuestionIndex > 0)
              Expanded(
                child: SecondaryButton(
                  label: 'Previous',
                  onPressed: () => ref.read(quizProvider.notifier).prevQuestion(),
                ),
              ),
            if (state.currentQuestionIndex > 0) const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: isLast ? 'Submit Quiz' : 'Next Question',
                onPressed: hasAnswer
                    ? () {
                        if (isLast) {
                          ref.read(quizProvider.notifier).submitQuiz();
                        } else {
                          ref.read(quizProvider.notifier).nextQuestion();
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
