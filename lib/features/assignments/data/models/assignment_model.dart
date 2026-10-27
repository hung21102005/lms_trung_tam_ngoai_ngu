double? _parseDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class AssignmentAttachmentModel {
  final String name;
  final String url;
  final String fileType;
  final int? size;

  const AssignmentAttachmentModel({
    required this.name,
    required this.url,
    required this.fileType,
    this.size,
  });

  factory AssignmentAttachmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAttachmentModel(
      name: json['name'] as String? ?? 'Tài liệu',
      url: json['url'] as String? ?? '',
      fileType:
          (json['fileType'] ?? json['type'])?.toString().toUpperCase() ??
          'DOCUMENT',
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'fileType': fileType,
    if (size != null) 'size': size,
  };
}

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? studentName;
  final String? studentCode;
  final String? avatarUrl;
  final String? content;
  final List<AssignmentAttachmentModel> fileUrls;
  final String submittedAt;
  final double? score;
  final String? feedback;
  final String status; // SUBMITTED, GRADED, RETURNED, LATE
  final String? gradedByName;
  final String? gradedAt;
  final String? resultPublishedAt;
  final String? updatedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    this.studentName,
    this.studentCode,
    this.avatarUrl,
    this.content,
    required this.fileUrls,
    required this.submittedAt,
    this.score,
    this.feedback,
    required this.status,
    this.gradedByName,
    this.gradedAt,
    this.resultPublishedAt,
    this.updatedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>?;
    final gradedBy = json['gradedBy'] as Map<String, dynamic>?;
    final filesList = (json['fileUrls'] as List<dynamic>?) ?? [];

    return SubmissionModel(
      id: json['id'] as String? ?? '',
      assignmentId: json['assignmentId'] as String? ?? '',
      studentId: json['studentId'] as String? ?? '',
      studentName: student?['fullName'] as String?,
      studentCode: student?['userCode'] as String?,
      avatarUrl: student?['avatarUrl'] as String?,
      content: json['content'] as String?,
      fileUrls: filesList
          .whereType<Map>()
          .map(
            (e) => AssignmentAttachmentModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      submittedAt: json['submittedAt'] as String? ?? '',
      score: _parseDouble(json['score']),
      feedback: json['feedback'] as String?,
      status: json['status'] as String? ?? 'SUBMITTED',
      gradedByName: gradedBy?['fullName'] as String?,
      gradedAt: json['gradedAt'] as String?,
      resultPublishedAt: json['resultPublishedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

class AssignmentModel {
  final String id;
  final String classId;
  final String? className;
  final String? courseName;
  final String? classCode;
  final String title;
  final String? description;
  final String type; // HOMEWORK, PROJECT, SPEAKING, WRITING
  final String status;
  final String? deadline;
  final double maxScore;
  final List<AssignmentAttachmentModel> attachments;
  final String? createdByName;
  final String createdAt;
  final int totalSubmissions;
  final int gradedCount;
  final SubmissionModel? mySubmission;

  const AssignmentModel({
    required this.id,
    required this.classId,
    this.className,
    this.courseName,
    this.classCode,
    required this.title,
    this.description,
    required this.type,
    this.status = 'PUBLISHED',
    this.deadline,
    required this.maxScore,
    required this.attachments,
    this.createdByName,
    required this.createdAt,
    this.totalSubmissions = 0,
    this.gradedCount = 0,
    this.mySubmission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final createdBy = json['createdBy'] as Map<String, dynamic>?;
    final stats = json['stats'] as Map<String, dynamic>?;
    final attachmentsList = (json['attachments'] as List<dynamic>?) ?? [];
    final subJson = json['mySubmission'] as Map<String, dynamic>?;

    return AssignmentModel(
      id: json['id'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String?,
      courseName: json['courseName'] as String?,
      classCode: json['classCode'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'HOMEWORK',
      status: json['status'] as String? ?? 'PUBLISHED',
      deadline: json['deadline'] as String?,
      maxScore: _parseDouble(json['maxScore']) ?? 10.0,
      attachments: attachmentsList
          .whereType<Map>()
          .map(
            (e) => AssignmentAttachmentModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      createdByName: createdBy?['fullName'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      totalSubmissions:
          (stats?['submittedCount'] ?? stats?['totalSubmissions']) as int? ?? 0,
      gradedCount: stats?['gradedCount'] as int? ?? 0,
      mySubmission: subJson != null ? SubmissionModel.fromJson(subJson) : null,
    );
  }
}

class StudentSubmissionItemModel {
  final String studentId;
  final String userCode;
  final String fullName;
  final String? avatarUrl;
  final bool hasSubmitted;
  final SubmissionModel? submission;

  const StudentSubmissionItemModel({
    required this.studentId,
    required this.userCode,
    required this.fullName,
    this.avatarUrl,
    required this.hasSubmitted,
    this.submission,
  });

  factory StudentSubmissionItemModel.fromJson(Map<String, dynamic> json) {
    final student = json['student'] as Map<String, dynamic>? ?? {};
    final subJson = json['submission'] as Map<String, dynamic>?;

    return StudentSubmissionItemModel(
      studentId: student['id'] as String? ?? '',
      userCode: student['userCode'] as String? ?? '',
      fullName: student['fullName'] as String? ?? '',
      avatarUrl: student['avatarUrl'] as String?,
      hasSubmitted: json['hasSubmitted'] as bool? ?? false,
      submission: subJson != null ? SubmissionModel.fromJson(subJson) : null,
    );
  }
}

class AssignmentSubmissionsResponseModel {
  final String assignmentId;
  final String title;
  final String? deadline;
  final double maxScore;
  final String type;
  final int totalEnrolled;
  final int submittedCount;
  final int gradedCount;
  final int lateCount;
  final int notSubmittedCount;
  final List<StudentSubmissionItemModel> students;

  const AssignmentSubmissionsResponseModel({
    required this.assignmentId,
    required this.title,
    this.deadline,
    required this.maxScore,
    required this.type,
    required this.totalEnrolled,
    required this.submittedCount,
    required this.gradedCount,
    required this.lateCount,
    required this.notSubmittedCount,
    required this.students,
  });

  factory AssignmentSubmissionsResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final assignment = json['assignment'] as Map<String, dynamic>? ?? {};
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final list = (json['students'] as List<dynamic>?) ?? [];

    return AssignmentSubmissionsResponseModel(
      assignmentId: assignment['id'] as String? ?? '',
      title: assignment['title'] as String? ?? '',
      deadline: assignment['deadline'] as String?,
      maxScore: _parseDouble(assignment['maxScore']) ?? 10.0,
      type: assignment['type'] as String? ?? 'HOMEWORK',
      totalEnrolled: stats['totalEnrolled'] as int? ?? 0,
      submittedCount: stats['submittedCount'] as int? ?? 0,
      gradedCount: stats['gradedCount'] as int? ?? 0,
      lateCount: stats['lateCount'] as int? ?? 0,
      notSubmittedCount: stats['notSubmittedCount'] as int? ?? 0,
      students: list
          .map(
            (e) =>
                StudentSubmissionItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
