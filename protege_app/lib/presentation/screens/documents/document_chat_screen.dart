import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document_model.dart';
import '../../../providers/document_providers.dart';

/// Document chat screen — RAG-powered Q&A with a document.
class DocumentChatScreen extends ConsumerStatefulWidget {
  final String documentId;

  const DocumentChatScreen({super.key, required this.documentId});

  @override
  ConsumerState<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends ConsumerState<DocumentChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(documentChatProvider.notifier).sendMessage(widget.documentId, text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
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
    final chatState = ref.watch(documentChatProvider);

    // Scroll when new message arrives
    ref.listen(documentChatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chat with Document', style: AppTypography.titleMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => ref.read(documentChatProvider.notifier).clearChat(),
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildStarterView(chatState)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length && chatState.isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _MessageBubble(message: chatState.messages[index]);
                    },
                  ),
          ),

          // Follow-up suggestions
          if (chatState.suggestedQuestions.isNotEmpty && !chatState.isLoading)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: chatState.suggestedQuestions.map((q) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, maxLines: 1, overflow: TextOverflow.ellipsis),
                    labelStyle: AppTypography.caption.copyWith(color: AppColors.primary),
                    backgroundColor: AppColors.primary.withAlpha(20),
                    side: BorderSide(color: AppColors.primary.withAlpha(51)),
                    onPressed: () {
                      _controller.text = q;
                      _sendMessage();
                    },
                  ),
                )).toList(),
              ),
            ),

          // Error
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(chatState.error!, style: AppTypography.bodySmall.copyWith(color: AppColors.error))),
                  TextButton(
                    onPressed: () => ref.read(documentChatProvider.notifier).retryLast(widget.documentId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + MediaQuery.of(context).viewPadding.bottom),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about your document...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: chatState.isLoading ? null : _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterView(DocumentChatState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.chat_rounded, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('Ask anything about your document', style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your answers will be grounded in the document content with page citations.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _StarterQuestion('Summarize the main points', () {
                  _controller.text = 'Summarize the main points of this document';
                  _sendMessage();
                }),
                _StarterQuestion('What are the key takeaways?', () {
                  _controller.text = 'What are the key takeaways from this document?';
                  _sendMessage();
                }),
                _StarterQuestion('Explain the core concepts', () {
                  _controller.text = 'Explain the core concepts discussed in this document';
                  _sendMessage();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('Analyzing...', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────

class _StarterQuestion extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _StarterQuestion(this.text, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary),
      backgroundColor: AppColors.primary.withAlpha(15),
      side: BorderSide(color: AppColors.primary.withAlpha(40)),
      onPressed: onTap,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DocumentChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Column(
          crossAxisAlignment:
              message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isUser
                  ? Text(
                      message.content,
                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: AppTypography.bodyMedium,
                        h1: AppTypography.titleMedium,
                        h2: AppTypography.titleSmall,
                        listBullet: AppTypography.bodyMedium,
                        strong: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),

            // Source pills
            if (message.sources != null && message.sources!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: message.sources!
                      .where((s) => s.relevanceScore > 0.2)
                      .map((source) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '📄 Page ${source.page}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
