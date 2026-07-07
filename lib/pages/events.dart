import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/event_model.dart';
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

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late List<EventModel> _events;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _events = StorageService.events();
    StorageService.revision.addListener(_handleStorageChanged);
  }

  @override
  void dispose() {
    StorageService.revision.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    if (mounted) setState(() => _events = StorageService.events());
  }

  void _save() {
    StorageService.saveEvents(_events);
    setState(() => _events = StorageService.events());
  }

  Future<void> _openForm([EventModel? event]) async {
    final result = await showDialog<EventModel>(
      context: context,
      builder: (context) => _EventFormDialog(existing: event),
    );
    if (result == null) return;
    final index = _events.indexWhere((item) => item.id == result.id);
    if (index == -1) {
      _events.add(result);
    } else {
      _events[index] = result;
    }
    _save();
  }

  Future<void> _delete(int id) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to permanently delete this event?',
      confirmText: 'Delete',
      danger: true,
    );
    if (!confirmed) return;
    _events.removeWhere((item) => item.id == id);
    _save();
  }

  Future<void> _complete(EventModel item) async {
    final confirmed = await showConfirmationModal(
      context,
      title: 'Complete Event',
      message: 'Mark this event as completed? It will move to event logs.',
    );
    if (!confirmed) return;
    final completedAt = nowIso();
    final replacement = item.copyWith(
      status: 'Completed',
      completedAt: completedAt,
    );
    final index = _events.indexWhere((e) => e.id == item.id);
    if (index != -1) _events[index] = replacement;
    _save();
    StorageService.appendLog(
      LogModel(
        key: 'Event-${item.id}',
        id: item.id,
        date: completedAt,
        module: 'Event',
        reference: 'EVT-${'${item.id}'.substring('${item.id}'.length - 4)}',
        record: item.title,
        result: 'Completed',
        details: [
          ['Event Title', item.title],
          ['Event Type', item.type],
          ['Organizer', item.organizer],
          ['Event Date', item.date],
          ['Event Time', item.time],
          ['Venue', item.venue],
          ['Date and Time Posted', item.postedAt],
          ['Date Completed', completedAt],
          ['Description', item.description],
          ['Final Status', 'Completed'],
        ],
      ),
    );
  }

  void _showLogs() {
    final logs = _events.where((item) => item.isCompleted).toList()
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
                            'Event Logs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Completed barangay event transactions.',
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
                    title: 'Event Logs',
                    showHeader: false,
                    framed: false,
                    horizontalMargin: 18,
                    columnSpacing: 20,
                    headingRowHeight: 56,
                    dataRowMinHeight: 58,
                    dataRowMaxHeight: 64,
                    emptyText: 'No event logs yet.',
                    columns: const [
                      'REFERENCE',
                      'EVENT',
                      'TYPE',
                      'SCHEDULE',
                      'VENUE',
                      'RESULT',
                      'ACTION',
                    ],
                    rows: logs
                        .map(
                          (item) => [
                            Text(
                              'EVT-${'${item.id}'.substring('${item.id}'.length - 4)}',
                            ),
                            Text(item.title),
                            Text(item.type),
                            Text(
                              '${item.date}\n${item.time}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(item.venue),
                            const StatusChip(
                              label: 'Completed',
                              background: AppColors.emerald100,
                              foreground: AppColors.emerald700,
                            ),
                            _PrintRecordButton(
                              onPressed: () => _printEventRecord(item),
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

  void _printEventRecord(EventModel item) {
    PrintService.printRecord(
      title: 'Event Transaction Record',
      module: 'Events',
      reference: _eventReference(item),
      result: 'Completed',
      details: [
        PrintDetail('Event Title', item.title),
        PrintDetail('Event Type', item.type),
        PrintDetail('Organizer', item.organizer),
        PrintDetail('Event Date', item.date),
        PrintDetail('Event Time', item.time),
        PrintDetail('Venue', item.venue),
        PrintDetail('Date and Time Posted', item.postedAt),
        PrintDetail('Date Completed', item.completedAt),
        PrintDetail('Description', item.description),
        const PrintDetail('Final Status', 'Completed'),
      ],
    );
  }

  String _eventReference(EventModel item) {
    final id = '${item.id}';
    return 'EVT-${id.length <= 4 ? id : id.substring(id.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final active = _events.where((event) {
      if (event.isCompleted) return false;
      if (query.isEmpty) return true;
      return [
        event.title,
        event.type,
        event.date,
        event.time,
        event.postedAt,
        event.venue,
        event.organizer,
      ].join(' ').toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    return AppShell(
      currentRoute: AppRoutes.adminEvents,
      isResident: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Event Management',
            subtitle: 'Manage and track all barangay events and activities.',
            actions: [
              CustomButton(
                label: 'Logs',
                icon: Icons.access_time,
                primary: false,
                onPressed: _showLogs,
              ),
              CustomButton(
                label: 'Add Event',
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
                    Icons.calendar_today_outlined,
                    color: AppColors.blue700,
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: 'Total Events: ',
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
            title: 'Events Masterlist',
            searchPlaceholder: 'Search events...',
            onSearchChanged: (value) => setState(() => _query = value),
            emptyText: 'No active events found. Click "Add Event" to start.',
            columns: const [
              'Event Title',
              'Type',
              'Date & Time',
              'Posted',
              'Venue',
              'Organizer',
              'Action',
            ],
            rows: active.map((event) {
              return [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StatusChip(
                  label: event.type.isEmpty ? 'Other' : event.type,
                  background: _typeColor(event.type),
                  foreground: _typeText(event.type),
                ),
                Text(
                  '${event.date}\n${event.time}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  event.postedAt.isEmpty ? 'Not recorded' : event.postedAt,
                  style: const TextStyle(fontSize: 12),
                ),
                Text(event.venue),
                Text(event.organizer),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomButton(
                      label: 'Mark as Complete',
                      icon: Icons.check_circle,
                      compact: true,
                      success: true,
                      onPressed: () => _complete(event),
                    ),
                    IconButton(
                      tooltip: 'View/Edit',
                      icon: const Icon(
                        Icons.edit,
                        color: AppColors.blue600,
                        size: 18,
                      ),
                      onPressed: () => _openForm(event),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete,
                        color: AppColors.red600,
                        size: 18,
                      ),
                      onPressed: () => _delete(event.id),
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

  Color _typeColor(String type) {
    if (type.contains('Health')) return AppColors.emerald100;
    if (type.contains('Sports')) return const Color(0xffffedd5);
    if (type.contains('Peace')) return AppColors.red100;
    if (type.contains('Cultural')) return AppColors.purple100;
    if (type.contains('Environmental')) return const Color(0xffccfbf1);
    return AppColors.blue100;
  }

  Color _typeText(String type) {
    if (type.contains('Health')) return AppColors.emerald700;
    if (type.contains('Sports')) return const Color(0xffc2410c);
    if (type.contains('Peace')) return AppColors.red700;
    if (type.contains('Cultural')) return AppColors.purple700;
    if (type.contains('Environmental')) return const Color(0xff0f766e);
    return AppColors.blue700;
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

class _EventFormDialog extends StatefulWidget {
  const _EventFormDialog({this.existing});
  final EventModel? existing;

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController organizer;
  late final TextEditingController date;
  late final TextEditingController time;
  late final TextEditingController venue;
  late final TextEditingController description;
  String type = '';

  @override
  void initState() {
    super.initState();
    final event = widget.existing;
    title = TextEditingController(text: event?.title ?? '');
    organizer = TextEditingController(text: event?.organizer ?? '');
    date = TextEditingController(text: event?.date ?? '');
    time = TextEditingController(text: event?.time ?? '');
    venue = TextEditingController(text: event?.venue ?? '');
    description = TextEditingController(text: event?.description ?? '');
    type = event?.type ?? '';
  }

  @override
  void dispose() {
    title.dispose();
    organizer.dispose();
    date.dispose();
    time.dispose();
    venue.dispose();
    description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      EventModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch,
        title: title.text,
        type: type,
        organizer: organizer.text,
        date: date.text,
        time: time.text,
        venue: venue.text,
        description: description.text,
        status: existing?.status ?? '',
        postedAt: existing?.postedAt ?? nowIso(),
        completedAt: existing?.completedAt ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      title: widget.existing == null ? 'Add New Event' : 'Edit Event',
      saveText: widget.existing == null ? 'Save Event' : 'Update Event',
      width: 604,
      onCancel: () => Navigator.pop(context),
      onSave: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormSectionTitle('Event Information'),
            LabeledTextField(
              label: 'Event Title',
              controller: title,
              requiredField: true,
            ),
            const SizedBox(height: 20),
            _grid([
              LabeledDropdown(
                label: 'Event Type',
                value: type,
                requiredField: true,
                items: const [
                  '',
                  'Community Assembly',
                  'Health & Medical',
                  'Livelihood',
                  'Sports & Recreation',
                  'Peace & Order',
                  'Cultural & Festival',
                  'Educational',
                  'Environmental',
                  'Other',
                ],
                onChanged: (v) => setState(() => type = v ?? ''),
              ),
              LabeledTextField(
                label: 'Organizer',
                controller: organizer,
                requiredField: true,
              ),
            ]),
            const SizedBox(height: 24),
            const FormSectionTitle('Schedule & Location'),
            _grid([
              LabeledTextField(
                label: 'Date',
                controller: date,
                requiredField: true,
                hint: 'dd/mm/yyyy',
                suffixIcon: Icons.calendar_month_outlined,
              ),
              LabeledTextField(
                label: 'Time',
                controller: time,
                requiredField: true,
                hint: 'HH:MM',
                suffixIcon: Icons.access_time,
              ),
              LabeledTextField(
                label: 'Venue',
                controller: venue,
                requiredField: true,
              ),
            ], columns: 3),
            const SizedBox(height: 24),
            const FormSectionTitle('Additional Details'),
            LabeledTextField(
              label: 'Description',
              controller: description,
              requiredField: true,
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children, {int columns = 2}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = constraints.maxWidth < 640 ? 1 : columns;
        final spacing = effectiveColumns == 3 ? 20.0 : 24.0;
        final width =
            (constraints.maxWidth - (spacing * (effectiveColumns - 1))) /
            effectiveColumns;
        return Wrap(
          spacing: spacing,
          runSpacing: 20,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
