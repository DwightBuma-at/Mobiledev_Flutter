import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'firebase_options.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
  runApp(BarangayBootstrapApp(initialization: StorageService.initialize()));
}

class BarangayBootstrapApp extends StatelessWidget {
  const BarangayBootstrapApp({required this.initialization, super.key});

  final Future<void> initialization;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const BarangayApp();
        }
        return MaterialApp(
          title: 'Barangay Information Management System',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: Scaffold(
            backgroundColor: AppColors.slate50,
            body: Center(
              child: snapshot.hasError
                  ? const _StartupMessage(
                      title: 'Unable to connect',
                      message: 'Please check Firebase or your connection.',
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class BarangayApp extends StatelessWidget {
  const BarangayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barangay Information Management System',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
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

ThemeData _buildTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue600),
    scaffoldBackgroundColor: AppColors.slate50,
    textTheme: AppTextStyles.theme(),
    useMaterial3: false,
  );
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.red600, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.slate800,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
