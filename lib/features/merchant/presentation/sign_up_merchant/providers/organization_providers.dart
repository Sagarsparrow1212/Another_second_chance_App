import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/sign_up/merchant_remote_datasource.dart';
import '../../../data/repositories/sign_up/merchant_repository_impl.dart';

import '../../../data/models/sign_up/merchant_registration_model.dart';
import '../../../data/usecases/sign_up/register_merchant_usecase.dart';

// Dio provider (reuse from auth if available, or create new)
final merchantDioProvider = Provider((ref) => Dio());

// Datasource provider
final merchantRemoteDatasourceProvider = Provider(
  (ref) => MerchantRemoteDatasource(ref.watch(merchantDioProvider)),
);

// Repository provider
final merchantRepositoryProvider = Provider(
  (ref) => MerchantRepositoryImpl(ref.watch(merchantRemoteDatasourceProvider)),
);

// Usecase provider
final registerMerchantUseCaseProvider = Provider(
  (ref) => RegisterMerchantUseCase(ref.watch(merchantRepositoryProvider)),
);

final getMerchantDetailsUseCaseProvider = FutureProvider<MerchantDetailModel>((
  ref,
) async {
  final useCase = RegisterMerchantUseCase(
    ref.watch(merchantRepositoryProvider),
  );
  return await useCase.getMerchantDetails();
});

final merchantDetailsProvider = Provider<AsyncValue<MerchantDetailModel>>((
  ref,
) {
  return ref.watch(getMerchantDetailsUseCaseProvider);
});
