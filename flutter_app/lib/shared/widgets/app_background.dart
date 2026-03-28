import 'package:flutter/material.dart';
import 'dart:async';

/// Reusable background widget that shows the campus image behind content.
class AppBackground extends StatefulWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.opacity = 0.15,
    // this.slideDuration = const Duration(seconds: 4),
    // this.fadeDuration = const Duration(milliseconds: 800),
  });

  final Widget child;
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

}
