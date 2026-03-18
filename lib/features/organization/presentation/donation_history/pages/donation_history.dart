import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';

import 'package:homelyhope/core/contanst/contanst.dart';
import 'package:homelyhope/features/organization/presentation/donation_history/providers/organization_donation_history_provider.dart';
import 'package:homelyhope/features/organization/presentation/donation_history/widgets/donation_list_item.dart';
import 'package:homelyhope/features/organization/presentation/donation_history/widgets/history_summary_card.dart';

class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends ConsumerState<DonationHistoryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final historyAsync = ref.watch(organizationDonationHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      appBar: const CustomAppBar(title: 'Donation History'),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 80,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightText,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search donations...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 24,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (donations) {
                // Calculate stats
                double totalReceived = 0;
                int completedCount = 0;
                int pendingCount = 0;

                for (var donation in donations) {
                  // Assuming netAmount is valid for all, or maybe only check completed?
                  // Sticking to design usually showing totals.
                  totalReceived += donation
                      .netAmount; // Use netAmount logic as per request to focus on net.

                  if (donation.status.toLowerCase() == 'completed') {
                    completedCount++;
                  } else if (donation.status.toLowerCase() == 'pending') {
                    pendingCount++;
                  }
                }

                if (donations.isEmpty) {
                  return Column(
                    children: [
                      HistorySummaryCard(
                        totalReceived: 0,
                        completedCount: 0,
                        pendingCount: 0,
                        totalCount: 0,
                      ),
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: Text('No donations found')),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    HistorySummaryCard(
                      totalReceived: totalReceived,
                      completedCount: completedCount,
                      pendingCount: pendingCount,
                      totalCount: donations.length,
                    ),
                    const SizedBox(height: 20),
                    ...donations.map((donation) {
                      return DonationListItem(donation: donation);
                    }).toList(),
                  ],
                );
              },
              loading: () => Center(child: AppLoader()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}
