import 'package:equatable/equatable.dart';
import '../../../../core/router/route_names.dart';

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
  final String? teacherDegrees;
  final String? teacherSpecialties;
  final Map<String, dynamic> linkedStats;

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
    this.teacherDegrees,
    this.teacherSpecialties,
    this.linkedStats = const {},
  });

  bool _hasRole(String code) =>
      roles.any((r) => r.trim().toLowerCase() == code.toLowerCase());

  bool get isSuperAdmin => _hasRole('super_admin');
  bool get isBranchAdmin => _hasRole('branch_admin');
  bool get isAcademicStaff => _hasRole('academic_staff');
  bool get isCashier => _hasRole('cashier');
  bool get isTeacher => _hasRole('teacher') || _hasRole('teaching_assistant');
  bool get isStudent => _hasRole('student');
  bool get isParent => _hasRole('parent');

  bool get hasValidRole =>
      isSuperAdmin ||
      isBranchAdmin ||
      isAcademicStaff ||
      isCashier ||
      isTeacher ||
      isParent ||
      isStudent;

  /// Trả về route dashboard chuẩn xác theo vai trò đã xác thực.
  /// TUYỆT ĐỐI KHÔNG fallback về [RouteNames.studentHome] khi chưa xác định được role.
  String? get dashboardRoute {
    if (isSuperAdmin || isBranchAdmin || isAcademicStaff || isCashier) {
      return RouteNames.adminHome;
    }
    if (isTeacher) {
      return RouteNames.teacherHome;
    }
    if (isParent) {
      return RouteNames.parentHome;
    }
    if (isStudent) {
      return RouteNames.studentHome;
    }
    return null;
  }

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
        teacherDegrees,
        teacherSpecialties,
        linkedStats,
      ];
}
