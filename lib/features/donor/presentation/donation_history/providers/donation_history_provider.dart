import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/donation/donation_history_response.dart';
import '../../donation/providers/donation_provider.dart';

final donationHistoryProvider =
    FutureProvider.autoDispose<List<DonationHistoryItem>>((ref) async {
      final datasource = ref.watch(donationRemoteDatasourceProvider);
      final response = await datasource.getMyDonationHistory();
      return response.data?.donations ?? [];
    });
