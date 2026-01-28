/// Quiz model matching backend structure
class QuizModel {
  final String? quizId;
  final String quizTitle;
  final String? lessonId;
  final int totalQuestions;
  final int estimatedTimeMinutes;
  final List<QuestionModel> questions;

  const QuizModel({
    this.quizId,
    required this.quizTitle,
    this.lessonId,
    required this.totalQuestions,
    required this.estimatedTimeMinutes,
    required this.questions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quiz_id'] as String?,
      quizTitle: json['quiz_title'] as String,
      lessonId: json['lesson_id'] as String?,
      totalQuestions: json['total_questions'] as int,
      estimatedTimeMinutes: json['estimated_time_minutes'] as int,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'lesson_id': lessonId,
      'total_questions': totalQuestions,
      'estimated_time_minutes': estimatedTimeMinutes,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class QuestionModel {
  final int questionNumber;
  final String questionType;
  final String difficulty;
  final String questionText;
  final List<String>? options;
  final String correctAnswer;
  final List<String>? acceptableAnswers;
  final String? codeTemplate;
  final String explanation;
  final String? conceptTested;

  const QuestionModel({
    required this.questionNumber,
    required this.questionType,
    required this.difficulty,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    this.acceptableAnswers,
    this.codeTemplate,
    required this.explanation,
    this.conceptTested,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      questionNumber: json['question_number'] as int,
      questionType: json['question_type'] as String,
      difficulty: json['difficulty'] as String,
      questionText: json['question_text'] as String,
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      correctAnswer: json['correct_answer'] as String,
      acceptableAnswers: (json['acceptable_answers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      codeTemplate: json['code_template'] as String?,
      explanation: json['explanation'] as String,
      conceptTested: json['concept_tested'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_number': questionNumber,
      'question_type': questionType,
      'difficulty': difficulty,
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'acceptable_answers': acceptableAnswers,
      'code_template': codeTemplate,
      'explanation': explanation,
      'concept_tested': conceptTested,
    };
  }
}

class QuizResultModel {
  final String quizId;
  final String userId;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final int timeTakenSeconds;
  final List<QuestionResultModel> questionResults;
  final bool passed;

  const QuizResultModel({
    required this.quizId,
    required this.userId,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.timeTakenSeconds,
    required this.questionResults,
    required this.passed,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quiz_id'] as String,
      userId: json['user_id'] as String,
      score: json['score'] as int,
      correctCount: json['correct_count'] as int,
      totalQuestions: json['total_questions'] as int,
      timeTakenSeconds: json['time_taken_seconds'] as int,
      questionResults: (json['question_results'] as List<dynamic>)
          .map((e) => QuestionResultModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      passed: json['passed'] as bool,
    );
  }
}

class QuestionResultModel {
  final int questionNumber;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? explanation;

  const QuestionResultModel({
    required this.questionNumber,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.explanation,
  });

  factory QuestionResultModel.fromJson(Map<String, dynamic> json) {
    return QuestionResultModel(
      questionNumber: json['question_number'] as int,
      userAnswer: json['user_answer'] as String,
      correctAnswer: json['correct_answer'] as String,
      isCorrect: json['is_correct'] as bool,
      explanation: json['explanation'] as String?,
    );
  }
}
