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
    super.teacherDegrees,
    super.teacherSpecialties,
    super.linkedStats = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Xử lý linh hoạt cả khi branch là object hoặc null
    String? branchId;
    String? branchName;
    if (json['branch'] is Map) {
      final b = Map<String, dynamic>.from(json['branch'] as Map);
      branchId = b['id'] as String?;
      branchName = b['name'] as String?;
    } else {
      if (json['branchId'] is String) {
        branchId = json['branchId'] as String?;
      }
      if (json['branchName'] is String) {
        branchName = json['branchName'] as String?;
      }
    }

    // Xử lý danh sách roles (chuỗi, object hoặc từ userRoles)
    final rolesList = <String>[];
    if (json['roles'] is List) {
      for (final r in json['roles']) {
        if (r is String && r.trim().isNotEmpty) {
          rolesList.add(r.trim());
        } else if (r is Map && r['code'] is String) {
          rolesList.add((r['code'] as String).trim());
        }
      }
    } else if (json['role'] is String && (json['role'] as String).trim().isNotEmpty) {
      rolesList.add((json['role'] as String).trim());
    }
    if (rolesList.isEmpty && json['userRoles'] is List) {
      for (final ur in json['userRoles']) {
        if (ur is Map) {
          final roleObj = ur['role'];
          if (roleObj is Map && roleObj['code'] is String) {
            rolesList.add((roleObj['code'] as String).trim());
          } else if (ur['code'] is String) {
            rolesList.add((ur['code'] as String).trim());
          }
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
    String? studentCode = json['studentCode'] as String?;
    String? currentClass = json['currentClass'] as String?;
    if (json['studentProfile'] is Map) {
      final sp = Map<String, dynamic>.from(json['studentProfile'] as Map);
      studentCode ??= sp['studentCode'] as String?;
      if (currentClass == null &&
          sp['classStudents'] is List &&
          (sp['classStudents'] as List).isNotEmpty) {
        final firstEnroll = sp['classStudents'][0];
        if (firstEnroll is Map && firstEnroll['class'] is Map) {
          currentClass = firstEnroll['class']['name'] as String?;
        }
      }
    }

    String? teacherCode = json['teacherCode'] as String?;
    String? teacherDegrees = json['teacherDegrees'] as String?;
    String? teacherSpecialties = json['teacherSpecialties'] as String?;
    if (json['teacherProfile'] is Map) {
      final tp = Map<String, dynamic>.from(json['teacherProfile'] as Map);
      teacherCode ??= tp['teacherCode'] as String?;
      teacherDegrees ??= tp['degrees'] as String?;
      teacherSpecialties ??= tp['specialties'] as String?;
    }

    Map<String, dynamic> linkedStats = const {};
    if (json['linkedStats'] is Map) {
      linkedStats = Map<String, dynamic>.from(json['linkedStats'] as Map);
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
      teacherDegrees: teacherDegrees,
      teacherSpecialties: teacherSpecialties,
      linkedStats: linkedStats,
    );
  }

  /// Hợp nhất thông tin với dữ liệu user trước đó nếu response thiếu roles/branch
  UserModel mergeWithFallback(UserEntity? fallback) {
    if (fallback == null) return this;
    return UserModel(
      id: id.isNotEmpty ? id : fallback.id,
      userCode: userCode.isNotEmpty ? userCode : fallback.userCode,
      fullName: fullName.isNotEmpty ? fullName : fallback.fullName,
      email: email ?? fallback.email,
      phone: phone ?? fallback.phone,
      avatarUrl: avatarUrl ?? fallback.avatarUrl,
      status: status.isNotEmpty ? status : fallback.status,
      isFirstLogin: isFirstLogin,
      branchId: branchId ?? fallback.branchId,
      branchName: branchName ?? fallback.branchName,
      roles: roles.isNotEmpty ? roles : fallback.roles,
      permissions: permissions.isNotEmpty ? permissions : fallback.permissions,
      gender: gender ?? fallback.gender,
      dateOfBirth: dateOfBirth ?? fallback.dateOfBirth,
      address: address ?? fallback.address,
      studentCode: studentCode ?? fallback.studentCode,
      currentClass: currentClass ?? fallback.currentClass,
      teacherCode: teacherCode ?? fallback.teacherCode,
      teacherDegrees: teacherDegrees ?? fallback.teacherDegrees,
      teacherSpecialties: teacherSpecialties ?? fallback.teacherSpecialties,
      linkedStats: linkedStats.isNotEmpty ? linkedStats : fallback.linkedStats,
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
      'teacherDegrees': teacherDegrees,
      'teacherSpecialties': teacherSpecialties,
      'linkedStats': linkedStats,
    };
  }
}
