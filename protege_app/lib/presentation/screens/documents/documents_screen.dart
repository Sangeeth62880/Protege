import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document_model.dart';
import '../../../providers/document_providers.dart';
import '../../widgets/cards/modern_card.dart';

/// Documents list screen — shows all user-uploaded documents with real-time status.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(userDocumentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Documents', style: AppTypography.headlineMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/documents/upload'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: Text('Upload', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userDocumentsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: docs.length,
              itemBuilder: (context, index) => _DocumentCard(doc: docs[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading documents', style: AppTypography.bodyMedium),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'No documents yet',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a PDF or image to get AI-powered summaries, explanations, and chat with your documents.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/documents/upload'),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload Your First Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends ConsumerWidget {
  final DocumentModel doc;

  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        margin: EdgeInsets.zero,
        onTap: doc.isReady ? () => context.push('/documents/${doc.id}') : null,
        child: Dismissible(
          key: Key(doc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Document?'),
                content: Text('This will permanently delete "${doc.fileName}".'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ref.read(documentRepositoryProvider).deleteDocument(doc.id);
          },
          child: Row(
            children: [
              // File type icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _fileColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_fileIcon, color: _fileColor, size: 24),
              ),
              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.fileName,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (doc.isReady && doc.summary != null)
                      Text(
                        doc.summary!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (doc.isFailed)
                      Text(
                        doc.processingError ?? 'Processing failed',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                        maxLines: 1,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusChip(status: doc.status),
                        const SizedBox(width: 8),
                        Text(
                          doc.fileSizeFormatted,
                          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                        ),
                        if (doc.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.MMMd().format(doc.createdAt!),
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ],
                    ),
                    if (doc.isReady && doc.keyTopics.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: doc.keyTopics.take(3).map((t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(t, style: AppTypography.caption.copyWith(color: AppColors.primary)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              if (doc.isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (doc.isReady)
                Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _fileIcon {
    if (doc.fileType == 'pdf') return Icons.picture_as_pdf_rounded;
    return Icons.image_rounded;
  }

  Color get _fileColor {
    if (doc.fileType == 'pdf') return AppColors.error;
    return AppColors.info;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'ready':
        color = AppColors.success;
        label = 'Ready';
        break;
      case 'processing':
        color = AppColors.warning;
        label = 'Processing';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Failed';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
