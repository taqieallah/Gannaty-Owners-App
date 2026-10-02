import 'package:flutter/material.dart';

/// Pulsing placeholder rows shown while a screen loads. It tells the user the
/// layout is coming (and roughly what shape), which feels faster than a lone
/// spinner on a blank page.
class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 76});

  final int count;
  final double height;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_c),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.count; i++)
            Container(
              height: widget.height,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
        ],
      ),
    );
  }
}
