class ForgotPasswordState {
  final bool isLoading;
  final int otp;
  final bool isShowOtpField;
  final bool showEmailPreview;
  final bool isResetSuccess;
  final String? errorMessage;
  final bool isOtpVerified;
  final bool isSuccessOtpSended;

  const ForgotPasswordState({
    this.isLoading = false,
    this.isShowOtpField = false,
    this.otp = 0,
    this.isResetSuccess = false,
    this.isOtpVerified = false,
    this.showEmailPreview = false,
    this.errorMessage,
    this.isSuccessOtpSended = false,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    bool? showEmailPreview,
    bool? isOtpVerified,
    bool? isResetSuccess,
    int? otp,
    bool? isShowOtpField,
    String? errorMessage,
    bool? isSuccessOtpSended,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      showEmailPreview: showEmailPreview ?? this.showEmailPreview,
      errorMessage: errorMessage,
      isResetSuccess: isResetSuccess ?? this.isResetSuccess,
      otp: otp ?? this.otp,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      isShowOtpField: isShowOtpField ?? this.isShowOtpField,
      isSuccessOtpSended: isSuccessOtpSended ?? this.isSuccessOtpSended,
    );
  }
}
