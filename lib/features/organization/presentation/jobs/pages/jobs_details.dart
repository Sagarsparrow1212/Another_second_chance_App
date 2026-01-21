import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/organization/presentation/jobs/providers/jobs_provider.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Placeholder provider, replace with actual provider for job detail.

class ViewJobDetailPage extends ConsumerWidget {
  final String jobId;

  const ViewJobDetailPage({Key? key, required this.jobId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobDetailAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true, title: 'Job Details'),
      body: jobDetailAsync.when(
        data: (jobDetail) {
          final job = jobDetail.job;
          final salary = job.salaryRange;
          final salaryText = salary != null
              ? '₹${salary.min} - ₹${salary.max}'
              : 'Not specified';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job.merchant != null)
                  _buildJobMerchantDetail(job.merchant!),
                const SizedBox(height: 16),
                _buildJobDetail(context, job),
                // Add more job details as needed
              ],
            ),
          );
        },
        loading: () => Center(child: AppLoader()),
        error: (err, stack) => Center(child: Text('Error loading job: $err')),
      ),
    );
  }

  Widget _buildJobDetail(BuildContext context, JobModel job) {
    final salary = job.salaryRange;
    final salaryText = salary != null
        ? '₹${salary.min} - ₹${salary.max}'
        : 'Not specified';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                LineAwesomeIcons.briefcase_solid,
                color: AppTheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Job Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Job Title',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            job.title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),

          Text(
            job.status,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Salary',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            salaryText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            job.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildJobMerchantDetail(MerchantInfo job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.8),
            const Color(0xFF2CBFA8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Merchant',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Text(
            job.businessName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
