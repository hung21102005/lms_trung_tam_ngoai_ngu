import 'package:equatable/equatable.dart';

class ClassModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String courseId;
  final String? courseTitle;
  final String? courseCode;
  final String levelId;
  final String? levelName;
  final String branchId;
  final String? branchName;
  final String? roomId;
  final String? roomName;
  final int? roomCapacity;
  final String? mainTeacherId;
  final String? mainTeacherName;
  final String? mainTeacherCode;
  final String? mainTeacherAvatar;
  final String? assistantTeacherId;
  final String? assistantTeacherName;
  final String status; // PLANNING, OPEN_FOR_ENROLLMENT, IN_PROGRESS, COMPLETED, CANCELLED
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> scheduleDays;
  final String startTime;
  final String endTime;
  final int totalSessions;
  final int maxCapacity;
  final double tuitionFee;
  final DateTime? registrationOpenAt;
  final DateTime? registrationCloseAt;
  final String? notes;
  final int studentsCount;
  final int sessionsCount;
  final List<ClassStudentModel> students;
  final List<ClassSessionModel> sessions;

  const ClassModel({
    required this.id,
    required this.code,
    required this.name,
    required this.courseId,
    this.courseTitle,
    this.courseCode,
    required this.levelId,
    this.levelName,
    required this.branchId,
    this.branchName,
    this.roomId,
    this.roomName,
    this.roomCapacity,
    this.mainTeacherId,
    this.mainTeacherName,
    this.mainTeacherCode,
    this.mainTeacherAvatar,
    this.assistantTeacherId,
    this.assistantTeacherName,
    this.status = 'PLANNING',
    this.startDate,
    this.endDate,
    this.scheduleDays = const [],
    required this.startTime,
    required this.endTime,
    this.totalSessions = 24,
    this.maxCapacity = 20,
    this.tuitionFee = 0,
    this.registrationOpenAt,
    this.registrationCloseAt,
    this.notes,
    this.studentsCount = 0,
    this.sessionsCount = 0,
    this.students = const [],
    this.sessions = const [],
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>?;
    final level = json['level'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
    final room = json['room'] as Map<String, dynamic>?;
    final teacher = json['mainTeacher'] as Map<String, dynamic>?;
    final assistant = json['assistantTeacher'] as Map<String, dynamic>?;

    final counts = json['_count'] as Map<String, dynamic>?;
    final sCount = counts?['students'] as int? ?? 0;
    final sessCount = counts?['sessions'] as int? ?? 0;

    List<ClassStudentModel> parsedStudents = [];
    if (json['students'] is List) {
      parsedStudents = (json['students'] as List)
          .map((s) => ClassStudentModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    List<ClassSessionModel> parsedSessions = [];
    if (json['sessions'] is List) {
      parsedSessions = (json['sessions'] as List)
          .map((s) => ClassSessionModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    List<String> parsedDays = [];
    if (json['scheduleDays'] is List) {
      parsedDays = (json['scheduleDays'] as List).map((d) => d.toString()).toList();
    }

    return ClassModel(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      courseId: json['courseId'] as String? ?? (course?['id'] as String? ?? ''),
      courseTitle: course?['title'] as String?,
      courseCode: course?['code'] as String?,
      levelId: json['levelId'] as String? ?? (level?['id'] as String? ?? ''),
      levelName: level?['name'] as String?,
      branchId: json['branchId'] as String? ?? (branch?['id'] as String? ?? ''),
      branchName: branch?['name'] as String?,
      roomId: json['roomId'] as String? ?? (room?['id'] as String?),
      roomName: room?['name'] as String? ?? room?['code'] as String?,
      roomCapacity: room?['capacity'] as int?,
      mainTeacherId: json['mainTeacherId'] as String? ?? (teacher?['id'] as String?),
      mainTeacherName: teacher?['fullName'] as String?,
      mainTeacherCode: teacher?['userCode'] as String?,
      mainTeacherAvatar: teacher?['avatarUrl'] as String?,
      assistantTeacherId: json['assistantTeacherId'] as String? ?? (assistant?['id'] as String?),
      assistantTeacherName: assistant?['fullName'] as String?,
      status: json['status'] as String? ?? 'PLANNING',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      scheduleDays: parsedDays,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      totalSessions: json['totalSessions'] as int? ?? 24,
      maxCapacity: json['maxCapacity'] as int? ?? 20,
      tuitionFee: json['tuitionFee'] != null ? double.tryParse(json['tuitionFee'].toString()) ?? 0.0 : 0.0,
      registrationOpenAt: json['registrationOpenAt'] != null
          ? DateTime.tryParse(json['registrationOpenAt'].toString()) : null,
      registrationCloseAt: json['registrationCloseAt'] != null
          ? DateTime.tryParse(json['registrationCloseAt'].toString()) : null,
      notes: json['notes'] as String?,
      studentsCount: parsedStudents.isNotEmpty ? parsedStudents.length : sCount,
      sessionsCount: parsedSessions.isNotEmpty ? parsedSessions.length : sessCount,
      students: parsedStudents,
      sessions: parsedSessions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        courseId,
        levelId,
        branchId,
        roomId,
        mainTeacherId,
        status,
        startDate,
        endDate,
        scheduleDays,
        startTime,
        endTime,
        totalSessions,
        maxCapacity,
        tuitionFee,
        registrationOpenAt,
        registrationCloseAt,
        studentsCount,
        sessionsCount,
      ];
}

class ClassStudentModel extends Equatable {
  final String id;
  final String classId;
  final String studentId;
  final String? studentName;
  final String? studentCode;
  final String? studentEmail;
  final String? studentPhone;
  final String? studentAvatar;
  final String status; // ENROLLED, RESERVED, DROPPED_OUT, COMPLETED
  final DateTime? joinedAt;
  final double tuitionPaid;
  final String? notes;

  const ClassStudentModel({
    required this.id,
    required this.classId,
    required this.studentId,
    this.studentName,
    this.studentCode,
    this.studentEmail,
    this.studentPhone,
    this.studentAvatar,
    this.status = 'ENROLLED',
    this.joinedAt,
    this.tuitionPaid = 0,
    this.notes,
  });

  factory ClassStudentModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;

    return ClassStudentModel(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? (student?['id'] as String? ?? ''),
      studentName: student?['fullName'] as String?,
      studentCode: student?['userCode'] as String?,
      studentEmail: student?['email'] as String?,
      studentPhone: student?['phone'] as String?,
      studentAvatar: student?['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'ENROLLED',
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'].toString()) : null,
      tuitionPaid: json['tuitionPaid'] != null ? double.tryParse(json['tuitionPaid'].toString()) ?? 0.0 : 0.0,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        studentId,
        studentName,
        studentCode,
        status,
        joinedAt,
        tuitionPaid,
      ];
}

class ClassSessionModel extends Equatable {
  final String id;
  final String classId;
  final String? classCode;
  final String? className;
  final String? courseTitle;
  final String? branchName;
  final String? lessonId;
  final String? lessonTitle;
  final int sessionNumber;
  final String title;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String? roomId;
  final String? roomName;
  final String? roomCode;
  final String? teacherId;
  final String? teacherName;
  final String? teacherCode;
  final String status; // SCHEDULED, COMPLETED, CANCELLED, RESCHEDULED
  final String? notes;

  const ClassSessionModel({
    required this.id,
    required this.classId,
    this.classCode,
    this.className,
    this.courseTitle,
    this.branchName,
    this.lessonId,
    this.lessonTitle,
    this.sessionNumber = 1,
    required this.title,
    this.date,
    required this.startTime,
    required this.endTime,
    this.roomId,
    this.roomName,
    this.roomCode,
    this.teacherId,
    this.teacherName,
    this.teacherCode,
    this.status = 'SCHEDULED',
    this.notes,
  });

  factory ClassSessionModel.fromJson(Map<String, dynamic> json) {
    final classObj = json['class'] as Map<String, dynamic>?;
    final room = json['room'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;
    final lesson = json['lesson'] as Map<String, dynamic>?;
    final course = classObj?['course'] as Map<String, dynamic>?;
    final branch = classObj?['branch'] as Map<String, dynamic>?;

    return ClassSessionModel(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? (classObj?['id'] as String? ?? ''),
      classCode: classObj?['code'] as String?,
      className: classObj?['name'] as String?,
      courseTitle: course?['title'] as String?,
      branchName: branch?['name'] as String?,
      lessonId: json['lessonId'] as String? ?? (lesson?['id'] as String?),
      lessonTitle: lesson?['title'] as String?,
      sessionNumber: json['sessionNumber'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      roomId: json['roomId'] as String? ?? (room?['id'] as String?),
      roomName: room?['name'] as String?,
      roomCode: room?['code'] as String?,
      teacherId: json['teacherId'] as String? ?? (teacher?['id'] as String?),
      teacherName: teacher?['fullName'] as String?,
      teacherCode: teacher?['userCode'] as String?,
      status: json['status'] as String? ?? 'SCHEDULED',
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        sessionNumber,
        title,
        date,
        startTime,
        endTime,
        roomId,
        teacherId,
        status,
      ];
}
