import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/official_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/confirmation_modal.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart';
import '../widgets/form_widgets.dart';
import '../widgets/status_dropdown.dart';

class OfficialsPage extends StatefulWidget {
  const OfficialsPage({super.key});

  @override
  State<OfficialsPage> createState() => _OfficialsPageState();
}

class _OfficialsPageState extends State<OfficialsPage> {
  late List<OfficialModel> _officials;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _officials = StorageService.officials();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    if (mounted) setState(() => _officials = StorageService.officials());
  }

  void _save() {
    StorageService.saveOfficials(_officials);
    setState(() => _officials = StorageService.officials());
  }

  Future<void> _openForm([OfficialModel? official]) async {
    final result = await showDialog<OfficialModel>(
      context: context,
      builder: (context) => _OfficialFormDialog(existing: official),
    );
    if (result == null) return;
    final index = _officials.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      _officials.add(result);
    } else {
      _officials[index] = result;
    }
    _save();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Remove Official',
      message: 'Are you sure you want to remove this official record?',
      confirmText: 'Remove',
      danger: true,
    );
    if (!confirmed) return;
    _officials.removeWhere((item) => item.id == id);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final sorted = _officials.where((official) {
      if (query.isEmpty) return true;
      return [
        official.name,
        official.position,
        official.committee,
        official.contact,
        official.email,
        official.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
    return AppShell(
      currentRoute: AppRoutes.adminOfficials,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Officials Management',
            subtitle:
                'Manage and track all barangay elected and appointed officials.',
            actions: [
              CustomButton(
                label: 'Add Official',
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
                    Icons.groups_outlined,
                    color: AppColors.blue700,
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: 'Total Officials: ',
                    style: const TextStyle(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '${_officials.length}',
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
            title: 'Officials Masterlist',
            searchPlaceholder: 'Search officials...',
            onSearchChanged: (value) => setState(() => _query = value),
            emptyText: 'No officials found. Click "Add Official" to start.',
            columns: const [
              'Full Name',
              'Position',
              'Committee',
              'Contact',
              'Term',
              'Status',
              'Action',
            ],
            rows: sorted.map((off) {
              return [
                Text(
                  off.name,
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(off.position),
                Text(off.committee),
                Text(off.contact),
                Text(
                  '${off.termStart}\n${off.termEnd}',
                  style: const TextStyle(fontSize: 12),
                ),
                StatusChip(
                  label: off.status,
                  background: off.status == 'Active'
                      ? AppColors.emerald100
                      : AppColors.slate100,
                  foreground: off.status == 'Active'
                      ? AppColors.emerald700
                      : AppColors.slate700,
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
                      onPressed: () => _openForm(off),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.red600,
                        size: 18,
                      ),
                      onPressed: () => _delete(off.id),
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

class _OfficialFormDialog extends StatefulWidget {
  const _OfficialFormDialog({this.existing});
  final OfficialModel? existing;

  @override
  State<_OfficialFormDialog> createState() => _OfficialFormDialogState();
}

class _OfficialFormDialogState extends State<_OfficialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController contact;
  late final TextEditingController email;
  late final TextEditingController termStart;
  late final TextEditingController termEnd;
  String position = '';
  String committee = '';
  String status = 'Active';

  @override
  void initState() {
    super.initState();
    final o = widget.existing;
    name = TextEditingController(text: o?.name ?? '');
    contact = TextEditingController(text: o?.contact ?? '');
    email = TextEditingController(text: o?.email ?? '');
    termStart = TextEditingController(text: o?.termStart ?? '');
    termEnd = TextEditingController(text: o?.termEnd ?? '');
    position = o?.position ?? '';
    committee = o?.committee ?? '';
    status = o?.status ?? 'Active';
  }

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    email.dispose();
    termStart.dispose();
    termEnd.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      OfficialModel(
        id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: name.text,
        position: position,
        committee: committee,
        contact: contact.text,
        email: email.text,
        termStart: termStart.text,
        termEnd: termEnd.text,
        status: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: widget.existing == null ? 'Add Official' : 'Edit Official',
      saveText: widget.existing == null ? 'Save Official' : 'Update Official',
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle('Official Information'),
            _grid([
              LabeledTextField(
                label: 'Name',
                controller: name,
                requiredField: true,
              ),
              LabeledDropdown(
                label: 'Position',
                value: position,
                requiredField: true,
                items: const [
                  '',
                  'Barangay Captain',
                  'Barangay Kagawad',
                  'SK Chairman',
                  'Secretary',
                  'Treasurer',
                  'Tanod',
                ],
                onChanged: (v) => setState(() => position = v ?? ''),
              ),
              LabeledDropdown(
                label: 'Committee',
                value: committee,
                requiredField: true,
                items: const [
                  '',
                  'Peace and Order',
                  'Health',
                  'Education',
                  'Environment',
                  'Infrastructure',
                  'Youth and Sports',
                  'Finance',
                  'General Services',
                ],
                onChanged: (v) => setState(() => committee = v ?? ''),
              ),
              LabeledTextField(
                label: 'Contact',
                controller: contact,
                requiredField: true,
                hint: '09XXXXXXXXX',
              ),
              LabeledTextField(label: 'Email', controller: email),
              LabeledTextField(
                label: 'Term Start',
                controller: termStart,
                requiredField: true,
                hint: 'YYYY-MM-DD',
              ),
              LabeledTextField(
                label: 'Term End',
                controller: termEnd,
                requiredField: true,
                hint: 'YYYY-MM-DD',
              ),
              LabeledDropdown(
                label: 'Status',
                value: status,
                requiredField: true,
                items: const ['', 'Active', 'Inactive'],
                onChanged: (v) => setState(() => status = v ?? 'Active'),
              ),
            ]),
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
