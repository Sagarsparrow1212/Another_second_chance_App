// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:homelyhope/features/common/auth/data/auth_remote_datasource.dart';
import 'package:homelyhope/features/common/auth/data/auth_repository_impl.dart';
import 'package:homelyhope/features/common/auth/data/login_usecase.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/common/auth/presentation/notifiers/auth_notifier.dart';
import 'package:homelyhope/features/common/Drawer/providers/drawer_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

// // --- Providers ---
final dioProvider = Provider((ref) => Dio());
final remoteProvider = Provider(
  (ref) => AuthRemoteDatasource(ref.watch(dioProvider)),
);
final repoProvider = Provider(
  (ref) => AuthRepositoryImpl(ref.watch(remoteProvider)),
);
final usecaseProvider = Provider(
  (ref) => LoginUseCase(ref.watch(repoProvider)),
);
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<Map<String, dynamic>?>>(
      (ref) => AuthNotifier(ref.watch(usecaseProvider)),
    );

// ✅ Shared constants for login page (accessible to all widgets)
class _LoginPageConstants {
  static const gradientColor1 = Color(0xFF3ebaaf);
  static const gradientColor2 = Color(0xFF1e3f7c);
  static const whiteColor = Color(0xFFFFFFFF);
  static const semiTransparentBlue = Color(0x661e3f7c); // 40% opacity

