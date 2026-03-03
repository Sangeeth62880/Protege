import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/teaching_session_model.dart';
import '../../../providers/teaching_provider.dart';
import '../../widgets/teaching/aha_meter_widget.dart';

/// Screen showing detailed teaching session results
class TeachingResultsScreen extends ConsumerWidget {
  final String sessionId;

  const TeachingResultsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachingState = ref.watch(teachingProvider);
    final results = teachingState.results;
    final session = teachingState.session;

    if (results == null && session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('No results available')),
      );
    }

    // Use results if available, otherwise build from session
    final finalScore = results?.finalScore ?? session?.ahaMeterScore.toInt() ?? 0;
    final breakdown = results?.ahaBreakdown ?? session?.ahaBreakdown ?? const AhaBreakdown();
    final topic = results?.topic ?? session?.topic ?? '';
    final personaName = results?.personaName ?? session?.persona?.name ?? 'Student';
    final feedback = results?.feedback ?? session?.feedback ?? 'Great job completing the teaching session!';
    final strengths = results?.strengths ?? [];
    final improvements = results?.improvements ?? [];
    final conceptsCovered = results?.conceptsCovered ?? session?.conceptsCovered ?? [];
    final timeSpent = results?.timeSpentSeconds ?? 0;
    final messageCount = results?.messageCount ?? session?.messages.length ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with score
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ref.read(teachingProvider.notifier).reset();
                context.go('/');
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Celebration for mastery
                      if (finalScore >= 85)
                        const Text(
                          '🎉 Mastery Achieved! 🎉',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Text(
                          'Session Complete',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Aha! score
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: AhaMeterWidget(
                          score: finalScore.toDouble(),
                          breakdown: breakdown,
                          showBreakdown: false,
                          size: 100,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Teaching: $topic',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Student: $personaName',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breakdown section
                  _SectionTitle(title: 'Score Breakdown'),
                  const SizedBox(height: 12),
                  _BreakdownCard(breakdown: breakdown),
                  const SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_outlined,
                          label: 'Time',
                          value: _formatTime(timeSpent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.chat_outlined,
                          label: 'Messages',
                          value: '$messageCount',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.lightbulb_outline,
                          label: 'Concepts',
                          value: '${conceptsCovered.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Feedback
                  _SectionTitle(title: 'Feedback'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      feedback,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Strengths
                  if (strengths.isNotEmpty) ...[
                    _SectionTitle(title: '✅ Strengths'),
                    const SizedBox(height: 12),
                    ...strengths.map((s) => _BulletPoint(text: s, isStrength: true)),
                    const SizedBox(height: 24),
                  ],

                  // Improvements
                  if (improvements.isNotEmpty) ...[
                    _SectionTitle(title: '📈 Areas to Improve'),
                    const SizedBox(height: 12),
                    ...improvements.map((s) => _BulletPoint(text: s, isStrength: false)),
                    const SizedBox(height: 24),
                  ],

                  // Concepts covered
                  if (conceptsCovered.isNotEmpty) ...[
                    _SectionTitle(title: '💡 Concepts You Taught'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: conceptsCovered
                          .map((c) => Chip(
                                label: Text(c),
                                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(teachingProvider.notifier).reset();
                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Continue Learning',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs}s';
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final AhaBreakdown breakdown;

  const _BreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _ScoreBar(
            label: 'Clarity',
            score: breakdown.clarity,
            color: Colors.blue,
            description: 'How easy to understand',
          ),
          const SizedBox(height: 16),
          _ScoreBar(
            label: 'Accuracy',
            score: breakdown.accuracy,
            color: Colors.green,
            description: 'Factually correct info',
          ),
          const SizedBox(height: 16),
          _ScoreBar(
            label: 'Completeness',
            score: breakdown.completeness,
            color: Colors.purple,
            description: 'Coverage of concepts',
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  final String description;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '$score%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final bool isStrength;

  const _BulletPoint({required this.text, required this.isStrength});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isStrength ? Icons.check_circle : Icons.arrow_forward,
            size: 18,
            color: isStrength ? AppColors.success : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
