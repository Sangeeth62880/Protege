import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// User model with learning preferences
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final List<String> learningPathIds;
  final UserPreferences preferences;
  
  // Learning profile
  final String? learningGoal;
  final String experienceLevel; // beginner, intermediate, advanced
  final int dailyTimeMinutes;
  final int totalXp;
  final int currentStreak;

  // Aggregated stats
  final int lessonsCompleted;
  final int totalLearningMinutes;
  final int teachSessions;
  final int quizzesPassed;
  final List<Map<String, dynamic>> badges;
  final DateTime? lastActivityAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.learningPathIds = const [],
    this.preferences = const UserPreferences(),
    this.learningGoal,
    this.experienceLevel = 'beginner',
    this.dailyTimeMinutes = 30,
    this.totalXp = 0,
    this.currentStreak = 0,
    this.lessonsCompleted = 0,
    this.totalLearningMinutes = 0,
    this.teachSessions = 0,
    this.quizzesPassed = 0,
    this.badges = const [],
    this.lastActivityAt,
  });

  /// Create from Firebase Auth User
  factory UserModel.fromFirebaseUser(auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Learner',
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String? ?? 'Learner',
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] is Timestamp
              ? (json['lastLoginAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastLoginAt'] as String))
          : null,
      learningPathIds: List<String>.from(json['learningPathIds'] ?? []),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'])
          : const UserPreferences(),
      learningGoal: json['learningGoal'] as String?,
      experienceLevel: json['experienceLevel'] as String? ?? 'beginner',
      dailyTimeMinutes: json['dailyTimeMinutes'] as int? ?? 30,
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      totalLearningMinutes: json['totalLearningMinutes'] as int? ?? 0,
      teachSessions: json['teachSessions'] as int? ?? 0,
      quizzesPassed: json['quizzesPassed'] as int? ?? 0,
      badges: (json['badges'] as List<dynamic>?)
          ?.map((b) => Map<String, dynamic>.from(b as Map))
          .toList() ?? [],
      lastActivityAt: json['lastActivityAt'] != null
          ? (json['lastActivityAt'] is Timestamp
              ? (json['lastActivityAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastActivityAt'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'learningPathIds': learningPathIds,
      'preferences': preferences.toJson(),
      'learningGoal': learningGoal,
      'experienceLevel': experienceLevel,
      'dailyTimeMinutes': dailyTimeMinutes,
      'totalXp': totalXp,
      'currentStreak': currentStreak,
      'lessonsCompleted': lessonsCompleted,
      'totalLearningMinutes': totalLearningMinutes,
      'teachSessions': teachSessions,
      'quizzesPassed': quizzesPassed,
      'badges': badges,
      'lastActivityAt': lastActivityAt != null ? Timestamp.fromDate(lastActivityAt!) : null,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    List<String>? learningPathIds,
    UserPreferences? preferences,
    String? learningGoal,
    String? experienceLevel,
    int? dailyTimeMinutes,
    int? totalXp,
    int? currentStreak,
    int? lessonsCompleted,
    int? totalLearningMinutes,
    int? teachSessions,
    int? quizzesPassed,
    List<Map<String, dynamic>>? badges,
    DateTime? lastActivityAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      learningPathIds: learningPathIds ?? this.learningPathIds,
      preferences: preferences ?? this.preferences,
      learningGoal: learningGoal ?? this.learningGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      totalLearningMinutes: totalLearningMinutes ?? this.totalLearningMinutes,
      teachSessions: teachSessions ?? this.teachSessions,
      quizzesPassed: quizzesPassed ?? this.quizzesPassed,
      badges: badges ?? this.badges,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

/// User preferences model
class UserPreferences {
  final String themeMode; // light, dark, system
  final bool notificationsEnabled;
  final bool soundEnabled;
  final String preferredLanguage;

  const UserPreferences({
    this.themeMode = 'system',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.preferredLanguage = 'en',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      themeMode: json['themeMode'] as String? ?? 'system',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'preferredLanguage': preferredLanguage,
    };
  }

  UserPreferences copyWith({
    String? themeMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    String? preferredLanguage,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
