class UserModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String role; // 'ADMIN', 'TEACHER', 'PARENT'
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final bool isOtpVerified;
  final String avatar;
  final List<String> subjects;
  final bool isClassTeacher;
  final dynamic assignedClass;
  final String? address;
  final dynamic schoolId;
  final Map<String, dynamic>? permissions;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    required this.status,
    this.isOtpVerified = false,
    this.avatar = '',
    this.subjects = const [],
    this.isClassTeacher = false,
    this.assignedClass,
    this.address,
    this.schoolId,
    this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'PARENT',
      status: json['status'] ?? 'PENDING',
      isOtpVerified: json['isOtpVerified'] ?? false,
      avatar: json['avatar'] ?? '',
      subjects: json['subjects'] != null
          ? List<String>.from(json['subjects'].map((x) => x.toString()))
          : [],
      isClassTeacher: json['isClassTeacher'] ?? false,
      assignedClass: json['assignedClass'],
      address: json['address'],
      schoolId: json['schoolId'],
      permissions: json['permissions'] is Map ? Map<String, dynamic>.from(json['permissions']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'isOtpVerified': isOtpVerified,
      'avatar': avatar,
      'subjects': subjects,
      'isClassTeacher': isClassTeacher,
      'assignedClass': assignedClass,
      'address': address,
      'schoolId': schoolId,
      'permissions': permissions,
    };
  }

  bool get isSuperAdmin => role == 'SUPER_ADMIN';
  bool get isAdmin => role == 'ADMIN';
  bool get isTeacher => role == 'TEACHER';
  bool get isParent => role == 'PARENT';
  bool get isApproved => status == 'APPROVED';
}
