import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // Check authentication status
    final isLoggedIn = await AuthStorageService.isLoggedIn();
    final isVerified = await AuthStorageService.isVerified();
    final userRole = await AuthStorageService.getUserRole();

    if (!mounted) return;

    if (!isLoggedIn) {
      // Navigate to login if not logged in
      context.go('/login');
    } else {
      // Navigate to appropriate dashboard based on role
      if (userRole == 'organization') {
        if (!isVerified) {
          context.go('/organization/verification');
        } else {
          context.go('/organization/dashboard');
        }
      } else if (userRole == 'merchant') {
        context.go('/merchant/dashboard');
      } else if (userRole == 'homeless') {
        context.go('/homeless/dashboard');
      } else if (userRole == 'donor') {
        context.go('/donor/dashboard');
      } else {
        // Fallback to login if role is unknown
        context.go('/login');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    precacheImage(const AssetImage('assets/logo/homelyhope.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    if (MediaQuery.of(context).disableAnimations) {
      // print('Animations are disabled');
      return const Scaffold(body: _SplashCenterContent());
    }
    return Scaffold(
      body: Stack(
        children: [
          const ColoredBox(color: Colors.white),
          _AnimatedLightLine(top: size.height * 0.65, theme: theme),
          const _SplashCenterContent(),
        ],
      ),
    );
  }
}

class _AnimatedLightLine extends StatelessWidget {
  final double top;
  final ThemeData theme;

  const _AnimatedLightLine({required this.top, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: -200,
      child:
          Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 200,
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.0),
                        theme.primaryColor.withOpacity(0.4),
                        theme.primaryColor.withOpacity(0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              )
              .animate(delay: 1000.ms)
              .move(
                begin: const Offset(-200, 100),
                end: const Offset(800, -300),
                duration: 2000.ms,
                curve: Curves.linear,
              )
              .fadeIn(duration: 600.ms)
              .then(delay: 1500.ms)
              .fadeOut(duration: 400.ms),
    );
  }
}

class _SplashCenterContent extends StatelessWidget {
  const _SplashCenterContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo/homelyhope.png',
            height: 150,
            width: 150,
          ).animate().scale(duration: 500.ms),

          const SizedBox(height: 12),

          Text(
                'HomelyHope',
                style: theme.textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              )
              .animate(delay: 1000.ms)
              .slideY(
                begin: -0.5,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutQuint,
              )
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        ],
      ),
    );
  }
}
