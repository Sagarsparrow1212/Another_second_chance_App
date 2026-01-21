import 'package:flutter/material.dart';
import 'package:homelyhope/features/donor/data/datasources/homeless_people/homeless_remote_datasource.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/features/donor/presentation/homeless_people/pages/homeless_detail.dart';
import '../homeless_people/pages/homeless_donate_page.dart';
import '../homeless_people/pages/homeless_table.dart';
import '../organization/organization_homeless_page.dart';
import '../myprofile/pages/myprofile_page.dart';
import '../dashboard/pages/dashboard.dart';
import '../donation_history/pages/donation_history.dart';
import '../organization/organization_table.dart';
import '../sign_up/signup_page.dart';
import '../../data/models/profile/donor_profile_model.dart';

final donorRoutes = [
  GoRoute(
    path: '/donor/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/donor/signUp',
    builder: (context, state) {
      final donorToEdit = state.extra as DonorProfileModel?;
      return SignUpDonorPage(donorToEdit: donorToEdit);
    },
  ),
  GoRoute(
    path: '/donor/homeless-table',
    builder: (context, state) => const DonorHomelessTable(),
  ),
  GoRoute(
    path: '/donor/homeless/:id/donate',
    builder: (context, state) {
      final person = state.extra as HomelessPerson?;
      if (person == null) {
        return const Scaffold(
          body: Center(child: Text('Homeless person data not provided')),
        );
      }
      return DonorHomelessDonatePage(homeless: person);
    },
  ),
  GoRoute(
    path: '/donor/homeless/:id',
    builder: (context, state) {
      final homeless = state.extra as HomelessPerson?;
      return HomelessDetailPage(
        homelessId: state.pathParameters['id'] ?? '',
        homeless: homeless,
      );
    },
  ),
  GoRoute(
    path: '/donor/organization/:id/homeless',
    builder: (context, state) {
      final args = state.extra as OrganizationHomelessArgs?;
      final orgId = state.pathParameters['id'] ?? '';
      return OrganizationHomelessPage(
        organizationId: orgId,
        organizationName: args?.organizationName ?? 'Organization',
        gradientColors: args?.gradientColors,
      );
    },
  ),
  GoRoute(
    path: '/donor/organization-table',
    builder: (context, state) => const OrganizationTable(),
  ),
  GoRoute(
    path: '/donor/my-donations',
    builder: (context, state) => const DonationHistoryPage(),
  ),
  GoRoute(
    path: '/donor/my-profile',
    builder: (context, state) => const MyProfilePage(),
  ),
];
