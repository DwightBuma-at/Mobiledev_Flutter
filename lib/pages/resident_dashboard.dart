import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/status_dropdown.dart';
import '../widgets/summary_card.dart';

class ResidentDashboardPage extends StatefulWidget {
  const ResidentDashboardPage({super.key});

  @override
  State<ResidentDashboardPage> createState() => _ResidentDashboardPageState();
}

class _ResidentDashboardPageState extends State<ResidentDashboardPage> {
  @override
  void initState() {
    super.initState();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = StorageService.currentResident();
    final residentName = '${session?['name'] ?? 'Resident'}';
    final residentUsername = '${session?['username'] ?? ''}';
    final residentId = session?['id'];
    final residentRecord = StorageService.residents().where((resident) {
      return resident.id == session?['id'] ||
          resident.username == residentUsername;
    }).firstOrNull;

    final blotters = StorageService.blotters()
        .where(
          (item) => _isResidentRecord(
            item.submittedBy,
            item.residentId,
            item.residentName,
            item.complainant,
            residentId,
            residentName,
            residentUsername,
          ),
        )
        .toList();
    final certs = StorageService.certs()
        .where(
          (item) => _isResidentRecord(
            item.submittedBy,
            item.residentId,
            item.residentName,
            item.resident,
            residentId,
            residentName,
            residentUsername,
          ),
        )
        .toList();
    final events = StorageService.events()
        .where(
          (item) => !item.isCompleted && item.submittedBy != 'Resident Portal',
        )
        .toList();

    final activeBlotters = blotters.where((item) => !item.isCompleted).toList();
    final completedBlotters = blotters
        .where((item) => item.isCompleted)
        .toList();
    final pendingCerts = certs.where((item) => !item.isClaimed).toList();
    final claimedCerts = certs.where((item) => item.isClaimed).toList();

    final recent = <_ResidentActivity>[
      ...blotters.map(
        (b) => _ResidentActivity(
          id: b.id,
          route: AppRoutes.residentBlotter,
          title: b.caseNo.isEmpty ? 'Blotter report' : b.caseNo,
          meta: '${b.type} / ${b.status}',
          pill: b.status,
          color: b.isCompleted ? AppColors.emerald100 : AppColors.amber100,
          textColor: b.isCompleted ? AppColors.emerald700 : AppColors.amber700,
        ),
      ),
      ...certs.map(
        (c) => _ResidentActivity(
          id: c.id,
          route: AppRoutes.residentCertificates,
          title: c.controlNo.isEmpty ? 'Certificate request' : c.controlNo,
          meta: '${c.docType} / ${c.status}',
          pill: c.status,
          color: c.isClaimed ? AppColors.emerald100 : AppColors.blue100,
          textColor: c.isClaimed ? AppColors.emerald700 : AppColors.blue700,
        ),
      ),
    ]..sort((a, b) => b.id.compareTo(a.id));

    return AppShell(
      currentRoute: AppRoutes.residentDashboard,
      isResident: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Resident Dashboard',
            subtitle:
                'Track blotter reports and certificate requests submitted through the resident portal.',
            eyebrow: 'Dashboard',
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.slate200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final info = Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.blue100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Center(
                        child: Text(
                          'R',
                          style: TextStyle(
                            color: AppColors.blue700,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            residentRecord?.fullName ?? residentName,
                            style: const TextStyle(
                              color: AppColors.slate800,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            residentRecord?.classification ?? 'Resident',
                            style: const TextStyle(color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final chip = StatusChip(
                  label: residentRecord?.residentStatus ?? 'Active',
                  background: AppColors.emerald100,
                  foreground: AppColors.emerald700,
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [info, const SizedBox(height: 16), chip],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: info),
                    chip,
                  ],
                );
              },
            ),
          ),
          _ResidentSummaryGrid(
            cards: [
              SummaryCard(
                title: 'Active Blotters',
                value: '${activeBlotters.length}',
                footer: '${completedBlotters.length} completed reports',
                icon: Icons.warning_amber,
                iconBg: AppColors.red50,
                iconColor: AppColors.red600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.residentBlotter),
              ),
              SummaryCard(
                title: 'Certificate Requests',
                value: '${pendingCerts.length}',
                footer: '${claimedCerts.length} claimed documents',
                icon: Icons.description_outlined,
                iconBg: AppColors.emerald50,
                iconColor: AppColors.emerald600,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.residentCertificates,
                ),
              ),
              SummaryCard(
                title: 'Posted Events',
                value: '${events.length}',
                footer: 'Active barangay events',
                icon: Icons.calendar_today_outlined,
                iconBg: AppColors.purple50,
                iconColor: AppColors.purple600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.residentEvents),
              ),
              SummaryCard(
                title: 'Logs',
                value: '${completedBlotters.length + claimedCerts.length}',
                footer: 'Completed blotters and claimed certificates',
                icon: Icons.history,
                iconBg: AppColors.blue50,
                iconColor: AppColors.blue600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.residentLogs),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.slate200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            color: AppColors.slate800,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Latest records from your submissions.',
                          style: TextStyle(color: AppColors.slate500),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.slate200),
                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No recent activity yet.',
                      style: TextStyle(color: AppColors.slate400),
                    ),
                  )
                else
                  ...recent
                      .take(6)
                      .map(
                        (item) => ListTile(
                          onTap: () => Navigator.pushNamed(context, item.route),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppColors.slate800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(item.meta),
                          trailing: StatusChip(
                            label: item.pill,
                            background: item.color,
                            foreground: item.textColor,
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

  bool _isResidentRecord(
    String source,
    int? recordResidentId,
    String recordResidentName,
    String value,
    Object? residentId,
    String residentName,
    String username,
  ) {
    final normalized = value.toLowerCase();
    final savedResidentName = recordResidentName.toLowerCase();
    return source == 'Resident Portal' &&
        ((residentId != null && '$recordResidentId' == '$residentId') ||
            savedResidentName == residentName.toLowerCase() ||
            normalized.contains(residentName.toLowerCase()) ||
            normalized.contains(username.toLowerCase()) ||
            residentName == 'Resident');
  }
}

class _ResidentSummaryGrid extends StatelessWidget {
  const _ResidentSummaryGrid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            mainAxisExtent: 172,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _ResidentActivity {
  const _ResidentActivity({
    required this.id,
    required this.route,
    required this.title,
    required this.meta,
    required this.pill,
    required this.color,
    required this.textColor,
  });

  final int id;
  final String route;
  final String title;
  final String meta;
  final String pill;
  final Color color;
  final Color textColor;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
