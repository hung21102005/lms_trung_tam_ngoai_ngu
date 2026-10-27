# Original User Request

## Initial Request — 2026-10-19T09:49:59Z

Xây dựng và hoàn thiện toàn diện hệ thống quản lý học tập (LMS) cho trung tâm ngoại ngữ, đồng bộ trải nghiệm đa nền tảng (Web Portal với Sidebar cố định và Mobile App trên Android với Bottom Navigation/Drawer) cho cả 3 vai trò: Admin, Giảng viên, Học viên kết nối trực tiếp với backend NestJS và PostgreSQL production-ready.

Working directory: C:\Users\Vi-Hung\my_flutter_pj\XD_HT_LMS\lms_trung_tam_ngoai_ngu
Integrity mode: development

## Requirements

### R1. Cross-Platform UI/UX Parity (Web Desktop vs Android Mobile)
Deliver a unified full-stack application supporting both Web Desktop and Android Mobile platforms according to StitchMCP project designs:
- **Web Desktop (`width > 900`)**: Full desktop workspace with a persistent 260px left sidebar (featuring all core modules, active status indicator, quick actions, and profile footer), top navigation header (search, branch/term selector, notifications, user avatar), and an adaptive content canvas without horizontal layout overflows.
- **Mobile App (`width <= 900` on Android Pixel 9)**: Native mobile UX with a top AppBar, slide-out navigation Drawer containing all modules, and a bottom navigation bar for high-frequency actions.
- Support role-specific home portals for Super Admin, Teacher, and Student.

### R2. Live Full-Stack API Integration & Role-Based Auth
- Implement JWT Bearer token authentication and role-based routing: `admin@lms-edu.vn` routes to the Admin Portal, `teacher@lms-edu.vn` routes to the Teacher Portal, and `student@lms-edu.vn` routes to the Student Portal.
- All Flutter frontend views must connect to live NestJS backend endpoints under `/api/v1/` and PostgreSQL without static mock fallbacks:
  - Users Management (`/users` with role filters)
  - Branches & Rooms (`/branches`)
  - CRM Admissions Pipeline (`/admissions/leads`)
  - Courses & Curriculum (`/courses`)
  - Classes & Scheduling (`/classes`)
  - Attendance & Session Logbooks (`/attendance`)
  - Assignments & Grading (`/assignments`)
  - Gradebook & Academic Evaluations (`/reports/academic`)
  - Financial Invoices & VNPay Payment tracking (`/finance/invoices`, `/reports/debts`)

### R3. Teacher & Student Core Workflows
- **Teacher Workflow**: View weekly teaching schedule, take real-time attendance with 4 statuses (Có mặt, Đi trễ, Phép, Không phép), log lesson topic and homework into the digital logbook (Sổ đầu bài), grade Speaking (audio recording submissions) and Writing essays with criteria rubrics, and update student gradebook scores.
- **Student Workflow**: View personal timetable, submit assignments, view digital report card and GPA ranking, and review tuition invoices with VNPay QR code payment simulation.

### R4. Automated Verification & Code Quality
- Ensure strict adherence to Flutter and NestJS best practices with zero analysis errors.
- Validate live database interactions against PostgreSQL container and verify cross-platform responsiveness on both Chrome (Web) and Pixel 9 Emulator (Android).

## Acceptance Criteria

### A. Cross-Platform Adaptation & Navigation
- [ ] On screen width > 900 (Web Chrome), Admin and Teacher portals render a persistent 260px left sidebar and responsive content canvas without layout overflows.
- [ ] On screen width <= 900 (Android Pixel 9), navigation switches to AppBar + Drawer + BottomNavigationBar with touch-friendly controls.
- [ ] Login screen correctly routes `admin@lms-edu.vn` to Admin Portal, `teacher@lms-edu.vn` to Teacher Portal, and `student@lms-edu.vn` to Student Portal.

### B. Live Backend & Business Data Flow
- [ ] All API requests use prefix `/api/v1/` and correctly attach Bearer JWT authentication tokens extracted from login responses.
- [ ] Users management view displays real paginated user lists with role filters (Student, Teacher, Staff, Parent).
- [ ] Attendance & logbook view allows marking student attendance statuses and saving session logbook.
- [ ] Assignments view enables grading submissions with scoring criteria and feedback persistence.
- [ ] Financial invoices and student debt records load from the backend without server errors.

### C. Build & Static Analysis Guardrails
- [ ] `flutter analyze` runs cleanly across all `lib/` files with 0 compile errors or broken imports.
- [ ] Backend NestJS passes `npm run build` with exit code 0.
- [ ] Docker services (`lms_postgres`, `lms_redis`) remain healthy and seeded.
