import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_animations.dart';
import '../../../providers/auth_provider.dart';

/// Premium splash screen — white background with animated wordmark and loading bar.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _sequenceController;

  late Animation<double> _wordmarkFade;
  late Animation<double> _wordmarkScale;
  late Animation<double> _loadingBarScale;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Wordmark fade & scale in (Interval 0.0 - 0.25) ~ 500ms
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );
    _wordmarkScale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
      ),
    );

    // Loading bar width (Interval 0.3 - 0.8) ~ 1000ms
    _loadingBarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    // Exit fade out and scale up (Interval 0.85 - 1.0) ~ 300ms
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _sequenceController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    _sequenceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndRedirect();
      }
    });

    // Start sequence immediately
    _sequenceController.forward();
  }

  void _checkAuthAndRedirect() {
    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (!mounted) return;
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      },
      loading: () {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 200), _checkAuthAndRedirect);
      },
      error: (_, __) {
        if (!mounted) return;
        context.go('/login');
      },
    );
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _sequenceController,
        builder: (context, child) {
          // Wrap everything in exit transition
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Wordmark
                    FadeTransition(
                      opacity: _wordmarkFade,
                      child: ScaleTransition(
                        scale: _wordmarkScale,
                        child: Text(
                          'Protégé',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Loading bar
                    Container(
                      width: 80,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _loadingBarScale.value,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
