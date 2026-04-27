import 'package:flutter/material.dart';

class PulsingAvatar extends StatefulWidget {
  final Widget child;
  final Color color;

  const PulsingAvatar(
      {super.key, required this.child, this.color = Colors.teal});

  @override
  State<PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse Circle 1
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 2.5).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: FadeTransition(
            opacity: Tween(begin: 0.4, end: 0.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        // Pulse Circle 2 (Delayed/Offset)
        // Note: For simplicity, single pulse for now to save resources,
        // but could add a second controller or staggered delay.

        // Main Avatar
        widget.child,
      ],
    );
  }
}
