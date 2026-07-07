class ResidentModel {
  ResidentModel({
    required this.id,
    this.lastName = '',
    this.firstName = '',
    this.middleName = '',
    this.suffix = '',
    this.gender = '',
    this.birthDate = '',
    this.civilStatus = '',
    this.contact = '',
    this.email = '',
    this.address = '',
    this.purok = '',
    this.classification = '',
    this.voterStatus = '',
    this.residentStatus = 'Active',
    this.username = '',
    this.password = '',
    this.registeredAt = '',
  });

  final int id;
  final String lastName;
  final String firstName;
  final String middleName;
  final String suffix;
  final String gender;
  final String birthDate;
  final String civilStatus;
  final String contact;
  final String email;
  final String address;
  final String purok;
  final String classification;
  final String voterStatus;
  final String residentStatus;
  final String username;
  final String password;
  final String registeredAt;

  String get fullName => [
    firstName,
    middleName,
    lastName,
    suffix,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  factory ResidentModel.fromJson(Map<String, dynamic> json) => ResidentModel(
    id: _toInt(json['id']),
    lastName: '${json['lastName'] ?? ''}',
    firstName: '${json['firstName'] ?? ''}',
    middleName: '${json['middleName'] ?? ''}',
    suffix: '${json['suffix'] ?? ''}',
    gender: '${json['gender'] ?? ''}',
    birthDate: '${json['birthDate'] ?? ''}',
    civilStatus: '${json['civilStatus'] ?? ''}',
    contact: '${json['contact'] ?? ''}',
    email: '${json['email'] ?? ''}',
    address: '${json['address'] ?? ''}',
    purok: '${json['purok'] ?? ''}',
    classification: '${json['classification'] ?? ''}',
    voterStatus: '${json['voterStatus'] ?? ''}',
    residentStatus: '${json['residentStatus'] ?? 'Active'}',
    username: '${json['username'] ?? ''}',
    password: '${json['password'] ?? ''}',
    registeredAt: '${json['registeredAt'] ?? ''}',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lastName': lastName,
    'firstName': firstName,
    'middleName': middleName,
    'suffix': suffix,
    'gender': gender,
    'birthDate': birthDate,
    'civilStatus': civilStatus,
    'contact': contact,
    'email': email,
    'address': address,
    'purok': purok,
    'classification': classification,
    'voterStatus': voterStatus,
    'residentStatus': residentStatus,
    'username': username,
    'password': password,
    'registeredAt': registeredAt,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
