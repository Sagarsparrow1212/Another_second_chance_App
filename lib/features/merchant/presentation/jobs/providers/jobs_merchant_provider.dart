import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/datasources/jobs/job_remote_datasource.dart';
import '../../../data/models/jobs/jobs_model.dart';
import '../../../data/repositories/jobs/jobs_repository_impl.dart';
import '../../../data/usecases/jobs/get_merchant_jobs.dart';

// Helper provider to get merchant ID
final merchantIdProvider = FutureProvider<String?>((ref) async {
  try {
    final merchantBox = await Hive.openBox('merchantBox');
    final merchantId = merchantBox.get('merchantId')?.toString();
    return merchantId;
  } catch (e) {
    print('Error getting merchant ID: $e');
    return null;
  }
});

final jobsMerchantDioProvider = Provider((ref) => Dio());

final jobsMerchantRemoteDatasourceProvider = Provider(
  (ref) => JobsMerchantRemoteDatasource(ref.watch(jobsMerchantDioProvider)),
);

final jobsMerchantRepositoryProvider = Provider(
  (ref) => JobsMerchantRepositoryImpl(
    ref.watch(jobsMerchantRemoteDatasourceProvider),
  ),
);

final getMerchantJobsUseCaseProvider = Provider(
  (ref) => GetMerchantJobsUseCase(ref.watch(jobsMerchantRepositoryProvider)),
);

final jobsMerchantListProvider = FutureProvider<JobsMerchantListResponse>((
  ref,
) async {
  final merchantIdAsync = await ref.watch(merchantIdProvider.future);
  if (merchantIdAsync == null || merchantIdAsync.isEmpty) {
    throw Exception('Merchant ID not found. Please login again.');
  }
  final useCase = ref.watch(getMerchantJobsUseCaseProvider);
  return await useCase.call(merchantIdAsync);
});
