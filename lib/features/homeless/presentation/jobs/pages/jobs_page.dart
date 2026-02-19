import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/homeless/presentation/jobs/pages/job_history_page.dart';
import 'package:homelyhope/features/organization/presentation/jobs/providers/jobs_provider.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:intl/intl.dart';

import '../../../../common/auth/data/services/auth_storage_service.dart';
import '../../../../common/widgets/custom_appbar.dart';
import '../../../../common/widgets/divider.dart';
import 'package:homelyhope/features/homeless/presentation/jobs/widgets/application_sending_dialog.dart';
import 'package:homelyhope/features/homeless/presentation/jobs/widgets/application_success_dialog.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.title;
  SortOrder _sortOrder = SortOrder.ascending;
  String? _searchQuery;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(allJobsProvider);
      }
    });
  }

  @override
  void dispose() {
    expandedJobIds.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

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
        _sortOrder = _sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;
      } else {
        _sortBy = sortBy;
        _sortOrder = SortOrder.ascending;
      }
    });
  }

  void printToken() async {
    final token = await AuthStorageService.getToken();
    print(token);
  }

  List<JobModel> _filterAndSortJobs(List<JobModel> jobs) {
    // Only show active jobs for homeless users
    List<JobModel> filtered = jobs
        .where((job) => job.status == 'active')
        .toList();

    // Filter by search query
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

    // Filter by category
    if (_selectedCategoryFilter != null && _selectedCategoryFilter != 'all') {
      filtered = filtered
          .where(
            (job) =>
                job.category.toLowerCase() ==
                _selectedCategoryFilter!.toLowerCase(),
          )
          .toList();
    }

    // Sort the filtered list
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.title:
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
  Widget build(BuildContext context) {
    printToken();
    final jobsAsync = ref.watch(allJobsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(
        title: 'Available Jobs',
        actions: [
          IconButton(
            icon: Icon(
              Icons.history,
              color: AppTheme.primary.withValues(alpha: 0.85),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JobHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => Center(child: AppLoader()),
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
                onPressed: () => ref.invalidate(allJobsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (jobsResponse) {
          final filteredAndSortedJobs = _filterAndSortJobs(jobsResponse.jobs);

          if (jobsResponse.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_off_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs available',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new job opportunities',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            edgeOffset: 100,
            onRefresh: () async {
              ref.invalidate(allJobsProvider);
              await ref.read(allJobsProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: 100)),
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                          hintText:
                              'Search jobs by title, category, location...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        onChanged: _onSearchChanged,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category filter dropdown
                        SizedBox(
                          width: screenWidth * 0.5,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategoryFilter,
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
                              'Category',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All Categories'),
                              ),
                              DropdownMenuItem(
                                value: 'retail',
                                child: Text('Retail'),
                              ),
                              DropdownMenuItem(
                                value: 'food service',
                                child: Text('Food Service'),
                              ),
                              DropdownMenuItem(
                                value: 'warehouse',
                                child: Text('Warehouse'),
                              ),
                              DropdownMenuItem(
                                value: 'cleaning',
                                child: Text('Cleaning'),
                              ),
                              DropdownMenuItem(
                                value: 'construction',
                                child: Text('Construction'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryFilter = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          '${filteredAndSortedJobs.length} jobs found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
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
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title column - sortable
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleSort(SortBy.title),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Job Title',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _sortBy == SortBy.title
                                        ? AppTheme.primary
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                        GestureDetector(
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
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
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
                      ],
                    ),
                  ),
                ),
                // Jobs list
                if (filteredAndSortedJobs.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100),
                          // SliverToBoxAdapter(child: SizedBox(height: 100)),
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs found matching your search',
                            style: TextStyle(
                              color: Colors.grey.shade600,
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
                        return _buildJobCard(context, job);
                      }, childCount: filteredAndSortedJobs.length),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedJobIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(job.id);
        return GestureDetector(
          onTap: () {
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
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Salary
                  Padding(
                    padding: const EdgeInsets.only(right: 4, left: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        if (job.salaryRange != null)
                          Text(
                            '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),

                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: const Icon(Icons.expand_more_rounded),
                        ),
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
                              // Category
                              if (job.category.isNotEmpty)
                                _buildDetailRow(
                                  icon: Icons.category_outlined,
                                  iconColor: Colors.purple,
                                  label: 'Category',
                                  value: job.category,
                                ),
                              // Business/Merchant
                              if (job.merchant != null)
                                _buildDetailRow(
                                  icon: Icons.store_outlined,
                                  iconColor: Colors.green,
                                  label: 'Company',
                                  value: job.merchant!.businessName,
                                ),
                              // Location
                              if (job.location?.address != null)
                                _buildDetailRow(
                                  icon: Icons.location_on_outlined,
                                  iconColor: Colors.red,
                                  label: 'Location',
                                  value: job.location!.address,
                                ),
                              // Posted Date
                              if (job.createdAt.isNotEmpty)
                                _buildDetailRow(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: Colors.blue,
                                  label: 'Posted',
                                  value: _formatDate(job.createdAt),
                                ),
                              // Description
                              if (job.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.description_outlined,
                                              size: 16,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Description',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        job.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        customDivider(),
                        // Action buttons - View & Apply
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // View Details Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  // TODO: Navigate to job details page
                                  _showJobDetailsDialog(context, job);
                                },
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                                label: Text(
                                  'View',
                                  style: TextStyle(color: Colors.blue.shade700),
                                ),
                              ),
                              // Apply Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.green.shade500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  _confirmAndApply(context, ref, job);
                                },
                                icon: const Icon(
                                  Icons.send_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Apply',
                                  style: TextStyle(color: Colors.white),
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

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showJobDetailsDialog(BuildContext context, JobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          job.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (job.salaryRange != null)
                _buildDialogRow(
                  'Salary',
                  '\$${job.salaryRange!.min.toStringAsFixed(0)} - \$${job.salaryRange!.max.toStringAsFixed(0)}',
                ),
              _buildDialogRow('Category', job.category),
              if (job.merchant != null)
                _buildDialogRow('Company', job.merchant!.businessName),
              if (job.location?.address != null)
                _buildDialogRow('Location', job.location!.address),
              _buildDialogRow('Posted', _formatDate(job.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                job.description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context);
                  _confirmAndApply(context, ref, job);
                },
                child: const Text(
                  'Apply Now',
                  style: TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmAndApply(
    BuildContext context,
    WidgetRef ref,
    JobModel job,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Ready to Apply?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'You are about to apply for '),
                    TextSpan(
                      text: job.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '. Make sure your profile is up to date before proceeding.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        elevation: 2,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      // 1. Show Sending Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ApplicationSendingDialog(
          companyName: job.merchant?.businessName ?? 'the company',
        ),
      );

      try {
        // 2. Perform API Call
        await ref.read(applyJobProvider(job.id).future);

        // Artificial delay for animation to be seen if API is too fast
        await Future.delayed(const Duration(seconds: 2));

        if (context.mounted) {
          // 3. Close Sending Dialog
          Navigator.of(context).pop();

          // 4. Show Success Dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => ApplicationSuccessDialog(
              jobTitle: job.title,
              companyName: job.merchant?.businessName ?? 'the company',
            ),
          );

          // Refresh job history
          ref.invalidate(jobHistoryProvider);
        }
      } catch (e) {
        if (context.mounted) {
          // Close Sending Dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to apply: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}
