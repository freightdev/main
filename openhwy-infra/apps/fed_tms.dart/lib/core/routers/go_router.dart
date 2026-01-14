import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:fed_tms/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:fed_tms/features/analytics/presentation/screens/reports_screen.dart';
import 'package:fed_tms/features/auth/data/services/auth_service.dart';
import 'package:fed_tms/features/auth/presentation/screens/login_screen.dart';
import 'package:fed_tms/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:fed_tms/features/auth/presentation/screens/splash_screen.dart';
import 'package:fed_tms/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:fed_tms/features/company/presentation/screens/company_screen.dart';
import 'package:fed_tms/features/compliance/presentation/screens/courses_screen.dart';
import 'package:fed_tms/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fed_tms/features/documents/presentation/screens/documents_screen.dart';
import 'package:fed_tms/features/drivers/presentation/screens/driver_details_screen.dart';
import 'package:fed_tms/features/drivers/presentation/screens/drivers_screen.dart';
import 'package:fed_tms/features/drivers/presentation/screens/eld_screen.dart';
import 'package:fed_tms/features/drivers/presentation/screens/hos_screen.dart';
import 'package:fed_tms/features/invoicing/presentation/screens/invoice_details_screen.dart';
import 'package:fed_tms/features/invoicing/presentation/screens/invoices_screen.dart';
import 'package:fed_tms/features/invoicing/presentation/screens/payments_screen.dart';
import 'package:fed_tms/features/loads/presentation/screens/create_load_screen.dart';
import 'package:fed_tms/features/loads/presentation/screens/load_details_screen.dart';
import 'package:fed_tms/features/loads/presentation/screens/loads_screen.dart';
import 'package:fed_tms/features/loads/presentation/screens/tracking_screen.dart';
import 'package:fed_tms/features/messaging/presentation/screens/messages_screen.dart';
import 'package:fed_tms/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:fed_tms/features/settings/presentation/screens/profile_screen.dart';
import 'package:fed_tms/features/settings/presentation/screens/settings_screen.dart';

// Screens
// Services


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: 'company-setup',
            name: 'company-setup',
            builder: (context, state) => const CompanySetupScreen(),
          ),
        ],
      ),

      // Loads
      GoRoute(
        path: '/loads',
        name: 'loads',
        builder: (context, state) => const LoadsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'load-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LoadDetailsScreen(loadId: id);
            },
          ),
        ],
      ),

      // Drivers
      GoRoute(
        path: '/drivers',
        name: 'drivers',
        builder: (context, state) => const DriversScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'driver-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DriverDetailsScreen(driverId: id);
            },
          ),
        ],
      ),

      // Accounting
      GoRoute(
        path: '/invoices',
        name: 'invoices',
        builder: (context, state) => const InvoicesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'invoice-details',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return InvoiceDetailsScreen(invoiceId: id);
            },
          ),
        ],
      ),

      // Payments
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),

      // Compliance
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => const DocumentsScreen(),
      ),

      // HOS
      GoRoute(
        path: '/hos',
        name: 'hos',
        builder: (context, state) => const HosScreen(),
      ),

      // Training
      GoRoute(
        path: '/training',
        name: 'training',
        builder: (context, state) => const CoursesScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Analytics
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Calendar
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),

      // Messages
      GoRoute(
        path: '/messages',
        name: 'messages',
        builder: (context, state) => const MessagesScreen(),
      ),

      // Reports
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Create Load
      GoRoute(
        path: '/loads/create',
        name: 'create-load',
        builder: (context, state) => const CreateLoadScreen(),
      ),

      // ELD
      GoRoute(
        path: '/eld',
        name: 'eld',
        builder: (context, state) => const EldScreen(),
      ),

      // Tracking
      GoRoute(
        path: '/tracking',
        name: 'tracking',
        builder: (context, state) => const TrackingScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
