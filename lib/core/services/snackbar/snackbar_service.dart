// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

class SnackbarService {
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showSuccess(String message) {
    _showSnackbar(message, Icons.check);
  }

  void showError(String message) {
    _showSnackbar(message, Icons.close);
  }

  void showInfo(String message) {
    _showSnackbar(message, Icons.info);
  }

  void _showSnackbar(String message, IconData icon) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 2),

        // Animate manually (no SnackBar.of(...) required)
        content: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: const Offset(0, 0.3), end: Offset.zero),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, offset, child) {
            // offset.dy will go from 0.3 -> 0.0
            return Transform.translate(
              offset: Offset(0, offset.dy * 40), // vertical slide
              child: Opacity(
                opacity: 1 - (offset.dy / 0.3), // fade in
                child: child,
              ),
            );
          },
          child: _GlassSnackbar(
            message: message,
            icon: icon,

            onClose: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      ),
    );
  }
}

class _GlassSnackbar extends StatelessWidget {
  final String message;
  final IconData icon;

  final VoidCallback onClose;

  const _GlassSnackbar({
    required this.message,
    required this.icon,

    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6), // transparent frost
            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1.5,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 25,
                offset: Offset(0, 8),
              ),
            ],
          ),

          child: Row(
            children: [
              // Sharp colored icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.4),
                      Colors.white.withValues(alpha: 0.5),
                    ],
                  ), // Semi-transparent color
                  borderRadius: BorderRadius.circular(16.0),

                  // White glass border
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.5),
                    width: 1,
                  ),

                  // 🔥 Added Black Highlight Shadow
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2), // soft black
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.6),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Icon(Icons.close, color: AppTheme.primary, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
