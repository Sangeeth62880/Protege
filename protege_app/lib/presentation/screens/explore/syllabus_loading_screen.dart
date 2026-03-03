import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/learning_provider.dart';

class SyllabusLoadingScreen extends ConsumerStatefulWidget {
  final String topic;
  final String goal;
  final String difficulty;
  final int duration;

  const SyllabusLoadingScreen({
    super.key,
    required this.topic,
    required this.goal,
    required this.difficulty,
    required this.duration,
  });

  @override
  ConsumerState<SyllabusLoadingScreen> createState() => _SyllabusLoadingScreenState();
}

class _SyllabusLoadingScreenState extends ConsumerState<SyllabusLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _statusText = 'Analyzing topic...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    Future.microtask(() => _startGeneration());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

    Future<void> _startGeneration() async {
    _updateStatus();
    
    try {
      print('DEBUG_SYLLABUS: Starting generation for ${widget.topic}');
      final result = await ref.read(syllabusGeneratorProvider.notifier).generateSyllabus(
        topic: widget.topic,
        goal: widget.goal,
        difficulty: widget.difficulty,
        dailyMinutes: widget.duration,
      ).timeout(const Duration(seconds: 130)); 

      print('DEBUG_SYLLABUS: Generation finished. Result: ${result != null ? "Success" : "Null"}');

      if (!mounted) {
         print('DEBUG_SYLLABUS: Widget unmounted after generation');
         return;
      }

      if (result != null) {
        print('DEBUG_SYLLABUS: Navigating to preview');
        context.pushReplacement('/create-path/preview');
      } else {
        // Check provider state for error
        final state = ref.read(syllabusGeneratorProvider);
        print('DEBUG_SYLLABUS: Result is null. Has Error: ${state.hasError}');
        if (state.hasError) {
          _handleError(message: state.error.toString());
        } else {
          _handleError();
        }
      }
    } catch (e) {
      print('DEBUG_SYLLABUS: Exception catch block: $e');
      if (!mounted) return;
      // Extract meaningful error message
      String errorMessage = 'Something went wrong. Please try again.';
      if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet or if the server is running.';
      } else if (e.toString().contains('503')) {
        errorMessage = 'AI Service unavailable. Please try again later.';
      } else if (e.toString().contains('timeout')) {
         errorMessage = 'Request timed out. The AI is taking too long.';
      }
      
      _handleError(message: errorMessage);
    }
  }

  void _handleError({String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Failed to generate syllabus. Please try again.'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
    if (mounted) {
      context.pop(); 
    }
  }

  void _updateStatus() async {
    final stages = [
      'Analyzing topic...',
      'Structuring modules...',
      'Curating resources...',
      'Finalizing curriculum...',
    ];
    
    for (final stage in stages) {
      if (!mounted) break;
      setState(() => _statusText = stage);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20 * _controller.value,
                        spreadRadius: 10 * _controller.value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            
            Text(
              'Generating Syllabus',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                '$_statusText\nCreating a personalized path for "${widget.topic}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
