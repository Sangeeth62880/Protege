/// Resource Types
enum ResourceType { video, article, repository, wikipedia, book, qa, course, documentation, unknown }

/// Base Resource Model
abstract class LearningResource {
  final String title;
  final String description;
  final String url;
  final ResourceType type;
  final double qualityScore;

  const LearningResource({
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    this.qualityScore = 0.0,
  });
}

/// Video Resource (YouTube)
class VideoResource extends LearningResource {
  final String videoId;
  final String thumbnailUrl;
  final String channelName;
  final String durationFormatted;
  final int viewCount;

  const VideoResource({
    required super.title,
    required super.description,
    required super.url,
    required this.videoId,
    required this.thumbnailUrl,
    required this.channelName,
    required this.durationFormatted,
    required this.viewCount,
    super.qualityScore,
  }) : super(type: ResourceType.video);

  factory VideoResource.fromJson(Map<String, dynamic> json) {
    return VideoResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      videoId: json['video_id'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      channelName: json['channel_name'] ?? '',
      durationFormatted: json['duration_formatted'] ?? '',
      viewCount: json['view_count'] ?? 0,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Article Resource (Google/Dev.to)
class ArticleResource extends LearningResource {
  final String sourceName;
  final String sourceDomain;
  final int readTimeMinutes;
  final bool isTrustedSource;
  final String? coverImage;
  final String? author;

  const ArticleResource({
    required super.title,
    required super.description,
    required super.url,
    required this.sourceName,
    required this.sourceDomain,
    required this.readTimeMinutes,
    this.isTrustedSource = false,
    this.coverImage,
    this.author,
    super.qualityScore,
  }) : super(type: ResourceType.article);

  factory ArticleResource.fromJson(Map<String, dynamic> json) {
    return ArticleResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      sourceName: json['source_name'] ?? json['source_domain'] ?? 'Web',
      sourceDomain: json['source_domain'] ?? '',
      readTimeMinutes: json['read_time_minutes'] ?? 5,
      isTrustedSource: json['is_trusted_source'] ?? false,
      coverImage: json['cover_image'],
      author: json['author'],
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// GitHub Repository Resource
class GithubResource extends LearningResource {
  final String fullName;
  final int stars;
  final int forks;
  final String language;
  final List<String> topics;
  final String? ownerAvatar;

  const GithubResource({
    required super.title,
    required super.description,
    required super.url,
    required this.fullName,
    required this.stars,
    required this.forks,
    required this.language,
    required this.topics,
    this.ownerAvatar,
    super.qualityScore,
  }) : super(type: ResourceType.repository);

  factory GithubResource.fromJson(Map<String, dynamic> json) {
    return GithubResource(
      title: json['name'] ?? '', // Using repo name as title
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      fullName: json['full_name'] ?? '',
      stars: json['stars'] ?? 0,
      forks: json['forks'] ?? 0,
      language: json['language'] ?? 'Unknown',
      topics: List<String>.from(json['topics'] ?? []),
      ownerAvatar: json['owner'] != null ? json['owner']['avatar_url'] : null,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Wikipedia Summary
class WikipediaResource extends LearningResource {
  final String extractHtml;
  final String? thumbnailUrl;

  const WikipediaResource({
    required super.title,
    required super.description,
    required super.url,
    required this.extractHtml,
    this.thumbnailUrl,
  }) : super(type: ResourceType.wikipedia);

  factory WikipediaResource.fromJson(Map<String, dynamic> json) {
    return WikipediaResource(
      title: json['title'] ?? '',
      description: json['extract'] ?? '',
      url: json['url'] ?? '',
      extractHtml: json['extract_html'] ?? '',
      thumbnailUrl: json['thumbnail'],
    );
  }
}

/// Book Resource (Open Library)
class BookResource extends LearningResource {
  final String author;
  final int? year;
  final String? coverImage;

  const BookResource({
    required super.title,
    required super.description,
    required super.url,
    required this.author,
    this.year,
    this.coverImage,
    super.qualityScore,
  }) : super(type: ResourceType.book);

  factory BookResource.fromJson(Map<String, dynamic> json) {
    return BookResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      author: json['author'] ?? 'Unknown',
      year: json['year'],
      coverImage: json['cover_image'],
      qualityScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Q&A Resource (Stack Overflow)
class QAResource extends LearningResource {
  final int score;
  final int answerCount;
  final List<String> tags;

  const QAResource({
    required super.title,
    required super.description,
    required super.url,
    required this.score,
    required this.answerCount,
    this.tags = const [],
    super.qualityScore,
  }) : super(type: ResourceType.qa);

  factory QAResource.fromJson(Map<String, dynamic> json) {
    return QAResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      score: json['score'] ?? 0,
      answerCount: json['answer_count'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      qualityScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Course Resource (Coursera)
class CourseResource extends LearningResource {
  final String? coverImage;
  final String? workload;

  const CourseResource({
    required super.title,
    required super.description,
    required super.url,
    this.coverImage,
    this.workload,
    super.qualityScore,
  }) : super(type: ResourceType.course);

  factory CourseResource.fromJson(Map<String, dynamic> json) {
    return CourseResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      coverImage: json['cover_image'],
      workload: json['workload'],
      qualityScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Documentation Resource (MDN)
class DocResource extends LearningResource {
  const DocResource({
    required super.title,
    required super.description,
    required super.url,
    super.qualityScore,
  }) : super(type: ResourceType.documentation);

  factory DocResource.fromJson(Map<String, dynamic> json) {
    return DocResource(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      qualityScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Curated Lesson Resources Container
class LessonResources {
  final String lessonTitle;
  final List<VideoResource> videos;
  final List<ArticleResource> articles;
  final List<GithubResource> repositories;
  final WikipediaResource? wikipedia;
  final List<BookResource> books;
  final List<QAResource> questions;
  final List<CourseResource> courses;
  final List<DocResource> docs;
  final int totalCount;

  const LessonResources({
    required this.lessonTitle,
    this.videos = const [],
    this.articles = const [],
    this.repositories = const [],
    this.wikipedia,
    this.books = const [],
    this.questions = const [],
    this.courses = const [],
    this.docs = const [],
    this.totalCount = 0,
  });

  factory LessonResources.fromJson(Map<String, dynamic> json) {
    print('Parsing LessonResources: $json');
    return LessonResources(
      lessonTitle: json['lesson_title'] ?? '',
      videos: (json['videos'] as List?)
              ?.map((e) => VideoResource.fromJson(e))
              .toList() ??
          [],
      articles: (json['articles'] as List?)
              ?.map((e) => ArticleResource.fromJson(e))
              .toList() ??
          [],
      repositories: (json['repositories'] as List?)
              ?.map((e) => GithubResource.fromJson(e))
              .toList() ??
          [],
      wikipedia: json['wikipedia'] != null
          ? WikipediaResource.fromJson(json['wikipedia'])
          : null,
      books: (json['books'] as List?)
              ?.map((e) => BookResource.fromJson(e))
              .toList() ??
          [],
      questions: (json['questions'] as List?)
              ?.map((e) => QAResource.fromJson(e))
              .toList() ??
          [],
      courses: (json['courses'] as List?)
              ?.map((e) => CourseResource.fromJson(e))
              .toList() ??
          [],
      docs: (json['docs'] as List?)
              ?.map((e) => DocResource.fromJson(e))
              .toList() ??
          [],
      totalCount: json['total_resources'] ?? 0,
    );
  }
}

