import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/routing/routes_observer.dart';
import 'package:homelyhope/features/common/splash/splashscreen.dart';
import '../../features/organization/presentation/routes/organization_routes.dart';
import '../../features/common/auth/presentation/login_page.dart';
import '../../features/common/auth/presentation/role_selection_page.dart';
import '../../features/common/auth/presentation/forgot_password_page.dart';
import '../../features/common/auth/data/services/auth_storage_service.dart';
import '../../features/merchant/presentation/routes/merchant_routes.dart';
import '../../features/homeless/presentation/routes/homeless_routes.dart';
import '../../features/donor/presentation/routes/donor_routes.dart';
import '../../features/common/chat/presentation/routes/chat_routes.dart';

final appRoutesObserver = AppRoutesObserver();

final appRouter = GoRouter(
  observers: [appRoutesObserver],
  initialLocation: '/splashscreen',
  restorationScopeId: 'app_router',

  routes: [
    GoRoute(
      path: '/splashscreen',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/forgotPassword',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    ...organizationRoutes,
    ...merchantRoutes,
    ...homelessRoutes,
    ...donorRoutes,
    ...chatRoutes,
  ],
  redirect: (context, state) async {
    final isLoggedIn = await AuthStorageService.isLoggedIn();
    final isVerified = await AuthStorageService.isVerified();
    final currentPath = state.uri.path;
    final userRole = await AuthStorageService.getUserRole();

    // Allow splash screen to be shown without redirect
    if (currentPath == '/splashscreen') {
      return null;
    }

    // If not logged in, redirect to login (except if already on login/signup)
    if (!isLoggedIn) {
      // Clear saved route on logout

      if (currentPath != '/login' &&
          currentPath != '/signUp' &&
          currentPath != '/organization/signUp' &&
          currentPath != '/merchant/signUp' &&
          currentPath != '/donor/signUp' &&
          currentPath != '/role-selection' &&
          currentPath != '/forgotPassword') {
        return '/login';
      }
      return null;
    }

    // If logged in, handle role-specific logic
    if (isLoggedIn) {
      // Only check verification for organization role
      if (userRole == 'organization') {
        // If organization user is not verified, redirect to verification (except if already there)
        if (!isVerified) {
          if (currentPath != '/organization/verification' &&
              currentPath != '/verification') {
            return '/organization/verification';
          }
          return null;
        }
      }

      // If logged in and on login/signup pages, try to restore saved route
      if (currentPath == '/login' || currentPath == '/signUp') {
        // Redirect to appropriate dashboard based on role
        if (userRole == 'organization' && isVerified) {
          return '/organization/dashboard';
        } else if (userRole == 'merchant') {
          return '/merchant/dashboard';
        } else if (userRole == 'homeless') {
          return '/homeless/dashboard';
        } else if (userRole == 'donor') {
          return '/donor/dashboard';
        }
      }
    }

    return null;
  },
);
