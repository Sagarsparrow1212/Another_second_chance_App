import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Donation History'),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 80,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            _buildTableHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 4),
          right: BorderSide(color: AppTheme.primary, width: 4),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
