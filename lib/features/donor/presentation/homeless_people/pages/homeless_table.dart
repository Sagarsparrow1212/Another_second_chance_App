import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/auth/data/services/auth_storage_service.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';
import 'package:homelyhope/features/common/widgets/divider.dart';
import 'package:homelyhope/features/donor/data/datasources/homeless_people/homeless_remote_datasource.dart';
import '../../organization/providers/organization_provider.dart';

class DonorHomelessTable extends ConsumerStatefulWidget {
  const DonorHomelessTable({super.key});

  @override
  ConsumerState<DonorHomelessTable> createState() => _DonorHomelessTableState();
}

enum SortBy { name, age, date }

enum SortOrder { ascending, descending }

class _DonorHomelessTableState extends ConsumerState<DonorHomelessTable> {
  final ValueNotifier<Set<String>> expandedHomelessIds = ValueNotifier(
    <String>{},
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _hasInitialized = false;
  SortBy _sortBy = SortBy.name;
  SortOrder _sortOrder = SortOrder.ascending;
  String? _searchQuery;
  String? _selectedGenderFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        ref.invalidate(allHomelessListProvider);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    expandedHomelessIds.dispose();
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

  void _handleSort(SortBy sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortOrder = _sortOrder == SortOrder.ascending
            ? SortOrder.descending
            : SortOrder.ascending;
      } else {
        _sortBy = sortBy;
        _sortOrder = SortOrder.ascending;
      }
    });
  }

  List<HomelessPerson> _filterAndSortHomeless(
    List<HomelessPerson> homelessList,
  ) {
    List<HomelessPerson> filtered = homelessList;

    // Filter by gender
    if (_selectedGenderFilter != null && _selectedGenderFilter != 'all') {
      filtered = filtered
          .where(
            (h) =>
                h.gender?.toLowerCase() == _selectedGenderFilter!.toLowerCase(),
          )
          .toList();
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((homeless) {
        final fullName = homeless.fullName.toLowerCase();
        final phone = (homeless.contactPhone ?? '').toLowerCase();
        final email = (homeless.contactEmail ?? '').toLowerCase();
        final location = (homeless.location ?? '').toLowerCase();
        final skills = (homeless.skills ?? [])
            .map((s) => s.toLowerCase())
            .join(' ');

        return fullName.contains(query) ||
            phone.contains(query) ||
            email.contains(query) ||
            location.contains(query) ||
            skills.contains(query);
      }).toList();
    }

    // Sort the filtered list
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case SortBy.name:
          comparison = a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          );
          break;
        case SortBy.age:
          final aAge = a.age ?? 0;
          final bAge = b.age ?? 0;
          comparison = aAge.compareTo(bAge);
          break;
        case SortBy.date:
          // Since we don't have createdAt in HomelessPerson, sort by name
          comparison = a.fullName.toLowerCase().compareTo(
            b.fullName.toLowerCase(),
          );
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return filtered;
  }

  String? _buildImageUrl(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    try {
      if (profilePicture.startsWith('http://') ||
          profilePicture.startsWith('https://')) {
        return profilePicture;
      } else if (profilePicture.startsWith('/')) {
        return '$baseUrl$profilePicture';
      } else {
        return '$baseUrl/$profilePicture';
      }
    } catch (e) {
      return null;
    }
  }

  void printTokenAndgetHomelessId() async {
    final token = await AuthStorageService.getToken();

    final donorId = await AuthStorageService.getDonorId();
    print(token);
    print(donorId);
  }

  @override
  Widget build(BuildContext context) {
    printTokenAndgetHomelessId();
    final homelessAsync = ref.watch(allHomelessListProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Homeless People'),
      body: homelessAsync.when(
        loading: () => Center(child: AppLoader()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading homeless people',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(allHomelessListProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (response) {
          final homelessList = response.homeless;
          final filteredAndSortedHomeless = _filterAndSortHomeless(
            homelessList,
          );

          if (homelessList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No homeless people found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for updates',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            edgeOffset: 100,
            key: const ValueKey('donor_homeless_refresh'),
            onRefresh: () async {
              ref.invalidate(allHomelessListProvider);
              await ref.read(allHomelessListProvider.future);
            },
            child: CustomScrollView(
              key: const ValueKey('donor_homeless_scroll'),
              slivers: [
                SliverToBoxAdapter(child: Container(height: 100)),

                // Search bar
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
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 20,
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

                // Filter and count row
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
                          textAlign: TextAlign.end,
                          'Total: ${filteredAndSortedHomeless.length} people',
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

                // Header with sorting
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
                        // Name column - sortable
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _handleSort(SortBy.name),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _sortBy == SortBy.name
                                        ? AppTheme.primary
                                        : Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 4),
                                if (_sortBy == SortBy.name)
                                  Icon(
                                    _sortOrder == SortOrder.ascending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: AppTheme.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Age column - sortable
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GestureDetector(
                            onTap: () => _handleSort(SortBy.age),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Age',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: _sortBy == SortBy.age
                                        ? AppTheme.primary
                                        : Colors.black,
                                  ),
                                ),
                                SizedBox(width: 4),
                                if (_sortBy == SortBy.age)
                                  Icon(
                                    _sortOrder == SortOrder.ascending
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

                // Empty state for filtered results
                if (filteredAndSortedHomeless.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Color(0xff15306C),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            textAlign: TextAlign.center,
                            'No homeless people found matching your search',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final homeless = filteredAndSortedHomeless[index];
                        return _buildHomelessCard(context, homeless, index);
                      }, childCount: filteredAndSortedHomeless.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHomelessCard(
    BuildContext context,
    HomelessPerson homeless,
    int index,
  ) {
    final fullName = homeless.fullName;
    final age = homeless.age;
    final imageUrl = _buildImageUrl(homeless.profilePicture);

    return ValueListenableBuilder<Set<String>>(
      valueListenable: expandedHomelessIds,
      builder: (context, expandedSet, child) {
        final isExpanded = expandedSet.contains(homeless.id);
        return GestureDetector(
          onTap: () {
            final newSet = Set<String>.from(expandedSet);
            if (isExpanded) {
              newSet.remove(homeless.id);
            } else {
              newSet.add(homeless.id);
            }
            expandedHomelessIds.value = newSet;
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
                  // Name and Age row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Photo and Name
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
                                  style: TextStyle(
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
                        SizedBox(width: 16),
                        // Age
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
                        SizedBox(width: 8),
                        isExpanded
                            ? Icon(Icons.expand_less_rounded)
                            : Icon(Icons.expand_more_rounded),
                      ],
                    ),
                  ),

                  // Expanded content
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    customDivider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Gender
                          if (homeless.gender != null)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.person_outline,
                              iconColor: Colors.purple,
                              label: 'Gender',
                              value: homeless.gender!,
                            ),

                          // Phone
                          if (homeless.contactPhone != null &&
                              homeless.contactPhone!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.phone_outlined,
                              iconColor: Colors.green,
                              label: 'Phone',
                              value: homeless.contactPhone!,
                            ),

                          // Email
                          if (homeless.contactEmail != null &&
                              homeless.contactEmail!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.email_outlined,
                              iconColor: Colors.blue,
                              label: 'Email',
                              value: homeless.contactEmail!,
                            ),

                          // Location
                          if (homeless.location != null &&
                              homeless.location!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.location_on_outlined,
                              iconColor: Colors.red,
                              label: 'Location',
                              value: homeless.location!,
                            ),

                          // Skills
                          if (homeless.skills != null &&
                              homeless.skills!.isNotEmpty)
                            _buildDetailRowWithIconBackground(
                              icon: Icons.work_outline,
                              iconColor: Colors.orange,
                              label: 'Skills',
                              value: homeless.skills!.join(', '),
                              isMultiline: true,
                            ),

                          // Bio
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
                          // Contact Button
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
                          // View Profile Button
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
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
