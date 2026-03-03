import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/document_providers.dart';

/// Document upload screen — pick a file, preview it, upload for processing.
class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true, // Required for web: loads bytes into memory
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          ref.read(documentUploadProvider.notifier).selectFile(
                fileName: file.name,
                bytes: file.bytes!,
                size: file.size,
              );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(documentUploadProvider);

    // Auto-navigate when upload completes
    ref.listen(documentUploadProvider, (prev, next) {
      if (next.uploadedDocument != null && prev?.uploadedDocument == null) {
        final docId = next.uploadedDocument!.id;
        ref.read(documentUploadProvider.notifier).reset();
        context.go('/documents/$docId');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Upload Document', style: AppTypography.titleMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload area
            Expanded(
              child: GestureDetector(
                onTap: uploadState.isUploading ? null : _pickFile,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(77),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: uploadState.hasFile
                      ? _buildFilePreview(uploadState)
                      : _buildDropZone(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Error message
            if (uploadState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        uploadState.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),

            // Upload button
            if (uploadState.hasFile && !uploadState.isUploading)
              ElevatedButton.icon(
                onPressed: () {
                  final user = ref.read(currentUserProvider);
                  if (user != null) {
                    ref.read(documentUploadProvider.notifier).upload(user.uid);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please sign in to upload documents')),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_upload_rounded),
                label: const Text('Upload & Analyze'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),

            // Progress indicator
            if (uploadState.isUploading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: uploadState.uploadProgress,
                backgroundColor: AppColors.surfaceVariant,
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _progressLabel(uploadState.uploadProgress),
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],

            // Supported formats
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Supported: PDF, PNG, JPG · Max 20 MB',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.upload_file_rounded,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        Text('Tap to select a file', style: AppTypography.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Upload PDFs or images for AI analysis',
          style:
              AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFilePreview(DocumentUploadState state) {
    final isPdf = state.fileExtension == 'pdf';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
          size: 64,
          color: isPdf ? AppColors.error : AppColors.info,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            state.selectedFileName ?? '',
            style: AppTypography.titleSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.fileSizeFormatted,
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: state.isUploading ? null : _pickFile,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('Change file'),
        ),
      ],
    );
  }

  String _progressLabel(double progress) {
    if (progress < 0.3) return 'Uploading...';
    if (progress < 0.6) return 'Extracting text...';
    if (progress < 0.8) return 'Analyzing content...';
    if (progress < 1.0) return 'Generating summary...';
    return 'Done!';
  }
}
