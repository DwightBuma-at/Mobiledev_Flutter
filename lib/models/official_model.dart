class OfficialModel {
  OfficialModel({
    required this.id,
    this.name = '',
    this.position = '',
    this.committee = '',
    this.contact = '',
    this.email = '',
    this.termStart = '',
    this.termEnd = '',
    this.status = 'Active',
  });

  final int id;
  final String name;
  final String position;
  final String committee;
  final String contact;
  final String email;
  final String termStart;
  final String termEnd;
  final String status;

  factory OfficialModel.fromJson(Map<String, dynamic> json) => OfficialModel(
    id: _toInt(json['id']),
    name: '${json['name'] ?? ''}',
    position: '${json['position'] ?? ''}',
    committee: '${json['committee'] ?? ''}',
    contact: '${json['contact'] ?? ''}',
    email: '${json['email'] ?? ''}',
    termStart: '${json['termStart'] ?? ''}',
    termEnd: '${json['termEnd'] ?? ''}',
    status: '${json['status'] ?? 'Active'}',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'position': position,
    'committee': committee,
    'contact': contact,
    'email': email,
    'termStart': termStart,
    'termEnd': termEnd,
    'status': status,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
