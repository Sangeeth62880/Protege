import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/dashboard_models.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/animated_progress_bar.dart';
import '../../widgets/common/staggered_list_item.dart';
import '../../widgets/common/shimmer_placeholder.dart';
import '../../widgets/common/accent_stat_card.dart';
import '../../widgets/icons/flame_icon.dart';
import '../../widgets/icons/sparkle_star_icon.dart';
import '../../widgets/icons/status_dot.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userData = ref.watch(userStreamProvider);
    final displayName = user?.displayName?.split(' ').first ?? 'Friend';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: () async {
            ref.invalidate(continueLearningProvider);
            ref.invalidate(recentActivityProvider);
            ref.invalidate(userStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                StaggeredListItem(
                  index: 0,
                  child: _buildHeader(context, greeting, displayName, user),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Stat cards row
                StaggeredListItem(
                  index: 1,
                  child: userData.when(
                    data: (u) => _buildStatCards(
                      streakDays: u?.currentStreak ?? 0,
                      totalXp: u?.totalXp ?? 0,
                    ),
                    loading: () => _buildStatCards(streakDays: 0, totalXp: 0),
                    error: (_, __) => _buildStatCards(streakDays: 0, totalXp: 0),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Quick Actions
                StaggeredListItem(
                  index: 2,
                  child: Text('Quick Actions', style: AppTypography.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.md),
                StaggeredListItem(
                  index: 3,
                  child: _buildQuickActions(context),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Continue Learning
                StaggeredListItem(
                  index: 4,
                  child: Text('Continue Learning', style: AppTypography.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildContinueLearning(context),
                const SizedBox(height: AppSpacing.xxxl),

                // Recent Activity
                StaggeredListItem(
                  index: 6,
                  child: Text('Recent Activity', style: AppTypography.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildRecentActivity(),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String greeting, String displayName, dynamic user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                displayName,
                style: AppTypography.headlineLarge,
              ),
            ],
          ),
        ),
        AnimatedPressable(
          onTap: () => context.go('/profile'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
              image: user?.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(user!.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.photoURL == null
                ? Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards({required int streakDays, required int totalXp}) {
    return Row(
      children: [
        Expanded(
          child: AccentStatCard(
            backgroundColor: AppColors.yellowLight,
            icon: const FlameIcon(size: 24),
            value: streakDays,
            label: 'day streak',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AccentStatCard(
            backgroundColor: AppColors.greenLight,
            icon: const SparkleStarIcon(size: 24, color: AppColors.green),
            value: totalXp,
            label: 'total XP',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickActionPill(
          icon: Icons.explore_rounded,
          label: 'Explore',
          color: AppColors.purple,
          onTap: () => context.go('/explore'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionPill(
          icon: Icons.school_rounded,
          label: 'Teach',
          color: AppColors.blue,
          onTap: () => context.go('/teach'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionPill(
          icon: Icons.description_rounded,
          label: 'Docs',
          color: AppColors.orange,
          onTap: () => context.push('/documents'),
        ),
      ],
    );
  }

  Widget _buildContinueLearning(BuildContext context) {
    final continueLearning = ref.watch(continueLearningProvider);

    return continueLearning.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.school_rounded,
            message: 'No courses yet. Explore to start learning!',
            actionLabel: 'Explore Courses',
            onAction: () => context.go('/explore'),
          );
        }

        return Column(
          children: items.asMap().entries.map((entry) {
            return StaggeredListItem(
              index: 5 + entry.key,
              child: _ContinueLearningCard(item: entry.value),
            );
          }).toList(),
        );
      },
      loading: () => const ShimmerCard(height: 140),
      error: (_, __) => _buildEmptyState(
        icon: Icons.error_outline_rounded,
        message: 'Could not load courses.',
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = ref.watch(recentActivityProvider);

    return activity.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history_rounded,
            message: 'No activity yet. Complete a lesson to start!',
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: events.asMap().entries.map((entry) {
              return StaggeredListItem(
                index: 7 + entry.key,
                child: _ActivityItem(
                  icon: _iconForEvent(entry.value.type),
                  iconColor: _colorForEvent(entry.value.type),
                  title: entry.value.displayTitle,
                  time: _timeAgo(entry.value.timestamp),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const ShimmerCard(height: 120),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 36),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForEvent(String type) {
    switch (type) {
      case 'lesson_completed':
        return Icons.check_circle_rounded;
      case 'quiz_passed':
        return Icons.quiz_rounded;
      case 'teach_completed':
        return Icons.school_rounded;
      case 'path_started':
        return Icons.play_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _colorForEvent(String type) {
    switch (type) {
      case 'lesson_completed':
        return AppColors.green;
      case 'quiz_passed':
        return AppColors.green;
      case 'teach_completed':
        return AppColors.purple;
      case 'path_started':
        return AppColors.blue;
      default:
        return AppColors.blue;
    }
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}

/// Continue Learning card
class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearningItem item;
  const _ContinueLearningCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final remaining = item.totalLessons - item.completedLessons;
    final percentText = '${(item.percentComplete * 100).toInt()}%';

    return AnimatedPressable(
      onTap: () => context.push('/learn/${item.pathId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.purple, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$remaining lesson${remaining == 1 ? '' : 's'} left',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                Text(
                  percentText,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedProgressBar(progress: item.percentComplete),
            if (item.nextLessonTitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Next: ${item.nextLessonTitle}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick action pill button
class _QuickActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: color.withAlpha(40), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.buttonSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Activity item row
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          StatusDot(
            state: iconColor == AppColors.green
                ? StatusDotState.completed
                : StatusDotState.inProgress,
            size: 8,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            time,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
