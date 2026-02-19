import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/common/widgets/divider.dart';
import 'package:homelyhope/features/organization/presentation/myprofile/providers/profile_provider.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/custom_appbar.dart';
import '../providers/homeless_providers.dart';
import 'add_homeless.dart';

class HomelessTable extends ConsumerStatefulWidget {
  const HomelessTable({super.key});

  @override
  ConsumerState<HomelessTable> createState() => _HomelessTableState();
}

enum SortBy { name, phone, date }

enum SortOrder { ascending, descending }

class _HomelessTableState extends ConsumerState<HomelessTable> {
  final ValueNotifier<Set<String>> expandedHomelessIds = ValueNotifier(
    <String>{},
  );
  final ValueNotifier<List<dynamic>> localHomelessList = ValueNotifier(
    <dynamic>[],
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  String? _searchQuery;
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Invalidate homeless list once when page is first loaded
    // Use post-frame callback to ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        _invalidateHomelessList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    expandedHomelessIds.dispose();
    localHomelessList.dispose();
    super.dispose();
  }

  void _invalidateHomelessList() {
    final orgId = ref.read(organizationIdProvider).value;
    if (orgId != null) {
      ref.invalidate(
        homelessListProvider(HomelessListParams(organizationId: orgId)),
      );
    }
  }

