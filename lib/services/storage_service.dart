import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/blotter_model.dart';
import '../models/certificate_model.dart';
import '../models/event_model.dart';
import '../models/log_model.dart';
import '../models/official_model.dart';
import '../models/resident_model.dart';
import 'storage_backend.dart';

class StorageKeys {
  static const residents = 'bims_residents';
  static const officials = 'bims_officials';
  static const blotters = 'bims_blotters';
  static const events = 'bims_events';
  static const certs = 'bims_certs';
  static const logs = 'bims_logs';
  static const currentResident = 'bims_current_resident';
}

class StorageService {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static bool _initialized = false;
  static late StorageBackend _storage;

  static const _recordKeys = [
    StorageKeys.residents,
    StorageKeys.officials,
    StorageKeys.blotters,
    StorageKeys.events,
    StorageKeys.certs,
    StorageKeys.logs,
  ];

  static Future<void> initialize() async {
    if (_initialized) return;
    _storage = await StorageBackend.create();
    _initialized = true;
    for (final key in _recordKeys) {
      if (!_storage.containsKey(key)) {
        await _storage.setString(key, jsonEncode([]));
      }
    }
  }

  static void _notifyChanged() {
    revision.value = revision.value + 1;
  }

  static List<Map<String, dynamic>> _readList(String key) {
    try {
      final raw = _storage.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      final raw = _storage.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final backupKey =
            '${key}_backup_${DateTime.now().millisecondsSinceEpoch}';
        _storage.setString(backupKey, raw);
      }
      return [];
    }
  }

  static void _writeList(String key, List<Map<String, dynamic>> records) {
    _storage.setString(key, jsonEncode(records));
    _notifyChanged();
  }

  static List<ResidentModel> residents() =>
      _readList(StorageKeys.residents).map(ResidentModel.fromJson).toList();

  static void saveResidents(List<ResidentModel> records) => _writeList(
    StorageKeys.residents,
    records.map((e) => e.toJson()).toList(),
  );

  static List<OfficialModel> officials() =>
      _readList(StorageKeys.officials).map(OfficialModel.fromJson).toList();

  static void saveOfficials(List<OfficialModel> records) => _writeList(
    StorageKeys.officials,
    records.map((e) => e.toJson()).toList(),
  );

  static List<BlotterModel> blotters() =>
      _readList(StorageKeys.blotters).map(BlotterModel.fromJson).toList();

  static void saveBlotters(List<BlotterModel> records) =>
      _writeList(StorageKeys.blotters, records.map((e) => e.toJson()).toList());

  static List<EventModel> events() =>
      _readList(StorageKeys.events).map(EventModel.fromJson).toList();

  static void saveEvents(List<EventModel> records) =>
      _writeList(StorageKeys.events, records.map((e) => e.toJson()).toList());

  static List<CertificateModel> certs() =>
      _readList(StorageKeys.certs).map(CertificateModel.fromJson).toList();

  static void saveCerts(List<CertificateModel> records) =>
      _writeList(StorageKeys.certs, records.map((e) => e.toJson()).toList());

  static List<LogModel> logs() =>
      _readList(StorageKeys.logs).map(LogModel.fromJson).toList();

  static void appendLog(LogModel log) {
    final existing = logs();
    if (existing.any((item) => item.key == log.key)) return;
    existing.add(log);
    _writeList(StorageKeys.logs, existing.map((e) => e.toJson()).toList());
  }

  static Map<String, dynamic>? currentResident() {
    try {
      final raw = _storage.getString(StorageKeys.currentResident);
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static void setCurrentResident(ResidentModel resident) {
    _storage.setString(
      StorageKeys.currentResident,
      jsonEncode({
        'id': resident.id,
        'name': resident.fullName.trim(),
        'username': resident.username,
      }),
    );
    _notifyChanged();
  }

  static void clearCurrentResident() {
    _storage.remove(StorageKeys.currentResident);
    _notifyChanged();
  }
}

String todayIso() => DateTime.now().toIso8601String().split('T').first;

String nowIso() => DateTime.now().toIso8601String();

String sequence(String prefix) {
  final year = DateTime.now().year;
  final num = 1000 + DateTime.now().millisecondsSinceEpoch % 9000;
  return '$prefix-$year-$num';
}
