import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final Curve curve;

  const AnimatedCounter({
    Key? key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.curve = Curves.easeOut,
  }) : super(key: key);

  @override
  _AnimatedCounterState createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _counter;
  late int _targetValue;

  @override
  void initState() {
    super.initState();
    _targetValue = widget.value;
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _counter = IntTween(
      begin: 0,
      end: _targetValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start the animation when the widget is first built
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _targetValue) {
      _targetValue = widget.value;
      _counter = IntTween(
        begin: _counter.value,
        end: _targetValue,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      
      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _counter,
      builder: (context, child) {
        return Text(
          _counter.value.toString(),
          style: widget.style,
        );
      },
    );
  }
}
