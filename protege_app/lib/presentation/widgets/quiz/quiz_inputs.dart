import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class FillBlankInput extends StatefulWidget {
  final String? initialValue;
  final Function(String)? onChanged;

  const FillBlankInput({
    super.key,
    this.initialValue,
    this.onChanged,
  });

  @override
  State<FillBlankInput> createState() => _FillBlankInputState();
}

class _FillBlankInputState extends State<FillBlankInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(FillBlankInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text) {
          // Only update if external change (e.g. navigation)
         _controller.text = widget.initialValue ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Type your answer:",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          enabled: widget.onChanged != null,
          decoration: InputDecoration(
            hintText: "Enter answer...",
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class CodeCompletionInput extends StatefulWidget {
  final String template;
  final String? initialValue;
  final Function(String)? onChanged;

  const CodeCompletionInput({
    super.key,
    required this.template,
    this.initialValue,
    this.onChanged,
  });

  @override
  State<CodeCompletionInput> createState() => _CodeCompletionInputState();
}

class _CodeCompletionInputState extends State<CodeCompletionInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }
  
  @override
  void didUpdateWidget(CodeCompletionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
     if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text) {
         _controller.text = widget.initialValue ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF282C34), // Dark code background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Code Challenge",
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.template,
                style: const TextStyle(
                  fontFamily: 'Courier New', // Monospace
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text(
                "Missing part:",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                enabled: widget.onChanged != null,
                style: const TextStyle(
                  fontFamily: 'Courier New',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Type code here...",
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
