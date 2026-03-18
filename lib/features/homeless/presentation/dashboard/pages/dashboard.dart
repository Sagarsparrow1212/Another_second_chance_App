import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/homeless/data/models/dashboard/dashboard_model.dart';
import 'package:homelyhope/features/homeless/presentation/dashboard/providers/dashboard_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  DateTime? lastPressed;
  bool _hasInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(homelessDashboardProvider);
      }
      fetchUserDetails();
    });
  }

  IconData _getIconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'briefcase':
        return FontAwesomeIcons.briefcase;
      case 'check-circle':
        return FontAwesomeIcons.circleCheck;
      case 'heart-handshake':
        return FontAwesomeIcons.handHoldingHeart;
      case 'trending-up':
        return FontAwesomeIcons.arrowTrendUp;
      case 'briefcase-check':
        return FontAwesomeIcons.briefcase;
      case 'clock':
        return FontAwesomeIcons.clock;
      case 'building':
        return FontAwesomeIcons.building;
      case 'store':
        return FontAwesomeIcons.store;
      default:
        return FontAwesomeIcons.chartLine;
    }
  }

  String? _userName;

  void fetchUserDetails() async {
    final userName = await fetchUserName();
    setState(() {
      _userName = userName;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dashboardAsync = ref.watch(homelessDashboardProvider);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        final now = DateTime.now();
        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          ref.read(snackbarServiceProvider).showInfo("Tap again to exit");
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: const AppDrawer(),
        appBar: CustomAppBar(title: 'Dashboard'),
        body: RefreshIndicator(
          edgeOffset: 100,
          onRefresh: () async {
            ref.invalidate(homelessDashboardProvider);
            await ref.read(homelessDashboardProvider.future);
          },
          child: dashboardAsync.when(
            loading: () => Center(child: AppLoader()),
            error: (error, stack) => _buildErrorState(error),
            data: (dashboard) => _buildDashboardContent(dashboard),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(homelessDashboardProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(HomelessDashboardResponse dashboard) {
    final quickStats = dashboard.quickStats;
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: topPadding + 75,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          RichText(
            text: TextSpan(
              text: '${createGreetingBasedOnTime()}! 👋, ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.grey[800],
              ),
              children: [
                TextSpan(
                  text: _userName ?? dashboard.userInfo.fullName,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            'Here\'s what\'s happening with your opportunities',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),
          // Quick Stats Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
              return GridView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 160,
                ),
                children: [
                  if (quickStats.matchingJobs != null)
                    _buildStatCard(
                      title: quickStats.matchingJobs!.title,
                      value: quickStats.matchingJobs!.value.toString(),
                      icon: FontAwesomeIcons.magnifyingGlass,
                      color: Colors.blue,
                      subtitle: quickStats.matchingJobs!.description,
                    ),
                  _buildStatCard(
                    title: quickStats.activeJobs.title,
                    value: quickStats.activeJobs.value.toString(),
                    icon: _getIconForName(quickStats.activeJobs.icon),
                    color: Colors.teal,
                    subtitle: quickStats.activeJobs.description,
                  ),
                  _buildStatCard(
                    title: quickStats.appliedJobs.title,
                    value: quickStats.appliedJobs.value.toString(),
                    icon: _getIconForName(quickStats.appliedJobs.icon),
                    color: Colors.green,
                    subtitle: quickStats.appliedJobs.description,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
          // Total Donations Card
          _buildDonationsCard(quickStats.totalDonations),

          const SizedBox(height: 16),
          // Recent Jobs Section
          if (dashboard.recentJobs.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Jobs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/homeless/jobs'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dashboard.recentJobs
                .take(3)
                .map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentJobCard(job),
                  ),
                ),
          ],

          const SizedBox(height: 16),
          // Recent Donations Section
          if (dashboard.recentDonations.isNotEmpty) ...[
            Text(
              'Recent Donations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            ...dashboard.recentDonations
                .take(5)
                .map(
                  (donation) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecentDonationCard(donation),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(icon, size: 18, color: color),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsCard(QuickStatItem donation) {
    final formattedAmount = donation.formatted ?? '\$${donation.value}';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FaIcon(
                _getIconForName(donation.icon),
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedAmount,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    donation.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobCard(RecentJob job) {
    return InkWell(
      onTap: () {
        // Navigate to job details
        ref.read(snackbarServiceProvider).showInfo('Job details coming soon');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.category,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: job.status == 'active'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: job.status == 'active'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            if (job.salaryRange != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.dollarSign,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${job.salaryRange!.min} - \$${job.salaryRange!.max}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (job.location != null && job.location!.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.locationDot,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location!.address,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (job.postedBy != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  FaIcon(
                    job.postedBy!.type == 'merchant'
                        ? FontAwesomeIcons.store
                        : FontAwesomeIcons.building,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Posted by ${job.postedBy!.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${job.daysAgo}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDonationCard(RecentDonation donation) {
    final statusColor = _getDonationStatusColor(donation.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.handHoldingHeart,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.donorName.isNotEmpty
                          ? donation.donorName
                          : donation.donorEmail,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      donation.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  donation.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Amount: ',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                '\$${donation.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          if (donation.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              donation.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (donation.organization != null &&
              donation.organization!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.building,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  donation.organization!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            donation.timeAgo.isNotEmpty
                ? donation.timeAgo
                : _formatTimeAgo(donation.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Color _getDonationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'failed':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInsightCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
