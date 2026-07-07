import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/certificate_model.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_table.dart';
import '../widgets/form_widgets.dart';
import '../widgets/status_dropdown.dart';

class ResidentCertificatesPage extends StatefulWidget {
  const ResidentCertificatesPage({super.key});

  @override
  State<ResidentCertificatesPage> createState() =>
      _ResidentCertificatesPageState();
}

class _ResidentCertificatesPageState extends State<ResidentCertificatesPage> {
  late List<CertificateModel> _certs;

  @override
  void initState() {
    super.initState();
    _certs = StorageService.certs();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    if (mounted) setState(() => _certs = StorageService.certs());
  }

  void _save(List<CertificateModel> certs) {
    StorageService.saveCerts(certs);
    setState(() => _certs = StorageService.certs());
  }

  Future<void> _openForm() async {
    final result = await showDialog<CertificateModel>(
      context: context,
      builder: (context) => const _ResidentCertificateForm(),
    );
    if (result == null) return;
    _save([..._certs, result]);
  }

  @override
  Widget build(BuildContext context) {
    final current = StorageService.currentResident();
    final name = '${current?['name'] ?? 'Resident'}';
    final mine = _certs.where((item) => _isMine(item, current, name)).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

    return AppShell(
      currentRoute: AppRoutes.residentCertificates,
      isResident: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Certificate Requests',
            subtitle: 'Submit and monitor barangay document requests.',
            actions: [
              CustomButton(
                label: 'New Request',
                icon: Icons.add,
                onPressed: _openForm,
              ),
            ],
          ),
          CustomTable(
            title: 'My Certificate Requests',
            emptyText: 'No certificate requests submitted yet.',
            columns: const ['Control No.', 'Document', 'Date', 'Status'],
            rows: mine
                .map(
                  (item) => [
                    Text(
                      item.controlNo,
                      style: const TextStyle(
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(item.docType),
                    Text(item.date),
                    StatusChip(
                      label: item.status,
                      background: item.isClaimed
                          ? AppColors.emerald100
                          : AppColors.blue100,
                      foreground: item.isClaimed
                          ? AppColors.emerald700
                          : AppColors.blue700,
                    ),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  bool _isMine(
    CertificateModel item,
    Map<String, dynamic>? current,
    String name,
  ) {
    if (item.submittedBy != 'Resident Portal') return false;
    final residentId = current?['id'];
    if (residentId != null && '${item.residentId}' == '$residentId') {
      return true;
    }
    final residentName = '${current?['name'] ?? name}'.toLowerCase();
    return item.residentName.toLowerCase() == residentName ||
        item.resident.toLowerCase() == residentName ||
        item.resident.toLowerCase().contains(residentName);
  }
}

class _ResidentCertificateForm extends StatefulWidget {
  const _ResidentCertificateForm();

  @override
  State<_ResidentCertificateForm> createState() =>
      _ResidentCertificateFormState();
}

class _ResidentCertificateFormState extends State<_ResidentCertificateForm> {
  final _formKey = GlobalKey<FormState>();
  final resident = TextEditingController();
  final purpose = TextEditingController();
  String docType = '';

  @override
  void initState() {
    super.initState();
    final current = StorageService.currentResident();
    resident.text = '${current?['name'] ?? ''}';
  }

  @override
  void dispose() {
    resident.dispose();
    purpose.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final current = StorageService.currentResident();
    Navigator.pop(
      context,
      CertificateModel(
        id: DateTime.now().millisecondsSinceEpoch,
        controlNo: sequence('CERT'),
        resident: resident.text,
        docType: docType,
        date: todayIso(),
        purpose: purpose.text,
        status: 'Pending',
        submittedBy: 'Resident Portal',
        residentId: current?['id'] is int
            ? current!['id'] as int
            : int.tryParse('${current?['id']}'),
        residentName: '${current?['name'] ?? resident.text}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: 'New Certificate Request',
      saveText: 'Submit Request',
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted requests appear in the admin certificates module for processing.',
              style: TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Resident Name',
              controller: resident,
              requiredField: true,
            ),
            const SizedBox(height: 20),
            LabeledDropdown(
              label: 'Document Type',
              value: docType,
              requiredField: true,
              items: const [
                '',
                'Barangay Clearance',
                'Certificate of Residency',
                'Certificate of Indigency',
                'Business Clearance',
                'Certificate of Good Moral',
                'First Time Jobseeker',
                'Solo Parent',
                'Other',
              ],
              onChanged: (v) => setState(() => docType = v ?? ''),
            ),
            const SizedBox(height: 20),
            LabeledTextField(
              label: 'Purpose',
              controller: purpose,
              requiredField: true,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}
