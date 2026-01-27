import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protege_app/presentation/screens/home/home_screen.dart';
import 'package:protege_app/presentation/screens/explore/explore_screen.dart';
import 'package:protege_app/presentation/screens/learning/learning_path_screen.dart';
import 'package:protege_app/presentation/screens/profile/profile_screen.dart';
import 'package:protege_app/presentation/screens/splash/splash_screen.dart';
import 'package:protege_app/presentation/screens/auth/login_screen.dart';
import 'package:protege_app/presentation/screens/auth/signup_screen.dart';
import 'package:protege_app/presentation/screens/shell/main_shell.dart';
import 'package:protege_app/presentation/screens/explore/goal_selection_screen.dart';
import 'package:protege_app/presentation/screens/explore/syllabus_loading_screen.dart';
import 'package:protege_app/presentation/screens/explore/syllabus_preview_screen.dart';
import '../../presentation/screens/tutor/tutor_chat_screen.dart';
import '../../presentation/screens/lesson/lesson_screen.dart';
import '../../providers/auth_provider.dart';

// Private navigator keys
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorExploreKey = GlobalKey<NavigatorState>(debugLabel: 'shellExplore');
final _shellNavigatorLearnKey = GlobalKey<NavigatorState>(debugLabel: 'shellLearn');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

class AppRouter {
  static final routerProvider = Provider<GoRouter>((ref) {
    final authState = ref.watch(authStateProvider);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isLoading = authState.isLoading;
        // ... rest of redirect logic
        final hasError = authState.hasError;
        final isAuthenticated = authState.valueOrNull != null;
        
        final isSplash = state.uri.path == '/';
        final isLogin = state.uri.path == '/login';
        final isSignup = state.uri.path == '/signup';
        final isReset = state.uri.path == '/forgot-password';

        // If still loading auth, show splash
        if (isLoading) return null;

        // If authenticated and trying to access auth routes, go to home
        if (isAuthenticated && (isSplash || isLogin || isSignup || isReset)) {
          return '/home';
        }

        // If not authenticated and trying to access protected routes, go to login
        if (!isAuthenticated && !isSplash && !isLogin && !isSignup && !isReset) {
          return '/login';
        }

        return null;
      },
      routes: [
        // Splash Screen
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const Scaffold(body: Center(child: Text("Forgot Password (TODO)"))), // Placeholder
        ),

        // Main App Shell with Bottom Navigation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // Home Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorHomeKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            
            // Explore Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorExploreKey,
              routes: [
                GoRoute(
                  path: '/explore',
                  builder: (context, state) => const ExploreScreen(),
                ),
              ],
            ),
            
            // Learning Branch (Progress)
            StatefulShellBranch(
              navigatorKey: _shellNavigatorLearnKey,
              routes: [
                GoRoute(
                  path: '/learning',
                  builder: (context, state) => const Scaffold(body: Center(child: Text("My Learning (TODO)"))), // Reuse learning path list or screen
                ),
              ],
            ),
            
            // Profile Branch
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfileKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        
        // Create Path Flow Routes
        GoRoute(
          path: '/create-path/goals',
          builder: (context, state) {
            final topic = state.extra as String;
            return GoalSelectionScreen(topic: topic);
          },
        ),
        GoRoute(
          path: '/create-path/loading',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            return SyllabusLoadingScreen(
              topic: params['topic'],
              goal: params['goal'],
              difficulty: params['difficulty'],
              duration: params['duration'],
            );
          },
        ),
        GoRoute(
          path: '/create-path/preview',
          builder: (context, state) => const SyllabusPreviewScreen(),
        ),

        // Individual Routes (Push on top of shell)
        GoRoute(
          path: '/tutor',
          builder: (context, state) {
            final extras = state.extra as Map<String, dynamic>;
            return TutorChatScreen(
              topic: extras['topic'] as String,
              lessonTitle: extras['lessonTitle'] as String,
              keyConcepts: List<String>.from(extras['keyConcepts']),
              experienceLevel: extras['experienceLevel'] as String,
            );
          },
        ),
        GoRoute(
          path: '/learn/:pathId',
          builder: (context, state) {
            final pathId = state.pathParameters['pathId']!;
            return LearningPathScreen(learningPathId: pathId);
          },
          routes: [
            GoRoute(
              path: 'lesson/:lessonId',
              builder: (context, state) {
                final pathId = state.pathParameters['pathId']!;
                final lessonId = state.pathParameters['lessonId']!;
                return LessonScreen(
                  pathId: pathId,
                  lessonId: int.parse(lessonId),
                );
              },
            ),
          ],
        ),
      ],
    );
  });
}
