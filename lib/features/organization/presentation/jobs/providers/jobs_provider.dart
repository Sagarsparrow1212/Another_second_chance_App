import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/features/organization/data/datasources/jobs/jobs_remote_datasource.dart';
import 'package:homelyhope/features/organization/data/models/jobs/jobs_model.dart';
import 'package:homelyhope/features/organization/data/repositories/jobs/jobs_repository_impl.dart';
import 'package:homelyhope/features/organization/data/usecases/jobs/get_jobs_usecase.dart';

// Dio provider
final jobsDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final jobsRemoteDatasourceProvider = Provider(
  (ref) => JobsRemoteDatasource(ref.watch(jobsDioProvider)),
);

// Repository provider
final jobsRepositoryProvider = Provider(
  (ref) => JobsRepositoryImpl(ref.watch(jobsRemoteDatasourceProvider)),
);

// Use case provider
final getJobsUseCaseProvider = Provider<GetJobsUseCase>((ref) {
  return GetJobsUseCase(ref.watch(jobsRepositoryProvider));
});

// Jobs list provider (FutureProvider for async data)
// Paged jobs provider - request 10 items per page by default
final jobsListProvider = FutureProvider.family<JobsListResponse, int>((
  ref,
  page,
) async {
  final useCase = ref.watch(getJobsUseCaseProvider);
  return await useCase.call(page: page, limit: 10);
});

/// Provider to fetch ALL jobs for client-side filtering/sorting/pagination
final allJobsProvider = FutureProvider<JobsListResponse>((ref) async {
  final useCase = ref.watch(getJobsUseCaseProvider);
  // Fetch with high limit to get all jobs at once
  return await useCase.call(page: 1, limit: 1000);
});

final getJobDetailUseCaseProvider = Provider<GetJobsUseCase>((ref) {
  return GetJobsUseCase(ref.watch(jobsRepositoryProvider));
});

final jobDetailProvider = FutureProvider.family<JobDetailModel, String>((
  ref,
  jobId,
) async {
  final useCase = ref.watch(getJobDetailUseCaseProvider);
  return await useCase.getJobDetail(jobId);
});

final deleteJobUseCaseProvider = Provider<GetJobsUseCase>((ref) {
  return GetJobsUseCase(ref.watch(jobsRepositoryProvider));
});

final deleteJobProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  jobId,
) async {
  print('🔗 [JOBS PROVIDER] deleteJobProvider called with ID: $jobId');
  try {
    final useCase = ref.watch(deleteJobUseCaseProvider);
    print('🔗 [JOBS PROVIDER] UseCase obtained, calling deleteJob...');
    final result = await useCase.deleteJob(jobId);
    print('🔗 [JOBS PROVIDER] UseCase returned result: $result');
    return result;
  } catch (e, stackTrace) {
    print('❌ [JOBS PROVIDER] Error in deleteJobProvider: $e');
    print('❌ [JOBS PROVIDER] Stack trace: $stackTrace');
    rethrow;
  }
});
