import 'package:flutter/material.dart';

/// Reusable background widget that shows the campus image behind content.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.opacity = 0.85});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/LBS IMAGE.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.68),
                Colors.white.withOpacity(
                  0.96 + (1 - opacity.clamp(0.0, 1.0)) * 0.03,
                ),
                const Color(0xFFF4F0E8).withOpacity(1.0),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
