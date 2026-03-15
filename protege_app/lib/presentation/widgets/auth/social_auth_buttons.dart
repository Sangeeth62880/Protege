import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../common/animated_pressable.dart';

class SocialAuthButtons extends ConsumerStatefulWidget {
  final bool isLoading; // Whether parent form is loading

  const SocialAuthButtons({
    super.key,
    this.isLoading = false,
  });

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _anyLoading => widget.isLoading || _isGoogleLoading || _isAppleLoading;

  Future<void> _handleGoogleSignIn() async {
    if (_anyLoading) return;
    setState(() => _isGoogleLoading = true);
    
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      final errorMsg = authState.error.toString();
      // Handle missing config gracefull
      if (errorMsg.contains('platformException') || errorMsg.contains('developer_error')) {
        _showError('Google Sign-In is not configured. Please contact support.');
      } else {
        _showError(errorMsg);
      }
    } else if (authState.value != null) {
      context.go('/home');
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_anyLoading) return;
    setState(() => _isAppleLoading = true);
    
    await ref.read(authNotifierProvider.notifier).signInWithApple();
    
    if (!mounted) return;
    setState(() => _isAppleLoading = false);
    
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      _showError(authState.error.toString());
    } else if (authState.value != null) {
      context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showApple = !kIsWeb && (Platform.isIOS || Platform.isMacOS);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Button
        AnimatedPressable(
          onTap: _anyLoading ? null : _handleGoogleSignIn,
          child: Opacity(
            opacity: (_anyLoading && !_isGoogleLoading) ? 0.6 : 1.0,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Center(
                child: _isGoogleLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.googleChromeLogo(PhosphorIconsStyle.fill),
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Continue with Google',
                            style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        
        if (showApple) ...[
          const SizedBox(height: AppSpacing.md),
          // Apple Button
          AnimatedPressable(
            onTap: _anyLoading ? null : _handleAppleSignIn,
            child: Opacity(
              opacity: (_anyLoading && !_isAppleLoading) ? 0.6 : 1.0,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary, // Near black
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Center(
                  child: _isAppleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PhosphorIcon(
                              PhosphorIcons.appleLogo(PhosphorIconsStyle.fill),
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Continue with Apple',
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        
        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'or continue with email',
                style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.borderLight, thickness: 1)),
          ],
        ),
      ],
    );
  }
}
