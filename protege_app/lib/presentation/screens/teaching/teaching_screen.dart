import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/teaching_provider.dart';
import '../../../data/models/teaching_session_model.dart';
import '../../widgets/teaching/aha_meter_widget.dart';

/// Teaching screen for reverse tutoring (Aha! Meter)
class TeachingScreen extends ConsumerStatefulWidget {
  final String topicId;
  final String? topic;

  const TeachingScreen({
    super.key, 
    required this.topicId, 
    this.topic,
  });

  @override
  ConsumerState<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends ConsumerState<TeachingScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teachingProvider.notifier).startSession(
            topicId: widget.topicId,
            topic: widget.topic ?? 'General Topic',
          );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendExplanation() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(teachingProvider.notifier).sendExplanation(text);
    _textController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teachingState = ref.watch(teachingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.teachMode),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(teachingProvider.notifier).reset();
            context.pop();
          },
        ),
        actions: [
          // Aha! Meter (using new widget)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CompactAhaMeter(score: teachingState.session?.ahaMeterScore ?? 0),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          if (teachingState.session?.status == TeachingStatus.inProgress)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.info.withValues(alpha: 0.1),
              child: Row(
                children: [
                  // Persona avatar if available
                  if (teachingState.session?.persona != null) ...[
                    Text(
                      teachingState.session!.persona!.avatarEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teaching ${teachingState.session!.persona!.name}',
                        style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  if (teachingState.session?.persona == null) ...[
                    Icon(Icons.lightbulb_outline, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.explainConcept,
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Messages
          Expanded(
            child: teachingState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: teachingState.session?.messages.length ?? 0,
                    itemBuilder: (context, index) {
                      final message = teachingState.session!.messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          // Typing indicator
          if (teachingState.isEvaluating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDot(delay: 0),
                        _TypingDot(delay: 1),
                        _TypingDot(delay: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Completion banner
          if (teachingState.session?.status == TeachingStatus.completed)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.success.withValues(alpha: 0.1),
              child: Column(
                children: [
                  // Show Aha! meter with final score
                  AhaMeterWidget(
                    score: teachingState.session!.ahaMeterScore,
                    breakdown: teachingState.session!.ahaBreakdown,
                    showBreakdown: true,
                    size: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teachingState.session!.ahaMeterScore >= 85 
                        ? '🎉 Mastery Achieved!' 
                        : AppStrings.greatExplanation,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.success,
                        ),
                  ),
                  if (teachingState.session?.feedback != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      teachingState.session!.feedback!,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to detailed results
                      context.go('/teaching/results/${teachingState.session!.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('View Results', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          // Input
          if (teachingState.session?.status == TeachingStatus.inProgress)
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Explain the concept...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    mini: true,
                    onPressed: teachingState.isEvaluating ? null : _sendExplanation,
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AhaMeter extends StatelessWidget {
  final double score;

  const _AhaMeter({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.success
        : score >= 50
            ? AppColors.warning
            : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.psychology, color: color),
        const SizedBox(width: 4),
        Text(
          '${score.toInt()}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TeachingMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay * 200), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textLight.withValues(alpha: 0.5 + _animation.value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
