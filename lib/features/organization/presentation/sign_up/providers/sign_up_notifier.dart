import 'package:flutter_riverpod/legacy.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';

class SignUpState {
  final int currentStep;
  final bool isAgreed;

  // Edit Mode
  final bool isEditMode;
  final String? organizationId;

  // Step 0: Organisation Details
  final String organisationName;
  final String organisationType;
  final String email;
  final String contactPersonName;
  final String primaryPhoneNumber;
  final String contactEmail;
  final String password;
  final String confirmPassword;
  //Commission Cut (%)
  final String commissionCut;
  // Step 1: Address Details
  final String streetAddress;
  final String city;

  final String state;
  final String zipCode;
  final String country;

  SignUpState({
    this.currentStep = 0,
    this.isAgreed = false,
    this.isEditMode = false,
    this.organizationId,
    this.organisationName = '',
    this.organisationType = '',
    this.commissionCut = '',
    this.email = '',
    this.contactPersonName = '',
    this.primaryPhoneNumber = '',
    this.contactEmail = '',
    this.password = '',
    this.confirmPassword = '',
    this.streetAddress = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
  });

  SignUpState copyWith({
    int? currentStep,
    bool? isAgreed,
    bool? isEditMode,
    String? organizationId,
    String? organisationName,
    String? organisationType,
    String? email,
    String? contactPersonName,
    String? primaryPhoneNumber,
    String? contactEmail,
    String? password,
    String? confirmPassword,
    String? commissionCut,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) {
    return SignUpState(
      currentStep: currentStep ?? this.currentStep,
      isAgreed: isAgreed ?? this.isAgreed,
      isEditMode: isEditMode ?? this.isEditMode,
      organizationId: organizationId ?? this.organizationId,
      organisationName: organisationName ?? this.organisationName,
      organisationType: organisationType ?? this.organisationType,
      commissionCut: commissionCut ?? this.commissionCut,
      email: email ?? this.email,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      primaryPhoneNumber: primaryPhoneNumber ?? this.primaryPhoneNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
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

  void setCommissionCut(String value) {
    state = state.copyWith(commissionCut: value);
  }

  // Step 0: Organisation Details
  void setOrganisationName(String value) {
    state = state.copyWith(organisationName: value);
  }

  void setOrganisationType(String value) {
    state = state.copyWith(organisationType: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
  }

  void setContactPersonName(String value) {
    state = state.copyWith(contactPersonName: value);
  }

  void setPrimaryPhoneNumber(String value) {
    state = state.copyWith(primaryPhoneNumber: value);
  }

  void setContactEmail(String value) {
    state = state.copyWith(contactEmail: value);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value);
  }

  // Step 1: Address Details
  void setStreetAddress(String value) {
    state = state.copyWith(streetAddress: value);
  }

  void setCity(String value) {
    state = state.copyWith(city: value);
  }

  void setStateValue(String value) {
    state = state.copyWith(state: value);
  }

  void setZipCode(String value) {
    state = state.copyWith(zipCode: value);
  }

  void setCountry(String value) {
    state = state.copyWith(country: value);
  }

  /// Load form data from existing organization model (for edit mode)
  void loadFromOrganization(OrganizationDetailModel organization) {
    state = SignUpState(
      isEditMode: true,
      organizationId: organization.id,
      organisationName: organization.name,
      organisationType: organization.orgType,
      email: organization.email,
      contactPersonName: organization.contactPerson ?? '',
      primaryPhoneNumber: organization.contactPhone ?? '',
      contactEmail: organization.emergencyContactEmail ?? '',
      streetAddress: organization.streetAddress,
      city: organization.city,
      state: organization.state,
      zipCode: organization.zipCode,
      country: organization.country,

      // Don't load password in edit mode
      password: '',
      confirmPassword: '',
    );
  }

  /// Reset form state
  void reset() {
    state = SignUpState();
  }
}

final signUpNotifierProvider =
    StateNotifierProvider<SignUpNotifier, SignUpState>((ref) {
      return SignUpNotifier();
    });
