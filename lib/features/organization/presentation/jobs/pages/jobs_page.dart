import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/organization/presentation/jobs/providers/jobs_provider.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../../common/widgets/custom_appbar.dart';
import '../../../../common/widgets/divider.dart';

/// A widget that smoothly animates size changes using SizeTransition
class _AnimatedExpandableCard extends StatefulWidget {
  final bool isExpanded;
  final Widget child;

  const _AnimatedExpandableCard({
    required this.isExpanded,
    required this.child,
  });

  @override
  State<_AnimatedExpandableCard> createState() =>
      _AnimatedExpandableCardState();
}

class _AnimatedExpandableCardState extends State<_AnimatedExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_AnimatedExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _animation,
        axisAlignment: -1.0,
        child: widget.child,
      ),
    );
  }
}

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

enum SortBy { title, salary, date }

enum SortOrder { ascending, descending }

/// Helper class to represent a text match position
class _TextMatch {
  final int start;
  final int end;

  _TextMatch(this.start, this.end);
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final ValueNotifier<Set<String>> expandedJobIds = ValueNotifier(<String>{});
  final ValueNotifier<List<JobModel>> localJobsList = ValueNotifier(
    <JobModel>[],
  );
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.title;
  int _currentPage = 1;
  static const int _pageSize = 10;
  SortOrder _sortOrder = SortOrder.ascending;
  String? _searchQuery;
  String? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    // Invalidate jobs list once when page is first loaded
    // Use post-frame callback to ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(allJobsProvider);
      }
    });
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      // Reset to first page when search changes
      _currentPage = 1;
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
      // Reset to first page when sort changes
      _currentPage = 1;
    });
  }

  List<JobModel> _filterAndSortJobs(List<JobModel> jobs) {
    // Start from the full list
    List<JobModel> filtered = List<JobModel>.from(jobs);

    // Apply status filter if selected (default: show all)
    if (_selectedStatusFilter != null && _selectedStatusFilter != 'all') {
      filtered = filtered
          .where((job) => job.status == _selectedStatusFilter)
          .toList();
    }

    // Apply search on the already-filtered list
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query) ||
            job.category.toLowerCase().contains(query) ||
            (job.merchant?.businessName.toLowerCase().contains(query) ??
                false) ||
            (job.location?.address.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort the filtered list
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.title:
          // Case-insensitive sorting for titles
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortBy.salary:
          final aSalary = a.salaryRange?.min ?? 0;
          final bSalary = b.salaryRange?.min ?? 0;
          comparison = aSalary.compareTo(bSalary);
          break;
        case SortBy.date:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  void dispose() {
    expandedJobIds.dispose();
    localJobsList.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(allJobsProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Jobs'),
      body: jobsAsync.when(
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
                'Error loading jobs',
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
                  ref.invalidate(allJobsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        // ✅ Success state - Display jobs
        data: (jobsResponse) {
          // Sync local list with provider data
          final allJobsFromProvider = jobsResponse.jobs;
          if (localJobsList.value.isEmpty ||
              localJobsList.value.length != allJobsFromProvider.length) {
            // Initialize or update local list when provider data changes
            localJobsList.value = List<JobModel>.from(allJobsFromProvider);
          }

          return ValueListenableBuilder<List<JobModel>>(
            valueListenable: localJobsList,
            builder: (context, localJobs, _) {
              // Re-filter and sort with current local list
              final filteredAndSortedJobs = _filterAndSortJobs(localJobs);

              // Client-side pagination
              final totalItems = filteredAndSortedJobs.length;
              final totalPages = math.max(1, (totalItems / _pageSize).ceil());

              // Ensure current page doesn't exceed total pages
              if (_currentPage > totalPages && totalPages > 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentPage = 1;
                    });
                  }
                });
              }

              final safeCurrentPage = math.min(_currentPage, totalPages);
              final startIndex = ((safeCurrentPage - 1) * _pageSize)
                  .clamp(0, totalItems)
                  .toInt();
              final endIndex = math
                  .min(safeCurrentPage * _pageSize, totalItems)
                  .toInt();
              final paginatedJobs = totalItems > 0
                  ? filteredAndSortedJobs.sublist(startIndex, endIndex)
                  : <JobModel>[];

              if (localJobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs available',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new job postings',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                edgeOffset: 100,
                key: const ValueKey('organization_jobs_refresh'),
                // ✅ Pull to refresh
                onRefresh: () async {
                  ref.invalidate(allJobsProvider);
                  // Wait for the provider to refresh and sync local list
                  final refreshedData = await ref.read(allJobsProvider.future);
                  localJobsList.value = List<JobModel>.from(refreshedData.jobs);
                },
                child: CustomScrollView(
                  key: const ValueKey('organization_jobs_scroll'),
                  slivers: [
                    SliverToBoxAdapter(child: Container(height: 100)),

                    // Search bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        child: Row(
                          children: [
                            // Search bar - takes remaining space
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 0.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.lightText,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
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
                                        width: 0.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primary,
                                        width: 1.0,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Search for a job',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 20,
                                    ),

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
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) {
                                    _performSearch();
                                  },
                                ),
                              ),
                            ),

                            // Dropdown menu for filtering by job status
                          ],
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
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              textAlign: TextAlign.end,
                              'Added: $totalItems jobs',
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
                            left: BorderSide(color: AppTheme.primary, width: 4),
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
                            // Title column - sortable with teal bar
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _handleSort(SortBy.title),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Title',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _sortBy == SortBy.title
                                            ? AppTheme.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    if (_sortBy == SortBy.title)
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
                            // Salary column - sortable
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: GestureDetector(
                                onTap: () => _handleSort(SortBy.salary),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Salary',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _sortBy == SortBy.salary
                                            ? AppTheme.primary
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    if (_sortBy == SortBy.salary)
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
                    // Jobs list
                    if (paginatedJobs.isEmpty)
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
                                'No jobs found matching your search',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                            final job = paginatedJobs[index];
                            return _buildJobCard(context, job, index);
                          }, childCount: paginatedJobs.length),
                        ),
                      ),

                    // Pagination controls
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: _buildPaginationFooter(
                          totalItems,
                          math.min(_currentPage, totalPages),
                          totalPages,
                          _pageSize,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, int index) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedJobIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(job.id);
        return GestureDetector(
          onTap: () {
            // Create a new Set to trigger ValueNotifier notification
            print('job.id: ${job.id}');
            final newSet = Set<String>.from(expandedSet);
            if (isExpanded) {
              newSet.remove(job.id);
            } else {
              newSet.add(job.id);
            }
            expandedJobIds.value = newSet;
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
              //     blurRadius: 2,
              //     offset: const Offset(0, 0.2),
              //   ),
              // ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 5),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: 36,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            // color: Colors.red,
                            child: _buildHighlightedText(
                              text: job.title,
                              searchQuery: _searchQuery,
                            ),
                          ),
                        ),

                        SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (job.salaryRange != null) ...[
                                Container(
                                  // color: Colors.blue,
                                  child: Text(
                                    '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(width: 4),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Icon(Icons.expand_more_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded content with optimized rendering
                  _AnimatedExpandableCard(
                    isExpanded: isExpanded,
                    child: RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          customDivider(),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                if (job.category.isNotEmpty)
                                  _buildDetailRowWithIconBackground(
                                    icon: Icons.business,
                                    iconColor: Colors.green,
                                    label: 'Category',
                                    value: job.category,
                                  ),

                                // Status with badge - Clock icon with orange background
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              job.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Created Date - Calendar icon with blue background
                                if (job.createdAt.isNotEmpty)
                                  _buildDetailRowWithIconBackground(
                                    icon: Icons.calendar_today,
                                    iconColor: Colors.blue,
                                    label: 'Posted Date',
                                    value: _formatDate(job.createdAt),
                                  ),

                                // Merchant/Business - Briefcase icon with green background
                                if (job.merchant != null)
                                  _buildDetailRowWithIconBackground(
                                    icon: Icons.business,
                                    iconColor: Colors.green,
                                    label: 'Business',
                                    value: job.merchant!.businessName,
                                  ),
                              ],
                            ),
                          ),
                          // Category - Briefcase icon with green background

                          // Divider before buttons
                          customDivider(),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  onPressed: () {
                                    // TODO: Navigate to view job details page
                                    context.push(
                                      '/organization/view-job/${job.id}',
                                    );
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

                                // Delete Button - White with grey border, red icon
                                // OutlinedButton(
                                //   style: OutlinedButton.styleFrom(
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(10),
                                //     ),
                                //     backgroundColor: Colors.white,
                                //     foregroundColor: Colors.red,
                                //     side: BorderSide(
                                //       color: Colors.grey.shade300,
                                //     ),
                                //     padding: const EdgeInsets.symmetric(
                                //       horizontal: 12,
                                //       vertical: 8,
                                //     ),
                                //   ),
                                //   onPressed: () {
                                //     showDeleteJobDialog(
                                //       context,
                                //       job.id,
                                //       job.title,
                                //       ref,
                                //     );
                                //   },
                                //   child: const Icon(
                                //     Icons.delete_outline,
                                //     size: 20,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
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
          const SizedBox(width: 16),
          // Value on the right
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
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

  Widget _buildPaginationFooter(
    int totalItems,
    int currentPage,
    int totalPages,
    int itemsPerPage,
  ) {
    final start = totalItems == 0 ? 0 : ((currentPage - 1) * itemsPerPage) + 1;
    final end = totalItems == 0
        ? 0
        : math.min(currentPage * itemsPerPage, totalItems);

    // Generate page numbers to display (max 5 page buttons)
    List<int> pagesToShow = _getPagesToShow(currentPage, totalPages);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // color: Colors.red,
              child: Text(
                'Showing $start-$end of $totalItems',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
            ),

            Row(
              children: [
                // Pagination controls in rounded container - constrained to prevent overflow
                Container(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.58,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Left arrow
                      IconButton(
                        onPressed: currentPage > 1
                            ? () {
                                _goToPage(currentPage - 1);
                              }
                            : null,
                        icon: Icon(
                          Icons.chevron_left,
                          color: currentPage > 1
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                        ),
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 6,
                        //   vertical: 8,
                        // ),
                        // constraints: const BoxConstraints(
                        //   minWidth: 28,
                        //   minHeight: 32,
                        // ),
                        iconSize: 20,
                      ),

                      // Page number buttons with ellipsis handling - limit to max 5 buttons
                      ...pagesToShow.take(7).map((pageNumber) {
                        final isActive = currentPage == pageNumber;
                        final isEllipsis =
                            pageNumber == -1; // -1 represents ellipsis

                        if (isEllipsis) {
                          return Container(
                            width: 30,
                            height: 30,
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
                          onTap: () {
                            if (pageNumber != currentPage) {
                              _goToPage(pageNumber);
                            }
                          },
                          child: Container(
                            width: 30,
                            height: 30,
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
                        onPressed: currentPage < totalPages
                            ? () {
                                _goToPage(currentPage + 1);
                              }
                            : null,
                        icon: Icon(
                          Icons.chevron_right,
                          color: currentPage < totalPages
                              ? AppTheme.primary
                              : Colors.grey.shade400,
                        ),
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 6,
                        //   vertical: 8,
                        // ),
                        // constraints: const BoxConstraints(
                        //   minWidth: 28,
                        //   minHeight: 32,
                        // ),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Build text with highlighted search matches (highlights all occurrences)
  Widget _buildHighlightedText({required String text, String? searchQuery}) {
    if (searchQuery == null || searchQuery.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );
    }

    final query = searchQuery.toLowerCase();
    final lowerText = text.toLowerCase();

    // Find all matches (case-insensitive)
    final matches = <_TextMatch>[];
    int startIndex = 0;
    while (startIndex < lowerText.length) {
      final index = lowerText.indexOf(query, startIndex);
      if (index == -1) break;
      matches.add(_TextMatch(index, index + query.length));
      startIndex = index + 1;
    }

    if (matches.isEmpty) {
      // No match found, return normal text
      return Text(
        text,
        style: TextStyle(
          fontSize: text.length > 20 ? 13 : 14,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Build TextSpan with all highlighted portions
    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      // Add text before match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        );
      }

      // Add highlighted matched text
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade700,
            backgroundColor: Colors.green.shade50,
          ),
        ),
      );

      lastIndex = match.end;
    }

    // Add remaining text after last match
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  /// Generate list of page numbers to display with ellipsis
  /// Returns list of page numbers, with -1 representing ellipsis
  /// Maximum 5 page buttons: [1] + [...] + [current-1] + [current] + [current] + [current+1] + [...] + [last]
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

  /// Show delete job dialog with optimized deletion
  void showDeleteJobDialog(
    BuildContext context,
    String jobId,
    String jobTitle,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "$jobTitle"?'),
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
                  '🗑️ [JOBS DIALOG] Calling delete API for job ID: $jobId',
                );

                // Invalidate provider first to ensure fresh API call (not cached)
                ref.invalidate(deleteJobProvider(jobId));
                print(
                  '🗑️ [JOBS DIALOG] Provider invalidated, making fresh API call...',
                );

                final result = await ref.read(deleteJobProvider(jobId).future);
                print('✅ [JOBS DIALOG] Delete API response received: $result');

                // Check if deletion was successful
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
                  '🔍 [JOBS DIALOG] Success check - statusCode: $statusCode, success: $isSuccess',
                );

                if (isSuccess) {
                  // After successful deletion, remove from local list
                  final currentJobs = List<JobModel>.from(localJobsList.value);
                  final indexToRemove = currentJobs.indexWhere(
                    (job) => job.id == jobId,
                  );

                  if (indexToRemove != -1) {
                    currentJobs.removeAt(indexToRemove);
                    localJobsList.value = currentJobs;
                    print(
                      '✅ [JOBS DIALOG] Removed job from local list at index: $indexToRemove',
                    );

                    // Show success message
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Job deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    print(
                      '⚠️ [JOBS DIALOG] Job ID not found in local list: $jobId',
                    );
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Item not found in list'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  print('❌ [JOBS DIALOG] Delete failed. Response: $result');
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
                print('❌ [JOBS DIALOG] Delete error: $e');
                print('❌ [JOBS DIALOG] Stack trace: $stackTrace');
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
}
