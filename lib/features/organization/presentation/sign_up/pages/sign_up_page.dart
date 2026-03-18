// ignore_for_file: avoid_print, deprecated_member_use

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';
import 'package:homelyhope/features/organization/presentation/sign_up/providers/organization_providers.dart';
import 'package:homelyhope/features/organization/presentation/sign_up/providers/sign_up_notifier.dart';
import 'package:homelyhope/features/organization/presentation/sign_up/widgets/stepper.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/providers/snackbar_provider.dart';

class OrgSignUpPage extends ConsumerStatefulWidget {
  final OrganizationDetailModel? organizationToEdit;

  const OrgSignUpPage({super.key, this.organizationToEdit});

  @override
  ConsumerState<OrgSignUpPage> createState() => _OrgSignUpPageState();
}

class _OrgSignUpPageState extends ConsumerState<OrgSignUpPage> {
  // Check if we're in edit mode
  bool get isEditMode => widget.organizationToEdit != null;

  // Step 0: Organisation Details Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _organisationNameController =
      TextEditingController();
  final TextEditingController _organisationTypeController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _primaryPhoneNumberController =
      TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  String? _articlesOfIncorporationName;
  String? _articlesOfIncorporationPath;

  String? _einName;
  String? _einPath;

  String? _irsLetterName;
  String? _irsLetterPath;
  bool _isRegistering = false;
  // Step 1: Address Details Controllers
  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _commissionCutController =
      TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing data for editing or reset form for new entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        ref
            .read(signUpNotifierProvider.notifier)
            .loadFromOrganization(widget.organizationToEdit!);
      } else {
        // Reset form for new entry
        ref.read(signUpNotifierProvider.notifier).reset();
      }

      // Sync controllers with Riverpod state
      final state = ref.read(signUpNotifierProvider);
      _organisationNameController.text = state.organisationName;
      _organisationTypeController.text = state.organisationType;
      _emailController.text = state.email;
      _contactPersonNameController.text = state.contactPersonName;
      _primaryPhoneNumberController.text = state.primaryPhoneNumber;
      _contactEmailController.text = state.contactEmail;
      _passwordController.text = state.password;
      _confirmPasswordController.text = state.confirmPassword;
      _streetAddressController.text = state.streetAddress;
      _cityController.text = state.city;
      _commissionCutController.text = state.commissionCut;
      _stateController.text = state.state;
      _zipCodeController.text = state.zipCode;
      _countryController.text = state.country;
    });
    final state = ref.read(signUpNotifierProvider);
    print("state.organisationType ${state.organisationType}");
  }

  @override
  void dispose() {
    // Step 0 Controllers
    _organisationNameController.dispose();
    _organisationTypeController.dispose();
    _emailController.dispose();
    _commissionCutController.dispose();
    _contactPersonNameController.dispose();
    _primaryPhoneNumberController.dispose();
    _contactEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Step 1 Controllers
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
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

  Future<void> _pickFile(String documentType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileSize = file.size; // bytes

        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size exceeds 10MB limit.')),
            );
          }
          return;
        }

        setState(() {
          if (documentType == 'articles') {
            _articlesOfIncorporationName = file.name;
            _articlesOfIncorporationPath = file.path;
          } else if (documentType == 'ein') {
            _einName = file.name;
            _einPath = file.path;
          } else if (documentType == 'irs') {
            _irsLetterName = file.name;
            _irsLetterPath = file.path;
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

  Widget _buildDocumentUploadItem({
    required String title,
    required String? documentName,
    required String? documentPath,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (documentPath != null) ...[
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: onClear,
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
                ],
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (documentName == null) ...[
                        const Icon(
                          Icons.upload_file,
                          size: 40,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text('Click to upload'),
                        const SizedBox(height: 4),
                        const Text(
                          'PDF, JPG, JPEG, PNG (Max 10MB)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ] else ...[
                        if (!documentName.toLowerCase().endsWith('.pdf')) ...[
                          SizedBox(
                            height: 80,
                            child: Image.file(File(documentPath!)),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              documentName,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            Icons.picture_as_pdf,
                            size: 40,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Text(
                              documentName,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _getHintPhoneNumber() async {
    try {
      final phoneNumber = await SmsAutoFill().hint;
      if (phoneNumber != null) {
        setState(() {
          _primaryPhoneNumberController.text = phoneNumber;
        });
      }
    } catch (e) {}
  }

  Future<void> _handleRegistration() async {
    // Get form data from state
    final state = ref.read(signUpNotifierProvider);

    // Validate document is uploaded (only required for new registration)
    if (!isEditMode &&
        (_articlesOfIncorporationPath == null ||
            _einPath == null ||
            _irsLetterPath == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required verification documents'),
        ),
      );
      return;
    }

    // Validate required fields
    if (state.email.isEmpty ||
        (!isEditMode && state.password.isEmpty) ||
        state.organisationName.isEmpty ||
        state.organisationType.isEmpty ||
        state.streetAddress.isEmpty ||
        state.city.isEmpty ||
        state.state.isEmpty ||
        state.zipCode.isEmpty ||
        state.country.isEmpty ||
        state.commissionCut.isEmpty) {
      ref
          .read(snackbarServiceProvider)
          .showInfo('Please fill in required fields');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      // Prepare documents - use existing if in edit mode and no new file uploaded
      List<OrgDocument> documents = [];
      if (_articlesOfIncorporationPath != null) {
        documents.add(
          OrgDocument(
            docName:
                'Articles of Incorporation - ${File(_articlesOfIncorporationPath!).path.split('/').last}',
            docUrl: _articlesOfIncorporationPath!,
            id: '',
          ),
        );
      }
      if (_einPath != null) {
        documents.add(
          OrgDocument(
            docName: 'EIN - ${File(_einPath!).path.split('/').last}',
            docUrl: _einPath!,
            id: '',
          ),
        );
      }
      if (_irsLetterPath != null) {
        documents.add(
          OrgDocument(
            docName:
                'IRS 501(c)(3) Letter - ${File(_irsLetterPath!).path.split('/').last}',
            docUrl: _irsLetterPath!,
            id: '',
          ),
        );
      }

      if (documents.isEmpty &&
          isEditMode &&
          widget.organizationToEdit?.documents != null) {
        // Keep existing documents if no new file uploaded
        documents = widget.organizationToEdit!.documents!;
      }

      // Create registration/update model
      final registrationModel = OrganizationDetailModel(
        id: isEditMode ? state.organizationId : null,
        email: state.email,
        password: isEditMode && state.password.isNotEmpty
            ? state.password
            : (isEditMode ? null : state.password),
        name: state.organisationName,
        orgType: state.organisationType,
        streetAddress: state.streetAddress,
        city: state.city,
        state: state.state,
        zipCode: state.zipCode,
        country: state.country,
        contactPerson: state.contactPersonName.isNotEmpty
            ? state.contactPersonName
            : '',
        emergencyContactEmail: state.contactEmail.isNotEmpty
            ? state.contactEmail
            : '',
        contactPhone: state.primaryPhoneNumber.isNotEmpty
            ? state.primaryPhoneNumber.replaceAll(
                RegExp(r'[^\d]'),
                '',
              ) // Remove formatting
            : '',

        documents: documents.isNotEmpty ? documents : null,
      );

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
        // Get usecase from provider
        final useCase = ref.read(registerOrganizationUseCaseProvider);

        // Call API
        final response = await useCase.call(registrationModel);

        // Success
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });

          // Check for Stripe connect accountLink and launch it
          if (response.accountLink != null &&
              response.accountLink!.isNotEmpty) {
            final uri = Uri.parse(response.accountLink!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not open Stripe setup link. Please contact support.',
                    ),
                  ),
                );
              }
            }
          }

          // Navigate to verification page
          if (mounted) {
            context.push('/organization/verification');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Registration completed successfully! Please complete your Stripe verification.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
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
                      isEditMode ? 'Edit Profile' : 'Register Organization',
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
              // Using stable key to prevent widget recreation and animation replay
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                ),
                child: RepaintBoundary(
                  child: Steppers(
                    key: const ValueKey(
                      'stepper',
                    ), // Stable key - doesn't change
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
        return _buildOrganisationDetailsStep();
      case 1:
        return _buildAddressDetailsStep();
      case 2:
        return _buildUploadDocumentsStep();
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

  Widget _buildOrganisationDetailsStep() {
    final notifier = ref.read(signUpNotifierProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Organization Details Section
          _buildSectionHeader(
            'Organization Details',
            'Enter your organization information',
          ),
          const SizedBox(height: 20),
          _buildModernTextField(
            controller: _organisationNameController,
            label: 'Organisation Name',
            icon: Icons.business_outlined,
            onChanged: (value) {
              notifier.setOrganisationName(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Organisation Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Dropdown for Organization Type
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _organisationTypeController.text.isNotEmpty
                    ? _organisationTypeController.text
                    : null,
                decoration: InputDecoration(
                  labelText: 'Organisation Type',
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
                items: const [
                  DropdownMenuItem(value: 'NGO', child: Text('NGO')),
                  DropdownMenuItem(value: 'Private', child: Text('Private')),
                  DropdownMenuItem(value: 'Govt', child: Text('Govt')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _organisationTypeController.text = value;
                    notifier.setOrganisationType(value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Organisation Type is required';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: [AutofillHints.email],
            onChanged: (value) => notifier.setEmail(value),
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
            controller: _primaryPhoneNumberController,
            label: 'Primary Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            autofillHints: [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              UsNumberTextInputFormatter(),
            ],
            onTap: () {
              if (_primaryPhoneNumberController.text.isEmpty) {
                _getHintPhoneNumber();
              }
            },
            onChanged: (value) => notifier.setPrimaryPhoneNumber(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Primary Phone Number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _contactEmailController,
            label: 'Contact Email',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: [AutofillHints.email],
            optional: true,
            onChanged: (value) => notifier.setContactEmail(value),
          ),

          // Account Credentials Section (only for new registration)
          if (!isEditMode) ...[
            const SizedBox(height: 8),
            _buildSectionHeader(
              'Account Credentials',
              'Set up your login information',
            ),
            const SizedBox(height: 16),
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

  Widget _buildAddressDetailsStep() {
    final notifier = ref.read(signUpNotifierProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Address Details Section
          _buildSectionHeader(
            'Address Details',
            'Enter your organization address',
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
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _zipCodeController,
            label: 'Zip Code',
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            autofillHints: [AutofillHints.postalCode],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
            ],
            onChanged: (value) => notifier.setZipCode(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Zip Code is required';
              }
              final zipRegex = RegExp(r'^\d{5}(-\d{4})?$');
              if (!zipRegex.hasMatch(value)) {
                return 'Enter a valid US ZIP Code (e.g. 10001 or 10001-1234)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _countryController,
            label: 'Country',
            icon: Icons.public_outlined,
            onChanged: (value) => notifier.setCountry(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Country is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            controller: _commissionCutController,
            label: 'Default Commission Cut (%)',
            icon: Icons.percent_outlined,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            hintText: 'Enter default commission percentage (0-100)',
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{0,3}(\.\d{0,2})?$'),
              ),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final parsed = double.tryParse(newValue.text);
                if (parsed == null) return oldValue;
                if (parsed > 100) return oldValue;
                return newValue;
              }),
            ],
            onChanged: (value) => notifier.setCommissionCut(value),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Default Commission Cut is required';
              }
              final parsed = double.tryParse(value);
              if (parsed == null) {
                return 'Please enter a valid number';
              }
              if (parsed < 0 || parsed > 100) {
                return 'Commission Cut must be between 0 and 100';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
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

  Widget _buildUploadDocumentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isEditMode
              ? 'Verification Documents (Optional)'
              : 'Verification Documents',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (isEditMode &&
            widget.organizationToEdit?.documents != null &&
            widget.organizationToEdit!.documents!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Current documents will be kept if no new file is uploaded',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
        const SizedBox(height: 16),
        _buildDocumentUploadItem(
          title: 'Articles of Incorporation',
          documentName: _articlesOfIncorporationName,
          documentPath: _articlesOfIncorporationPath,
          onPick: () => _pickFile('articles'),
          onClear: () {
            setState(() {
              _articlesOfIncorporationName = null;
              _articlesOfIncorporationPath = null;
            });
          },
        ),
        _buildDocumentUploadItem(
          title: 'EIN (Employer Identification Number)',
          documentName: _einName,
          documentPath: _einPath,
          onPick: () => _pickFile('ein'),
          onClear: () {
            setState(() {
              _einName = null;
              _einPath = null;
            });
          },
        ),
        _buildDocumentUploadItem(
          title: 'IRS 501(c)(3) Determination Letter',
          documentName: _irsLetterName,
          documentPath: _irsLetterPath,
          onPick: () => _pickFile('irs'),
          onClear: () {
            setState(() {
              _irsLetterName = null;
              _irsLetterPath = null;
            });
          },
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRegistering
                    ? SizedBox(height: 20, width: 20, child: AppLoader())
                    : Text(isEditMode ? 'Update' : 'Register'),
              ),
            ),
          ],
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
