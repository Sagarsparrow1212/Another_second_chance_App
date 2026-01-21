import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/donor/data/datasources/homeless_people/homeless_remote_datasource.dart';

class HomelessDetailPage extends StatelessWidget {
  final String homelessId;
  final HomelessPerson? homeless;

  const HomelessDetailPage({
    super.key,
    required this.homelessId,
    this.homeless,
  });

  String? _buildImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }

  @override
  Widget build(BuildContext context) {
    final person = homeless;

    if (person == null) {
      return Scaffold(
        appBar: CustomAppBar(showBackButton: true, title: 'Person Details'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Homeless person data not provided'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final profileImageUrl = _buildImageUrl(person.profilePicture);
    final skills = person.skills ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(showBackButton: true, title: 'Person Details'),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroCard(person, profileImageUrl),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'About',
                children: [
                  _infoRow(
                    'Age',
                    person.age?.toString() ?? 'N/A',
                    icon: Icons.cake_outlined,
                  ),
                  _infoRow(
                    'Gender',
                    person.gender ?? 'N/A',
                    icon: Icons.wc_outlined,
                  ),
                  _infoRow(
                    'Location',
                    person.location ?? 'N/A',
                    icon: Icons.location_on_outlined,
                  ),
                  if (person.bio != null && person.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        person.bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  if (person.healthConditions != null &&
                      person.healthConditions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _pill(
                        label: person.healthConditions!,
                        color: Colors.red.shade50,
                        textColor: Colors.red.shade700,
                        icon: Icons.favorite_border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Contact',
                children: [
                  _contactRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: person.contactPhone ?? 'Not provided',
                    onTap: person.contactPhone == null
                        ? null
                        : () {
                            // Placeholder: hook up launcher
                          },
                  ),
                  const SizedBox(height: 12),
                  _contactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: person.contactEmail ?? 'Not provided',
                    onTap: person.contactEmail == null
                        ? null
                        : () {
                            // Placeholder: hook up launcher
                          },
                  ),
                ],
              ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Skills',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              labelStyle: TextStyle(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ],
              if (person.organization != null) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Organization',
                  children: [
                    _infoRow(
                      'Name',
                      person.organization!.name,
                      icon: Icons.apartment_outlined,
                    ),
                    _infoRow(
                      'City',
                      person.organization!.city ?? 'N/A',
                      icon: Icons.location_city_outlined,
                    ),
                    _infoRow(
                      'State',
                      person.organization!.state ?? 'N/A',
                      icon: Icons.map_outlined,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _buildActions(context, person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(HomelessPerson person, String? profileImageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl == null
                ? Icon(Icons.person, size: 44, color: AppTheme.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            person.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (person.location != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    person.location!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (person.gender != null && person.gender!.isNotEmpty)
                _pill(
                  label: person.gender!,
                  icon: Icons.wc,
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  textColor: AppTheme.primary,
                ),
              _pill(
                label: 'ID: ${person.id}',
                icon: Icons.badge_outlined,
                color: Colors.grey.shade100,
                textColor: Colors.grey.shade800,
              ),
              if (person.age != null)
                _pill(
                  label: '${person.age} yrs',
                  icon: Icons.cake_outlined,
                  color: Colors.orange.shade50,
                  textColor: Colors.orange.shade700,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(icon, size: 16, color: Colors.grey[600]),
                ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDisabled ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDisabled ? Colors.grey[300] : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, HomelessPerson person) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppTheme.primary),
              foregroundColor: AppTheme.primary,
            ),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: () => context.push(
              '/donor/homeless/${person.id}/donate',
              extra: person,
            ),
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('Donate'),
          ),
        ),
      ],
    );
  }
}
