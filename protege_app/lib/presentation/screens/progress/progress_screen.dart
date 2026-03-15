import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/dashboard_models.dart';
import '../../widgets/common/animated_progress_bar.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/common/count_up_text.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';

/// Progress screen — shows real Firestore data
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final pathProgress = ref.watch(pathProgressProvider);
    final userState = ref.watch(userStreamProvider);
    final recentActivity = ref.watch(recentActivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async {
            ref.invalidate(weeklyStatsProvider);
            ref.invalidate(pathProgressProvider);
            ref.invalidate(recentActivityProvider);
            ref.invalidate(userStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: AppSpacing.screenH.copyWith(top: 20, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StaggeredItem(
                  index: 0,
                  child: Text('Progress', style: AppTypography.headingLg),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Top Stats (XP, Streak, Lessons) ──
                StaggeredItem(
                  index: 1,
                  child: userState.when(
                    data: (user) {
                      if (user == null) return const SizedBox.shrink();
                      return Row(
                        children: [
                          Expanded(child: _StatCard(icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill), color: AppColors.accentOrange, value: user.totalXp, label: 'Total XP')),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _StatCard(icon: PhosphorIcons.fire(PhosphorIconsStyle.fill), color: AppColors.error, value: user.currentStreak, label: 'Day Streak')),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: _StatCard(icon: PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.success, value: user.lessonsCompleted, label: 'Lessons')),
                        ],
                      );
                    },
                    loading: () => const Row(
                      children: [
                        Expanded(child: ShimmerCard(height: 100)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: ShimmerCard(height: 100)),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: ShimmerCard(height: 100)),
                      ],
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── Weekly Stats ──
                StaggeredItem(
                  index: 2,
                  child: weeklyStats.when(
                    data: (stats) => _WeeklyStatsCard(stats: stats),
                    loading: () => const ShimmerCard(height: 200),
                    error: (_, __) => const ShimmerCard(height: 200),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Path Progress ──
                StaggeredItem(
                  index: 3,
                  child: const SectionHeader(title: 'Learning Paths'),
                ),
                pathProgress.when(
                  data: (paths) {
                    if (paths.isEmpty) {
                      return EmptyState(
                        icon: PhosphorIcons.trendUp(),
                        title: 'No progress yet',
                        subtitle: 'Complete lessons to see your progress here',
                      );
                    }
                    return Column(
                      children: paths.asMap().entries.map((entry) {
                        return StaggeredItem(
                          index: 3 + entry.key,
                          child: _PathProgressCard(summary: entry.value),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const ShimmerCard(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // ── Recent Activity Timeline ──
                StaggeredItem(
                  index: 4 + (pathProgress.valueOrNull?.length ?? 0),
                  child: const SectionHeader(title: 'Recent Activity'),
                ),
                recentActivity.when(
                  data: (events) {
                    if (events.isEmpty) {
                      return EmptyState(
                        icon: PhosphorIcons.clock(),
                        title: 'No activity yet',
                        subtitle: 'Your recent learning events will appear here',
                      );
                    }
                    return Column(
                      children: events.asMap().entries.map((entry) {
                        return StaggeredItem(
                          index: 5 + (pathProgress.valueOrNull?.length ?? 0) + entry.key,
                          child: _TimelineItem(
                            event: entry.value,
                            isLast: entry.key == events.length - 1,
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const ShimmerCard(height: 150),
                  error: (e, _) => Center(child: Text('Error loading activity: $e')),
                ),
                const SizedBox(height: AppSpacing.navbarClearance),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Weekly stats card with bar chart
class _WeeklyStatsCard extends StatelessWidget {
  final WeeklyStats stats;
  const _WeeklyStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week', style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.xl),

          // Stats row
          Row(
            children: [
              _MiniStat(
                icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                color: AppColors.brand,
                value: '${stats.lessonsCount}',
                label: 'lessons',
              ),
              const SizedBox(width: AppSpacing.xl),
              _MiniStat(
                icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                color: AppColors.success,
                value: '${stats.xpEarned}',
                label: 'XP earned',
              ),
              const SizedBox(width: AppSpacing.xl),
              _MiniStat(
                icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
                color: AppColors.accentOrange,
                value: '${stats.totalMinutes}',
                label: 'minutes',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Bar chart
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.dayValues.asMap().entries.map((entry) {
                final i = entry.key;
                final value = entry.value;
                final isToday = i == stats.todayIndex;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: AppMotion.slow,
                              curve: AppMotion.curveDecelerate,
                              width: double.infinity,
                              height: (value * 80).clamp(4.0, 80.0),
                              decoration: BoxDecoration(
                                color: isToday ? AppColors.brand : AppColors.brandLight,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          dayLabels[i],
                          style: AppTypography.bodySm.copyWith(
                            color: isToday ? AppColors.brand : AppColors.textTertiary,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final PhosphorIconData icon;
  final Color color;
  final String value;
  final String label;
  const _MiniStat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhosphorIcon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.statSm),
        Text(label, style: AppTypography.bodySm),
      ],
    );
  }
}

/// Individual path progress card
class _PathProgressCard extends StatelessWidget {
  final PathProgressSummary summary;
  const _PathProgressCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Expanded(
                child: Text(
                  summary.title,
                  style: AppTypography.headingSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(summary.percentComplete * 100).toInt()}%',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedProgressBar(progress: summary.percentComplete, fillColor: AppColors.brand),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${summary.lessonsCompleted}/${summary.totalLessons} lessons completed',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

/// A generic card to show a top-level stat (XP, streak, etc.)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSpacing.md),
          CountUpText(
            end: value,
            style: AppTypography.headingMd,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A timeline item to show an activity event
class _TimelineItem extends StatelessWidget {
  final ActivityEvent event;
  final bool isLast;

  const _TimelineItem({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final bool isLesson = event.type == 'lesson_completed';
    final bool isPath = event.type == 'path_completed';
    
    final icon = isPath ? PhosphorIcons.trophy(PhosphorIconsStyle.fill) 
               : isLesson ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
               : PhosphorIcons.bookOpen(PhosphorIconsStyle.fill);
               
    final color = isPath ? AppColors.accentOrange : AppColors.brand;

    // Time ago
    final diff = DateTime.now().difference(event.timestamp);
    String timeAgo;
    if (diff.inDays > 0) {
      timeAgo = '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      timeAgo = '${diff.inMinutes}m ago';
    } else {
      timeAgo = 'Just now';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline line + icon
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isLesson ? 'Lesson Completed' : (isPath ? 'Path Completed' : 'Activity'),
                        style: AppTypography.bodySm.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        timeAgo,
                        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (event.meta?['xp'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${event.meta!['xp']} XP',
                      style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
