import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/organization/presentation/myprofile/providers/profile_provider.dart';
import '../../../../common/Drawer/pages/dynamic_drawer.dart';
import '../../../../common/widgets/custom_appbar.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  bool _hasInitialized = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _invalidateOrganizationProfileDetails();
      }
    });
  }

  void _invalidateOrganizationProfileDetails() {
    ref.invalidate(organizationProfileDetailsProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized && mounted) {
      _hasInitialized = true;
      _invalidateOrganizationProfileDetails();
    }
  }

  String _getStatusText(String? status) {
    if (status == null || status.isEmpty) return 'Pending';
    return status;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String? _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    return '$baseUrl/$url';
  }

  NetworkImage? _getProfileImage(dynamic data) {
    // print(data.json());
    if (data.logo == null || data.logo!.isEmpty) return null;
    final url = _buildImageUrl(data.logo);
    if (url == null) return null;
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final organizationProfileDetails = ref.watch(
      organizationProfileDetailsProvider,
    );

    // Log organization details if available
    if (organizationProfileDetails.value != null) {
      log(
        'organizationProfileDetails: ${organizationProfileDetails.value?.name ?? 'N/A'}',
      );
    } else if (organizationProfileDetails.isLoading) {
      log('organizationProfileDetails: Loading...');
    } else if (organizationProfileDetails.hasError) {
      log(
        'organizationProfileDetails: Error - ${organizationProfileDetails.error}',
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'My Profile'),
      body: RefreshIndicator(
        edgeOffset: 100,
        onRefresh: () async {
          _invalidateOrganizationProfileDetails();
        },
        child: organizationProfileDetails.when(
          data: (data) => _buildProfileContent(data),
          loading: () => Center(child: AppLoader()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading profile: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _invalidateOrganizationProfileDetails(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(data) {
    print('Building profile content for organization: ${data.logo}');
    final topPadding = MediaQuery.of(context).padding.top;
    final status = _getStatusText(data.currentStatus);
    final statusColor = _getStatusColor(data.currentStatus);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: topPadding + 80,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 40), // let width take child
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  // Pass organization data for editing
                  context.push('/organization/signUp', extra: data);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeaderCard(data, status, statusColor),
          const SizedBox(height: 16),

          // Contact Information Card
          _buildContactInfoCard(data),
          const SizedBox(height: 16),

          // Organization Details Card
          _buildOrganizationDetailsCard(data),
          const SizedBox(height: 16),

          // Organization Documents Card
          if (data.documents != null && data.documents!.isNotEmpty)
            _buildDocumentsCard(data),
          if (data.documents != null && data.documents!.isNotEmpty)
            const SizedBox(height: 16),

          // Organization Photos Card
          if (data.photos != null && data.photos!.isNotEmpty)
            _buildPhotosCard(data),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(data, String status, Color statusColor) {
    return Container(
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Profile Picture with Verification Badge
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _getProfileImage(data),
                  child: _getProfileImage(data) == null
                      ? Text(
                          (data.name.isNotEmpty ? data.name[0] : 'O')
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              // Verification Badge
              if (data.verified == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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

          // Organization Name
          Text(
            data.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Organization Type
          Text(
            data.orgType.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Status: $status',
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildContactInfoCard(data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactItem(Icons.email, 'Email', data.email),
            const SizedBox(height: 16),
            if (data.contactPhone != null && data.contactPhone!.isNotEmpty)
              _buildContactItem(Icons.phone, 'Phone', data.contactPhone!),
            if (data.contactPhone != null && data.contactPhone!.isNotEmpty)
              const SizedBox(height: 16),
            _buildContactItem(
              Icons.location_on,
              'Address',
              '${data.streetAddress}\n${data.city}, ${data.state} ${data.zipCode}\n${data.country}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.purple, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
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
    );
  }

  Widget _buildOrganizationDetailsCard(data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Organization Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDetailBox(
                    Icons.business,
                    'Type',
                    data.orgType,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailBox(
                    Icons.public,
                    'Country',
                    data.country,
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailBox(
                    Icons.verified,
                    'Verified',
                    data.verified == true ? 'Yes' : 'No',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailBox(
                    Icons.calendar_today,
                    'Created',
                    data.createdAt ?? 'N/A',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailBox(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsCard(data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Organization Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.documents?.length ?? 0,
                itemBuilder: (context, index) {
                  final doc = data.documents![index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageUrl(doc.docUrl) != null
                          ? Image.network(
                              _buildImageUrl(doc.docUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.description,
                                    color: Colors.grey[600],
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.description,
                                color: Colors.grey[600],
                                size: 40,
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

  Widget _buildPhotosCard(data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library, color: Colors.pink, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Organization Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: data.photos?.length ?? 0,
                itemBuilder: (context, index) {
                  final photo = data.photos![index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageUrl(photo.photoUrl) != null
                          ? Image.network(
                              _buildImageUrl(photo.photoUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.photo,
                                    color: Colors.grey[600],
                                    size: 40,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.photo,
                                color: Colors.grey[600],
                                size: 40,
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
