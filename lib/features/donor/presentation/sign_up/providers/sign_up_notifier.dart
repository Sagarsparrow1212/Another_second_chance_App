import 'package:flutter_riverpod/legacy.dart';

class DonorSignUpState {
  final int currentStep;
  final bool isAgreed;

  // Step 0: Donor Details
  final String organisationName;
  final String organisationType;
  final String email;
  final String contactPersonName;
  final String primaryPhoneNumber;
  final String contactEmail;
  final String password;
  final String confirmPassword;

  // Step 1: Address Details
  final String streetAddress;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  DonorSignUpState({
    this.currentStep = 0,
    this.isAgreed = false,
    this.organisationName = '',
    this.organisationType = '',
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

  DonorSignUpState copyWith({
    int? currentStep,
    bool? isAgreed,
    String? organisationName,
    String? organisationType,
    String? email,
    String? contactPersonName,
    String? primaryPhoneNumber,
    String? contactEmail,
    String? password,
    String? confirmPassword,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) {
    return DonorSignUpState(
      currentStep: currentStep ?? this.currentStep,
      isAgreed: isAgreed ?? this.isAgreed,
      organisationName: organisationName ?? this.organisationName,
      organisationType: organisationType ?? this.organisationType,
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

class DonorSignUpNotifier extends StateNotifier<DonorSignUpState> {
  DonorSignUpNotifier() : super(DonorSignUpState());

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

  // Step 0: Donor Details
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
}

final signUpNotifierProvider =
    StateNotifierProvider<DonorSignUpNotifier, DonorSignUpState>((ref) {
      return DonorSignUpNotifier();
    });
