import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../data/datasources/donation/donation_remote_datasource.dart';
import '../../../data/models/donation/donation_model.dart';

// Dio provider
final donationDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final donationRemoteDatasourceProvider = Provider(
  (ref) => DonationRemoteDatasource(ref.watch(donationDioProvider)),
);

// StateNotifier for donation creation
class DonationNotifier extends StateNotifier<AsyncValue<DonationModel?>> {
  DonationNotifier(this._datasource) : super(const AsyncValue.data(null));

  final DonationRemoteDatasource _datasource;

  Future<void> createDonation(CreateDonationRequest request) async {
    state = const AsyncValue.loading();
    try {
      final response = await _datasource.createDonation(request);
      state = AsyncValue.data(response.data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Provider for donation notifier
final donationNotifierProvider =
    StateNotifierProvider<DonationNotifier, AsyncValue<DonationModel?>>((ref) {
      return DonationNotifier(ref.watch(donationRemoteDatasourceProvider));
    });
