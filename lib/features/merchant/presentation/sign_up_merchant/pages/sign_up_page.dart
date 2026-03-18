// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/merchant/data/models/sign_up/merchant_registration_model.dart';
import 'package:homelyhope/features/merchant/data/services/merchant_draft_storage_service.dart';
import 'package:homelyhope/features/merchant/presentation/sign_up_merchant/providers/organization_providers.dart';
import 'package:homelyhope/features/merchant/presentation/sign_up_merchant/providers/sign_up_notifier.dart';
import 'package:homelyhope/features/merchant/presentation/sign_up_merchant/widgets/stepper.dart';
import 'package:sms_autofill/sms_autofill.dart';

import '../../../../../core/providers/snackbar_provider.dart';
import '../../../data/models/myprofile/myprofile_model.dart';

class SignUpMerchantPage extends ConsumerStatefulWidget {
  final MyProfileModel? merchantToEdit;

  const SignUpMerchantPage({super.key, this.merchantToEdit});

  @override
  ConsumerState<SignUpMerchantPage> createState() => _SignUpMerchantPageState();
}

class _SignUpMerchantPageState extends ConsumerState<SignUpMerchantPage> {
  // Check if we're in edit mode
  bool get isEditMode => widget.merchantToEdit != null;

  // Step 0: Business Information Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessEmailController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  // Step 1: Address & Contact Controllers
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _contactPersonDesignationController =
      TextEditingController();

  // Step 2: Document paths
  String? _gstCertificatePath;
  String? _gstCertificateName;
  String? _businessLicensePath;
  String? _businessLicenseName;
  String? _photoIdPath;
  String? _photoIdName;

