class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String firstLoginSetup = '/first-login-setup';
  static const String publicHome = '/gioi-thieu';
  static const String publicCourses = '/khoa-hoc-cong-khai';
  static const String publicCourseDetail = '/khoa-hoc-cong-khai/:slug';
  static const String publicClasses = '/lop-sap-khai-giang';
  static const String publicConsultation = '/tu-van';
  static const String publicRegistration = '/dang-ky-lop/:id';

  // Role Dashboards
  static const String studentHome = '/student/home';
  static const String adminHome = '/admin/home';
  static const String teacherHome = '/teacher/home';
  static const String teacherAssignments = '/teacher/assignments';
  static const String parentHome = '/parent/home';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/change-password';

  // Courses & Curriculum
  static const String courses = '/courses';
  static const String programs = '/admin/programs';
  static const String courseDetail = '/courses/:id';

  // Classes & Scheduling
  static const String classes = '/classes';
  static const String classCreate = '/classes/create';
  static const String classDetail = '/classes/:id';
  static const String schedule = '/schedule';

  // Attendance
  static const String attendanceMark = '/sessions/:id/attendance';
  static const String myAttendance = '/attendance/my';

  // Assignments
  static const String assignments = '/assignments';
  static const String classAssignments = '/classes/:classId/assignments';
  static const String createAssignment = '/classes/:classId/assignments/create';
  static const String assignmentDetail = '/assignments/:id';
  static const String editAssignment = '/assignments/:id/edit';
  static const String submitAssignment = '/assignments/:id/submit';
  static const String gradeSubmissions = '/assignments/:id/submissions';
  static const String reviewSubmission =
      '/assignments/:id/submissions/:studentId/review';

  // Exams & Assessments
  static const String exams = '/exams';
  static const String examDetail = '/exams/:id';
  static const String createExam = '/exams/create';
  static const String takeExam = '/exams/:id/take';
  static const String examResults = '/exams/:id/results';
  static const String myExamResults = '/my-exam-results';
  static const String questionBanks = '/question-banks';

  // Finance & Payments
  static const String invoices = '/invoices';
  static const String myInvoices = '/my-invoices';
  static const String invoiceDetail = '/invoices/:id';
  static const String recordPayment = '/invoices/:id/record-payment';
  static const String payOnline = '/invoices/:id/pay-online';

  // Notifications
  static const String notifications = '/notifications';

  // Reports & Analytics
  static const String adminDashboard = '/reports/dashboard';
  static const String reportsOverview = '/reports/overview';
  static const String debtsReport = '/reports/debts';
  static const String teacherDashboard = '/teacher/dashboard';
}
