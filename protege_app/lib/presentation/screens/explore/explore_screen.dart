import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/buttons/primary_button.dart';

/// Explore screen for discovering new topics (Step 1: Input)
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _topicController = TextEditingController();
  
  final List<_SuggestedTopic> _suggestedTopics = [
    _SuggestedTopic('Python Basics', Icons.code, AppColors.primary),
    _SuggestedTopic('Machine Learning', Icons.psychology, AppColors.secondary),
    _SuggestedTopic('Web Development', Icons.web, AppColors.accent),
    _SuggestedTopic('Data Science', Icons.analytics, AppColors.info),
    _SuggestedTopic('Mobile Apps', Icons.phone_android, AppColors.success),
    _SuggestedTopic('Cloud Computing', Icons.cloud, AppColors.warning),
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_topicController.text.trim().isEmpty) return;
    
    // Navigate to Goal Selection with the topic
    context.push('/create-path/goals', extra: _topicController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'What do you want to learn?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a topic, skill, or subject you want to master.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Topic input
            TextField(
              controller: _topicController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'e.g., React Native, French History...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 18),
              onSubmitted: (_) => _onContinue(),
            ),
            const SizedBox(height: 24),
            
            // Continue Button
            PrimaryButton(
              text: 'Continue',
              onPressed: _onContinue,
              icon: Icons.arrow_forward,
            ),
            
            const SizedBox(height: 48),
            
            // Suggested topics
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Or try these',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: _suggestedTopics.length,
              itemBuilder: (context, index) {
                final topic = _suggestedTopics[index];
                return _TopicCard(
                  topic: topic,
                  onTap: () {
                    _topicController.text = topic.name;
                    _onContinue(); // Optionally auto-submit
                  },
                );
              },
            ),
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

  _SuggestedTopic(this.name, this.icon, this.color);
}

class _TopicCard extends StatelessWidget {
  final _SuggestedTopic topic;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.textLight.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(topic.icon, color: topic.color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                topic.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
