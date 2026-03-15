import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/buttons/primary_button.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  final String topic;
  const GoalSelectionScreen({super.key, required this.topic});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  String _selectedGoal = 'Career';
  String _selectedDifficulty = 'beginner';
  int _selectedTime = 30;

  final _goals = ['Career', 'Hobby', 'Exam Prep', 'General Interest'];
  final _difficulties = ['beginner', 'intermediate', 'advanced'];
  final _times = [15, 30, 60, 90];

  void _onGenerate() {
    context.push('/create-path/loading', extra: {
      'topic': widget.topic,
      'goal': _selectedGoal,
      'difficulty': _selectedDifficulty,
      'duration': _selectedTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(), size: 22),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: AppSpacing.screenH.copyWith(top: 8, bottom: 32 + AppSpacing.navbarClearance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaggeredItem(
              index: 0,
              child: Text('Customize your\n${widget.topic} path', style: AppTypography.displaySm),
            ),
            const SizedBox(height: AppSpacing.xs),
            StaggeredItem(
              index: 1,
              child: Text('We\'ll build a personalized syllabus for you', style: AppTypography.bodyLg),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ── Goal ──
            StaggeredItem(
              index: 2,
              child: Text('LEARNING GOAL', style: AppTypography.labelSm),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _goals.map((g) => _ChoiceChip(
                label: g,
                selected: _selectedGoal == g,
                onTap: () => setState(() => _selectedGoal = g),
              )).toList(),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ── Difficulty ──
            StaggeredItem(
              index: 3,
              child: Text('DIFFICULTY', style: AppTypography.labelSm),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _difficulties.map((d) {
                final display = d[0].toUpperCase() + d.substring(1);
                return _ChoiceChip(
                  label: display,
                  selected: _selectedDifficulty == d,
                  onTap: () => setState(() => _selectedDifficulty = d),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ── Time ──
            StaggeredItem(
              index: 4,
              child: Text('DAILY TIME', style: AppTypography.labelSm),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _times.map((t) => _ChoiceChip(
                label: '$t min',
                selected: _selectedTime == t,
                onTap: () => setState(() => _selectedTime = t),
              )).toList(),
            ),
            const SizedBox(height: AppSpacing.huge),

            PrimaryButton(label: 'Generate Syllabus', onPressed: _onGenerate),
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: selected ? AppColors.brand : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.headingSm.copyWith(
            fontSize: 14,
            color: selected ? AppColors.textOnBrand : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
