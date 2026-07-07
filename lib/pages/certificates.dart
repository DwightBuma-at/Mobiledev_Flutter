import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/certificate_model.dart';
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

class CertificatesPage extends StatefulWidget {
  const CertificatesPage({super.key});

  @override
  State<CertificatesPage> createState() => _CertificatesPageState();
}

class _CertificatesPageState extends State<CertificatesPage> {
  late List<CertificateModel> _certs;
  String _query = '';

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

  void _save() {
    StorageService.saveCerts(_certs);
    setState(() => _certs = StorageService.certs());
  }

  Future<void> _openForm([CertificateModel? cert]) async {
    final result = await showDialog<CertificateModel>(
      context: context,
      builder: (context) => _CertificateFormDialog(existing: cert),
    );
    if (result == null) return;
    final index = _certs.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      _certs.add(result);
    } else {
      _certs[index] = result;
    }
    _save();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Delete Request',
      message:
          'Are you sure you want to permanently delete this certificate request?',
      confirmText: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    _certs.removeWhere((item) => item.id == id);
    _save();
  }

  Future<void> _updateStatus(CertificateModel item, String status) async {
    if (status == 'Claimed') {
      final confirmed = await showConfirmationModal(
        context,
        title: 'Claim Certificate',
        message:
            'Mark this certificate request as claimed? It will move to certificate logs.',
      );
      if (!confirmed) return;
      final claimedAt = nowIso();
      _replace(item.copyWith(status: 'Claimed', claimedAt: claimedAt));
      StorageService.appendLog(
        LogModel(
          key: 'Certificate-${item.id}',
          id: item.id,
          date: claimedAt,
          module: 'Certificate',
          reference: item.controlNo,
          record: '${item.resident} - ${item.docType}',
          result: 'Claimed',
          details: [
            ['Control Number', item.controlNo],
            ['Resident Name', item.resident],
            ['Document Type', item.docType],
            ['Request Date', item.date],
            ['Purpose', item.purpose],
            ['Submitted By', item.submittedBy],
            ['Date Claimed', claimedAt],
            ['Final Status', 'Claimed'],
          ],
        ),
      );
    } else {
      _replace(item.copyWith(status: status));
    }
    _save();
  }

  void _replace(CertificateModel replacement) {
    final index = _certs.indexWhere((item) => item.id == replacement.id);
    if (index != -1) _certs[index] = replacement;
  }

  void _showLogs() {
    final logs = _certs.where((item) => item.isClaimed).toList()
      ..sort(
        (a, b) => (b.claimedAt.isEmpty ? '${b.id}' : b.claimedAt).compareTo(
          a.claimedAt.isEmpty ? '${a.id}' : a.claimedAt,
        ),
      );
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 920,
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
                            'Certificate Logs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Claimed and released certificate transactions.',
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
                    title: 'Certificate Logs',
                    showHeader: false,
                    framed: false,
                    horizontalMargin: 18,
                    columnSpacing: 18,
                    headingRowHeight: 56,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 72,
                    emptyText: 'No certificate logs yet.',
                    columns: const [
                      'CONTROL NO.',
                      'RESIDENT',
                      'DOCUMENT',
                      'REQUEST DATE',
                      'PURPOSE',
                      'RESULT',
                      'ACTION',
                    ],
                    rows: logs
                        .map(
                          (item) => [
                            Text(item.controlNo),
                            Text(item.resident),
                            Text(item.docType),
                            Text(item.date),
                            Text(item.purpose),
                            const StatusChip(
                              label: 'Claimed',
                              background: AppColors.emerald100,
                              foreground: AppColors.emerald700,
                            ),
                            _PrintRecordButton(
                              onPressed: () => _printCertRecord(item),
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

  void _printCertRecord(CertificateModel item) {
    final result = item.status == 'Released' ? 'Released' : 'Claimed';
    PrintService.printRecord(
      title: 'Certificate Transaction Record',
      module: 'Certificates',
      reference: item.controlNo,
      result: result,
      details: [
        PrintDetail('Control Number', item.controlNo),
        PrintDetail('Resident Name', item.resident),
        PrintDetail('Document Type', item.docType),
        PrintDetail('Request Date', item.date),
        PrintDetail('Purpose', item.purpose),
        PrintDetail('Submitted By', item.submittedBy),
        PrintDetail('Date Claimed', item.claimedAt),
        PrintDetail('Final Status', result),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final active = _certs.where((cert) {
      if (cert.isClaimed) return false;
      if (query.isEmpty) return true;
      return [
        cert.controlNo,
        cert.resident,
        cert.docType,
        cert.date,
        cert.purpose,
        cert.submittedBy,
        cert.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.id.compareTo(a.id));
    return AppShell(
      currentRoute: AppRoutes.adminCertificates,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Certificate Management',
            subtitle: 'Manage and track all barangay document requests.',
            actions: [
              CustomButton(
                label: 'Logs',
                icon: Icons.access_time,
                primary: false,
                onPressed: _showLogs,
              ),
              CustomButton(
                label: 'New Request',
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
                    text: 'Total Requests: ',
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
            title: 'Certificate Requests Masterlist',
            searchPlaceholder: 'Search requests...',
            onSearchChanged: (value) => setState(() => _query = value),
            emptyText:
                'No active certificate requests found. Click "New Request" to start.',
            columns: const [
              'Control No.',
              'Resident Name',
              'Document Type',
              'Request Date',
              'Purpose',
              'Source',
              'Status',
              'Action',
            ],
            rows: active.map((cert) {
              final status = CertificateModel.normalizeStatus(cert.status);
              return [
                Text(
                  cert.controlNo,
                  style: const TextStyle(
                    color: AppColors.slate700,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  cert.resident,
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(cert.docType),
                Text(cert.date, style: const TextStyle(fontSize: 12)),
                SizedBox(
                  width: 180,
                  child: Text(
                    cert.purpose,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                StatusChip(
                  label: cert.submittedBy.isEmpty ? 'Admin' : cert.submittedBy,
                  background: cert.submittedBy == 'Resident Portal'
                      ? AppColors.blue100
                      : AppColors.slate100,
                  foreground: cert.submittedBy == 'Resident Portal'
                      ? AppColors.blue700
                      : AppColors.slate700,
                ),
                StatusDropdown(
                  value: status,
                  items: const [
                    'Pending',
                    'In Progress',
                    'Ready to Claim',
                    'Claimed',
                  ],
                  onChanged: (value) {
                    if (value != null) _updateStatus(cert, value);
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
                      onPressed: () => _openForm(cert),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.red600,
                        size: 18,
                      ),
                      onPressed: () => _delete(cert.id),
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
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .4,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('PRINT RECORD'),
    );
  }
}

class _CertificateFormDialog extends StatefulWidget {
  const _CertificateFormDialog({this.existing});
  final CertificateModel? existing;

  @override
  State<_CertificateFormDialog> createState() => _CertificateFormDialogState();
}

class _CertificateFormDialogState extends State<_CertificateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController resident;
  late final TextEditingController date;
  late final TextEditingController purpose;
  String docType = '';
  String status = 'Pending';

  @override
  void initState() {
    super.initState();
    final cert = widget.existing;
    resident = TextEditingController(text: cert?.resident ?? '');
    date = TextEditingController(text: cert?.date ?? _longToday());
    purpose = TextEditingController(text: cert?.purpose ?? '');
    docType = cert?.docType ?? '';
    status = cert?.status ?? 'Pending';
  }

  @override
  void dispose() {
    resident.dispose();
    date.dispose();
    purpose.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      CertificateModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch,
        controlNo: existing?.controlNo ?? sequence('CERT'),
        resident: resident.text,
        docType: docType,
        date: date.text,
        status: status,
        purpose: purpose.text,
        submittedBy: existing?.submittedBy ?? 'Admin',
        claimedAt: existing?.claimedAt ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: widget.existing == null
          ? 'New Certificate Request'
          : 'Edit Request',
      saveText: widget.existing == null ? 'Save Request' : 'Update Request',
      width: 520,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle('Request Details'),
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
            _grid([
              LabeledTextField(
                label: 'Request Date',
                controller: date,
                readOnly: true,
              ),
              LabeledDropdown(
                label: 'Status',
                value: status,
                requiredField: true,
                items: const [
                  '',
                  'Pending',
                  'In Progress',
                  'Ready to Claim',
                  'Claimed',
                ],
                onChanged: (v) => setState(() => status = v ?? 'Pending'),
              ),
            ]),
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

  Widget _grid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 2;
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

  String _longToday() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
