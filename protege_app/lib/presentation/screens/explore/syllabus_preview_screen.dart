import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/learning_provider.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../../data/models/learning_path_model.dart'; // For SyllabusModel

class SyllabusPreviewScreen extends ConsumerStatefulWidget {
  const SyllabusPreviewScreen({super.key});

  @override
  ConsumerState<SyllabusPreviewScreen> createState() => _SyllabusPreviewScreenState();
}

class _SyllabusPreviewScreenState extends ConsumerState<SyllabusPreviewScreen> {
  
  Future<void> _onStartLearning(SyllabusModel? syllabus) async {
    if (syllabus == null) return;
    
    final path = await ref.read(saveSyllabusProvider.notifier).save(syllabus);
    
    if (path != null && mounted) {
      // Clear navigation stack and go to the path
      // Use push to preserve history or go to home then push
      // Simple fix: push so 'Back' works (returns to Preview, which is acceptable)
      context.push('/learn/${path.id}');
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save path. Please try again.'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syllabusState = ref.watch(syllabusGeneratorProvider);
    final saveState = ref.watch(saveSyllabusProvider);
    
    final syllabus = syllabusState.valueOrNull;

    if (syllabus == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('No syllabus generated. Please try again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Syllabus'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(), // Cancel
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Description
                  Text(
                    syllabus.topic,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    syllabus.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatBadge(
                        icon: Icons.timer,
                        label: '${syllabus.totalDurationHours} Hours',
                        color: AppColors.info,
                      ),
                      _StatBadge(
                        icon: Icons.speed,
                        label: syllabus.difficulty,
                        color: AppColors.warning,
                      ),
                      _StatBadge(
                        icon: Icons.layers,
                        label: '${syllabus.modules.length} Modules',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Modules List
                  Text(
                    'Curriculum',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...syllabus.modules.map((module) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.textLight.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        'Module ${module.moduleNumber}: ${module.title}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${module.lessons.length} Lessons • ${module.durationHours} Hours',
                        style: TextStyle(color: AppColors.textLight, fontSize: 13),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(module.description, style: TextStyle(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              const Divider(),
                              ...module.lessons.map((lesson) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.play_circle_outline, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(lesson.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text('${lesson.durationMinutes}m', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Start Learning',
                    isLoading: saveState.isLoading,
                    onPressed: () => _onStartLearning(syllabus),
                    icon: Icons.rocket_launch,
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

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label[0].toUpperCase() + label.substring(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
