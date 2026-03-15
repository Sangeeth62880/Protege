import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

/// Premium splash screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _wordmarkController;
  late Animation<double> _wordmarkFade;
  late Animation<double> _wordmarkScale;
  late AnimationController _loadingController;
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();

    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: Curves.easeOut),
    );
    _wordmarkScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _wordmarkController, curve: AppMotion.curveSnap),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

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
          context.go(user != null ? '/home' : '/login');
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
      body: FadeTransition(
        opacity: _exitFade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _wordmarkFade,
                child: ScaleTransition(
                  scale: _wordmarkScale,
                  child: Text('Protégé', style: AppTypography.displayLg.copyWith(fontSize: 48)),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
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
                          color: AppColors.brand,
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
