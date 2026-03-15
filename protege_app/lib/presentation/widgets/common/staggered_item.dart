import 'package:flutter/material.dart';
import '../../../core/constants/app_design.dart';

/// Staggered fade+slide animation for list items
class StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Skip animation for items beyond index 12
    if (widget.index >= 12) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration.zero,
      )..value = 1.0;
      _fadeAnimation = const AlwaysStoppedAnimation(1.0);
      _slideAnimation = const AlwaysStoppedAnimation(Offset.zero);
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveDecelerate,
    ));

    Future.delayed(
      Duration(milliseconds: widget.index * AppMotion.staggerDelay.inMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
