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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Assign publishable key to flutter_stripe
  Stripe.publishableKey =
      'pk_test_51Smq6qAprVPeX2Q9lMjU1xSOnnCjIrBPni4tFpeH8PgKxxG33pJSCNXGM2ykaXJUn0US2bKFa2y2pEj9t7WrCFlc00AYls1pj1';
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
