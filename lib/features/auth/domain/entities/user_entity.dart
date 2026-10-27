import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String userCode;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String status;
  final bool isFirstLogin;
  final String? branchId;
  final String? branchName;
  final List<String> roles;
  final List<String> permissions;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? studentCode;
  final String? currentClass;
  final String? teacherCode;

  const UserEntity({
    required this.id,
    required this.userCode,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.status,
    required this.isFirstLogin,
    this.branchId,
    this.branchName,
    required this.roles,
    required this.permissions,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.studentCode,
    this.currentClass,
    this.teacherCode,
  });

  bool get isSuperAdmin => roles.contains('super_admin');
  bool get isBranchAdmin => roles.contains('branch_admin');
  bool get isAcademicStaff => roles.contains('academic_staff');
  bool get isTeacher => roles.contains('teacher') || roles.contains('teaching_assistant');
  bool get isStudent => roles.contains('student');
  bool get isParent => roles.contains('parent');

  @override
  List<Object?> get props => [
        id,
        userCode,
        fullName,
        email,
        phone,
        avatarUrl,
        status,
        isFirstLogin,
        branchId,
        branchName,
        roles,
        permissions,
        gender,
        dateOfBirth,
        address,
        studentCode,
        currentClass,
        teacherCode,
      ];
}
