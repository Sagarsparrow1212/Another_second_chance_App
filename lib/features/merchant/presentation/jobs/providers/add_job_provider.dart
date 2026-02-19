import 'package:flutter_riverpod/legacy.dart';
import '../../../data/datasources/jobs/job_remote_datasource.dart';
import 'jobs_merchant_provider.dart';

/// State for add/edit job operation
class AddJobState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  AddJobState({this.isLoading = false, this.error, this.isSuccess = false});

  AddJobState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return AddJobState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Provider for add/edit job state management
class AddJobNotifier extends StateNotifier<AddJobState> {
  final JobsMerchantRemoteDatasource _datasource;

  AddJobNotifier(this._datasource) : super(AddJobState());

  /// Create a new job
  Future<void> createJob(
    Map<String, dynamic> jobData,
    String merchantId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _datasource.createJob(jobData, merchantId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update an existing job
  Future<void> updateJob(String jobId, Map<String, dynamic> jobData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _datasource.updateJob(jobId, jobData);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Delete a job
  Future<void> deleteJob(String jobId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _datasource.deleteJob(jobId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = AddJobState();
  }
}

/// Provider for add/edit job notifier
final addJobProvider = StateNotifierProvider<AddJobNotifier, AddJobState>((
  ref,
) {
  final datasource = ref.watch(jobsMerchantRemoteDatasourceProvider);
  return AddJobNotifier(datasource);
});
