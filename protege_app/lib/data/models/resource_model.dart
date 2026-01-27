/// Resource model for learning materials
class ResourceModel {
  final String id;
  final String title;
  final String description;
  final String url;
  final ResourceType type;
  final String source; // youtube, github, devto, wikipedia, etc.
  final String? thumbnailUrl;
  final String? author;
  final int? duration; // in seconds for videos
  final DateTime? publishedAt;
  final double? rating;

  const ResourceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    required this.source,
    this.thumbnailUrl,
    this.author,
    this.duration,
    this.publishedAt,
    this.rating,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      url: json['url'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ResourceType.article,
      ),
      source: json['source'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      author: json['author'] as String?,
      duration: json['duration'] as int?,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'type': type.name,
      'source': source,
      'thumbnailUrl': thumbnailUrl,
      'author': author,
      'duration': duration,
      'publishedAt': publishedAt?.toIso8601String(),
      'rating': rating,
    };
  }

  /// Get formatted duration string
  String? get formattedDuration {
    if (duration == null) return null;
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    if (minutes < 60) {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}:${mins.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Types of learning resources
enum ResourceType {
  video,
  article,
  tutorial,
  documentation,
  repository,
  book,
  podcast,
  course,
}

extension ResourceTypeExtension on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.video:
        return 'Video';
      case ResourceType.article:
        return 'Article';
      case ResourceType.tutorial:
        return 'Tutorial';
      case ResourceType.documentation:
        return 'Docs';
      case ResourceType.repository:
        return 'Repo';
      case ResourceType.book:
        return 'Book';
      case ResourceType.podcast:
        return 'Podcast';
      case ResourceType.course:
        return 'Course';
    }
  }

  String get icon {
    switch (this) {
      case ResourceType.video:
        return '🎬';
      case ResourceType.article:
        return '📄';
      case ResourceType.tutorial:
        return '📝';
      case ResourceType.documentation:
        return '📚';
      case ResourceType.repository:
        return '💻';
      case ResourceType.book:
        return '📖';
      case ResourceType.podcast:
        return '🎧';
      case ResourceType.course:
        return '🎓';
    }
  }
}
