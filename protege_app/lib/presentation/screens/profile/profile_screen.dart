import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common/animated_pressable.dart';
import '../../widgets/common/staggered_item.dart';
import '../../widgets/common/count_up_text.dart';
import '../../widgets/buttons/primary_button.dart';

/// Profile screen
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userData = ref.watch(userStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSpacing.screenH.copyWith(top: 20, bottom: 120),
          child: Column(
            children: [
              // ── Avatar + Name ──
              StaggeredItem(
                index: 0,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: PhosphorIcon(
                        PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
                        size: 44,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      user?.displayName ?? 'Learner',
                      style: AppTypography.headingLg,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      user?.email ?? '',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Stats Grid ──
              StaggeredItem(
                index: 1,
                child: userData.when(
                  data: (u) => _buildStatsGrid(
                    xp: u?.totalXp ?? 0,
                    streak: u?.currentStreak ?? 0,
                    lessons: u?.lessonsCompleted ?? 0,
                    teaches: u?.teachSessions ?? 0,
                  ),
                  loading: () => _buildStatsGrid(xp: 0, streak: 0, lessons: 0, teaches: 0),
                  error: (_, __) => _buildStatsGrid(xp: 0, streak: 0, lessons: 0, teaches: 0),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // ── Settings ──
              StaggeredItem(
                index: 2,
                child: Column(
                  children: [
                    const _LinkedAccountsRow(),
                    _SettingItem(
                      icon: PhosphorIcons.user(),
                      label: 'Edit Profile',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: PhosphorIcons.bell(),
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: PhosphorIcons.shieldCheck(),
                      label: 'Privacy',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: PhosphorIcons.question(),
                      label: 'Help & Support',
                      onTap: () {},
                    ),
                    _SettingItem(
                      icon: PhosphorIcons.signOut(),
                      label: 'Sign Out',
                      isDestructive: true,
                      onTap: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.navbarClearance),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid({
    required int xp,
    required int streak,
    required int lessons,
    required int teaches,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                iconColor: AppColors.success,
                bgColor: AppColors.successLight,
                value: xp,
                label: 'Total XP',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: PhosphorIcons.flame(PhosphorIconsStyle.fill),
                iconColor: AppColors.warning,
                bgColor: AppColors.warningLight,
                value: streak,
                label: 'Day Streak',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
                iconColor: AppColors.brand,
                bgColor: AppColors.brandLight,
                value: lessons,
                label: 'Lessons',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatCard(
                icon: PhosphorIcons.brain(PhosphorIconsStyle.fill),
                iconColor: AppColors.info,
                bgColor: AppColors.infoLight,
                value: teaches,
                label: 'Teaches',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final PhosphorIconData icon;
  final Color iconColor;
  final Color bgColor;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(child: PhosphorIcon(icon, size: 18, color: iconColor)),
          ),
          const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CountUpText(end: value, style: AppTypography.statSm),
              Text(label, style: AppTypography.bodySm),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    return AnimatedPressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 22, color: color),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text(label, style: AppTypography.bodyLg.copyWith(color: color))),
            PhosphorIcon(PhosphorIcons.caretRight(), size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountsRow extends StatelessWidget {
  const _LinkedAccountsRow();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData.map((p) => p.providerId).toList() ?? [];
    
    // If empty but authenticated, usually means email/password
    if (providers.isEmpty && user != null) {
      providers.add('password');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          PhosphorIcon(PhosphorIcons.link(), size: 22, color: AppColors.textPrimary),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: Text('Linked Accounts', style: AppTypography.bodyLg.copyWith(color: AppColors.textPrimary))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: providers.map((p) {
              PhosphorIconData icon;
              Color color = AppColors.textSecondary;
              
              if (p == 'google.com') {
                icon = PhosphorIcons.googleChromeLogo(PhosphorIconsStyle.fill);
                color = AppColors.textPrimary;
              } else if (p == 'apple.com') {
                icon = PhosphorIcons.appleLogo(PhosphorIconsStyle.fill);
                color = AppColors.textPrimary;
              } else {
                // Email / password
                icon = PhosphorIcons.envelopeSimple(PhosphorIconsStyle.fill);
              }
              
              return Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: PhosphorIcon(icon, size: 22, color: color),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
