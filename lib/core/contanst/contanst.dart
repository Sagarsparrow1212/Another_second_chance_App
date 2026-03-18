import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive/hive.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/pngloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

final String baseUrl = 'http://192.168.1.62:5000';
// final String baseUrl = 'https://another-second-chance-1.onrender.com';

final String apiBaseUrl = '$baseUrl/api/v1';

//final String apiBaseUrl = '$baseUrl/v1';
// final String organizationDocumentBaseUrl =
//     'http://192.168.1.62:5000/uploads/organizations';
final String organizationDocumentBaseUrl =
    'https://another-second-chance-1.onrender.com/uploads/organizations';
Future<Map<String, String>> getHeaders() async {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final token = await _secureStorage.read(key: 'token');
  return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
}

Future<bool> isCheckInternetAvilable() async {
  try {
    final result = await InternetAddress.lookup('google.com');

    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}

Future<String?> fetchUserName() async {
  final userBox = await Hive.openBox('userBox');
  final userName = userBox.get('userName')?.toString();
  return userName;
}

Future<String?> fetchUserProfilePicture() async {
  final userBox = await Hive.openBox('userBox');
  final userProfilePicture = userBox.get('userProfilePicture')?.toString();
  return userProfilePicture;
}

Future<String?> fetchUserEmail() async {
  final userBox = await Hive.openBox('userBox');
  final userEmail = userBox.get('userEmail')?.toString();
  return userEmail;
}

String? createGreetingBasedOnTime() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 18) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    // TickerMode pauses animation when the route is not active
    // This prevents CPU usage when the screen is not visible
    return TickerMode(
      enabled: ModalRoute.of(context)?.isCurrent ?? true,
      child: const Center(child: PngLogoLoader()),
    );
  }
}

Widget spinkitForButton() =>
    LoadingAnimationWidget.hexagonDots(color: AppTheme.primary, size: 20);
