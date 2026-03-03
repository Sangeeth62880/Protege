import 'package:cloud_firestore/cloud_firestore.dart';

/// Syllabus model (Response from AI)
class SyllabusModel {
  final String topic;
  final String description;
  final double totalDurationHours;
  final String difficulty;
  final List<String> prerequisites;
  final List<ModuleModel> modules;
  final CapstoneProjectModel? capstoneProject;

  const SyllabusModel({
    required this.topic,
    required this.description,
    required this.totalDurationHours,
    required this.difficulty,
    this.prerequisites = const [],
    required this.modules,
    this.capstoneProject,
  });

  factory SyllabusModel.fromJson(Map<String, dynamic> json) {
    return SyllabusModel(
      topic: json['topic']?.toString() ?? 'Untitled',
      description: json['description']?.toString() ?? '',
      totalDurationHours: (json['total_duration_hours'] as num?)?.toDouble() ?? 0.0,
      difficulty: json['difficulty']?.toString() ?? 'beginner',
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capstoneProject: json['capstone_project'] != null
          ? CapstoneProjectModel.fromJson(json['capstone_project'])
          : null,
    );
  }
}

/// Capstone Project
class CapstoneProjectModel {
  final String title;
  final String description;
  final List<String> skillsApplied;

  const CapstoneProjectModel({
    required this.title,
    required this.description,
    required this.skillsApplied,
  });

  factory CapstoneProjectModel.fromJson(Map<String, dynamic> json) {
    return CapstoneProjectModel(
      title: json['title'] as String,
      description: json['description'] as String,
      skillsApplied: List<String>.from(json['skills_applied'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'skills_applied': skillsApplied,
    };
  }
}

/// Learning path model (Saved in Firestore)
class LearningPathModel {
  final String id;
  final String userId;
  final String topic;
  final String description;
  final String difficulty;
  final List<ModuleModel> modules; // Changed from lessons to modules
  final CapstoneProjectModel? capstoneProject;
  final double progress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;

  const LearningPathModel({
    required this.id,
    required this.userId,
    required this.topic,
    required this.description,
    required this.difficulty,
    required this.modules,
    this.capstoneProject,
    this.progress = 0.0,
    required this.createdAt,
    this.updatedAt,
    this.isCompleted = false,
  });

  // Backward compatibility getter for flat list of lessons
  List<LessonModel> get lessons {
    return modules.expand((m) => m.lessons).toList();
  }

  factory LearningPathModel.fromJson(Map<String, dynamic> json) {
    return LearningPathModel(
      id: json['id'] as String,
      userId: json['user_id'] ?? json['userId'] as String, // Handle snake/camel
      topic: json['topic'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      capstoneProject: json['capstone_project'] != null
          ? CapstoneProjectModel.fromJson(json['capstone_project'])
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? (json['created_at'] is Timestamp 
                ? (json['created_at'] as Timestamp).toDate()
                : DateTime.parse(json['created_at'].toString()))
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is Timestamp 
                ? (json['updated_at'] as Timestamp).toDate()
                : DateTime.parse(json['updated_at'].toString()))
          : null,
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'topic': topic,
      'description': description,
      'difficulty': difficulty,
      'modules': modules.map((e) => e.toJson()).toList(),
      'capstone_project': capstoneProject?.toJson(),
      'progress': progress,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'is_completed': isCompleted,
    };
  }

  LearningPathModel copyWith({
    String? id,
    String? userId,
    String? topic,
    String? description,
    String? difficulty,
    List<ModuleModel>? modules,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return LearningPathModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      modules: modules ?? this.modules,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ModuleModel {
  final int moduleNumber;
  final String title;
  final String description;
  final double durationHours;
  final List<LessonModel> lessons;
  final bool isCompleted;

  const ModuleModel({
    required this.moduleNumber,
    required this.title,
    required this.description,
    required this.durationHours,
    required this.lessons,
    this.isCompleted = false,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      moduleNumber: (json['module_number'] ?? json['moduleNumber'] ?? 0) as int,
      title: json['title']?.toString() ?? 'Untitled Module',
      description: json['description']?.toString() ?? '',
      durationHours: (json['duration_hours'] ?? json['durationHours'] as num?)?.toDouble() ?? 0.0,
      lessons: (json['lessons'] as List<dynamic>?)
              ?.map((e) => LessonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_number': moduleNumber,
      'title': title,
      'description': description,
      'duration_hours': durationHours,
      'lessons': lessons.map((e) => e.toJson()).toList(),
      'completed': isCompleted, // Backend expects 'completed'
    };
  }
}

/// Helper to parse search_queries with null-safe handling
Map<String, String>? _parseSearchQueries(dynamic json) {
  if (json == null) return null;
  final map = json as Map<String, dynamic>;
  final result = <String, String>{};
  for (final entry in map.entries) {
    if (entry.value != null) {
      result[entry.key] = entry.value.toString();
    }
  }
  return result.isEmpty ? null : result;
}

class LessonModel {
  final int lessonNumber;
  final String title;
  final String description;
  final int durationMinutes;
  final List<String> learningObjectives;
  final List<String> keyConcepts; // Added missing field
  final Map<String, String>? searchQueries;
  final bool isCompleted;
  
  // Resources
  final List<String> videoResourceIds;
  final List<String> articleResourceIds;

  const LessonModel({
    required this.lessonNumber,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.learningObjectives = const [],
    this.keyConcepts = const [], // Default empty
    this.searchQueries,
    this.isCompleted = false,
    this.videoResourceIds = const [],
    this.articleResourceIds = const [],
  });
  
  // Compatibility getter for older UI
  int get order => lessonNumber;
  String get id => "$lessonNumber"; // Mock ID for UI compatibility
  String? get quizId => null;

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      lessonNumber: (json['lesson_number'] ?? json['lessonNumber'] ?? json['order'] ?? 0) as int,
      title: json['title']?.toString() ?? 'Untitled Lesson',
      description: json['description']?.toString() ?? '',
      durationMinutes: (json['duration_minutes'] ?? json['durationMinutes'] ?? 15) as int,
      learningObjectives: List<String>.from(json['learning_objectives'] ?? []),
      keyConcepts: List<String>.from(json['key_concepts'] ?? []),
      searchQueries: _parseSearchQueries(json['search_queries']),
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? json['completed'] ?? false,
      videoResourceIds: List<String>.from(json['video_resource_ids'] ?? []),
      articleResourceIds: List<String>.from(json['article_resource_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_number': lessonNumber,
      'title': title,
      'description': description,
      'duration_minutes': durationMinutes,
      'learning_objectives': learningObjectives,
      'key_concepts': keyConcepts, // Include in JSON
      'search_queries': searchQueries,
      'completed': isCompleted, // Backend expects 'completed'
      'video_resource_ids': videoResourceIds,
      'article_resource_ids': articleResourceIds,
    };
  }
  
  LessonModel copyWith({
    bool? isCompleted,
    List<String>? videoResourceIds,
    List<String>? articleResourceIds,
  }) {
    return LessonModel(
      lessonNumber: lessonNumber,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      learningObjectives: learningObjectives,
      keyConcepts: keyConcepts,
      searchQueries: searchQueries,
      isCompleted: isCompleted ?? this.isCompleted,
      videoResourceIds: videoResourceIds ?? this.videoResourceIds,
      articleResourceIds: articleResourceIds ?? this.articleResourceIds,
    );
  }
}
