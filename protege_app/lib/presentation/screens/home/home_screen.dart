import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/dashboard_models.dart';
import '../../widgets/cards/stats_card.dart';
import '../../widgets/common/section_header.dart';

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
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(continueLearningProvider);
            ref.invalidate(recentActivityProvider);
            ref.invalidate(userStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Greeting
                _buildHeader(context, greeting, displayName, user),
                const SizedBox(height: 24),

                // Stats Card — live from user stream
                userData.when(
                  data: (u) => StatsCard(
                    streakDays: u?.currentStreak ?? 0,
                    totalXp: u?.totalXp ?? 0,
                    lessonsCompleted: u?.lessonsCompleted ?? 0,
                  ),
                  loading: () => const StatsCard(
                    streakDays: 0,
                    totalXp: 0,
                    lessonsCompleted: 0,
                  ),
                  error: (_, __) => const StatsCard(
                    streakDays: 0,
                    totalXp: 0,
                    lessonsCompleted: 0,
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Actions
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 28),

                // Continue Learning — live
                const SectionHeader(
                  title: 'Continue Learning',
                  actionText: 'See All',
                  actionIcon: Icons.arrow_forward_ios_rounded,
                ),
                const SizedBox(height: 12),
                _buildContinueLearning(context),
                const SizedBox(height: 28),

                // Recent Activity — live
                const SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 12),
                _buildRecentActivity(),
                
                const SizedBox(height: 24),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '$displayName!',
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              shape: BoxShape.circle,
              image: user?.photoURL != null
                  ? DecorationImage(
                      image: NetworkImage(user!.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.photoURL == null
                ? Center(
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _QuickActionButton(
          icon: Icons.explore_rounded,
          label: 'Explore',
          color: AppColors.primary,
          onTap: () => context.go('/explore'),
        ),
        _QuickActionButton(
          icon: Icons.psychology_rounded,
          label: 'Teach',
          color: AppColors.teachMode,
          onTap: () => context.go('/teach'),
        ),
        _QuickActionButton(
          icon: Icons.quiz_rounded,
          label: 'Quiz',
          color: AppColors.quizMode,
          onTap: () => context.push('/explore'),
        ),
        _QuickActionButton(
          icon: Icons.description_rounded,
          label: 'Docs',
          color: AppColors.info,
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
          children: items.map((item) => _ContinueLearningCard(item: item)).toList(),
        );
      },
      loading: () => const _ContinueLearningShimmer(),
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
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.textTertiary, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No activity yet. Complete a lesson to start!',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: events.map((event) {
              return _ActivityItem(
                icon: _iconForEvent(event.type),
                iconColor: _colorForEvent(event.type),
                title: event.displayTitle,
                time: _timeAgo(event.timestamp),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const _ContinueLearningShimmer(),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
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
        return Icons.psychology_rounded;
      case 'path_started':
        return Icons.play_circle_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _colorForEvent(String type) {
    switch (type) {
      case 'lesson_completed':
        return AppColors.success;
      case 'quiz_passed':
        return AppColors.quizMode;
      case 'teach_completed':
        return AppColors.teachMode;
      case 'path_started':
        return AppColors.primary;
      default:
        return AppColors.info;
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

/// Continue Learning card showing real path progress
class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearningItem item;

  const _ContinueLearningCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final remaining = item.totalLessons - item.completedLessons;
    final percentText = '${(item.percentComplete * 100).toInt()}% complete';
    final lessonsText = '$remaining lesson${remaining == 1 ? '' : 's'} left';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      '$percentText • $lessonsText',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentComplete,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          if (item.nextLessonTitle != null) ...[
            const SizedBox(height: 8),
            Text(
              'Next: ${item.nextLessonTitle}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/learn/${item.pathId}'),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder while loading
class _ContinueLearningShimmer extends StatelessWidget {
  const _ContinueLearningShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
