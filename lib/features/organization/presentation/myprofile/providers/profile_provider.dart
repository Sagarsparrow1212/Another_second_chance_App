import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/organization/data/datasources/profile/profile_remote_datasource.dart';

import '../../../data/models/sign_up/organization_registration_model.dart';
import '../../../data/repositories/profile/profile_respository_impl.dart';

final profileProvider = Provider((ref) => Dio());

final profileRemoteDatasourceProvider = Provider(
  (ref) => ProfileRemoteDatasource(ref.watch(profileProvider)),
);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDatasourceProvider)),
);

final organizationProfileDetailsProvider =
    FutureProvider<OrganizationDetailModel>((ref) async {
      final repo = ref.watch(profileRepositoryProvider);
      return await repo.getOrganizationDetails();
    });

final deleteHomelessProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      homelessId,
    ) async {
      print(
        '🔗 [PROVIDER] deleteHomelessProfileProvider called with ID: $homelessId',
      );
      try {
        final repo = ref.watch(profileRepositoryProvider);
        print(
          '🔗 [PROVIDER] Repository obtained, calling deleteHomelessProfile...',
        );
        final result = await repo.deleteHomelessProfile(homelessId);
        print('🔗 [PROVIDER] Repository returned result: $result');
        return result;
      } catch (e, stackTrace) {
        print('❌ [PROVIDER] Error in deleteHomelessProfileProvider: $e');
        print('❌ [PROVIDER] Stack trace: $stackTrace');
        rethrow;
      }
    });
