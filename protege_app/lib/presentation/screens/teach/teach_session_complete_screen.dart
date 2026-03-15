import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_design.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/teaching_session_model.dart';

class TeachSessionCompleteScreen extends StatelessWidget {
  final Map<String, dynamic> results;

  const TeachSessionCompleteScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    // The backend primarily returns `evaluation` dict
    final evaluation = results['evaluation'] as Map<String, dynamic>? ?? {};

    // Parse results
    final topic = results['topic'] as String? ?? 'General Topic';
    final personaName = results['persona'] as String? ?? 'Student';
    
    final overallScore = (evaluation['overall_score'] as num?)?.toInt() ?? 0;
    final accuracyConfidence = (results['accuracy_confidence'] as num?)?.toInt() ?? 100;
    
    final clarity = (evaluation['clarity_score'] as num?)?.toInt() ?? 0;
    final accuracy = (evaluation['accuracy_score'] as num?)?.toInt() ?? 0;
    final completeness = (evaluation['depth_score'] as num?)?.toInt() ?? 0;
    
    final summary = evaluation['summary'] as String? ?? 'Session completed.';
    
    final strengthsList = evaluation['strengths'] as List<dynamic>? ?? [];
    final strengths = strengthsList.map((e) => e.toString()).toList();
    
    final improvementsList = evaluation['improvements'] as List<dynamic>? ?? [];
    final improvements = improvementsList.map((e) => e.toString()).toList();
    
    final misconceptionsList = results['misconceptions'] as List<dynamic>? ?? [];
    final misconceptions = misconceptionsList.map((e) => Map<String, String>.from(e as Map)).toList();
    
    final nextActions = [
      'Review foundational concepts of $topic',
      'Try teaching $personaName again to improve your score',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Session Complete',
          style: AppTypography.titleMedium,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Force user to use our buttons
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: 120.0, // Added bottom padding to stand clear of the nav bar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Ring
              Center(
                child: SizedBox(
                  height: 180, // Increased height to prevent overlap
                  width: 180,  // Increased width
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 180,
                        width: 180,
                        child: CircularProgressIndicator(
                          value: overallScore / 100,
                          strokeWidth: 14,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(overallScore)),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$overallScore',
                            style: AppTypography.displayMedium.copyWith(
                              color: _getScoreColor(overallScore),
                              fontWeight: FontWeight.bold,
                              fontSize: 56, // Adjusted font size to fit nicely
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Mastery',
                            style: AppTypography.labelLarge.copyWith( // Slightly larger text
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Accuracy Indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAccuracyIcon(accuracyConfidence),
                      color: _getScoreColor(accuracyConfidence),
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accuracy Confidence',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getAccuracyText(accuracyConfidence),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$accuracyConfidence%',
                      style: AppTypography.titleLarge.copyWith(
                        color: _getScoreColor(accuracyConfidence),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Summary Section
              Text(
                'Summary for $personaName',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(
                summary,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Aha breakdown
              _buildScoreBar('Clarity', clarity),
              const SizedBox(height: 12),
              _buildScoreBar('Accuracy', accuracy),
              const SizedBox(height: 12),
              _buildScoreBar('Completeness', completeness),
              const SizedBox(height: 32),
              
              // Key Strengths
              if (strengths.isNotEmpty) ...[
                Text('💪 Key Strengths', style: AppTypography.titleSmall),
                const SizedBox(height: 12),
                ...strengths.map((str) => _buildBulletPoint(str, AppColors.success)),
                const SizedBox(height: 24),
              ],
              
              // Improvements
              if (improvements.isNotEmpty) ...[
                Text('📈 Areas to Improve', style: AppTypography.titleSmall),
                const SizedBox(height: 12),
                ...improvements.map((imp) => _buildBulletPoint(imp, AppColors.warning)),
                const SizedBox(height: 24),
              ],

              // Misconceptions
              if (misconceptions.isNotEmpty) ...[
                Text('⚠️ Misconceptions Detected', style: AppTypography.titleSmall.copyWith(color: AppColors.error)),
                const SizedBox(height: 12),
                ...misconceptions.map((misc) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detected:', style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
                      const SizedBox(height: 4),
                      Text(misc['detected'] ?? 'Unknown', style: AppTypography.bodyMedium),
                      const SizedBox(height: 12),
                      Text('Canonical Truth:', style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
                      const SizedBox(height: 4),
                      Text(misc['canonical'] ?? 'Unknown', style: AppTypography.bodyMedium),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
              ],
              
              // Next Actions
              if (nextActions.isNotEmpty) ...[
                Text('🎯 Next Best Actions', style: AppTypography.titleSmall),
                const SizedBox(height: 12),
                ...nextActions.map((action) => _buildBulletPoint(action, AppColors.primary)),
                const SizedBox(height: 32),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      onPressed: () {
                        // Go back to progress or wherever
                        context.go('/home');
                      },
                      child: Text(
                        'Back to Home',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // Go back to progress or wherever
                        context.go('/teach');
                      },
                      child: Text(
                        'Teach Another',
                        style: AppTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              // Removed the extra height here, relying on bottom padding instead
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: AppTypography.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getScoreColor(score),
              ),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text('$score', style: AppTypography.labelSmall),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
  
  IconData _getAccuracyIcon(int conf) {
    if (conf >= 90) return Icons.verified_user_rounded;
    if (conf >= 70) return Icons.gpp_maybe_rounded;
    return Icons.gpp_bad_rounded;
  }
  
  String _getAccuracyText(int conf) {
    if (conf >= 90) return 'Highly accurate information taught.';
    if (conf >= 70) return 'Mostly accurate, minor inaccuracies.';
    return 'Significant inaccuracies detected.';
  }
}
