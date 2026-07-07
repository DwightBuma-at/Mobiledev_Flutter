class BlotterModel {
  BlotterModel({
    required this.id,
    this.caseNo = '',
    this.complainant = '',
    this.contact = '',
    this.respondent = '',
    this.type = '',
    this.date = '',
    this.time = '',
    this.location = '',
    this.status = 'Pending',
    this.narrative = '',
    this.actionTaken = '',
    this.submittedBy = 'Admin',
    this.residentId,
    this.residentName = '',
    this.completedAt = '',
  });

  final int id;
  final String caseNo;
  final String complainant;
  final String contact;
  final String respondent;
  final String type;
  final String date;
  final String time;
  final String location;
  final String status;
  final String narrative;
  final String actionTaken;
  final String submittedBy;
  final int? residentId;
  final String residentName;
  final String completedAt;

  bool get isCompleted => normalizeStatus(status) == 'Completed';

  static String normalizeStatus(String status) {
    if (status == 'Active') return 'In-progress';
    if (status == 'Resolved' || status == 'Dismissed') return 'Completed';
    return status.isEmpty ? 'Pending' : status;
  }

  factory BlotterModel.fromJson(Map<String, dynamic> json) => BlotterModel(
    id: _toInt(json['id']),
    caseNo: '${json['caseNo'] ?? ''}',
    complainant: '${json['complainant'] ?? ''}',
    contact: '${json['contact'] ?? ''}',
    respondent: '${json['respondent'] ?? ''}',
    type: '${json['type'] ?? ''}',
    date: '${json['date'] ?? ''}',
    time: '${json['time'] ?? ''}',
    location: '${json['location'] ?? ''}',
    status: normalizeStatus('${json['status'] ?? 'Pending'}'),
    narrative: '${json['narrative'] ?? ''}',
    actionTaken: '${json['actionTaken'] ?? ''}',
    submittedBy: '${json['submittedBy'] ?? 'Admin'}',
    residentId: json['residentId'] == null ? null : _toInt(json['residentId']),
    residentName: '${json['residentName'] ?? ''}',
    completedAt: '${json['completedAt'] ?? ''}',
  );

  BlotterModel copyWith({String? status, String? completedAt}) => BlotterModel(
    id: id,
    caseNo: caseNo,
    complainant: complainant,
    contact: contact,
    respondent: respondent,
    type: type,
    date: date,
    time: time,
    location: location,
    status: status ?? this.status,
    narrative: narrative,
    actionTaken: actionTaken,
    submittedBy: submittedBy,
    residentId: residentId,
    residentName: residentName,
    completedAt: completedAt ?? this.completedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'caseNo': caseNo,
    'complainant': complainant,
    'contact': contact,
    'respondent': respondent,
    'type': type,
    'date': date,
    'time': time,
    'location': location,
    'status': status,
    'narrative': narrative,
    'actionTaken': actionTaken,
    'submittedBy': submittedBy,
    'residentId': residentId,
    'residentName': residentName,
    'completedAt': completedAt,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
