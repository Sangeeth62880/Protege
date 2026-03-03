import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dashboard_models.dart';
import 'auth_provider.dart';
import 'learning_provider.dart';

/// Continue Learning items for Home screen
final continueLearningProvider = FutureProvider<List<ContinueLearningItem>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getContinueLearningPaths(currentUser.uid);
});

/// Recent activity feed for Home screen
final recentActivityProvider = FutureProvider<List<ActivityEvent>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getRecentActivity(currentUser.uid, limit: 10);
});

/// Path progress summaries for Progress screen
final pathProgressProvider = FutureProvider<List<PathProgressSummary>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getPathProgressSummaries(currentUser.uid);
});

/// Weekly stats for Progress screen chart
final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return WeeklyStats.empty();

  final learningRepo = ref.watch(learningRepositoryProvider);
  final events = await learningRepo.getWeeklyActivityEvents(currentUser.uid);

  if (events.isEmpty) return WeeklyStats.empty();

  // Aggregate events by day of the week
  final now = DateTime.now();
  final todayIndex = (now.weekday - 1).clamp(0, 6); // 0=Mon, 6=Sun
  final dayMinutes = List.filled(7, 0);
  var totalLessons = 0;
  var totalXp = 0;

  for (final event in events) {
    final dayIdx = (event.timestamp.weekday - 1).clamp(0, 6);
    final minutes = (event.meta?['durationMinutes'] as int?) ?? 15;
    dayMinutes[dayIdx] += minutes;

    if (event.type == 'lesson_completed') totalLessons++;
    totalXp += (event.meta?['xp'] as int?) ?? 25;
  }

  final totalMinutes = dayMinutes.fold(0, (sum, m) => sum + m);
  final maxMinutes = dayMinutes.reduce((a, b) => a > b ? a : b);

  // Normalize to 0.0 - 1.0
  final dayValues = dayMinutes
      .map((m) => maxMinutes > 0 ? m / maxMinutes : 0.0)
      .toList();

  return WeeklyStats(
    dayValues: dayValues,
    dayMinutes: dayMinutes,
    totalMinutes: totalMinutes,
    lessonsCount: totalLessons,
    xpEarned: totalXp,
    todayIndex: todayIndex,
  );
});

/// Monthly activity events for Progress calendar heatmap
final monthlyActivityProvider = FutureProvider.family<List<ActivityEvent>, ({int year, int month})>((ref, params) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final learningRepo = ref.watch(learningRepositoryProvider);
  return await learningRepo.getMonthlyActivityEvents(currentUser.uid, params.year, params.month);
});
