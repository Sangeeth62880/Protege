import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/dashboard_models.dart';
import '../../widgets/cards/modern_card.dart';
import '../../widgets/common/animated_progress_bar.dart';

/// Progress screen showing live learning stats, weekly overview, and activity calendar
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weeklyStatsProvider);
            ref.invalidate(pathProgressProvider);
            ref.invalidate(userStreamProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              
              // Weekly Overview — live
              SliverToBoxAdapter(
                child: _buildWeeklyOverview(context, ref),
              ),
              
              // Learning Paths Progress — live
              SliverToBoxAdapter(
                child: _buildLearningPaths(context, ref),
              ),
              
              // Activity Calendar — live
              SliverToBoxAdapter(
                child: _buildActivityCalendar(context, ref),
              ),
              
              // Detailed Stats — live
              SliverToBoxAdapter(
                child: _buildDetailedStats(context, ref),
              ),
              
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Keep up the great work! 🎉',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ModernCard(
        margin: EdgeInsets.zero,
        child: weeklyAsync.when(
          data: (stats) => _weeklyContent(stats),
          loading: () => _weeklyContent(WeeklyStats.empty()),
          error: (_, __) => _weeklyContent(WeeklyStats.empty()),
        ),
      ),
    );
  }

  Widget _weeklyContent(WeeklyStats stats) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This Week',
              style: AppTypography.titleMedium,
            ),
            if (stats.totalMinutes > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stats.totalTimeFormatted,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Weekly chart — live values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) => _DayBar(
            day: dayLabels[i],
            value: stats.dayValues[i],
            isToday: i == stats.todayIndex,
          )),
        ),
        
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        
        // Stats row — live
        Row(
          children: [
            Expanded(
              child: _WeekStat(
                label: 'Time Spent',
                value: stats.totalTimeFormatted,
                icon: Icons.timer_outlined,
              ),
            ),
            Expanded(
              child: _WeekStat(
                label: 'Lessons',
                value: '${stats.lessonsCount}',
                icon: Icons.book_outlined,
              ),
            ),
            Expanded(
              child: _WeekStat(
                label: 'XP Earned',
                value: '${stats.xpEarned}',
                icon: Icons.star_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLearningPaths(BuildContext context, WidgetRef ref) {
    final pathsAsync = ref.watch(pathProgressProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Paths',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          pathsAsync.when(
            data: (paths) {
              if (paths.isEmpty) {
                return ModernCard(
                  margin: EdgeInsets.zero,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No learning paths yet. Start exploring!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: paths.asMap().entries.map((entry) {
                  final path = entry.value;
                  final colors = [AppColors.primary, AppColors.secondary, AppColors.teachMode, AppColors.quizMode, AppColors.accent];
                  final color = colors[entry.key % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LearningPathProgress(
                      title: path.title,
                      progress: path.percentComplete,
                      lessonsCompleted: path.lessonsCompleted,
                      totalLessons: path.totalLessons,
                      color: color,
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCalendar(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthEvents = ref.watch(monthlyActivityProvider((year: now.year, month: now.month)));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          
          ModernCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(now),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                monthEvents.when(
                  data: (events) {
                    // Aggregate events by day
                    final dayActivity = <int, int>{};
                    for (final event in events) {
                      final day = event.timestamp.day;
                      dayActivity[day] = (dayActivity[day] ?? 0) + 1;
                    }

                    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                    // First day of month offset (0=Monday in our grid)
                    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon
                    final offset = firstDayWeekday - 1;

                    return Column(
                      children: [
                        // Day headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((d) => SizedBox(
                                    width: 32,
                                    child: Center(
                                      child: Text(d, style: AppTypography.caption.copyWith(color: AppColors.textTertiary)),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        // Calendar grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: offset + daysInMonth,
                          itemBuilder: (context, index) {
                            if (index < offset) {
                              return const SizedBox.shrink();
                            }
                            final day = index - offset + 1;
                            final count = dayActivity[day] ?? 0;
                            final isToday = day == now.day;
                            
                            // Activity intensity
                            int alpha;
                            if (count == 0) {
                              alpha = 0;
                            } else if (count <= 1) {
                              alpha = 77;
                            } else if (count <= 3) {
                              alpha = 140;
                            } else {
                              alpha = 220;
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: count > 0
                                    ? AppColors.primary.withAlpha(alpha)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                                border: isToday
                                    ? Border.all(color: AppColors.primary, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: AppTypography.caption.copyWith(
                                    color: count > 0
                                        ? AppColors.primary
                                        : AppColors.textTertiary,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox(height: 200),
                ),
                
                const SizedBox(height: 12),
                
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: AppColors.surfaceVariant, label: 'No activity'),
                    const SizedBox(width: 16),
                    _LegendItem(color: AppColors.primary.withAlpha(77), label: 'Some'),
                    const SizedBox(width: 16),
                    _LegendItem(color: AppColors.primary.withAlpha(179), label: 'Good'),
                    const SizedBox(width: 16),
                    _LegendItem(color: AppColors.primary, label: 'Great'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, WidgetRef ref) {
    final userDataAsync = ref.watch(userStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Time Stats',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          
          userDataAsync.when(
            data: (userData) {
              final totalMinutes = userData?.totalLearningMinutes ?? 0;
              final hours = totalMinutes ~/ 60;
              final mins = totalMinutes % 60;
              final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

              return ModernCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DetailedStatRow(
                      icon: Icons.timer_rounded,
                      label: 'Total Learning Time',
                      value: timeStr,
                      color: AppColors.info,
                    ),
                    const Divider(height: 1),
                    _DetailedStatRow(
                      icon: Icons.check_circle_rounded,
                      label: 'Lessons Completed',
                      value: '${userData?.lessonsCompleted ?? 0}',
                      color: AppColors.success,
                    ),
                    const Divider(height: 1),
                    _DetailedStatRow(
                      icon: Icons.quiz_rounded,
                      label: 'Quizzes Passed',
                      value: '${userData?.quizzesPassed ?? 0}',
                      color: AppColors.quizMode,
                    ),
                    const Divider(height: 1),
                    _DetailedStatRow(
                      icon: Icons.psychology_rounded,
                      label: 'Teaching Sessions',
                      value: '${userData?.teachSessions ?? 0}',
                      color: AppColors.teachMode,
                    ),
                    const Divider(height: 1),
                    _DetailedStatRow(
                      icon: Icons.emoji_events_rounded,
                      label: 'Achievements Unlocked',
                      value: '${userData?.badges.length ?? 0}',
                      color: AppColors.xp,
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final String day;
  final double value;
  final bool isToday;

  const _DayBar({
    required this.day,
    required this.value,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 32,
                height: 80 * value,
                decoration: BoxDecoration(
                  gradient: isToday 
                      ? AppColors.primaryGradient 
                      : LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(179),
                            AppColors.primary.withAlpha(128),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: AppTypography.labelSmall.copyWith(
            color: isToday ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _WeekStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WeekStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _LearningPathProgress extends StatelessWidget {
  final String title;
  final double progress;
  final int lessonsCompleted;
  final int totalLessons;
  final Color color;

  const _LearningPathProgress({
    required this.title,
    required this.progress,
    required this.lessonsCompleted,
    required this.totalLessons,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$lessonsCompleted/$totalLessons',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedProgressBar(
            progress: progress,
            fillColor: color,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}

class _DetailedStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailedStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
