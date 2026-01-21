// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:homelyhope/features/common/auth/presentation/notifiers/forgot_password_state.dart';
import 'package:homelyhope/features/common/auth/presentation/provider/forgot_password_notifier.dart';
import 'package:pinput/pinput.dart';

// ✅ Shared constants for forgot password page (matching login page)
class _ForgotPasswordPageConstants {
  static const gradientColor1 = Color(0xFF3ebaaf);
  static const gradientColor2 = Color(0xFF1e3f7c);
  static const whiteColor = Color(0xFFFFFFFF);

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
}

final forgotPasswordProvider =
    NotifierProvider.autoDispose<ForgotPasswordNotifier, ForgotPasswordState>(
      ForgotPasswordNotifier.new,
    );

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode otpFocusNode = FocusNode();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showEmailPreview = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    if (mounted) {
      emailFocusNode.unfocus();
      FocusManager.instance.primaryFocus?.unfocus();
    }
    emailFocusNode.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _handleSendOTP() {
    final state = ref.read(forgotPasswordProvider);
    if (!_formKey.currentState!.validate()) {
      ref.read(snackbarServiceProvider).showInfo('Please enter a valid email');
      return;
    }
    if (!state.isShowOtpField) {
      ref
          .read(forgotPasswordProvider.notifier)
          .sendResetOtp(emailController.text.trim())
          .then((_) {
            otpFocusNode.requestFocus();
          });
    } else {
      // Verify OTP logic here
      final enteredOtp = otpController.text.trim();
      if (enteredOtp.length != 6) {
        ref.read(snackbarServiceProvider).showInfo('Please enter a valid OTP');
        return;
      }

      final isVerify = ref
          .read(forgotPasswordProvider.notifier)
          .verifyOtp(int.parse(enteredOtp));
      if (isVerify) {
        ref
            .read(snackbarServiceProvider)
            .showSuccess('OTP Verified Successfully');
      } else {
        ref.read(snackbarServiceProvider).showError('Invalid OTP');
      }
    }
  }

  void _handleResetPassword() {
    if (!_formKey.currentState!.validate()) {
      ref.read(snackbarServiceProvider).showInfo('Please enter a valid email');
      return;
    }

    final isReset = ref
        .read(forgotPasswordProvider.notifier)
        .resetPassword(
          email: emailController.text.trim(),
          newPassword: passwordController.text.trim(),
        );

    if (isReset) {
      ref
          .read(snackbarServiceProvider)
          .showSuccess('Password Reset Successfully');
      // context.pop();
    } else {
      ref.read(snackbarServiceProvider).showError('Password Reset Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (previous, next) {
      if (next.errorMessage != null) {
        ref.read(snackbarServiceProvider).showError(next.errorMessage!);
      }

      if (next.isSuccessOtpSended && previous?.isSuccessOtpSended == false) {
        ref
            .read(snackbarServiceProvider)
            .showSuccess('Password reset link has been sent to your email');
      }
    });

    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: _ForgotPasswordPageConstants.whiteColor,
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
              _ForgotPasswordBackground(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              // ✅ Static middle card - never rebuilds
              _ForgotPasswordMiddleCard(
                screenHeight: screenHeight,
                screenWidth: screenWidth,
              ),
              // ✅ Form card
              ForgotPasswordFormCard(
                passwordController: passwordController,
                passwordConfirmController: confirmPasswordController,
                otpController: otpController,
                emailFocusNode: emailFocusNode,
                emailController: emailController,
                formKey: _formKey,
                onResetPassword: _handleResetPassword,
                onSendOTPResetPassword: _handleSendOTP,

                otpFocusNode: otpFocusNode,
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

// ✅ Separate widget for background - const prevents rebuilds
class _ForgotPasswordBackground extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _ForgotPasswordBackground({
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
        gradient: _ForgotPasswordPageConstants.backgroundGradient,
      ),
      child: Column(
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
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
class _ForgotPasswordMiddleCard extends StatelessWidget {
  final double screenHeight;
  final double screenWidth;

  const _ForgotPasswordMiddleCard({
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
          color: _ForgotPasswordPageConstants.gradientColor1.withValues(
            alpha: 0.3,
          ),
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

class ForgotPasswordFormCard extends ConsumerStatefulWidget {
  final FocusNode emailFocusNode;
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSendOTPResetPassword;
  final VoidCallback onResetPassword;

  final TextEditingController otpController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;

  final FocusNode otpFocusNode;

  final double screenHeight;
  final double screenWidth;

  const ForgotPasswordFormCard({
    super.key,
    required this.emailFocusNode,
    required this.emailController,
    required this.otpController,
    required this.onSendOTPResetPassword,
    required this.formKey,
    required this.otpFocusNode,
    required this.onResetPassword,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.screenHeight,
    required this.screenWidth,
  });

  @override
  ConsumerState<ForgotPasswordFormCard> createState() =>
      _ForgotPasswordFormCardState();
}

class _ForgotPasswordFormCardState
    extends ConsumerState<ForgotPasswordFormCard> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordProvider);
    print('ForgotPasswordFormCard rebuild ${state.isShowOtpField}');
    final notifier = ref.read(forgotPasswordProvider.notifier);
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
              if (!state.isOtpVerified) ...[
                const SizedBox(height: 24),
                Text(
                  'Forgot Password?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your email to reset your password',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: state.showEmailPreview
                      ? GestureDetector(
                          onTap: () {
                            notifier.unlockEmail();
                          },
                          child: Container(
                            key: const ValueKey('email_container'),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  size: 18,
                                  Icons.email_outlined,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.emailController.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  size: 14,
                                  Icons.arrow_forward_ios_outlined,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        )
                      : TextFormField(
                          onChanged: (value) {
                            if (widget.formKey.currentState!.validate()) {
                              notifier.sendOtpFieldVisible();
                              widget.otpController.clear();

                              notifier.otpVerified(false);
                            }
                          },
                          key: const ValueKey('email_field'),
                          focusNode: widget.emailFocusNode,
                          controller: widget.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 6,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 20,
                            ),
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          validator: (value) {
                            final input = value?.trim() ?? '';

                            if (input.isEmpty) {
                              return 'Email should not be empty';
                            }

                            // Basic email format check
                            if (!_ForgotPasswordPageConstants.emailRegex
                                .hasMatch(input)) {
                              return 'Enter a valid email address';
                            }

                            // Blocked exact emails (fake/test)
                            final blockedEmails = {
                              // Generic test emails
                              'test@test.com',
                              'test@gmail.com',
                              'test@yahoo.com',
                              'test@outlook.com',

                              // Example placeholders
                              'example@example.com',
                              'example@gmail.com',
                              'example@yahoo.com',
                              'example@domain.com',

                              // Invalid / dummy patterns
                              'invalid@invalid.com',
                              'email@email.com',
                              'user@user.com',
                              'admin@admin.com',
                              'root@root.com',

                              // Common fake inputs
                              'abc@abc.com',
                              'xyz@xyz.com',
                              'demo@demo.com',
                              'sample@sample.com',

                              // Temporary-looking names
                              'temp@temp.com',
                              'fake@fake.com',
                              'noemail@noemail.com',
                            };

                            if (blockedEmails.contains(input.toLowerCase())) {
                              return 'Please use a real email address';
                            }

                            // Blocked disposable domains
                            final blockedDomains = {
                              'tempmail.com',
                              '10minutemail.com',
                              'disposablemail.com',
                            };

                            final domain = input.split('@').last.toLowerCase();

                            if (blockedDomains.contains(domain)) {
                              return 'Disposable email addresses are not allowed';
                            }

                            return null;
                          },

                          onFieldSubmitted: (_) => widget.onResetPassword(),
                        ),
                ),

                SizedBox(height: 16),
                state.isShowOtpField
                    ? Pinput(
                        animationCurve: Curves.easeInOutQuint,
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        animationDuration: const Duration(milliseconds: 300),
                        controller: widget.otpController,
                        focusNode: widget.otpFocusNode,
                        length: 6,

                        // onCompleted: (pin) {
                        //   Future.delayed(const Duration(milliseconds: 50), () {
                        //     widget.otpFocusNode.requestFocus();
                        //   });
                        // },
                        defaultPinTheme: PinTheme(
                          height: 45,
                          width: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        closeKeyboardWhenCompleted: false,
                        keyboardType: TextInputType.number,
                        focusedPinTheme: PinTheme(
                          height: 45,
                          width: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),

                const SizedBox(height: 24),
                InkWell(
                  onTap: state.isLoading ? null : widget.onSendOTPResetPassword,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: state.isLoading
                          ? null
                          : _ForgotPasswordPageConstants.buttonGradient,
                      color: state.isLoading ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: state.isLoading
                          ? SizedBox(height: 20, width: 20, child: AppLoader())
                          : !state.isShowOtpField
                          ? const Text(
                              'Send OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : const Text(
                              'Verify OTP',
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
              ] else ...[
                const SizedBox(height: 0),
                Text(
                  'Reset Password',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter a new password to reset your password.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                TextFormField(
                  key: const ValueKey('password_field'),

                  controller: widget.passwordController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 20,
                    ),
                    labelText: 'New Password',
                    hintText: 'Enter your new password',

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  validator: (value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty) return 'Password should not be empty';
                    if (value!.length < 6) {
                      return 'Enter a password with at least 6 characters';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => widget.onResetPassword(),
                ),
                SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('confirm_password_field'),

                  controller: widget.passwordConfirmController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 20,
                    ),
                    labelText: 'Confirm Password',
                    hintText: 'Enter your confirm password',
                    // prefixIcon: const Icon(Icons.email_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  validator: (value) {
                    final input = value?.trim() ?? '';
                    if (input.isEmpty) return 'Password should not be empty';
                    if (value!.length < 6) {
                      return 'Enter a password with at least 6 characters';
                    }
                    if (value != widget.passwordController.text) {
                      return 'password must be same';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => widget.onResetPassword(),
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: state.isLoading ? null : widget.onResetPassword,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: state.isLoading
                          ? null
                          : _ForgotPasswordPageConstants.buttonGradient,
                      color: state.isLoading ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Center(
                      child: state.isLoading
                          ? SizedBox(height: 20, width: 20, child: AppLoader())
                          : const Text(
                              'Set New Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ],

              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
