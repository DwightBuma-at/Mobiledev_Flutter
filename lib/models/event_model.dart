class EventModel {
  EventModel({
    required this.id,
    this.title = '',
    this.type = '',
    this.organizer = '',
    this.date = '',
    this.time = '',
    this.venue = '',
    this.description = '',
    this.status = '',
    this.postedAt = '',
    this.completedAt = '',
    this.submittedBy = 'Admin',
  });

  final int id;
  final String title;
  final String type;
  final String organizer;
  final String date;
  final String time;
  final String venue;
  final String description;
  final String status;
  final String postedAt;
  final String completedAt;
  final String submittedBy;

  bool get isCompleted => status == 'Completed';

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: _toInt(json['id']),
    title: '${json['title'] ?? ''}',
    type: '${json['type'] ?? ''}',
    organizer: '${json['organizer'] ?? ''}',
    date: '${json['date'] ?? ''}',
    time: '${json['time'] ?? ''}',
    venue: '${json['venue'] ?? json['location'] ?? ''}',
    description: '${json['description'] ?? ''}',
    status: '${json['status'] ?? ''}',
    postedAt: '${json['postedAt'] ?? ''}',
    completedAt: '${json['completedAt'] ?? ''}',
    submittedBy: '${json['submittedBy'] ?? 'Admin'}',
  );

  EventModel copyWith({String? status, String? completedAt}) => EventModel(
    id: id,
    title: title,
    type: type,
    organizer: organizer,
    date: date,
    time: time,
    venue: venue,
    description: description,
    status: status ?? this.status,
    postedAt: postedAt,
    completedAt: completedAt ?? this.completedAt,
    submittedBy: submittedBy,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'organizer': organizer,
    'date': date,
    'time': time,
    'venue': venue,
    'description': description,
    'status': status,
    'postedAt': postedAt,
    'completedAt': completedAt,
    'submittedBy': submittedBy,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
