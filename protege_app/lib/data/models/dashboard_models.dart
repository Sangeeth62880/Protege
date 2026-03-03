import 'package:cloud_firestore/cloud_firestore.dart';

/// Item for "Continue Learning" section on Home
class ContinueLearningItem {
  final String pathId;
  final String title;
  final String difficulty;
  final String? nextLessonTitle;
  final int nextLessonIndex;
  final double percentComplete;
  final DateTime? lastActivityAt;
  final int totalLessons;
  final int completedLessons;

  const ContinueLearningItem({
    required this.pathId,
    required this.title,
    required this.difficulty,
    this.nextLessonTitle,
    required this.nextLessonIndex,
    required this.percentComplete,
    this.lastActivityAt,
    required this.totalLessons,
    required this.completedLessons,
  });
}

/// Activity event for the feed
class ActivityEvent {
  final String id;
  final String type; // lesson_completed, quiz_passed, teach_completed, path_started
  final String title;
  final String? pathId;
  final String? lessonId;
  final DateTime timestamp;
  final Map<String, dynamic>? meta;

  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    this.pathId,
    this.lessonId,
    required this.timestamp,
    this.meta,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> json, String docId) {
    return ActivityEvent(
      id: docId,
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      pathId: json['pathId'] as String?,
      lessonId: json['lessonId'] as String?,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'pathId': pathId,
      'lessonId': lessonId,
      'timestamp': Timestamp.fromDate(timestamp),
      'meta': meta,
    };
  }

  /// Human-readable description
  String get displayTitle {
    switch (type) {
      case 'lesson_completed':
        return 'Completed "$title"';
      case 'quiz_passed':
        return 'Scored ${meta?['score'] ?? ''}% on $title quiz';
      case 'teach_completed':
        return 'Taught "$title"';
      case 'path_started':
        return 'Started learning "$title"';
      default:
        return title;
    }
  }

  /// Icon data key for UI
  String get iconKey {
    switch (type) {
      case 'lesson_completed':
        return 'check_circle';
      case 'quiz_passed':
        return 'quiz';
      case 'teach_completed':
        return 'psychology';
      case 'path_started':
        return 'play_circle';
      default:
        return 'info';
    }
  }
}

/// Per-path progress summary for Progress screen
class PathProgressSummary {
  final String pathId;
  final String title;
  final double percentComplete;
  final int lessonsCompleted;
  final int totalLessons;
  final DateTime? lastActivityAt;

  const PathProgressSummary({
    required this.pathId,
    required this.title,
    required this.percentComplete,
    required this.lessonsCompleted,
    required this.totalLessons,
    this.lastActivityAt,
  });
}

/// Weekly learning stats
class WeeklyStats {
  final List<double> dayValues; // 7 values, Mon-Sun (0.0 - 1.0 normalized)
  final List<int> dayMinutes; // actual minutes per day
  final int totalMinutes;
  final int lessonsCount;
  final int xpEarned;
  final int todayIndex; // 0=Mon, 6=Sun

  const WeeklyStats({
    required this.dayValues,
    required this.dayMinutes,
    required this.totalMinutes,
    required this.lessonsCount,
    required this.xpEarned,
    required this.todayIndex,
  });

  /// Empty / zero week
  factory WeeklyStats.empty() {
    final now = DateTime.now();
    return WeeklyStats(
      dayValues: List.filled(7, 0.0),
      dayMinutes: List.filled(7, 0),
      totalMinutes: 0,
      lessonsCount: 0,
      xpEarned: 0,
      todayIndex: (now.weekday - 1).clamp(0, 6),
    );
  }

  String get totalTimeFormatted {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }
}
