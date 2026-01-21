import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthStorageService {
  static const _secureStorage = FlutterSecureStorage();
  static const String _authBoxName = 'authBox';
  static const String _userBoxName = 'userBox';
  static const String _organizationBoxName = 'organizationBox';
  static const String _merchantBoxName = 'merchantBox';
  static const String _homelessBoxName = 'homelessBox';
  static const String _donorBoxName = 'donorBox';

  /// Save login data to secure storage and Hive
  static Future<void> saveLoginData(Map<String, dynamic> response) async {
    try {
      // Get the data object from response
      final data = response['data'] as Map<String, dynamic>?;

      if (data == null) {
        throw Exception('Invalid response: data is null');
      }

      // Get user and token from data
      final user = data['user'] as Map<String, dynamic>?;
      final token = data['token'] as String?;

      if (user == null || token == null) {
        throw Exception('Invalid response: user or token is null');
      }

      // Open Hive box
      final authBox = await Hive.openBox(_authBoxName);

      // Secure storage → Token
      await _secureStorage.write(key: 'token', value: token);

      // Hive → Other data
      // Note: API returns 'id' not '_id', but checking both for compatibility
      final userId = user['_id'] ?? user['id'];
      if (userId != null) {
        authBox.put('userId', userId.toString());

        final userBox = await Hive.openBox(_userBoxName);
        userBox.put('userId', userId.toString());
        userBox.put('email', user['email'] ?? '');
        userBox.put('role', user['role'] ?? '');
        userBox.put('isLoggedIn', true);
        userBox.put('isVerified', user['isVerified'] ?? false);
      }

      authBox.put('email', user['email'] ?? '');
      authBox.put('role', user['role'] ?? '');
      authBox.put('isLoggedIn', true);

      // Optionally save organization data if available
      if (user['role'] == 'organization') {
        final organization = data['organization'] as Map<String, dynamic>?;
        if (organization != null) {
          final organizationBox = await Hive.openBox(_organizationBoxName);
          // i want to save the organization details to the organizationBox
          organizationBox.put('organizationDetails', organization);
          organizationBox.put(
            'organizationId',
            organization['id']?.toString() ?? '',
          );
          organizationBox.put(
            'organizationName',
            organization['orgName'] ?? '',
          );
        }
      } else if (user['role'] == 'merchant') {
        final merchant = data['merchant'] as Map<String, dynamic>?;
        if (merchant != null) {
          final merchantBox = await Hive.openBox(_merchantBoxName);
          merchantBox.put('merchantId', merchant['id']?.toString() ?? '');
          merchantBox.put('merchantName', merchant['merchantName'] ?? '');
          merchantBox.put('merchantDetails', merchant);
        }
      } else if (user['role'] == 'homeless') {
        final homeless = data['homeless'] as Map<String, dynamic>?;
        if (homeless != null) {
          final homelessBox = await Hive.openBox(_homelessBoxName);
          homelessBox.put('homelessId', homeless['id']?.toString() ?? '');
          homelessBox.put('homelessName', homeless['homelessName'] ?? '');
          homelessBox.put('homelessDetails', homeless);
        }
      } else if (user['role'] == 'donor') {
        final donor = data['donor'] as Map<String, dynamic>?;
        if (donor != null) {
          final donorBox = await Hive.openBox(_donorBoxName);
          donorBox.put('donorId', donor['id']?.toString() ?? '');
          donorBox.put('donorName', donor['donorName'] ?? '');
          donorBox.put('donorDetails', donor);
        }
      }
    } catch (e) {
      throw Exception('Failed to save login data: $e');
    }
  }

  /// Get stored token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  static Future<String?> getHomelessId() async {
    final homelessBox = await Hive.openBox(_homelessBoxName);
    return homelessBox.get('homelessId')?.toString();
  }

  static Future<String?> getDonorId() async {
    final donorBox = await Hive.openBox(_donorBoxName);
    return donorBox.get('donorId')?.toString();
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final authBox = await Hive.openBox(_authBoxName);
    return authBox.get('userId')?.toString();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final authBox = await Hive.openBox(_authBoxName);
    return authBox.get('isLoggedIn', defaultValue: false) as bool;
  }

  static Future<String?> getUserRole() async {
    final userBox = await Hive.openBox(_userBoxName);
    return userBox.get('role')?.toString();
  }

  /// Check if user is verified
  static Future<bool> isVerified() async {
    final userBox = await Hive.openBox(_userBoxName);
    return userBox.get('isVerified', defaultValue: false) as bool;
  }

  /// Update verified status
  static Future<void> updateVerifiedStatus(bool isVerified) async {
    final userBox = await Hive.openBox(_userBoxName);
    await userBox.put('isVerified', isVerified);
  }

  static Future<Map<String, dynamic>?> fetchUserData() async {
    // i want to fetch the organization details from the organizationBox
    try {
      final authBox = await Hive.openBox(_authBoxName);
      final role = authBox.get('role');
      if (role == 'organization') {
        final organizationBox = await Hive.openBox(_organizationBoxName);
        final organizationData = organizationBox.get('organizationDetails');

        // Safely check if organizationData is a Map before accessing
        if (organizationData != null && organizationData is Map) {
          return Map<String, dynamic>.from(organizationData);
        }
        return null;
      } else if (role == 'merchant') {
        final merchantBox = await Hive.openBox(_merchantBoxName);
        final merchantData = merchantBox.get('merchantDetails');
        if (merchantData != null && merchantData is Map) {
          return Map<String, dynamic>.from(merchantData);
        }
        return null;
      } else if (role == 'homeless') {
        final homelessBox = await Hive.openBox(_homelessBoxName);
        final homelessData = homelessBox.get('homelessDetails');

        if (homelessData != null && homelessData is Map) {
          return Map<String, dynamic>.from(homelessData);
        }
        return null;
      } else if (role == 'donor') {
        final donorBox = await Hive.openBox(_donorBoxName);
        final donorData = donorBox.get('donorDetails');
        if (donorData != null && donorData is Map) {
          return Map<String, dynamic>.from(donorData);
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  /// Get organization name directly (helper method)
  static Future<String?> getOrganizationName() async {
    try {
      final organizationBox = await Hive.openBox(_organizationBoxName);
      final orgName = organizationBox.get('organizationName');
      return orgName?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Clear all auth data
  static Future<void> clearAuthData() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: 'token');

      // Clear Hive box
      final authBox = await Hive.openBox(_authBoxName);
      await authBox.clear();
      final userBox = await Hive.openBox(_userBoxName);
      await userBox.clear();
      final organizationBox = await Hive.openBox(_organizationBoxName);
      await organizationBox.clear();
      final merchantBox = await Hive.openBox(_merchantBoxName);
      await merchantBox.clear();
      final homelessBox = await Hive.openBox(_homelessBoxName);
      await homelessBox.clear();
      final donorBox = await Hive.openBox(_donorBoxName);
      await donorBox.clear();
    } catch (e) {
      throw Exception('Failed to clear auth data: $e');
    }
  }
}
