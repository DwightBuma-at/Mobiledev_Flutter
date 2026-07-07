import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const firestoreMigrated = 'bims_firestore_migrated';
}

class StorageService {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);
  static bool _initialized = false;
  static bool _syncStarted = false;
  static Timer? _notifyTimer;
  static Timer? _syncTimer;
  static Completer<void>? _readyCompleter;
  static late StorageBackend _sessionStorage;
  static late FirebaseFirestore _db;
  static final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = [];

  static List<ResidentModel> _residents = [];
  static List<OfficialModel> _officials = [];
  static List<BlotterModel> _blotters = [];
  static List<EventModel> _events = [];
  static List<CertificateModel> _certs = [];
  static List<LogModel> _logs = [];

  static Future<void> get ready => _readyCompleter?.future ?? Future.value();

  static Future<void> ensureReady() {
    _startSync();
    return ready;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _readyCompleter = Completer<void>();
    _sessionStorage = await StorageBackend.create();
    _db = FirebaseFirestore.instance;
    _initialized = true;
    _syncTimer = Timer(const Duration(seconds: 4), _startSync);
  }

  static void _startSync() {
    if (_syncStarted) return;
    _syncStarted = true;
    _syncTimer?.cancel();
    unawaited(_syncInitialData());
  }

  static Future<void> _syncInitialData() async {
    try {
      await _loadInitialRecords().timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      await _migrateLegacyLocalRecords();
      _listenForChanges();
      _notifyChanged();
      _readyCompleter?.complete();
    } catch (_) {
      _readyCompleter?.complete();
    }
  }

  static Future<void> _loadInitialRecords() async {
    final snapshots = await Future.wait([
      _collection('residents').get(),
      _collection('officials').get(),
      _collection('blotters').get(),
      _collection('events').get(),
      _collection('certificates').get(),
      _collection('logs').get(),
    ]);

    _residents = _fromSnapshot(snapshots[0], ResidentModel.fromJson);
    _officials = _fromSnapshot(snapshots[1], OfficialModel.fromJson);
    _blotters = _fromSnapshot(snapshots[2], BlotterModel.fromJson);
    _events = _fromSnapshot(snapshots[3], EventModel.fromJson);
    _certs = _fromSnapshot(snapshots[4], CertificateModel.fromJson);
    _logs = snapshots[5].docs.map(_logFromDoc).toList();
  }

  static Future<void> _migrateLegacyLocalRecords() async {
    if (_sessionStorage.getString(StorageKeys.firestoreMigrated) == 'true') {
      return;
    }

    final legacyResidents = _readLegacyList(
      StorageKeys.residents,
      ResidentModel.fromJson,
    );
    final legacyOfficials = _readLegacyList(
      StorageKeys.officials,
      OfficialModel.fromJson,
    );
    final legacyBlotters = _readLegacyList(
      StorageKeys.blotters,
      BlotterModel.fromJson,
    );
    final legacyEvents = _readLegacyList(
      StorageKeys.events,
      EventModel.fromJson,
    );
    final legacyCerts = _readLegacyList(
      StorageKeys.certs,
      CertificateModel.fromJson,
    );
    final legacyLogs = _readLegacyList(StorageKeys.logs, LogModel.fromJson);

    if (_residents.isEmpty && legacyResidents.isNotEmpty) {
      _residents = legacyResidents;
      await _saveList(
        collection: 'residents',
        previous: const <ResidentModel>[],
        records: _residents,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      );
    }
    if (_officials.isEmpty && legacyOfficials.isNotEmpty) {
      _officials = legacyOfficials;
      await _saveList(
        collection: 'officials',
        previous: const <OfficialModel>[],
        records: _officials,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      );
    }
    if (_blotters.isEmpty && legacyBlotters.isNotEmpty) {
      _blotters = legacyBlotters;
      await _saveList(
        collection: 'blotters',
        previous: const <BlotterModel>[],
        records: _blotters,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      );
    }
    if (_events.isEmpty && legacyEvents.isNotEmpty) {
      _events = legacyEvents;
      await _saveList(
        collection: 'events',
        previous: const <EventModel>[],
        records: _events,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      );
    }
    if (_certs.isEmpty && legacyCerts.isNotEmpty) {
      _certs = legacyCerts;
      await _saveList(
        collection: 'certificates',
        previous: const <CertificateModel>[],
        records: _certs,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      );
    }
    if (_logs.isEmpty && legacyLogs.isNotEmpty) {
      _logs = legacyLogs;
      final batch = _db.batch();
      for (final log in _logs) {
        batch.set(_collection('logs').doc(log.key), _logToFirestore(log));
      }
      await batch.commit();
    }

    await _sessionStorage.setString(StorageKeys.firestoreMigrated, 'true');
  }

  static List<T> _readLegacyList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      final raw = _sessionStorage.getString(key);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static void _listenForChanges() {
    _subscriptions.addAll([
      _collection('residents').snapshots().listen((snapshot) {
        _residents = _fromSnapshot(snapshot, ResidentModel.fromJson);
        _notifyChanged();
      }),
      _collection('officials').snapshots().listen((snapshot) {
        _officials = _fromSnapshot(snapshot, OfficialModel.fromJson);
        _notifyChanged();
      }),
      _collection('blotters').snapshots().listen((snapshot) {
        _blotters = _fromSnapshot(snapshot, BlotterModel.fromJson);
        _notifyChanged();
      }),
      _collection('events').snapshots().listen((snapshot) {
        _events = _fromSnapshot(snapshot, EventModel.fromJson);
        _notifyChanged();
      }),
      _collection('certificates').snapshots().listen((snapshot) {
        _certs = _fromSnapshot(snapshot, CertificateModel.fromJson);
        _notifyChanged();
      }),
      _collection('logs').snapshots().listen((snapshot) {
        _logs = snapshot.docs.map(_logFromDoc).toList();
        _notifyChanged();
      }),
    ]);
  }

  static CollectionReference<Map<String, dynamic>> _collection(String name) =>
      _db.collection(name);

  static List<T> _fromSnapshot<T>(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      return fromJson(data);
    }).toList();
  }

  static LogModel _logFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    final rawDetails = data['details'];
    if (rawDetails is List) {
      data['details'] = rawDetails
          .map((row) {
            if (row is Map) {
              return ['${row['label'] ?? ''}', '${row['value'] ?? ''}'];
            }
            if (row is List) {
              return row.map((cell) => '$cell').toList();
            }
            return <String>[];
          })
          .where((row) => row.isNotEmpty)
          .toList();
    }
    return LogModel.fromJson(data);
  }

  static void _notifyChanged() {
    if (_notifyTimer?.isActive ?? false) return;
    _notifyTimer = Timer(const Duration(milliseconds: 16), () {
      revision.value = revision.value + 1;
    });
  }

  static Future<void> _saveList<T>({
    required String collection,
    required List<T> previous,
    required List<T> records,
    required String Function(T record) docId,
    required Map<String, dynamic> Function(T record) toJson,
  }) async {
    final previousById = <String, T>{};
    for (final record in previous) {
      final id = docId(record);
      if (id.isNotEmpty) previousById[id] = record;
    }
    final currentById = <String, T>{};
    for (final record in records) {
      final id = docId(record);
      if (id.isNotEmpty) currentById[id] = record;
    }
    final batch = _db.batch();
    var hasWrites = false;

    for (final entry in currentById.entries) {
      final previousRecord = previousById[entry.key];
      final currentData = _cleanMap(toJson(entry.value));
      final previousData = previousRecord == null
          ? null
          : _cleanMap(toJson(previousRecord));
      if (previousData == null || !mapEquals(previousData, currentData)) {
        batch.set(_collection(collection).doc(entry.key), currentData);
        hasWrites = true;
      }
    }

    for (final removedId in previousById.keys.toSet().difference(
      currentById.keys.toSet(),
    )) {
      batch.delete(_collection(collection).doc(removedId));
      hasWrites = true;
    }

    if (hasWrites) await batch.commit();
  }

  static Map<String, dynamic> _cleanMap(Map<String, dynamic> data) {
    return Map<String, dynamic>.fromEntries(
      data.entries.where((entry) => entry.value != null),
    );
  }

  static Map<String, dynamic> _logToFirestore(LogModel log) {
    final json = log.toJson();
    json['details'] = log.details
        .map(
          (row) => {
            'label': row.isNotEmpty ? row.first : '',
            'value': row.length > 1 ? row[1] : '',
          },
        )
        .toList();
    return json;
  }

  static List<ResidentModel> residents() =>
      List<ResidentModel>.from(_residents);

  static void saveResidents(List<ResidentModel> records) {
    final previous = List<ResidentModel>.from(_residents);
    _residents = List<ResidentModel>.from(records);
    _notifyChanged();
    unawaited(
      _saveList(
        collection: 'residents',
        previous: previous,
        records: _residents,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      ),
    );
  }

  static List<OfficialModel> officials() =>
      List<OfficialModel>.from(_officials);

  static void saveOfficials(List<OfficialModel> records) {
    final previous = List<OfficialModel>.from(_officials);
    _officials = List<OfficialModel>.from(records);
    _notifyChanged();
    unawaited(
      _saveList(
        collection: 'officials',
        previous: previous,
        records: _officials,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      ),
    );
  }

  static List<BlotterModel> blotters() => List<BlotterModel>.from(_blotters);

  static void saveBlotters(List<BlotterModel> records) {
    final previous = List<BlotterModel>.from(_blotters);
    _blotters = List<BlotterModel>.from(records);
    _notifyChanged();
    unawaited(
      _saveList(
        collection: 'blotters',
        previous: previous,
        records: _blotters,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      ),
    );
  }

  static List<EventModel> events() => List<EventModel>.from(_events);

  static void saveEvents(List<EventModel> records) {
    final previous = List<EventModel>.from(_events);
    _events = List<EventModel>.from(records);
    _notifyChanged();
    unawaited(
      _saveList(
        collection: 'events',
        previous: previous,
        records: _events,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      ),
    );
  }

  static List<CertificateModel> certs() => List<CertificateModel>.from(_certs);

  static void saveCerts(List<CertificateModel> records) {
    final previous = List<CertificateModel>.from(_certs);
    _certs = List<CertificateModel>.from(records);
    _notifyChanged();
    unawaited(
      _saveList(
        collection: 'certificates',
        previous: previous,
        records: _certs,
        docId: (record) => '${record.id}',
        toJson: (record) => record.toJson(),
      ),
    );
  }

  static List<LogModel> logs() => List<LogModel>.from(_logs);

  static void appendLog(LogModel log) {
    if (_logs.any((item) => item.key == log.key)) return;
    _logs = [..._logs, log];
    _notifyChanged();
    unawaited(_collection('logs').doc(log.key).set(_logToFirestore(log)));
  }

  static void appendModuleLog(String collection, LogModel log) {
    unawaited(_collection(collection).doc(log.key).set(_logToFirestore(log)));
  }

  static void deleteLog(String key, {String? moduleCollection}) {
    _logs = _logs.where((item) => item.key != key).toList();
    _notifyChanged();
    unawaited(_collection('logs').doc(key).delete());
    if (moduleCollection != null) {
      unawaited(_collection(moduleCollection).doc(key).delete());
    }
  }

  static void appendActionLog({
    required String module,
    required String action,
    required String reference,
    required String record,
    String actor = 'Admin',
    List<List<String>> details = const [],
  }) {
    final timestamp = nowIso();
    appendLog(
      LogModel(
        key: '$module-$action-${DateTime.now().microsecondsSinceEpoch}'
            .replaceAll(' ', '-'),
        id: DateTime.now().microsecondsSinceEpoch,
        date: timestamp,
        module: module,
        reference: reference,
        record: record,
        result: action,
        details: [
          ['Action', action],
          ['Actor', actor],
          ['Date', timestamp],
          ...details,
        ],
      ),
    );
  }

  static Map<String, dynamic>? currentResident() {
    try {
      final raw = _sessionStorage.getString(StorageKeys.currentResident);
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static void setCurrentResident(ResidentModel resident) {
    unawaited(
      _sessionStorage.setString(
        StorageKeys.currentResident,
        jsonEncode({
          'id': resident.id,
          'name': resident.fullName.trim(),
          'username': resident.username,
        }),
      ),
    );
    _notifyChanged();
  }

  static void clearCurrentResident() {
    unawaited(_sessionStorage.remove(StorageKeys.currentResident));
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
