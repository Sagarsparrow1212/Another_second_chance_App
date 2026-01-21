import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/merchant/presentation/jobs/providers/jobs_merchant_provider.dart';
import 'package:homelyhope/features/merchant/data/models/jobs/jobs_model.dart';
import 'package:intl/intl.dart';
import '../../../../common/auth/data/services/auth_storage_service.dart';
import '../../../../common/widgets/custom_appbar.dart';
import '../../../../common/widgets/divider.dart';
import 'add_job_page.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

enum SortBy { title, salary, date }

enum SortOrder { ascending, descending }

class _JobsPageState extends ConsumerState<JobsPage> {
  final ValueNotifier<Set<String>> expandedJobIds = ValueNotifier(<String>{});
  final TextEditingController _searchController = TextEditingController();
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.title;
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
        ref.invalidate(jobsMerchantListProvider);
      }
    });
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
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

  List<JobModel> _filterAndSortJobs(List<JobModel> jobs) {
    // Filter by search query
    List<JobModel> filtered = jobs;
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = jobs.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query) ||
            job.category.toLowerCase().contains(query) ||
            (job.location?.address.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort the filtered list
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.title:
          comparison = a.title.compareTo(b.title);
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
    _searchController.dispose();
    super.dispose();
  }

  void getToken() async {
    final token = await AuthStorageService.getToken();
    print(token);
  }

  @override
  Widget build(BuildContext context) {
    getToken();
    final jobsAsync = ref.watch(jobsMerchantListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      drawer: AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(title: 'My Jobs'),

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
                  ref.invalidate(jobsMerchantListProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        // ✅ Success state - Display jobs
        data: (jobsResponse) {
          final filteredAndSortedJobs = _filterAndSortJobs(jobsResponse.jobs);

          if (jobsResponse.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.work_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs posted yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first job posting to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            edgeOffset: 100,
            key: const ValueKey('merchant_jobs_refresh'),
            // ✅ Pull to refresh
            onRefresh: () async {
              ref.invalidate(jobsMerchantListProvider);
              // Wait for the provider to refresh
              await ref.read(jobsMerchantListProvider.future);
            },
            child: CustomScrollView(
              key: const ValueKey('merchant_jobs_scroll'),
              slivers: [
                SliverToBoxAdapter(child: Container(height: 100)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            context.push('/merchant/add-job');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'Add Job',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Search bar and Add Job button
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
                                color: Colors.grey.shade300,
                                width: 1,
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
                                    width: 1.5,
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
                        const SizedBox(width: 12),

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.5,
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatusFilter,
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
                              'Filter by Status',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Status'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'closed',
                                child: Text('Closed'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatusFilter = value;
                              });
                              // TODO: Implement filter by status
                            },
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.end,
                          'Added: ${filteredAndSortedJobs.length} jobs',
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
                        right: BorderSide(color: AppTheme.primary, width: 4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                if (filteredAndSortedJobs.isEmpty)
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
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final job = filteredAndSortedJobs[index];
                        return _buildJobCard(context, job, index);
                      }, childCount: filteredAndSortedJobs.length),
                    ),
                  ),
              ],
            ),
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
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        if (job.salaryRange != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                              // if (_sortBy == SortBy.salary) ...[
                              //   SizedBox(width: 4),
                              //   Icon(
                              //     _sortOrder == SortOrder.ascending
                              //         ? Icons.arrow_upward
                              //         : Icons.arrow_downward,
                              //     size: 14,
                              //     color: AppTheme.primary,
                              //   ),
                              // ],
                            ],
                          ),
                        ],
                        SizedBox(width: 8),
                        isExpanded
                            ? Icon(Icons.expand_less_rounded)
                            : Icon(Icons.expand_more_rounded),
                      ],
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
                                  if (job.category.isNotEmpty)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.business,
                                      iconColor: Colors.green,
                                      label: 'Category',
                                      value: job.category,
                                    ),

                                  // Description - Info icon with blue background

                                  // Location - Map pin icon with orange background
                                  if (job.location != null &&
                                      job.location!.address.isNotEmpty)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.location_on,
                                      iconColor: Colors.orange,
                                      label: 'Location',
                                      value: job.location!.address,
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
                                          width: 32,
                                          height: 32,
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
                                            size: 18,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                  if (job.description.isNotEmpty)
                                    _buildDetailRowWithIconBackground(
                                      icon: Icons.info_outline,
                                      iconColor: Colors.blue,
                                      label: 'Description',
                                      value: job.description,
                                      isMultiline: true,
                                    ),
                                ],
                              ),
                            ),
                            // Category - Briefcase icon with green background

                            // Divider before buttons
                            customDivider(),

                            // Action buttons
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
                                    onPressed: () {
                                      // TODO: Navigate to view job details page
                                      // context.push('/merchant/view-job/${job.id}');
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
                                      // Navigate to edit job page
                                      final result = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AddJobPage(jobToEdit: job),
                                        ),
                                      );
                                      // Refresh list if update was successful
                                      if (result == true && mounted) {
                                        ref.invalidate(
                                          jobsMerchantListProvider,
                                        );
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
                                      // TODO: Navigate to delete job page or show dialog
                                      // context.push('/merchant/delete-job/${job.id}');
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
      child: label == 'Description'
          ? Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: iconDarkColor),
                      ),
                      const SizedBox(width: 12),
                      // Label on the left
                      SizedBox(
                        width: 100,
                        child: Text(
                          textAlign: TextAlign.left,
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,

                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                      maxLines: isMultiline ? null : 3,
                      overflow: isMultiline ? null : TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: isMultiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconDarkColor),
                ),
                const SizedBox(width: 12),
                // Label on the left
                SizedBox(
                  width: 100,
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
}

class SortHeader extends StatelessWidget {
  final bool isAscending;
  final VoidCallback onSortTap;

  const SortHeader({
    super.key,
    required this.isAscending,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left Line + Title
          Row(
            children: [
              Container(
                width: 6,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Title",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),

          /// Salary Sort Button
          InkWell(
            onTap: onSortTap,
            child: Row(
              children: [
                const Text(
                  "Salary",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(width: 4),
                Icon(
                  isAscending
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
