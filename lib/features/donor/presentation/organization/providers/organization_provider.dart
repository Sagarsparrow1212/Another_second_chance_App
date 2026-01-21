import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/homeless_people/homeless_remote_datasource.dart';
import '../../../data/datasources/organization/get_org_remote_datasource.dart';
import '../../../data/models/organization/organization_model.dart';
import '../../../data/repositories/organization/organization_repo_impl.dart';
import '../../../data/usecases/organization/organization_usecase.dart';

final organizationDioProvider = Provider((ref) => Dio());

final organizationRemoteDatasourceProvider = Provider(
  (ref) => GetAllOrgRemoteDatasource(ref.watch(organizationDioProvider)),
);

final getAllOrganizationRepositoryProvider = Provider(
  (ref) => GetAllOrganizationRepositoryImpl(
    ref.watch(organizationRemoteDatasourceProvider),
  ),
);

final getAllOrganizationUseCaseProvider = Provider(
  (ref) => GetAllOrganizationUseCase(
    ref.watch(getAllOrganizationRepositoryProvider),
  ),
);

final allOrganizationListProvider =
    FutureProvider.family<OrganizationListResponse, int>((ref, page) async {
      final useCase = ref.watch(getAllOrganizationUseCaseProvider);
      return await useCase.call(page: page, limit: 10);
    });

/// Provider to fetch ALL organizations for client-side filtering/sorting/pagination
final allOrganizationsProvider = FutureProvider<OrganizationListResponse>((ref) async {
  final useCase = ref.watch(getAllOrganizationUseCaseProvider);
  // Fetch with high limit to get all organizations at once
  // The datasource will automatically fetch all pages if needed
  return await useCase.call(page: 1, limit: 1000);
});

// Homeless providers for organizations
final donorHomelessDatasourceProvider = Provider(
  (ref) => DonorHomelessRemoteDatasource(ref.watch(organizationDioProvider)),
);

/// Provider to fetch homeless list by organization ID
/// Uses family modifier to accept organizationId parameter
final homelessListByOrgProvider =
    FutureProvider.family<HomelessListByOrgResponse, String>((
      ref,
      organizationId,
    ) async {
      final datasource = ref.watch(donorHomelessDatasourceProvider);
      final result = await datasource.getHomelessByOrganization(organizationId);

      return result;
    });

/// Provider to fetch ALL homeless people (for donor view)
/// @route GET /api/v1/homeless
final allHomelessListProvider = FutureProvider<AllHomelessResponse>((
  ref,
) async {
  final datasource = ref.watch(donorHomelessDatasourceProvider);
  final result = await datasource.getAllHomeless();
  return result;
});
