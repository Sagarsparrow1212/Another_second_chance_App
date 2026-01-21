import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/common/widgets/custom_appbar.dart';

import '../../../../common/Drawer/pages/dynamic_drawer.dart';

class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends ConsumerState<DonationHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: CustomAppBar(title: 'Donation History'),
      body: Column(children: [Text('Donation History')]),
    );
  }
}
