import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/chip.dart';

class GoalSelectionScreen extends ConsumerStatefulWidget {
  final String topic;

  const GoalSelectionScreen({
    super.key,
    required this.topic,
  });

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  String _selectedGoal = 'Career';
  String _selectedDifficulty = 'beginner';
  int _selectedTime = 30;

  final List<String> _goals = [
    'Career',
    'Hobby',
    'Exam Prep',
    'General Interest',
  ];

  final List<String> _difficulties = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  final List<int> _times = [15, 30, 60, 90];

  void _onGenerate() {
    // Navigate to Loading screen with all params
    context.push(
      '/create-path/loading',
      extra: {
        'topic': widget.topic,
        'goal': _selectedGoal,
        'difficulty': _selectedDifficulty,
        'duration': _selectedTime,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Path'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary
            Text(
              'Topic: ${widget.topic}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Goal Section
            _SectionHeader(title: 'What is your goal?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _goals.map((goal) {
                return SelectableChip(
                  label: goal,
                  isSelected: _selectedGoal == goal,
                  onTap: () => setState(() => _selectedGoal = goal),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Difficulty Section
            _SectionHeader(title: 'What is your experience level?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _difficulties.map((diff) {
                return SelectableChip(
                  label: diff[0].toUpperCase() + diff.substring(1),
                  isSelected: _selectedDifficulty == diff,
                  onTap: () => setState(() => _selectedDifficulty = diff),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Time Section
            _SectionHeader(title: 'Daily time commitment?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: _times.map((min) {
                return SelectableChip(
                  label: '$min min',
                  isSelected: _selectedTime == min,
                  onTap: () => setState(() => _selectedTime = min),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 48),
            
            PrimaryButton(
              text: 'Generate Syllabus',
              onPressed: _onGenerate,
              icon: Icons.auto_awesome,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
