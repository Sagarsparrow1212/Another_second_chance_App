import 'package:dio/dio.dart';
import 'package:homelyhope/core/contanst/contanst.dart';

class AuthRemoteDatasource {
  final Dio dio;
  AuthRemoteDatasource(this.dio);

  Future<Map<String, dynamic>> login(
    String email,
    String password, [
    String? fcmToken,
  ]) async {
    try {
      print('Attempting to login: email=$email, fcmToken=$fcmToken');
      final data = {"email": email, "password": password};
      if (fcmToken != null) {
        data["fcmToken"] = fcmToken;
      }
      final response = await dio.post('$apiBaseUrl/auth/login', data: data);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?["message"] ?? "Something went wrong";
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> SendOtpForResetPassWord(
    String otp,
    String email,
  ) async {
    try {
      print(
        'Attempting to send OTP for password reset: otp=$otp, email=$email',
      );
      final response = await dio.post(
        '$apiBaseUrl/auth/reset-password-otp',
        data: {"otp": otp, "email": email},
        options: Options(
          headers: {
            'x-security-key':
                'ecbfa1d51ceea08d7036afe3ea3147e9bcb2bd70ed7e1b4e1df3182948bb1ffa620270abd924c36aa6dde9bb228cb3ce2e129496789b72122923204668fa77e0',
            'Content-Type': 'application/json',
          },
        ),
      );
      print(response.data);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?["message"] ?? "Something went wrong";
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> ResetPassWord(
    String email,
    String newPassword,
  ) async {
    try {
      final response = await dio.post(
        '$apiBaseUrl/auth/reset-password',
        data: {"email": email, "newPassword": newPassword},
        options: Options(
          headers: {
            'x-security-key':
                'ecbfa1d51ceea08d7036afe3ea3147e9bcb2bd70ed7e1b4e1df3182948bb1ffa620270abd924c36aa6dde9bb228cb3ce2e129496789b72122923204668fa77e0',
            'Content-Type': 'application/json',
          },
        ),
      );
      // print(response.data);

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?["message"] ?? "Something went wrong";
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> logout(String token, String fcmToken) async {
    try {
      final response = await dio.post(
        '$apiBaseUrl/auth/logout',
        data: {"fcmToken": fcmToken},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?["message"] ?? "Something went wrong";
      throw Exception(msg);
    }
  }
}
