import 'package:flutter/material.dart';

/// Reusable background widget that shows the campus image behind content.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Image.asset(
            'assets/LBS IMAGE.jpg',
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}
