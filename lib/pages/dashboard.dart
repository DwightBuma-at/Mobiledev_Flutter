import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/status_dropdown.dart';
import '../widgets/summary_card.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
    final residents = StorageService.residents();
    final officials = StorageService.officials();
    final blotters = StorageService.blotters();
    final events = StorageService.events();
    final certs = StorageService.certs();
    final today = todayIso();

    final openBlotters = blotters.where((b) => !b.isCompleted).toList();
    final completedBlotters = blotters.where((b) => b.isCompleted).toList();
    final pendingCerts = certs.where((c) => !c.isClaimed).toList();
    final claimedCerts = certs.where((c) => c.isClaimed).toList();
    final upcomingEvents =
        events
            .where((e) => !e.isCompleted && e.date.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final activeOfficials = officials
        .where((o) => o.status == 'Active')
        .toList();
    final voters = residents
        .where((r) => r.voterStatus == 'Registered')
        .toList();

    final recentItems = <_Activity>[
      ...residents.map(
        (r) => _Activity(
          id: r.id,
          title:
              '${r.lastName}${r.lastName.isNotEmpty ? ', ' : ''}${r.firstName}',
          meta:
              '${r.purok.isEmpty ? 'No purok' : r.purok} / ${r.classification.isEmpty ? 'Resident' : r.classification}',
          pill: 'Resident',
          route: AppRoutes.adminResidents,
          color: AppColors.blue100,
          textColor: AppColors.blue700,
        ),
      ),
      ...blotters.map(
        (b) => _Activity(
          id: b.id,
          title: b.caseNo.isEmpty ? 'Blotter record' : b.caseNo,
          meta:
              '${b.complainant.isEmpty ? 'Complainant' : b.complainant} vs. ${b.respondent.isEmpty ? 'Respondent' : b.respondent}',
          pill: b.isCompleted ? 'Completed' : b.status,
          route: AppRoutes.adminBlotter,
          color: b.isCompleted ? AppColors.emerald100 : AppColors.red100,
          textColor: b.isCompleted ? AppColors.emerald700 : AppColors.red700,
        ),
      ),
      ...events.map(
        (e) => _Activity(
          id: e.id,
          title: e.title.isEmpty ? 'Barangay event' : e.title,
          meta: e.date.isEmpty ? 'No date' : e.date,
          pill: 'Event',
          route: AppRoutes.adminEvents,
          color: AppColors.purple100,
          textColor: AppColors.purple700,
        ),
      ),
      ...certs.map(
        (c) => _Activity(
          id: c.id,
          title: c.controlNo.isEmpty ? 'Certificate request' : c.controlNo,
          meta:
              '${c.resident.isEmpty ? 'Resident' : c.resident} / ${c.docType.isEmpty ? 'Document' : c.docType}',
          pill: c.status,
          route: AppRoutes.adminCertificates,
          color: c.isClaimed ? AppColors.emerald100 : AppColors.amber100,
          textColor: c.isClaimed ? AppColors.emerald700 : AppColors.amber700,
        ),
      ),
    ]..sort((a, b) => b.id.compareTo(a.id));

    final attentionItems = <_Activity>[
      ...openBlotters
          .take(3)
          .map(
            (b) => _Activity(
              id: b.id,
              title: b.caseNo.isEmpty ? 'Open blotter' : b.caseNo,
              meta: '${b.complainant} vs. ${b.respondent}',
              pill: b.status,
              route: AppRoutes.adminBlotter,
              color: AppColors.red100,
              textColor: AppColors.red700,
            ),
          ),
      ...pendingCerts
          .take(3)
          .map(
            (c) => _Activity(
              id: c.id,
              title: c.controlNo.isEmpty ? 'Certificate request' : c.controlNo,
              meta: '${c.resident} / ${c.docType}',
              pill: c.status,
              route: AppRoutes.adminCertificates,
              color: AppColors.amber100,
              textColor: AppColors.amber700,
            ),
          ),
    ].take(5).toList();

    return AppShell(
      currentRoute: AppRoutes.adminDashboard,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            eyebrow: 'Dashboard',
            title: 'Community Overview',
            subtitle:
                'Monitor residents, requests, reports, and upcoming barangay activities.',
            bottomSpacing: 24,
          ),
          _SummaryGrid(
            cards: [
              SummaryCard(
                title: 'Total Residents',
                value: '${residents.length}',
                footer: '${voters.length} registered voters',
                icon: Icons.people_outline,
                iconBg: AppColors.blue50,
                iconColor: AppColors.blue600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminResidents),
              ),
              SummaryCard(
                title: 'Open Blotters',
                value: '${openBlotters.length}',
                footer: '${completedBlotters.length} resolved or dismissed',
                icon: Icons.warning_amber,
                iconBg: AppColors.red50,
                iconColor: AppColors.red600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminBlotter),
              ),
              SummaryCard(
                title: 'Pending Certificates',
                value: '${pendingCerts.length}',
                footer: '${claimedCerts.length} claimed documents',
                icon: Icons.description_outlined,
                iconBg: AppColors.emerald50,
                iconColor: AppColors.emerald600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminCertificates),
              ),
              SummaryCard(
                title: 'Upcoming Events',
                value: '${upcomingEvents.length}',
                footer: '${activeOfficials.length} active officials',
                icon: Icons.calendar_today_outlined,
                iconBg: AppColors.purple50,
                iconColor: AppColors.purple600,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.adminEvents),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final sidePanels = Column(
                children: [
                  _Panel(
                    title: 'Upcoming Schedule',
                    subtitle: 'Nearest barangay events.',
                    empty: 'No upcoming events.',
                    items: upcomingEvents
                        .take(4)
                        .map(
                          (e) => _Activity(
                            id: e.id,
                            title: e.title,
                            meta:
                                '${e.date.isEmpty ? 'No date' : e.date} / ${e.venue.isEmpty ? 'No location' : e.venue}',
                            pill: e.type.isEmpty ? 'Event' : e.type,
                            route: AppRoutes.adminEvents,
                            color: AppColors.purple100,
                            textColor: AppColors.purple700,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  _Panel(
                    title: 'Needs Attention',
                    subtitle: 'Open work that may require follow-up.',
                    empty: 'No urgent items.',
                    items: attentionItems,
                  ),
                ],
              );
              final recentPanel = _Panel(
                title: 'Recent Activity',
                subtitle: 'Latest records added across modules.',
                empty: 'No recent activity yet.',
                items: recentItems.take(6).toList(),
                emptyVerticalPadding: 40,
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    recentPanel,
                    const SizedBox(height: 24),
                    sidePanels,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: recentPanel),
                  const SizedBox(width: 24),
                  Expanded(child: sidePanels),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cards});

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
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 138,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _Activity {
  const _Activity({
    required this.id,
    required this.title,
    required this.meta,
    required this.pill,
    required this.route,
    required this.color,
    required this.textColor,
  });

  final int id;
  final String title;
  final String meta;
  final String pill;
  final String route;
  final Color color;
  final Color textColor;
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.empty,
    required this.items,
    this.emptyVerticalPadding = 32,
  });

  final String title;
  final String subtitle;
  final String empty;
  final List<_Activity> items;
  final double emptyVerticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d0f172a),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.slate200),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: emptyVerticalPadding),
              child: Text(
                empty,
                style: const TextStyle(color: AppColors.slate400, fontSize: 14),
              ),
            )
          else
            ...items.map(
              (item) => InkWell(
                onTap: () => Navigator.pushNamed(context, item.route),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.slate100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.slate800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(
                        label: item.pill,
                        background: item.color,
                        foreground: item.textColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
