import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/persona_model.dart';
import '../../../providers/teaching_provider.dart';

/// Persona selection screen for choosing AI student before teaching
class PersonaSelectionScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String topic;
  final List<String> concepts;

  const PersonaSelectionScreen({
    super.key,
    required this.topicId,
    required this.topic,
    this.concepts = const [],
  });

  @override
  ConsumerState<PersonaSelectionScreen> createState() =>
      _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState
    extends ConsumerState<PersonaSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Load personas when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teachingProvider.notifier).loadPersonas();
    });
  }

  void _selectPersona(PersonaModel persona) {
    ref.read(teachingProvider.notifier).selectPersona(persona);
  }

  void _startSession() async {
    final selectedPersona = ref.read(selectedPersonaProvider);
    if (selectedPersona == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student to teach')),
      );
      return;
    }

    await ref.read(teachingProvider.notifier).startSession(
          topicId: widget.topicId,
          topic: widget.topic,
          conceptsToCover: widget.concepts,
        );

    if (mounted) {
      final teachingState = ref.read(teachingProvider);
      if (teachingState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(teachingState.error!),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (teachingState.session != null) {
        context.go('/teaching/${widget.topicId}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachingState = ref.watch(teachingProvider);
    final personas = ref.watch(personasProvider);
    final selectedPersona = ref.watch(selectedPersonaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Column(
              children: [
                Icon(
                  Icons.school,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Teach Mode: ${widget.topic}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'The best way to learn is to teach.\nChoose a student persona to explain concepts to.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textLight,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Persona grid
          Expanded(
            child: teachingState.isLoadingPersonas
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: personas.length,
                    itemBuilder: (context, index) {
                      final persona = personas[index];
                      final isSelected = selectedPersona?.id == persona.id;

                      return _PersonaCard(
                        persona: persona,
                        isSelected: isSelected,
                        onTap: () => _selectPersona(persona),
                      );
                    },
                  ),
          ),

          // Start button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (selectedPersona != null) ...[
                  Text(
                    'Teaching ${selectedPersona.name}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedPersona.shortDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedPersona != null && !teachingState.isLoading
                        ? _startSession
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: teachingState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Start Teaching Session',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card widget for displaying a persona
class _PersonaCard extends StatelessWidget {
  final PersonaModel persona;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaCard({
    required this.persona,
    required this.isSelected,
    required this.onTap,
  });

  Color get _difficultyColor {
    switch (persona.difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              Text(
                persona.avatarEmoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),

              // Name and age
              Text(
                persona.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${persona.age} years old',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
              ),
              const SizedBox(height: 8),

              // Difficulty badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _difficultyColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  persona.difficulty.toUpperCase(),
                  style: TextStyle(
                    color: _difficultyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                persona.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLight,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