  /// Debounced search - waits 300ms after user stops typing
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().isEmpty ? null : value.trim();
        });
      }
    });
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = null;
    });
  }

  void _handleSort(SortBy sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        // Toggle sort order if clicking the same column
        _sortOrder = _sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;
      } else {
        // Set new sort column and default to ascending
        _sortBy = sortBy;
        _sortOrder = SortOrder.ascending;
      }
    });
  }

  List<dynamic> _filterAndSortHomeless(List<dynamic> homelessList) {
    // Filter by search query
    List<dynamic> filtered = homelessList;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = homelessList.where((homeless) {
        final fullName = (homeless.fullName ?? homeless.name ?? '')
            .toLowerCase();
        final phone = (homeless.phone ?? homeless.contactPhone ?? '')
            .toLowerCase();
        final email = (homeless.email ?? homeless.contactEmail ?? '')
            .toLowerCase();
        final location = (homeless.location ?? homeless.address ?? '')
            .toLowerCase();
        final skills = (homeless.skills ?? homeless.skillset ?? [])
            .map((s) => s.toLowerCase())
            .join(' ');

        return fullName.contains(query) ||
            phone.contains(query) ||
            email.contains(query) ||
            location.contains(query) ||
            skills.contains(query);
      }).toList();
    }

    // Sort the filtered list
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.name:
          final aName = (a.fullName ?? a.name ?? '').toLowerCase();
          final bName = (b.fullName ?? b.name ?? '').toLowerCase();
          comparison = aName.compareTo(bName);
          break;
        case SortBy.phone:
          final aPhone = (a.phone ?? a.contactPhone ?? '').toLowerCase();
          final bPhone = (b.phone ?? b.contactPhone ?? '').toLowerCase();
          comparison = aPhone.compareTo(bPhone);
          break;
        case SortBy.date:
          final aDate = a.createdAt ?? '';
          final bDate = b.createdAt ?? '';
          comparison = aDate.compareTo(bDate);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  String? _buildImageUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    try {
      if (profilePicture.startsWith('http://') ||
          profilePicture.startsWith('https://')) {
        // Already a full URL
        return profilePicture;
      } else if (profilePicture.startsWith('/')) {
        // Relative path starting with /
        return '$baseUrl$profilePicture';
      } else {
        // Relative path without leading /
        return '$baseUrl/$profilePicture';
      }
    } catch (e) {
      return null;
    }
  }

  void printToken() async {
    final token = await AuthStorageService.getToken();
    print(token);
  }

  @override
  Widget build(BuildContext context) {
    printToken();
    // Watch organization ID
    final orgIdAsync = ref.watch(organizationIdProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Homeless People'),
      body: orgIdAsync.when(
        // ✅ Loading state
        loading: () => Center(child: AppLoader()),
        // ✅ Error state
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading organization ID',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // ✅ Success state - Display homeless list
        data: (orgId) {
          debugPrint('DEBUG: Organization ID loaded: $orgId');
          if (orgId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Organization ID not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          // Fetch ALL homeless users, filtering is done locally
          final homelessListAsync = ref.watch(
            homelessListProvider(HomelessListParams(organizationId: orgId)),
          );

          return homelessListAsync.when(
            // ✅ Loading state
            loading: () {
              debugPrint('DEBUG: Homeless list loading...');
              return Center(child: AppLoader());
            },
            // ✅ Error state
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading homeless users',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // ✅ Retry by invalidating provider
                      ref.invalidate(
                        homelessListProvider(
                          HomelessListParams(organizationId: orgId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            // ✅ Success state - Display homeless
            data: (response) {
              // Sync local list with provider data
              final homelessListFromProvider = response.homeless;
              debugPrint(
                'DEBUG: Homeless list from provider length: ${homelessListFromProvider.length}',
              );

              if (localHomelessList.value.isEmpty ||
                  localHomelessList.value.length !=
                      homelessListFromProvider.length) {
                debugPrint(
                  'DEBUG: Updating local homeless list. New length: ${homelessListFromProvider.length}',
                );
                // Initialize or update local list when provider data changes
                localHomelessList.value = List<dynamic>.from(
                  homelessListFromProvider,
                );
              }

              return ValueListenableBuilder<List<dynamic>>(
                valueListenable: localHomelessList,
                builder: (context, localHomeless, _) {
                  // Re-filter and sort with current local list
                  final filteredAndSortedHomeless = _filterAndSortHomeless(
                    localHomeless,
                  );

                  if (localHomeless.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No homeless users found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add homeless users to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final result = context.push(
                                '/organization/add-homeless',
                              );

                              if (result == true && mounted) {
                                ref.invalidate(homelessListProvider);
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Homeless'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    edgeOffset: 100,
                    key: const ValueKey('organization_homeless_refresh'),
                    // ✅ Pull to refresh
                    onRefresh: () async {
                      ref.invalidate(
                        homelessListProvider(
                          HomelessListParams(organizationId: orgId),
                        ),
                      );
                      // Wait for the provider to refresh and sync local list
                      final refreshedData = await ref.read(
                        homelessListProvider(
                          HomelessListParams(organizationId: orgId),
                        ).future,
                      );
                      localHomelessList.value = List<dynamic>.from(
                        refreshedData.homeless,
                      );
                    },
                    child: CustomScrollView(
                      key: const ValueKey('organization_homeless_scroll'),
                      slivers: [
                        SliverToBoxAdapter(child: Container(height: 100)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.lightText,
                                        ),
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 8,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 0.5,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppTheme.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          hintText:
                                              'Search for a homeless person',
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: Colors.grey.shade400,
                                            size: 20,
                                          ),
                                          prefixIconConstraints:
                                              const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 20,
                                              ),
                                          suffixIcon:
                                              _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey.shade400,
                                                    size: 20,
                                                  ),
                                                  onPressed: _clearSearch,
                                                )
                                              : null,
                                          isDense: false,
                                          floatingLabelAlignment:
                                              FloatingLabelAlignment.start,
                                          labelStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primary,
                                          ),
                                          hintStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade400,
                                          ),
                                          floatingLabelStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                          errorStyle: const TextStyle(
                                            height: 0,
                                            fontSize: 0,
                                          ),
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.0,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Colors.red,
                                              width: 1,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                borderSide: const BorderSide(
                                                  color: Colors.red,
                                                  width: 1,
                                                ),
                                              ),
                                        ),
                                        onChanged: _onSearchChanged,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      context.push(
                                        '/organization/add-homeless',
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text(
                                      'Add',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: screenWidth * 0.5,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedFilter,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: AppTheme.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    hint: const Text(
                                      'Filter',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'all',
                                        child: Text('All'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'verified',
                                        child: Text('Verified'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'unverified',
                                        child: Text('Unverified'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedFilter = value;
                                      });
                                      // TODO: Implement filter
                                    },
                                  ),
                                ),
                                Text(
                                  textAlign: TextAlign.end,
                                  'Total: ${filteredAndSortedHomeless.length} people',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Header with sorting
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.primary,
                                  width: 4,
                                ),
                                right: BorderSide(
                                  color: AppTheme.primary,
                                  width: 4,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Name column - sortable
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _handleSort(SortBy.name),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _sortBy == SortBy.name
                                                ? AppTheme.primary
                                                : Colors.black87,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        if (_sortBy == SortBy.name)
                                          Icon(
                                            _sortOrder == SortOrder.ascending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Phone column - sortable
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _handleSort(SortBy.phone),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Phone',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _sortBy == SortBy.phone
                                                ? AppTheme.primary
                                                : Colors.black,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        if (_sortBy == SortBy.phone)
                                          Icon(
                                            _sortOrder == SortOrder.ascending
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 16,
                                            color: AppTheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Homeless list
                        if (filteredAndSortedHomeless.isEmpty)
                          SliverFillRemaining(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Color(0xff15306C),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      textAlign: TextAlign.center,
                                      'No homeless people found matching your search',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final homeless =
                                    filteredAndSortedHomeless[index];
                                return _buildHomelessCard(
                                  context,
                                  homeless,
                                  index,
                                );
                              }, childCount: filteredAndSortedHomeless.length),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHomelessCard(BuildContext context, dynamic homeless, int index) {
    final fullName = homeless.fullName ?? homeless.name ?? 'Unknown';
    final phone = homeless.phone ?? homeless.contactPhone ?? '';
    final imageUrl = _buildImageUrl(homeless.profilePicture);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedHomelessIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(homeless.id);
        return GestureDetector(
          onTap: () {
            // Create a new Set to trigger ValueNotifier notification
            final newSet = Set<String>.from(expandedSet);
            if (isExpanded) {
              newSet.remove(homeless.id);
            } else {
              newSet.add(homeless.id);
            }
            expandedHomelessIds.value = newSet;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade400.withValues(alpha: 0.75),
              ),
              borderRadius: BorderRadius.circular(12),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.1),
              //     blurRadius: 3,
              //     offset: const Offset(0, 1),
              //   ),
              // ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Phone
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      // color: Colors.red,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Photo and Name
                          Expanded(
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final result = await context.push(
                                      '/organization/view-homeless/${homeless.id}',
                                    );
                                    // Refresh list if detail page returned true (e.g., after edit)
                                    if (result == true && mounted) {
                                      ref.invalidate(homelessListProvider);
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 23,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: imageUrl != null
                                        ? NetworkImage(imageUrl)
                                        : null,
                                    child: imageUrl == null
                                        ? Text(
                                            fullName.isNotEmpty
                                                ? fullName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await context.push(
                                        '/organization/view-homeless/${homeless.id}',
                                      );
                                      // Refresh list if detail page returned true (e.g., after edit)
                                      if (result == true && mounted) {
                                        ref.invalidate(homelessListProvider);
                                      }
                                    },
                                    child: Text(
                                      fullName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 26),
                          // Phone
                          if (phone.isNotEmpty)
                            Text(
                              phone,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          SizedBox(width: 4),
                          isExpanded
                              ? Icon(Icons.expand_less_rounded)
                              : Icon(Icons.expand_more_rounded),
                        ],
                      ),
                    ),
                  ),

                  // Expanded content
                  isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            customDivider(),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                children: [
                                  // Email
                                  if ((homeless.email ??
                                              homeless.contactEmail) !=
                                          null &&
                                      (homeless.email ?? homeless.contactEmail)!
                                          .isNotEmpty)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.email_outlined,
                                      iconColor: Colors.blue,
                                      label: 'Email',
                                      value:
                                          homeless.email ??
                                          homeless.contactEmail ??
                                          '',
                                    ),

                                  // Age & Gender
                                  if (homeless.age != null ||
                                      homeless.gender != null)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.person_outline,
                                      iconColor: Colors.purple,
                                      label: 'Details',
                                      value: [
                                        if (homeless.age != null)
                                          'Age: ${homeless.age}',
                                        if (homeless.gender != null)
                                          'Gender: ${homeless.gender}',
                                      ].join(', '),
                                    ),

                                  // Created Date
                                  if (homeless.createdAt != null &&
                                      homeless.createdAt!.isNotEmpty)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.calendar_today,
                                      iconColor: Colors.blue,
                                      label: 'Added Date',
                                      value: _formatDate(homeless.createdAt!),
                                    ),
                                ],
                              ),
                            ),

                            // Divider before buttons
                            customDivider(),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // View Button - Light green background
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.green.shade100,
                                      foregroundColor: Colors.green.shade700,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () async {
                                      final result = await context.push(
                                        '/organization/view-homeless/${homeless.id}',
                                      );
                                      // Refresh list if detail page returned true (e.g., after edit)
                                      if (result == true && mounted) {
                                        ref.invalidate(homelessListProvider);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                      color: Colors.green.shade700,
                                    ),
                                    label: Text(
                                      'View',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  // Edit Button - White with grey border
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.grey.shade700,
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddHomeless(
                                            homelessToEdit: homeless,
                                          ),
                                        ),
                                      );
                                      // Refresh list if update was successful
                                      if (result == true && mounted) {
                                        ref.invalidate(homelessListProvider);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                    label: Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  // Delete Button - White with grey border, red icon
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      showDeleteHomelessDialog(
                                        context,
                                        homeless.id,
                                        ref,
                                        localHomelessList,
                                      );
                                    },
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build a detail row with colored icon background
  Widget _buildDetailRowWithIconBackground({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    // Get darker shade for icon
    Color iconDarkColor = iconColor;
    if (iconColor == Colors.green) {
      iconDarkColor = Colors.green.shade700;
    } else if (iconColor == Colors.blue) {
      iconDarkColor = Colors.blue.shade700;
    } else if (iconColor == Colors.orange) {
      iconDarkColor = Colors.orange.shade700;
    } else if (iconColor == Colors.purple) {
      iconDarkColor = Colors.purple.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconDarkColor),
          ),
          const SizedBox(width: 8),
          // Label on the left
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Value on the right
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
              maxLines: isMultiline ? null : 3,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date string to readable format
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

void showDeleteHomelessDialog(
  BuildContext context,
  String homelessId,
  WidgetRef ref,
  ValueNotifier<List<dynamic>> localHomelessList,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Homeless'),
      content: const Text('Are you sure you want to delete this homeless?'),
      actions: [
        TextButton(
          onPressed: () {
            context.pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            // Get scaffold context before closing dialog
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            // Close dialog first
            navigator.pop();

            try {
              // Send delete request to backend first
              print(
                '🗑️ [DIALOG] Calling delete API for homeless ID: $homelessId',
              );

              // Invalidate provider first to ensure fresh API call (not cached)
              ref.invalidate(deleteHomelessProfileProvider(homelessId));
              print(
                '🗑️ [DIALOG] Provider invalidated, making fresh API call...',
              );

              final result = await ref.read(
                deleteHomelessProfileProvider(homelessId).future,
              );
              print('✅ [DIALOG] Delete API response received: $result');

              // Check if deletion was successful
              // If API call succeeded (no exception), consider it successful
              // Check multiple conditions to handle different response formats
              final statusCode = result['statusCode'];
              final isSuccess =
                  // Explicit success flag
                  result['success'] == true ||
                  // Status code indicates success (200-299)
                  (statusCode != null &&
                      statusCode >= 200 &&
                      statusCode < 300) ||
                  // Message contains success
                  (result['message'] != null &&
                      result['message'].toString().toLowerCase().contains(
                        'success',
                      )) ||
                  // Status field indicates success
                  result['status'] == 'success' ||
                  // If response is empty but no exception, consider it success
                  (result.isEmpty &&
                      statusCode != null &&
                      statusCode >= 200 &&
                      statusCode < 300);

              print(
                '🔍 Success check - statusCode: $statusCode, success: $isSuccess',
              );

              if (isSuccess) {
                // After successful deletion, remove from local list
                final currentHomeless = List<dynamic>.from(
                  localHomelessList.value,
                );
                final indexToRemove = currentHomeless.indexWhere(
                  (homeless) => homeless.id == homelessId,
                );

                if (indexToRemove != -1) {
                  currentHomeless.removeAt(indexToRemove);
                  localHomelessList.value = currentHomeless;
                  print(
                    '✅ Removed homeless from local list at index: $indexToRemove',
                  );

                  // Show success message
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Homeless deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  print('⚠️ Homeless ID not found in local list: $homelessId');
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Item not found in list'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                print('❌ Delete failed. Response: $result');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete: ${result['message'] ?? 'Unknown error'}',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            } catch (e, stackTrace) {
              print('❌ Delete error: $e');
              print('Stack trace: $stackTrace');
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
