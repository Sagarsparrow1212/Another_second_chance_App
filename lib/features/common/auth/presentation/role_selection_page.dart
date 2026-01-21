import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

enum UserRole { organization, merchant, donor }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  final selectedRole = ValueNotifier<UserRole?>(null);

  @override
  void dispose() {
    selectedRole.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (selectedRole.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to appropriate sign up page based on role
    switch (selectedRole.value!) {
      case UserRole.organization:
        context.push('/organization/signUp');
        break;
      case UserRole.merchant:
        context.push('/merchant/signUp');
        break;
      case UserRole.donor:
        context.push('/donor/signUp');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  _buildLogo(),
                  const SizedBox(height: 8),

                  // Title
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Choose how you\'d like to join our platform',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.lightSubText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Role Cards
                  _buildRoleCard(
                    role: UserRole.organization,
                    title: 'Organization',
                    description:
                        'Register your NGO or group to support homeless individuals.',
                    icon: Icons.business_center_outlined,
                    iconColor: const Color(0xFF3ebaaf),
                  ),
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: UserRole.merchant,
                    title: 'Merchant',
                    description:
                        'Provide services, or essentials through our platform.',
                    icon: Icons.store_outlined,
                    iconColor: const Color(0xFFEB9A4A),
                  ),
                  // add other role card that is the donor
                  const SizedBox(height: 16),
                  _buildRoleCard(
                    role: UserRole.donor,
                    title: 'Donor',
                    description:
                        'Donate to homeless individuals through our platform.',
                    icon: Icons.favorite_outlined,
                    iconColor: const Color(0xFF15306C),
                  ),
                  const SizedBox(height: 16),

                  // Continue Button
                  _buildContinueButton(),
                ],
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.lightText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(20),
      //   gradient: LinearGradient(
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //     colors: [const Color(0xFF3ebaaf), const Color(0xFF1e3f7c)],
      //   ),
      // ),
      child: Image.asset('assets/logo/homelyhope.png'),
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return ValueListenableBuilder<UserRole?>(
      valueListenable: selectedRole,
      builder: (context, value, child) {
        // Calculate inside builder to get updated value
        final isSelected = value == role;
        final cardColor = isSelected
            ? iconColor.withValues(alpha: 0.1)
            : Colors.white;
        final borderColor = isSelected ? iconColor : Colors.grey.shade300;

        return GestureDetector(
          onTap: () {
            // Toggle selection: if already selected, deselect; otherwise select
            selectedRole.value = isSelected ? null : role;
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Row(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.lightText,
                                ),
                              ),
                              Text(
                                description,
                                maxLines: 3,
                                style: TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.lightSubText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Checkmark indicator
                if (isSelected)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContinueButton() {
    return ValueListenableBuilder<UserRole?>(
      valueListenable: selectedRole,
      builder: (context, value, child) {
        final isEnabled = value != null;

        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEnabled
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [const Color(0xFF3ebaaf), const Color(0xFF1e3f7c)],
                  )
                : null,
            color: isEnabled ? null : Colors.grey.shade300,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? _handleContinue : null,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
