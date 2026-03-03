import 'package:flutter/foundation.dart';
import 'resource_models.dart';

/// Represents the full content of a lesson
class LessonContent {
  final String id;
  final String title;
  final String description;
  final LessonExplanation explanation;
  final LessonResources resources;
  final bool isCompleted;

  const LessonContent({
    required this.id,
    required this.title,
    required this.description,
    required this.explanation,
    this.resources = const LessonResources(lessonTitle: ''),
    this.isCompleted = false,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      explanation: LessonExplanation.fromJson(json['explanation'] ?? {}),
      resources: json['resources'] != null
          ? LessonResources.fromJson(json['resources'])
          : const LessonResources(lessonTitle: ''),
      isCompleted: json['is_completed'] ?? false,
    );
  }

  /// Create a mock lesson content for development/testing
  factory LessonContent.mock(String title) {
    return LessonContent(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: 'Learn the fundamentals of $title with this interactive lesson.',
      explanation: LessonExplanation.mock(title),
      resources: const LessonResources(lessonTitle: ''),
    );
  }
}

/// Structured explanation of the lesson topic
class LessonExplanation {
  final String introduction;
  final List<ContentSection> sections;
  final String summary;
  final List<String> keyTakeaways;

  const LessonExplanation({
    required this.introduction,
    required this.sections,
    required this.summary,
    required this.keyTakeaways,
  });

  factory LessonExplanation.fromJson(Map<String, dynamic> json) {
    return LessonExplanation(
      introduction: json['introduction'] ?? '',
      sections: (json['sections'] as List?)
              ?.map((e) => ContentSection.fromJson(e))
              .toList() ??
          [],
      summary: json['summary'] ?? '',
      keyTakeaways: List<String>.from(json['key_takeaways'] ?? []),
    );
  }

  factory LessonExplanation.mock(String topic) {
    return LessonExplanation(
      introduction: 'Welcome to this lesson on $topic. In this session, we will explore the core concepts and practical applications.',
      sections: [
        ContentSection(
          title: 'What is $topic?',
          content: '$topic is a fundamental concept that allows you to build scalable and maintainable applications. It forms the backbone of modern software development.',
          codeExample: null,
        ),
        ContentSection(
          title: 'Core Concepts',
          content: 'Understanding the syntax and structure is crucial. Here is a simple example to get you started:',
          codeExample: 'void main() {\n  print("Hello, $topic!");\n}',
          language: 'dart',
        ),
        ContentSection(
          title: 'Best Practices',
          content: 'Always ensure your code is readable and well-documented. Avoid magic numbers and use meaningful variable names.',
          codeExample: null,
        ),
      ],
      summary: 'To wrap up, $topic is essential for your journey. Practice the examples provided to solidify your understanding.',
      keyTakeaways: [
        'Understand the basic syntax.',
        'Practice writing clean code.',
        'Apply $topic in real-world scenarios.',
      ],
    );
  }
}

/// A specific section of the lesson explanation
class ContentSection {
  final String title;
  final String content;
  final String? codeExample;
  final String? language;
  final String? imageUrl;

  const ContentSection({
    required this.title,
    required this.content,
    this.codeExample,
    this.language,
    this.imageUrl,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    return ContentSection(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      codeExample: json['code_example'],
      language: json['language'],
      imageUrl: json['image_url'],
    );
  }
}
