import 'package:flutter/material.dart';

class CollegeBanner extends StatefulWidget {
  const CollegeBanner({super.key});

  @override
  State<CollegeBanner> createState() => _CollegeBannerState();
}

class _CollegeBannerState extends State<CollegeBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Slower duration so the banner text moves more gently
      duration: const Duration(seconds: 25),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Move the row by up to 3 * full width so that
              // the repeated segments always cover the entire base.
              final progress = _controller.value; // 0..1
              final offsetX = -3 * width * progress;
              return ClipRect(
                child: Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: child,
                ),
              );
            },
            child: OverflowBox(
              // Allow the row to be wider than the viewport without
              // triggering the yellow/black overflow indicator.
              minWidth: width,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  // Use 3 repeated segments so that as we scroll left
                  // there is always another segment filling the viewport
                  // with no gaps.
                  for (int i = 0; i < 3; i++)
                    SizedBox(
                      width: width,
                      child: _buildSegment(context, colorScheme),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSegment(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black,
      child: Text(
        'LBS COLLEGE OF ENGINEERING KASARAGOD',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
