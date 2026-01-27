import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/learning_path_model.dart';
import '../../widgets/cards/stats_card.dart';
import '../../widgets/cards/learning_path_card.dart';
import '../../widgets/cards/topic_card.dart';
import '../../widgets/common/search_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Get user from auth provider
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName?.split(' ').first ?? 'Friend';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // TODO: Refresh dashboard data
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header & Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textLight,
                              ),
                        ),
                        Text(
                          '$displayName!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.push('/profile'),
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user?.photoURL != null 
                            ? NetworkImage(user!.photoURL!) 
                            : null,
                        child: user?.photoURL == null 
                            ? Text(
                                displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Stats
                const StatsCard(
                  streakDays: 3,
                  totalXp: 1250,
                  lessonsCompleted: 12,
                ),
                const SizedBox(height: 32),

                // 3. Search Bar
                CustomSearchBar(
                  hintText: 'What do you want to learn today?',
                  onSubmitted: (query) {
                     // TODO: Navigate to exploration with query
                     context.go('/explore');
                  },
                ),
                const SizedBox(height: 32),

                // 4. Continue Learning (Mock logic)
                Text(
                  'Continue Learning',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                LearningPathCard(
                  isFeatured: true,
                  path: LearningPathModel(
                    id: '1',
                    userId: '1',
                    topic: 'Flutter Architecture',
                    description: 'Learn the best practices for building scalable Flutter apps.',
                    difficulty: 'intermediate',
                    modules: [
                      ModuleModel(
                        moduleNumber: 1,
                        title: 'State Management',
                        description: 'Learn state management patterns',
                        durationHours: 2.0,
                        lessons: [
                          const LessonModel(
                            lessonNumber: 1,
                            title: 'Introduction to Riverpod',
                            description: 'State management basics',
                            durationMinutes: 30,
                          ),
                        ],
                      ),
                    ],
                    createdAt: DateTime.now(),
                    progress: 0.35,
                  ),
                  onTap: () {
                    // Navigate to mock path
                    context.push('/learn/1');
                  },
                ),
                
                const SizedBox(height: 32),

                // 5. Recommended Topics
                Text(
                  'Recommended for you',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      TopicCard(
                        title: 'Python for AI',
                        difficulty: 'Beginner',
                        estimatedTime: '4h',
                        icon: Icons.code_rounded,
                        onTap: () {},
                      ),
                      TopicCard(
                        title: 'Data Structures',
                        difficulty: 'Intermediate',
                        estimatedTime: '6h',
                        icon: Icons.storage_rounded,
                        onTap: () {},
                      ),
                      TopicCard(
                        title: 'System Design',
                        difficulty: 'Advanced',
                        estimatedTime: '8h',
                        icon: Icons.architecture_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
