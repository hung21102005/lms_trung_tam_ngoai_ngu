import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  /// Địa chỉ base URL của Backend:
  /// - Web / Windows: http://localhost:3000/api
  /// - Android Emulator: http://10.0.2.2:3000/api
  /// - Thiết bị thật: thay bằng IP mạng LAN máy dev
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 trỏ về localhost máy tính host khi chạy trên Android Emulator
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  // --- AUTH ENDPOINTS ---
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String getMe = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String uploadFile = '/upload';
  static const String firstLoginSetup = '/auth/first-login-setup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // --- USERS ENDPOINTS ---
  static const String users = '/users';
  static const String createStudent = '/users/students';
  static const String createParent = '/users/parents';
  static const String createStaff = '/users/staff';
  static const String importUsers = '/users/import';

  static String userDetail(String id) => '/users/$id';
  static String updateUserStatus(String id) => '/users/$id/status';
  static String adminResetPassword(String id) => '/users/$id/reset-password';
  static String userRoles(String id) => '/users/$id/roles';

  // --- PROFILE ENDPOINTS ---
  static const String updateProfile = '/users/profile/me';

  // --- BRANCHES & ROOMS ---
  static const String branches = '/branches';
  static const String rooms = '/rooms';
  static String branchDetail(String id) => '/branches/$id';
  static String branchRooms(String branchId) => '/branches/$branchId/rooms';
  static String roomDetail(String id) => '/rooms/$id';

  // --- ADMISSIONS & LEADS ---
  static const String leads = '/admissions/leads';
  static String leadDetail(String id) => '/admissions/leads/$id';
  static String convertLead(String id) => '/admissions/leads/$id/convert';

  // --- COURSES & CURRICULUM ---
  static const String courses = '/courses';
  static String courseDetail(String id) => '/courses/$id';
  static String courseLevels(String courseId) => '/courses/$courseId/levels';
  static String levelModules(String levelId) => '/levels/$levelId/modules';
  static String moduleLessons(String moduleId) => '/modules/$moduleId/lessons';
  static String lessonMaterials(String lessonId) =>
      '/lessons/$lessonId/materials';

  // --- CLASSES & SCHEDULING ---
  static const String classes = '/classes';
  static String classDetail(String id) => '/classes/$id';
  static String classStudents(String classId) => '/classes/$classId/students';
  static String classStudentDelete(String classId, String studentId) =>
      '/classes/$classId/students/$studentId';
  static String classSessions(String classId) => '/classes/$classId/sessions';
  static String updateSession(String sessionId) => '/sessions/$sessionId';
  static const String myClasses = '/my/classes';
  static const String mySchedule = '/my/schedule';

  // --- ATTENDANCE & MAKEUP ---
  static String sessionAttendance(String sessionId) =>
      '/sessions/$sessionId/attendance';
  static String updateAttendance(String id) => '/attendance/$id';
  static String studentAttendance(String studentId) =>
      '/students/$studentId/attendance';
  static String classAttendanceSummary(String classId) =>
      '/classes/$classId/attendance-summary';
  static const String makeupRequests = '/makeup-requests';
  static String makeupRequestDetail(String id) => '/makeup-requests/$id';

  // --- ASSIGNMENTS & SUBMISSIONS ---
  static String classAssignments(String classId) =>
      '/classes/$classId/assignments';
  static const String assignments = '/assignments';
  static String assignmentDetail(String id) => '/assignments/$id';
  static String submitAssignment(String assignmentId) =>
      '/assignments/$assignmentId/submit';
  static String saveAssignmentDraft(String assignmentId) =>
      '/assignments/$assignmentId/draft';
  static String assignmentSubmissions(String assignmentId) =>
      '/assignments/$assignmentId/submissions';
  static String gradeSubmission(String submissionId) =>
      '/submissions/$submissionId/grade';
  static String publishSubmissionResult(String submissionId) =>
      '/submissions/$submissionId/publish';
  static String returnSubmission(String submissionId) =>
      '/submissions/$submissionId/return';

  // --- EXAMS & QUESTION BANKS ---
  static const String questionBanks = '/question-banks';
  static String questionBankDetail(String id) => '/question-banks/$id';
  static String questionBankQuestions(String id) =>
      '/question-banks/$id/questions';
  static String importQuestions(String bankId) =>
      '/question-banks/$bankId/questions/import';
  static String questionDetail(String id) => '/questions/$id';
  static const String exams = '/exams';
  static String examDetail(String id) => '/exams/$id';
  static String startExam(String examId) => '/exams/$examId/start';
  static String saveExamAnswers(String attemptId) =>
      '/exam-attempts/$attemptId/answers';
  static String submitExam(String examId) => '/exams/$examId/submit';
  static String examResults(String examId) => '/exams/$examId/results';
  static const String myExamResults = '/my/exam-results';
  static String gradeExamAnswer(String answerId) =>
      '/exam-answers/$answerId/grade';

  // --- FINANCE & PAYMENTS ---
  static const String invoices = '/finance/invoices';
  static const String myInvoices = '/finance/my-invoices';
  static String invoiceDetail(String id) => '/finance/invoices/$id';
  static String recordPayment(String invoiceId) =>
      '/finance/invoices/$invoiceId/payments';
  static String cancelInvoice(String invoiceId) =>
      '/finance/invoices/$invoiceId/cancel';
  static String refundInvoice(String invoiceId) =>
      '/finance/invoices/$invoiceId/refund';
  static String payOnline(String invoiceId) =>
      '/finance/invoices/$invoiceId/pay-online';
  static const String promotions = '/finance/promotions';
  static const String validatePromotion = '/finance/promotions/validate';

  // --- NOTIFICATIONS ---
  static const String notifications = '/notifications';
  static const String myNotifications = '/my/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
  static String markNotificationAsRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsAsRead = '/notifications/read-all';
  static const String updateFcmToken = '/notifications/fcm-token';
  static const String sendNotification = '/notifications/send';

  // --- REPORTS & ANALYTICS ---
  static const String reportsDashboard = '/reports/dashboard';
  static const String reportsRevenue = '/reports/revenue';
  static const String reportsAttendance = '/reports/attendance';
  static const String reportsAcademic = '/reports/academic';
  static const String reportsDebts = '/reports/debts';
  static const String reportsTeacherWorkload = '/reports/teacher-workload';
  static String reportsExport(String type) => '/reports/export/$type';
  static const String refreshDashboardCache =
      '/reports/dashboard/refresh-cache';
}
