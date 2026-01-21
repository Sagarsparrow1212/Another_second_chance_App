import 'package:homelyhope/features/common/auth/data/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDatasource remote;
  AuthRepositoryImpl(this.remote);

  Future<Map<String, dynamic>> login(String email, String password) {
    return remote.login(email, password);
  }

  Future<Map<String, dynamic>> sendOtpForResetPassWord(
    String otp,
    String email,
  ) {
    return remote.SendOtpForResetPassWord(otp, email);
  }

  Future<Map<String, dynamic>> ResetPassWord(String email, String newPassword) {
    return remote.ResetPassWord(email, newPassword);
  }
}
