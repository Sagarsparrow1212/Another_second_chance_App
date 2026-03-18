// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:homelyhope/core/routing/app_router.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:homelyhope/firebase_options.dart';
import 'package:homelyhope/core/services/notification_service.dart';
import 'package:homelyhope/features/common/auth/presentation/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set the background messaging handler early on, as a named top-level function
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Notification Service
  await NotificationService.instance.init();

  //Assign publishable key to flutter_stripe
  Stripe.publishableKey = 'pk_test_pFdgV81w4gpee3K96QghDMXO00UkXAj2Nr';
  await Stripe.instance.applySettings();
  await Hive.initFlutter();
  await Hive.openBox('authBox');
  await Hive.openBox('userBox');
  await Hive.openBox('organizationBox');
  await Hive.openBox('merchantBox');
  await Hive.openBox('routeBox');
  // Chat related boxes
  await Hive.openBox('messagesBox');
  await Hive.openBox('chatsBox');
  await Hive.openBox('chatMetadataBox');
  await Hive.openBox('pendingMessagesBox');
  // Draft storage
  await Hive.openBox('donorDraftBox');
  await Hive.openBox('merchantDraftBox');

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final snackbarService = ref.watch(snackbarServiceProvider);
    
    return MaterialApp.router(
      scaffoldMessengerKey: snackbarService.messengerKey,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
    );
    // return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: AppLoader()));
  }
}
