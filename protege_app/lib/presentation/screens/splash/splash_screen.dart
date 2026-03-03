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
  // Wordmark animation
  late AnimationController _wordmarkController;
  late Animation<double> _wordmarkFade;
  late Animation<double> _wordmarkScale;

  // Loading bar animation
  late AnimationController _loadingController;

  // Exit animation
  late AnimationController _exitController;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    // Wordmark: fade in + scale
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );
    _wordmarkScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: AppAnimations.curveSnap),
    );

    // Loading bar: fill left to right
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Exit: fade out + slight scale up
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );
    _exitScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Start animation sequence
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _wordmarkController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _loadingController.forward();

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _checkAuthAndRedirect();
  }

  void _checkAuthAndRedirect() {
    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        if (!mounted) return;
        _exitController.forward().then((_) {
          if (!mounted) return;
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        });
      },
      loading: () {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 500), _checkAuthAndRedirect);
      },
      error: (_, __) {
        if (!mounted) return;
        _exitController.forward().then((_) {
          if (!mounted) return;
          context.go('/login');
        });
      },
    );
  }

  @override
  void dispose() {
    _wordmarkController.dispose();
    _loadingController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _exitFade,
            child: ScaleTransition(
              scale: _exitScale,
              child: child,
            ),
          );
        },
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
              AnimatedBuilder(
                animation: _loadingController,
                builder: (context, _) {
                  return Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _loadingController.value,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
