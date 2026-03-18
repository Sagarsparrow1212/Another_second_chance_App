import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/organization/data/models/homeless_people/homeless_model.dart';
import 'package:homelyhope/features/organization/presentation/homeless_people/providers/homeless_providers.dart';
import 'package:intl/intl.dart';
import 'add_homeless.dart';
import 'package:homelyhope/core/utils/formatters.dart';

class ViewHomelessDetailPage extends ConsumerWidget {
  final String homelessId;

  const ViewHomelessDetailPage({super.key, required this.homelessId});

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

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homelessAsync = ref.watch(homelessDetailProvider(homelessId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Person Details', showBackButton: true),
      body: homelessAsync.when(
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading person details',
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
                  ref.invalidate(homelessDetailProvider(homelessId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detailResponse) {
          final homeless = detailResponse.homeless;
          final topPadding = MediaQuery.of(context).padding.top;
          final profileImageUrl = _buildImageUrl(homeless.profilePicture);
          final verificationDocUrl = _buildImageUrl(
            homeless.verificationDocument,
          );
          final fullName = homeless.fullName ?? homeless.name ?? 'Unknown';
          final skills = homeless.skillset ?? homeless.skills ?? [];
          final languages = homeless.languages ?? [];

          return RefreshIndicator(
            edgeOffset: 100,
            onRefresh: () async {
              ref.invalidate(homelessDetailProvider(homelessId));
              await ref.read(homelessDetailProvider(homelessId).future);
            },
            child: SingleChildScrollView(
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
                  // Header Card with Profile Picture
                  _buildHeaderCard(
                    context,
                    fullName,
                    profileImageUrl,
                    homeless.verified ?? false,
                    detailResponse.isActive ?? true,
                  ),
                  const SizedBox(height: 16),

                  // Organization Information Card (if available)
                  if (detailResponse.organization != null)
                    _buildOrganizationCard(detailResponse.organization!),
                  if (detailResponse.organization != null)
                    const SizedBox(height: 16),

                  // Personal Information Card
                  _buildPersonalInfoCard(
                    homeless,
                    detailResponse.userEmail,
                    detailResponse.updatedAt,
                  ),
                  const SizedBox(height: 16),

                  // Contact Information Card
                  _buildContactInfoCard(homeless),
                  const SizedBox(height: 16),

                  // Skills & Languages Card
                  if (skills.isNotEmpty || languages.isNotEmpty)
                    _buildSkillsLanguagesCard(skills, languages),
                  if (skills.isNotEmpty || languages.isNotEmpty)
                    const SizedBox(height: 16),

                  // Bio Card
                  if (homeless.bio != null && homeless.bio!.isNotEmpty)
                    _buildBioCard(homeless.bio!),
                  if (homeless.bio != null && homeless.bio!.isNotEmpty)
                    const SizedBox(height: 16),

                  // Experience Card
                  if (homeless.experience != null &&
                      homeless.experience!.isNotEmpty)
                    _buildExperienceCard(homeless.experience!),
                  if (homeless.experience != null &&
                      homeless.experience!.isNotEmpty)
                    const SizedBox(height: 16),
                  if (homeless.organizationCutPercentage != null &&
                      homeless.organizationCutPercentage!.isNotEmpty)
                    _buildCommissionCutCard(
                      homeless.organizationCutPercentage!,
                    ),

                  // Verification Document Card
                  if (verificationDocUrl != null)
                    _buildVerificationDocCard(verificationDocUrl),
                  if (verificationDocUrl != null) const SizedBox(height: 16),

                  // Action Buttons
                  _buildActionButtons(context, homeless),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommissionCutCard(String commissionCut) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.percent_outlined, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Commission Cut',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              commissionCut,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    String fullName,
    String? profileImageUrl,
    bool verified,
    bool isActive,
  ) {
    return Container(
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
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
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
              if (verified)
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

          // Name
          Text(
            fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // Status Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // // Verification Status
              // Container(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16,
              //     vertical: 8,
              //   ),
              //   decoration: BoxDecoration(
              //     color: Colors.white.withValues(alpha: 0.2),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: Colors.white.withValues(alpha: 0.3),
              //       width: 1,
              //     ),
              //   ),
              //   child: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Icon(
              //         verified ? Icons.verified : Icons.access_time,
              //         color: Colors.white,
              //         size: 16,
              //       ),
              //       const SizedBox(width: 8),
              //       Text(
              //         verified ? 'Verified' : 'Pending',
              //         style: const TextStyle(
              //           color: Colors.white,
              //           fontSize: 14,
              //           fontWeight: FontWeight.w500,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Account Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Active' : 'Inactive',
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
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(OrganizationInfo organization) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withValues(alpha: 0.3),
        //     blurRadius: 4,
        //     offset: const Offset(0, 0.5),
        //   ),
        // ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Organization',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.business_center, 'Name', organization.name),
            const SizedBox(height: 16),
            if (organization.city != null && organization.city!.isNotEmpty)
              _buildInfoRow(Icons.location_city, 'City', organization.city!),
            if (organization.city != null && organization.city!.isNotEmpty)
              const SizedBox(height: 16),
            if (organization.state != null && organization.state!.isNotEmpty)
              _buildInfoRow(Icons.map, 'State', organization.state!),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(
    dynamic homeless,
    String? userEmail,
    String? updatedAt,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (homeless.username != null && homeless.username!.isNotEmpty)
              _buildInfoRow(
                Icons.alternate_email,
                'Username',
                homeless.username!,
              ),
            if (homeless.username != null && homeless.username!.isNotEmpty)
              const SizedBox(height: 16),
            if (userEmail != null && userEmail.isNotEmpty)
              _buildInfoRow(Icons.email_outlined, 'User Email', userEmail),
            if (userEmail != null && userEmail.isNotEmpty)
              const SizedBox(height: 16),
            if (homeless.age != null)
              _buildInfoRow(Icons.cake, 'Age', '${homeless.age} years'),
            if (homeless.age != null) const SizedBox(height: 16),
            if (homeless.gender != null && homeless.gender!.isNotEmpty)
              _buildInfoRow(Icons.people_outline, 'Gender', homeless.gender!),
            if (homeless.gender != null && homeless.gender!.isNotEmpty)
              const SizedBox(height: 16),
            if (homeless.healthConditions != null &&
                homeless.healthConditions!.isNotEmpty)
              _buildInfoRow(
                Icons.favorite_outline,
                'Health Conditions',
                homeless.healthConditions!,
              ),
            if (homeless.healthConditions != null &&
                homeless.healthConditions!.isNotEmpty)
              const SizedBox(height: 16),
            if (homeless.createdAt != null && homeless.createdAt!.isNotEmpty)
              _buildInfoRow(
                Icons.calendar_today,
                'Registered',
                _formatDate(homeless.createdAt),
              ),
            if (homeless.createdAt != null && homeless.createdAt!.isNotEmpty)
              const SizedBox(height: 16),
            if (updatedAt != null && updatedAt.isNotEmpty)
              _buildInfoRow(
                Icons.update,
                'Last Updated',
                _formatDate(updatedAt),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(dynamic homeless) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (homeless.email != null && homeless.email!.isNotEmpty)
              _buildInfoRow(Icons.email, 'Email', homeless.email!),
            if (homeless.email != null && homeless.email!.isNotEmpty)
              const SizedBox(height: 16),
            if ((homeless.phone != null && homeless.phone!.isNotEmpty) ||
                (homeless.contactPhone != null &&
                    homeless.contactPhone!.isNotEmpty))
              _buildInfoRow(
                Icons.phone,
                'Phone',
                Formatters.formatPhoneNumber(
                  homeless.phone ?? homeless.contactPhone ?? '',
                ),
              ),
            if ((homeless.phone != null && homeless.phone!.isNotEmpty) ||
                (homeless.contactPhone != null &&
                    homeless.contactPhone!.isNotEmpty))
              const SizedBox(height: 16),
            if (homeless.address != null && homeless.address!.isNotEmpty)
              _buildInfoRow(Icons.location_on, 'Address', homeless.address!),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsLanguagesCard(
    List<String> skills,
    List<String> languages,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (skills.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.work_outline, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Skills',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (languages.isNotEmpty) const SizedBox(height: 24),
            ],
            if (languages.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.language, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Languages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages.map((language) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      language,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBioCard(String bio) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: Colors.pink, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Bio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(String experience) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business_center_outlined,
                  color: Colors.indigo,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Experience',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              experience,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationDocCard(String docUrl) {
    return Container(
      // elevation: 2,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                  'Verification Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // TODO: Open document in full screen or external viewer
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    docUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Document',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic homeless) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddHomeless(homelessToEdit: homeless),
                ),
              );
              if (result == true && context.mounted) {
                context.pop(true); // Return true to refresh list
              }
            },
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade700),
            label: Text(
              'Edit',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: () {
              context.push('/organization/delete-homeless/${homeless.id}');
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
}
