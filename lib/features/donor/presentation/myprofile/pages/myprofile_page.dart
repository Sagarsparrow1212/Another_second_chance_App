import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/donor/data/models/profile/donor_profile_model.dart';
import 'package:intl/intl.dart';
import '../../../../common/Drawer/pages/dynamic_drawer.dart';
import '../providers/donor_profile_provider.dart';
import 'package:homelyhope/core/utils/formatters.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  // Detect scroll position to change drawer icon color when header collapses
  final ScrollController _scrollController = ScrollController();
  Color _iconColor = Colors.white;

  void _onScroll() {
    // Change icon color based on scroll position
    if (_scrollController.position.pixels > 180) {
      if (_iconColor != AppTheme.primary) {
        setState(() => _iconColor = AppTheme.primary);
      }
    } else {
      if (_iconColor != Colors.white) {
        setState(() => _iconColor = Colors.white);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(donorProfileProvider);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final profileAsync = ref.watch(donorProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: CustomAppBar(title: 'My Profile'),
      body: profileAsync.when(
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
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
                  onPressed: () => ref.invalidate(donorProfileProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => RefreshIndicator(
          edgeOffset: 100,
          onRefresh: () async {
            ref.invalidate(donorProfileProvider);
            await ref.read(donorProfileProvider.future);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Custom SliverAppBar with profile header
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 80,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: _buildProfileHeader(profile),
                ),

                // Profile details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Card
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                        children: [
                          _buildInfoRow(
                            icon: Icons.person,
                            iconColor: Colors.blue,
                            label: 'Full Name',
                            value: profile.fullName,
                          ),
                          _buildInfoRow(
                            icon: Icons.male,
                            iconColor: Colors.purple,
                            label: 'Gender',
                            value: profile.gender.isNotEmpty
                                ? profile.gender
                                : 'Not specified',
                          ),
                          _buildInfoRow(
                            icon: Icons.volunteer_activism,
                            iconColor: Colors.pink,
                            label: 'Preferred Donation',
                            value: profile.preferredDonationType.isNotEmpty
                                ? profile.preferredDonationType
                                : 'Not specified',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Information Card
                      _buildSectionCard(
                        title: 'Contact Information',
                        icon: Icons.contact_mail_outlined,
                        children: [
                          _buildInfoRow(
                            icon: Icons.email,
                            iconColor: Colors.orange,
                            label: 'Email',
                            value: profile.email,
                          ),
                          _buildInfoRow(
                            icon: Icons.phone,
                            iconColor: Colors.green,
                            label: 'Phone',
                            value: profile.phone.isNotEmpty
                                ? Formatters.formatPhoneNumber(profile.phone)
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            icon: Icons.location_on,
                            iconColor: Colors.red,
                            label: 'Address',
                            value: profile.address.isNotEmpty
                                ? profile.address
                                : 'Not provided',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Account Information Card
                      _buildSectionCard(
                        title: 'Account Information',
                        icon: Icons.account_circle_outlined,
                        children: [
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            iconColor: Colors.teal,
                            label: 'Member Since',
                            value: _formatDate(profile.createdAt),
                          ),
                          _buildInfoRow(
                            icon: Icons.update,
                            iconColor: Colors.indigo,
                            label: 'Last Updated',
                            value: _formatDate(profile.updatedAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: AppTheme.primary),
                          ),
                          onPressed: () {
                            // Navigate to signup page with donor data for editing
                            context.push('/donor/signUp', extra: profile);
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                          ),
                          label: Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.lock_outline),
                          label: const Text(
                            'Change Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(DonorProfileModel profile) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      width: width * 0.9,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primary, Color(0xFF2CBFA8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // const SizedBox(height: 40),
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : 'D',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  // Verified badge
                  if (profile.verified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              // Email
              Text(
                profile.email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              // Status badges
              _buildStatusBadge(
                label: profile.isActive ? 'Active' : 'Inactive',
                icon: profile.isActive ? Icons.check_circle : Icons.cancel,
                color: profile.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isSmall = false,
  }) {
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
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: isSmall ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
