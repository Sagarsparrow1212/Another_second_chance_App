// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/donor/data/models/sign_up/donor_registration_model.dart';
import 'package:homelyhope/features/donor/data/models/profile/donor_profile_model.dart';
import 'package:homelyhope/features/donor/data/services/donor_draft_storage_service.dart';
import 'package:homelyhope/features/donor/presentation/sign_up/providers/donor_providers.dart';
import '../../../../core/providers/snackbar_provider.dart';
import '../../../organization/presentation/sign_up/pages/sign_up_page.dart';

class _UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    if (newText.length > 14) {
      return oldValue;
    }

    // Identify if backspacing
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Check if new character is waiting to be formatted
    var buffer = StringBuffer();
    // Remove all non-digits
    String digits = newText.replaceAll(RegExp(r'\D'), '');

    // Format based on length
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }

    String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SignUpDonorPage extends ConsumerStatefulWidget {
  final DonorProfileModel? donorToEdit;

  const SignUpDonorPage({super.key, this.donorToEdit});

  @override
  ConsumerState<SignUpDonorPage> createState() => _SignUpDonorPageState();
}

class _SignUpDonorPageState extends ConsumerState<SignUpDonorPage> {
  // Check if we're in edit mode
  bool get isEditMode => widget.donorToEdit != null;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _obscureText = true;
  bool _obscureConfirmText = true;
  bool _isRegistering = false;
  bool _isSavingDraft = false;
  String? _gender;
  String? _preferredDonationType;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure widget is built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        // Load existing data for editing
        _loadDonorData();
      } else {
        // Load draft for new entry
        _loadDraft();
      }
    });
  }

  /// Load existing donor data for editing
  void _loadDonorData() {
    if (!mounted) return;
    final donor = widget.donorToEdit!;
    setState(() {
      _nameController.text = donor.fullName.isNotEmpty ? donor.fullName : '';
      _emailController.text = donor.email.isNotEmpty ? donor.email : '';
      _phoneNumberController.text = donor.phone.isNotEmpty ? donor.phone : '';
      _addressController.text = donor.address.isNotEmpty ? donor.address : '';
      _gender = donor.gender.isNotEmpty ? donor.gender : null;
      _preferredDonationType = donor.preferredDonationType.isNotEmpty
          ? donor.preferredDonationType
          : null;
      // Don't load password in edit mode
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  /// Load draft data and populate form fields
  Future<void> _loadDraft() async {
    try {
      final draft = await DonorDraftStorageService.getDraft();
      if (draft != null && mounted) {
        setState(() {
          _nameController.text = draft['fullName'] ?? '';
          _emailController.text = draft['email'] ?? '';
          _passwordController.text = draft['password'] ?? '';
          _confirmPasswordController.text = draft['password'] ?? '';
          _addressController.text = draft['address'] ?? '';
          _phoneNumberController.text = draft['phoneNumber'] ?? '';
          _gender = draft['gender'];
          _preferredDonationType = draft['preferredDonationType'];
        });

        // Show snackbar if draft was loaded
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Draft data loaded'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'Clear',
                  textColor: Colors.white,
                  onPressed: () async {
                    await DonorDraftStorageService.clearDraft();
                    setState(() {
                      _nameController.clear();
                      _emailController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _addressController.clear();
                      _phoneNumberController.clear();
                      _gender = null;
                      _preferredDonationType = null;
                    });
                  },
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      // Handle error silently
      print('Error loading draft: $e');
    }
  }

  /// Save current form data as draft
  Future<void> _saveDraft() async {
    try {
      setState(() {
        _isSavingDraft = true;
      });

      final draftData = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'address': _addressController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
        'gender': _gender,
        'preferredDonationType': _preferredDonationType,
      };

      await DonorDraftStorageService.saveDraft(draftData);

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save draft: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ref
          .read(snackbarServiceProvider)
          .showInfo('Please fill in all required fields');
      return;
    }

    // Validate gender
    if (_gender == null || _gender!.isEmpty) {
      ref.read(snackbarServiceProvider).showInfo('Please select your gender');
      return;
    }

    // Validate preferred donation type
    if (_preferredDonationType == null || _preferredDonationType!.isEmpty) {
      ref
          .read(snackbarServiceProvider)
          .showInfo('Please select a preferred donation type');
      return;
    }

    // In edit mode, password is optional
    if (isEditMode) {
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text.length < 8) {
          ref
              .read(snackbarServiceProvider)
              .showInfo('Password must be at least 8 characters');
          return;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          ref.read(snackbarServiceProvider).showInfo('Passwords do not match');
          return;
        }
      }
    } else {
      // In registration mode, password is required
      if (_passwordController.text.isEmpty) {
        ref.read(snackbarServiceProvider).showInfo('Password is required');
        return;
      }
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Format phone number (remove formatting characters, keep + and digits)
      String phoneNumber = _phoneNumberController.text.replaceAll(
        RegExp(r'[^\d+]'),
        '',
      );

      // Ensure phone number starts with +
      if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      if (isEditMode) {
        // Update mode - password fields are hidden, so use placeholder
        // The datasource will remove 'NO_CHANGE' from the request
        final password = 'NO_CHANGE';

        // Create update request
        final updateRequest = DonorRegistrationRequest(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: phoneNumber,
          password: password,
          gender: _gender!,
          address: _addressController.text.trim(),
          preferredDonationType: _preferredDonationType!,
        );

        // Get usecase from provider
        final useCase = ref.read(registerDonorUseCaseProvider);

        // Call update API
        final response = await useCase.updateDonor(
          widget.donorToEdit!.id,
          updateRequest,
        );

        // Success - navigate back
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message.isNotEmpty
                    ? response.message
                    : 'Profile updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to profile page
          context.pop();
        }
      } else {
        // Create registration request
        final registrationRequest = DonorRegistrationRequest(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: phoneNumber,
          password: _passwordController.text,
          gender: _gender!,
          address: _addressController.text.trim(),
          preferredDonationType: _preferredDonationType!,
        );

        // Get usecase from provider
        final useCase = ref.read(registerDonorUseCaseProvider);

        // Call API
        final response = await useCase.call(registrationRequest);

        // Success - navigate to login
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });

          // Clear draft after successful registration
          await DonorDraftStorageService.clearDraft();

          // Navigate to login page
          context.push('/login');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.message.isNotEmpty
                    ? response.message
                    : 'Registration completed successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isEditMode ? 'Update' : 'Registration'} failed: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    context.pop();
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                ),
                SizedBox(width: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 0.0),
                  child: Text(
                    isEditMode ? 'Edit Profile' : 'Register as Donor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            //SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 16.0,
                bottom: 24.0,
              ),
              child: _buildDonorForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.lightSubText,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool optional = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    VoidCallback? onTap,
    List<String>? autofillHints,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator: validator,
          onTap: onTap,
          autofillHints: autofillHints,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightText,
          ),
          decoration: InputDecoration(
            labelText: label + (optional ? ' (Optional)' : ''),
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppTheme.lightSubText, size: 22),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            isDense: false,
            floatingLabelAlignment: FloatingLabelAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightSubText,
            ),
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            floatingLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              height: 1.5,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonorForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Required Fields Section
          _buildSectionHeader(
            'Required Information',
            'Please fill in all required fields',
          ),
          const SizedBox(height: 20),

          // Full Name
          _buildModernTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            autofillHints: [AutofillHints.name],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Full Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email
          _buildModernTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: [AutofillHints.email],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password fields (only show in registration mode, not edit mode)
          if (!isEditMode) ...[
            // Password
            _buildModernTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: _obscureText,
              autofillHints: [AutofillHints.password],
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.lightSubText,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            _buildModernTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmText,
              autofillHints: [AutofillHints.password],
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmText ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.lightSubText,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmText = !_obscureConfirmText;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm Password is required';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Address
          _buildModernTextField(
            controller: _addressController,
            label: 'Address',
            icon: Icons.location_on_outlined,
            hintText: '123 Main Street, City, State, ZIP',
            maxLines: 2,
            autofillHints: [AutofillHints.streetAddressLine1],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Gender
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.lightSubText,
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  isDense: false,
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightSubText,
                  ),
                  floatingLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    height: 1.5,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                  DropdownMenuItem(
                    value: 'Prefer not to say',
                    child: Text('Prefer not to say'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gender is required';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferred Donation Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _preferredDonationType,
                decoration: InputDecoration(
                  labelText: 'Preferred Donation Type',
                  prefixIcon: Icon(
                    Icons.favorite_outline,
                    color: AppTheme.lightSubText,
                    size: 22,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  isDense: false,
                  floatingLabelAlignment: FloatingLabelAlignment.start,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightSubText,
                  ),
                  floatingLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    height: 1.5,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Money', child: Text('Money')),
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Clothes', child: Text('Clothes')),
                  DropdownMenuItem(value: 'Services', child: Text('Services')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _preferredDonationType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Preferred Donation Type is required';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phone Number
          _buildModernTextField(
            controller: _phoneNumberController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: [AutofillHints.telephoneNumber],
            hintText: '(123) 456-7890',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone Number is required';
              }
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              UsNumberTextInputFormatter(),
              LengthLimitingTextInputFormatter(14),
            ],
          ),
          const SizedBox(height: 32),

          // Save as Draft Button (only show in registration mode)
          if (!isEditMode) ...[
            OutlinedButton(
              onPressed: _isSavingDraft || _isRegistering ? null : _saveDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSavingDraft
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primary,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Save as Draft'),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],

          // Register/Update Button
          ElevatedButton(
            onPressed: _isRegistering ? null : _handleRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRegistering
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isEditMode ? 'Update Profile' : 'Register'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
