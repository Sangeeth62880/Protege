import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/learning_provider.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/animated_progress_bar.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/common/section_header.dart';

/// Explore screen for discovering new topics
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  String? _selectedTopic;

  static const _suggestedTopics = [
    _SuggestedTopic('Python', PhosphorIconsStyle.fill, 'code'),
    _SuggestedTopic('JavaScript', PhosphorIconsStyle.fill, 'code'),
    _SuggestedTopic('Data Science', PhosphorIconsStyle.fill, 'data'),
    _SuggestedTopic('Machine Learning', PhosphorIconsStyle.fill, 'ml'),
    _SuggestedTopic('Web Development', PhosphorIconsStyle.fill, 'web'),
    _SuggestedTopic('Mathematics', PhosphorIconsStyle.fill, 'math'),
    _SuggestedTopic('Physics', PhosphorIconsStyle.fill, 'science'),
    _SuggestedTopic('Algorithms', PhosphorIconsStyle.fill, 'algo'),
    _SuggestedTopic('Flutter', PhosphorIconsStyle.fill, 'code'),
    _SuggestedTopic('SQL', PhosphorIconsStyle.fill, 'data'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final topic = _selectedTopic ?? _searchController.text.trim();
    if (topic.isEmpty) return;
    context.push('/create-path/goals', extra: topic);
  }

  PhosphorIconData _topicIcon(String category) {
    switch (category) {
      case 'code': return PhosphorIcons.code(PhosphorIconsStyle.fill);
      case 'data': return PhosphorIcons.database(PhosphorIconsStyle.fill);
      case 'ml': return PhosphorIcons.robot(PhosphorIconsStyle.fill);
      case 'web': return PhosphorIcons.globe(PhosphorIconsStyle.fill);
      case 'math': return PhosphorIcons.mathOperations(PhosphorIconsStyle.fill);
      case 'science': return PhosphorIcons.atom(PhosphorIconsStyle.fill);
      case 'algo': return PhosphorIcons.treeStructure(PhosphorIconsStyle.fill);
      default: return PhosphorIcons.graduationCap(PhosphorIconsStyle.fill);
    }
  }

  Color _topicColor(String category) {
    switch (category) {
      case 'code': return AppColors.brand;
      case 'data': return AppColors.accentTeal;
      case 'ml': return AppColors.accentPink;
      case 'web': return AppColors.accentOrange;
      case 'math': return AppColors.info;
      case 'science': return AppColors.accentIndigo;
      case 'algo': return AppColors.success;
      default: return AppColors.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    final learningPaths = ref.watch(learningPathsStreamProvider);
    final hasInput = _selectedTopic != null || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSpacing.screenH.copyWith(top: 20, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ──
              StaggeredItem(
                index: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _selectedTopic = null),
                    decoration: InputDecoration(
                      hintText: 'Search topics...',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: PhosphorIcon(PhosphorIcons.magnifyingGlass(), size: 20, color: AppColors.textTertiary),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Featured card ──
              StaggeredItem(
                index: 1,
                child: AnimatedPressable(
                  onTap: () {
                    setState(() => _selectedTopic = 'Python');
                    _onContinue();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.brand, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.graduationCap(PhosphorIconsStyle.fill),
                              size: 48,
                              color: AppColors.brand,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('LEARNING PATH', style: AppTypography.labelSm.copyWith(color: AppColors.brand)),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Python Fundamentals', style: AppTypography.headingLg),
                            const SizedBox(height: AppSpacing.sm),
                            Text('Master Python from basics to advanced', style: AppTypography.bodyMd),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text('TOP PICK', style: AppTypography.labelSm.copyWith(color: AppColors.textOnBrand)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Browse Categories ──
              StaggeredItem(
                index: 2,
                child: const SectionHeader(title: 'Browse Categories'),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _suggestedTopics.asMap().entries.map((entry) {
                  final topic = entry.value;
                  final isSelected = _selectedTopic == topic.name;
                  final color = _topicColor(topic.category);

                  return StaggeredItem(
                    index: 3 + entry.key,
                    child: AnimatedPressable(
                      onTap: () {
                        setState(() {
                          _selectedTopic = isSelected ? null : topic.name;
                          if (!isSelected) _searchController.clear();
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isSelected ? color : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: isSelected ? [] : AppShadow.sm,
                          border: isSelected ? null : Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              _topicIcon(topic.category),
                              size: 18,
                              color: isSelected ? AppColors.textOnBrand : color,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              topic.name,
                              style: AppTypography.headingSm.copyWith(
                                fontSize: 14,
                                color: isSelected ? AppColors.textOnBrand : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Your Paths ──
              learningPaths.when(
                data: (paths) {
                  if (paths.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Your Paths'),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: paths.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final path = paths[index];
                            return AnimatedPressable(
                              onTap: () => context.push('/learn/${path.id}'),
                              child: Container(
                                width: 160,
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: AppShadow.sm,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      path.topic,
                                      style: AppTypography.headingSm.copyWith(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Column(
                                      children: [
                                        AnimatedProgressBar(progress: path.progress),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(path.progress * 100).toInt()}%',
                                          style: AppTypography.bodySm,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.huge),

              // ── Continue button ──
              if (hasInput)
                AnimatedPressable(
                  onTap: _onContinue,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: Center(
                      child: Text(
                        'Continue',
                        style: AppTypography.btnLg.copyWith(color: AppColors.textOnBrand),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.navbarClearance),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestedTopic {
  final String name;
  final PhosphorIconsStyle style;
  final String category;
  const _SuggestedTopic(this.name, this.style, this.category);
}
