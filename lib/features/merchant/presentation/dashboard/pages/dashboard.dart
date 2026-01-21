import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<int, AnimationController> _charControllers = {};
  final Map<int, Animation<Offset>> _charAnimations = {};

  String displayedText = "";
  int _previousTextLength = 0;

  @override
  void initState() {
    super.initState();

    // Auto show keyboard
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    _textController.addListener(() {
      setState(() {
        final newText = _textController.text;
        final newLength = newText.length;

        // Animate new characters
        if (newLength > _previousTextLength) {
          // New characters added
          for (int i = _previousTextLength; i < newLength; i++) {
            _createCharAnimation(i, _previousTextLength);
          }
        } else if (newLength < _previousTextLength) {
          // Characters removed - dispose unused controllers
          for (int i = newLength; i < _previousTextLength; i++) {
            _charControllers[i]?.dispose();
            _charControllers.remove(i);
            _charAnimations.remove(i);
          }
        }

        displayedText = newText;
        _previousTextLength = newLength;
      });
    });
  }

  void _createCharAnimation(int index, int startIndex) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final animation = Tween<Offset>(
      begin: const Offset(0, 1), // Start below
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    _charControllers[index] = controller;
    _charAnimations[index] = animation;

    // Animate immediately with a small stagger for visual effect
    // Stagger based on position relative to the start of new characters
    final staggerDelay = (index - startIndex) * 30;
    Future.delayed(Duration(milliseconds: staggerDelay), () {
      if (mounted && _charControllers.containsKey(index)) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    // Dispose all character controllers
    for (var controller in _charControllers.values) {
      controller.dispose();
    }
    _charControllers.clear();
    _charAnimations.clear();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,

      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Dashboard'),
      body: Padding(
        padding: EdgeInsets.only(
          top: topPadding + 75,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: displayedText.isEmpty
                  ? const Text(
                      "Start typing...",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: displayedText.split('').asMap().entries.map((
                        entry,
                      ) {
                        final index = entry.key;
                        final char = entry.value;
                        final animation = _charAnimations[index];

                        if (animation == null) {
                          // Fallback if animation not ready yet
                          return Text(
                            char,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          );
                        }

                        return SlideTransition(
                          position: animation,
                          child: Text(
                            char,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              // style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type here...",
                // hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                // fillColor: Colors.grey.shade900,
                // border: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(12),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
