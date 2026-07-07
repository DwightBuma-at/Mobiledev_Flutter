import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/resident_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/confirmation_modal.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart';
import '../widgets/form_widgets.dart';
import '../widgets/status_dropdown.dart';

class ResidentsPage extends StatefulWidget {
  const ResidentsPage({super.key});

  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  late List<ResidentModel> _residents;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _load() {
    _residents = StorageService.residents();
  }

  void _handleStorageChanged() {
    if (mounted) setState(_load);
  }

  void _save() {
    StorageService.saveResidents(_residents);
    setState(_load);
  }

  Future<void> _openForm([ResidentModel? resident]) async {
    final result = await showDialog<ResidentModel>(
      context: context,
      builder: (context) =>
          _ResidentFormDialog(existing: resident, residents: _residents),
    );
    if (result == null) return;
    final index = _residents.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      _residents.add(result);
    } else {
      _residents[index] = result;
    }
    _save();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Delete Resident',
      message:
          'Are you sure you want to permanently delete this resident record?',
      confirmText: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    _residents.removeWhere((item) => item.id == id);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final sorted = _residents.where((resident) {
      if (query.isEmpty) return true;
      return [
        resident.fullName,
        resident.gender,
        resident.civilStatus,
        resident.classification,
        resident.voterStatus,
        resident.username,
        resident.purok,
      ].join(' ').toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
    return AppShell(
      currentRoute: AppRoutes.adminResidents,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Resident Management',
            subtitle: 'Manage and track all barangay residents.',
            actions: [
              CustomButton(
                label: 'Add Resident',
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
                    Icons.people_outline,
                    color: AppColors.blue700,
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: 'Total Residents: ',
                    style: const TextStyle(
                      color: AppColors.slate800,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(
                        text: '${_residents.length}',
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
            title: 'Residents Masterlist',
            searchPlaceholder: 'Search residents...',
            onSearchChanged: (value) => setState(() => _query = value),
            emptyText: 'No residents found. Click "Add Resident" to start.',
            columns: const [
              'Full Name',
              'Gender',
              'Civil Status',
              'Classification',
              'Voter Status',
              'Username',
              'Action',
            ],
            rows: sorted.map((res) {
              return [
                Text(
                  res.fullName.isEmpty ? '-' : res.fullName,
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(res.gender.isEmpty ? '-' : res.gender),
                StatusChip(
                  label: res.civilStatus.isEmpty ? '-' : res.civilStatus,
                  background: AppColors.slate100,
                  foreground: AppColors.slate700,
                ),
                StatusChip(
                  label: res.classification.isEmpty ? '-' : res.classification,
                  background: AppColors.amber100,
                  foreground: AppColors.amber700,
                ),
                StatusChip(
                  label: res.voterStatus.isEmpty ? '-' : res.voterStatus,
                  background: res.voterStatus == 'Registered'
                      ? AppColors.emerald100
                      : AppColors.slate100,
                  foreground: res.voterStatus == 'Registered'
                      ? AppColors.emerald700
                      : AppColors.slate700,
                ),
                Text(
                  res.username.isEmpty ? '-' : res.username,
                  style: const TextStyle(fontFamily: 'monospace'),
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
                      onPressed: () => _openForm(res),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.red600,
                        size: 18,
                      ),
                      onPressed: () => _delete(res.id),
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

class _ResidentFormDialog extends StatefulWidget {
  const _ResidentFormDialog({required this.residents, this.existing});

  final ResidentModel? existing;
  final List<ResidentModel> residents;

  @override
  State<_ResidentFormDialog> createState() => _ResidentFormDialogState();
}

class _ResidentFormDialogState extends State<_ResidentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController lastName;
  late final TextEditingController firstName;
  late final TextEditingController middleName;
  late final TextEditingController suffix;
  late final TextEditingController birthDate;
  late final TextEditingController contact;
  late final TextEditingController email;
  late final TextEditingController address;
  late final TextEditingController username;
  late final TextEditingController password;
  String gender = '';
  String civilStatus = '';
  String purok = '';
  String classification = '';
  String voterStatus = '';
  String residentStatus = 'Active';

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    lastName = TextEditingController(text: r?.lastName ?? '');
    firstName = TextEditingController(text: r?.firstName ?? '');
    middleName = TextEditingController(text: r?.middleName ?? '');
    suffix = TextEditingController(text: r?.suffix ?? '');
    birthDate = TextEditingController(text: r?.birthDate ?? '');
    contact = TextEditingController(text: r?.contact ?? '');
    email = TextEditingController(text: r?.email ?? '');
    address = TextEditingController(text: r?.address ?? '');
    username = TextEditingController(text: r?.username ?? '');
    password = TextEditingController(text: r?.password ?? '');
    gender = r?.gender ?? '';
    civilStatus = r?.civilStatus ?? '';
    purok = r?.purok ?? '';
    classification = r?.classification ?? '';
    voterStatus = r?.voterStatus ?? '';
    residentStatus = r?.residentStatus ?? 'Active';
  }

  @override
  void dispose() {
    for (final controller in [
      lastName,
      firstName,
      middleName,
      suffix,
      birthDate,
      contact,
      email,
      address,
      username,
      password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final duplicate = widget.residents.any(
      (resident) =>
          resident.username == username.text.trim() &&
          resident.id != widget.existing?.id,
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This resident username is already in use.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ResidentModel(
        id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch,
        lastName: lastName.text,
        firstName: firstName.text,
        middleName: middleName.text,
        suffix: suffix.text,
        gender: gender,
        birthDate: birthDate.text,
        civilStatus: civilStatus,
        contact: contact.text,
        email: email.text,
        address: address.text,
        purok: purok,
        classification: classification,
        voterStatus: voterStatus,
        residentStatus: residentStatus,
        username: username.text.trim(),
        password: password.text,
        registeredAt: widget.existing?.registeredAt ?? nowIso(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: widget.existing == null ? 'Add New Resident' : 'Edit Resident',
      width: 900,
      saveText: widget.existing == null ? 'Save Resident' : 'Update Resident',
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle('Personal Information'),
            _grid([
              LabeledTextField(
                label: 'Last Name',
                controller: lastName,
                requiredField: true,
              ),
              LabeledTextField(
                label: 'First Name',
                controller: firstName,
                requiredField: true,
              ),
              LabeledTextField(label: 'Middle Name', controller: middleName),
              LabeledTextField(label: 'Suffix', controller: suffix),
              LabeledDropdown(
                label: 'Gender',
                value: gender,
                requiredField: true,
                items: const ['', 'Male', 'Female'],
                onChanged: (v) => setState(() => gender = v ?? ''),
              ),
              LabeledTextField(
                label: 'Birth Date',
                controller: birthDate,
                requiredField: true,
                hint: 'YYYY-MM-DD',
                helperText: 'Format: YYYY-MM-DD',
                suffixIcon: Icons.calendar_month_outlined,
              ),
              LabeledDropdown(
                label: 'Civil Status',
                value: civilStatus,
                requiredField: true,
                items: const [
                  '',
                  'Single',
                  'Married',
                  'Widowed',
                  'Separated',
                  'Divorced',
                ],
                onChanged: (v) => setState(() => civilStatus = v ?? ''),
              ),
            ]),
            const SizedBox(height: 24),
            const FormSectionTitle('Contact & Address'),
            _grid([
              LabeledTextField(
                label: 'Contact Number',
                controller: contact,
                requiredField: true,
                hint: '09XX XXX XXXX',
              ),
              LabeledTextField(label: 'Email', controller: email),
              LabeledTextField(
                label: 'Address',
                controller: address,
                requiredField: true,
              ),
              LabeledDropdown(
                label: 'Purok',
                value: purok,
                requiredField: true,
                items: const [
                  '',
                  'Purok 1',
                  'Purok 2',
                  'Purok 3',
                  'Purok 4',
                  'Purok 5',
                  'Purok 6',
                  'Purok 7',
                ],
                onChanged: (v) => setState(() => purok = v ?? ''),
              ),
            ]),
            const SizedBox(height: 24),
            const FormSectionTitle('Classification & Account'),
            _grid([
              LabeledDropdown(
                label: 'Classification',
                value: classification,
                requiredField: true,
                items: const [
                  '',
                  'Resident',
                  'Senior Citizen',
                  'PWD',
                  'Solo Parent',
                  'Indigent',
                  'Student',
                ],
                onChanged: (v) => setState(() => classification = v ?? ''),
              ),
              LabeledDropdown(
                label: 'Voter Status',
                value: voterStatus,
                requiredField: true,
                items: const ['', 'Registered', 'Not Registered'],
                onChanged: (v) => setState(() => voterStatus = v ?? ''),
              ),
              LabeledTextField(
                label: 'Username',
                controller: username,
                requiredField: true,
              ),
              LabeledTextField(
                label: 'Password',
                controller: password,
                requiredField: true,
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
