/// Quiz model for assessments
class QuizModel {
  final String id;
  final String lessonId;
  final String topic;
  final List<QuestionModel> questions;
  final int timeLimit; // in seconds, 0 for no limit
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.lessonId,
    required this.topic,
    required this.questions,
    this.timeLimit = 0,
    required this.createdAt,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      topic: json['topic'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeLimit: json['timeLimit'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'topic': topic,
      'questions': questions.map((e) => e.toJson()).toList(),
      'timeLimit': timeLimit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get totalQuestions => questions.length;
}

/// Individual question model
class QuestionModel {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options; // for multiple choice
  final String correctAnswer;
  final String? explanation;
  final int points;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    required this.correctAnswer,
    this.explanation,
    this.points = 1,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      question: json['question'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String?,
      points: json['points'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'type': type.name,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }
}

/// Types of quiz questions
enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  fillBlank,
}

/// Quiz result model
class QuizResultModel {
  final String id;
  final String quizId;
  final String userId;
  final int score;
  final int totalPoints;
  final List<AnswerModel> answers;
  final Duration timeTaken;
  final DateTime completedAt;

  const QuizResultModel({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.score,
    required this.totalPoints,
    required this.answers,
    required this.timeTaken,
    required this.completedAt,
  });

  double get percentage => totalPoints > 0 ? (score / totalPoints) * 100 : 0;

  bool get passed => percentage >= 70;

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      id: json['id'] as String,
      quizId: json['quizId'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      totalPoints: json['totalPoints'] as int,
      answers: (json['answers'] as List<dynamic>)
          .map((e) => AnswerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeTaken: Duration(seconds: json['timeTakenSeconds'] as int),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizId': quizId,
      'userId': userId,
      'score': score,
      'totalPoints': totalPoints,
      'answers': answers.map((e) => e.toJson()).toList(),
      'timeTakenSeconds': timeTaken.inSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

/// Individual answer model
class AnswerModel {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;

  const AnswerModel({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }
}
