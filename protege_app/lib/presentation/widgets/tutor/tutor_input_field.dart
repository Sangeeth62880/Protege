import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TutorInputField extends StatefulWidget {
  final Function(String) onSubmitted;
  final bool isLoading;

  const TutorInputField({
    super.key,
    required this.onSubmitted,
    this.isLoading = false,
  });

  @override
  State<TutorInputField> createState() => _TutorInputFieldState();
}

class _TutorInputFieldState extends State<TutorInputField> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      widget.onSubmitted(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.isLoading ? null : _submit,
            icon: widget.isLoading 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Icon(Icons.send_rounded),
            color: AppColors.primary,
            disabledColor: Colors.grey,
            style: IconButton.styleFrom(
              backgroundColor: widget.isLoading ? Colors.transparent : AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
