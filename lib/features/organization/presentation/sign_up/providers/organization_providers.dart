import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/organization/data/datasources/sign_up/organization_remote_datasource.dart';
import 'package:homelyhope/features/organization/data/repositories/sign_up/organization_repository_impl.dart';
import 'package:homelyhope/features/organization/data/usecases/sign_up/register_organization_usecase.dart';

import '../../../data/models/sign_up/organization_registration_model.dart';

// Dio provider (reuse from auth if available, or create new)
final organizationDioProvider = Provider((ref) => Dio());

// Datasource provider
final organizationRemoteDatasourceProvider = Provider(
  (ref) => OrganizationRemoteDatasource(ref.watch(organizationDioProvider)),
);

// Repository provider
final organizationRepositoryProvider = Provider(
  (ref) => OrganizationRepositoryImpl(
    ref.watch(organizationRemoteDatasourceProvider),
  ),
);

// Usecase provider
final registerOrganizationUseCaseProvider = Provider(
  (ref) =>
      RegisterOrganizationUseCase(ref.watch(organizationRepositoryProvider)),
);

final getOrganizationDetailsUseCaseProvider =
    FutureProvider<OrganizationDetailModel>((ref) async {
      final useCase = RegisterOrganizationUseCase(
        ref.watch(organizationRepositoryProvider),
      );
      return await useCase.getOrganizationDetails();
    });

final organizationDetailsProvider =
    Provider<AsyncValue<OrganizationDetailModel>>((ref) {
      return ref.watch(getOrganizationDetailsUseCaseProvider);
    });

final updateOrganizationDetailsUseCaseProvider =
    FutureProvider.family<OrganizationDetailModel, OrganizationDetailModel>((
      ref,
      OrganizationDetailModel model,
    ) async {
      print(
        '🔗 [ORG PROVIDER] updateOrganizationDetailsUseCaseProvider called',
      );
      print('🔗 [ORG PROVIDER] Model ID: ${model.id}');

      final useCase = RegisterOrganizationUseCase(
        ref.watch(organizationRepositoryProvider),
      );

      // Get id from model, throw error if id is null
      if (model.id == null || model.id!.isEmpty) {
        throw Exception('Organization ID is required for update');
      }

      print('🔗 [ORG PROVIDER] Calling useCase.updateOrganizationDetails...');
      final result = await useCase.updateOrganizationDetails(model, model.id!);
      print('🔗 [ORG PROVIDER] Update completed: $result');

      return result;
    });
