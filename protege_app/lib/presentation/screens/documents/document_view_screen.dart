import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document_model.dart';
import '../../../providers/document_providers.dart';
import '../../widgets/cards/modern_card.dart';

/// Document detail/view screen — streams Firestore for real-time status updates.
class DocumentViewScreen extends ConsumerWidget {
  final String documentId;

  const DocumentViewScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use stream provider for real-time updates during processing
    final docStream = ref.watch(documentStreamProvider(documentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Document', style: AppTypography.titleMedium),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Document?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Delete', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(documentRepositoryProvider).deleteDocument(documentId);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: docStream.when(
        data: (doc) {
          if (doc == null) {
            return const Center(child: Text('Document not found'));
          }
          return _buildContent(context, ref, doc);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, DocumentModel doc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          ModernCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (doc.fileType == 'pdf' ? AppColors.error : AppColors.info).withAlpha(26),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    doc.fileType == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: doc.fileType == 'pdf' ? AppColors.error : AppColors.info,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.fileName, style: AppTypography.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.fileType.toUpperCase()} · ${doc.pageCount} pages · ${doc.fileSizeFormatted}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      if (doc.createdAt != null)
                        Text(
                          'Uploaded ${DateFormat.yMMMd().format(doc.createdAt!)}',
                          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Processing state — shows progressive status ──────────────
          if (doc.isProcessing) ...[
            const SizedBox(height: 20),
            ModernCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doc.statusLabel,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress steps indicator
                  _ProcessingSteps(currentStatus: doc.status),
                  const SizedBox(height: 12),
                  Text(
                    'This usually takes a few seconds.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // ── Failed state ─────────────────────────────────────────────
          if (doc.isFailed) ...[
            const SizedBox(height: 20),
            ModernCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      doc.processingError ?? 'Processing failed',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Ready state — show summary, topics, chat CTA ─────────────
          if (doc.isReady) ...[
            // Summary
            if (doc.summary != null) ...[
              const SizedBox(height: 24),
              Text('Summary', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              ModernCard(
                margin: EdgeInsets.zero,
                child: Text(doc.summary!, style: AppTypography.bodyMedium),
              ),
            ],

            // Key Topics
            if (doc.keyTopics.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Key Topics', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doc.keyTopics.map((topic) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(51)),
                  ),
                  child: Text(topic, style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                )).toList(),
              ),
            ],

            // Chat CTA
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/documents/$documentId/chat'),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('Chat with Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            // Extracted text preview
            if (doc.extractedTextPreview != null) ...[
              const SizedBox(height: 28),
              Text('Extracted Text', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              ModernCard(
                margin: EdgeInsets.zero,
                child: Text(
                  doc.extractedTextPreview!.length > 1000
                      ? '${doc.extractedTextPreview!.substring(0, 1000)}...'
                      : doc.extractedTextPreview!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],

            // Stats row
            const SizedBox(height: 24),
            Row(
              children: [
                _StatPill(icon: Icons.article_outlined, label: '${doc.wordCount} words'),
                const SizedBox(width: 8),
                _StatPill(icon: Icons.layers_outlined, label: '${doc.chunkCount} chunks'),
                const SizedBox(width: 8),
                _StatPill(icon: Icons.auto_stories_outlined, label: '${doc.pageCount} pages'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Visual progress steps indicator showing pipeline stages
class _ProcessingSteps extends StatelessWidget {
  final String currentStatus;
  const _ProcessingSteps({required this.currentStatus});

  static const _steps = [
    ('extracting', 'Extract', Icons.text_snippet_outlined),
    ('chunking', 'Chunk', Icons.content_cut_outlined),
    ('embedding', 'Embed', Icons.hub_outlined),
    ('storing', 'Store', Icons.storage_outlined),
    ('summarizing', 'Summarize', Icons.auto_awesome_outlined),
  ];

  int get _currentIndex {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == currentStatus) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_steps.length, (i) {
          final isDone = i < current;
          final isCurrent = i == current;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.success
                      : isCurrent
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                ),
                child: Icon(
                  isDone ? Icons.check : _steps[i].$3,
                  size: 14,
                  color: (isDone || isCurrent) ? Colors.white : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _steps[i].$2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: (isDone || isCurrent) ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
