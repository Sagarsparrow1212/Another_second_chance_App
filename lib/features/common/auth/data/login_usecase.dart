import 'package:homelyhope/features/common/auth/data/auth_repository_impl.dart';

class LoginUseCase {
  final AuthRepositoryImpl repo;
  LoginUseCase(this.repo);

  Future<Map<String, dynamic>> call(
    String email,
    String password, [
    String? fcmToken,
  ]) {
    return repo.login(email, password, fcmToken);
  }

  Future<Map<String, dynamic>> sendOtpForResetPassWord(
    String otp,
    String email,
  ) {
    return repo.sendOtpForResetPassWord(otp, email);
  }

  Future<Map<String, dynamic>> ResetPassWord(String email, String newPassword) {
    return repo.ResetPassWord(email, newPassword);
  }

  Future<Map<String, dynamic>> logout(String token, String fcmToken) {
    return repo.logout(token, fcmToken);
  }
}
