// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';

class DrawerNotifier extends StateNotifier<AsyncValue<String?>> {
  DrawerNotifier() : super(const AsyncValue.data(null));

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<void> getUserRole() async {
    // Check if user is logged in first
    final isLoggedIn = await AuthStorageService.isLoggedIn();
    if (!isLoggedIn) {
      // User is not logged in, set state to null (only if not already null)
      if (state.value != null) {
        state = const AsyncValue.data(null);
      }
      return;
    }

    // Get fresh role
    final userRole = await AuthStorageService.getUserRole();

    // Only update state if role actually changed (avoid unnecessary rebuilds)
    if (state.value != userRole) {
      state = AsyncValue.data(userRole);
    }
  }
}
