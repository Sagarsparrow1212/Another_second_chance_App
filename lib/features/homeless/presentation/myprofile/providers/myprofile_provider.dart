import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../organization/data/models/homeless_people/homeless_model.dart';
import '../../../data/datasources/myprofile/myprofile_remote_datasource.dart';

// Dio provider
final _dioProvider = Provider((ref) => Dio());

// Datasource provider
final myProfileDatasourceProvider = Provider(
  (ref) => MyProfileRemoteDatasource(ref.watch(_dioProvider)),
);

// Profile provider
final myProfileProvider = FutureProvider<HomelessModel>((ref) async {
  final datasource = ref.watch(myProfileDatasourceProvider);
  return await datasource.getMyProfile();
});
