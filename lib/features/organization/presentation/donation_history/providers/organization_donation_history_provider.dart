import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/donation/organization_donation_remote_datasource.dart';
import '../../../data/models/donation/organization_donation_history_response.dart';

// Dio provider
final organizationDonationDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final organizationDonationRemoteDatasourceProvider = Provider(
  (ref) => OrganizationDonationRemoteDatasource(
    ref.watch(organizationDonationDioProvider),
  ),
);

// FutureProvider for donation history
final organizationDonationHistoryProvider =
    FutureProvider.autoDispose<List<OrganizationDonationHistoryItem>>((
      ref,
    ) async {
      final datasource = ref.watch(
        organizationDonationRemoteDatasourceProvider,
      );
      final response = await datasource.getOrganizationDonationHistory();
      return response.data?.donations ?? [];
    });
