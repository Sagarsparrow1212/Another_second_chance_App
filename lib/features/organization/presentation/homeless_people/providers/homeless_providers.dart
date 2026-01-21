import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import '../../../data/datasources/homeless_people/homeless_remote_datasource.dart';
import '../../../data/repositories/homeless_people/homeless_repository_impl.dart';
import '../../../data/models/homeless_people/homeless_model.dart';

// Dio provider
final homelessDioProvider = Provider((ref) => Dio());

// Datasource provider
final homelessRemoteDatasourceProvider = Provider(
  (ref) => HomelessRemoteDatasource(ref.watch(homelessDioProvider)),
);

// Repository provider
final homelessRepositoryProvider = Provider(
  (ref) => HomelessRepositoryImpl(ref.watch(homelessRemoteDatasourceProvider)),
);

// Parameter class for homeless list provider (with proper equality)
class HomelessListParams {
  final String organizationId;

  HomelessListParams({required this.organizationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomelessListParams &&
          runtimeType == other.runtimeType &&
          organizationId == other.organizationId;

  @override
  int get hashCode => organizationId.hashCode;
}

// Homeless list provider (takes organizationId only, filtering is done locally)
final homelessListProvider =
    FutureProvider.family<HomelessListResponse, HomelessListParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(homelessRepositoryProvider);

      return await repository.getHomelessByOrganization(params.organizationId);
    });

// Provider to fetch a single homeless person by ID with full details
final homelessDetailProvider =
    FutureProvider.family<HomelessDetailResponse, String>((
      ref,
      homelessId,
    ) async {
      final repository = ref.watch(homelessRepositoryProvider);
      return await repository.getHomelessById(homelessId);
    });

// Helper provider to get organization ID
final organizationIdProvider = FutureProvider<String?>((ref) async {
  try {
    final organizationBox = await Hive.openBox('organizationBox');
    final organizationId = organizationBox.get('organizationId')?.toString();
    return organizationId;
  } catch (e) {
    print('Error getting organization ID: $e');
    return null;
  }
});

// ==================== Add Homeless Form State Management ====================

/// Form state model holding all form values, errors, and loading state
class AddHomelessFormState {
  // Edit Mode
  final bool isEditMode;
  final String? homelessId;
  final String? existingProfilePictureUrl;
  final bool? isChangePassewordSuffix;
  final bool? isChangeConfirmPassewordSuffix;
  // Form Values
  final String fullName;
  final String dateOfBirth;
  final DateTime? selectedDateOfBirth;
  final int? directAge; // For edit mode when we have age directly
  final String gender;
  final String bio;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String username;
  final String password;
  final String confirmPassword;
  final List<String> selectedSkills;
  final String healthConditions;
  final String experience;
  final String commissionCut;
  final List<String> selectedLanguages;
  final File? profileImageFile;

  // Validation State
  final Map<String, String?> fieldErrors;
  final Map<String, bool> fieldValid;

  // UI State
  final bool isLoading;
  final String? submitError;
  final bool isSuccess;

  // Skills list (static)
  static const List<String> skills = [
    "General Labor",
    "Cleaning / Housekeeping",
    "Driving / Delivery",
    "Construction Helper",
    "Warehouse Work",
    "Landscaping / Gardening",
    "Retail Helper",
    "Kitchen / Cooking Help",
    "Painting",
    "Maintenance Helper",
    "Pet Care",
    "Other",
  ];

  // Languages list (static)
  static const List<String> languages = [
    "English",
    "Spanish",
    "French",
    "German",
    "Chinese",
    "Hindi",
    "Arabic",
    "Portuguese",
    "Russian",
    "Japanese",
    "Korean",
    "Other",
  ];

