import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/widgets/logoutPopup.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/providers/snackbar_provider.dart';
import '../providers/drawer_provider.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  Map<String, dynamic>? organizationData;
  String? userRole;
  String? userName;
  String? userProfilePicture;
  String? userEmail;
  bool _isFetchingUser = false;

  // Cache filtered menu items to avoid recomputing on every build
  List<DrawerItem>? _cachedMenuItems;
  DrawerItem? _cachedLogoutItem;
  String? _cachedRole;

  // Separate menu items from logout
  List<DrawerItem> getMenuItems(String role) {
    if (_cachedMenuItems != null && _cachedRole == role) {
      return _cachedMenuItems!;
    }
    final filtered = items
        .where((item) => item.role == role && !item.route!.contains('/logout'))
        .toList();
    _cachedMenuItems = filtered;
    _cachedRole = role;
    return filtered;
  }

  DrawerItem? getLogoutItem(String role) {
    if (_cachedLogoutItem != null && _cachedRole == role) {
      return _cachedLogoutItem;
    }
    final logout = items.firstWhere(
      (item) => item.role == role && item.route!.contains('/logout'),
      orElse: () => DrawerItem(
        title: 'Logout',
        icon: FontAwesomeIcons.rightFromBracket,
        route: '/logout',
        role: role,
      ),
    );
    _cachedLogoutItem = logout;
    return logout;
  }

  void _clearCache() {
    _cachedMenuItems = null;
    _cachedLogoutItem = null;
    _cachedRole = null;
  }

  final List<DrawerItem> items = [
    // --- Organization ---
    DrawerItem(
      title: 'Dashboard',
      icon: LucideIcons.layoutDashboard,
      route: '/organization/dashboard',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Homeless People',
      icon: LucideIcons.users,
      route: '/organization/homeless-table',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Jobs',
      icon: LucideIcons.briefcase,
      route: '/organization/jobs',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Donation History',
      icon: LucideIcons.heartHandshake,
      route: '/organization/donation-history',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Messages',
      icon: LucideIcons.messageCircle,
      route: '/organization/chat',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Wallet',
      icon: LucideIcons.wallet,
      route: '/organization/wallet',
      role: 'organization',
    ),
    DrawerItem(
      title: 'My Profile',
      icon: LucideIcons.user,
      route: '/organization/my-profile',
      role: 'organization',
    ),
    DrawerItem(
      title: 'Logout',
      icon: LucideIcons.logOut,
      route: '/logout',
      role: 'organization',
    ),

    // --- Merchant ---
    DrawerItem(
      title: 'Dashboard',
      icon: LucideIcons.layoutDashboard,
      route: '/merchant/dashboard',
      role: 'merchant',
    ),
    DrawerItem(
      title: 'Jobs',
      icon: LucideIcons.briefcase,
      route: '/merchant/jobs',
      role: 'merchant',
    ),
    DrawerItem(
      title: 'Applicants',
      icon: LucideIcons.users,
      route: '/merchant/applicants',
      role: 'merchant',
    ),
    DrawerItem(
      title: 'Messages',
      icon: LucideIcons.messageCircle,
      route: '/merchant/chat',
      role: 'merchant',
    ),
    DrawerItem(
      title: 'My Profile',
      icon: LucideIcons.user,
      route: '/merchant/my-profile',
      role: 'merchant',
    ),
    DrawerItem(
      title: 'Logout',
      icon: LucideIcons.logOut,
      route: '/logout',
      role: 'merchant',
    ),

    // --- Homeless ---
    DrawerItem(
      title: 'Dashboard',
      icon: FontAwesomeIcons.house,
      route: '/homeless/dashboard',
      role: 'homeless',
    ),
    DrawerItem(
      title: 'Jobs',
      icon: FontAwesomeIcons.briefcase,
      route: '/homeless/jobs',
      role: 'homeless',
    ),
    DrawerItem(
      title: 'My Donations',
      icon: FontAwesomeIcons.handHoldingHeart,
      route: '/homeless/my-donations',
      role: 'homeless',
    ),
    DrawerItem(
      title: 'Messages',
      icon: FontAwesomeIcons.message,
      route: '/homeless/chat',
      role: 'homeless',
    ),
    DrawerItem(
      title: 'My Profile',
      icon: FontAwesomeIcons.user,
      route: '/homeless/my-profile',
      role: 'homeless',
    ),
    DrawerItem(
      title: 'Logout',
      icon: FontAwesomeIcons.rightFromBracket,
      route: '/logout',
      role: 'homeless',
    ),

    // --- Donor ---
    DrawerItem(
      title: 'Dashboard',
      icon: FontAwesomeIcons.chartSimple,
      route: '/donor/dashboard',
      role: 'donor',
    ),
    DrawerItem(
      title: 'Homeless People',
      icon: FontAwesomeIcons.personShelter,
      route: '/donor/homeless-table',
      role: 'donor',
    ),
    DrawerItem(
      title: 'Organizations',
      icon: FontAwesomeIcons.peopleRoof,
      route: '/donor/organization-table',
      role: 'donor',
    ),
    DrawerItem(
      title: 'My Donations',
      icon: FontAwesomeIcons.handHoldingHeart,
      route: '/donor/my-donations',
      role: 'donor',
    ),

    DrawerItem(
      title: 'My Profile',
      icon: FontAwesomeIcons.user,
      route: '/donor/my-profile',
      role: 'donor',
    ),
    DrawerItem(
      title: 'Logout',
      icon: FontAwesomeIcons.rightFromBracket,
      route: '/logout',
      role: 'donor',
    ),
  ];
  @override
  void initState() {
    super.initState();
    // Only fetch user role if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(drawerNotifierProvider);
      // Only call getUserRole if we don't have data yet
      if (currentState.value == null && !currentState.isLoading) {
        ref.read(drawerNotifierProvider.notifier).getUserRole();
      }
      _fetchUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch user data if not already fetching
    if (!_isFetchingUser && userName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchUser();
      });
    }
  }

  @override
  void dispose() {
    _clearCache();
    super.dispose();
  }

  Future<void> _fetchUser() async {
    // Prevent duplicate concurrent calls
    if (_isFetchingUser) return;

    _isFetchingUser = true;
    try {
      const String _userBoxName = 'userBox';
      final userBox = await Hive.openBox(_userBoxName);
      final role = await AuthStorageService.getUserRole();

      // Properly await the fetch - no Future.delayed needed
      final userData = await AuthStorageService.fetchUserData();

      if (userData != null) {
        setState(() {
          // Handle different roles and their name fields
          if (role == 'organization') {
            userName =
                userData['orgName']?.toString() ??
                userData['name']?.toString() ??
                'User';

            userProfilePicture = '$baseUrl${userData['logo']?.toString()}';

            userBox.put('logo', userData['logo']?.toString());
          } else if (role == 'merchant') {
            userName =
                userData['businessName']?.toString() ??
                userData['merchantName']?.toString() ??
                userData['name']?.toString() ??
                'User';
          } else if (role == 'donor') {
            userName =
                userData['name']?.toString() ??
                userData['donorName']?.toString() ??
                userData['fullName']?.toString() ??
                'User';
          } else if (role == 'homeless') {
            userName =
                userData['fullName']?.toString() ??
                userData['name']?.toString() ??
                userData['homelessName']?.toString() ??
                'User';
            userProfilePicture =
                '$baseUrl${userData['profilePicture']?.toString()}';
          } else {
            userName =
                userData['fullName']?.toString() ??
                userData['name']?.toString() ??
                'User';
          }

          // Get email from user data
          userEmail = userData['email']?.toString();
        });
        // Clear cache when user data changes

        userBox.put('userName', userName);
        userBox.put('userProfilePicture', userProfilePicture);
        userBox.put('userEmail', userEmail);
        _clearCache();
      } else {
        // If no user data, try to get name from userBox as fallback
        final userBox = await Hive.openBox('userBox');
        final email = userBox.get('email')?.toString();
        setState(() {
          userName = 'User';
          userEmail = email;
        });
        _clearCache();
      }

      // Get user email if not already set
      if (userEmail == null) {
        final userBox = await Hive.openBox('userBox');
        final email = userBox.get('email')?.toString();
        setState(() {
          userEmail = email;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'User';
        userEmail = null;
      });
    } finally {
      _isFetchingUser = false;
    }
  }

  // String _getRoleDisplayName(String? role) {
  //   switch (role) {
  //     case 'organization':
  //       return 'Organization';
  //     case 'merchant':
  //       return 'Merchant';
  //     case 'homeless':
  //       return 'Homeless';
  //     case 'donor':
  //       return 'Donor';
  //     default:
  //       return 'User';
  //   }
  // }

  void getRole() async {
    final role = await AuthStorageService.getUserRole();
    setState(() {
      userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth > 600 ? 320 : screenWidth * 0.84;
    final double fallbackDrawerWidth = screenWidth > 600
        ? 320
        : screenWidth * 0.7;
    final userRole = ref.watch(drawerNotifierProvider);
    final userRoleValue = userRole.value;
    // Get current route from go_router state safely
    String currentRoute = '';
    try {
      currentRoute = GoRouterState.of(context).uri.path;
    } catch (e) {
      // Fallback if context is not under a RouteBase.builder (e.g. pushed page)
      currentRoute = GoRouter.of(
        context,
      ).routerDelegate.currentConfiguration.uri.path;
    }
    print('Current Route in Drawer: $currentRoute');

    if (userRole.isLoading) {
      return Drawer(
        width: fallbackDrawerWidth,
        child: Center(child: AppLoader()),
      );
    }

    // If user is not logged in (null role), don't show drawer
    if (userRoleValue == null) {
      return Drawer(
        width: fallbackDrawerWidth,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please log in to access the menu',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (userRole.hasError) {
      return Drawer(
        width: fallbackDrawerWidth,
        child: const Center(child: Text('Unable to load user role')),
      );
    }

    // Get menu items and logout separately (cached)
    final menuItems = getMenuItems(userRoleValue);
    final logoutItem = getLogoutItem(userRoleValue);

    return Drawer(
      width: drawerWidth,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            // color: AppTheme.primary,
            // decoration: BoxDecoration(color: Colors.teal),
            child: UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primary),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                backgroundImage: (userProfilePicture?.isNotEmpty ?? false)
                    ? NetworkImage(userProfilePicture!)
                    : null,
                onBackgroundImageError:
                    (userProfilePicture?.isNotEmpty ?? false)
                    ? (exception, stackTrace) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              userProfilePicture = null;
                            });
                          }
                        });
                      }
                    : null,
                child: !(userProfilePicture?.isNotEmpty ?? false)
                    ? Text(
                        (userName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              accountName: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      userName ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2,
                        ),
                        child: Text(
                          userRole.value ?? 'User',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              accountEmail: GestureDetector(
                onTap: () {
                  // TODO: Implement email copy to clipboard
                  Clipboard.setData(ClipboardData(text: userEmail ?? ''));
                  context.pop();
                  ref
                      .read(snackbarServiceProvider)
                      .showSuccess('Email copied to clipboard');
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    userEmail ?? 'User',
                    maxLines: 2,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ),
          // DrawerHeader(
          //   child: Text(
          //     'Homely Hope',
          //     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          //   ),
          // ),
          // Compact Header with Avatar - wrapped in RepaintBoundary
          // RepaintBoundary(child: _buildCompactHeader(userRoleValue)),

          // Menu Items - wrapped in RepaintBoundary
          Expanded(
            child: RepaintBoundary(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1,
                  indent: 56,
                  endIndent: 20,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final route = item.route ?? '';

                  final title = item.title ?? '';
                  final icon = item.icon;

                  final isActive = currentRoute == route;

                  // Use key for better ListView performance
                  return KeyedSubtree(
                    key: ValueKey(route),
                    child: _buildMenuItem(
                      context: context,
                      icon: icon,
                      title: title,
                      route: route,
                      isActive: isActive,
                      currentRoute: currentRoute,
                    ),
                  );
                },
              ),
            ),
          ),

          // Divider before logout
          Divider(height: 1, thickness: 1, color: Colors.grey.shade300),

          // Logout at bottom - wrapped in RepaintBoundary
          if (logoutItem != null)
            RepaintBoundary(
              child: _buildLogoutItem(context: context, logoutItem: logoutItem),
            ),
        ],
      ),
    );
  }

  bool _isDashboardRoute(String route) {
    return route.endsWith('/dashboard');
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
    required String currentRoute,
  }) {
    // Use const colors to avoid recreating on every build
    final activeColor = AppTheme.primary.withValues(alpha: 0.08);
    final transparentColor = Colors.transparent;

    return Material(
      color: isActive ? activeColor : transparentColor,
      child: InkWell(
        onTap: () async {
          // Close drawer first
          context.pop();

          // Navigate to route if it exists and is not empty
          if (route.isNotEmpty) {
            // Check if we are already on the dashboard
            if (_isDashboardRoute(currentRoute) && _isDashboardRoute(route)) {
              return; // Already on dashboard, do nothing
            }

            // If navigating to Dashboard, use go() to reset navigation stack
            if (_isDashboardRoute(route)) {
              context.go(route);
            }
            // If navigating from Dashboard to a drawer item, use push() to maintain back navigation
            else if (_isDashboardRoute(currentRoute)) {
              context.push(route);
            }
            // If navigating from one drawer item to another (or the same item pushed on top of another), use go()
            // This replaces the current stack but maintains the root Dashboard underneath in shell routes
            else {
              context.go(route);
            }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon with proper spacing
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: FaIcon(
                  icon,
                  size: 20,
                  color: isActive ? AppTheme.primary : AppTheme.lightSubText,
                ),
              ),
              SizedBox(width: 20),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? AppTheme.primary : AppTheme.lightText,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              // Arrow with reduced spacing
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isActive
                    ? AppTheme.primary
                    : AppTheme.lightSubText.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem({
    required BuildContext context,
    required DrawerItem logoutItem,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.pop(); // Close the drawer first
          showLogoutPopup(context);
        },

        // Get router instance before closing drawer
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              // Icon
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                child: FaIcon(
                  logoutItem.icon,
                  size: 20,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(width: 20),
              // Title
              Expanded(
                child: Text(
                  logoutItem.title ?? 'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawerItem {
  final String? title;
  final IconData icon;

  final String? route;
  final String role;
  const DrawerItem({
    required this.title,
    required this.icon,

    required this.route,
    required this.role,
  });
}
