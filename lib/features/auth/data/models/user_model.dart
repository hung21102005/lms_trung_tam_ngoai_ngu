import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.userCode,
    required super.fullName,
    super.email,
    super.phone,
    super.avatarUrl,
    required super.status,
    required super.isFirstLogin,
    super.branchId,
    super.branchName,
    required super.roles,
    required super.permissions,
    super.gender,
    super.dateOfBirth,
    super.address,
    super.studentCode,
    super.currentClass,
    super.teacherCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Xử lý linh hoạt cả khi branch là object hoặc null
    String? branchId;
    String? branchName;
    if (json['branch'] is Map<String, dynamic>) {
      branchId = json['branch']['id'] as String?;
      branchName = json['branch']['name'] as String?;
    } else if (json['branchId'] is String) {
      branchId = json['branchId'] as String?;
    }

    // Xử lý danh sách roles (chuỗi hoặc object)
    final rolesList = <String>[];
    if (json['roles'] is List) {
      for (final r in json['roles']) {
        if (r is String) {
          rolesList.add(r);
        } else if (r is Map && r['code'] is String) {
          rolesList.add(r['code'] as String);
        }
      }
    }

    // Xử lý permissions
    final permissionsList = <String>[];
    if (json['permissions'] is List) {
      for (final p in json['permissions']) {
        if (p is String) permissionsList.add(p);
      }
    }

    // Trích xuất thông tin hồ sơ bổ sung
    String? studentCode;
    String? currentClass;
    if (json['studentProfile'] is Map<String, dynamic>) {
      final sp = json['studentProfile'] as Map<String, dynamic>;
      studentCode = sp['studentCode'] as String?;
      if (sp['classStudents'] is List && (sp['classStudents'] as List).isNotEmpty) {
        final firstEnroll = sp['classStudents'][0];
        if (firstEnroll is Map && firstEnroll['class'] is Map) {
          currentClass = firstEnroll['class']['name'] as String?;
        }
      }
    }

    String? teacherCode;
    if (json['teacherProfile'] is Map<String, dynamic>) {
      teacherCode = json['teacherProfile']['teacherCode'] as String?;
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      isFirstLogin: json['isFirstLogin'] as bool? ?? false,
      branchId: branchId,
      branchName: branchName,
      roles: rolesList,
      permissions: permissionsList,
      gender: json['gender'] as String?,
      dateOfBirth: json['dateOfBirth']?.toString(),
      address: json['address'] as String?,
      studentCode: studentCode,
      currentClass: currentClass,
      teacherCode: teacherCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCode': userCode,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'status': status,
      'isFirstLogin': isFirstLogin,
      'branchId': branchId,
      'branchName': branchName,
      'roles': roles,
      'permissions': permissions,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'studentCode': studentCode,
      'currentClass': currentClass,
      'teacherCode': teacherCode,
    };
  }
}
