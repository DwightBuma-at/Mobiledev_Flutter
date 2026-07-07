import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'pages/blotter.dart';
import 'pages/certificates.dart';
import 'pages/dashboard.dart';
import 'pages/events.dart';
import 'pages/landing_page.dart';
import 'pages/logs.dart';
import 'pages/officials.dart';
import 'pages/resident_blotter.dart';
import 'pages/resident_certificates.dart';
import 'pages/resident_dashboard.dart';
import 'pages/resident_events.dart';
import 'pages/residents.dart';
import 'routes/app_routes.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await StorageService.initialize();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const BarangayApp(),
    ),
  );
}

class BarangayApp extends StatelessWidget {
  const BarangayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barangay Information Management System',
      debugShowCheckedModeBanner: false,
      // ignore: deprecated_member_use
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue600),
        scaffoldBackgroundColor: AppColors.slate50,
        textTheme: AppTextStyles.theme(),
        useMaterial3: false,
      ),
      initialRoute: AppRoutes.landing,
      routes: {
        AppRoutes.landing: (_) => const LandingPage(),
        AppRoutes.adminDashboard: (_) => const AdminDashboardPage(),
        AppRoutes.adminResidents: (_) => const ResidentsPage(),
        AppRoutes.adminOfficials: (_) => const OfficialsPage(),
        AppRoutes.adminBlotter: (_) => const BlotterPage(),
        AppRoutes.adminEvents: (_) => const EventsPage(),
        AppRoutes.adminCertificates: (_) => const CertificatesPage(),
        AppRoutes.residentDashboard: (_) => const ResidentDashboardPage(),
        AppRoutes.residentBlotter: (_) => const ResidentBlotterPage(),
        AppRoutes.residentEvents: (_) => const ResidentEventsPage(),
        AppRoutes.residentCertificates: (_) => const ResidentCertificatesPage(),
        AppRoutes.residentLogs: (_) => const LogsPage(),
      },
    );
  }
}
