import 'package:go_router/go_router.dart';

import 'features/accounting/presentation/screens/accounting_page.dart';
import 'features/ai_assistant/presentation/screens/ai_chat_screen.dart';
import 'features/auth/presentation/screens/forget_password_screen.dart';
import 'features/auth/presentation/screens/home_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/compliance/presentation/screens/compliance_page.dart';
import 'features/compliance/presentation/screens/documents_manager_screen.dart';
import 'features/compliance/presentation/screens/documents_screen.dart';
import 'features/compliance/presentation/screens/eld_screen.dart';
import 'features/compliance/presentation/screens/hos_screen.dart';
import 'features/compliance/presentation/screens/hos_tracking_screen.dart';
import 'features/compliance/presentation/screens/reports_screen.dart';
import 'features/dashboard/presentation/screens/analytics_screen.dart';
import 'features/dashboard/presentation/screens/calendar_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/dispatch/presentation/screens/calendar_dispatch_screen.dart';
import 'features/dispatch/presentation/screens/dispatch_page.dart';
import 'features/drivers/presentation/screens/add_driver_screen.dart';
import 'features/drivers/presentation/screens/driver_details_screen.dart';
import 'features/drivers/presentation/screens/drivers_screen.dart';
import 'features/gamification/presentation/screens/badges_screen.dart';
import 'features/gamification/presentation/screens/leaderboard_screen.dart';
import 'features/gamification/presentation/screens/shop_screen.dart';
import 'features/invoicing/presentation/screens/invoice_details_screen.dart';
import 'features/invoicing/presentation/screens/invoices_list_screen.dart';
import 'features/invoicing/presentation/screens/invoices_screen.dart';
import 'features/invoicing/presentation/screens/invoicing_screen.dart';
import 'features/invoicing/presentation/screens/payments_screen.dart';
import 'features/loads/presentation/screens/create_load_screen.dart';
import 'features/loads/presentation/screens/loadboard_screen.dart';
import 'features/loads/presentation/screens/load_detail_screen.dart';
import 'features/loads/presentation/screens/load_details_screen.dart';
import 'features/loads/presentation/screens/loads_list_screen.dart';
import 'features/loads/presentation/screens/loads_screen.dart';
import 'features/loads/presentation/screens/tracking_screen.dart';
import 'features/marketplace/presentation/screens/browse_dispatchers_screen.dart';
import 'features/marketplace/presentation/screens/browse_drivers_screen.dart';
import 'features/marketplace/presentation/screens/marketplace_screen.dart';
import 'features/marketplace/presentation/screens/my_connection_screen.dart';
import 'features/messaging/presentation/screens/messages_screen.dart';
import 'features/messaging/presentation/screens/messaging_screen.dart';
import 'features/messaging/presentation/screens/notifications_screen.dart';
import 'features/onboarding/presentation/screens/company_setup_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/settings/presentation/screens/company_screen.dart';
import 'features/settings/presentation/screens/profile_screen.dart';
import 'features/settings/presentation/screens/settings_main_screen.dart';
import 'features/settings/presentation/screens/settings_page.dart';
import 'features/training/presentation/screens/course_detail_screen.dart';
import 'features/training/presentation/screens/course_screen.dart';
import 'features/training/presentation/screens/lesson_screen.dart';
import 'features/training/presentation/screens/progress_screen.dart';
import 'features/training/presentation/screens/quiz_screen.dart';
import 'features/training/presentation/screens/tms_simulator_screen.dart';
import 'features/training/presentation/screens/training_page.dart';

