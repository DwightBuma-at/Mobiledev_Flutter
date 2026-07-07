import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../routes/app_routes.dart';

class SidebarItem {
  const SidebarItem(this.label, this.route, this.icon);
  final String label;
  final String route;
  final IconData icon;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.isResident,
    this.onLogout,
    this.residentName,
  });

  final String currentRoute;
  final bool isResident;
  final VoidCallback? onLogout;
  final String? residentName;

  @override
  Widget build(BuildContext context) {
    final items = isResident ? _residentItems : _adminItems;
    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.slate200)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.blue600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Barangay Information\nManagement System',
                    style: TextStyle(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(right: 8),
              children: [
                _Section(
                  title: 'Main',
                  children: [
                    _NavItem(
                      item: items.first,
                      active: currentRoute == items.first.route,
                    ),
                  ],
                ),
                if (!isResident)
                  _Section(
                    title: 'People',
                    children: items
                        .where(
                          (item) =>
                              item.route == AppRoutes.adminResidents ||
                              item.route == AppRoutes.adminOfficials,
                        )
                        .map(
                          (item) => _NavItem(
                            item: item,
                            active: currentRoute == item.route,
                          ),
                        )
                        .toList(),
                  ),
                _Section(
                  title: isResident ? 'Services' : 'Records & Services',
                  children: items
                      .where((item) => item.route != items.first.route)
                      .where(
                        (item) =>
                            isResident ||
                            (item.route != AppRoutes.adminResidents &&
                                item.route != AppRoutes.adminOfficials),
                      )
                      .map(
                        (item) => _NavItem(
                          item: item,
                          active: currentRoute == item.route,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.slate200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      isResident ? 'R' : 'A',
                      style: const TextStyle(
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residentName ??
                            (isResident ? 'Resident' : 'Administrator'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        isResident ? 'Resident portal' : 'admin@barangay.gov',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Log out',
                  color: AppColors.slate400,
                  hoverColor: AppColors.red50,
                  onPressed:
                      onLogout ??
                      () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.landing,
                        (_) => false,
                      ),
                  icon: const Icon(Icons.logout, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _adminItems = [
    SidebarItem('Dashboard', AppRoutes.adminDashboard, Icons.home_outlined),
    SidebarItem('Residents', AppRoutes.adminResidents, Icons.people_outline),
    SidebarItem('Officials', AppRoutes.adminOfficials, Icons.groups_outlined),
    SidebarItem('Blotter Records', AppRoutes.adminBlotter, Icons.warning_amber),
    SidebarItem('Events', AppRoutes.adminEvents, Icons.calendar_today_outlined),
    SidebarItem(
      'Certificates',
      AppRoutes.adminCertificates,
      Icons.description_outlined,
    ),
  ];

  static const _residentItems = [
    SidebarItem('Dashboard', AppRoutes.residentDashboard, Icons.home_outlined),
    SidebarItem(
      'Blotter Reports',
      AppRoutes.residentBlotter,
      Icons.warning_amber,
    ),
    SidebarItem(
      'Events',
      AppRoutes.residentEvents,
      Icons.calendar_today_outlined,
    ),
    SidebarItem(
      'Certificates',
      AppRoutes.residentCertificates,
      Icons.description_outlined,
    ),
    SidebarItem('Logs', AppRoutes.residentLogs, Icons.history),
  ];
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.active});
  final SidebarItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.pushNamed(context, item.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.blue50 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: active ? AppColors.blue700 : AppColors.slate600,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: active ? AppColors.blue700 : AppColors.slate600,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
