/// Persona model for AI student personas in reverse tutoring
class PersonaModel {
  final String id;
  final String name;
  final int age;
  final String type;
  final String description;
  final String avatarEmoji;
  final String difficulty;
  final List<String> traits;

  const PersonaModel({
    required this.id,
    required this.name,
    required this.age,
    required this.type,
    required this.description,
    required this.avatarEmoji,
    required this.difficulty,
    this.traits = const [],
  });

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    return PersonaModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      type: json['type'] as String,
      description: json['description'] as String,
      avatarEmoji: json['avatar_emoji'] as String,
      difficulty: json['difficulty'] as String,
      traits: (json['traits'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'type': type,
      'description': description,
      'avatar_emoji': avatarEmoji,
      'difficulty': difficulty,
      'traits': traits,
    };
  }

  /// Get color for difficulty level
  String get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return '#4CAF50'; // Green
      case 'medium':
        return '#FF9800'; // Orange
      case 'hard':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get a short description for the persona
  String get shortDescription {
    switch (type) {
      case 'curious_child':
        return 'Loves asking "why?" - Great for practicing simple explanations';
      case 'skeptical_teen':
        return 'Challenges everything - Tests your logical reasoning';
      case 'confused_adult':
        return 'Needs patience - Practice real-world applications';
      case 'technical_peer':
        return 'Asks edge cases - For advanced mastery validation';
      default:
        return description;
    }
  }
}

/// Static list of personas for offline use
class PersonaData {
  static const List<PersonaModel> personas = [
    PersonaModel(
      id: 'curious_child',
      name: 'Maya',
      age: 8,
      type: 'curious_child',
      description: 'An excited 8-year-old who loves asking "why?" and needs simple, fun explanations',
      avatarEmoji: '👧',
      difficulty: 'easy',
      traits: [
        'Asks "why?" constantly',
        'Needs very simple language',
        'Loves analogies and stories',
        'Gets excited when understanding',
      ],
    ),
    PersonaModel(
      id: 'skeptical_teen',
      name: 'Jake',
      age: 16,
      type: 'skeptical_teen',
      description: 'A 16-year-old who questions everything and needs proof',
      avatarEmoji: '🧑',
      difficulty: 'medium',
      traits: [
        'Questions everything',
        'Asks "but what if...?" a lot',
        'Needs proof and examples',
        'Uses casual language',
      ],
    ),
    PersonaModel(
      id: 'confused_adult',
      name: 'Sarah',
      age: 35,
      type: 'confused_adult',
      description: 'A career changer who is anxious about learning new things',
      avatarEmoji: '👩‍💼',
      difficulty: 'medium',
      traits: [
        'Career changer, anxious',
        'Needs patience and encouragement',
        'Asks for real-world applications',
        'Very grateful when things click',
      ],
    ),
    PersonaModel(
      id: 'technical_peer',
      name: 'Alex',
      age: 28,
      type: 'technical_peer',
      description: 'A developer who asks about edge cases and precision',
      avatarEmoji: '🧑‍💻',
      difficulty: 'hard',
      traits: [
        'Has technical background',
        'Asks about edge cases',
        'Appreciates precision',
        'Good for advanced validation',
      ],
    ),
  ];
}
