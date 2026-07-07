class LogModel {
  LogModel({
    required this.key,
    required this.id,
    required this.date,
    required this.module,
    required this.reference,
    required this.record,
    required this.result,
    required this.details,
  });

  final String key;
  final int id;
  final String date;
  final String module;
  final String reference;
  final String record;
  final String result;
  final List<List<String>> details;

  factory LogModel.fromJson(Map<String, dynamic> json) => LogModel(
    key: '${json['key'] ?? ''}',
    id: _toInt(json['id']),
    date: '${json['date'] ?? ''}',
    module: '${json['module'] ?? ''}',
    reference: '${json['reference'] ?? ''}',
    record: '${json['record'] ?? ''}',
    result: '${json['result'] ?? ''}',
    details: (json['details'] is List)
        ? (json['details'] as List)
              .map((row) => (row as List).map((cell) => '$cell').toList())
              .toList()
        : <List<String>>[],
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'id': id,
    'date': date,
    'module': module,
    'reference': reference,
    'record': record,
    'result': result,
    'details': details,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
