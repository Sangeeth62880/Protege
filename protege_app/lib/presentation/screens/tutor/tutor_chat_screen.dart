import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/tutor_models.dart';
import '../../../providers/tutor_provider.dart';
import '../../widgets/tutor/chat_message_bubble.dart';
import '../../widgets/tutor/tutor_input_field.dart';

class TutorChatScreen extends ConsumerStatefulWidget {
  final String topic;
  final String lessonTitle;
  final List<String> keyConcepts;
  final String experienceLevel;

  const TutorChatScreen({
    Key? key,
    required this.topic,
    required this.lessonTitle,
    required this.keyConcepts,
    required this.experienceLevel,
  }) : super(key: key);

  @override
  ConsumerState<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends ConsumerState<TutorChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Maybe init session here?
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorState = ref.watch(tutorProvider);

    // Auto-scroll when new messages arrive
    ref.listen(tutorProvider, (previous, next) {
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
      
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              ref.read(tutorProvider.notifier).clearConversation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.secondary.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Asking about: ${widget.lessonTitle}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: tutorState.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: tutorState.messages.length,
                    itemBuilder: (context, index) {
                      return ChatMessageBubble(message: tutorState.messages[index]);
                    },
                  ),
          ),
          
          if (tutorState.isLoading && tutorState.messages.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // Input
          TutorInputField(
            isLoading: tutorState.isLoading,
            onSubmitted: (text) {
              ref.read(tutorProvider.notifier).askQuestion(
                question: text,
                topic: widget.topic,
                lessonTitle: widget.lessonTitle,
                keyConcepts: widget.keyConcepts,
                experienceLevel: widget.experienceLevel,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Ask me anything!',
            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'I can explain concepts, give examples,\nor help you debug code.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
