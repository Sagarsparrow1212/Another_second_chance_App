import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

import 'package:lucide_icons_flutter/test_icons.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/common/notifications/presentation/manager/notification_provider.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,

    this.centerTitle = true,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: LiquidGlassContainer(
        radius: 16,
        height: 54,
        child: Row(
          children: [
            // Leading icon (drawer)
            if (!showBackButton)
              Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: LiquidGlassContainer(
                    radius: 14,
                    height: 50,
                    child: IconButton(
                      onPressed: () {
                        // print("Drawer");
                        Scaffold.of(context).openDrawer();
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.barsStaggered,
                        size: 18,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              )
            else
              Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: LiquidGlassContainer(
                    radius: 50,
                    height: 50,
                    child: IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: FaIcon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),

            // Title
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),

                child: Text(
                  title,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // Actions or spacer
            if (actions != null && actions!.isNotEmpty) ...[
              ...actions!,
              GestureDetector(
                onTap: () {
                  context.push('/notifications');
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.bell,
                        size: 18,
                        color: AppTheme.primary.withValues(alpha: 0.85),
                      ),
                      ref
                          .watch(notificationProvider)
                          .maybeWhen(
                            data: (notifications) {
                              final unreadCount = notifications
                                  .where((n) => !n.isRead)
                                  .length;
                              if (unreadCount > 0) {
                                return Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 8,
                                      minHeight: 8,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4),

              const SizedBox(width: 8),
            ] else if (title != "Notifications") ...[
              Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: IconButton(
                    onPressed: () {
                      context.push('/notifications');
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.bell,
                      size: 18,
                      color: AppTheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}

/// iOS 26 Liquid Glass Container with water drop effect
/// Now with dynamic radius and height
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? height;
  final double blurX;
  final double blurY;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.radius = 16,
    this.height,
    this.blurX = 3,
    this.blurY = 1,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.3),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(radius),
            // Multi-layer glass effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.25),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            // Outer glow shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              // Inner shine gradient (top highlight)
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(width: 1.5, color: Colors.transparent),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                // Liquid glass rim light
                border: GradientBorder.uniform(
                  width: 1.2,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  radius: radius,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom gradient border for liquid glass effect
class GradientBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  final double radius;

  const GradientBorder._({
    required this.gradient,
    required this.width,
    required this.radius,
  });

  factory GradientBorder.uniform({
    required Gradient gradient,
    double width = 1.0,
    double radius = 16,
  }) {
    return GradientBorder._(gradient: gradient, width: width, radius: radius);
  }

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    final rrect =
        borderRadius?.toRRect(rect) ??
        RRect.fromRectAndRadius(rect, Radius.circular(radius));

    canvas.drawRRect(rrect.deflate(width / 2), paint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
