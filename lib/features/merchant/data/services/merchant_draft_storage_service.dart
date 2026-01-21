import 'package:hive_flutter/hive_flutter.dart';

class MerchantDraftStorageService {
  static const String _draftBoxName = 'merchantDraftBox';
  static const String _draftKey = 'merchant_registration_draft';

  /// Save draft registration data
  static Future<void> saveDraft(Map<String, dynamic> draftData) async {
    try {
      final box = await Hive.openBox(_draftBoxName);
      await box.put(_draftKey, draftData);
    } catch (e) {
      // Handle error silently
      print('Error saving draft: $e');
    }
  }

  /// Get draft registration data
  static Future<Map<String, dynamic>?> getDraft() async {
    try {
      final box = await Hive.openBox(_draftBoxName);
      final draftData = box.get(_draftKey);
      if (draftData is Map) {
        return Map<String, dynamic>.from(draftData);
      }
      return null;
    } catch (e) {
      // Handle error silently
      print('Error getting draft: $e');
      return null;
    }
  }

  /// Clear draft data
  static Future<void> clearDraft() async {
    try {
      final box = await Hive.openBox(_draftBoxName);
      await box.delete(_draftKey);
    } catch (e) {
      // Handle error silently
      print('Error clearing draft: $e');
    }
  }

  /// Check if draft exists
  static Future<bool> hasDraft() async {
    try {
      final box = await Hive.openBox(_draftBoxName);
      return box.containsKey(_draftKey);
    } catch (e) {
      return false;
    }
  }
}

