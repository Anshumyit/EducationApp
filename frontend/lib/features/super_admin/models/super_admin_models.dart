class SuperAdminSchoolModel {
  final String id;
  final String name;
  final String code;
  final String board;
  final String status;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String currentAcademicYear;
  final Map<String, dynamic> limits;
  final Map<String, dynamic> modules;

  SuperAdminSchoolModel({
    required this.id,
    required this.name,
    required this.code,
    required this.board,
    required this.status,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.currentAcademicYear = '2026-2027',
    this.limits = const {},
    this.modules = const {},
  });

  factory SuperAdminSchoolModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminSchoolModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      board: json['board'] ?? 'CBSE',
      status: json['status'] ?? 'PENDING',
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      address: json['address'],
      currentAcademicYear: json['currentAcademicYear'] ?? '2026-2027',
      limits: json['limits'] is Map ? Map<String, dynamic>.from(json['limits']) : {},
      modules: json['modules'] is Map ? Map<String, dynamic>.from(json['modules']) : {},
    );
  }

  int get maxStudents => (limits['maxStudents'] as num?)?.toInt() ?? 1000;
  int get maxTeachers => (limits['maxTeachers'] as num?)?.toInt() ?? 80;
  int get maxStaff => (limits['maxStaff'] as num?)?.toInt() ?? 40;
  int get storageLimitMB => (limits['storageLimitMB'] as num?)?.toInt() ?? 10240;

  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING';
  bool get isSuspended => status == 'SUSPENDED';
}

class SuperAdminUserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role;
  final String status;
  final bool isSuspended;
  final String? schoolName;
  final String? schoolId;
  final Map<String, dynamic> permissions;
  final DateTime? createdAt;

  SuperAdminUserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.status,
    this.isSuspended = false,
    this.schoolName,
    this.schoolId,
    this.permissions = const {},
    this.createdAt,
  });

  factory SuperAdminUserModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    String? sId;
    if (json['schoolId'] is Map) {
      sName = json['schoolId']['name'];
      sId = json['schoolId']['_id'] ?? json['schoolId']['id'];
    } else if (json['schoolId'] is String) {
      sId = json['schoolId'];
    }

    return SuperAdminUserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'ADMIN',
      status: json['status'] ?? 'APPROVED',
      isSuspended: json['isSuspended'] ?? false,
      schoolName: sName,
      schoolId: sId,
      permissions: json['permissions'] is Map ? Map<String, dynamic>.from(json['permissions']) : {},
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

class SuperAdminBusModel {
  final String id;
  final String busNumber;
  final String registrationNumber;
  final String? driverName;
  final String? driverPhone;
  final String status;
  final double currentSpeedKmph;
  final double latitude;
  final double longitude;
  final String? schoolName;

  SuperAdminBusModel({
    required this.id,
    required this.busNumber,
    required this.registrationNumber,
    this.driverName,
    this.driverPhone,
    required this.status,
    this.currentSpeedKmph = 0,
    this.latitude = 28.6139,
    this.longitude = 77.2090,
    this.schoolName,
  });

  factory SuperAdminBusModel.fromJson(Map<String, dynamic> json) {
    double lat = 28.6139;
    double lng = 77.2090;
    if (json['currentLocation'] is Map) {
      lat = (json['currentLocation']['latitude'] as num?)?.toDouble() ?? 28.6139;
      lng = (json['currentLocation']['longitude'] as num?)?.toDouble() ?? 77.2090;
    }
    String? sName;
    if (json['schoolId'] is Map) {
      sName = json['schoolId']['name'];
    }

    return SuperAdminBusModel(
      id: json['id'] ?? json['_id'] ?? '',
      busNumber: json['busNumber'] ?? 'Bus',
      registrationNumber: json['registrationNumber'] ?? '',
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      status: json['status'] ?? 'IDLE',
      currentSpeedKmph: (json['currentSpeedKmph'] as num?)?.toDouble() ?? 0,
      latitude: lat,
      longitude: lng,
      schoolName: sName,
    );
  }
}

class SuperAdminBiometricModel {
  final String id;
  final String deviceId;
  final String name;
  final String? location;
  final String status;
  final DateTime? lastSyncAt;
  final int batteryPercent;
  final String? schoolName;

  SuperAdminBiometricModel({
    required this.id,
    required this.deviceId,
    required this.name,
    this.location,
    required this.status,
    this.lastSyncAt,
    this.batteryPercent = 95,
    this.schoolName,
  });

  factory SuperAdminBiometricModel.fromJson(Map<String, dynamic> json) {
    String? sName;
    if (json['schoolId'] is Map) {
      sName = json['schoolId']['name'];
    }

    return SuperAdminBiometricModel(
      id: json['id'] ?? json['_id'] ?? '',
      deviceId: json['deviceId'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
      status: json['status'] ?? 'ONLINE',
      lastSyncAt: json['lastSyncAt'] != null ? DateTime.tryParse(json['lastSyncAt'].toString()) : null,
      batteryPercent: (json['batteryPercent'] as num?)?.toInt() ?? 95,
      schoolName: sName,
    );
  }
}
