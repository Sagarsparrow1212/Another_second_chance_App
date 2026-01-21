import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/services/format_service.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import '../../../../../core/contanst/contanst.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../common/widgets/custom_appbar.dart';
import '../../../data/models/myprofile/myprofile_model.dart';
import '../providers/profile_provider.dart';

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
    // Invalidate profile once when page is first loaded
    // Use post-frame callback to ensure ref is available and mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(profileMerchantProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileMerchant = ref.watch(profileMerchantProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'My Profile'),
      body: profileMerchant.when(
        data: (data) => _buildProfileContent(data),
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
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
                onPressed: () {
                  // Retry by invalidating provider
                  ref.invalidate(profileMerchantProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(MyProfileModel data) {
    final topPadding = MediaQuery.of(context).padding.top;
    return RefreshIndicator(
      edgeOffset: 100,
      onRefresh: () async {
        ref.invalidate(profileMerchantProvider);
        await ref.read(profileMerchantProvider.future);
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 80,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.primary,
                    Color(0xFF2CBFA8),
                  ],
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.businessName}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      '${data.businessType}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInfoCard(
                          'Account',
                          data.isActive ? 'Active' : 'Inactive',
                          FontAwesomeIcons.shield,
                        ),
                        _buildInfoCard(
                          'Member Since',
                          data.createdAt,
                          Icons.email,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildBusinessInformationCard(data),
            _buildContactPersonCard(data),

            _buildDocumentsCard(data),
            _buildAccountStatusCard(data),
            _buildTimelineCard(data),
            SizedBox(height: 16),
            _buildActionButtons(data),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInformationCard(MyProfileModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleCard('Business Information'),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.email,
            label: 'Business Email',
            value: data.businessEmail,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.phone,

            label: 'Phone Number',
            value: data.phoneNumber,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.business,

            label: 'Business Type',
            value: data.businessType,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.location_on,

            label: 'Address',
            value: '${data.streetAddress}\n${data.city}, ${data.state}',
            isMultiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildContactPersonCard(MyProfileModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleCard('Contact Person'),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.person,
            label: 'Name',
            value: data.contactPersonName,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.badge,
            label: 'Designation',
            value: data.contactDesignation,
          ),

          const SizedBox(height: 12),

          _buildDetailRow(icon: Icons.email, label: 'Email', value: data.email),
        ],
      ),
    );
  }

  Widget _buildTitleCard(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 18,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
            // color: AppTheme.primary.withValues(alpha: 0.01),
          ),
        ),
        Text(
          title,

          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            wordSpacing: 1.9,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsCard(MyProfileModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleCard('Documents'),

          const SizedBox(height: 16),
          if (data.gstCertificate.isNotEmpty)
            _buildDocumentItem(
              title: 'GST Certificate',
              documentType: 'PDF Document',
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.shade50,
              onView: () {
                // TODO: View GST Certificate
                _viewDocument(data.gstCertificate);
              },
            ),
          if (data.gstCertificate.isNotEmpty) const SizedBox(height: 12),
          if (data.businessLicense.isNotEmpty)
            _buildDocumentItem(
              title: 'Business License',
              documentType: 'Image Document',
              iconColor: Colors.blue,
              backgroundColor: Colors.blue.shade50,
              onView: () {
                // TODO: View Business License
                _viewDocument(data.businessLicense);
              },
            ),
          if (data.businessLicense.isNotEmpty) const SizedBox(height: 12),
          if (data.photoId.isNotEmpty)
            _buildDocumentItem(
              title: 'Photo ID',
              documentType: 'Image Document',
              iconColor: Colors.purple,
              backgroundColor: Colors.purple.shade50,
              onView: () {
                // TODO: View Photo ID
                _viewDocument(data.photoId);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard(MyProfileModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleCard('Account Status'),

          const SizedBox(height: 16),
          // _buildStatusRow(label: 'Merchant Verified', isActive: data.verified),
          const SizedBox(height: 12),
          _buildStatusRow(label: 'Account Active', isActive: data.isActive),
          // const SizedBox(height: 12),
          // _buildStatusRow(
          //   label: 'User Verified',
          //   isActive: data.isUserVerified,
          // ),
          // const SizedBox(height: 12),
          // _buildStatusRow(label: 'User Active', isActive: data.isUserActive),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(MyProfileModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleCard('Timeline'),

          const SizedBox(height: 16),
          _buildTimelineRow(
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            label: 'Account Created',
            date: formatDate(data.createdAt),
          ),
          const SizedBox(height: 12),
          _buildTimelineRow(
            icon: Icons.calendar_today,
            iconColor: Colors.blue,
            label: 'Last Updated',
            date: formatDate(data.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MyProfileModel data) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to signup page with merchant data for editing
              context.push('/merchant/signUp', extra: data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Contact Support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,

    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String documentType,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onView,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  documentType,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onView,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({required String label, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isActive ? 'Active' : 'Pending',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String date,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.2),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildDocumentUrl(String documentPath) {
    if (documentPath.startsWith('http://') ||
        documentPath.startsWith('https://')) {
      return documentPath;
    }
    return '$baseUrl$documentPath';
  }

  void _viewDocument(String documentPath) {
    //
    // You can use url_launcher or a custom documeTODO: Implement document viewingnt viewer
    final fullUrl = _buildDocumentUrl(documentPath);
    print('View document: $fullUrl');
    // Example: launchUrl(Uri.parse(fullUrl));
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.only(right: 8.0),

      width: screenWidth * 0.35,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: Column(
          children: [
            FaIcon(icon, color: Colors.white),
            Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
            Text(
              title == 'Member Since' ? formatDate(value) : value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
