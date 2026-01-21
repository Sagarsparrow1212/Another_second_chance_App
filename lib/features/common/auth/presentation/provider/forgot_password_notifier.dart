import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/common/auth/presentation/login_page.dart';
import 'package:homelyhope/features/common/auth/presentation/notifiers/forgot_password_state.dart';

class ForgotPasswordNotifier extends Notifier<ForgotPasswordState> {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  void _generateOTP() {
    final random = Random();
    final otp = 100000 + random.nextInt(900000); // Generate a 6-digit OTP
    state = state.copyWith(otp: otp);
  }

  void setOtp(int otp) {
    state = state.copyWith(otp: otp);
  }

  Future<void> sendResetOtp(String email) async {
    _generateOTP();
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .sendOtpForResetPassWord(state.otp.toString(), email);

      state = state.copyWith(
        isLoading: false,
        showEmailPreview: true,
        isSuccessOtpSended: true,
        isShowOtpField: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        isSuccessOtpSended: false,
      );
    }
  }

  bool resetPassword({required String email, required String newPassword}) {
    try {
      ref.read(authNotifierProvider.notifier).ResetPassWord(email, newPassword);
      print('Password reset successful for $email $newPassword');

      state = state.copyWith(isResetSuccess: true, isSuccessOtpSended: true);
      return true;
    } catch (e) {
      state = state.copyWith(isResetSuccess: false, errorMessage: e.toString());
      return false;
    }
  }

  bool verifyOtp(int enteredOtp) {
    if (enteredOtp == state.otp) {
      state = state.copyWith(isOtpVerified: true);
      return true;
    } else {
      state = state.copyWith(isOtpVerified: false, errorMessage: 'Invalid OTP');
      return false;
    }
  }

  void sendOtpFieldVisible() {
    state = state.copyWith(isShowOtpField: false);
  }

  void unlockEmail() {
    state = state.copyWith(showEmailPreview: false);
  }

  void otpVerified(bool isVerified) {
    state = state.copyWith(isOtpVerified: isVerified);
  }
}
