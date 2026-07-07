import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/blotter_model.dart';
import '../models/certificate_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/custom_table.dart';
import '../widgets/status_dropdown.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String _activeFilter = 'all';

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
    final current = StorageService.currentResident();
    final name = '${current?['name'] ?? 'Resident'}';
    final residentId = current?['id'];
    final blotters = StorageService.blotters()
        .where(
          (item) =>
              item.isCompleted &&
              _isResidentRecord(
                source: item.submittedBy,
                recordResidentId: item.residentId,
                recordResidentName: item.residentName,
                visibleName: item.complainant,
                residentId: residentId,
                residentName: name,
              ),
        )
        .toList();
    final certs = StorageService.certs()
        .where(
          (item) =>
              item.isClaimed &&
              _isResidentRecord(
                source: item.submittedBy,
                recordResidentId: item.residentId,
                recordResidentName: item.residentName,
                visibleName: item.resident,
                residentId: residentId,
                residentName: name,
              ),
        )
        .toList();

    final allRows = <_LogRow>[
      ...blotters.map((b) => _LogRow.blotter(b)),
      ...certs.map((c) => _LogRow.cert(c)),
    ]..sort((a, b) => b.id.compareTo(a.id));
    final rows = _activeFilter == 'all'
        ? allRows
        : allRows.where((row) => row.module == _activeFilter).toList();

    return AppShell(
      currentRoute: AppRoutes.residentLogs,
      isResident: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Completed Transactions',
            subtitle:
                'View your completed blotter reports and claimed certificate requests.',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final stats = [
                _MiniStat(
                  label: 'Completed Blotters',
                  value: '${blotters.length}',
                  icon: Icons.warning_amber,
                  color: AppColors.red600,
                ),
                _MiniStat(
                  label: 'Claimed Certificates',
                  value: '${certs.length}',
                  icon: Icons.description_outlined,
                  color: AppColors.emerald600,
                ),
              ];
              if (constraints.maxWidth < 640) {
                return Column(
                  children: [stats[0], const SizedBox(height: 16), stats[1]],
                );
              }
              return Row(
                children: [
                  Expanded(child: stats[0]),
                  const SizedBox(width: 20),
                  Expanded(child: stats[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterButton(
                label: 'All',
                active: _activeFilter == 'all',
                onPressed: () => setState(() => _activeFilter = 'all'),
              ),
              _FilterButton(
                label: 'Blotter',
                active: _activeFilter == 'Blotter',
                onPressed: () => setState(() => _activeFilter = 'Blotter'),
              ),
              _FilterButton(
                label: 'Certificate',
                active: _activeFilter == 'Certificate',
                onPressed: () => setState(() => _activeFilter = 'Certificate'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTable(
            title: 'Transaction Logs',
            emptyText: 'No completed transactions yet.',
            columns: const ['Date', 'Module', 'Reference', 'Record', 'Result'],
            rows: rows
                .map(
                  (row) => [
                    Text(row.date),
                    Text(row.module),
                    Text(
                      row.reference,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(row.record),
                    StatusChip(
                      label: row.result,
                      background: AppColors.emerald100,
                      foreground: AppColors.emerald700,
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  bool _isResidentRecord({
    required String source,
    required int? recordResidentId,
    required String recordResidentName,
    required String visibleName,
    required Object? residentId,
    required String residentName,
  }) {
    if (source != 'Resident Portal') return false;
    final normalizedResidentName = residentName.toLowerCase();
    return (residentId != null && '$recordResidentId' == '$residentId') ||
        recordResidentName.toLowerCase() == normalizedResidentName ||
        visibleName.toLowerCase() == normalizedResidentName ||
        visibleName.toLowerCase().contains(normalizedResidentName);
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: active ? AppColors.blue600 : Colors.white,
        foregroundColor: active ? Colors.white : AppColors.slate600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: active ? AppColors.blue600 : AppColors.slate200,
          ),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.slate200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
              Text(label, style: const TextStyle(color: AppColors.slate500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogRow {
  _LogRow({
    required this.id,
    required this.date,
    required this.module,
    required this.reference,
    required this.record,
    required this.result,
  });

  final int id;
  final String date;
  final String module;
  final String reference;
  final String record;
  final String result;

  factory _LogRow.blotter(BlotterModel b) => _LogRow(
    id: b.id,
    date: b.completedAt.isEmpty ? b.date : b.completedAt,
    module: 'Blotter',
    reference: b.caseNo,
    record: '${b.complainant} vs. ${b.respondent}',
    result: 'Completed',
  );

  factory _LogRow.cert(CertificateModel c) => _LogRow(
    id: c.id,
    date: c.claimedAt.isEmpty ? c.date : c.claimedAt,
    module: 'Certificate',
    reference: c.controlNo,
    record: '${c.resident} - ${c.docType}',
    result: 'Claimed',
  );
}