  AddHomelessFormState({
    this.isEditMode = false,
    this.homelessId,
    this.existingProfilePictureUrl,
    this.fullName = '',
    this.dateOfBirth = '',
    this.selectedDateOfBirth,
    this.directAge,
    this.gender = 'Male',
    this.bio = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.country = '',
    this.username = '',
    this.password = '',
    this.confirmPassword = '',
    List<String>? selectedSkills,
    this.healthConditions = '',
    this.experience = '',
    this.commissionCut = '',
    List<String>? selectedLanguages,
    this.profileImageFile,
    Map<String, String?>? fieldErrors,
    Map<String, bool>? fieldValid,
    this.isLoading = false,
    this.isChangePassewordSuffix = false,
    this.isChangeConfirmPassewordSuffix = false,
    this.submitError,
    this.isSuccess = false,
  }) : selectedSkills = selectedSkills ?? [],
       selectedLanguages = selectedLanguages ?? [],
       fieldErrors = fieldErrors ?? {},
       fieldValid = fieldValid ?? {};

  /// Calculate age from date of birth or use direct age
  int? get age {
    // If we have a direct age (from edit mode), use it
    if (directAge != null) return directAge;
    // Otherwise calculate from DOB
    if (selectedDateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - selectedDateOfBirth!.year;
    if (now.month < selectedDateOfBirth!.month ||
        (now.month == selectedDateOfBirth!.month &&
            now.day < selectedDateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  /// Get location string (city, state format)
  String get location {
    if (city.isEmpty && state.isEmpty) return '';
    if (city.isEmpty) return state;
    if (state.isEmpty) return city;
    return '$city, $state';
  }

  AddHomelessFormState copyWith({
    bool? isEditMode,
    String? homelessId,
    String? existingProfilePictureUrl,
    bool clearExistingProfilePicture = false,
    String? fullName,
    bool? isChangePassewordSuffix,
    bool? isChangeConfirmPassewordSuffix,

    String? dateOfBirth,
    DateTime? selectedDateOfBirth,
    bool clearSelectedDateOfBirth = false,
    int? directAge,
    bool clearDirectAge = false,
    String? gender,
    String? bio,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? country,
    String? username,
    String? password,
    String? confirmPassword,
    List<String>? selectedSkills,
    String? healthConditions,
    String? experience,
    String? commissionCut,
    List<String>? selectedLanguages,
    File? profileImageFile,
    bool clearProfileImage = false,
    Map<String, String?>? fieldErrors,
    Map<String, bool>? fieldValid,
    bool? isLoading,
    String? Function()? submitError,
    bool? isSuccess,
  }) {
    return AddHomelessFormState(
      isEditMode: isEditMode ?? this.isEditMode,
      homelessId: homelessId ?? this.homelessId,
      existingProfilePictureUrl: clearExistingProfilePicture
          ? null
          : (existingProfilePictureUrl ?? this.existingProfilePictureUrl),
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      selectedDateOfBirth: clearSelectedDateOfBirth
          ? null
          : (selectedDateOfBirth ?? this.selectedDateOfBirth),
      directAge: clearDirectAge ? null : (directAge ?? this.directAge),
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      isChangePassewordSuffix:
          isChangePassewordSuffix ?? this.isChangePassewordSuffix,
      isChangeConfirmPassewordSuffix:
          isChangeConfirmPassewordSuffix ?? this.isChangeConfirmPassewordSuffix,
      country: country ?? this.country,
      username: username ?? this.username,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      healthConditions: healthConditions ?? this.healthConditions,
      experience: experience ?? this.experience,
      commissionCut: commissionCut ?? this.commissionCut,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      profileImageFile: clearProfileImage
          ? null
          : (profileImageFile ?? this.profileImageFile),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      fieldValid: fieldValid ?? this.fieldValid,
      isLoading: isLoading ?? this.isLoading,
      submitError: submitError != null ? submitError() : this.submitError,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Check if form is valid
  bool get isValid {
    final noErrors = fieldErrors.values.every((error) => error == null);
    final hasRequiredFields =
        fullName.isNotEmpty && email.isNotEmpty && phone.isNotEmpty;

    if (isEditMode) {
      // In edit mode, password and username are not required
      // DOB can be skipped if we have directAge
      return noErrors &&
          hasRequiredFields &&
          (dateOfBirth.isNotEmpty || directAge != null);
    }

    // In create mode, all fields including password are required
    return noErrors &&
        hasRequiredFields &&
        dateOfBirth.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddHomelessFormState &&
          runtimeType == other.runtimeType &&
          isEditMode == other.isEditMode &&
          homelessId == other.homelessId &&
          existingProfilePictureUrl == other.existingProfilePictureUrl &&
          fullName == other.fullName &&
          dateOfBirth == other.dateOfBirth &&
          selectedDateOfBirth == other.selectedDateOfBirth &&
          directAge == other.directAge &&
          gender == other.gender &&
          bio == other.bio &&
          phone == other.phone &&
          email == other.email &&
          address == other.address &&
          city == other.city &&
          state == other.state &&
          zip == other.zip &&
          country == other.country &&
          username == other.username &&
          password == other.password &&
          confirmPassword == other.confirmPassword &&
          _listEquals(selectedSkills, other.selectedSkills) &&
          healthConditions == other.healthConditions &&
          experience == other.experience &&
          _listEquals(selectedLanguages, other.selectedLanguages) &&
          profileImageFile == other.profileImageFile &&
          _mapEquals(fieldErrors, other.fieldErrors) &&
          _mapEqualsBool(fieldValid, other.fieldValid) &&
          isLoading == other.isLoading &&
          submitError == other.submitError &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode =>
      isEditMode.hashCode ^
      (homelessId?.hashCode ?? 0) ^
      (existingProfilePictureUrl?.hashCode ?? 0) ^
      fullName.hashCode ^
      dateOfBirth.hashCode ^
      (selectedDateOfBirth?.hashCode ?? 0) ^
      (directAge?.hashCode ?? 0) ^
      gender.hashCode ^
      bio.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      address.hashCode ^
      city.hashCode ^
      state.hashCode ^
      zip.hashCode ^
      country.hashCode ^
      username.hashCode ^
      password.hashCode ^
      confirmPassword.hashCode ^
      selectedSkills.hashCode ^
      healthConditions.hashCode ^
      experience.hashCode ^
      selectedLanguages.hashCode ^
      (profileImageFile?.hashCode ?? 0) ^
      fieldErrors.hashCode ^
      fieldValid.hashCode ^
      isLoading.hashCode ^
      (submitError?.hashCode ?? 0) ^
      isSuccess.hashCode;

  // Helper methods for deep equality
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  bool _mapEqualsBool<K>(Map<K, bool>? a, Map<K, bool>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// StateNotifier for managing add homeless form state
class AddHomelessFormNotifier extends StateNotifier<AddHomelessFormState> {
  AddHomelessFormNotifier() : super(AddHomelessFormState());

  /// Load form data from existing homeless model (for edit mode)
  void loadFromHomeless(HomelessModel homeless) {
    // Parse location into city and state
    String city = '';
    String stateValue = '';
    if (homeless.location != null && homeless.location!.isNotEmpty) {
      final parts = homeless.location!.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) city = parts[0];
      if (parts.length > 1) stateValue = parts[1];
    }

    state = AddHomelessFormState(
      isEditMode: true,
      homelessId: homeless.id,
      existingProfilePictureUrl: homeless.profilePicture,
      fullName: homeless.fullName ?? homeless.name ?? '',
      directAge: homeless.age,
      gender: homeless.gender ?? 'Male',
      bio: homeless.bio ?? '',
      phone: homeless.contactPhone ?? homeless.phone ?? '',
      email: homeless.contactEmail ?? homeless.email ?? '',
      address: homeless.address ?? '',
      city: city,
      state: stateValue,
      username: homeless.username ?? '',
      selectedSkills: homeless.skillset ?? homeless.skills ?? [],
      healthConditions: homeless.healthConditions ?? '',
      experience: homeless.experience ?? '',
      selectedLanguages: homeless.languages ?? [],
    );
  }

  /// Set direct age (for edit mode)
  void setDirectAge(int? age) {
    state = state.copyWith(directAge: age, clearDirectAge: age == null);
  }

  /// Update field value and validate
  void updateField(String field, String value) {
    final updatedErrors = Map<String, String?>.from(state.fieldErrors);
    final updatedValid = Map<String, bool>.from(state.fieldValid);

    _validateField(field, value, updatedErrors, updatedValid);

    state = state.copyWith(
      fieldErrors: updatedErrors,
      fieldValid: updatedValid,
    );
  }

  /// Validate a single field
  void _validateField(
    String field,
    String value,
    Map<String, String?> errors,
    Map<String, bool> valid,
  ) {
    switch (field) {
      case 'email':
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (value.isEmpty) {
          errors[field] = 'Email is required';
          valid[field] = false;
        } else if (!emailRegex.hasMatch(value)) {
          errors[field] = 'Please enter a valid email';
          valid[field] = false;
        } else {
          errors[field] = null;
          valid[field] = true;
        }
        // Re-validate confirm password if password changed
        if (state.password.isNotEmpty) {
          _validateField(
            'confirmPassword',
            state.confirmPassword,
            errors,
            valid,
          );
        }
        break;

      case 'password':
        if (value.isEmpty) {
          errors[field] = 'Password is required';
          valid[field] = false;
        } else if (value.length < 6) {
          errors[field] = 'Password must be at least 6 characters';
          valid[field] = false;
        } else {
          errors[field] = null;
          valid[field] = true;
        }
        // Re-validate confirm password
        if (state.confirmPassword.isNotEmpty) {
          _validateField(
            'confirmPassword',
            state.confirmPassword,
            errors,
            valid,
          );
        }
        break;

      case 'confirmPassword':
        if (value.isEmpty) {
          errors[field] = 'Please confirm your password';
          valid[field] = false;
        } else if (value != state.password) {
          errors[field] = 'Passwords do not match';
          valid[field] = false;
        } else {
          errors[field] = null;
          valid[field] = true;
        }
        break;

      case 'phone':
        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

        if (value.isNotEmpty && digitsOnly.length != 10) {
          errors[field] = 'Please enter a valid 10-digit phone number';
          valid[field] = false;
        } else {
          errors[field] = null;
          valid[field] = value.isNotEmpty;
        }
        break;

      case 'username':
        final trimmedValue = value.trim();
        if (trimmedValue.isEmpty) {
          errors[field] = 'Username is required';
          valid[field] = false;
        } else if (trimmedValue.length < 3) {
          errors[field] = 'Username must be at least 3 characters';
          valid[field] = false;
        } else if (trimmedValue.length > 30) {
          errors[field] = 'Username must be at most 30 characters';
          valid[field] = false;
        } else {
          // Check if all digits
          if (RegExp(r'^[0-9]+$').hasMatch(trimmedValue)) {
            errors[field] = 'Username cannot be all digits';
            valid[field] = false;
          }
          // Check if starts or ends with dot
          else if (trimmedValue.startsWith('.') || trimmedValue.endsWith('.')) {
            errors[field] = 'Username cannot start or end with a dot';
            valid[field] = false;
          }
          // Check for consecutive dots
          else if (trimmedValue.contains('..')) {
            errors[field] = 'Username cannot have consecutive dots';
            valid[field] = false;
          }
          // Check allowed characters
          else if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(trimmedValue)) {
            errors[field] =
                'Username can only contain letters, numbers, dots, and underscores';
            valid[field] = false;
          } else {
            // All validations passed
            errors[field] = null;
            valid[field] = true;
          }
        }
        break;

      case 'commissionCut':
        if (value.isEmpty) {
          errors[field] = 'Commission Cut is required';
          valid[field] = false;
        } else {
          // Try to parse as double
          final parsedValue = double.tryParse(value);
          if (parsedValue == null) {
            errors[field] = 'Please enter a valid number';
            valid[field] = false;
          } else if (parsedValue < 0 || parsedValue > 100) {
            errors[field] = 'Commission Cut must be between 0 and 100';
            valid[field] = false;
          } else {
            errors[field] = null;
            valid[field] = true;
          }
        }
        break;

      default:
        if (value.isEmpty && field != 'healthConditions' && field != 'bio') {
          errors[field] = 'This field is required';
          valid[field] = false;
        } else {
          errors[field] = null;
          valid[field] = value.isNotEmpty;
        }
    }
  }

  /// Set field value directly (for controlled updates)
  void setFullName(String value) {
    state = state.copyWith(fullName: value);
    updateField('fullName', value);
  }

  void setDateOfBirth(String value, DateTime? selectedDate) {
    final updatedErrors = Map<String, String?>.from(state.fieldErrors);
    final updatedValid = Map<String, bool>.from(state.fieldValid);
    updatedErrors['dob'] = null;
    updatedValid['dob'] = true;

    state = state.copyWith(
      dateOfBirth: value,
      selectedDateOfBirth: selectedDate,
      fieldErrors: updatedErrors,
      fieldValid: updatedValid,
    );
  }

  void setGender(String value) {
    state = state.copyWith(gender: value);
  }

  void setBio(String value) {
    state = state.copyWith(bio: value);
    updateField('bio', value);
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value);
    updateField('phone', value);
  }

  void setPassWordSuffixChange(bool value) {
    state = state.copyWith(isChangePassewordSuffix: value);
  }

  void setConfirmPasswordSuffixChange(bool value) {
    state = state.copyWith(isChangeConfirmPassewordSuffix: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
    updateField('email', value);
  }

  void setAddress(String value) {
    state = state.copyWith(address: value);
    updateField('address', value);
  }

  void setCity(String value) {
    state = state.copyWith(city: value);
    updateField('city', value);
  }

  void setStateValue(String value) {
    state = state.copyWith(state: value);
    updateField('state', value);
  }

  void setZip(String value) {
    state = state.copyWith(zip: value);
    updateField('zip', value);
  }

  void setCountry(String value) {
    state = state.copyWith(country: value);
    updateField('country', value);
  }

  void setUsername(String value) {
    // Trim the value before storing and validating
    final trimmedValue = value.trim();
    state = state.copyWith(username: trimmedValue);
    updateField('username', trimmedValue);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
    updateField('password', value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
    updateField('confirmPassword', value);
  }

  void setHealthConditions(String value) {
    state = state.copyWith(healthConditions: value);
    updateField('healthConditions', value);
  }

  void setExperience(String value) {
    state = state.copyWith(experience: value);
    updateField('experience', value);
  }

  void setCommissionCut(String value) {
    state = state.copyWith(commissionCut: value);
    updateField('commissionCut', value);
  }

  void toggleSkill(String skill) {
    final updatedSkills = List<String>.from(state.selectedSkills);
    if (updatedSkills.contains(skill)) {
      updatedSkills.remove(skill);
    } else {
      updatedSkills.add(skill);
    }
    state = state.copyWith(selectedSkills: updatedSkills);
  }

  void toggleLanguage(String language) {
    final updatedLanguages = List<String>.from(state.selectedLanguages);
    if (updatedLanguages.contains(language)) {
      updatedLanguages.remove(language);
    } else {
      updatedLanguages.add(language);
    }
    state = state.copyWith(selectedLanguages: updatedLanguages);
  }

  void setProfileImage(File? file) {
    state = state.copyWith(profileImageFile: file);
  }

  /// Validate all fields
  void validateAll() {
    final updatedErrors = <String, String?>{};
    final updatedValid = <String, bool>{};

    _validateField('fullName', state.fullName, updatedErrors, updatedValid);
    _validateField('email', state.email, updatedErrors, updatedValid);
    _validateField('phone', state.phone, updatedErrors, updatedValid);
    _validateField(
      'commissionCut',
      state.commissionCut,
      updatedErrors,
      updatedValid,
    );

    if (state.isEditMode) {
      // In edit mode, DOB is optional if we already have age
      if (state.directAge == null && state.dateOfBirth.isEmpty) {
        _validateField('dob', state.dateOfBirth, updatedErrors, updatedValid);
      } else {
        updatedErrors['dob'] = null;
        updatedValid['dob'] = true;
      }
      // Username and password are optional in edit mode
      updatedErrors['username'] = null;
      updatedValid['username'] = true;
      updatedErrors['password'] = null;
      updatedValid['password'] = true;
      updatedErrors['confirmPassword'] = null;
      updatedValid['confirmPassword'] = true;
    } else {
      // In create mode, validate all required fields
      _validateField('dob', state.dateOfBirth, updatedErrors, updatedValid);
      _validateField('username', state.username, updatedErrors, updatedValid);
      _validateField('password', state.password, updatedErrors, updatedValid);
      _validateField(
        'confirmPassword',
        state.confirmPassword,
        updatedErrors,
        updatedValid,
      );
    }

    state = state.copyWith(
      fieldErrors: updatedErrors,
      fieldValid: updatedValid,
    );
  }

  /// Validate for edit mode (less strict)
  void validateForEdit() {
    final updatedErrors = <String, String?>{};
    final updatedValid = <String, bool>{};

    _validateField('fullName', state.fullName, updatedErrors, updatedValid);
    _validateField('email', state.email, updatedErrors, updatedValid);
    _validateField('phone', state.phone, updatedErrors, updatedValid);

    state = state.copyWith(
      fieldErrors: updatedErrors,
      fieldValid: updatedValid,
    );
  }

  /// Reset form state
  void reset() {
    state = AddHomelessFormState();
  }

  /// Reset only the profile picture, keeping all other form data
  void resetProfilePicture() {
    state = state.copyWith(clearProfileImage: true);
  }

  /// Submit form with API call (create new homeless)
  Future<void> submit(String organizationId) async {
    validateAll();

    if (!state.isValid) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      submitError: () => null,
      isSuccess: false,
    );

    try {
      final dio = Dio();
      final datasource = HomelessRemoteDatasource(dio);

      // Get organization's default commission if form field is empty
      String commissionCutToUse = state.commissionCut;
      if (commissionCutToUse.isEmpty) {
        try {
          // Try to get commission from raw API response
          final secureStorage = FlutterSecureStorage();
          final token = await secureStorage.read(key: 'token');
          if (token == null || token.isEmpty) {
            throw Exception('Authentication token not found');
          }

          final orgResponse = await dio.get(
            '$apiBaseUrl/organizations/me',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
          final orgData =
              orgResponse.data is Map<String, dynamic> &&
                  orgResponse.data.containsKey('data')
              ? orgResponse.data['data']
              : orgResponse.data;
          commissionCutToUse =
              orgData['commissionCut']?.toString() ??
              orgData['defaultCommissionCut']?.toString() ??
              '';

          if (commissionCutToUse.isEmpty) {
            throw Exception(
              'Organization default commission is not configured. Please set it in your organization profile.',
            );
          }
        } catch (e) {
          // If we can't get organization commission, throw error
          state = state.copyWith(
            isLoading: false,
            submitError: () => e.toString().contains('default commission')
                ? e.toString()
                : 'Organization default commission is not configured. Please set it in your organization profile.',
          );
          return;
        }
      }

      await datasource.registerHomeless(
        username: state.username,
        password: state.password,
        fullName: state.fullName,
        age: state.age ?? 0,
        gender: state.gender,
        skillset: state.selectedSkills,
        experience: state.experience,
        location: state.location,
        address: state.address,
        contactPhone: state.phone,
        contactEmail: state.email,
        bio: state.bio,
        languages: state.selectedLanguages,
        healthConditions: state.healthConditions,
        organizationId: organizationId,
        organizationCutPercentage: commissionCutToUse,
        profilePicture: state.profileImageFile,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      state = state.copyWith(isLoading: false, submitError: () => msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, submitError: () => e.toString());
    }
  }

  /// Update existing homeless person
  Future<void> update(String token) async {
    validateAll();

    if (!state.isValid || state.homelessId == null) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      submitError: () => null,
      isSuccess: false,
    );

    try {
      final dio = Dio();
      final datasource = HomelessRemoteDatasource(dio);

      await datasource.updateHomeless(
        homelessId: state.homelessId!,
        token: token,
        fullName: state.fullName,
        age: state.age,
        gender: state.gender,
        skillset: state.selectedSkills,
        experience: state.experience,
        location: state.location,
        address: state.address,
        contactPhone: state.phone,
        contactEmail: state.email,
        bio: state.bio,
        languages: state.selectedLanguages,
        organizationCutPercentage: state.commissionCut,

        healthConditions: state.healthConditions,
        profilePicture: state.profileImageFile,
      );

      state = state.copyWith(isLoading: false, isSuccess: true);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Something went wrong';
      state = state.copyWith(isLoading: false, submitError: () => msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, submitError: () => e.toString());
    }
  }
}

/// Provider for add homeless form notifier
final addHomelessFormNotifierProvider =
    StateNotifierProvider<AddHomelessFormNotifier, AddHomelessFormState>((ref) {
      return AddHomelessFormNotifier();
    });
