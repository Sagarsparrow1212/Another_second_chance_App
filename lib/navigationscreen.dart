import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/attadnace.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/homepage.dart';
import 'package:homelyhope/leaves.dart';
import 'package:homelyhope/profilescreen.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Tab Item Model
class TabItem {
  final IconData icon;
  final String label;

  TabItem(this.icon, this.label);
}

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const LeavesPage(),
    const AttendancePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        // color: Color(0xff030712),
        child: IosStyleBottomNav(
          currentIndex: _currentIndex,
          onChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

// iOS-Style Animated Bottom Navigation Bar
class IosStyleBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const IosStyleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  State<IosStyleBottomNav> createState() => _IosStyleBottomNavState();
}

class _IosStyleBottomNavState extends State<IosStyleBottomNav>
    with SingleTickerProviderStateMixin {
  final tabs = [
    TabItem(CupertinoIcons.home, 'Home'),
    TabItem(LucideIcons.treePalm, 'Leaves'),
    TabItem(CupertinoIcons.calendar, 'Attendance'),
    TabItem(LineAwesomeIcons.user, 'Profile'),
  ];

  late AnimationController _controller;
  double dragPosition = 0.0; // 0 → tabs.length-1
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    dragPosition = widget.currentIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: tabs.length - 1,
    );
    _controller.value = dragPosition;
    _controller.addListener(_updatePosition);
  }

  @override
  void didUpdateWidget(IosStyleBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      final newIndex = widget.currentIndex.toDouble();
      dragPosition = newIndex;
      _controller.value = newIndex;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void animateTo(double target) {
    final endPosition = target.clamp(0.0, (tabs.length - 1).toDouble());
    final targetIndex = endPosition.toInt();

    // Update visual position immediately
    setState(() {
      dragPosition = endPosition;
    });

    // Call onChanged to update the page - this must happen
    widget.onChanged(targetIndex);

    if (_isDragging) {
      // If dragging, just update controller value
      _controller.value = endPosition;
      return;
    }

    // Animate with spring
    final startPosition = _controller.value;
    _controller.value = startPosition;
    final simulation = SpringSimulation(
      const SpringDescription(mass: 0.8, stiffness: 180, damping: 20),
      startPosition,
      endPosition,
      0,
    );

    _controller.animateWith(simulation);
  }

  void _updatePosition() {
    if (mounted && !_isDragging) {
      setState(() {
        dragPosition = _controller.value;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -1),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  _isDragging = true;
                  _controller.stop();
                  HapticFeedback.lightImpact();
                },
                onHorizontalDragUpdate: (details) {
                  // Only update the pill position during drag, icons stay static
                  setState(() {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final itemWidth = (screenWidth - 32) / tabs.length;
                    dragPosition += details.delta.dx / itemWidth;
                    dragPosition = dragPosition.clamp(0, tabs.length - 1);
                    // Update controller value for pill animation only
                    _controller.value = dragPosition;
                  });
                },
                onHorizontalDragEnd: (details) {
                  _isDragging = false;
                  HapticFeedback.mediumImpact();
                  final target = dragPosition.roundToDouble().clamp(
                    0.0,
                    (tabs.length - 1).toDouble(),
                  );
                  final targetIndex = target.toInt();

                  // Update page first
                  widget.onChanged(targetIndex);

                  // Then snap pill to target position with animation
                  setState(() {
                    dragPosition = target;
                  });

                  _controller.value = dragPosition;
                  final simulation = SpringSimulation(
                    const SpringDescription(
                      mass: 0.8,
                      stiffness: 180,
                      damping: 20,
                    ),
                    dragPosition,
                    target,
                    0,
                  );
                  _controller.animateWith(simulation);
                },
                child: _buildBar(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar() {
    // Icons always use currentIndex (static during drag), only pill moves
    // Pill uses dragPosition during drag, currentIndex when idle
    final pillPosition = _isDragging
        ? dragPosition
        : widget.currentIndex.toDouble();

    return LayoutBuilder(
      builder: (context, constraints) {
        const pillWidth = 75.0;
        const pillHalfWidth = pillWidth / 2;
        final tabWidth = constraints.maxWidth / tabs.length;
        final pillLeft =
            (pillPosition * tabWidth) + (tabWidth / 2) - pillHalfWidth;
        final clampedLeft = pillLeft.clamp(
          0.0,
          constraints.maxWidth - pillWidth,
        );

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              left: clampedLeft,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: pillWidth,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                // Icons use currentIndex, not dragPosition
                final selected = widget.currentIndex == i;
                final opacity = selected ? 1.0 : 0.4;
                final scale = selected ? 1.2 : 1.0;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_isDragging && widget.currentIndex != i) {
                        HapticFeedback.selectionClick();
                        animateTo(i.toDouble());
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: scale,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Icon(
                            tabs[i].icon,
                            color: selected
                                ? AppTheme.primary
                                : Colors.grey[600],
                            size: 21,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedOpacity(
                          opacity: opacity,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            tabs[i].label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
