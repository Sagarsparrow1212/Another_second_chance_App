import '../../models/homeless_people/homeless_model.dart';

abstract class HomelessRepository {
  Future<HomelessListResponse> getHomelessByOrganization(
    String organizationId, {
    String? search,
  });

  Future<HomelessDetailResponse> getHomelessById(String homelessId);
}
