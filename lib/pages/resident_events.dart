import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_shell.dart';
import '../widgets/status_dropdown.dart';

class ResidentEventsPage extends StatefulWidget {
  const ResidentEventsPage({super.key});

  @override
  State<ResidentEventsPage> createState() => _ResidentEventsPageState();
}

class _ResidentEventsPageState extends State<ResidentEventsPage> {
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
    final events =
        StorageService.events()
            .where(
              (event) =>
                  !event.isCompleted && event.submittedBy != 'Resident Portal',
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return AppShell(
      currentRoute: AppRoutes.residentEvents,
      isResident: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Events',
            subtitle: 'View events and activities posted by the administrator.',
          ),
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
                    child: Text(
                      'Only active admin-posted events are shown here.',
                      style: TextStyle(color: AppColors.slate500),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.slate200),
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No posted events yet.',
                      style: TextStyle(color: AppColors.slate400),
                    ),
                  )
                else
                  ...events.map(
                    (event) => Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.slate100),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.purple50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.purple600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: AppColors.slate800,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    StatusChip(
                                      label: event.type.isEmpty
                                          ? 'Event'
                                          : event.type,
                                      background: AppColors.purple100,
                                      foreground: AppColors.purple700,
                                    ),
                                    Text(
                                      '${event.date} ${event.time}',
                                      style: const TextStyle(
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                    Text(
                                      event.venue,
                                      style: const TextStyle(
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
