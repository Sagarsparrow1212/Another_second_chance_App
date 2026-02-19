import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:homelyhope/features/common/Drawer/providers/drawer_provider.dart';
import 'package:homelyhope/features/common/auth/presentation/login_page.dart';

void showLogoutPopup(BuildContext context) {
  showDialog(
    context: context,

    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            buttonPadding: EdgeInsets.all(0),
            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            backgroundColor: Colors.white,

            content: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: Image.asset(
                    'assets/logout.png',
                    height: 170,
                    width: 170,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        'Confirm Logout',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 21,
                        ),
                      ),
                      SizedBox(height: 8),
                      const Text(
                        textAlign: TextAlign.center,
                        'Are you sure you want to logout? You will need to sign in again to access your account.',
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        foregroundColor: MaterialStateProperty.all(
                          Colors.grey.shade700,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () {
                        context.pop(); // close dialog
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Builder(
                      builder: (ctx) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final router = GoRouter.of(ctx);

                          // 🔐 SAFELY read providers without widget lifecycle risk
                          final container = ProviderScope.containerOf(
                            ctx,
                            listen: false,
                          );
                          final drawerNotifier = container.read(
                            drawerNotifierProvider.notifier,
                          );
                          final snackbar = container.read(
                            snackbarServiceProvider,
                          );

                          final authNotifier = container.read(
                            authNotifierProvider.notifier,
                          );

                          ctx.pop(); // close dialog

                          drawerNotifier.reset();

                          // Call logout API and clear data
                          await authNotifier.logout();

                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );

                          router.go('/login');

                          snackbar.showSuccess('Logged out successfully');
                        },

                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}
