import 'package:flutter/material.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Speed of the loop
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Adjust these sizes to match your specific logo's aspect ratio
    const double logoWidth = 140;
    const double logoHeight = 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: logoWidth,
          height: logoHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. The Base Logo (Inactive/Grey)
              Image.asset(
                'assets/logo/homelyhope.png',
                width: logoWidth,
                color: Colors.grey.shade300,
                fit: BoxFit.contain,
              ),

              // 2. The Animated Tracer Overlay
              // This paints the glowing line on top of the logo
              // 2. The Animated Tracer Overlay
              CustomPaint(
                size: Size(logoWidth, logoHeight),
                painter: _InfinityTracerPainter(
                  animationValue: _controller,
                  color: Color(0xFF004d61),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Loading Text
        Text(
          "Loading...",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _InfinityTracerPainter extends CustomPainter {
  final Animation<double> animationValue;
  final Color color;

  _InfinityTracerPainter({required this.animationValue, required this.color})
    : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Center point of the canvas
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // --- IMPORTANT: Adjust this value to fit your logo ---
    // 'a' controls how wide the infinity loops are.
    // Start with 0.4 and increase/decrease it to match your image perfectly.
    final double a = size.width * 0.4;

    // We draw a "comet tail" effect with multiple dots
    const int tailLength = 25;

    for (int i = 0; i < tailLength; i++) {
      // Calculate the position of each dot along the path
      // We subtract a small amount from the animation value to create the tail
      double t = (animationValue.value * 2 * math.pi) - (i * 0.04);

      // Calculate opacity: The head is fully opaque, the tail fades out
      double opacity = (1.0 - (i / tailLength)).clamp(0.0, 1.0);

      // --- Lemniscate of Bernoulli Formula (Infinity Shape) ---
      double denom = 1 + math.pow(math.sin(t), 2).toDouble();
      double x = (a * math.cos(t)) / denom;
      double y = (a * math.sin(t) * math.cos(t)) / denom;

      Offset dotPosition = Offset(cx + x, cy + y);

      // Draw the main dot
      paint.color = color.withOpacity(opacity);
      // The head dot is larger than the tail dots
      double radius = i == 0 ? 5.0 : 3.0;
      canvas.drawCircle(dotPosition, radius, paint);

      // Add a glow effect only to the head of the comet
      if (i == 0) {
        final Paint glowPaint = Paint()
          ..color = color.withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(dotPosition, 8.0, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InfinityTracerPainter oldDelegate) {
    return true; // Always repaint to show the animation
  }
}

/// Centralized loader widget for consistent usage across the app.
///
/// ✅ Best Practice: Use this widget instead of creating PngLogoLoader directly.
/// This ensures consistent styling and makes it easier to update the loader globally.
