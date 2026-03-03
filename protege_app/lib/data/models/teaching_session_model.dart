import 'persona_model.dart';

/// Aha! meter score breakdown
class AhaBreakdown {
  final int clarity;
  final int accuracy;
  final int completeness;

  const AhaBreakdown({
    this.clarity = 0,
    this.accuracy = 0,
    this.completeness = 0,
  });

  factory AhaBreakdown.fromJson(Map<String, dynamic> json) {
    return AhaBreakdown(
      clarity: (json['clarity'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
      completeness: (json['completeness'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clarity': clarity,
      'accuracy': accuracy,
      'completeness': completeness,
    };
  }
}

/// Teaching session model for reverse tutoring (Aha! Meter)
class TeachingSessionModel {
  final String id;
  final String userId;
  final String topicId;
  final String topic;
  final PersonaModel? persona;
  final List<TeachingMessageModel> messages;
  final double ahaMeterScore; // 0.0 to 100.0
  final AhaBreakdown ahaBreakdown;
  final List<String> conceptsToCover;
  final List<String> conceptsCovered;
  final TeachingStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? feedback;

  const TeachingSessionModel({
    required this.id,
    required this.userId,
    required this.topicId,
    required this.topic,
    this.persona,
    this.messages = const [],
    this.ahaMeterScore = 0.0,
    this.ahaBreakdown = const AhaBreakdown(),
    this.conceptsToCover = const [],
    this.conceptsCovered = const [],
    this.status = TeachingStatus.inProgress,
    required this.createdAt,
    this.completedAt,
    this.feedback,
  });

  factory TeachingSessionModel.fromJson(Map<String, dynamic> json) {
    return TeachingSessionModel(
      id: json['id'] as String? ?? json['session_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      topicId: json['topicId'] as String? ?? json['topic_id'] as String? ?? '',
      topic: json['topic'] as String,
      persona: json['persona'] != null
          ? PersonaModel.fromJson(json['persona'] as Map<String, dynamic>)
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => TeachingMessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ahaMeterScore: (json['ahaMeterScore'] as num?)?.toDouble() ??
          (json['aha_meter_score'] as num?)?.toDouble() ??
          (json['aha_score'] as num?)?.toDouble() ??
          0.0,
      ahaBreakdown: json['aha_breakdown'] != null
          ? AhaBreakdown.fromJson(json['aha_breakdown'] as Map<String, dynamic>)
          : const AhaBreakdown(),
      conceptsToCover: (json['concepts_to_cover'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conceptsCovered: (json['concepts_covered'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      status: TeachingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TeachingStatus.inProgress,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : json['completed_at'] != null
              ? DateTime.parse(json['completed_at'] as String)
              : null,
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'topicId': topicId,
      'topic': topic,
      'persona': persona?.toJson(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'ahaMeterScore': ahaMeterScore,
      'aha_breakdown': ahaBreakdown.toJson(),
      'concepts_to_cover': conceptsToCover,
      'concepts_covered': conceptsCovered,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'feedback': feedback,
    };
  }

  TeachingSessionModel copyWith({
    String? id,
    String? userId,
    String? topicId,
    String? topic,
    PersonaModel? persona,
    List<TeachingMessageModel>? messages,
    double? ahaMeterScore,
    AhaBreakdown? ahaBreakdown,
    List<String>? conceptsToCover,
    List<String>? conceptsCovered,
    TeachingStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? feedback,
  }) {
    return TeachingSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      topicId: topicId ?? this.topicId,
      topic: topic ?? this.topic,
      persona: persona ?? this.persona,
      messages: messages ?? this.messages,
      ahaMeterScore: ahaMeterScore ?? this.ahaMeterScore,
      ahaBreakdown: ahaBreakdown ?? this.ahaBreakdown,
      conceptsToCover: conceptsToCover ?? this.conceptsToCover,
      conceptsCovered: conceptsCovered ?? this.conceptsCovered,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      feedback: feedback ?? this.feedback,
    );
  }

  /// Check if the user has demonstrated understanding
  bool get hasProvenUnderstanding => ahaMeterScore >= 85.0;

  /// Get progress percentage towards mastery
  double get progressToMastery => (ahaMeterScore / 85.0).clamp(0.0, 1.0);
}

/// Individual message in a teaching session
class TeachingMessageModel {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final double? partialScore; // AI's evaluation of this explanation
  final List<String> conceptsMentioned;
  final Map<String, dynamic>? evaluation;

  const TeachingMessageModel({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.partialScore,
    this.conceptsMentioned = const [],
    this.evaluation,
  });

  factory TeachingMessageModel.fromJson(Map<String, dynamic> json) {
    return TeachingMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      partialScore: (json['partialScore'] as num?)?.toDouble() ??
          (json['partial_score'] as num?)?.toDouble(),
      conceptsMentioned: (json['concepts_mentioned'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      evaluation: json['evaluation'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'partialScore': partialScore,
      'concepts_mentioned': conceptsMentioned,
      'evaluation': evaluation,
    };
  }
}

/// Message roles in teaching session
enum MessageRole {
  user, // The learner (teaching the AI)
  ai, // The AI (pretending to be confused student)
  system, // System messages
}

/// Teaching session status
enum TeachingStatus {
  inProgress,
  completed,
  abandoned,
}

extension TeachingStatusExtension on TeachingStatus {
  String get displayName {
    switch (this) {
      case TeachingStatus.inProgress:
        return 'In Progress';
      case TeachingStatus.completed:
        return 'Completed';
      case TeachingStatus.abandoned:
        return 'Abandoned';
    }
  }
}

/// Teaching session results model
class TeachingResultsModel {
  final String sessionId;
  final String topic;
  final String personaName;
  final int finalScore;
  final AhaBreakdown ahaBreakdown;
  final List<String> conceptsCovered;
  final List<String> conceptsMissing;
  final int timeSpentSeconds;
  final int messageCount;
  final List<String> strengths;
  final List<String> improvements;
  final String feedback;

  const TeachingResultsModel({
    required this.sessionId,
    required this.topic,
    required this.personaName,
    required this.finalScore,
    required this.ahaBreakdown,
    this.conceptsCovered = const [],
    this.conceptsMissing = const [],
    this.timeSpentSeconds = 0,
    this.messageCount = 0,
    this.strengths = const [],
    this.improvements = const [],
    required this.feedback,
  });

  factory TeachingResultsModel.fromJson(Map<String, dynamic> json) {
    return TeachingResultsModel(
      sessionId: json['session_id'] as String,
      topic: json['topic'] as String,
      personaName: json['persona_name'] as String,
      finalScore: (json['final_score'] as num).toInt(),
      ahaBreakdown: AhaBreakdown.fromJson(
          json['aha_breakdown'] as Map<String, dynamic>),
      conceptsCovered: (json['concepts_covered'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      conceptsMissing: (json['concepts_missing'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timeSpentSeconds: (json['time_spent_seconds'] as num?)?.toInt() ?? 0,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      improvements: (json['improvements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      feedback: json['feedback'] as String,
    );
  }
}
