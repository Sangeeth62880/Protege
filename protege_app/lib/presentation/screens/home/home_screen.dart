import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/dashboard_models.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/animated_progress_bar.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/count_up_text.dart';

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
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayOfWeek = dayNames[DateTime.now().weekday - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async {
            ref.invalidate(continueLearningProvider);
            ref.invalidate(recentActivityProvider);
            ref.invalidate(userStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: AppSpacing.screenH.copyWith(top: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                StaggeredItem(
                  index: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: AppTypography.bodyLg.copyWith(color: AppColors.textTertiary),
                            ),
                            Text(displayName, style: AppTypography.headingLg),
                          ],
                        ),
                      ),
                      AnimatedPressable(
                        onTap: () => context.go('/profile'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: PhosphorIcon(
                            PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                            size: 26,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StaggeredItem(
                  index: 1,
                  child: Text(dayOfWeek, style: AppTypography.bodySm),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Stat Cards ──
                StaggeredItem(
                  index: 2,
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

                // ── Quick Actions ──
                StaggeredItem(
                  index: 3,
                  child: _buildQuickActions(context),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Continue Learning ──
                StaggeredItem(
                  index: 4,
                  child: const SectionHeader(title: 'Continue Learning'),
                ),
                _buildContinueLearning(context),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Recent Activity ──
                StaggeredItem(
                  index: 6,
                  child: const SectionHeader(title: 'Recent Activity'),
                ),
                _buildRecentActivity(),
                const SizedBox(height: AppSpacing.navbarClearance),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards({required int streakDays, required int totalXp}) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.flame(PhosphorIconsStyle.fill),
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CountUpText(end: streakDays, style: AppTypography.statSm),
                    Text('day streak', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                  size: 20,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CountUpText(end: totalXp, style: AppTypography.statSm),
                    Text('total XP', style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickActionPill(
          icon: PhosphorIcons.compass(),
          label: 'Explore',
          color: AppColors.brand,
          onTap: () => context.go('/explore'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionPill(
          icon: PhosphorIcons.brain(),
          label: 'Teach',
          color: AppColors.accentTeal,
          onTap: () => context.go('/teach'),
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionPill(
          icon: PhosphorIcons.fileText(),
          label: 'Docs',
          color: AppColors.accentOrange,
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
          return EmptyState(
            icon: PhosphorIcons.bookOpen(),
            title: 'No courses yet',
            subtitle: 'Explore to start learning!',
            actionLabel: 'Explore Courses',
            onAction: () => context.go('/explore'),
          );
        }

        return Column(
          children: items.asMap().entries.map((entry) {
            return StaggeredItem(
              index: 5 + entry.key,
              child: _ContinueLearningCard(item: entry.value),
            );
          }).toList(),
        );
      },
      loading: () => const ShimmerCard(height: 140),
      error: (_, __) => EmptyState(
        icon: PhosphorIcons.warning(),
        title: 'Could not load courses',
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = ref.watch(recentActivityProvider);

    return activity.when(
      data: (events) {
        if (events.isEmpty) {
          return EmptyState(
            icon: PhosphorIcons.clockCounterClockwise(),
            title: 'No activity yet',
            subtitle: 'Complete a lesson to start!',
          );
        }

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadow.sm,
          ),
          child: Column(
            children: events.asMap().entries.map((entry) {
              return StaggeredItem(
                index: 7 + entry.key,
                child: _ActivityItem(
                  type: entry.value.type,
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
    return AnimatedPressable(
      onTap: () => context.push('/learn/${item.pathId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: AppTypography.labelSm.copyWith(color: AppColors.brand),
                ),
                const Spacer(),
                PhosphorIcon(PhosphorIcons.arrowRight(), size: 16, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.title, style: AppTypography.headingMd, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.md),
            AnimatedProgressBar(progress: item.percentComplete),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${item.completedLessons}/${item.totalLessons} lessons',
              style: AppTypography.bodySm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action pill button
class _QuickActionPill extends StatelessWidget {
  final PhosphorIconData icon;
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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.btnMd.copyWith(color: color, fontSize: 13),
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
  final String type;
  final String title;
  final String time;

  const _ActivityItem({
    required this.type,
    required this.title,
    required this.time,
  });

  PhosphorIconData _iconForType() {
    switch (type) {
      case 'lesson_completed':
        return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      case 'quiz_passed':
        return PhosphorIcons.exam(PhosphorIconsStyle.fill);
      case 'teach_completed':
        return PhosphorIcons.brain(PhosphorIconsStyle.fill);
      case 'path_started':
        return PhosphorIcons.playCircle(PhosphorIconsStyle.fill);
      default:
        return PhosphorIcons.info(PhosphorIconsStyle.fill);
    }
  }

  Color _colorForType() {
    switch (type) {
      case 'lesson_completed':
      case 'quiz_passed':
        return AppColors.success;
      case 'teach_completed':
        return AppColors.brand;
      case 'path_started':
        return AppColors.info;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: PhosphorIcon(_iconForType(), size: 16, color: color),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodyMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(time, style: AppTypography.bodySm),
        ],
      ),
    );
  }
}