// Auto-generated routes based on discovered screens
final generatedRoutes = <GoRoute>[
  GoRoute(
    path: '/accounting',
    builder: (context, state) => const AccountingPage(),
  ),
  GoRoute(
    path: '/ai-chat',
    builder: (context, state) => const AiChatScreen(),
  ),
  GoRoute(
    path: '/forget-password',
    builder: (context, state) => const ForgetPasswordScreen(),
  ),
  GoRoute(
    path: '/home',
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/register',
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: '/splash',
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: '/compliance',
    builder: (context, state) => const CompliancePage(),
  ),
  GoRoute(
    path: '/documents-manager',
    builder: (context, state) => const DocumentsManagerScreen(),
  ),
  GoRoute(
    path: '/documents',
    builder: (context, state) => const DocumentsScreen(),
  ),
  GoRoute(
    path: '/eld',
    builder: (context, state) => const EldScreen(),
  ),
  GoRoute(
    path: '/hos',
    builder: (context, state) => const HosScreen(),
  ),
  GoRoute(
    path: '/hos-tracking',
    builder: (context, state) => const HosTrackingScreen(),
  ),
  GoRoute(
    path: '/reports',
    builder: (context, state) => const ReportsScreen(),
  ),
  GoRoute(
    path: '/analytics',
    builder: (context, state) => const AnalyticsScreen(),
  ),
  GoRoute(
    path: '/calendar',
    builder: (context, state) => const CalendarScreen(),
  ),
  GoRoute(
    path: '/dashboard',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/calendar-dispatch',
    builder: (context, state) => const CalendarDispatchScreen(),
  ),
  GoRoute(
    path: '/dispatch',
    builder: (context, state) => const DispatchPage(),
  ),
  GoRoute(
    path: '/add-driver',
    builder: (context, state) => const AddDriverScreen(),
  ),
  GoRoute(
    path: '/driver-details',
    builder: (context, state) => const DriverDetailsScreen(),
  ),
  GoRoute(
    path: '/drivers',
    builder: (context, state) => const DriversScreen(),
  ),
  GoRoute(
    path: '/badges',
    builder: (context, state) => const BadgesScreen(),
  ),
  GoRoute(
    path: '/leaderboard',
    builder: (context, state) => const LeaderboardScreen(),
  ),
  GoRoute(
    path: '/shop',
    builder: (context, state) => const ShopScreen(),
  ),
  GoRoute(
    path: '/invoice-details',
    builder: (context, state) => const InvoiceDetailsScreen(),
  ),
  GoRoute(
    path: '/invoices-list',
    builder: (context, state) => const InvoicesListScreen(),
  ),
  GoRoute(
    path: '/invoices',
    builder: (context, state) => const InvoicesScreen(),
  ),
  GoRoute(
    path: '/invoicing',
    builder: (context, state) => const InvoicingScreen(),
  ),
  GoRoute(
    path: '/payments',
    builder: (context, state) => const PaymentsScreen(),
  ),
  GoRoute(
    path: '/create-load',
    builder: (context, state) => const CreateLoadScreen(),
  ),
  GoRoute(
    path: '/loadboard',
    builder: (context, state) => const LoadboardScreen(),
  ),
  GoRoute(
    path: '/load-detail',
    builder: (context, state) => const LoadDetailScreen(),
  ),
  GoRoute(
    path: '/load-details',
    builder: (context, state) => const LoadDetailsScreen(),
  ),
  GoRoute(
    path: '/loads-list',
    builder: (context, state) => const LoadsListScreen(),
  ),
  GoRoute(
    path: '/loads',
    builder: (context, state) => const LoadsScreen(),
  ),
  GoRoute(
    path: '/tracking',
    builder: (context, state) => const TrackingScreen(),
  ),
  GoRoute(
    path: '/browse-dispatchers',
    builder: (context, state) => const BrowseDispatchersScreen(),
  ),
  GoRoute(
    path: '/browse-drivers',
    builder: (context, state) => const BrowseDriversScreen(),
  ),
  GoRoute(
    path: '/marketplace',
    builder: (context, state) => const MarketplaceScreen(),
  ),
  GoRoute(
    path: '/my-connection',
    builder: (context, state) => const MyConnectionScreen(),
  ),
  GoRoute(
    path: '/messages',
    builder: (context, state) => const MessagesScreen(),
  ),
  GoRoute(
    path: '/messaging',
    builder: (context, state) => const MessagingScreen(),
  ),
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: '/company-setup',
    builder: (context, state) => const CompanySetupScreen(),
  ),
  GoRoute(
    path: '/onboarding',
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(
    path: '/company',
    builder: (context, state) => const CompanyScreen(),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const ProfileScreen(),
  ),
  GoRoute(
    path: '/settings-main',
    builder: (context, state) => const SettingsMainScreen(),
  ),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsPage(),
  ),
  GoRoute(
    path: '/course-detail',
    builder: (context, state) => const CourseDetailScreen(),
  ),
  GoRoute(
    path: '/course',
    builder: (context, state) => const CourseScreen(),
  ),
  GoRoute(
    path: '/lesson',
    builder: (context, state) => const LessonScreen(),
  ),
  GoRoute(
    path: '/progress',
    builder: (context, state) => const ProgressScreen(),
  ),
  GoRoute(
    path: '/quiz',
    builder: (context, state) => const QuizScreen(),
  ),
  GoRoute(
    path: '/tms-simulator',
    builder: (context, state) => const TmsSimulatorScreen(),
  ),
  GoRoute(
    path: '/training',
    builder: (context, state) => const TrainingPage(),
  ),
];
