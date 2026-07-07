import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../services/storage_service.dart';
import 'app_sidebar.dart';
import 'confirmation_modal.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
    required this.isResident,
  });

  final String currentRoute;
  final Widget child;
  final bool isResident;

  @override
  Widget build(BuildContext context) {
    final resident = StorageService.currentResident();
    Future<void> handleLogout() async {
      final confirmed = await showConfirmationModal(
        context,
        title: 'Log out',
        message: 'Are you sure you want to log out of this account?',
        confirmText: 'Log out',
        danger: true,
        icon: Icons.logout,
      );
      if (!confirmed || !context.mounted) return;
      StorageService.clearCurrentResident();
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }

    Widget sidebar() => AppSidebar(
      currentRoute: currentRoute,
      isResident: isResident,
      residentName: resident?['name']?.toString(),
      onLogout: handleLogout,
    );

    Widget content(double width) => SingleChildScrollView(
      padding: EdgeInsets.all(width < 720 ? 20 : AppSpacing.pagePadding),
      child: child,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Scaffold(
            backgroundColor: AppColors.slate50,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.slate700,
              iconTheme: const IconThemeData(color: AppColors.slate700),
              title: const Text(
                'Barangay Information Management System',
                style: TextStyle(
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            drawer: Drawer(width: AppSpacing.sidebarWidth, child: sidebar()),
            body: content(constraints.maxWidth),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.slate50,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sidebar(),
              Expanded(child: content(constraints.maxWidth)),
            ],
          ),
        );
      },
    );
  }
}
