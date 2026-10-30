class AttendanceSummaryModel {
  final int totalEnrolled;
  final int markedCount;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int makeup;

  const AttendanceSummaryModel({
    required this.totalEnrolled,
    required this.markedCount,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.makeup,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      totalEnrolled: json['totalEnrolled'] as int? ?? 0,
      markedCount: json['markedCount'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      excused: json['excused'] as int? ?? 0,
      makeup: json['makeup'] as int? ?? 0,
    );
  }
}

class StudentAttendanceItemModel {
  final String studentId;
  final String userCode;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final String? email;
  final String? attendanceId;
  String? status; // PRESENT, ABSENT, LATE, EXCUSED, MAKEUP
  String? checkInTime;
  String? notes;
  final String? markedAt;

  StudentAttendanceItemModel({
    required this.studentId,
    required this.userCode,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.email,
    this.attendanceId,
    this.status,
    this.checkInTime,
    this.notes,
    this.markedAt,
  });

  factory StudentAttendanceItemModel.fromJson(Map<String, dynamic> json) {
    final rawCheckInTime = json['checkInTime']?.toString();
    return StudentAttendanceItemModel(
      studentId: json['studentId'] as String? ?? '',
      userCode: json['userCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      attendanceId: json['attendanceId'] as String?,
      status: json['status'] as String?,
      checkInTime: _formatCheckInTime(rawCheckInTime),
      notes: json['notes'] as String?,
      markedAt: json['markedAt'] as String?,
    );
  }

  static String? _formatCheckInTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toBatchItemJson() {
    return {
      'studentId': studentId,
      'status': status ?? 'PRESENT',
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

class SessionAttendanceResponseModel {
  final String sessionId;
  final String classId;
  final String className;
  final String classCode;
  final int sessionNumber;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? roomName;
  final String? roomCode;
  final AttendanceSummaryModel summary;
  final List<StudentAttendanceItemModel> students;

  const SessionAttendanceResponseModel({
    required this.sessionId,
    required this.classId,
    required this.className,
    required this.classCode,
    required this.sessionNumber,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.roomName,
    this.roomCode,
    required this.summary,
    required this.students,
  });

  factory SessionAttendanceResponseModel.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>? ?? {};
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final studentsList = (json['students'] as List<dynamic>?) ?? [];
    final room = session['room'] as Map<String, dynamic>?;

    return SessionAttendanceResponseModel(
      sessionId: session['id'] as String? ?? '',
      classId: session['classId'] as String? ?? '',
      className: session['className'] as String? ?? '',
      classCode: session['classCode'] as String? ?? '',
      sessionNumber: session['sessionNumber'] as int? ?? 1,
      title: session['title'] as String? ?? '',
      date: session['date'] as String? ?? '',
      startTime: session['startTime'] as String? ?? '',
      endTime: session['endTime'] as String? ?? '',
      status: session['status'] as String? ?? '',
      roomName: room?['name'] as String?,
      roomCode: room?['code'] as String?,
      summary: AttendanceSummaryModel.fromJson(summaryJson),
      students: studentsList
          .map(
            (e) =>
                StudentAttendanceItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class StudentAttendanceHistorySummary {
  final int totalSessions;
  final int present;
  final int late;
  final int absent;
  final int excused;
  final int makeup;
  final double attendanceRate;

  const StudentAttendanceHistorySummary({
    required this.totalSessions,
    required this.present,
    required this.late,
    required this.absent,
    required this.excused,
    required this.makeup,
    required this.attendanceRate,
  });

  factory StudentAttendanceHistorySummary.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceHistorySummary(
      totalSessions: json['totalSessions'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      excused: json['excused'] as int? ?? 0,
      makeup: json['makeup'] as int? ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble() ?? 100.0,
    );
  }
}

class StudentAttendanceRecordModel {
  final String id;
  final String status;
  final String? checkInTime;
  final String? notes;
  final String markedAt;
  final String sessionTitle;
  final int sessionNumber;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String className;
  final String classCode;

  const StudentAttendanceRecordModel({
    required this.id,
    required this.status,
    this.checkInTime,
    this.notes,
    required this.markedAt,
    required this.sessionTitle,
    required this.sessionNumber,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.className,
    required this.classCode,
  });

  factory StudentAttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>? ?? {};
    final classMap = session['class'] as Map<String, dynamic>? ?? {};

    return StudentAttendanceRecordModel(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'PRESENT',
      checkInTime: json['checkInTime'] as String?,
      notes: json['notes'] as String?,
      markedAt: json['markedAt'] as String? ?? '',
      sessionTitle: session['title'] as String? ?? '',
      sessionNumber: session['sessionNumber'] as int? ?? 1,
      sessionDate: session['date'] as String? ?? '',
      startTime: session['startTime'] as String? ?? '',
      endTime: session['endTime'] as String? ?? '',
      className: classMap['name'] as String? ?? '',
      classCode: classMap['code'] as String? ?? '',
    );
  }
}

class StudentAttendanceHistoryResponseModel {
  final StudentAttendanceHistorySummary summary;
  final List<StudentAttendanceRecordModel> records;

  const StudentAttendanceHistoryResponseModel({
    required this.summary,
    required this.records,
  });

  factory StudentAttendanceHistoryResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final recordsList = (json['records'] as List<dynamic>?) ?? [];

    return StudentAttendanceHistoryResponseModel(
      summary: StudentAttendanceHistorySummary.fromJson(summaryJson),
      records: recordsList
          .map(
            (e) => StudentAttendanceRecordModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class MakeupRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String originalSessionTitle;
  final String originalSessionDate;
  final String? targetSessionTitle;
  final String? targetSessionDate;
  final String status; // PENDING, APPROVED, REJECTED, COMPLETED
  final String? reason;
  final String createdAt;

  const MakeupRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.originalSessionTitle,
    required this.originalSessionDate,
    this.targetSessionTitle,
    this.targetSessionDate,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory MakeupRequestModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? {};
    final orig = json['originalSession'] as Map<String, dynamic>? ?? {};
    final target = json['targetSession'] as Map<String, dynamic>?;

    return MakeupRequestModel(
      id: json['id'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: student['fullName'] as String? ?? '',
      originalSessionTitle: orig['title'] as String? ?? '',
      originalSessionDate: orig['date'] as String? ?? '',
      targetSessionTitle: target?['title'] as String?,
      targetSessionDate: target?['date'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
