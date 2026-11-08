import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.online, this.size = 10});

  final bool online;
  final double size;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.online
        ? AppColors.green
        : Theme.of(context).colorScheme.outline;

    if (!widget.online) {
      return SizedBox(
        width: widget.size * 2.2,
        height: widget.size * 2.2,
        child: Center(
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final expanded = 0.55 + _controller.value * 0.45;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.size * 2.2 * expanded,
                  height: widget.size * 2.2 * expanded,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18 * (1 - _controller.value)),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
