import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/cards/modern_card.dart';

/// Home screen for Reverse Tutoring / Teach Mode
class TeachHomeScreen extends ConsumerWidget {
  const TeachHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
            
            // Start Teaching CTA
            SliverToBoxAdapter(
              child: _buildStartTeachingCard(context),
            ),
            
            // Explanation Card
            SliverToBoxAdapter(
              child: _buildExplanationCard(context),
            ),
            
            // Aha! Meter Overview
            SliverToBoxAdapter(
              child: _buildAhaMeterOverview(context),
            ),
            
            // Available Topics to Teach
            SliverToBoxAdapter(
              child: _buildTopicsSection(context),
            ),
            
            // Recent Teaching Sessions
            SliverToBoxAdapter(
              child: _buildRecentSessions(context),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.teachMode,
                      AppColors.teachMode.withAlpha(179),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teachMode.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teach Mode',
                      style: AppTypography.headlineLarge,
                    ),
                    Text(
                      'Prove your mastery by teaching the AI',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartTeachingCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: GestureDetector(
        onTap: () => _showCustomTopicDialog(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.teachMode,
                AppColors.teachMode.withAlpha(204),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.teachMode.withAlpha(102),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Teaching',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Teach any topic to our AI student',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomTopicDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'What do you want to teach?',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter any topic you know and want to explain',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g., "How photosynthesis works"',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.teachMode, width: 2),
                  ),
                  prefixIcon: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context);
                    context.push('/teach/session?topic=${Uri.encodeComponent(value.trim())}');
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final topic = controller.text.trim();
                    if (topic.isNotEmpty) {
                      Navigator.pop(context);
                      context.push('/teach/session?topic=${Uri.encodeComponent(topic)}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teachMode,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Start Teaching'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.teachMode.withAlpha(26),
              AppColors.teachMode.withAlpha(13),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.teachMode.withAlpha(51),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'How it works',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.teachMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStep('1', 'Choose a topic you\'ve learned'),
            _buildStep('2', 'Explain it to our AI student'),
            _buildStep('3', 'AI asks questions to test your understanding'),
            _buildStep('4', 'Earn Aha! points based on your explanation quality'),
            const SizedBox(height: 16),
            Text(
              '"The best way to learn is to teach"',
              style: AppTypography.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.teachMode,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAhaMeterOverview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ModernCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Aha! Score',
                  style: AppTypography.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level 3',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Aha! Meter Visual
            const _AhaMeterWidget(score: 72),
            
            const SizedBox(height: 20),
            
            // Score breakdown
            Row(
              children: const [
                _ScoreItem(
                  label: 'Clarity',
                  score: 78,
                  color: AppColors.info,
                ),
                SizedBox(width: 16),
                _ScoreItem(
                  label: 'Accuracy',
                  score: 85,
                  color: AppColors.success,
                ),
                SizedBox(width: 16),
                _ScoreItem(
                  label: 'Depth',
                  score: 65,
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topics You Can Teach',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Based on lessons you\'ve completed',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          
          _TopicCard(
            title: 'Variables in Python',
            progress: 'Completed 2 days ago',
            difficulty: 'Beginner',
            onTap: () => context.push('/teach/session/python-variables'),
          ),
          const SizedBox(height: 12),
          _TopicCard(
            title: 'Functions and Methods',
            progress: 'Completed 5 days ago',
            difficulty: 'Intermediate',
            onTap: () => context.push('/teach/session/python-functions'),
          ),
          const SizedBox(height: 12),
          _TopicCard(
            title: 'Control Flow',
            progress: 'Completed 1 week ago',
            difficulty: 'Beginner',
            onTap: () => context.push('/teach/session/python-control-flow'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Teaching Sessions',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          const _SessionHistoryItem(
            topic: 'Variables',
            score: 85,
            date: 'Yesterday',
            persona: 'Curious Maya',
          ),
          const _SessionHistoryItem(
            topic: 'Data Types',
            score: 72,
            date: '3 days ago',
            persona: 'Skeptical Jake',
          ),
        ],
      ),
    );
  }
}

class _AhaMeterWidget extends StatelessWidget {
  final int score;
  
  const _AhaMeterWidget({required this.score});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 12,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getScoreColor(score),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            children: [
              Text(
                '$score',
                style: AppTypography.displayMedium.copyWith(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Aha! Score',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int score;
  final Color color;

  const _ScoreItem({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$score%',
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String title;
  final String progress;
  final String difficulty;
  final VoidCallback onTap;

  const _TopicCard({
    required this.title,
    required this.progress,
    required this.difficulty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.teachMode.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_rounded,
                color: AppColors.teachMode,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                difficulty,
                style: AppTypography.labelSmall,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionHistoryItem extends StatelessWidget {
  final String topic;
  final int score;
  final String date;
  final String persona;

  const _SessionHistoryItem({
    required this.topic,
    required this.score,
    required this.date,
    required this.persona,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getScoreColor(score).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '$score',
                style: AppTypography.labelMedium.copyWith(
                  color: _getScoreColor(score),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: AppTypography.titleSmall,
                ),
                Text(
                  'with $persona • $date',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }
}
