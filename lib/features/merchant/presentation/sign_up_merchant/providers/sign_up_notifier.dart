import 'package:flutter_riverpod/legacy.dart';
import '../../../data/models/myprofile/myprofile_model.dart';

class SignUpState {
  final int currentStep;
  final bool isAgreed;

  // Edit Mode
  final bool isEditMode;
  final String? merchantId;

  // Step 0: Business Information
  final String businessName;
  final String businessEmail;
  final String phoneNumber;
  final String businessType;
  final String password;
  final String confirmPassword;

  // Step 1: Address & Contact Information
  final String streetAddress;
  final String city;
  final String state;
  final String contactPersonName;
  final String contactPersonDesignation;

  // Step 2: Verification Documents
  final String? gstCertificatePath;
  final String? gstCertificateName;
  final String? businessLicensePath;
  final String? businessLicenseName;
  final String? photoIdPath;
  final String? photoIdName;

  SignUpState({
    this.currentStep = 0,
    this.isAgreed = true,
    this.isEditMode = false,
    this.merchantId,
    this.businessName = '',
    this.businessEmail = '',
    this.phoneNumber = '',
    this.businessType = '',
    this.password = '',
    this.confirmPassword = '',
    this.streetAddress = '',
    this.city = '',
    this.state = '',
    this.contactPersonName = '',
    this.contactPersonDesignation = '',
    this.gstCertificatePath,
    this.gstCertificateName,
    this.businessLicensePath,
    this.businessLicenseName,
    this.photoIdPath,
    this.photoIdName,
  });

  SignUpState copyWith({
    int? currentStep,
    bool? isAgreed,
    bool? isEditMode,
    String? merchantId,
    String? businessName,
    String? businessEmail,
    String? phoneNumber,
    String? businessType,
    String? password,
    String? confirmPassword,
    String? streetAddress,
    String? city,
    String? state,
    String? contactPersonName,
    String? contactPersonDesignation,
    String? gstCertificatePath,
    String? gstCertificateName,
    String? businessLicensePath,
    String? businessLicenseName,
    String? photoIdPath,
    String? photoIdName,
  }) {
    return SignUpState(
      currentStep: currentStep ?? this.currentStep,
      isAgreed: isAgreed ?? this.isAgreed,
      isEditMode: isEditMode ?? this.isEditMode,
      merchantId: merchantId ?? this.merchantId,
      businessName: businessName ?? this.businessName,
      businessEmail: businessEmail ?? this.businessEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      businessType: businessType ?? this.businessType,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      contactPersonDesignation:
          contactPersonDesignation ?? this.contactPersonDesignation,
      gstCertificatePath: gstCertificatePath ?? this.gstCertificatePath,
      gstCertificateName: gstCertificateName ?? this.gstCertificateName,
      businessLicensePath: businessLicensePath ?? this.businessLicensePath,
      businessLicenseName: businessLicenseName ?? this.businessLicenseName,
      photoIdPath: photoIdPath ?? this.photoIdPath,
      photoIdName: photoIdName ?? this.photoIdName,
    );
  }
}

class SignUpNotifier extends StateNotifier<SignUpState> {
  SignUpNotifier() : super(SignUpState());

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setIsAgreed(bool value) {
    state = state.copyWith(isAgreed: value);
  }

  // Step 0: Business Information
  void setBusinessName(String value) {
    state = state.copyWith(businessName: value);
  }

  void setBusinessEmail(String value) {
    state = state.copyWith(businessEmail: value);
  }

  void setPhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  void setBusinessType(String value) {
    state = state.copyWith(businessType: value);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  // Step 1: Address & Contact Information
  void setStreetAddress(String value) {
    state = state.copyWith(streetAddress: value);
  }

  void setCity(String value) {
    state = state.copyWith(city: value);
  }

  void setStateValue(String value) {
    state = state.copyWith(state: value);
  }

  void setContactPersonName(String value) {
    state = state.copyWith(contactPersonName: value);
  }

  void setContactPersonDesignation(String value) {
    state = state.copyWith(contactPersonDesignation: value);
  }

  // Step 2: Verification Documents
  void setGstCertificate(String? path, String? name) {
    state = state.copyWith(gstCertificatePath: path, gstCertificateName: name);
  }

  void setBusinessLicense(String? path, String? name) {
    state = state.copyWith(
      businessLicensePath: path,
      businessLicenseName: name,
    );
  }

  void setPhotoId(String? path, String? name) {
    state = state.copyWith(photoIdPath: path, photoIdName: name);
  }

  /// Update state from draft data
  void updateFromDraft(Map<String, dynamic> draftData) {
    state = state.copyWith(
      businessName: draftData['businessName'] ?? state.businessName,
      businessEmail: draftData['businessEmail'] ?? state.businessEmail,
      phoneNumber: draftData['phoneNumber'] ?? state.phoneNumber,
      businessType: draftData['businessType'] ?? state.businessType,
      password: draftData['password'] ?? state.password,
      confirmPassword:
          draftData['confirmPassword'] ??
          draftData['password'] ??
          state.confirmPassword,
      streetAddress:
          draftData['streetAddress'] ??
          draftData['address'] ??
          state.streetAddress,
      city: draftData['city'] ?? state.city,
      state: draftData['state'] ?? state.state,
      contactPersonName:
          draftData['contactPersonName'] ?? state.contactPersonName,
      contactPersonDesignation:
          draftData['contactPersonDesignation'] ??
          state.contactPersonDesignation,
      gstCertificatePath:
          draftData['gstCertificatePath'] ?? state.gstCertificatePath,
      gstCertificateName:
          draftData['gstCertificateName'] ?? state.gstCertificateName,
      businessLicensePath:
          draftData['businessLicensePath'] ?? state.businessLicensePath,
      businessLicenseName:
          draftData['businessLicenseName'] ?? state.businessLicenseName,
      photoIdPath: draftData['photoIdPath'] ?? state.photoIdPath,
      photoIdName: draftData['photoIdName'] ?? state.photoIdName,
    );
  }

  /// Load form data from existing merchant model (for edit mode)
  void loadFromMerchant(MyProfileModel merchant) {
    state = SignUpState(
      isEditMode: true,
      merchantId: merchant.id,
      businessName: merchant.businessName,
      businessEmail: merchant.businessEmail,
      phoneNumber: merchant.phoneNumber,
      businessType: merchant.businessType,
      streetAddress: merchant.streetAddress,
      city: merchant.city,
      state: merchant.state,
      contactPersonName: merchant.contactPersonName,
      contactPersonDesignation: merchant.contactDesignation,
      // Don't load password in edit mode
      password: '',
      confirmPassword: '',
      // Keep existing document paths if available (they're URLs, not local paths)
      // These will be handled separately in the UI
    );
  }

  /// Reset state to initial values
  void reset() {
    state = SignUpState();
  }
}

final signUpNotifierProvider =
    StateNotifierProvider<SignUpNotifier, SignUpState>((ref) {
      return SignUpNotifier();
    });
