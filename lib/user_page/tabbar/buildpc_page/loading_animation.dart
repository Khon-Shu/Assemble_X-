// loading_animation.dart
import 'package:flutter/material.dart';

class RadialProgressAnimation extends StatefulWidget {
  final double progress;
  final Color color;

  const RadialProgressAnimation({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  State<RadialProgressAnimation> createState() => _RadialProgressAnimationState();
}

class _RadialProgressAnimationState extends State<RadialProgressAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _startAnimation();
  }

  @override
  void didUpdateWidget(RadialProgressAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80, // Reduced size for the grid
              height: 80,
              child: CircularProgressIndicator(
                value: _animation.value,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade300,
                color: widget.color,
              ),
            ),
            Text(
              '${(_animation.value * 100).round()}%',
              style: const TextStyle(
                fontSize: 16, // Smaller font for grid
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}