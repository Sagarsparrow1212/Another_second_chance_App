import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/donor/data/datasources/donation/donation_remote_datasource.dart';
import 'package:homelyhope/features/donor/data/models/donation/donation_model.dart';

// Dio provider
final homelessDonationDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final homelessDonationRemoteDatasourceProvider = Provider(
  (ref) => DonationRemoteDatasource(ref.watch(homelessDonationDioProvider)),
);

// Provider to get donations for current homeless user
final homelessDonationsProvider = FutureProvider<List<DonationModel>>((
  ref,
) async {
  final datasource = ref.watch(homelessDonationRemoteDatasourceProvider);

  // Use "me" to automatically get current user's donations
  // The API will automatically resolve to the logged-in homeless user's ID
  return await datasource.getDonationsByHomeless('me');
});
