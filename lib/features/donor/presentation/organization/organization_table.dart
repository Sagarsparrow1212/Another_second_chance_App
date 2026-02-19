import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/pngloader.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../common/Drawer/pages/dynamic_drawer.dart';
import '../../../common/widgets/custom_appbar.dart';
import '../../data/models/organization/organization_model.dart';
import 'providers/organization_provider.dart';
import 'organization_homeless_page.dart';

class OrganizationTable extends ConsumerStatefulWidget {
  const OrganizationTable({super.key});
  @override
  ConsumerState<OrganizationTable> createState() => _OrganizationTableState();
}

enum SortBy { name, type, status, date }

enum SortOrder { ascending, descending }

class _OrganizationTableState extends ConsumerState<OrganizationTable> {
  final ValueNotifier<Set<String>> expandedOrgIds = ValueNotifier(<String>{});
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  String? _searchQuery;
  String? _selectedTypeFilter;
  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(allOrganizationsProvider);
      }
    });
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      _currentPage = 1; // reset to first page on search
    });
  }

  void _handleSort(SortBy sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortOrder = _sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;
      } else {
        _sortBy = sortBy;
        _sortOrder = SortOrder.ascending;
      }
      _currentPage = 1; // reset page when sorting changes
    });
  }

  List<OrganizationModel> _filterAndSortOrgs(List<OrganizationModel> orgs) {
    List<OrganizationModel> filtered = orgs;

    // Filter to show only active organizations
    filtered = filtered.where((org) {
      final status = org.currentStatus.toLowerCase();
      return status == 'approved' || status == 'active';
    }).toList();

    // Filter by type
    if (_selectedTypeFilter != null && _selectedTypeFilter != 'all') {
      filtered = filtered
          .where(
            (org) =>
                org.orgType.toLowerCase() == _selectedTypeFilter!.toLowerCase(),
          )
          .toList();
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((org) {
        return org.name.toLowerCase().contains(query) ||
            org.email.toLowerCase().contains(query) ||
            org.orgType.toLowerCase().contains(query) ||
            org.city.toLowerCase().contains(query) ||
            org.contactPerson.toLowerCase().contains(query);
      }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortBy.type:
          comparison = a.orgType.toLowerCase().compareTo(
            b.orgType.toLowerCase(),
          );
          break;
        case SortBy.status:
          comparison = a.currentStatus.toLowerCase().compareTo(
            b.currentStatus.toLowerCase(),
          );
          break;
        case SortBy.date:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(1, _totalPages(_lastFilteredCount ?? 0));
    });
  }

  int? _lastFilteredCount;

  int _totalPages(int itemCount) {
    if (itemCount <= 0) return 1;
    return ((itemCount - 1) / _pageSize).floor() + 1;
  }

  @override
  void dispose() {
    expandedOrgIds.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getOrgTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'nonprofit':
      case 'non-profit':
        return Icons.volunteer_activism;
      case 'shelter':
        return Icons.home;
      case 'food bank':
        return Icons.restaurant;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return FontAwesomeIcons.peopleRoof;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(allOrganizationsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: CustomAppBar(title: 'Organizations'),
      body: orgsAsync.when(
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading organizations',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(allOrganizationsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (response) {
          final filteredOrgs = _filterAndSortOrgs(response.organizations);

          // prepare pagination for filtered results (client-side)
          _lastFilteredCount = filteredOrgs.length;
          final totalPages = _totalPages(filteredOrgs.length);
          final startIndex = ((_currentPage - 1) * _pageSize)
              .clamp(0, filteredOrgs.length)
              .toInt();
          final endIndex = (startIndex + _pageSize)
              .clamp(0, filteredOrgs.length)
              .toInt();
          final pagedOrgs = filteredOrgs.sublist(startIndex, endIndex);

          if (response.organizations.isEmpty) {
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
                    'No organizations found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Organizations will appear here once registered',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            edgeOffset: 100,
            onRefresh: () async {
              ref.invalidate(allOrganizationsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, topPadding + 80, 16, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                          hintText: 'Search organizations...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _performSearch();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => _performSearch(),
                      ),
                    ),
                  ),
                ),

                // Filter and count row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: screenWidth * 0.5,
                          child: DropdownButtonFormField<String>(
                            value: _selectedTypeFilter,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
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
                              'Filter by Type',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Types'),
                              ),
                              DropdownMenuItem(
                                value: 'nonprofit',
                                child: Text('Nonprofit'),
                              ),
                              DropdownMenuItem(
                                value: 'shelter',
                                child: Text('Shelter'),
                              ),
                              DropdownMenuItem(
                                value: 'food bank',
                                child: Text('Food Bank'),
                              ),
                              DropdownMenuItem(
                                value: 'healthcare',
                                child: Text('Healthcare'),
                              ),
                              DropdownMenuItem(
                                value: 'education',
                                child: Text('Education'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedTypeFilter = value;
                                _currentPage =
                                    1; // reset page when filter changes
                              });
                            },
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${filteredOrgs.length} organizations',
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

                // Sorting header
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
                        left: BorderSide(color: AppTheme.primary, width: 4),
                        right: BorderSide(color: AppTheme.primary, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildSortHeader('Name', SortBy.name, flex: 2),
                        _buildSortHeader('Type', SortBy.type, flex: 1),
                        _buildSortHeader('Status', SortBy.status, flex: 1),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Organization list (paged)
                if (filteredOrgs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No organizations match your search',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildOrgCard(context, pagedOrgs[index]),
                        childCount: pagedOrgs.length,
                      ),
                    ),
                  ),

                  // Pagination footer
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: _buildPaginationFooter(
                        filteredOrgs.length,
                        totalPages,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortHeader(String title, SortBy sortBy, {int flex = 1}) {
    final isActive = _sortBy == sortBy;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => _handleSort(sortBy),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? AppTheme.primary : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
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
    );
  }

  Widget _buildPaginationFooter(int totalItems, int totalPages) {
    final start = totalItems == 0 ? 0 : ((_currentPage - 1) * _pageSize) + 1;
    final end = totalItems == 0
        ? 0
        : math.min(_currentPage * _pageSize, totalItems);

    // Generate page numbers to display (max 5 page buttons)
    List<int> pagesToShow = _getPagesToShow(_currentPage, totalPages);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Flexible(
              flex: 2,
              child: Text(
                'Showing $start-$end of $totalItems',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Pagination controls in rounded container - constrained to prevent overflow
            Flexible(
              flex: 3,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _currentPage > 1
                            ? AppTheme.primary
                            : Colors.grey.shade400,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                      iconSize: 20,
                    ),

                    // Page number buttons with ellipsis handling - limit to max 5 buttons
                    ...pagesToShow.take(7).map((pageNumber) {
                      final isActive = _currentPage == pageNumber;
                      final isEllipsis =
                          pageNumber == -1; // -1 represents ellipsis

                      if (isEllipsis) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 32,
                          height: 32,
                          child: Center(
                            child: Text(
                              '...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: () => _goToPage(pageNumber),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '$pageNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    // Right arrow
                    IconButton(
                      onPressed: _currentPage < totalPages
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentPage < totalPages
                            ? AppTheme.primary
                            : Colors.grey.shade400,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 32,
                      ),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Generate list of page numbers to display with ellipsis
  /// Returns list of page numbers, with -1 representing ellipsis
  /// Maximum 5 page buttons: [1] + [...] + [current-1] + [current] + [current+1] + [...] + [last]
  /// This ensures no overflow even with 10+ pages
  List<int> _getPagesToShow(int currentPage, int totalPages) {
    if (totalPages <= 5) {
      // Show all pages if 5 or fewer
      return List.generate(totalPages, (index) => index + 1);
    }

    List<int> pages = [];

    if (currentPage <= 2) {
      // Near the beginning: show first 2 pages, ellipsis, last page (max 3 buttons + ellipsis)
      pages.add(1);
      pages.add(2);
      if (totalPages > 3) {
        pages.add(-1); // Ellipsis
        pages.add(totalPages);
      } else {
        pages.add(3);
      }
    } else if (currentPage >= totalPages - 1) {
      // Near the end: show first page, ellipsis, last 2 pages (max 3 buttons + ellipsis)
      pages.add(1);
      if (totalPages > 3) {
        pages.add(-1); // Ellipsis
      }
      pages.add(totalPages - 1);
      pages.add(totalPages);
    } else {
      // In the middle: show first page, ellipsis, current-1, current, current+1, ellipsis, last page
      // This gives us exactly 5 page buttons: 1, ..., current-1, current, current+1, ..., last
      pages.add(1);
      pages.add(-1); // Ellipsis
      pages.add(currentPage - 1);
      pages.add(currentPage);
      pages.add(currentPage + 1);
      if (currentPage + 1 < totalPages - 1) {
        pages.add(-1); // Ellipsis
        pages.add(totalPages);
      } else {
        // If current+1 is the second-to-last, just add last page without ellipsis
        pages.add(totalPages);
      }
    }

    // Ensure we never return more than 7 items total (5 buttons + 2 ellipsis max)
    return pages.length > 7 ? pages.sublist(0, 7) : pages;
  }

  Widget _buildOrgCard(BuildContext context, OrganizationModel org) {
    // Generate gradient colors based on org type
    final gradientColors = _getGradientColors(org.orgType);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedOrgIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(org.id);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: GestureDetector(
            onTap: () {
              final newSet = Set<String>.from(expandedSet);
              if (isExpanded) {
                newSet.remove(org.id);
              } else {
                newSet.add(org.id);
              }
              expandedOrgIds.value = newSet;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Main card content with gradient
                    Container(
                      decoration: BoxDecoration(color: Colors.white),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Circular logo with shadow
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: gradientColors,
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                                child: org.logo.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          '$baseUrl${org.logo}',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            _getOrgTypeIcon(org.orgType),
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        _getOrgTypeIcon(org.orgType),
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Name and tagline
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 0),
                                  Text(
                                    org.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[850],
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),

                                  TextButton(
                                    child: Text(
                                      ' ${org.homelessCount} people',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onPressed: () {
                                      context.push(
                                        '/donor/organization/${org.id}/homeless',
                                        extra: OrganizationHomelessArgs(
                                          organizationId: org.id,
                                          organizationName: org.name,
                                          gradientColors: gradientColors,
                                        ),
                                      );
                                    },

                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: AppTheme.primary,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),

                            // Arrow indicator
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey[600],
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Thin divider line

                    // Expanded content
                    if (isExpanded) ...[
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Status row at top
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    org.currentStatus,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      org.currentStatus,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          org.currentStatus,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      org.currentStatus.isNotEmpty
                                          ? '${org.currentStatus[0].toUpperCase()}${org.currentStatus.substring(1)} Organization'
                                          : 'Unknown Status',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(
                                          org.currentStatus,
                                        ),
                                      ),
                                    ),
                                    if (org.verified) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.blue[600],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Contact info
                              _buildDetailRow(
                                icon: Icons.person_outline,
                                iconColor: Colors.blue,
                                label: 'Contact Person',
                                value: org.contactPerson,
                              ),
                              _buildDetailRow(
                                icon: Icons.email_outlined,
                                iconColor: Colors.orange,
                                label: 'Email',
                                value: org.email,
                              ),
                              _buildDetailRow(
                                icon: Icons.phone_outlined,
                                iconColor: Colors.green,
                                label: 'Phone',
                                value: org.contactPhone,
                              ),
                              _buildDetailRow(
                                icon: Icons.location_on_outlined,
                                iconColor: Colors.red,
                                label: 'Address',
                                value: _formatAddress(org),
                              ),
                              if (org.createdAt.isNotEmpty)
                                _buildDetailRow(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: Colors.purple,
                                  label: 'Registered',
                                  value: _formatDate(org.createdAt),
                                ),

                              const SizedBox(height: 16),

                              // Action buttons
                              Row(
                                children: [
                                  // View People button with gradient
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: gradientColors,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          context.push(
                                            '/donor/organization/${org.id}/homeless',
                                            extra: OrganizationHomelessArgs(
                                              organizationId: org.id,
                                              organizationName: org.name,
                                              gradientColors: gradientColors,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.people_outline,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'View People',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // const SizedBox(width: 12),
                                  // Contact button (outlined)
                                  // Expanded(
                                  //   child: OutlinedButton.icon(
                                  //     style: OutlinedButton.styleFrom(
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(
                                  //           12,
                                  //         ),
                                  //       ),
                                  //       side: BorderSide(
                                  //         color: Colors.grey.shade300,
                                  //       ),
                                  //       padding: const EdgeInsets.symmetric(
                                  //         vertical: 12,
                                  //       ),
                                  //     ),
                                  //     onPressed: () {
                                  //       // TODO: Contact organization
                                  //     },
                                  //     icon: Icon(
                                  //       Icons.message_outlined,
                                  //       size: 18,
                                  //       color: Colors.grey[700],
                                  //     ),
                                  //     label: Text(
                                  //       'Contact',
                                  //       style: TextStyle(
                                  //         color: Colors.grey[700],
                                  //         fontWeight: FontWeight.w600,
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Color> _getGradientColors(String orgType) {
    switch (orgType.toLowerCase()) {
      case 'nonprofit':
      case 'non-profit':
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      case 'shelter':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'food bank':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case 'healthcare':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'education':
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      default:
        return [
          AppTheme.primary,
          const Color.fromARGB(255, 47, 83, 161),
          const Color.fromARGB(255, 95, 130, 206),
        ];
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(OrganizationModel org) {
    final parts = <String>[];
    if (org.streetAddress.isNotEmpty) parts.add(org.streetAddress);
    if (org.city.isNotEmpty) parts.add(org.city);
    if (org.state.isNotEmpty) parts.add(org.state);
    if (org.zipCode.isNotEmpty) parts.add(org.zipCode);
    if (org.country.isNotEmpty) parts.add(org.country);
    return parts.join(', ');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
