import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import '../../../providers/quiz_provider.dart';
import '../../widgets/buttons/primary_button.dart';

class QuizResultScreen extends ConsumerWidget {
  final QuizResultModel result;
  final VoidCallback? onReset;

  const QuizResultScreen({
    super.key, 
    required this.result,
    this.onReset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passed = result.passed;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                passed 
                  ? "You've mastered this topic." 
                  : "Review the material and try again.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildScoreCard(context, result),
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'Initial Lesson', // Or Back to Home
                onPressed: () {
                  if (onReset != null) {
                    onReset!();
                  } else {
                    ref.read(quizProvider.notifier).reset(); // Ensure reset
                  }
                  context.pop();
                },
              ),
              const SizedBox(height: 16),
              if (!result.passed)
                TextButton(
                  onPressed: () {
                    // Retry logic could go here
                     if (onReset != null) {
                        onReset!();
                      }
                      // Just pop to retry if the quiz screen logic supports it, 
                      // actually we probably need to trigger a regeneration or reset state to start mode.
                      // For now, pop.
                      context.pop(); 
                  },
                  child: const Text("Try Again"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, QuizResultModel result) {
    final percentage = (result.score).toStringAsFixed(0);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "$percentage%",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Text(
            "Final Score",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Questions", "${result.totalQuestions}"),
              _buildStat("Correct", "${result.correctCount}"),
              _buildStat("Time", "${result.timeTakenSeconds}s"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