  bool _isRegistering = false;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    // Load existing data for editing or load draft for new entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        // Load existing data for editing
        ref
            .read(signUpNotifierProvider.notifier)
            .loadFromMerchant(widget.merchantToEdit!);
      } else {
        // Load draft for new entry
        _loadDraft();
      }

      // Sync controllers with Riverpod state
      final state = ref.read(signUpNotifierProvider);
      _businessNameController.text = state.businessName;
      _businessEmailController.text = state.businessEmail;
      _phoneNumberController.text = state.phoneNumber;
      _businessTypeController.text = state.businessType;
      _passwordController.text = state.password;
      _confirmPasswordController.text = state.confirmPassword;
      _streetAddressController.text = state.streetAddress;
      _cityController.text = state.city;
      _stateController.text = state.state;
      _contactPersonNameController.text = state.contactPersonName;
      _contactPersonDesignationController.text = state.contactPersonDesignation;
    });
  }

  /// Load draft data and populate form fields
  Future<void> _loadDraft() async {
    try {
      final draft = await MerchantDraftStorageService.getDraft();
      if (draft != null && mounted) {
        // Update Riverpod state with draft data
        ref.read(signUpNotifierProvider.notifier).updateFromDraft({
          'businessName': draft['businessName'] ?? '',
          'businessEmail': draft['businessEmail'] ?? '',
          'phoneNumber': draft['phoneNumber'] ?? '',
          'businessType': draft['businessType'] ?? '',
          'password': draft['password'] ?? '',
          'confirmPassword': draft['password'] ?? '',
          'streetAddress': draft['address'] ?? draft['streetAddress'] ?? '',
          'city': draft['city'] ?? '',
          'state': draft['state'] ?? '',
          'contactPersonName': draft['contactPersonName'] ?? '',
          'contactPersonDesignation': draft['contactPersonDesignation'] ?? '',
          'gstCertificatePath': draft['gstCertificatePath'],
          'gstCertificateName': draft['gstCertificateName'],
          'businessLicensePath': draft['businessLicensePath'],
          'businessLicenseName': draft['businessLicenseName'],
          'photoIdPath': draft['photoIdPath'],
          'photoIdName': draft['photoIdName'],
        });

        // Update file paths if available
        setState(() {
          _gstCertificatePath = draft['gstCertificatePath'];
          _gstCertificateName = draft['gstCertificateName'];
          _businessLicensePath = draft['businessLicensePath'];
          _businessLicenseName = draft['businessLicenseName'];
          _photoIdPath = draft['photoIdPath'];
          _photoIdName = draft['photoIdName'];
        });

        // Update controllers after state is updated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = ref.read(signUpNotifierProvider);
          _businessNameController.text = state.businessName;
          _businessEmailController.text = state.businessEmail;
          _phoneNumberController.text = state.phoneNumber;
          _businessTypeController.text = state.businessType;
          _passwordController.text = state.password;
          _confirmPasswordController.text = state.confirmPassword;
          _streetAddressController.text = state.streetAddress;
          _cityController.text = state.city;
          _stateController.text = state.state;
          _contactPersonNameController.text = state.contactPersonName;
          _contactPersonDesignationController.text =
              state.contactPersonDesignation;
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
                    await MerchantDraftStorageService.clearDraft();
                    ref.read(signUpNotifierProvider.notifier).reset();
                    setState(() {
                      _gstCertificatePath = null;
                      _gstCertificateName = null;
                      _businessLicensePath = null;
                      _businessLicenseName = null;
                      _photoIdPath = null;
                      _photoIdName = null;
                    });
                    // Clear controllers
                    _businessNameController.clear();
                    _businessEmailController.clear();
                    _phoneNumberController.clear();
                    _businessTypeController.clear();
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                    _streetAddressController.clear();
                    _cityController.clear();
                    _stateController.clear();
                    _contactPersonNameController.clear();
                    _contactPersonDesignationController.clear();
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

      final state = ref.read(signUpNotifierProvider);
      final draftData = {
        'businessName': state.businessName,
        'businessEmail': state.businessEmail,
        'phoneNumber': state.phoneNumber,
        'businessType': state.businessType,
        'password': state.password,
        'address': state.streetAddress,
        'city': state.city,
        'state': state.state,
        'contactPersonName': state.contactPersonName,
        'contactPersonDesignation': state.contactPersonDesignation,
        'gstCertificatePath': _gstCertificatePath,
        'gstCertificateName': _gstCertificateName,
        'businessLicensePath': _businessLicensePath,
        'businessLicenseName': _businessLicenseName,
        'photoIdPath': _photoIdPath,
        'photoIdName': _photoIdName,
      };

      await MerchantDraftStorageService.saveDraft(draftData);

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
    // Step 0 Controllers
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _phoneNumberController.dispose();
    _businessTypeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Step 1 Controllers
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactPersonNameController.dispose();
    _contactPersonDesignationController.dispose();
    super.dispose();
  }

  void _onStepChanged(int step) {
    ref.read(signUpNotifierProvider.notifier).setCurrentStep(step);
  }

  void _nextStep() {
    ref.read(signUpNotifierProvider.notifier).nextStep();
  }

  void _previousStep() {
    ref.read(signUpNotifierProvider.notifier).previousStep();
  }

  Future<void> _pickFile({required String documentType}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;
        final filePath = file.path;

        // Check file size (5MB limit)
        if (filePath != null) {
          final fileSize = await File(filePath).length();
          if (fileSize > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File size must be less than 5MB'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        setState(() {
          switch (documentType) {
            case 'gst':
              _gstCertificateName = fileName;
              _gstCertificatePath = filePath;
              ref
                  .read(signUpNotifierProvider.notifier)
                  .setGstCertificate(filePath, fileName);
              break;
            case 'license':
              _businessLicenseName = fileName;
              _businessLicensePath = filePath;
              ref
                  .read(signUpNotifierProvider.notifier)
                  .setBusinessLicense(filePath, fileName);
              break;
            case 'photoId':
              _photoIdName = fileName;
              _photoIdPath = filePath;
              ref
                  .read(signUpNotifierProvider.notifier)
                  .setPhotoId(filePath, fileName);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _getHintPhoneNumber() async {
    try {
      final phoneNumber = await SmsAutoFill().hint;
      if (phoneNumber != null) {
        setState(() {
          _phoneNumberController.text = phoneNumber;
        });
      }
    } catch (e) {}
  }

  Future<void> _handleRegistration() async {
    // Validate required document (Photo ID) - only for new registration
    if (!isEditMode && _photoIdPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload Photo ID document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get form data from state
    final state = ref.read(signUpNotifierProvider);

    // Validate required fields
    if (state.businessName.isEmpty ||
        state.businessEmail.isEmpty ||
        state.phoneNumber.isEmpty ||
        state.businessType.isEmpty ||
        (!isEditMode && state.password.isEmpty) ||
        state.streetAddress.isEmpty ||
        state.city.isEmpty ||
        state.state.isEmpty ||
        state.contactPersonName.isEmpty) {
      ref
          .read(snackbarServiceProvider)
          .showInfo('Please fill in required fields');
      return;
    }

    // Validate passwords match (only for new registration or if password is being changed)
    if (!isEditMode || state.password.isNotEmpty) {
      if (state.password != state.confirmPassword) {
        ref.read(snackbarServiceProvider).showInfo('Passwords do not match');
        return;
      }
    }

    // Validate terms agreed (only for new registration)
    if (!isEditMode && !state.isAgreed) {
      ref
          .read(snackbarServiceProvider)
          .showInfo('Please agree to terms and conditions');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Format phone number (remove formatting characters)
      String phoneNumber = state.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Ensure phone number starts with + if not empty
      if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
        phoneNumber = '+$phoneNumber';
      }

      if (isEditMode) {
        // TODO: Implement update use case
        // For now, show a message that update is not yet implemented
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Update functionality is being implemented. Please check back soon.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Create registration request
        final registrationRequest = MerchantRegistrationRequest(
          businessName: state.businessName,
          businessEmail: state.businessEmail,
          phoneNumber: phoneNumber,
          password: state.password,
          businessType: state.businessType,
          address: state.streetAddress,
          city: state.city,
          state: state.state,
          contactPersonName: state.contactPersonName,
          contactPersonDesignation: state.contactPersonDesignation,
          gstCertificatePath: _gstCertificatePath,
          businessLicensePath: _businessLicensePath,
          photoIdPath: _photoIdPath,
        );

        // Get usecase from provider
        final useCase = ref.read(registerMerchantUseCaseProvider);

        // Call API
        final response = await useCase.call(registrationRequest);

        // Success - navigate to verification page or dashboard
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });

          // Clear draft after successful registration
          await MerchantDraftStorageService.clearDraft();

          ref.read(snackbarServiceProvider).showSuccess(
            response.message.isNotEmpty
                ? response.message
                : 'Registration completed successfully!',
          );

          // Navigate back or to merchant dashboard
          context.pop();
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
    // Only watch currentStep, not the entire state
    // This prevents rebuilds when other form fields change
    final currentStep = ref.watch(
      signUpNotifierProvider.select((state) => state.currentStep),
    );

    return PopScope(
      canPop: false, // STOP default pop
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (currentStep > 0) {
            _onStepChanged(currentStep - 1); // Go to previous step
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
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
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 0.0),
                    child: Text(
                      isEditMode ? 'Edit Profile' : 'Register Merchant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Stepper wrapped in RepaintBoundary to prevent unnecessary repaints
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                ),
                child: RepaintBoundary(
                  child: Steppers(
                    key: const ValueKey('stepper'),
                    currentStep: currentStep,
                    onStepChanged: _onStepChanged,
                  ),
                ),
              ),

              // Step Content - Wrapped in RepaintBoundary to prevent unnecessary repaints
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 0.0,
                ),
                child: RepaintBoundary(
                  key: ValueKey('step_content_$currentStep'),
                  child: _buildStepContent(currentStep),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    switch (currentStep) {
      case 0:
        return _buildBusinessInformationStep();
      case 1:
        return _buildAddressContactStep();
      case 2:
        return _buildVerificationDocumentsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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
            errorStyle: const TextStyle(height: 0, fontSize: 0),
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

  Widget _buildBusinessInformationStep() {
    final notifier = ref.read(signUpNotifierProvider.notifier);
    final state = ref.read(signUpNotifierProvider);

    // List of valid business types
    const List<String> validBusinessTypes = [
      'Retail',
      'Services',
      'Manufacturing',
      'Food & Beverage',
      'Other',
    ];

    // Get the current business type value, but only if it exists in the valid list
    final currentBusinessType =
        state.businessType.isNotEmpty &&
            validBusinessTypes.contains(state.businessType)
        ? state.businessType
        : null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Business Information Section
          _buildSectionHeader(
            'Business Information',
            'Enter your business details',
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _businessNameController,
            label: 'Business Name',
            icon: Icons.business_outlined,
            onChanged: (value) {
              notifier.setBusinessName(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _businessEmailController,
            label: 'Business Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: [AutofillHints.email],
            onChanged: (value) => notifier.setBusinessEmail(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business Email is required';
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
          _buildModernTextField(
            controller: _phoneNumberController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              UsNumberTextInputFormatter(),
            ],
            onTap: () {
              if (_phoneNumberController.text.isEmpty) {
                _getHintPhoneNumber();
              }
            },
            onChanged: (value) => notifier.setPhoneNumber(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone Number is required';
              }
              final digits = value.replaceAll(RegExp(r'[^\d]'), '');
              if (digits.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Dropdown for Business Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: currentBusinessType,
                decoration: InputDecoration(
                  labelText: 'Business Type',
                  prefixIcon: Icon(
                    Icons.category_outlined,
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
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'Retail',
                    child: Text('Retail'),
                  ),
                  const DropdownMenuItem(
                    value: 'Services',
                    child: Text('Services'),
                  ),
                  const DropdownMenuItem(
                    value: 'Manufacturing',
                    child: Text('Manufacturing'),
                  ),
                  const DropdownMenuItem(
                    value: 'Food & Beverage',
                    child: Text('Food & Beverage'),
                  ),
                  const DropdownMenuItem(value: 'Other', child: Text('Other')),
                  // If business type exists but not in the list, add it dynamically
                  if (state.businessType.isNotEmpty &&
                      !validBusinessTypes.contains(state.businessType))
                    DropdownMenuItem(
                      value: state.businessType,
                      child: Text(state.businessType),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _businessTypeController.text = value;
                    notifier.setBusinessType(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Business Type is required';
                  }
                  return null;
                },
              ),
            ],
          ),

          // Account Credentials Section (only for new registration)
          if (!isEditMode) ...[
            _buildSectionHeader(
              'Account Credentials',
              'Set up your login information',
            ),
            const SizedBox(height: 20),
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
              onChanged: (value) => notifier.setPassword(value),
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
              onChanged: (value) => notifier.setConfirmPassword(value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm Password is required';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _nextStep();
              } else {
                ref
                    .read(snackbarServiceProvider)
                    .showInfo('Please fill in required fields');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Continue  ➜'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAddressContactStep() {
    final notifier = ref.read(signUpNotifierProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address & Contact Information Section
          _buildSectionHeader(
            'Address & Contact Information',
            'Enter your business address and contact details',
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _streetAddressController,
            label: 'Street Address',
            icon: Icons.home_outlined,
            autofillHints: [AutofillHints.streetAddressLine1],
            onChanged: (value) => notifier.setStreetAddress(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Street Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
            autofillHints: [AutofillHints.addressCity],
            onChanged: (value) => notifier.setCity(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'City is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _stateController,
            label: 'State',
            icon: Icons.map_outlined,
            autofillHints: [AutofillHints.addressCityAndState],
            onChanged: (value) => notifier.setStateValue(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'State is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Contact Person', 'Person handling this account'),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _contactPersonNameController,
            label: 'Contact Person Name',
            icon: Icons.person_outline,
            autofillHints: [AutofillHints.name],
            onChanged: (value) => notifier.setContactPersonName(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Contact Person Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _contactPersonDesignationController,
            label: 'Contact Person Designation',
            icon: Icons.badge_outlined,
            hintText: 'Manager, Owner, etc.',
            optional: true,
            onChanged: (value) => notifier.setContactPersonDesignation(value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _nextStep();
                    } else {
                      ref
                          .read(snackbarServiceProvider)
                          .showInfo('Please fill in required fields');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(' Continue  ➜'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVerificationDocumentsStep() {
    final state = ref.watch(signUpNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          'Verification Documents',
          'Upload required documents for verification',
        ),
        const SizedBox(height: 20),
        // GST Certificate (Optional)
        _buildDocumentUpload(
          title: 'Certificate of Incorporation',
          optional: true,
          filePath: _gstCertificatePath,
          fileName: _gstCertificateName,
          onPick: () => _pickFile(documentType: 'gst'),
          onRemove: () {
            setState(() {
              _gstCertificatePath = null;
              _gstCertificateName = null;
            });
            ref
                .read(signUpNotifierProvider.notifier)
                .setGstCertificate(null, null);
          },
        ),
        const SizedBox(height: 16),
        // Business License (Optional)
        // _buildDocumentUpload(
        //   title: 'Business License',
        //   optional: true,
        //   filePath: _businessLicensePath,
        //   fileName: _businessLicenseName,
        //   onPick: () => _pickFile(documentType: 'license'),
        //   onRemove: () {
        //     setState(() {
        //       _businessLicensePath = null;
        //       _businessLicenseName = null;
        //     });
        //     ref
        //         .read(signUpNotifierProvider.notifier)
        //         .setBusinessLicense(null, null);
        //   },
        // ),
        const SizedBox(height: 16),
        // Photo ID (Required)
        _buildDocumentUpload(
          title: 'ID Card',
          optional: false,
          subtitle: 'State ID Card',
          filePath: _photoIdPath,
          fileName: _photoIdName,
          onPick: () => _pickFile(documentType: 'photoId'),
          onRemove: () {
            setState(() {
              _photoIdPath = null;
              _photoIdName = null;
            });
            ref.read(signUpNotifierProvider.notifier).setPhotoId(null, null);
          },
        ),

        if (!isEditMode) ...[
          //  _TermsCheckbox(),
          const SizedBox(height: 32),
        ] else
          const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: (_isRegistering || !state.isAgreed)
                    ? null
                    : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistering
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(isEditMode ? 'Update' : 'Register'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Save as Draft Button
        // if (!isEditMode) ...[
        //   OutlinedButton(
        //     onPressed: _isSavingDraft || _isRegistering ? null : _saveDraft,
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: AppTheme.primary,
        //       side: BorderSide(color: AppTheme.primary, width: 1.5),
        //       padding: const EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //     ),
        //     child: _isSavingDraft
        //         ? SizedBox(height: 20, width: 20, child: AppLoader())
        //         : const Row(
        //             mainAxisAlignment: MainAxisAlignment.center,
        //             children: [
        //               Icon(Icons.save_outlined, size: 20),
        //               SizedBox(width: 8),
        //               Text('Save as Draft'),
        //             ],
        //           ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required bool optional,
    String? subtitle,
    required String? filePath,
    required String? fileName,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightText,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              Text(
                '(Optional)',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: filePath != null ? Colors.green : Colors.grey.shade300,
                width: filePath != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                if (filePath != null) ...[
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (filePath == null) ...[
                        Icon(
                          Icons.upload_file,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click to upload',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF or image (Max 5 MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.check_circle, size: 40, color: Colors.green),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            fileName ?? 'File uploaded',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.lightText,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsCheckbox extends ConsumerWidget {
  const _TermsCheckbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAgreed = ref.watch(
      signUpNotifierProvider.select((state) => state.isAgreed),
    );
    final notifier = ref.read(signUpNotifierProvider.notifier);

    return Row(
      children: [
        Checkbox(
          activeColor: AppTheme.secondary,
          side: const BorderSide(width: 1),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          value: isAgreed,
          onChanged: (value) {
            notifier.setIsAgreed(value ?? false);
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              notifier.setIsAgreed(!isAgreed);
            },
            child: Text("I've read & agreed to terms & conditions"),
          ),
        ),
      ],
    );
  }
}

class UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digits
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    String formatted = "";

    if (digits.isEmpty) {
      formatted = "";
    } else if (digits.length <= 3) {
      formatted = "($digits";
    } else if (digits.length <= 6) {
      formatted = "(${digits.substring(0, 3)}) ${digits.substring(3)}";
    } else {
      formatted =
          "(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}";
    }

    // Maintain cursor at end
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
