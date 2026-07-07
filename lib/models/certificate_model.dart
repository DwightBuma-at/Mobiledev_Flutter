class CertificateModel {
  CertificateModel({
    required this.id,
    this.controlNo = '',
    this.resident = '',
    this.docType = '',
    this.date = '',
    this.status = 'Pending',
    this.purpose = '',
    this.submittedBy = 'Admin',
    this.residentId,
    this.residentName = '',
    this.claimedAt = '',
  });

  final int id;
  final String controlNo;
  final String resident;
  final String docType;
  final String date;
  final String status;
  final String purpose;
  final String submittedBy;
  final int? residentId;
  final String residentName;
  final String claimedAt;

  bool get isClaimed => normalizeStatus(status) == 'Claimed';

  static String normalizeStatus(String status) {
    if (status == 'Processing') return 'In Progress';
    if (status == 'Ready for Pickup') return 'Ready to Claim';
    if (status == 'Released') return 'Claimed';
    return status.isEmpty ? 'Pending' : status;
  }

  factory CertificateModel.fromJson(Map<String, dynamic> json) =>
      CertificateModel(
        id: _toInt(json['id']),
        controlNo: '${json['controlNo'] ?? ''}',
        resident: '${json['resident'] ?? json['residentName'] ?? ''}',
        docType: '${json['docType'] ?? ''}',
        date: '${json['date'] ?? ''}',
        status: normalizeStatus('${json['status'] ?? 'Pending'}'),
        purpose: '${json['purpose'] ?? ''}',
        submittedBy: '${json['submittedBy'] ?? 'Admin'}',
        residentId: json['residentId'] == null
            ? null
            : _toInt(json['residentId']),
        residentName: '${json['residentName'] ?? ''}',
        claimedAt: '${json['claimedAt'] ?? ''}',
      );

  CertificateModel copyWith({String? status, String? claimedAt}) =>
      CertificateModel(
        id: id,
        controlNo: controlNo,
        resident: resident,
        docType: docType,
        date: date,
        status: status ?? this.status,
        purpose: purpose,
        submittedBy: submittedBy,
        residentId: residentId,
        residentName: residentName,
        claimedAt: claimedAt ?? this.claimedAt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'controlNo': controlNo,
    'resident': resident,
    'docType': docType,
    'date': date,
    'status': status,
    'purpose': purpose,
    'submittedBy': submittedBy,
    'residentId': residentId,
    'residentName': residentName,
    'claimedAt': claimedAt,
  };
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? DateTime.now().millisecondsSinceEpoch;
}
