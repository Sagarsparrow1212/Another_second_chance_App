import 'package:flutter/src/material/scaffold.dart';

import 'package:flutter/src/widgets/basic.dart';

import 'package:flutter/src/widgets/framework.dart';

import 'homeless_repository.dart';
import '../../models/homeless_people/homeless_model.dart';
import '../../datasources/homeless_people/homeless_remote_datasource.dart';

class HomelessRepositoryImpl implements HomelessRepository {
  final HomelessRemoteDatasource remoteDatasource;

  HomelessRepositoryImpl(this.remoteDatasource);

  @override
  Future<HomelessListResponse> getHomelessByOrganization(
    String organizationId, {
    String? search,
  }) async {
    return await remoteDatasource.getHomelessByOrganization(
      organizationId,
      search: search,
    );
  }

  @override
  Future<HomelessDetailResponse> getHomelessById(String homelessId) async {
    return await remoteDatasource.getHomelessById(homelessId);
  }
}
