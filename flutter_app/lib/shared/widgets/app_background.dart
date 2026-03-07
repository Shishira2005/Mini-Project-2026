import 'package:flutter/material.dart';

/// Reusable background widget that shows the campus image behind content.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
  });

  /// Main page content to render on top of the background.
  final Widget child;

  /// How strongly the image should appear (0 = invisible, 1 = fully opaque).
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Positioned.fill(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Image.asset(
              'assets/LBS IMAGE.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Foreground content
        child,
      ],
    );
  }
}
