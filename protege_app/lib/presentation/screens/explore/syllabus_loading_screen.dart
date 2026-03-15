import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/learning_provider.dart';
import '../../widgets/common/glass_container.dart';

class SyllabusLoadingScreen extends ConsumerStatefulWidget {
  final String topic;
  final String goal;
  final String difficulty;
  final int duration;

  const SyllabusLoadingScreen({
    super.key,
    required this.topic,
    required this.goal,
    required this.difficulty,
    required this.duration,
  });

  @override
  ConsumerState<SyllabusLoadingScreen> createState() => _SyllabusLoadingScreenState();
}

class _SyllabusLoadingScreenState extends ConsumerState<SyllabusLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _phaseTimer;
  
  // 0: Loading, 1: Formatting, 2: Almost ready, 3: Done/Success
  int _currentPhase = 0;
  bool _apiResponseReceived = false;
  double _progressTarget = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startPhaseAnimation();
    Future.microtask(() => _startGeneration());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startPhaseAnimation() {
    // Phase 1 (0-3s)
    setState(() {
      _currentPhase = 0;
      _progressTarget = 0.3; // 30%
    });

    _phaseTimer = Timer(const Duration(seconds: 3), () {
      if (_apiResponseReceived || !mounted) return;
      // Phase 2 (3-6s)
      setState(() {
        _currentPhase = 1;
        _progressTarget = 0.6; // 60%
      });

      _phaseTimer = Timer(const Duration(seconds: 3), () {
        if (_apiResponseReceived || !mounted) return;
        // Phase 3 (6-9s)
        setState(() {
          _currentPhase = 2;
          _progressTarget = 0.85; // 85%
        });

        // Stays perfectly here looping until API finishes
      });
    });
  }

  Future<void> _startGeneration() async {
    try {
      final result = await ref.read(syllabusGeneratorProvider.notifier).generateSyllabus(
        topic: widget.topic,
        goal: widget.goal,
        difficulty: widget.difficulty,
        dailyMinutes: widget.duration,
      ).timeout(const Duration(seconds: 130));

      if (!mounted) return;

      if (result != null) {
        _handleSuccess();
      } else {
        final state = ref.read(syllabusGeneratorProvider);
        _handleError(message: state.hasError ? state.error.toString() : null);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Something went wrong. Please try again.';
      if (e.toString().contains('Connection refused') || e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Check your connection.';
      } else if (e.toString().contains('503')) {
        errorMessage = 'AI Service unavailable. Try again later.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timed out. The AI is taking too long.';
      }
      _handleError(message: errorMessage);
    }
  }

  void _handleSuccess() {
    _phaseTimer?.cancel();
    setState(() {
      _apiResponseReceived = true;
      _currentPhase = 3; // Success state
      _progressTarget = 1.0; // 100%
    });

    // Short delay to show 100% and success icon before popping
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        context.pushReplacement('/create-path/preview');
      }
    });
  }

  void _handleError({String? message}) {
    _phaseTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Failed to generate syllabus.'), backgroundColor: AppColors.error),
    );
    if (mounted) context.pop();
  }

  // Helper properties per phase
  String get _phaseText {
    switch (_currentPhase) {
      case 0: return 'Understanding your goals...';
      case 1: return 'Designing your learning path...';
      case 2: return 'Almost ready...';
      case 3: return 'Your path is ready!';
      default: return 'Loading...';
    }
  }

  PhosphorIconData get _phaseIcon {
    switch (_currentPhase) {
      case 0: return PhosphorIcons.brain(PhosphorIconsStyle.fill);
      case 1: return PhosphorIcons.treeStructure(PhosphorIconsStyle.fill);
      case 2: return PhosphorIcons.sparkle(PhosphorIconsStyle.fill);
      case 3: return PhosphorIcons.checkCircle(PhosphorIconsStyle.fill);
      default: return PhosphorIcons.brain(PhosphorIconsStyle.fill);
    }
  }

  Color get _phaseColor {
    return _currentPhase == 3 ? AppColors.success : AppColors.brand;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background UI mockup (simulating form blur) overlay
          Positioned.fill(
            child: Container(
              color: AppColors.background, // fallback
              // If we wanted to see the form behind, it would be passed in or Shell would be used.
              // Since this is a separate route, we'll just have the background color and place the glass on top
            ),
          ),
          
          // Full screen glass overlay
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: _currentPhase == 3 ? 0.0 : 1.0, 
              // Fade out the glass slightly before navigating away, or just fade immediately right before push
              // We'll let it stay for the 800ms
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
              child: GlassContainer(
                backgroundColor: Colors.black,
                opacity: 0.15,
                blurSigma: 10,
                borderRadius: 0,
                borderOpacity: 0.0,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon wrapped in scale animation (pulsing in phase 0-2, popping to 1 in phase 3)
                      AnimatedScale(
                        scale: _currentPhase == 3 ? 1.0 : (_pulseController.value * 0.1 + 0.95),
                        duration: _currentPhase == 3 ? const Duration(milliseconds: 300) : const Duration(milliseconds: 0),
                        curve: Curves.easeOutBack,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _currentPhase == 3 ? 1.0 : (_pulseController.value * 0.1 + 0.95),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                                child: PhosphorIcon(
                                  _phaseIcon,
                                  key: ValueKey(_currentPhase),
                                  size: 48,
                                  color: _phaseColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Phase Text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _phaseText,
                          key: ValueKey(_phaseText),
                          style: AppTypography.headingSm.copyWith(color: Colors.white),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Progress Bar Container
                      Container(
                        width: 200,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Stack(
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: _progressTarget),
                              duration: Duration(milliseconds: _currentPhase == 3 || _currentPhase == 0 ? 300 : 3000),
                              curve: _currentPhase == 3 ? Curves.easeOut : Curves.linear,
                              builder: (context, value, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _phaseColor,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _phaseColor.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