  static final backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.15],
    colors: const [gradientColor1, gradientColor2],
  );

  static final buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0.5, 0.8],
    colors: const [gradientColor2, gradientColor1],
  );

  static final emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  static final userNameRegex = RegExp(
    r'^(?![0-9]+$)(?!.*\.\.)(?!\.)(?!.*\.$)[a-zA-Z0-9._]{3,30}$',
  );
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _hasNavigated = false;
  bool _listenerRegistered = false;
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;

  @override
  void initState() {
    super.initState();
    // Reset navigation flag when page is initialized
    _hasNavigated = false;
    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();

    // ✅ Prevent auto-focus when page is initialized
    // Unfocus any existing focus to prevent auto-focus on return
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        emailFocusNode.unfocus();
        passwordFocusNode.unfocus();
        // Also unfocus any other focus in the widget tree
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    // ✅ Unfocus nodes before disposing to prevent focus issues
    // Only unfocus if widget is still mounted (safe to access context)
    if (mounted) {
      emailFocusNode.unfocus();
      passwordFocusNode.unfocus();
      // Use FocusManager instead of FocusScope.of(context) to avoid ancestor lookup
      FocusManager.instance.primaryFocus?.unfocus();
    }
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    emailController.dispose();
    passwordController.dispose();

    _listenerRegistered = false;
    _hasNavigated = false;
    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   FocusScope.of(context).unfocus();
  // }

  Future<void> _handleLoginSuccess() async {
    if (_hasNavigated || !mounted) {
      return;
    }

    _hasNavigated = true; // Set early to prevent duplicate calls

    try {
      // Reset drawer state to ensure fresh role fetch for new user
      ref.read(drawerNotifierProvider.notifier).reset();

      final isLoggedIn = await AuthStorageService.isLoggedIn();
      final isVerified = await AuthStorageService.isVerified();
      final userRole = await AuthStorageService.getUserRole();

      if (!mounted) {
        return;
      }

      if (!isLoggedIn) {
        _hasNavigated = false; // Reset to allow retry
        return;
      }

      // Only organization role needs verification
      if (userRole == 'organization' && !isVerified) {
        context.go('/organization/verification');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your email to continue'),
            ),
          );
        }
      } else {
        // Navigate to appropriate dashboard based on role
        String targetRoute;
        if (userRole == 'organization' && isVerified) {
          targetRoute = '/organization/dashboard';
        } else if (userRole == 'merchant') {
          targetRoute = '/merchant/dashboard';
        } else if (userRole == 'homeless') {
          targetRoute = '/homeless/dashboard';
        } else if (userRole == 'donor') {
          targetRoute = '/donor/dashboard';
        } else {
          _hasNavigated = false; // Reset to allow retry
          return;
        }

        context.go(targetRoute);
      }
    } catch (e) {
      _hasNavigated = false; // Reset to allow retry on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final authState = ref.watch(authNotifierProvider);

    // ✅ Register listener only once to avoid multiple registrations
    if (!_listenerRegistered) {
      _listenerRegistered = true;
      ref.listen<AsyncValue<Map<String, dynamic>?>>(authNotifierProvider, (
        previous,
        next,
      ) {
        // Check if login succeeded
        final hasData = next.hasValue && next.value != null;
        final hasError = next.hasError;
        final wasLoading = previous?.isLoading ?? false;
        final wasInitial = previous == null;
        final hadError = previous?.hasError ?? false;

        if (previous != null) {
          print(
            '  - previous: ${previous.isLoading
                ? "loading"
                : previous.hasError
                ? "error"
                : "data"}',
          );
        } else {}
        print(
          '  - next: ${next.isLoading
              ? "loading"
              : next.hasError
              ? "error"
              : next.hasValue
              ? "data"
              : "null"}',
        );
        print(
          '  - hasData: $hasData, wasLoading: $wasLoading, wasInitial: $wasInitial, _hasNavigated: $_hasNavigated',
        );

        // Show snackbar for login success
        if (hasData &&
            (wasLoading || wasInitial || hadError) &&
            !_hasNavigated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          _handleLoginSuccess();
        }

        // Show snackbar for login error
        if (hasError && wasLoading && !_hasNavigated) {
          final errorMessage =
              next.error?.toString() ?? 'Login failed. Please try again.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    }

    // ✅ Also check current state in case login already succeeded
    // This handles the case where login completes before listener is registered
    if (authState.hasValue &&
        authState.value != null &&
        !_hasNavigated &&
        !authState.isLoading &&
        !authState.hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasNavigated) {
          _handleLoginSuccess();
        }
      });
    }

    return Scaffold(
      backgroundColor: _LoginPageConstants.whiteColor,
      body: GestureDetector(
        // ✅ Unfocus when tapping outside text fields
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              // ✅ Static background - never rebuilds
              _LoginBackground(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              // ✅ Static middle card - never rebuilds
              _LoginMiddleCard(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              // ✅ Only form rebuilds when TextField focus changes
              _LoginFormCard(
                emailFocusNode: emailFocusNode,
                passwordFocusNode: passwordFocusNode,
                emailController: emailController,
                passwordController: passwordController,
                formKey: _formKey,
                onLogin: () async {
                  print('Login button pressed');
                  if (_formKey.currentState!.validate()) {
                    // Call login and wait for response
                    final isInternetAvailable = await isCheckInternetAvilable();
                    if (!isInternetAvailable) {
                      ref
                          .read(snackbarServiceProvider)
                          .showError('No internet connection');
                      return;
                    }

                    try {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .login(
                            emailController.text.trim(),
                            passwordController.text.trim(),
                          );

                      // Access the response and data
                      final authState = ref.read(authNotifierProvider);

                      // Handle the response
                      authState.when(
                        data: (responseData) {
                          if (responseData != null) {
                            if (responseData['data'] != null) {
                              ref
                                  .read(snackbarServiceProvider)
                                  .showSuccess(responseData['message']);
                            }
                          } else {
                            ref
                                .read(snackbarServiceProvider)
                                .showSuccess(responseData!['message']);
                          }
                        },
                        loading: () {},
                        error: (error, stackTrace) {
                          final rawMessage = error.toString().trim();
                          final errorMessage = rawMessage
                              .replaceFirst('Exception: ', '')
                              .trim();

                          ref
                              .read(snackbarServiceProvider)
                              .showError(errorMessage);
                        },
                      );
                    } catch (error) {
                      final rawMessage = error.toString().trim();
                      final errorMessage = rawMessage
                          .replaceFirst('Exception: ', '')
                          .trim();

                      ref.read(snackbarServiceProvider).showError(errorMessage);
                    }
                  } else {
                    ref
                        .read(snackbarServiceProvider)
                        .showInfo('Please fill in required fields');
                  }
                },
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildDonHaveAccount(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          'Don\'t have an account? ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/role-selection'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              color: _LoginPageConstants.semiTransparentBlue,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ✅ Separate widget for background - const prevents rebuilds
class _LoginBackground extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _LoginBackground({
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final titleSpacing = screenHeight * 0.045;

    return Container(
      height: screenHeight,
      width: screenWidth,
      decoration: BoxDecoration(
        gradient: _LoginPageConstants.backgroundGradient,
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          buildDonHaveAccount(context),
          SizedBox(height: titleSpacing),
          const Text(
            'HomelyHope',
            style: TextStyle(
              fontSize: 32,
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Separate widget for middle card - const prevents rebuilds
class _LoginMiddleCard extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _LoginMiddleCard({
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = screenWidth * 0.07;
    final topMargin = screenHeight * 0.275;
    final containerHeight = screenHeight * 0.73;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _LoginPageConstants.gradientColor1.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        margin: EdgeInsets.only(top: topMargin),
        height: containerHeight,
        width: screenWidth,
      ),
    );
  }
}

// ✅ Separate widget for form - only this rebuilds on TextField focus
// Uses ValueNotifier to manage password visibility locally without setState
class _LoginFormCard extends ConsumerStatefulWidget {
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;
  final double screenHeight;
  final double screenWidth;

  const _LoginFormCard({
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onLogin,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  ConsumerState<_LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends ConsumerState<_LoginFormCard> {
  // ✅ ValueNotifier created once in initState, disposed in dispose
  // This avoids setState completely
  late final ValueNotifier<bool> _isPasswordShowNotifier;

  @override
  void initState() {
    super.initState();
    _isPasswordShowNotifier = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _isPasswordShowNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomContainerHeight = widget.screenHeight * 0.70;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: bottomContainerHeight,
        width: widget.screenWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                'Welcome Back!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Login to your account',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                focusNode: widget.emailFocusNode,
                controller: widget.emailController,
                autofocus: false,

                decoration: InputDecoration(
                  labelText: 'Email or Username',
                  hintText: 'Enter email or username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                validator: (value) {
                  final input = value?.trim() ?? "";

                  if (input.isEmpty) {
                    return 'Email or username should not be empty';
                  }

                  // Use static regex patterns
                  if (_LoginPageConstants.emailRegex.hasMatch(input)) {
                    return null;
                  }

                  if (_LoginPageConstants.userNameRegex.hasMatch(input)) {
                    return null;
                  }

                  return 'Enter a valid email or username';
                },
              ),
              const SizedBox(height: 12),
              // ✅ Use ValueListenableBuilder to listen to password visibility changes
              // This avoids setState completely
              ValueListenableBuilder<bool>(
                valueListenable: _isPasswordShowNotifier,
                builder: (context, isPasswordShow, _) {
                  return TextFormField(
                    focusNode: widget.passwordFocusNode,
                    controller: widget.passwordController,
                    autofocus: false, // ✅ Explicitly disable auto-focus
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        onPressed: () {
                          // ✅ Update ValueNotifier - no setState needed
                          _isPasswordShowNotifier.value =
                              !_isPasswordShowNotifier.value;
                        },
                        icon: isPasswordShow
                            ? Icon(Icons.remove_red_eye)
                            : Icon(Icons.visibility_off),
                      ),
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password should not be empty';
                      } else if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                    obscureText: isPasswordShow,
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.push('/forgotPassword'),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),

              InkWell(
                onTap: widget.onLogin,
                child: Container(
                  width: double.infinity,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient: _LoginPageConstants.buttonGradient,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.push('/role-selection'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
