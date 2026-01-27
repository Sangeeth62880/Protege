import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StatsCard extends StatelessWidget {
  final int streakDays;
  final int totalXp;
  final int lessonsCompleted;

  const StatsCard({
    super.key,
    required this.streakDays,
    required this.totalXp,
    required this.lessonsCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.local_fire_department_rounded,
            color: AppColors.primary,
            value: '$streakDays',
            label: 'Day Streak',
          ),
          _buildDivider(),
          _buildStatItem(
            context,
            icon: Icons.flash_on_rounded,
            color: AppColors.accent,
            value: '$totalXp',
            label: 'Total XP',
          ),
          _buildDivider(),
          _buildStatItem(
            context,
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
            value: '$lessonsCompleted',
            label: 'Lessons',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textLight,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textLight.withValues(alpha: 0.2),
    );
  }
}
