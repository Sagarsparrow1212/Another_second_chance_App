import 'package:flutter_riverpod/legacy.dart';
import 'package:homelyhope/features/common/Drawer/providers/drawer_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final drawerNotifierProvider =
    StateNotifierProvider<DrawerNotifier, AsyncValue<String?>>(
      (ref) => DrawerNotifier(),
    );
