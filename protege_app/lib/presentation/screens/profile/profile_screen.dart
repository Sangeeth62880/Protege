import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../widgets/cards/modern_card.dart';

/// Profile screen with user info, live stats, achievements, and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userDataAsync = ref.watch(userStreamProvider);
    final displayName = user?.displayName ?? 'User';
    final email = user?.email ?? 'user@example.com';
    final initials = displayName.isNotEmpty 
        ? displayName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join().toUpperCase()
        : 'U';
    
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
                initials,
                user?.photoURL,
                userDataAsync.valueOrNull?.createdAt,
              ),
            ),
            
            // Stats Grid — live
            SliverToBoxAdapter(
              child: userDataAsync.when(
                data: (userData) => _buildStatsGrid(context, userData),
                loading: () => _buildStatsGrid(context, null),
                error: (_, __) => _buildStatsGrid(context, null),
              ),
            ),
            
            // Achievements Section — live
            SliverToBoxAdapter(
              child: userDataAsync.when(
                data: (userData) => _buildAchievements(context, userData?.badges ?? []),
                loading: () => _buildAchievements(context, []),
                error: (_, __) => _buildAchievements(context, []),
              ),
            ),
            
            // Settings Section
            SliverToBoxAdapter(
              child: _buildSettings(context, ref),
            ),
            
            // Logout Button
            SliverToBoxAdapter(
              child: _buildLogout(context, ref),
            ),
            
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String name,
    String email,
    String initials,
    String? photoUrl,
    DateTime? createdAt,
  ) {
    final memberSince = createdAt != null
        ? DateFormat('MMMM yyyy').format(createdAt)
        : 'recently';

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  image: photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(77),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: photoUrl == null
                    ? Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _showEditProfileSheet(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            name,
            style: AppTypography.headlineLarge,
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            email,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Member since — live
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🎓 Learning since $memberSince',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, dynamic userData) {
    final streak = userData?.currentStreak?.toString() ?? '0';
    final xp = userData?.totalXp != null ? _formatNumber(userData!.totalXp) : '0';
    final lessons = userData?.lessonsCompleted?.toString() ?? '0';
    final teaches = userData?.teachSessions?.toString() ?? '0';
    final quizzes = userData?.quizzesPassed?.toString() ?? '0';
    final timeSpent = userData?.totalLearningMinutes != null
        ? _formatTime(userData!.totalLearningMinutes)
        : '0h';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ModernCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Statistics',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(
                  icon: Icons.local_fire_department_rounded,
                  value: streak,
                  label: 'Day Streak',
                  color: AppColors.streak,
                ),
                _StatItem(
                  icon: Icons.star_rounded,
                  value: xp,
                  label: 'Total XP',
                  color: AppColors.xp,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(
                  icon: Icons.check_circle_rounded,
                  value: lessons,
                  label: 'Lessons Done',
                  color: AppColors.success,
                ),
                _StatItem(
                  icon: Icons.psychology_rounded,
                  value: teaches,
                  label: 'Teach Sessions',
                  color: AppColors.teachMode,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(
                  icon: Icons.quiz_rounded,
                  value: quizzes,
                  label: 'Quizzes Passed',
                  color: AppColors.quizMode,
                ),
                _StatItem(
                  icon: Icons.timer_rounded,
                  value: timeSpent,
                  label: 'Time Spent',
                  color: AppColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, List<Map<String, dynamic>> badges) {
    // Default achievement definitions
    final defaultBadges = [
      {'icon': 'emoji_events', 'title': 'First Lesson', 'key': 'first_lesson'},
      {'icon': 'local_fire_department', 'title': '7 Day Streak', 'key': 'streak_7'},
      {'icon': 'psychology', 'title': 'First Teach', 'key': 'first_teach'},
      {'icon': 'school', 'title': 'Path Master', 'key': 'path_master'},
      {'icon': 'diamond', 'title': '100 XP Day', 'key': 'xp_100'},
    ];

    final unlockedKeys = badges.map((b) => b['key'] as String? ?? '').toSet();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: AppTypography.titleMedium,
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'See all',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: defaultBadges.map((badge) {
                final isUnlocked = unlockedKeys.contains(badge['key']);
                return _AchievementBadge(
                  icon: _badgeIcon(badge['icon'] as String),
                  title: badge['title'] as String,
                  color: _badgeColor(badge['key'] as String),
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

  Color _badgeColor(String key) {
    switch (key) {
      case 'first_lesson': return AppColors.xp;
      case 'streak_7': return AppColors.streak;
      case 'first_teach': return AppColors.teachMode;
      case 'path_master': return AppColors.primary;
      case 'xp_100': return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return n.toString();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 12),
          ModernCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () => _showEditProfileSheet(context),
                ),
                _divider(),
                _SettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                    activeTrackColor: AppColors.primary.withAlpha(128),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                _divider(),
                _SettingItem(
                  icon: Icons.timer_outlined,
                  title: 'Daily Goal',
                  subtitle: '30 minutes',
                  onTap: () => _showDailyGoalSheet(context),
                ),
                _divider(),
                _SettingItem(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                _divider(),
                _SettingItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {},
                ),
                _divider(),
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

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
      indent: 56,
    );
  }

  Widget _buildLogout(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.error.withAlpha(51),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
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
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile', style: AppTypography.headlineSmall),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Save Changes'),
              ),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set Daily Goal', style: AppTypography.headlineSmall),
            const SizedBox(height: 20),
            ...[15, 30, 45, 60].map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              trailing: minutes == 30 
                  ? const Icon(Icons.check, color: AppColors.primary)
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
            const SizedBox(height: 16),
            Text(
              '© 2024 Protégé Learning',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Widgets

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isUnlocked ? color.withAlpha(26) : AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? color : AppColors.border,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : AppColors.textDisabled,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textDisabled,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.caption,
                    ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
