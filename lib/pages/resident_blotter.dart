import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/blotter_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart';
import '../widgets/form_widgets.dart';
import '../widgets/status_dropdown.dart';

class ResidentBlotterPage extends StatefulWidget {
  const ResidentBlotterPage({super.key});

  @override
  State<ResidentBlotterPage> createState() => _ResidentBlotterPageState();
}

class _ResidentBlotterPageState extends State<ResidentBlotterPage> {
  late List<BlotterModel> _records;

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

  void _save(List<BlotterModel> records) {
    StorageService.saveBlotters(records);
    setState(() => _records = StorageService.blotters());
  }

  Future<void> _openForm() async {
    final result = await showDialog<BlotterModel>(
      context: context,
      builder: (context) => const _ResidentBlotterForm(),
    );
    if (result == null) return;
    _save([..._records, result]);
  }

  @override
  Widget build(BuildContext context) {
    final current = StorageService.currentResident();
    final name = '${current?['name'] ?? 'Resident'}';
    final mine = _records.where((item) => _isMine(item, current, name)).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return AppShell(
      currentRoute: AppRoutes.residentBlotter,
      isResident: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Blotter Reports',
            subtitle: 'Submit and monitor your blotter reports.',
            actions: [
              CustomButton(
                label: 'Submit Report',
                icon: Icons.add,
                onPressed: _openForm,
              ),
            ],
          ),
          CustomTable(
            title: 'My Blotter Reports',
            emptyText: 'No blotter reports submitted yet.',
            columns: const ['Case No.', 'Incident', 'Date', 'Status'],
            rows: mine
                .map(
                  (item) => [
                    Text(
                      item.caseNo,
                      style: const TextStyle(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(item.type),
                    Text(item.date),
                    StatusChip(
                      label: item.status,
                      background: item.isCompleted
                          ? AppColors.emerald100
                          : AppColors.amber100,
                      foreground: item.isCompleted
                          ? AppColors.emerald700
                          : AppColors.amber700,
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  bool _isMine(BlotterModel item, Map<String, dynamic>? current, String name) {
    if (item.submittedBy != 'Resident Portal') return false;
    final residentId = current?['id'];
    if (residentId != null && '${item.residentId}' == '$residentId') {
      return true;
    }
    final residentName = '${current?['name'] ?? name}'.toLowerCase();
    return item.residentName.toLowerCase() == residentName ||
        item.complainant.toLowerCase() == residentName ||
        item.complainant.toLowerCase().contains(residentName);
  }
}

class _ResidentBlotterForm extends StatefulWidget {
  const _ResidentBlotterForm();

  @override
  State<_ResidentBlotterForm> createState() => _ResidentBlotterFormState();
}

class _ResidentBlotterFormState extends State<_ResidentBlotterForm> {
  final _formKey = GlobalKey<FormState>();
  final complainant = TextEditingController();
  final contact = TextEditingController();
  final respondent = TextEditingController();
  final date = TextEditingController(text: todayIso());
  final time = TextEditingController();
  final location = TextEditingController();
  final narrative = TextEditingController();
  String type = '';

  @override
  void initState() {
    super.initState();
    final current = StorageService.currentResident();
    complainant.text = '${current?['name'] ?? ''}';
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
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final current = StorageService.currentResident();
    Navigator.pop(
      context,
      BlotterModel(
        id: DateTime.now().millisecondsSinceEpoch,
        caseNo: sequence('BIMS'),
        complainant: complainant.text,
        contact: contact.text,
        respondent: respondent.text,
        type: type,
        date: date.text,
        time: time.text,
        location: location.text,
        status: 'Pending',
        narrative: narrative.text,
        submittedBy: 'Resident Portal',
        residentId: current?['id'] is int
            ? current!['id'] as int
            : int.tryParse('${current?['id']}'),
        residentName: '${current?['name'] ?? complainant.text}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'Submit Blotter Report',
      saveText: 'Submit Report',
      width: 780,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted reports appear in the admin blotter records for processing.',
              style: TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 20),
            _grid([
              LabeledTextField(
                label: 'Complainant Name',
                controller: complainant,
                requiredField: true,
              ),
              LabeledTextField(
                label: 'Contact',
                controller: contact,
                requiredField: true,
                hint: '09XX XXX XXXX',
              ),
              LabeledTextField(
                label: 'Respondent Name',
                controller: respondent,
                requiredField: true,
              ),
              LabeledDropdown(
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
              LabeledTextField(
                label: 'Incident Date',
                controller: date,
                requiredField: true,
              ),
              LabeledTextField(
                label: 'Incident Time',
                controller: time,
                requiredField: true,
              ),
              LabeledTextField(
                label: 'Location',
                controller: location,
                requiredField: true,
              ),
            ]),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Narrative',
              controller: narrative,
              requiredField: true,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 640 ? 1 : 2;
        final width = (constraints.maxWidth - (24 * (columns - 1))) / columns;
        return Wrap(
          spacing: 24,
          runSpacing: 20,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
