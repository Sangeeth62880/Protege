import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/learning_provider.dart';
import '../../../data/models/learning_path_model.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/common/staggered_item.dart';

class SyllabusPreviewScreen extends ConsumerStatefulWidget {
  const SyllabusPreviewScreen({super.key});

  @override
  ConsumerState<SyllabusPreviewScreen> createState() => _SyllabusPreviewScreenState();
}

class _SyllabusPreviewScreenState extends ConsumerState<SyllabusPreviewScreen> {
  Future<void> _onStartLearning(SyllabusModel? syllabus) async {
    if (syllabus == null) return;
    final path = await ref.read(saveSyllabusProvider.notifier).save(syllabus);
    if (path != null && mounted) {
      context.push('/learn/${path.id}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Try again.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syllabusState = ref.watch(syllabusGeneratorProvider);
    final saveState = ref.watch(saveSyllabusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIcons.arrowLeft(), size: 22),
          onPressed: () {
            ref.read(syllabusGeneratorProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text('Syllabus Preview', style: AppTypography.headingSm),
      ),
      body: syllabusState.when(
        data: (syllabus) {
          if (syllabus == null) {
            return Center(
              child: Text('No syllabus data', style: AppTypography.bodyMd),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: AppSpacing.screenH.copyWith(top: 8, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      StaggeredItem(
                        index: 0,
                        child: Text(syllabus.topic, style: AppTypography.displaySm),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      StaggeredItem(
                        index: 1,
                        child: Text(
                          syllabus.description,
                          style: AppTypography.bodyLg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Stats row
                      StaggeredItem(
                        index: 2,
                        child: Row(
                          children: [
                            _StatBadge(
                              icon: PhosphorIcons.stack(PhosphorIconsStyle.fill),
                              color: AppColors.brand,
                              label: '${syllabus.modules.length} modules',
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _StatBadge(
                              icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                              color: AppColors.success,
                              label: '${syllabus.modules.fold<int>(0, (sum, m) => sum + m.lessons.length)} lessons',
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _StatBadge(
                              icon: PhosphorIcons.clock(PhosphorIconsStyle.fill),
                              color: AppColors.accentOrange,
                              label: '${syllabus.totalDurationHours}h',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Modules
                      ...syllabus.modules.asMap().entries.map((entry) {
                        final module = entry.value;
                        return StaggeredItem(
                          index: 3 + entry.key,
                          child: _ModuleCard(module: module, index: entry.key),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl + AppSpacing.navbarClearance,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: saveState.when(
                  data: (_) => PrimaryButton(
                    label: 'Start Learning',
                    onPressed: () => _onStartLearning(syllabus),
                  ),
                  loading: () => const PrimaryButton(label: 'Saving...', isLoading: true),
                  error: (_, __) => PrimaryButton(
                    label: 'Retry',
                    onPressed: () => _onStartLearning(syllabus),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brand)),
        error: (e, __) => Center(child: Text('Error: $e', style: AppTypography.bodyMd)),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final PhosphorIconData icon;
  final Color color;
  final String label;
  const _StatBadge({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.bodySm.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleModel module;
  final int index;
  const _ModuleCard({required this.module, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.brandLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.headingSm.copyWith(fontSize: 13, color: AppColors.brand),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(module.title, style: AppTypography.headingSm),
              ),
            ],
          ),
          if (module.description != null && module.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(module.description!, style: AppTypography.bodySm, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: module.lessons.map((lesson) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      PhosphorIcon(PhosphorIcons.circle(), size: 8, color: AppColors.textTertiary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(lesson.title, style: AppTypography.bodyMd),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
