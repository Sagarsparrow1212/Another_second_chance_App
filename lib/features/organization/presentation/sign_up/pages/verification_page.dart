import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/organization/presentation/sign_up/providers/organization_providers.dart';
import 'package:homelyhope/core/services/format_service.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  Timer? _navigationTimer;
  int _countdown = 6;
  bool _wasVerified = false;

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _setupAutoNavigation(bool isVerified) async {
    final token = await AuthStorageService.getToken();

    if (token == null) {
      context.go('/login');
    }
    // Only set up timer if status changed from not verified to verified
    if (isVerified && !_wasVerified && mounted) {
      _wasVerified = true;
      _countdown = 6;

      // Update verified status in storage
      await AuthStorageService.updateVerifiedStatus(true);
      log('Updated verified status in storage');

      // Verify the update
      final verified = await AuthStorageService.isVerified();
      log('Verified status after update: $verified');

      // Update countdown every second
      _navigationTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _countdown--;
        });

        // Navigate when countdown reaches 0
        if (_countdown <= 0) {
          timer.cancel();
          if (mounted) {
            log('Countdown reached 0, navigating to dashboard...');
            // Double-check verified status
            final isStillVerified = await AuthStorageService.isVerified();
            log('Verified status before navigation: $isStillVerified');

            if (isStillVerified) {
              // Small delay to ensure everything is ready
              await Future.delayed(Duration(milliseconds: 100));
              if (mounted) {
                context.go('/organization/dashboard');
                log('Navigation to dashboard completed');
              }
            } else {
              log('Warning: Verified status is false, not navigating');
            }
          }
        }
      });
    } else if (!isVerified && _wasVerified) {
      // Reset if status changed from verified to not verified
      _wasVerified = false;
      _navigationTimer?.cancel();
      _navigationTimer = null;
      await AuthStorageService.updateVerifiedStatus(false);
      setState(() {
        _countdown = 6;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizationDetailsAsync = ref.watch(organizationDetailsProvider);
    log('organization detailss: ${organizationDetailsAsync.value}');
    // this above log show null how i debug this?
    // Handle loading state
    if (organizationDetailsAsync.isLoading) {
      return Scaffold(body: Center(child: AppLoader()));
    }

    // Handle error state
    if (organizationDetailsAsync.hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading organization details',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(getOrganizationDetailsUseCaseProvider);
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await AuthStorageService.clearAuthData();
                      context.go('/login');
                    },
                    icon: Icon(Icons.logout),
                    label: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Handle data state
    final data = organizationDetailsAsync.value;
    if (data == null) {
      return Scaffold(
        body: Center(child: Text('No organization data available')),
      );
    }
    // Print full data as JSON for debugging
    print('data: ${const JsonEncoder.withIndent('  ').convert(data.toJson())}');

    // Access properties directly from OrganizationDetailModel
    final currentStatus = data.currentStatus ?? '';
    log('currentStatus: $currentStatus');
    final isVerified = data.verified == true || currentStatus == 'verified';
    log('isVerified: $isVerified');
    final rejection = data.rejection;
    final isRejected = currentStatus == 'Rejected' && rejection != null;
    final isResubmitted = data.resubmitted == true;

    // Setup auto-navigation if verified
    _setupAutoNavigation(isVerified);

    // Build steps based on status
    List<VerifyStepItem> steps;
    String statusTitle;
    String statusDescription;
    Color statusColor;

    if (isRejected) {
      // Rejection steps
      steps = [
        VerifyStepItem(
          title: 'Resubmission Required',
          icon: Icons.refresh,
          description:
              'Please review the feedback and resubmit your application',
          isCompleted: false,
          isProcessing: false,
        ),
      ];
      statusTitle = 'Registration Rejected';
      statusDescription = 'Your application has been reviewed and rejected';
      statusColor = Colors.red;
    } else if (isVerified) {
      // Verified steps
      steps = [
        VerifyStepItem(
          title: 'Registration Complete',
          icon: Icons.check_circle_outline_rounded,
          description: 'Your information has been successfully submitted',
          isCompleted: true,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Under Review',
          icon: FontAwesomeIcons.clock,
          description: 'Our team reviewed your documents',
          isCompleted: true,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Email Notification',
          icon: Icons.email_outlined,
          description: 'You received an email confirming verification',
          isCompleted: true,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Account Activated',
          icon: FontAwesomeIcons.shield,
          description: 'Your account is now active and ready to use',
          isCompleted: true,
          isProcessing: false,
        ),
      ];
      statusTitle = 'Registration Verified!';
      statusDescription = 'Your account has been successfully verified';
      statusColor = Colors.green;
    } else if (isResubmitted) {
      // Resubmission under review steps
      steps = [
        VerifyStepItem(
          title: 'Resubmission Complete',
          icon: Icons.check_circle_outline_rounded,
          description:
              'Your updated information has been successfully submitted',
          isCompleted: true,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Under Review',
          icon: FontAwesomeIcons.clock,
          description:
              'Our team is currently reviewing your resubmitted documents',
          isCompleted: false,
          isProcessing: true,
        ),
        VerifyStepItem(
          title: 'Email Notification',
          icon: Icons.email_outlined,
          description: 'You\'ll receive an email once verification is complete',
          isCompleted: false,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Account Activation',
          icon: FontAwesomeIcons.shield,
          description: 'Your account will be activated after approval',
          isCompleted: false,
          isProcessing: false,
        ),
      ];
      statusTitle = 'Resubmission Under Review';
      statusDescription =
          'Your resubmitted profile is being reviewed for verification';
      statusColor = Color(0xff1c398e);
    } else {
      // Under review steps (first submission)
      steps = [
        VerifyStepItem(
          title: 'Registration Complete',
          icon: Icons.check_circle_outline_rounded,
          description: 'Your information has been successfully submitted',
          isCompleted: true,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Under Review',
          icon: FontAwesomeIcons.clock,
          description: 'Our team is currently verifying your documents',
          isCompleted: false,
          isProcessing: true,
        ),
        VerifyStepItem(
          title: 'Email Notification',
          icon: Icons.email_outlined,
          description: 'You\'ll receive an email once verification is complete',
          isCompleted: false,
          isProcessing: false,
        ),
        VerifyStepItem(
          title: 'Account Activation',
          icon: FontAwesomeIcons.shield,
          description: 'Your account will be activated after approval',
          isCompleted: false,
          isProcessing: false,
        ),
      ];
      statusTitle = 'Registration Successful!';
      statusDescription = 'Your Profile is being reviewed for verification';
      statusColor = Color(0xff1c398e);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Verification Status'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(getOrganizationDetailsUseCaseProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Status icon and title
            Stack(
              alignment: Alignment.center,
              children: [
                SpinKitPulse(
                  color: statusColor,
                  size: 120,
                  duration: Duration(seconds: 2),
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRejected
                        ? Icons.error_outline
                        : isVerified
                        ? Icons.check_circle_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              statusTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              statusDescription,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (isVerified) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Redirecting to Dashboard in $_countdown second${_countdown != 1 ? 's' : ''}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isRejected) ...[
              SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[900]),
                          SizedBox(width: 8),
                          Text(
                            'Rejection Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Reason: ${rejection.reason.isNotEmpty ? rejection.reason : 'No reason provided'}',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Rejected at: ${formatDateTime(rejection.rejectedAt.isNotEmpty ? rejection.rejectedAt : 'Unknown')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(height: 16),
            // Steps list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: steps[index].isProcessing
                            ? Border.all(color: Colors.grey[300]!)
                            : null,
                        color: steps[index].isCompleted
                            ? (isRejected ? Colors.red[50] : Color(0xFFf8fafc))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: steps[index].isCompleted
                                ? (isRejected
                                      ? Colors.red[100]
                                      : Colors.green[100])
                                : Color(0xffd2d7e8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            steps[index].isCompleted
                                ? (isRejected
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline_rounded)
                                : steps[index].icon,
                            color: !steps[index].isProcessing
                                ? (steps[index].isCompleted
                                      ? (isRejected ? Colors.red : Colors.green)
                                      : Color(0xff62748e))
                                : steps[index].isCompleted
                                ? (isRejected ? Colors.red : Colors.green)
                                : Color(0xff1c398e),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                steps[index].title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            if (steps[index].isProcessing)
                              SpinKitThreeBounce(
                                color: Color(0xff1c398e),
                                size: 12,
                                duration: Duration(seconds: 2),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            steps[index].description,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerifyStepItem {
  String title;
  String description;
  IconData icon;
  bool isCompleted;
  bool isProcessing;

  VerifyStepItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isCompleted,
    required this.isProcessing,
  });
}
