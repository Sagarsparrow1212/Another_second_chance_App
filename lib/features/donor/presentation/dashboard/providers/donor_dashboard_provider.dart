import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/dashboard/donor_dashboard_remote_datasource.dart';
import '../../../data/models/dashboard/donor_dashboard_response.dart';

// Dio provider (can reuse existing or create new locally if needed, but best to reuse if global, here we create simpler for isolation or reuse)
final donorDashboardDioProvider = Provider((ref) => Dio());

// Remote datasource provider
final donorDashboardRemoteDatasourceProvider = Provider(
  (ref) => DonorDashboardRemoteDatasource(ref.watch(donorDashboardDioProvider)),
);

// FutureProvider for dashboard stats
final donorDashboardStatsProvider =
    FutureProvider.autoDispose<DonorDashboardData>((ref) async {
      final datasource = ref.watch(donorDashboardRemoteDatasourceProvider);
      return datasource.getDashboardStats();
    });
