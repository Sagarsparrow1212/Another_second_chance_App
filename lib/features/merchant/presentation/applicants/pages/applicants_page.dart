import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/services/format_service.dart';
import 'package:homelyhope/features/common/chat/presentation/utils/chat_helper.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/merchant/presentation/applicants/providers/applicants_provider.dart';
import 'package:homelyhope/features/common/chat/presentation/providers/chat_providers.dart';

import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';

class ApplicantsPage extends ConsumerWidget {
  const ApplicantsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(merchantApplicationsProvider);

    return Scaffold(
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Applicants'),
      body: applicationsAsync.when(
        data: (applications) {
          if (applications.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(merchantApplicationsProvider.future),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent:
                              200, // Fixed height to prevent bottom overflow
                        ),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return _ApplicantCard(
                        application: applications[index],
                        ref: ref,
                        onApprove: () async {
                          try {
                            await ref
                                .read(applicantsRepositoryProvider)
                                .approveApplication(applications[index].id);
                            final _ = ref.refresh(merchantApplicationsProvider);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to approve: $e')),
                            );
                          }
                        },
                        onReject: () async {
                          try {
                            await ref
                                .read(applicantsRepositoryProvider)
                                .rejectApplication(applications[index].id);
                            final _ = ref.refresh(merchantApplicationsProvider);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to reject: $e')),
                            );
                          }
                        },
                      );
                    },
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: applications.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ApplicantCard(
                      application: applications[index],
                      ref: ref,
                      onApprove: () async {
                        try {
                          await ref
                              .read(applicantsRepositoryProvider)
                              .approveApplication(applications[index].id);
                          final _ = ref.refresh(merchantApplicationsProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to approve: $e')),
                          );
                        }
                      },
                      onReject: () async {
                        try {
                          await ref
                              .read(applicantsRepositoryProvider)
                              .rejectApplication(applications[index].id);
                          final _ = ref.refresh(merchantApplicationsProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to reject: $e')),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No applicants found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Job applications will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final dynamic application;
  final WidgetRef ref;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApplicantCard({
    required this.application,
    required this.ref,
    required this.onApprove,
    required this.onReject,
  });

  String? getAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    try {
      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        return avatarUrl;
      }
      if (avatarUrl.startsWith('/')) {
        return '$baseUrl$avatarUrl';
      }
      return '$baseUrl/$avatarUrl';
    } catch (e) {
      return null;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = const Color(0xFF2E7D32);
        break;
      case 'rejected':
        color = const Color(0xFFC62828);
        break;
      default:
        color = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.15), width: 0.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade50,
                  backgroundImage: application.applicant.photoUrl != null
                      ? NetworkImage(
                          getAvatarUrl(application.applicant.photoUrl!)!,
                        )
                      : null,
                  child: application.applicant.photoUrl == null
                      ? Icon(
                          Icons.person,
                          color: Colors.grey.shade300,
                          size: 24,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            application.applicant.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(application.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDateTime(application.appliedAt),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.work_outline, size: 14, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    application.job.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Chat Button
              InkWell(
                onTap: () {
                  ChatHelper.startChatWithUser(
                    ref: ref,
                    context: context,
                    targetUserId: application.applicant.id,
                    targetUserName: application.applicant.fullName,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Approve/Rejected Buttons
              Expanded(
                child: Row(
                  children: [
                    if (application.status == 'pending') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3F7C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onReject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: Colors.red.shade100,
                              width: 0.8,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else if (application.status == 'approved') ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Approved',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (application.status == 'rejected') ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cancel,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rejected',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//}
