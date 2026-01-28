import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../data/models/quiz_model.dart';
import 'quiz_options.dart';
import 'quiz_inputs.dart';

class QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final String? userAnswer;
  final Function(String) onAnswerSelected;
  final bool isSubmitting;

  const QuestionCard({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.onAnswerSelected,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 24),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Question ${question.questionNumber}',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getDifficultyColor(question.difficulty).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            question.difficulty.toUpperCase(),
            style: TextStyle(
              color: _getDifficultyColor(question.difficulty),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (question.questionType) {
      case 'multiple_choice':
        return MultipleChoiceOptions(
          options: question.options ?? [],
          selectedOption: userAnswer,
          onSelected: isSubmitting ? null : onAnswerSelected,
        );
      case 'true_false':
        return TrueFalseOptions(
          selectedOption: userAnswer,
          onSelected: isSubmitting ? null : onAnswerSelected,
        );
      case 'fill_blank':
        return FillBlankInput(
          initialValue: userAnswer,
          onChanged: isSubmitting ? null : onAnswerSelected,
        );
      case 'code_completion':
        return CodeCompletionInput(
          template: question.codeTemplate ?? "",
          initialValue: userAnswer,
          onChanged: isSubmitting ? null : onAnswerSelected,
        );
      default:
        return const Center(child: Text("Unknown Question Type"));
    }
  }
}
