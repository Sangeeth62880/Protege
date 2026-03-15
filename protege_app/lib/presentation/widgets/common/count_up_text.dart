import 'package:flutter/material.dart';

/// Animated number that counts up from [begin] to [end]
class CountUpText extends StatelessWidget {
  final int begin;
  final int end;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  const CountUpText({
    super.key,
    this.begin = 0,
    required this.end,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: begin, end: end),
      duration: duration,
      builder: (context, value, child) {
        return Text(
          '$prefix$value$suffix',
          style: style,
        );
      },
    );
  }
}
