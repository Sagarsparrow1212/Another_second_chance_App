import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/merchant/presentation/jobs/providers/add_job_provider.dart';
import 'package:homelyhope/features/merchant/presentation/jobs/providers/jobs_merchant_provider.dart';
import 'package:homelyhope/features/merchant/data/models/jobs/jobs_model.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
// import '../../../jobs/providers/add_job_provider.dart';
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

enum SortBy { title, salary, date, category }

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
        case SortBy.category:
          comparison = a.category.compareTo(b.category);
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
                // Search bar and Add Job button - Responsive
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    child: screenWidth >= 800
                        ? Row(
                            children: [
                              // Search bar
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(fontSize: 15),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                      border: InputBorder.none,
                                      hintText: 'Search for a job',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    onChanged: (_) => _performSearch(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Filter Dropdown
                              Expanded(
                                flex: 2,
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
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  hint: const Text('Filter by Status'),
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
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Added: ${filteredAndSortedJobs.length} jobs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              // Mobile Search
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(fontSize: 15),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Search for a job',
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  onChanged: (_) => _performSearch(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Mobile Filter
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.5,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedStatusFilter,
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
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      hint: const Text('Filter by Status'),
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
                                      },
                                    ),
                                  ),
                                  Text(
                                    'Added: ${filteredAndSortedJobs.length} jobs',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Table Header - Responsive
                SliverToBoxAdapter(
                  child: screenWidth >= 800
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              left: BorderSide(
                                color: AppTheme.primary,
                                width: 4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2, // Title
                                child: _buildSortableHeader(
                                  'Title',
                                  SortBy.title,
                                ),
                              ),
                              Expanded(
                                flex: 2, // Category
                                child: _buildSortableHeader(
                                  'Category',
                                  SortBy.category,
                                ),
                              ),
                              Expanded(
                                flex: 2, // Salary
                                child: _buildSortableHeader(
                                  'Salary',
                                  SortBy.salary,
                                ),
                              ),
                              const Expanded(
                                flex: 1, // Status
                                child: Text(
                                  'Status',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 48,
                              ), // Space for expand icon
                            ],
                          ),
                        )
                      : Container(
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
                              Expanded(
                                child: _buildSortableHeader(
                                  'Title',
                                  SortBy.title,
                                ),
                              ),
                              _buildSortableHeader('Salary', SortBy.salary),
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

  Widget _buildSortableHeader(String title, SortBy sortBy) {
    return GestureDetector(
      onTap: () => _handleSort(sortBy),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _sortBy == sortBy ? AppTheme.primary : Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          if (_sortBy == sortBy)
            Icon(
              _sortOrder == SortOrder.ascending
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 16,
              color: AppTheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job, int index) {
    final screenWidth = MediaQuery.of(context).size.width;

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
                    child: screenWidth >= 800
                        ? Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  job.category,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  job.salaryRange != null
                                      ? '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}'
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
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
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 32,
                                child: isExpanded
                                    ? const Icon(Icons.expand_less_rounded)
                                    : const Icon(Icons.expand_more_rounded),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (job.salaryRange != null) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(width: 8),
                              isExpanded
                                  ? const Icon(Icons.expand_less_rounded)
                                  : const Icon(Icons.expand_more_rounded),
                            ],
                          ),
                  ),

                  // Expanded content
                  if (isExpanded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        customDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Only show category/status in mobile view detail
                              if (screenWidth < 800) ...[
                                if (job.category.isNotEmpty)
                                  _buildDetailRowWithIconBackground(
                                    icon: Icons.business,
                                    iconColor: Colors.green,
                                    label: 'Category',
                                    value: job.category,
                                  ),
                              ],

                              if (job.location != null &&
                                  job.location!.address.isNotEmpty)
                                _buildDetailRowWithIconBackground(
                                  icon: Icons.location_on,
                                  iconColor: Colors.orange,
                                  label: 'Location',
                                  value: job.location!.address,
                                ),

                              // Only show status row in mobile view
                              if (screenWidth < 800)
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
                        customDivider(),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
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
                                  // TODO: Navigate to view job details
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
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddJobPage(jobToEdit: job),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    ref.invalidate(jobsMerchantListProvider);
                                  }
                                },
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                label: Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.red,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: () {
                                  _showDeleteConfirmationDialog(context, job);
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
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    JobModel job,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                // Red Icon with soft background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    color: Colors.red.shade400,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Delete Job',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Are you sure you want to delete "${job.title}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Delete Button
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close dialog

                            try {
                              await ref
                                  .read(addJobProvider.notifier)
                                  .deleteJob(job.id);

                              if (mounted) {
                                ref
                                    .read(snackbarServiceProvider)
                                    .showSuccess('Job deleted successfully');
                                ref.invalidate(jobsMerchantListProvider);
                              }
                            } catch (e) {
                              if (mounted) {
                                ref
                                    .read(snackbarServiceProvider)
                                    .showError(
                                      'Failed to delete job: ${e.toString()}',
                                    );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
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
