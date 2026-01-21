import 'package:go_router/go_router.dart';
import '../myprofile/pages/myprofile_page.dart';
import '../dashboard/pages/dashboard.dart';
import '../jobs/pages/jobs_page.dart';
import '../donation_history/pages/donation_history.dart';
import '../../../common/chat/presentation/pages/chat_list_page.dart';

final homelessRoutes = [
  GoRoute(
    path: '/homeless/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/homeless/jobs',
    builder: (context, state) => const JobsPage(),
  ),
  GoRoute(
    path: '/homeless/my-donations',
    builder: (context, state) => const DonationHistoryPage(),
  ),
  GoRoute(
    path: '/homeless/my-profile',
    builder: (context, state) => const MyProfilePage(),
  ),
  GoRoute(
    path: '/homeless/chat',
    builder: (context, state) => const ChatListPage(),
  ),
];
