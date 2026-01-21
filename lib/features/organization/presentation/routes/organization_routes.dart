import 'package:go_router/go_router.dart';
import 'package:homelyhope/features/common/chat/presentation/pages/CreateNewChat.dart';
import 'package:homelyhope/features/organization/presentation/jobs/pages/jobs_details.dart';
import 'package:homelyhope/features/organization/presentation/sign_up/pages/sign_up_page.dart';
import 'package:homelyhope/features/organization/data/models/sign_up/organization_registration_model.dart';
import '../myprofile/pages/myprofile_page.dart';
import '../sign_up/pages/verification_page.dart';
import '../dashboard/pages/dashboard.dart';
import '../homeless_people/pages/homeless_table.dart';
import '../homeless_people/pages/add_homeless.dart';
import '../homeless_people/pages/view_homeless_detail.dart';
import '../jobs/pages/jobs_page.dart';
import '../donation_history/pages/donation_history.dart';
import '../../../common/chat/presentation/pages/chat_list_page.dart';

final organizationRoutes = [
  GoRoute(
    path: '/organization/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/organization/signUp',
    builder: (context, state) {
      final organizationToEdit = state.extra as OrganizationDetailModel?;
      return OrgSignUpPage(organizationToEdit: organizationToEdit);
    },
  ),
  GoRoute(
    path: '/organization/verification',
    builder: (context, state) => const VerificationPage(),
  ),
  GoRoute(
    path: '/organization/homeless-table',
    builder: (context, state) => const HomelessTable(),
  ),
  GoRoute(
    path: '/organization/add-homeless',
    builder: (context, state) => const AddHomeless(),
  ),
  GoRoute(
    path: '/organization/view-homeless/:id',
    name: 'view-homeless',
    builder: (context, state) {
      final homelessId = state.pathParameters['id']!;
      return ViewHomelessDetailPage(homelessId: homelessId);
    },
  ),
  GoRoute(
    path: '/organization/jobs',
    builder: (context, state) => const JobsPage(),
  ),
  GoRoute(
    path: '/organization/donation-history',
    builder: (context, state) => const DonationHistoryPage(),
  ),
  GoRoute(
    path: '/organization/my-profile',
    builder: (context, state) => const MyProfilePage(),
  ),
  GoRoute(
    path: '/organization/chat',
    builder: (context, state) => const ChatListPage(),
  ),
  GoRoute(
    path: '/organization/chat/start',
    builder: (context, state) => const StartChatListPage(),
  ),
  GoRoute(
    path: '/organization/view-job/:id',
    builder: (context, state) {
      final jobId = state.pathParameters['id']!;
      return ViewJobDetailPage(jobId: jobId);
    },
  ),
];
