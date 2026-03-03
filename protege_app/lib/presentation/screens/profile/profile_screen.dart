import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/common/accent_stat_card.dart';

import '../../widgets/common/custom_switch.dart';
import '../../widgets/icons/flame_icon.dart';
import '../../widgets/icons/sparkle_star_icon.dart';

/// Profile screen with user info, live stats, achievements, and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userStreamProvider);
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'user@example.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: _buildProfileHeader(
                context,
                displayName,
                email,
                user?.photoURL,
                userDataAsync.valueOrNull?.createdAt,
              ),
            ),

            // Stats Grid
            SliverToBoxAdapter(
              child: userDataAsync.when(
                data: (userData) => _buildStatsGrid(context, userData),
                loading: () => _buildStatsGrid(context, null),
                error: (_, __) => _buildStatsGrid(context, null),
              ),
            ),

            // Achievements
            SliverToBoxAdapter(
              child: userDataAsync.when(
                data: (userData) => _buildAchievements(context, userData?.badges ?? []),
                loading: () => _buildAchievements(context, []),
                error: (_, __) => _buildAchievements(context, []),
              ),
            ),

            // Settings
            SliverToBoxAdapter(child: _buildSettings(context, ref)),

            // Logout
            SliverToBoxAdapter(child: _buildLogout(context, ref)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String email,
    String? photoUrl,
    DateTime? createdAt,
  ) {
    final memberSince = createdAt != null
        ? DateFormat('MMMM yyyy').format(createdAt)
        : 'recently';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photoUrl == null
                ? const Center(
                    child: Icon(Icons.person_rounded, size: 40, color: AppColors.textTertiary),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name
          Text(name, style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(email, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),

          // Member since badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Learning since $memberSince',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic userData) {
    final streak = userData?.currentStreak ?? 0;
    final xp = userData?.totalXp ?? 0;
    final lessons = userData?.lessonsCompleted ?? 0;
    final teaches = userData?.teachSessions ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AccentStatCard(
                  backgroundColor: AppColors.greenLight,
                  icon: const SparkleStarIcon(size: 20, color: AppColors.green),
                  value: xp,
                  label: 'Total XP',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AccentStatCard(
                  backgroundColor: AppColors.yellowLight,
                  icon: const FlameIcon(size: 20),
                  value: streak,
                  label: 'Day Streak',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AccentStatCard(
                  backgroundColor: AppColors.purpleLight,
                  icon: const Icon(Icons.menu_book_rounded, color: AppColors.purple, size: 20),
                  value: lessons,
                  label: 'Completed',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AccentStatCard(
                  backgroundColor: AppColors.blueLight,
                  icon: const Icon(Icons.school_rounded, color: AppColors.blue, size: 20),
                  value: teaches,
                  label: 'Teach Sessions',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List<Map<String, dynamic>> badges) {
    final defaultBadges = [
      {'icon': 'emoji_events', 'title': 'First Lesson', 'key': 'first_lesson', 'color': AppColors.amber},
      {'icon': 'local_fire_department', 'title': '7 Day Streak', 'key': 'streak_7', 'color': AppColors.orange},
      {'icon': 'psychology', 'title': 'First Teach', 'key': 'first_teach', 'color': AppColors.purple},
      {'icon': 'school', 'title': 'Path Master', 'key': 'path_master', 'color': AppColors.green},
      {'icon': 'diamond', 'title': '100 XP Day', 'key': 'xp_100', 'color': AppColors.blue},
    ];

    final unlockedKeys = badges.map((b) => b['key'] as String? ?? '').toSet();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Achievements', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: defaultBadges.map((badge) {
                final isUnlocked = unlockedKeys.contains(badge['key']);
                return _AchievementBadge(
                  icon: _badgeIcon(badge['icon'] as String),
                  title: badge['title'] as String,
                  color: badge['color'] as Color,
                  isUnlocked: isUnlocked,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _badgeIcon(String key) {
    switch (key) {
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'school': return Icons.school_rounded;
      case 'diamond': return Icons.diamond_rounded;
      default: return Icons.star_rounded;
    }
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTypography.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () => _showEditProfileSheet(context),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: const _NotificationSwitch(),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _SettingItem(
                  icon: Icons.timer_outlined,
                  title: 'Daily Goal',
                  subtitle: '30 minutes',
                  onTap: () => _showDailyGoalSheet(context),
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _SettingItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56, color: AppColors.borderLight),
                _SettingItem(
                  icon: Icons.info_outline_rounded,
                  title: 'About',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.redLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.red.withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.red, size: 20),
              const SizedBox(width: 8),
              Text('Log Out', style: AppTypography.buttonMedium.copyWith(color: AppColors.red)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile', style: AppTypography.headlineSmall),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: 'Display Name', hintText: 'Enter your name')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Email', hintText: 'Enter your email')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDailyGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set Daily Goal', style: AppTypography.headlineSmall),
            const SizedBox(height: 20),
            ...[15, 30, 45, 60].map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              trailing: minutes == 30
                  ? const Icon(Icons.check_rounded, color: AppColors.green)
                  : null,
              onTap: () => Navigator.pop(context),
            )),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Protégé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: AppTypography.bodyMedium),
            const SizedBox(height: 8),
            Text(
              'Protégé is your AI-powered learning companion. '
              'Learn anything, prove mastery by teaching, and track your progress.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Text('Log Out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// Helper widgets

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.icon,
    required this.title,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked ? color.withAlpha(20) : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? color : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : AppColors.textDisabled,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NotificationSwitch extends StatefulWidget {
  const _NotificationSwitch();

  @override
  State<_NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<_NotificationSwitch> {
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CustomSwitch(
      value: _isEnabled,
      onChanged: (value) {
        setState(() {
          _isEnabled = value;
        });
      },
    );
  }
}
