import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/donor/presentation/organization/providers/organization_provider.dart';
import 'package:homelyhope/features/organization/presentation/homeless_people/providers/homeless_providers.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/chat_helper.dart';
import 'package:homelyhope/core/utils/formatters.dart';

class StartChatListPage extends ConsumerStatefulWidget {
  const StartChatListPage({super.key});

  @override
  ConsumerState<StartChatListPage> createState() => _StartChatListPageState();
}

class _StartChatListPageState extends ConsumerState<StartChatListPage> {
  String? _userRole;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('init state');
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final role = await AuthStorageService.getUserRole();
    setState(() {
      _userRole = role;
    });
    print('user role: $_userRole');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  List<dynamic> _filterUsers(List<dynamic> users) {
    if (_searchQuery.isEmpty) return users;

    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      if (_userRole == 'organization') {
        // Filter homeless people
        final name = (user.fullName ?? user.name ?? '').toLowerCase();
        final email = (user.email ?? '').toLowerCase();
        final phone = (user.phone ?? user.contactPhone ?? '').toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
      } else {
        // Filter organizations
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(query) || email.contains(query);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: CustomAppBar(title: 'Start New Chat', showBackButton: true),
      body: Padding(
        padding: EdgeInsets.only(
          top: topPadding + 75,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _userRole == 'organization'
                      ? 'Search homeless people...'
                      : _userRole == 'homeless'
                      ? 'Search organizations...'
                      : 'Search...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // User list based on role
            Expanded(
              child: _userRole == 'organization'
                  ? _buildHomelessList()
                  : _userRole == 'homeless'
                  ? _buildOrganizationList()
                  : _buildUnsupportedRole(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomelessList() {
    // Use organizationIdProvider like homeless_table does
    final orgIdAsync = ref.watch(organizationIdProvider);

    return orgIdAsync.when(
      loading: () => Center(child: AppLoader()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading organization ID',
              style: TextStyle(color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(organizationIdProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orgId) {
        if (orgId == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Organization ID not found',
                  style: TextStyle(color: Colors.grey[800]),
                ),
              ],
            ),
          );
        }

        // Fetch homeless list using the same provider as homeless_table
        final homelessAsync = ref.watch(
          homelessListProvider(HomelessListParams(organizationId: orgId)),
        );

        return homelessAsync.when(
          data: (response) {
            final homelessList = response.homeless;
            final filteredList = _filterUsers(homelessList);

            if (filteredList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'No homeless people found'
                          : 'No results found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  homelessListProvider(
                    HomelessListParams(organizationId: orgId),
                  ),
                );
              },
              child: Container(
                // color: Colors.amber,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final homeless = filteredList[index];
                    return _buildUserTile(
                      id: homeless.id,
                      name: homeless.fullName ?? homeless.name ?? 'Unknown',
                      subtitle:
                          homeless.email ??
                          Formatters.formatPhoneNumber(
                            homeless.phone ?? homeless.contactPhone ?? '',
                          ),
                      avatarUrl: _buildImageUrl(homeless.profilePicture),
                      role: 'Homeless',
                      roleColor: Colors.blue,
                      onTap: () {
                        ChatHelper.startChatWithUser(
                          ref: ref,
                          context: context,
                          targetUserId: homeless.id,
                          targetUserName: homeless.fullName ?? homeless.name,
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
          loading: () => Center(child: AppLoader()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading homeless people',
                  style: TextStyle(color: Colors.grey[800]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(
                      homelessListProvider(
                        HomelessListParams(organizationId: orgId),
                      ),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrganizationList() {
    final organizationsAsync = ref.watch(allOrganizationsProvider);

    return organizationsAsync.when(
      data: (response) {
        final orgList = response.organizations;
        final filteredList = _filterUsers(orgList);

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.business_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty
                      ? 'No organizations found'
                      : 'No results found',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(allOrganizationsProvider);
          },
          child: ListView.builder(
            itemCount: filteredList.length,
            itemBuilder: (context, index) {
              final org = filteredList[index];
              return _buildUserTile(
                id: org.id,
                name: org.name,
                subtitle: org.email,
                avatarUrl: _buildImageUrl(org.logo),
                role: 'Organization',
                roleColor: AppTheme.primary,
                onTap: () {
                  ChatHelper.startChatWithUser(
                    ref: ref,
                    context: context,
                    targetUserId: org.id,
                    targetUserName: org.name,
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => Center(child: AppLoader()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading organizations',
              style: TextStyle(color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(allOrganizationsProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedRole() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chat is only available for organization and homeless users',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile({
    required String id,
    required String name,
    required String subtitle,
    String? avatarUrl,
    required String role,
    required Color roleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: roleColor.withValues(alpha: 0.1),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(LucideIcons.mail, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chat icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LineAwesomeIcons.comments,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
