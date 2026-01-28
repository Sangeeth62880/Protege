import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class MultipleChoiceOptions extends StatelessWidget {
  final List<String> options;
  final String? selectedOption;
  final Function(String)? onSelected;

  const MultipleChoiceOptions({
    super.key,
    required this.options,
    this.selectedOption,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedOption == option;
        // Parse "A) Option" if needed, or just display raw
        // The backend sends formatted strings like "A) Option 1" usually
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onSelected != null ? () => onSelected!(option) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade400,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class TrueFalseOptions extends StatelessWidget {
  final String? selectedOption;
  final Function(String)? onSelected;

  const TrueFalseOptions({
    super.key,
    this.selectedOption,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildButton(context, "True", Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildButton(context, "False", Colors.red)),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String label, Color color) {
    // Backend expects lowercase "true" or "false" usually? 
    // Backend prompt says: correct_answer: "true"
    // So we should send "true" or "false" (lowercase)
    final value = label.toLowerCase();
    final isSelected = selectedOption == value;
    
    return InkWell(
      onTap: onSelected != null ? () => onSelected!(value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              label == "True" ? Icons.check_circle_outline : Icons.highlight_off,
              size: 32,
              color: isSelected ? color : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
