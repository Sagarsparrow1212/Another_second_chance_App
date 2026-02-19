import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/services/notification_service.dart';
import 'package:homelyhope/features/common/auth/data/login_usecase.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';

class AuthNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final LoginUseCase loginUseCase;

  AuthNotifier(this.loginUseCase) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final fcmToken = await NotificationService.instance.getFCMToken();
      final response = await loginUseCase(email, password, fcmToken);

      // Save login data to storage
      await AuthStorageService.saveLoginData(response);

      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> sendOtpForResetPassWord(String otp, String email) async {
    state = const AsyncValue.loading();

    try {
      final response = await loginUseCase.sendOtpForResetPassWord(otp, email);

      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> ResetPassWord(String email, String newPassword) async {
    state = const AsyncValue.loading();

    try {
      final response = await loginUseCase.ResetPassWord(email, newPassword);

      state = AsyncValue.data(response);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Logout and clear auth data
  Future<void> logout() async {
    try {
      final token = await AuthStorageService.getToken();
      final fcmToken = await NotificationService.instance.getFCMToken();

      if (token != null && fcmToken != null) {
        await loginUseCase.logout(token, fcmToken);
      }
    } catch (e) {
      // Ignore errors during logout API call, proceed to clear local data
      print('Logout API call failed: $e');
    } finally {
      await AuthStorageService.clearAuthData();
      state = const AsyncValue.data(null);
    }
  }
}
