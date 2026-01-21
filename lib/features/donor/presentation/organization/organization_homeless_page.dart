import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/common/widgets/divider.dart';
import 'package:homelyhope/features/donor/data/datasources/homeless_people/homeless_remote_datasource.dart';
import 'package:homelyhope/features/donor/presentation/organization/providers/organization_provider.dart';

class OrganizationHomelessArgs {
  final String organizationId;
  final String organizationName;
  final List<Color>? gradientColors;

  const OrganizationHomelessArgs({
    required this.organizationId,
    required this.organizationName,
    this.gradientColors,
  });
}

enum OrgSortBy { name, age }

enum OrgSortOrder { ascending, descending }

class OrganizationHomelessPage extends ConsumerStatefulWidget {
  final String organizationId;
  final String organizationName;
  final List<Color> gradientColors;

  const OrganizationHomelessPage({
    super.key,
    required this.organizationId,
    required this.organizationName,
    List<Color>? gradientColors,
  }) : gradientColors =
           gradientColors ?? const [Color(0xFF6C63FF), Color(0xFF2CBFA8)];

  @override
  ConsumerState<OrganizationHomelessPage> createState() =>
      _OrganizationHomelessPageState();
}

class _OrganizationHomelessPageState
    extends ConsumerState<OrganizationHomelessPage> {
  final ValueNotifier<Set<String>> expandedIds = ValueNotifier(HashSet());
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  OrgSortBy _sortBy = OrgSortBy.name;
  OrgSortOrder _sortOrder = OrgSortOrder.ascending;
  String? _searchQuery;
  String? _selectedGenderFilter;

  @override
  void dispose() {
    expandedIds.dispose();
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

  void _handleSort(OrgSortBy sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortOrder = _sortOrder == OrgSortOrder.ascending
            ? OrgSortOrder.descending
            : OrgSortOrder.ascending;
      } else {
        _sortBy = sortBy;
        _sortOrder = OrgSortOrder.ascending;
      }
    });
  }

  List<HomelessPerson> _filterAndSort(List<HomelessPerson> list) {
    List<HomelessPerson> filtered = list;

    if (_selectedGenderFilter != null && _selectedGenderFilter != 'all') {
      filtered = filtered
          .where((h) => h.gender?.toLowerCase() == _selectedGenderFilter)
          .toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((person) {
        final fullName = person.fullName.toLowerCase();
        final phone = (person.contactPhone ?? '').toLowerCase();
        final email = (person.contactEmail ?? '').toLowerCase();
        final location = (person.location ?? '').toLowerCase();
        final skills = (person.skills ?? [])
            .map((s) => s.toLowerCase())
            .join(' ');
        return fullName.contains(query) ||
            phone.contains(query) ||
            email.contains(query) ||
            location.contains(query) ||
            skills.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case OrgSortBy.name:
          cmp = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
          break;
        case OrgSortBy.age:
          cmp = (a.age ?? 0).compareTo(b.age ?? 0);
          break;
      }
      return _sortOrder == OrgSortOrder.ascending ? cmp : -cmp;
    });

    return filtered;
  }

  String? _buildImageUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) return null;
    if (profilePicture.startsWith('http://') ||
        profilePicture.startsWith('https://')) {
      return profilePicture;
    } else if (profilePicture.startsWith('/')) {
      return '$baseUrl$profilePicture';
    } else {
      return '$baseUrl/$profilePicture';
    }
  }

  @override
  Widget build(BuildContext context) {
    final homelessAsync = ref.watch(
      homelessListByOrgProvider(widget.organizationId),
    );
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        showBackButton: true,
        title: widget.organizationName,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(homelessListByOrgProvider(widget.organizationId));
          await ref.read(
            homelessListByOrgProvider(widget.organizationId).future,
          );
        },
        child: homelessAsync.when(
          loading: () => Center(child: AppLoader()),
          error: (error, stack) => _buildError(context, ref, error),
          data: (response) {
            final list = response.homeless;
            final filtered = _filterAndSort(list);

            if (list.isEmpty) {
              return _buildEmpty();
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Container(height: 100)),

                // Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
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
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 0.5,
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
                          hintText: 'Search homeless people...',
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
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ),

                // Filter and count
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.4,
                          child: DropdownButtonFormField<String>(
                            value: _selectedGenderFilter,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
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
                              'Gender',
                              style: TextStyle(fontSize: 14),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All'),
                              ),
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGenderFilter = value;
                              });
                            },
                          ),
                        ),
                        Text(
                          'Total: ${filtered.length} people',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sort header
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
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleSort(OrgSortBy.name),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _sortBy == OrgSortBy.name
                                        ? AppTheme.primary
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (_sortBy == OrgSortBy.name)
                                  Icon(
                                    _sortOrder == OrgSortOrder.ascending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: AppTheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GestureDetector(
                            onTap: () => _handleSort(OrgSortBy.age),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Age',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _sortBy == OrgSortBy.age
                                        ? AppTheme.primary
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (_sortBy == OrgSortBy.age)
                                  Icon(
                                    _sortOrder == OrgSortOrder.ascending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: AppTheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('No homeless people found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final person = filtered[index];
                        return _buildHomelessCard(context, person);
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomelessCard(BuildContext context, HomelessPerson homeless) {
    final fullName = homeless.fullName;
    final age = homeless.age;
    final imageUrl = _buildImageUrl(homeless.profilePicture);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(homeless.id);
        return GestureDetector(
          onTap: () {
            final newSet = Set<String>.from(expandedSet);
            isExpanded ? newSet.remove(homeless.id) : newSet.add(homeless.id);
            expandedIds.value = newSet;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : null,
                                child: imageUrl == null
                                    ? Text(
                                        fullName.isNotEmpty
                                            ? fullName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (age != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$age yrs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        isExpanded
                            ? const Icon(Icons.expand_less_rounded)
                            : const Icon(Icons.expand_more_rounded),
                      ],
                    ),
                  ),

                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    customDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (homeless.gender != null)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.person_outline,
                              iconColor: Colors.purple,
                              label: 'Gender',
                              value: homeless.gender!,
                            ),
                          if (homeless.contactPhone != null &&
                              homeless.contactPhone!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.phone_outlined,
                              iconColor: Colors.green,
                              label: 'Phone',
                              value: homeless.contactPhone!,
                            ),
                          if (homeless.contactEmail != null &&
                              homeless.contactEmail!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.email_outlined,
                              iconColor: Colors.blue,
                              label: 'Email',
                              value: homeless.contactEmail!,
                            ),
                          if (homeless.location != null &&
                              homeless.location!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.location_on_outlined,
                              iconColor: Colors.red,
                              label: 'Location',
                              value: homeless.location!,
                            ),
                          if (homeless.skills != null &&
                              homeless.skills!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.work_outline,
                              iconColor: Colors.orange,
                              label: 'Skills',
                              value: homeless.skills!.join(', '),
                              isMultiline: true,
                            ),
                          if (homeless.bio != null && homeless.bio!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.description_outlined,
                              iconColor: Colors.teal,
                              label: 'Bio',
                              value: homeless.bio!,
                              isMultiline: true,
                            ),
                        ],
                      ),
                    ),

                    // Actions
                    customDivider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              context.push(
                                '/donor/homeless/${homeless.id}/donate',
                                extra: homeless,
                              );
                            },
                            icon: Icon(
                              FontAwesomeIcons.handHoldingHeart,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            label: Text(
                              'Donate',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primary,
                              side: BorderSide(color: AppTheme.primary),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () => context.push(
                              '/donor/homeless/${homeless.id}',
                              extra: homeless,
                            ),
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 18,
                              color: AppTheme.primary,
                            ),
                            label: Text(
                              'View',
                              style: TextStyle(color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            const Text(
              'Failed to load people',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(
                  homelessListByOrgProvider(widget.organizationId),
                );
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No people registered yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'This organization hasn\'t registered any homeless people yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIconBackground({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    Color iconDarkColor = iconColor;
    if (iconColor == Colors.green) {
      iconDarkColor = Colors.green.shade700;
    } else if (iconColor == Colors.blue) {
      iconDarkColor = Colors.blue.shade700;
    } else if (iconColor == Colors.orange) {
      iconDarkColor = Colors.orange.shade700;
    } else if (iconColor == Colors.purple) {
      iconDarkColor = Colors.purple.shade700;
    } else if (iconColor == Colors.red) {
      iconDarkColor = Colors.red.shade700;
    } else if (iconColor == Colors.teal) {
      iconDarkColor = Colors.teal.shade700;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconDarkColor),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: isMultiline ? null : 3,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
