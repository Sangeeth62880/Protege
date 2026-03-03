import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

/// Notes tab with per-lesson Firestore persistence and auto-save.
class NotesTab extends StatefulWidget {
  final String pathId;
  final int moduleId;
  final int lessonId;

  const NotesTab({
    super.key,
    required this.pathId,
    required this.moduleId,
    required this.lessonId,
  });

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final TextEditingController _notesController = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSaved = false;
  String? _lastSavedText;

  String get _docPath =>
      'learning_paths/${widget.pathId}/notes/${widget.moduleId}_${widget.lessonId}';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _notesController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .doc(_docPath)
          .get();

      if (doc.exists && doc.data() != null) {
        final text = doc.data()!['content'] as String? ?? '';
        _notesController.text = text;
        _lastSavedText = text;
      }
    } catch (e) {
      debugPrint('Failed to load notes: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTextChanged() {
    // Don't auto-save while loading
    if (_isLoading) return;

    // Cancel previous debounce
    _debounceTimer?.cancel();

    // Reset saved indicator
    if (_hasSaved) {
      setState(() => _hasSaved = false);
    }

    // Debounce: save after 2 seconds of inactivity
    _debounceTimer = Timer(const Duration(seconds: 2), _saveNotes);
  }

  Future<void> _saveNotes() async {
    final text = _notesController.text;
    if (text == _lastSavedText) return; // No changes

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.doc(_docPath).set({
        'content': text,
        'updated_at': FieldValue.serverTimestamp(),
        'module_id': widget.moduleId,
        'lesson_id': widget.lessonId,
      }, SetOptions(merge: true));

      _lastSavedText = text;
      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasSaved = true;
        });
      }

      // Reset "Saved" indicator after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _hasSaved = false);
      });
    } catch (e) {
      debugPrint('Failed to save notes: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save notes: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with save status
          Row(
            children: [
              Text(
                'My Notes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (_isSaving)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else if (_hasSaved)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Notes auto-save as you type.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                decoration: InputDecoration(
                  hintText: 'Start typing your notes...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
