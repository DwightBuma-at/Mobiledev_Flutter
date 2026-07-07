import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/blotter_model.dart';
import '../models/log_model.dart';
import '../routes/app_routes.dart';
import '../services/print_service.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/confirmation_modal.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart';
import '../widgets/form_widgets.dart';
import '../widgets/status_dropdown.dart';

class BlotterPage extends StatefulWidget {
  const BlotterPage({super.key});

  @override
  State<BlotterPage> createState() => _BlotterPageState();
}

class _BlotterPageState extends State<BlotterPage> {
  late List<BlotterModel> _records;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _records = StorageService.blotters();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    if (mounted) setState(() => _records = StorageService.blotters());
  }

  void _save() {
    StorageService.saveBlotters(_records);
    setState(() => _records = StorageService.blotters());
  }

  Future<void> _openForm([BlotterModel? record]) async {
    final result = await showDialog<BlotterModel>(
      context: context,
      builder: (context) => _BlotterFormDialog(existing: record),
    );
    if (result == null) return;
    final index = _records.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      _records.add(result);
    } else {
      _records[index] = result;
    }
    _save();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Delete Record',
      message:
          'Are you sure you want to permanently delete this blotter record? This action cannot be undone.',
      confirmText: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    _records.removeWhere((item) => item.id == id);
    _save();
  }

  Future<void> _updateStatus(BlotterModel item, String status) async {
    if (status == 'Completed') {
      final confirmed = await showConfirmationModal(
        context,
        title: 'Complete Blotter Record',
        message:
            'Mark this blotter record as completed? It will be removed from active blotter records.',
      );
      if (!confirmed) return;
      final completedAt = nowIso();
      _replace(item.copyWith(status: 'Completed', completedAt: completedAt));
      StorageService.appendLog(
        LogModel(
          key: 'Blotter-${item.id}',
          id: item.id,
          date: completedAt,
          module: 'Blotter',
          reference: item.caseNo,
          record: '${item.complainant} vs. ${item.respondent}',
          result: 'Completed',
          details: [
            ['Case Number', item.caseNo],
            ['Complainant', item.complainant],
            ['Contact Number', item.contact],
            ['Respondent', item.respondent],
            ['Incident Type', item.type],
            ['Incident Date', item.date],
            ['Incident Time', item.time],
            ['Location', item.location],
            ['Narrative', item.narrative],
            ['Action Taken', item.actionTaken],
            ['Submitted By', item.submittedBy],
            ['Date Completed', completedAt],
            ['Final Status', 'Completed'],
          ],
        ),
      );
    } else {
      _replace(item.copyWith(status: status));
    }
    _save();
  }

  void _replace(BlotterModel replacement) {
    final index = _records.indexWhere((item) => item.id == replacement.id);
    if (index != -1) _records[index] = replacement;
  }

  void _showLogs() {
    final logs = _records.where((item) => item.isCompleted).toList()
      ..sort(
        (a, b) => (b.completedAt.isEmpty ? '${b.id}' : b.completedAt).compareTo(
          a.completedAt.isEmpty ? '${a.id}' : a.completedAt,
        ),
      );
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 980,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blotter Logs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Completed, resolved, and dismissed blotter transactions.',
                            style: TextStyle(color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.slate400),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  child: CustomTable(
                    title: 'Blotter Logs',
                    showHeader: false,
                    framed: false,
                    horizontalMargin: 14,
                    columnSpacing: 16,
                    headingRowHeight: 56,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 64,
                    emptyText: 'No blotter logs yet.',
                    columns: const [
                      'CASE NO.',
                      'COMPLAINANT',
                      'RESPONDENT',
                      'INCIDENT',
                      'DATE',
                      'RESULT',
                      'ACTION',
                    ],
                    rows: logs
                        .map(
                          (item) => [
                            Text(item.caseNo),
                            Text(item.complainant),
                            Text(item.respondent),
                            Text(item.type),
                            Text(
                              item.completedAt.isEmpty
                                  ? item.date
                                  : item.completedAt,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const StatusChip(
                              label: 'Completed',
                              background: AppColors.emerald100,
                              foreground: AppColors.emerald700,
                            ),
                            _PrintRecordButton(
                              onPressed: () => _printBlotterRecord(item),
                            ),
                          ],
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _printBlotterRecord(BlotterModel item) {
    final result = item.status == 'Resolved' || item.status == 'Dismissed'
        ? item.status
        : 'Completed';
    PrintService.printRecord(
      title: 'Blotter Transaction Record',
      module: 'Blotter Records',
      reference: item.caseNo,
      result: result,
      details: [
        PrintDetail('Case Number', item.caseNo),
        PrintDetail('Complainant', item.complainant),
        PrintDetail('Contact Number', item.contact),
        PrintDetail('Respondent', item.respondent),
        PrintDetail('Incident Type', item.type),
        PrintDetail('Incident Date', item.date),
        PrintDetail('Incident Time', item.time),
        PrintDetail('Location', item.location),
        PrintDetail('Narrative', item.narrative),
        PrintDetail('Action Taken', item.actionTaken),
        PrintDetail('Submitted By', item.submittedBy),
        PrintDetail('Date Completed', item.completedAt),
        PrintDetail('Final Status', result),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final active = _records.where((item) {
      if (item.isCompleted) return false;
      if (query.isEmpty) return true;
      return [
        item.caseNo,
        item.complainant,
        item.respondent,
        item.type,
        item.date,
        item.time,
        item.submittedBy,
        item.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
    return AppShell(
      currentRoute: AppRoutes.adminBlotter,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Blotter Records',
            subtitle: 'Manage and track all barangay incident reports.',
            actions: [
              CustomButton(
                label: 'Logs',
                icon: Icons.access_time,
                primary: false,
                onPressed: _showLogs,
              ),
              CustomButton(
                label: 'Add Blotter',
                icon: Icons.add,
                onPressed: () => _openForm(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.blue700,
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: 'Total Blotter Records: ',
                    style: const TextStyle(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '${active.length}',
                        style: const TextStyle(
                          color: AppColors.blue600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CustomTable(
            title: 'Incident Reports Masterlist',
            searchPlaceholder: 'Search records...',
            onSearchChanged: (value) => setState(() => _query = value),
            emptyText:
                'No active blotter records found. Click "Add Blotter" to start.',
            columns: const [
              'Case No.',
              'Complainant',
              'Respondent',
              'Incident Type',
              'Date & Time',
              'Source',
              'Status',
              'Action',
            ],
            rows: active.map((item) {
              final status = BlotterModel.normalizeStatus(item.status);
              return [
                Text(
                  item.caseNo,
                  style: const TextStyle(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.complainant,
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(item.respondent),
                Text(item.type),
                Text(
                  '${item.date}\n${item.time}',
                  style: const TextStyle(fontSize: 12),
                ),
                StatusChip(
                  label: item.submittedBy.isEmpty ? 'Admin' : item.submittedBy,
                  background: item.submittedBy == 'Resident Portal'
                      ? AppColors.blue100
                      : AppColors.slate100,
                  foreground: item.submittedBy == 'Resident Portal'
                      ? AppColors.blue700
                      : AppColors.slate700,
                ),
                StatusDropdown(
                  value: status,
                  items: const ['Pending', 'In-progress', 'Completed'],
                  onChanged: (value) {
                    if (value != null) _updateStatus(item, value);
                  },
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View/Edit',
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.blue600,
                        size: 18,
                      ),
                      onPressed: () => _openForm(item),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.red600,
                        size: 18,
                      ),
                      onPressed: () => _delete(item.id),
                    ),
                  ],
                ),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PrintRecordButton extends StatelessWidget {
  const _PrintRecordButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.slate800,
        foregroundColor: Colors.white,
        minimumSize: const Size(74, 30),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('PRINT RECORD'),
    );
  }
}

class _BlotterFormDialog extends StatefulWidget {
  const _BlotterFormDialog({this.existing});
  final BlotterModel? existing;

  @override
  State<_BlotterFormDialog> createState() => _BlotterFormDialogState();
}

class _BlotterFormDialogState extends State<_BlotterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController complainant;
  late final TextEditingController contact;
  late final TextEditingController respondent;
  late final TextEditingController date;
  late final TextEditingController time;
  late final TextEditingController location;
  late final TextEditingController narrative;
  late final TextEditingController actionTaken;
  String type = '';
  String status = 'Pending';

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    complainant = TextEditingController(text: item?.complainant ?? '');
    contact = TextEditingController(text: item?.contact ?? '');
    respondent = TextEditingController(text: item?.respondent ?? '');
    date = TextEditingController(text: item?.date ?? todayIso());
    time = TextEditingController(text: item?.time ?? '');
    location = TextEditingController(text: item?.location ?? '');
    narrative = TextEditingController(text: item?.narrative ?? '');
    actionTaken = TextEditingController(text: item?.actionTaken ?? '');
    type = item?.type ?? '';
    status = item?.status ?? 'Pending';
  }

  @override
  void dispose() {
    for (final c in [
      complainant,
      contact,
      respondent,
      date,
      time,
      location,
      narrative,
      actionTaken,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      BlotterModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch,
        caseNo: existing?.caseNo ?? sequence('BIMS'),
        complainant: complainant.text,
        contact: contact.text,
        respondent: respondent.text,
        type: type,
        date: date.text,
        time: time.text,
        location: location.text,
        status: status,
        narrative: narrative.text,
        actionTaken: actionTaken.text,
        submittedBy: existing?.submittedBy ?? 'Admin',
        completedAt: existing?.completedAt ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: widget.existing == null
          ? 'Add New Blotter'
          : 'Edit Blotter Details',
      saveText: widget.existing == null ? 'Save Blotter' : 'Update Blotter',
      width: 806,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle('Parties Involved'),
            _partiesGrid(),
            const SizedBox(height: 24),
            const FormSectionTitle('Incident Details'),
            _incidentGrid(),
            const SizedBox(height: 24),
            const FormSectionTitle('Narrative & Action'),
            LabeledTextField(
              label: 'Narrative (Detailed Report)',
              controller: narrative,
              requiredField: true,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Action Taken',
              controller: actionTaken,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _partiesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640 ? 1 : 2;
        final width = (constraints.maxWidth - (20 * (columns - 1))) / columns;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: width,
              child: LabeledTextField(
                label: 'Complainant Name',
                controller: complainant,
                requiredField: true,
              ),
            ),
            SizedBox(
              width: width,
              child: LabeledTextField(
                label: 'Complainant Contact',
                controller: contact,
                requiredField: true,
                hint: '09XX XXX XXXX',
              ),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: LabeledTextField(
                label: 'Respondent Name',
                controller: respondent,
                requiredField: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _incidentGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640 ? 1 : 3;
        final third = (constraints.maxWidth - (20 * (columns - 1))) / columns;
        final half = constraints.maxWidth < 640
            ? constraints.maxWidth
            : (constraints.maxWidth - 20) / 2;
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            SizedBox(
              width: third,
              child: LabeledDropdown(
                label: 'Incident Type',
                value: type,
                requiredField: true,
                items: const [
                  '',
                  'Theft',
                  'Physical Injury',
                  'Harassment',
                  'Disturbing the Peace',
                  'Domestic Violence',
                  'Property Damage',
                  'Other',
                ],
                onChanged: (v) => setState(() => type = v ?? ''),
              ),
            ),
            SizedBox(
              width: third,
              child: LabeledTextField(
                label: 'Incident Date',
                controller: date,
                requiredField: true,
                hint: 'YYYY-MM-DD',
                suffixIcon: Icons.calendar_month_outlined,
              ),
            ),
            SizedBox(
              width: third,
              child: LabeledTextField(
                label: 'Incident Time',
                controller: time,
                requiredField: true,
                hint: 'HH:MM',
                suffixIcon: Icons.access_time,
              ),
            ),
            SizedBox(
              width: half,
              child: LabeledTextField(
                label: 'Location',
                controller: location,
                requiredField: true,
              ),
            ),
            SizedBox(
              width: half,
              child: LabeledDropdown(
                label: 'Status',
                value: status,
                requiredField: true,
                items: const ['', 'Pending', 'In-progress', 'Completed'],
                onChanged: (v) => setState(() => status = v ?? 'Pending'),
              ),
            ),
          ],
        );
      },
    );
  }
}
