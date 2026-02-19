import 'package:go_router/go_router.dart';
// import '../../../organization/presentation/homeless_people/pages/homeless_table.dart';
import '../applicants/pages/applicants_page.dart';
import '../myprofile/pages/myprofile_page.dart';
import '../dashboard/pages/dashboard.dart';
import '../jobs/pages/jobs_page.dart';
import '../jobs/pages/add_job_page.dart';
import '../../../common/chat/presentation/pages/chat_list_page.dart';
import '../sign_up_merchant/pages/sign_up_page.dart';
import '../../data/models/myprofile/myprofile_model.dart';

final merchantRoutes = [
  GoRoute(
    path: '/merchant/dashboard',
    builder: (context, state) => const DashboardPage(),
  ),
  GoRoute(
    path: '/merchant/signUp',
    builder: (context, state) {
      final merchantToEdit = state.extra as MyProfileModel?;
      return SignUpMerchantPage(merchantToEdit: merchantToEdit);
    },
  ),
  GoRoute(
    path: '/merchant/jobs',
    builder: (context, state) => const JobsPage(),
  ),
  GoRoute(
    path: '/merchant/add-job',
    builder: (context, state) => const AddJobPage(),
  ),
  GoRoute(
    path: '/merchant/applicants',
    builder: (context, state) => const ApplicantsPage(),
  ),
  GoRoute(
    path: '/merchant/my-profile',
    builder: (context, state) => const MyProfilePage(),
  ),
  GoRoute(
    path: '/merchant/chat',
    builder: (context, state) => const ChatListPage(),
  ),
];
