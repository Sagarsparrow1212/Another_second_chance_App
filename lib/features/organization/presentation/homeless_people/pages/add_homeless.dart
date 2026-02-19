import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import '../../../data/models/homeless_people/homeless_model.dart';
import '../providers/homeless_providers.dart';

class AddHomeless extends ConsumerStatefulWidget {
  final HomelessModel? homelessToEdit;

  const AddHomeless({super.key, this.homelessToEdit});

  @override
  ConsumerState<AddHomeless> createState() => _AddHomelessState();
}

class _AddHomelessState extends ConsumerState<AddHomeless> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Check if we're in edit mode
  bool get isEditMode => widget.homelessToEdit != null;

  // Text editing controllers for UI (synced with provider)
  // Initialize immediately to avoid LateInitializationError during hot reload
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _commissionCutController =
      TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _healthConditionsController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Reset form state when page opens (using post-frame callback to ensure ref is available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditMode) {
        // Load existing data for editing
        ref
            .read(addHomelessFormNotifierProvider.notifier)
            .loadFromHomeless(widget.homelessToEdit!);
      } else {
        // Reset form for new entry
        ref.read(addHomelessFormNotifierProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _commissionCutController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _healthConditionsController.dispose();
    _experienceController.dispose();
    _scrollController.dispose();
    // Don't reset provider state in dispose - let it persist or reset on page open
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    // Validate all fields
    notifier.validateAll();

    final formState = ref.read(addHomelessFormNotifierProvider);

    if (!formState.isValid) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
      // Collect valid-looking field names that have errors
      final errorFields = <String>[];

      formState.fieldErrors.forEach((key, error) {
        if (error != null) {
          // Convert key to readable name
          String fieldName = key;
          switch (key) {
            case 'fullName':
              fieldName = 'Full Name';
              break;
            case 'dob':
              fieldName = 'Date of Birth';
              break;
            case 'phone':
              fieldName = 'Phone Number';
              break;
            case 'email':
              fieldName = 'Email Address';
              break;
            case 'username':
              fieldName = 'Username';
              break;
            case 'password':
              fieldName = 'Password';
              break;
            case 'confirmPassword':
              fieldName = 'Confirm Password';
              break;
            case 'commissionCut':
              fieldName = 'Organization Cut';
              break;
          }
          errorFields.add(fieldName);
        }
      });

      // Special check for required fields that might be empty but not yet touched/validated
      if (!isEditMode) {
        if (formState.fullName.isEmpty && !errorFields.contains('Full Name'))
          errorFields.add('Full Name');
        if (formState.dateOfBirth.isEmpty &&
            !errorFields.contains('Date of Birth'))
          errorFields.add('Date of Birth');
        if (formState.phone.isEmpty && !errorFields.contains('Phone Number'))
          errorFields.add('Phone Number');
        if (formState.email.isEmpty && !errorFields.contains('Email Address'))
          errorFields.add('Email Address');
        if (formState.username.isEmpty && !errorFields.contains('Username'))
          errorFields.add('Username');
        if (formState.password.isEmpty && !errorFields.contains('Password'))
          errorFields.add('Password');
      }

      final errorMessage = errorFields.isNotEmpty
          ? 'Please check: ${errorFields.join(", ")}'
          : 'Please fill in all required fields';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
      );
      return;
    }

    if (isEditMode) {
      // Update existing homeless person
      const secureStorage = FlutterSecureStorage();
      final token = await secureStorage.read(key: 'token');

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Authentication token not found. Please login again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await notifier.update(token);

      if (mounted) {
        final currentState = ref.read(addHomelessFormNotifierProvider);
        if (currentState.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${currentState.submitError}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (currentState.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Homeless person updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back with result
          Navigator.of(context).pop(true);
        }
      }
    } else {
      // Create new homeless person
      print('Creating new homeless person');
      final organizationId = await ref.read(organizationIdProvider.future);
      if (organizationId == null || organizationId.isEmpty) {
        print('Organization ID not found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization ID not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      print('Organization ID found: $organizationId');
      await notifier.submit(organizationId);

      if (mounted) {
        print('Mounted');
        final currentState = ref.read(addHomelessFormNotifierProvider);
        print('Current state: $currentState');
        if (currentState.submitError != null) {
          print('Error: ${currentState.submitError}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${currentState.submitError}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (currentState.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Homeless person registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset form and navigate back
          notifier.reset();
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  /// Sync text controllers with provider state (only if different to avoid loops)
  void _syncControllers(AddHomelessFormState formState) {
    if (_fullNameController.text != formState.fullName) {
      _fullNameController.text = formState.fullName;
    }
    if (_dobController.text != formState.dateOfBirth) {
      _dobController.text = formState.dateOfBirth;
    }
    if (_bioController.text != formState.bio) {
      _bioController.text = formState.bio;
    }
    if (_phoneController.text != formState.phone) {
      _phoneController.text = formState.phone;
    }
    if (_emailController.text != formState.email) {
      _emailController.text = formState.email;
    }
    if (_addressController.text != formState.address) {
      _addressController.text = formState.address;
    }
    if (_cityController.text != formState.city) {
      _cityController.text = formState.city;
    }
    if (_stateController.text != formState.state) {
      _stateController.text = formState.state;
    }
    if (_zipController.text != formState.zip) {
      _zipController.text = formState.zip;
    }
    if (_countryController.text != formState.country) {
      _countryController.text = formState.country;
    }
    if (_usernameController.text != formState.username) {
      _usernameController.text = formState.username;
    }
    if (_passwordController.text != formState.password) {
      _passwordController.text = formState.password;
    }
    if (_confirmPasswordController.text != formState.confirmPassword) {
      _confirmPasswordController.text = formState.confirmPassword;
    }
    if (_healthConditionsController.text != formState.healthConditions) {
      _healthConditionsController.text = formState.healthConditions;
    }
    if (_experienceController.text != formState.experience) {
      _experienceController.text = formState.experience;
    }
    if (_commissionCutController.text != formState.commissionCut) {
      _commissionCutController.text = formState.commissionCut;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch form state from provider
    final formState = ref.watch(addHomelessFormNotifierProvider);

    // Sync controllers with provider state
    _syncControllers(formState);

    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          isEditMode ? 'Edit Homeless Person' : 'Add Homeless Person',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightText,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.lightIcon),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              _buildProfileImageSection(),
              const SizedBox(height: 32),

              // Personal Information Section
              _buildSectionHeader(
                'Personal Information',
                'Enter basic details about the person',
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _fullNameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                fieldKey: 'fullName',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Show age display in edit mode if we have direct age
              if (isEditMode && formState.directAge != null) ...[
                _buildAgeDisplay(formState.directAge!),
                const SizedBox(height: 16),
              ],
              _buildDateOfBirthField(),
              const SizedBox(height: 20),

              // Gender Selection
              _buildGenderSelector(),
              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _bioController,
                label: 'Short Bio / Description',
                icon: Icons.description_outlined,
                fieldKey: 'bio',
                maxLines: 3,
                optional: true,
              ),
              const SizedBox(height: 32),

              // Contact Information Section
              _buildSectionHeader(
                'Contact Information',
                'How to reach this person',
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _phoneController,
                label: 'Phone Number',

                icon: Icons.phone_outlined,
                fieldKey: 'phone',
                keyboardType: TextInputType.phone,

                autofillHints: [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  UsPhoneNumberFormatter(),
                ],
                validator: (value) => formState.fieldErrors['phone'],
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                fieldKey: 'email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => formState.fieldErrors['email'],
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _addressController,
                label: 'Street Address',
                icon: Icons.home_outlined,
                fieldKey: 'address',
                optional: true,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city_outlined,
                fieldKey: 'city',
                optional: true,
              ),
              const SizedBox(height: 16),
              // Account Credentials Section (only for new entries)
              if (!isEditMode) ...[
                _buildSectionHeader(
                  'Account Credentials',
                  'Login information for the account',
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  fieldKey: 'username',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  fieldKey: 'password',
                  suffixIcon: formState.isChangePassewordSuffix!
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () {
                    final isCurrentlyObscured =
                        formState.isChangePassewordSuffix ?? true;

                    ref
                        .read(addHomelessFormNotifierProvider.notifier)
                        .setPassWordSuffixChange(!isCurrentlyObscured);
                  },
                  obscureText: formState.isChangePassewordSuffix ?? true,
                  validator: (value) => formState.fieldErrors['password'],
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  fieldKey: 'confirmPassword',
                  suffixIcon: formState.isChangeConfirmPassewordSuffix!
                      ? Icons.visibility_off
                      : Icons.visibility,
                  onSuffixIconTap: () {
                    final isCurrentlyObscured =
                        formState.isChangeConfirmPassewordSuffix ?? true;

                    ref
                        .read(addHomelessFormNotifierProvider.notifier)
                        .setConfirmPasswordSuffixChange(!isCurrentlyObscured);
                  },
                  obscureText: formState.isChangeConfirmPassewordSuffix ?? true,
                  validator: (value) =>
                      formState.fieldErrors['confirmPassword'],
                ),
                const SizedBox(height: 32),
              ],

              // Skills Section
              _buildSectionHeader(
                'Skills & Abilities',
                'Select relevant skills (multiple selection)',
              ),
              const SizedBox(height: 16),
              _buildSkillsSelector(),
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _experienceController,
                label: 'Work Experience',
                icon: Icons.work_outline,
                fieldKey: 'experience',
                optional: true,
                maxLines: 2,
                hintText: 'e.g., 5 years in restaurant work',
              ),
              const SizedBox(height: 32),

              // Languages Section
              _buildSectionHeader(
                'Languages',
                'Select languages spoken (multiple selection)',
              ),
              const SizedBox(height: 16),
              _buildLanguagesSelector(),
              const SizedBox(height: 32),

              _buildSectionHeader(
                'Organization Cut',
                'Enter your commission cut percentage',
              ),

              _buildModernTextField(
                controller: _commissionCutController,
                label: 'Organization Cut',
                icon: Icons.percent_outlined,
                fieldKey: 'commissionCut',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Allow digits and one decimal point
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,2})?$'),
                  ),
                  // Custom formatter to restrict to 0-100
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) return newValue;
                    final parsed = double.tryParse(newValue.text);
                    if (parsed == null) return oldValue;
                    if (parsed > 100)
                      return oldValue; // Prevent values over 100
                    return newValue;
                  }),
                ],
                validator: (value) {
                  // Validation is handled by provider on change
                  return formState.fieldErrors['commissionCut'];
                },
              ),

              // Health Section
              _buildSectionHeader(
                'Health Information',
                'Optional medical information',
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: _healthConditionsController,
                label: 'Health Conditions',
                icon: Icons.health_and_safety_outlined,
                fieldKey: 'healthConditions',
                optional: true,
                maxLines: 2,
                hintText: 'Any medical conditions or special needs',
              ),
              const SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    try {
      // If image already exists, remove it (toggle behavior)
      if (formState.profileImageFile != null) {
        notifier.setProfileImage(null);
        return;
      }

      // Pick new image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        notifier.setProfileImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileImageSection() {
    final formState = ref.watch(addHomelessFormNotifierProvider);

    // Determine what image to show
    Widget imageContent;
    bool hasImage =
        formState.profileImageFile != null ||
        (formState.existingProfilePictureUrl != null &&
            formState.existingProfilePictureUrl!.isNotEmpty);

    if (formState.profileImageFile != null) {
      // New image selected
      imageContent = ClipOval(
        child: Image.file(
          formState.profileImageFile!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.camera_alt,
              size: 50,
              color: AppTheme.primary.withValues(alpha: 0.6),
            );
          },
        ),
      );
    } else if (formState.existingProfilePictureUrl != null &&
        formState.existingProfilePictureUrl!.isNotEmpty) {
      // Existing image from server
      final imageUrl = _buildImageUrl(formState.existingProfilePictureUrl);
      imageContent = ClipOval(
        child: Image.network(
          imageUrl ?? '',
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(child: AppLoader());
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 50,
              color: AppTheme.primary.withValues(alpha: 0.6),
            );
          },
        ),
      );
    } else {
      // No image
      imageContent = Icon(
        Icons.camera_alt,
        size: 50,
        color: AppTheme.primary.withValues(alpha: 0.6),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImageFromGallery,
        child: Stack(
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.1),
                    AppTheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.01),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imageContent,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    final rotateAnim = Tween(begin: 0.75, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    );
                    final scaleAnim = Tween(begin: 0.6, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    );
                    return RotationTransition(
                      turns: rotateAnim,
                      child: ScaleTransition(scale: scaleAnim, child: child),
                    );
                  },
                  child: !hasImage
                      ? const Icon(
                          Icons.add,
                          key: ValueKey('add-icon'),
                          color: Colors.white,
                          size: 24,
                        )
                      : GestureDetector(
                          key: const ValueKey('edit-icon'),
                          onTap: () {
                            ref
                                .read(addHomelessFormNotifierProvider.notifier)
                                .resetProfilePicture();
                          },
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image URL for network images
  String? _buildImageUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }
    if (profilePicture.startsWith('http://') ||
        profilePicture.startsWith('https://')) {
      return profilePicture;
    } else if (profilePicture.startsWith('/')) {
      return '$baseUrl$profilePicture';
    } else {
      return '$baseUrl/$profilePicture';
    }
  }

  /// Display current age (for edit mode)
  Widget _buildAgeDisplay(int age) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.cake_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Text(
            'Current Age: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightSubText,
            ),
          ),
          Text(
            '$age years old',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightText,
            ),
          ),
        ],
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
    required String fieldKey,
    List<String>? autofillHints,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool optional = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    final hasError = formState.fieldErrors[fieldKey] != null;
    final isValid = formState.fieldValid[fieldKey] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          validator:
              validator ??
              (optional
                  ? null
                  : (value) {
                      // Validation is handled by provider on change
                      return formState.fieldErrors[fieldKey];
                    }),
          onChanged: (value) {
            // Update provider state
            switch (fieldKey) {
              case 'fullName':
                notifier.setFullName(value);
                break;
              case 'bio':
                notifier.setBio(value);
                break;
              case 'phone':
                notifier.setPhone(value);
                break;
              case 'email':
                notifier.setEmail(value);
                break;
              case 'address':
                notifier.setAddress(value);
                break;
              case 'city':
                notifier.setCity(value);
                break;
              case 'state':
                notifier.setStateValue(value);
                break;
              case 'zip':
                notifier.setZip(value);
                break;
              case 'country':
                notifier.setCountry(value);
                break;
              case 'username':
                notifier.setUsername(value);
                break;
              case 'password':
                notifier.setPassword(value);
                break;
              case 'confirmPassword':
                notifier.setConfirmPassword(value);
                break;
              case 'healthConditions':
                notifier.setHealthConditions(value);
                break;
              case 'experience':
                notifier.setExperience(value);
                break;
              case 'commissionCut':
                notifier.setCommissionCut(value);
                break;
            }
          },
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightText,
          ),
          decoration: InputDecoration(
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixIconTap,
                    icon: Icon(suffixIcon, color: AppTheme.primary, size: 20),
                  )
                : null,
            labelText: label + (optional ? ' (Optional)' : ''),
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? Colors.red
                  : isValid
                  ? AppTheme.primary
                  : AppTheme.lightSubText,
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),

            isDense: false,
            floatingLabelAlignment: FloatingLabelAlignment.start,
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: hasError
                  ? Colors.red
                  : isValid
                  ? AppTheme.primary
                  : AppTheme.lightSubText,
            ),
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            floatingLabelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: hasError
                  ? Colors.red
                  : isValid
                  ? AppTheme.primary
                  : AppTheme.primary,
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red
                    : isValid
                    ? AppTheme.primary
                    : Colors.grey.shade300,
                width: hasError || isValid ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: hasError
                    ? Colors.red
                    : isValid
                    ? AppTheme.primary
                    : Colors.grey.shade300,
                width: hasError || isValid ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.primary,
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
          ),
        ),
        if (formState.fieldErrors[fieldKey] != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    formState.fieldErrors[fieldKey]!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }

  Future<void> _selectDateOfBirth() async {
    final formState = ref.read(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          formState.selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.lightText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      notifier.setDateOfBirth(formattedDate, picked);
    }
  }

  Widget _buildDateOfBirthField() {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final hasError = formState.fieldErrors['dob'] != null;
    final isValid = formState.fieldValid['dob'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(12.0),
          child: TextFormField(
            controller: _dobController,
            enabled: false,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightText,
            ),
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: hasError
                    ? Colors.red
                    : isValid
                    ? AppTheme.primary
                    : AppTheme.lightSubText,
                size: 22,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              isDense: false,
              floatingLabelAlignment: FloatingLabelAlignment.start,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasError
                    ? Colors.red
                    : isValid
                    ? AppTheme.primary
                    : AppTheme.lightSubText,
              ),
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              floatingLabelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: hasError
                    ? Colors.red
                    : isValid
                    ? AppTheme.primary
                    : AppTheme.primary,
              ),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : isValid
                      ? AppTheme.primary
                      : Colors.grey.shade300,
                  width: hasError || isValid ? 1.5 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : isValid
                      ? AppTheme.primary
                      : Colors.grey.shade300,
                  width: hasError || isValid ? 1.5 : 1,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : isValid
                      ? AppTheme.primary
                      : Colors.grey.shade300,
                  width: hasError || isValid ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : AppTheme.primary,
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
            ),
            validator: (value) {
              // Validation is handled by provider
              return formState.fieldErrors['dob'];
            },
          ),
        ),
        if (formState.fieldErrors['dob'] != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  formState.fieldErrors['dob']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightSubText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderChip('Male', Icons.male)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderChip('Female', Icons.female)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip(String gender, IconData icon) {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);
    final isSelected = formState.gender == gender;
    return GestureDetector(
      onTap: () => notifier.setGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.01)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.lightSubText,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSelector() {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: AddHomelessFormState.skills.map((skill) {
        final isSelected = formState.selectedSkills.contains(skill);
        return FilterChip(
          label: Text(
            skill,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.lightText,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            notifier.toggleSkill(skill);
          },
          selectedColor: AppTheme.primary,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 2 : 0,
          shadowColor: AppTheme.primary.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildLanguagesSelector() {
    final formState = ref.watch(addHomelessFormNotifierProvider);
    final notifier = ref.read(addHomelessFormNotifierProvider.notifier);

    return Wrap(
      spacing: 6,
      runSpacing: -6,
      children: AddHomelessFormState.languages.map((language) {
        final isSelected = formState.selectedLanguages.contains(language);
        return FilterChip(
          label: Text(
            language,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.lightText,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            notifier.toggleLanguage(language);
          },
          selectedColor: AppTheme.secondary,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppTheme.secondary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isSelected ? 2 : 0,
          shadowColor: AppTheme.secondary.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    print("object");
    final formState = ref.watch(addHomelessFormNotifierProvider);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEditMode
              ? [AppTheme.secondary, AppTheme.secondary.withValues(alpha: 0.8)]
              : [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isEditMode ? AppTheme.secondary : AppTheme.primary)
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: formState.isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: formState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isEditMode ? 'Update' : 'Submit',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

class UsPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    if (digits.length > 10) {
      return oldValue;
    }

    String formatted = _formatNumber(digits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String digits) {
    if (digits.isEmpty) return '';

    if (digits.length <= 3) {
      return '($digits';
    } else if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      return '(${digits.substring(0, 3)}) '
          '${digits.substring(3, 6)}-'
          '${digits.substring(6)}';
    }
  }
}
