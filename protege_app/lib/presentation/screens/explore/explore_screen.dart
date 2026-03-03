import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/speech_bubble.dart';
import '../../widgets/common/staggered_list_item.dart';
import '../../widgets/icons/protege_diamond_icon.dart';
import '../../widgets/icons/topic_programming_icon.dart';
import '../../widgets/icons/topic_data_icon.dart';
import '../../widgets/icons/topic_science_icon.dart';
import '../../widgets/icons/topic_math_icon.dart';
import '../../widgets/icons/topic_default_icon.dart';
import '../../widgets/common/category_label.dart';

/// Explore screen for discovering new topics (Step 1: Input)
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _topicController = TextEditingController();

  final List<_SuggestedTopic> _suggestedTopics = [
    _SuggestedTopic('Python Programming', Icons.code_rounded, AppColors.purple, true),
    _SuggestedTopic('Data Analysis', Icons.bar_chart_rounded, AppColors.orange, false),
    _SuggestedTopic('Machine Learning', Icons.psychology_rounded, AppColors.blue, false),
    _SuggestedTopic('Web Development', Icons.web_rounded, AppColors.green, false),
    _SuggestedTopic('Mobile Apps', Icons.phone_android_rounded, AppColors.purple, false),
    _SuggestedTopic('Cloud Computing', Icons.cloud_rounded, AppColors.amber, false),
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_topicController.text.trim().isEmpty) return;
    context.push('/create-path/goals', extra: _topicController.text.trim());
  }

  Widget _topicIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('python') || lower.contains('programming') || lower.contains('code') || lower.contains('web') || lower.contains('mobile')) {
      return const TopicProgrammingIcon(size: 56);
    }
    if (lower.contains('data') || lower.contains('analytics')) {
      return const TopicDataIcon(size: 56);
    }
    if (lower.contains('machine') || lower.contains('science') || lower.contains('cloud')) {
      return const TopicScienceIcon(size: 56);
    }
    if (lower.contains('math') || lower.contains('probability')) {
      return const TopicMathIcon(size: 56);
    }
    return const TopicDefaultIcon(size: 56);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Explore', style: AppTypography.headlineSmall),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Diamond + speech bubble
            StaggeredListItem(
              index: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProtegeDiamondIcon(size: 40),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: SpeechBubble(
                      text: "Here's what I recommend. Get started with one and switch any time.",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Topic input
            StaggeredListItem(
              index: 1,
              child: TextField(
                controller: _topicController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'e.g., React Native, French History...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(AppSpacing.lg),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    borderSide: const BorderSide(color: AppColors.green, width: 2),
                  ),
                ),
                style: AppTypography.bodyLarge,
                onSubmitted: (_) => _onContinue(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Featured TOP PICK card
            StaggeredListItem(
              index: 2,
              child: AnimatedPressable(
                onTap: () {
                  _topicController.text = _suggestedTopics.first.name;
                  _onContinue();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    border: Border.all(color: AppColors.purpleBorder, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: Text(
                              'TOP PICK',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Center(child: TopicProgrammingIcon(size: 64)),
                      const SizedBox(height: AppSpacing.lg),
                      CategoryLabel(text: 'LEARNING PATH', color: AppColors.purple),
                      const SizedBox(height: AppSpacing.sm),
                      Text(_suggestedTopics.first.name, style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Master the fundamentals with hands-on practice',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Regular topic cards
            ...List.generate(
              _suggestedTopics.length - 1,
              (i) {
                final topic = _suggestedTopics[i + 1];
                return StaggeredListItem(
                  index: 3 + i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AnimatedPressable(
                      onTap: () {
                        _topicController.text = topic.name;
                        _onContinue();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 56, height: 56, child: _topicIcon(topic.name)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CategoryLabel(text: 'LEARNING PATH', color: topic.color),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(topic.name, style: AppTypography.headlineSmall),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Learn from Documents card
            StaggeredListItem(
              index: 8,
              child: AnimatedPressable(
                onTap: () => context.push('/documents'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(color: AppColors.blue.withAlpha(40)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: const Icon(Icons.description_rounded, color: AppColors.blue, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Learn from Documents', style: AppTypography.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              'Upload PDFs & images — get AI summaries and chat',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.blue),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Continue button
            PrimaryButton(
              label: 'Continue',
              onPressed: _onContinue,
              icon: Icons.arrow_forward_rounded,
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _SuggestedTopic {
  final String name;
  final IconData icon;
  final Color color;
  final bool isFeatured;

  _SuggestedTopic(this.name, this.icon, this.color, this.isFeatured);
}
