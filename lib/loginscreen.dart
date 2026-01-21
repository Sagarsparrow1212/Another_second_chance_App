import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/navigationscreen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isDarkMode = true; // Default to dark mode
  bool _hasAttemptedSubmit = false;

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to dark mode
    _isDarkMode = true;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _isDarkMode ? const Color(0xFF040927) : Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo/SalaryBox.png',
                          width: 130,
                          height: 130,
                        ),
                        const SizedBox(height: 4),

                        Text(
                          'SalaryBox',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Sign in to continue',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 24),

                        _GradientTextField(
                          controller: _emailController,
                          hintText: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          isDarkMode: _isDarkMode,
                          prefixIcon: Icons.email_outlined,
                          shouldValidate: _hasAttemptedSubmit,
                          onChanged: (value) {
                            // Clear error when user starts typing
                            if (emailError != null) {
                              setState(() {
                                emailError = null;
                              });
                            }
                          },
                        ),
                        if (emailError != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                emailError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _GradientTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          obscureText: _obscurePassword,
                          isDarkMode: _isDarkMode,
                          prefixIcon: Icons.lock_outlined,
                          onChanged: (value) {
                            // Clear error when user starts typing
                            if (passwordError != null) {
                              setState(() {
                                passwordError = null;
                              });
                            }
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        if (passwordError != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                passwordError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        _GradientButton(
                          text: 'LOGIN',
                          onPressed: () {
                            setState(() {
                              _hasAttemptedSubmit = true;
                              // Clear previous errors
                              emailError = null;
                              passwordError = null;
                            });

                            // Validate email
                            final emailValue = _emailController.text.trim();
                            if (emailValue.isEmpty) {
                              setState(() {
                                emailError = 'Please enter Email';
                              });
                            } else if (!emailValue.contains('@')) {
                              setState(() {
                                emailError = 'Please enter a valid email';
                              });
                            }

                            // Validate password
                            final passwordValue = _passwordController.text;
                            if (passwordValue.isEmpty) {
                              setState(() {
                                passwordError = 'Please enter Password';
                              });
                            }

                            // If no errors, proceed with login
                            if (emailError == null && passwordError == null) {
                              // TODO: Handle login
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NavigationScreen(),
                                ),
                              );
                            }
                          },
                          isDarkMode: _isDarkMode,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Gradient Text Field Widget
class _GradientTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final bool isDarkMode;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool shouldValidate;
  final ValueChanged<String>? onChanged;

  const _GradientTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.isDarkMode,
    required this.prefixIcon,
    this.suffixIcon,
    this.shouldValidate = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3ebaaf), // Teal
            const Color(0xFF9966CC), // Purple
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDarkMode ? const Color(0xFF0A0F2E) : Colors.white,
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}

// Gradient Button Widget
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDarkMode;

  const _GradientButton({
    required this.text,
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8],
          colors: [
            const Color(0xFF37ddcc),
            const Color(0xFF4db8d8),
            const Color(0xFF6191ed),
            const Color(0xFF747bef),
            const Color(0xFFa048f2),
          ],
        ),
        boxShadow: isDarkMode
            ? [
                BoxShadow(
                  color: const Color(0xFF3ebaaf).withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Social Login Button Widget
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;

  const _SocialLoginButton({
    required this.icon,
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? const Color(0xFF0A0F2E) : Colors.grey[100],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 28,
          ),
        ),
      ),
    );
  }
}
