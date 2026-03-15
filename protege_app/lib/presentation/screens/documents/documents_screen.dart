import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';

/// Documents upload screen
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Documents', style: AppTypography.headlineMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIcons.filePdf(PhosphorIconsStyle.fill),
                    size: 64,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                'Upload a Document',
                style: AppTypography.displaySm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Upload a PDF or image to get AI-powered summaries, explanations, and chat with your documents.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLg.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.huge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/documents/upload'),
                  icon: PhosphorIcon(PhosphorIcons.uploadSimple(), color: Colors.white, size: 20),
                  label: Text(
                    'Upload Document',
                    style: AppTypography.headingSm.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.brand.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
