import 'package:flutter/material.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

/// Optimized PNG logo loader with performance improvements:
/// - RepaintBoundary to prevent unnecessary repaints
/// - CurvedAnimation for smoother animation
/// - Proper disposal of animation controller
///
/// ⚠️ Performance Note: Use ONE instance per screen for best performance.
/// Avoid using multiple instances in ListView/GridView items.
class PngLogoLoader extends StatefulWidget {
  const PngLogoLoader({super.key});

  @override
  State<PngLogoLoader> createState() => _PngLogoLoaderState();
}

class _PngLogoLoaderState extends State<PngLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Use CurvedAnimation for smoother, more efficient animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary prevents unnecessary repaints of parent widgets
    return RepaintBoundary(
      child: Container(
        // color: Colors.red,
        width: 120,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// Logo outline (optional)
            Image.asset(
              width: 80,
              height: 80,
              'assets/logo/homelyhope.png',
              color: Colors.grey.shade300,
            ),

            /// Animated fill inside PNG - Liquid fill from bottom to top (unfilled to filled)
            AnimatedBuilder(
              animation: _animation,
              builder: (_, __) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    // Fill height: 0.0 = unfilled (empty), 1.0 = filled (full)
                    final fillHeight = _animation.value.clamp(0.0, 1.0);
                    // Calculate stops: ensure they're always in ascending order for three-color gradient
                    // When fillHeight is 0.0, use a tiny value to ensure stops are distinct
                    const minStop = 0.001;
                    final topStop = fillHeight > minStop ? fillHeight : minStop;
                    // Middle stop should be between 0.0 and topStop
                    final middleStop = fillHeight > minStop
                        ? fillHeight * 0.7
                        : minStop * 0.5;
                    return LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppTheme.primary, // Colored (filled) at bottom
                        AppTheme.primary.withOpacity(0.8),
                        AppTheme.primary.withOpacity(
                          0,
                        ), // Transparent (unfilled) at top
                      ],
                      stops: [
                        0.0, // Always start colored at bottom
                        middleStop, // Middle transition point
                        topStop, // Transition point: starts near bottom, moves to top as fillHeight increases
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Image.asset(
                    'assets/logo/homelyhope.png',
                    width: 80,
                    height: 80,
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centralized loader widget for consistent usage across the app.
///
/// ✅ Best Practice: Use this widget instead of creating PngLogoLoader directly.
/// This ensures consistent styling and makes it easier to update the loader globally.
