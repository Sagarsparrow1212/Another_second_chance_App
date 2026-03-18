import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/wallet/organization_wallet_remote_datasource.dart';
import '../../../data/models/wallet/wallet_response.dart';

final organizationWalletDioProvider = Provider((ref) => Dio());

final organizationWalletRemoteDatasourceProvider = Provider(
  (ref) => OrganizationWalletRemoteDatasource(
    ref.watch(organizationWalletDioProvider),
  ),
);

final organizationWalletDetailsProvider =
    FutureProvider.autoDispose<WalletData>((ref) async {
      final datasource = ref.watch(organizationWalletRemoteDatasourceProvider);
      final response = await datasource.getWalletDetails();

      if (response.data == null) {
        throw Exception('No wallet data found');
      }

      return response.data!;
    });

final transactionsProvider =
    FutureProvider.autoDispose.family<List<WalletTransaction>, String>((ref, filter) async {
  final datasource = ref.watch(organizationWalletRemoteDatasourceProvider);
  return await datasource.getTransactions(filter);
});
