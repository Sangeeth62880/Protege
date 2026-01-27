import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/quiz_provider.dart';
import '../../widgets/buttons/primary_button.dart';

/// Quiz screen for assessments
class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    // Generate quiz when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).generateQuiz(
            lessonId: widget.quizId,
            topic: 'Sample Topic', // TODO: Get from lesson
            difficulty: 'Beginner', // Default for now
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(quizProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: quizState.when(
        data: (state) {
          if (state.result != null) {
            return _QuizResult(result: state.result!);
          }
          if (state.quiz == null) {
            return const Center(child: Text('No quiz available'));
          }
          return _QuizContent(state: state);
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating quiz...'),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _QuizContent extends ConsumerWidget {
  final QuizState state;

  const _QuizContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: AppColors.textLight.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question number
                Text(
                  'Question ${state.currentQuestionIndex + 1} of ${state.quiz!.questions.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // Question
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                // Options
                ...question.options.map((option) {
                  final isSelected =
                      state.userAnswers[state.currentQuestionIndex] == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      text: option,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(quizProvider.notifier).answerQuestion(option);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              if (state.currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(quizProvider.notifier).previousQuestion();
                    },
                    child: const Text('Previous'),
                  ),
                ),
              if (state.currentQuestionIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  text: state.isLastQuestion ? 'Submit' : 'Next',
                  isLoading: state.isSubmitting,
                  onPressed: state.userAnswers[state.currentQuestionIndex].isEmpty
                      ? null
                      : () {
                          if (state.isLastQuestion) {
                            ref.read(quizProvider.notifier).submitQuiz();
                          } else {
                            ref.read(quizProvider.notifier).nextQuestion();
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResult extends ConsumerWidget {
  final QuizResultModel result;

  const _QuizResult({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passed = result.passed;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Result icon
            Icon(
              passed ? Icons.celebration_rounded : Icons.sentiment_dissatisfied_rounded,
              size: 80,
              color: passed ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(height: 24),
            // Result text
            Text(
              passed ? 'Great Job! 🎉' : 'Keep Practicing! 💪',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Score
            Text(
              'You scored ${result.score} out of ${result.totalPoints}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            // Percentage
            Text(
              '${result.percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: passed ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            // Actions
            PrimaryButton(
              text: 'Continue',
              onPressed: () {
                ref.read(quizProvider.notifier).reset();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
