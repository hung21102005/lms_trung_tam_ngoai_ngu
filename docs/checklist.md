# ✅ CHECKLIST DỰ ÁN LMS TRUNG TÂM NGOẠI NGỮ

> **Tiến độ tổng:** 0 / 280 tasks
> **Cập nhật lần cuối:** 2026-09-27
>
> Đánh dấu `[x]` khi hoàn thành. Cập nhật tiến độ tổng sau mỗi lần review.

---

## 📋 HƯỚNG DẪN SỬ DỤNG

| Ký hiệu | Ý nghĩa |
|:---|:---|
| `[ ]` | Chưa làm |
| `[x]` | Đã hoàn thành |
| `🔴` | Blocker / Ưu tiên cao |
| `🟡` | Quan trọng |
| `🟢` | Nice-to-have / Có thể làm sau |
| `[BE]` | Backend task |
| `[FE]` | Frontend task |
| `[DB]` | Database task |
| `[OPS]` | DevOps / Infra task |
| `[QA]` | Testing task |

---

## PHASE 0: CHUẨN BỊ MÔI TRƯỜNG (Trước khi code)

### Cài đặt công cụ

- [x] 🔴 Cài đặt Node.js (v24.13.0)
- [x] 🔴 Cài đặt Flutter SDK (v3.47.2 / Dart 3.13.2)
- [x] 🔴 Cài đặt PostgreSQL 16 (chạy qua Docker Compose)
- [x] 🔴 Cài đặt Redis 7 (chạy qua Docker Compose)
- [x] 🔴 Cài đặt Docker Desktop (v29.7.2 & Compose v5.5.1)
- [x] 🟡 Cài đặt công cụ quản trị DB (Adminer chạy qua Docker tại localhost:8080)
- [ ] 🟡 Cài đặt Postman / Insomnia (test API)
- [x] 🔴 Cài đặt Git (v2.51.1)

### Tạo tài khoản & dịch vụ

- [ ] 🔴 Tạo Firebase Project trên Firebase Console
- [ ] 🔴 Bật Firebase Cloud Messaging (FCM)
- [ ] 🔴 Bật Firebase Storage
- [ ] 🔴 Tải `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
- [ ] 🔴 Tải Firebase Admin SDK service account key (cho Backend)
- [ ] 🟡 Đăng ký tài khoản VNPay Sandbox (test thanh toán)
- [ ] 🟢 Đăng ký SendGrid / cấu hình Gmail App Password (gửi email)
- [ ] 🟢 Đăng ký SMS Gateway (Twilio / eSMS / Viettel)

### Khởi tạo dự án

- [x] 🔴 Tạo Git repository
- [x] 🔴 Setup `.gitignore` monorepo cho Flutter + Node.js + Docker
- [x] 🔴 Tạo nhánh `develop` từ `main`
- [ ] 🔴 Viết `README.md` cơ bản cho dự án

---

## PHASE 1: FOUNDATION — NỀN TẢNG (Tuần 1–3)

> **Mục tiêu:** Project skeleton, xác thực JWT, RBAC, CRUD users/branches/rooms.

### 1.1 Backend — Khởi tạo NestJS

- [x] 🔴 `[BE]` Khởi tạo NestJS project (`nest new backend`)
- [x] 🔴 `[BE]` Cấu hình TypeScript strict mode
- [ ] 🔴 `[BE]` Cài đặt và cấu hình Prisma ORM
- [ ] 🔴 `[BE]` Cấu hình kết nối PostgreSQL (`database.config.ts`)
- [ ] 🔴 `[BE]` Cấu hình Redis (`redis.config.ts`)
- [ ] 🟡 `[BE]` Cấu hình Firebase Admin SDK (`firebase.config.ts`)
- [ ] 🔴 `[BE]` Setup cấu trúc thư mục: `config/`, `common/`, `modules/`, `database/`
- [ ] 🔴 `[BE]` Tạo Global Exception Filter (`http-exception.filter.ts`)
- [ ] 🔴 `[BE]` Tạo Response Transform Interceptor (chuẩn hóa response JSON)
- [ ] 🔴 `[BE]` Tạo Validation Pipe (class-validator)
- [ ] 🟡 `[BE]` Tạo Logging Interceptor
- [ ] 🔴 `[BE]` Setup Swagger/OpenAPI documentation

### 1.2 Database — Schema & Migration đầu tiên

- [ ] 🔴 `[DB]` Viết Prisma schema: model `Branch`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `Room`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `User`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `Role`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `Permission`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `UserRole`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `RolePermission`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `StudentProfile`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `TeacherProfile`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `ParentStudent`
- [ ] 🔴 `[DB]` Viết Prisma schema: model `AdmissionLead` (tiếp nhận đăng ký tư vấn)
- [ ] 🔴 `[DB]` Chạy migration đầu tiên (`prisma migrate dev`)
- [ ] 🔴 `[DB]` Seed roles mặc định (super_admin, branch_admin, academic_staff, cashier, teacher, teaching_assistant, student, parent)
- [ ] 🔴 `[DB]` Seed permissions mặc định (~40 permissions)
- [ ] 🔴 `[DB]` Seed tài khoản Super Admin mặc định
- [ ] 🟡 `[DB]` Seed dữ liệu mẫu: 1 branch, 2 rooms, vài users

### 1.3 Backend — Module Auth & First-time Activation

- [ ] 🔴 `[BE]` Tạo `auth.module.ts`
- [ ] 🔴 `[BE]` Implement JWT Strategy (`jwt.strategy.ts`)
- [ ] 🔴 `[BE]` Implement `JwtAuthGuard`
- [ ] 🔴 `[BE]` Implement `RolesGuard` + `@Roles()` decorator
- [ ] 🔴 `[BE]` Implement `@CurrentUser()` decorator
- [ ] 🔴 `[BE]` API: `POST /auth/login` (email/phone/mã tài khoản + password → JWT)
- [ ] 🔴 `[BE]` API: `POST /auth/first-login-setup` (kích hoạt & đổi mật khẩu lần đầu)
- [ ] 🔴 `[BE]` API: `POST /auth/refresh` (refresh token → new access token)
- [ ] 🔴 `[BE]` API: `GET /auth/me` (thông tin user hiện tại)
- [ ] 🔴 `[BE]` API: `POST /auth/change-password`
- [ ] 🟡 `[BE]` API: `POST /auth/forgot-password` (gửi OTP email/SMS)
- [ ] 🟡 `[BE]` API: `POST /auth/reset-password` (reset bằng OTP)
- [ ] 🟢 `[BE]` API: `POST /auth/google` (liên kết OAuth2 với tài khoản đã cấp)
- [ ] 🔴 `[BE]` Hash password với bcrypt (salt rounds = 12)
- [ ] 🔴 `[BE]` Validate input DTO (class-validator)

### 1.4 Backend — Module Admissions & Leads (Tuyển sinh & Tư vấn)

- [ ] 🔴 `[BE]` API: `POST /admissions/leads` (Public — gửi đăng ký nhu cầu học tập)
- [ ] 🔴 `[BE]` API: `GET /admissions/leads` (Học vụ xem & lọc danh sách tư vấn)
- [ ] 🔴 `[BE]` API: `PATCH /admissions/leads/:id` (Cập nhật tiến trình tư vấn, hẹn test)
- [ ] 🔴 `[BE]` API: `POST /admissions/leads/:id/convert` (Chuyển đổi lead thành học viên chính thức & cấp tài khoản)

### 1.5 Backend — Module Users & Cấp phát tài khoản

- [ ] 🔴 `[BE]` Tạo `users.module.ts`
- [ ] 🔴 `[BE]` API: `GET /users` (phân trang, search, filter by role/branch/class)
- [ ] 🔴 `[BE]` API: `GET /users/:id` (chi tiết user + profile)
- [ ] 🔴 `[BE]` API: `POST /users/students` (Admin/Học vụ tạo tài khoản học viên kèm lớp)
- [ ] 🔴 `[BE]` API: `POST /users/parents` (Admin/Học vụ tạo tài khoản phụ huynh kèm liên kết con)
- [ ] 🔴 `[BE]` API: `POST /users/staff` (Admin tạo tài khoản giáo viên/nhân viên)
- [ ] 🔴 `[BE]` API: `PATCH /users/:id` (cập nhật user)
- [ ] 🔴 `[BE]` API: `PATCH /users/:id/status` (khóa / mở khóa tài khoản)
- [ ] 🔴 `[BE]` API: `POST /users/:id/reset-password` (Admin cấp lại mật khẩu tạm thời)
- [ ] 🟡 `[BE]` API: `POST /users/import` (import Excel danh sách học viên)
- [ ] 🔴 `[BE]` API: `GET /users/:id/roles` (lấy roles)
- [ ] 🔴 `[BE]` API: `POST /users/:id/roles` (gán role)

### 1.5 Backend — Module Branches & Rooms

- [ ] 🔴 `[BE]` API: `GET /branches` — danh sách chi nhánh
- [ ] 🔴 `[BE]` API: `POST /branches` — tạo chi nhánh
- [ ] 🔴 `[BE]` API: `PATCH /branches/:id` — cập nhật
- [ ] 🔴 `[BE]` API: `GET /branches/:id/rooms` — phòng theo chi nhánh
- [ ] 🔴 `[BE]` API: `POST /rooms` — tạo phòng
- [ ] 🔴 `[BE]` API: `PATCH /rooms/:id` — cập nhật phòng

### 1.6 Frontend — Setup Flutter

- [ ] 🔴 `[FE]` Tạo cấu trúc thư mục: `core/`, `features/`, `shared/`
- [ ] 🔴 `[FE]` Cấu hình `pubspec.yaml` (thêm dependencies Phase 1)
- [ ] 🔴 `[FE]` Setup theme (`app_theme.dart` — colors, typography, dark mode)
- [ ] 🔴 `[FE]` Setup routing (`go_router` + `app_router.dart`)
- [ ] 🔴 `[FE]` Setup DI container (`get_it` + `injectable`)
- [ ] 🔴 `[FE]` Setup API client (`dio` + `api_client.dart`)
- [ ] 🔴 `[FE]` Tạo API interceptor (auto-attach JWT, auto-refresh token)
- [ ] 🔴 `[FE]` Setup secure storage (`flutter_secure_storage`)
- [ ] 🔴 `[FE]` Setup BLoC pattern (`flutter_bloc`)
- [ ] 🔴 `[FE]` Tạo `api_endpoints.dart` (constants)
- [ ] 🔴 `[FE]` Tạo `api_response.dart` (generic response wrapper)
- [ ] 🔴 `[FE]` Tạo `api_exception.dart` (error handling)

### 1.7 Frontend — Shared Widgets

- [ ] 🔴 `[FE]` Widget: `AppButton` (primary, secondary, outline, loading state)
- [ ] 🔴 `[FE]` Widget: `AppTextField` (text, password, search, multiline)
- [ ] 🔴 `[FE]` Widget: `AppCard`
- [ ] 🔴 `[FE]` Widget: `AppDialog` (confirm, alert, custom)
- [ ] 🔴 `[FE]` Widget: `LoadingWidget` (spinner, skeleton shimmer)
- [ ] 🔴 `[FE]` Widget: `EmptyStateWidget`
- [ ] 🔴 `[FE]` Widget: `ErrorWidget` (retry button)
- [ ] 🟡 `[FE]` Widget: `AppDropdown`
- [ ] 🟡 `[FE]` Widget: `AppDatePicker`
- [ ] 🟡 `[FE]` Widget: `PaginatedListView`

### 1.8 Frontend — Feature Auth

- [ ] 🔴 `[FE]` Tạo `AuthBloc` (events: Login, Logout, CheckAuth, RefreshToken)
- [ ] 🔴 `[FE]` Tạo `AuthRepository` (interface + implementation)
- [ ] 🔴 `[FE]` Tạo `LoginUseCase`
- [ ] 🔴 `[FE]` UI: `LoginScreen` (email/phone + password)
- [ ] 🔴 `[FE]` UI: `LoginForm` widget (validation, loading state)
- [ ] 🟡 `[FE]` UI: `ForgotPasswordScreen`
- [ ] 🟢 `[FE]` UI: Social login buttons (Google, Facebook)
- [ ] 🔴 `[FE]` Logic: lưu JWT vào secure storage sau login
- [ ] 🔴 `[FE]` Logic: auto-navigate theo role sau login (student→student dashboard, admin→admin dashboard)
- [ ] 🔴 `[FE]` Logic: auto-logout khi token hết hạn + refresh fail
- [ ] 🔴 `[FE]` UI: Splash screen (check auth state)

### 1.9 Frontend — Feature Profile

- [ ] 🔴 `[FE]` UI: `ProfileScreen` (xem thông tin cá nhân)
- [ ] 🟡 `[FE]` UI: `EditProfileScreen` (sửa tên, SĐT, avatar)
- [ ] 🟡 `[FE]` UI: `ChangePasswordScreen`
- [ ] 🟡 `[FE]` Upload avatar (image_picker → gửi lên backend)

### 1.10 DevOps — Phase 1

- [ ] 🔴 `[OPS]` Viết `docker-compose.yml` (PostgreSQL + Redis)
- [ ] 🔴 `[OPS]` Viết `.env.example` + `.env` cho backend
- [ ] 🔴 `[OPS]` Viết `Dockerfile` cho backend
- [ ] 🟡 `[OPS]` Setup ESLint + Prettier cho backend
- [ ] 🟡 `[OPS]` Setup `analysis_options.yaml` cho Flutter (lint rules)

### 1.11 Testing — Phase 1

- [ ] 🟡 `[QA]` Unit test: AuthService (login, hash password, JWT generation)
- [ ] 🟡 `[QA]` Unit test: RolesGuard
- [ ] 🟡 `[QA]` E2E test: POST /auth/login, GET /auth/me
- [ ] 🟡 `[QA]` Widget test: LoginScreen, LoginForm

### ✅ Milestone Phase 1

- [ ] Đăng nhập được trên app Flutter → nhận JWT → gọi API thành công
- [ ] Admin tạo được user, gán role, tạo branch/room qua Swagger
- [ ] Docker Compose chạy PostgreSQL + Redis + Backend local thành công

---

## PHASE 2: CORE ACADEMIC — NGHIỆP VỤ HỌC THUẬT (Tuần 4–6)

> **Mục tiêu:** Quản lý khóa học, lớp học, xếp lịch, sinh buổi học tự động.

### 2.1 Database — Schema mở rộng

- [ ] 🔴 `[DB]` Prisma schema: model `Course`
- [ ] 🔴 `[DB]` Prisma schema: model `CourseLevel`
- [ ] 🔴 `[DB]` Prisma schema: model `Module`
- [ ] 🔴 `[DB]` Prisma schema: model `Lesson`
- [ ] 🔴 `[DB]` Prisma schema: model `LessonMaterial`
- [ ] 🔴 `[DB]` Prisma schema: model `Class`
- [ ] 🔴 `[DB]` Prisma schema: model `ClassStudent`
- [ ] 🔴 `[DB]` Prisma schema: model `ClassSession`
- [ ] 🔴 `[DB]` Chạy migration
- [ ] 🟡 `[DB]` Seed dữ liệu mẫu: 2 courses, vài classes

### 2.2 Backend — Module Courses

- [ ] 🔴 `[BE]` API: `GET /courses` — danh sách khóa học (phân trang, filter by language)
- [ ] 🔴 `[BE]` API: `GET /courses/:id` — chi tiết khóa học + levels
- [ ] 🔴 `[BE]` API: `POST /courses` — tạo khóa học
- [ ] 🔴 `[BE]` API: `PATCH /courses/:id` — cập nhật khóa học
- [ ] 🔴 `[BE]` API: `GET /courses/:id/levels` — danh sách level
- [ ] 🔴 `[BE]` API: `POST /courses/:id/levels` — tạo level
- [ ] 🟡 `[BE]` API: `GET /levels/:id/modules` — danh sách module
- [ ] 🟡 `[BE]` API: `POST /levels/:id/modules` — tạo module
- [ ] 🟡 `[BE]` API: `GET /modules/:id/lessons` — danh sách bài học
- [ ] 🟡 `[BE]` API: `POST /modules/:id/lessons` — tạo bài học
- [ ] 🟡 `[BE]` API: `POST /lessons/:id/materials` — upload tài liệu

### 2.3 Backend — Module Classes

- [ ] 🔴 `[BE]` API: `GET /classes` — danh sách lớp (filter: status, branch, course, teacher)
- [ ] 🔴 `[BE]` API: `GET /classes/:id` — chi tiết lớp + danh sách HV
- [ ] 🔴 `[BE]` API: `POST /classes` — tạo lớp mới
- [ ] 🔴 `[BE]` Logic: auto-generate `class_sessions` từ schedule_days + start_date + total_sessions
- [ ] 🔴 `[BE]` Logic: kiểm tra trùng lịch phòng khi tạo lớp
- [ ] 🔴 `[BE]` Logic: kiểm tra trùng lịch giáo viên khi tạo lớp
- [ ] 🔴 `[BE]` API: `PATCH /classes/:id` — cập nhật lớp
- [ ] 🔴 `[BE]` API: `POST /classes/:id/students` — thêm HV vào lớp (check sĩ số tối đa)
- [ ] 🔴 `[BE]` API: `DELETE /classes/:id/students/:studentId` — xóa HV
- [ ] 🔴 `[BE]` API: `GET /classes/:id/sessions` — danh sách buổi học
- [ ] 🟡 `[BE]` API: `PATCH /sessions/:id` — sửa buổi (đổi phòng, GV thay)
- [ ] 🔴 `[BE]` API: `GET /my/classes` — lớp của tôi (student/teacher)
- [ ] 🔴 `[BE]` API: `GET /my/schedule` — lịch tuần này (student/teacher)

### 2.4 Backend — Module File Upload

- [ ] 🔴 `[BE]` Service upload file lên Firebase Storage
- [ ] 🔴 `[BE]` Validate loại file (pdf, jpg, png, mp3, mp4)
- [ ] 🔴 `[BE]` Giới hạn dung lượng file (config: max 50MB)
- [ ] 🔴 `[BE]` Trả về signed URL sau khi upload

### 2.5 Frontend — Feature Courses

- [ ] 🔴 `[FE]` `CoursesBloc` + `CourseRepository`
- [ ] 🔴 `[FE]` UI: `CourseListScreen` (grid/list view, filter by ngôn ngữ)
- [ ] 🔴 `[FE]` UI: `CourseDetailScreen` (thông tin + danh sách levels)
- [ ] 🟡 `[FE]` UI: `LessonDetailScreen` (nội dung bài + tài liệu)
- [ ] 🟡 `[FE]` Audio player widget (nghe tài liệu âm thanh)
- [ ] 🟡 `[FE]` PDF viewer widget (xem tài liệu)

### 2.6 Frontend — Feature Classes

- [ ] 🔴 `[FE]` `ClassesBloc` + `ClassRepository`
- [ ] 🔴 `[FE]` UI (Admin/Staff): `ClassListScreen` (filter by status/branch)
- [ ] 🔴 `[FE]` UI (Admin/Staff): `ClassCreateScreen` (form tạo lớp)
- [ ] 🔴 `[FE]` UI (Admin/Staff): `ClassDetailScreen` (thông tin lớp + danh sách HV + sessions)
- [ ] 🔴 `[FE]` UI (Admin/Staff): Thêm/xóa HV khỏi lớp
- [ ] 🔴 `[FE]` UI (Teacher): Danh sách lớp mình dạy
- [ ] 🔴 `[FE]` UI (Student): Danh sách lớp đang học
- [ ] 🔴 `[FE]` UI: `ScheduleScreen` — lịch học tuần (Calendar view, `table_calendar`)
- [ ] 🟡 `[FE]` UI: Session detail — xem chi tiết buổi học

### 2.7 Testing — Phase 2

- [ ] 🟡 `[QA]` Unit test: auto-generate sessions logic
- [ ] 🟡 `[QA]` Unit test: kiểm tra trùng lịch phòng/GV
- [ ] 🟡 `[QA]` E2E test: tạo lớp → thêm HV → xem sessions
- [ ] 🟡 `[QA]` Widget test: ClassCreateScreen validation

### ✅ Milestone Phase 2

- [ ] Admin tạo khóa học → tạo lớp → hệ thống tự sinh buổi học
- [ ] Admin thêm HV vào lớp → HV thấy lịch học trên app
- [ ] Giáo viên xem được lịch dạy tuần trên Calendar

---

## PHASE 3: ATTENDANCE & ASSIGNMENT — ĐIỂM DANH & BÀI TẬP (Tuần 7–9)

> **Mục tiêu:** Điểm danh buổi học, quản lý học bù, giao/nộp/chấm bài tập.

### 3.1 Database — Schema mở rộng

- [ ] 🔴 `[DB]` Prisma schema: model `Attendance`
- [ ] 🔴 `[DB]` Prisma schema: model `MakeupRequest`
- [ ] 🔴 `[DB]` Prisma schema: model `Assignment`
- [ ] 🔴 `[DB]` Prisma schema: model `Submission`
- [ ] 🔴 `[DB]` Chạy migration

### 3.2 Backend — Module Attendance

- [ ] 🔴 `[BE]` API: `GET /sessions/:id/attendance` — danh sách điểm danh 1 buổi
- [ ] 🔴 `[BE]` API: `POST /sessions/:id/attendance` — điểm danh hàng loạt (mảng students + status)
- [ ] 🔴 `[BE]` API: `PATCH /attendance/:id` — sửa điểm danh
- [ ] 🔴 `[BE]` API: `GET /students/:id/attendance` — lịch sử chuyên cần 1 HV
- [ ] 🔴 `[BE]` API: `GET /classes/:id/attendance-summary` — thống kê chuyên cần lớp
- [ ] 🟡 `[BE]` API: `POST /makeup-requests` — HV đăng ký bù
- [ ] 🟡 `[BE]` API: `GET /makeup-requests` — danh sách yêu cầu bù (Staff)
- [ ] 🟡 `[BE]` API: `PATCH /makeup-requests/:id` — duyệt/từ chối
- [ ] 🟡 `[BE]` Logic: khi điểm danh vắng → trigger notification cho phụ huynh
- [ ] 🟡 `[BE]` Logic: tính tỷ lệ chuyên cần (%) theo lớp, theo HV

### 3.3 Backend — Module Assignments

- [ ] 🔴 `[BE]` API: `GET /classes/:id/assignments` — danh sách bài tập
- [ ] 🔴 `[BE]` API: `POST /classes/:id/assignments` — tạo bài tập (GV)
- [ ] 🔴 `[BE]` API: `GET /assignments/:id` — chi tiết bài tập
- [ ] 🔴 `[BE]` API: `POST /assignments/:id/submit` — nộp bài (HV)
- [ ] 🔴 `[BE]` API: `GET /assignments/:id/submissions` — danh sách bài nộp (GV)
- [ ] 🔴 `[BE]` API: `PATCH /submissions/:id/grade` — chấm điểm + nhận xét
- [ ] 🔴 `[BE]` Upload file bài nộp (PDF, audio, image) lên Firebase Storage
- [ ] 🟡 `[BE]` Cron job: nhắc deadline sắp hết hạn (trước 24h)
- [ ] 🟡 `[BE]` Logic: đánh dấu bài nộp muộn (status = 'late')

### 3.4 Frontend — Feature Attendance

- [ ] 🔴 `[FE]` `AttendanceBloc` + `AttendanceRepository`
- [ ] 🔴 `[FE]` UI (Teacher): `AttendanceMarkScreen`
  - [ ] Danh sách HV của buổi học
  - [ ] Chọn trạng thái cho từng HV (present/absent/late/excused)
  - [ ] Nút Submit điểm danh
- [ ] 🔴 `[FE]` UI (Student): `MyAttendanceScreen` — lịch sử chuyên cần (calendar heatmap)
- [ ] 🟡 `[FE]` UI (Parent): Xem chuyên cần của con
- [ ] 🟡 `[FE]` UI (Staff): Danh sách yêu cầu học bù + duyệt/từ chối
- [ ] 🟡 `[FE]` UI (Student): Đăng ký học bù

### 3.5 Frontend — Feature Assignments

- [ ] 🔴 `[FE]` `AssignmentBloc` + `AssignmentRepository`
- [ ] 🔴 `[FE]` UI (Teacher): `CreateAssignmentScreen` (title, mô tả, deadline, đính kèm file)
- [ ] 🔴 `[FE]` UI (Teacher): `SubmissionListScreen` (xem bài nộp, chấm điểm)
- [ ] 🔴 `[FE]` UI (Teacher): `GradeSubmissionScreen` (nhập điểm + nhận xét)
- [ ] 🔴 `[FE]` UI (Student): `AssignmentListScreen` (danh sách bài tập, deadline countdown)
- [ ] 🔴 `[FE]` UI (Student): `SubmitAssignmentScreen` (nhập text / upload file / ghi âm audio)
- [ ] 🔴 `[FE]` Widget: `AudioRecorderWidget` — ghi âm bài nói (package: `record`)
- [ ] 🟡 `[FE]` Widget: `AudioPlayerWidget` — nghe lại bản ghi âm
- [ ] 🟡 `[FE]` Widget: `DeadlineCountdownWidget`

### 3.6 Testing — Phase 3

- [ ] 🟡 `[QA]` Unit test: attendance service (mark, tính tỷ lệ)
- [ ] 🟡 `[QA]` Unit test: submission service (nộp, chấm, trạng thái muộn)
- [ ] 🟡 `[QA]` E2E test: GV điểm danh → HV xem lịch sử
- [ ] 🟡 `[QA]` Widget test: AttendanceMarkScreen, SubmitAssignmentScreen

### ✅ Milestone Phase 3

- [ ] GV mở app → chọn buổi học → điểm danh từng HV → Submit
- [ ] HV vắng → phụ huynh nhận thông báo (in-app trước, push ở Phase 5)
- [ ] GV tạo bài tập → HV nộp bài (text + audio ghi âm) → GV chấm điểm + nhận xét

---

## PHASE 4: EXAM & ASSESSMENT — THI & KIỂM TRA (Tuần 10–12)

> **Mục tiêu:** Ngân hàng câu hỏi, thi online, tự động chấm trắc nghiệm.

### 4.1 Database — Schema mở rộng

- [ ] 🔴 `[DB]` Prisma schema: model `QuestionBank`
- [ ] 🔴 `[DB]` Prisma schema: model `Question` (content JSONB)
- [ ] 🔴 `[DB]` Prisma schema: model `Exam`
- [ ] 🔴 `[DB]` Prisma schema: model `ExamQuestion`
- [ ] 🔴 `[DB]` Prisma schema: model `ExamAttempt`
- [ ] 🔴 `[DB]` Prisma schema: model `ExamAnswer`
- [ ] 🔴 `[DB]` Chạy migration

### 4.2 Backend — Module Question Banks

- [ ] 🔴 `[BE]` API: `GET /question-banks` — danh sách ngân hàng
- [ ] 🔴 `[BE]` API: `POST /question-banks` — tạo ngân hàng
- [ ] 🔴 `[BE]` API: `GET /question-banks/:id/questions` — câu hỏi trong ngân hàng
- [ ] 🔴 `[BE]` API: `POST /question-banks/:id/questions` — thêm câu hỏi
- [ ] 🔴 `[BE]` API: `PATCH /questions/:id` — sửa câu hỏi
- [ ] 🔴 `[BE]` API: `DELETE /questions/:id` — xóa câu hỏi
- [ ] 🟡 `[BE]` API: `POST /question-banks/:id/questions/import` — import từ file
- [ ] 🔴 `[BE]` Hỗ trợ nhiều loại câu hỏi: multiple_choice, fill_blank, matching, ordering, essay

### 4.3 Backend — Module Exams

- [ ] 🔴 `[BE]` API: `GET /exams` — danh sách bài thi
- [ ] 🔴 `[BE]` API: `POST /exams` — tạo bài thi (chọn câu hỏi từ ngân hàng)
- [ ] 🔴 `[BE]` API: `GET /exams/:id` — chi tiết bài thi (GV: xem đề, HV: chỉ khi đã bắt đầu)
- [ ] 🔴 `[BE]` API: `POST /exams/:id/start` — HV bắt đầu làm bài (tạo attempt)
- [ ] 🔴 `[BE]` API: `PATCH /exam-attempts/:id/answers` — HV lưu câu trả lời (auto-save)
- [ ] 🔴 `[BE]` API: `POST /exams/:id/submit` — HV nộp bài
- [ ] 🔴 `[BE]` Logic: auto-submit khi hết thời gian (server-side validation)
- [ ] 🔴 `[BE]` Logic: tự động chấm trắc nghiệm (so đáp án)
- [ ] 🟡 `[BE]` Logic: shuffle câu hỏi nếu cấu hình bật
- [ ] 🔴 `[BE]` API: `GET /exams/:id/results` — kết quả thi cả lớp (GV)
- [ ] 🔴 `[BE]` API: `GET /my/exam-results` — kết quả thi của tôi (HV)
- [ ] 🟡 `[BE]` API: `PATCH /exam-answers/:id/grade` — GV chấm tay bài tự luận

### 4.4 Frontend — Feature Exams (Teacher)

- [ ] 🔴 `[FE]` `ExamBloc` + `ExamRepository`
- [ ] 🔴 `[FE]` UI: `QuestionBankListScreen`
- [ ] 🔴 `[FE]` UI: `CreateQuestionScreen` (form theo từng loại câu hỏi)
- [ ] 🔴 `[FE]` UI: `CreateExamScreen` (chọn câu hỏi, cấu hình thời gian/điểm)
- [ ] 🔴 `[FE]` UI: `ExamResultsScreen` (bảng điểm lớp)
- [ ] 🟡 `[FE]` UI: `GradeEssayScreen` (chấm tự luận)

### 4.5 Frontend — Feature Exams (Student)

- [ ] 🔴 `[FE]` UI: `ExamListScreen` (danh sách bài thi sắp tới / đã làm)
- [ ] 🔴 `[FE]` UI: `TakeExamScreen` — màn hình làm bài thi
  - [ ] 🔴 Countdown timer (hiển thị thời gian còn lại)
  - [ ] 🔴 Navigation giữa các câu hỏi (prev/next + jump to question)
  - [ ] 🔴 Đánh dấu câu đã làm / chưa làm / đánh dấu review
  - [ ] 🔴 Auto-save câu trả lời
  - [ ] 🔴 Confirm dialog trước khi nộp
  - [ ] 🔴 Auto-submit khi hết giờ
- [ ] 🔴 `[FE]` Widget: `MultipleChoiceQuestion`
- [ ] 🔴 `[FE]` Widget: `FillBlankQuestion`
- [ ] 🟡 `[FE]` Widget: `MatchingQuestion` (kéo thả nối)
- [ ] 🟡 `[FE]` Widget: `OrderingQuestion` (kéo thả sắp xếp)
- [ ] 🟡 `[FE]` Widget: `EssayQuestion` (nhập text dài)
- [ ] 🔴 `[FE]` UI: `ExamResultScreen` (xem điểm + đáp án nếu cho phép)
- [ ] 🟡 `[FE]` Widget: `SkillRadarChart` (biểu đồ radar điểm theo kỹ năng)

### 4.6 Testing — Phase 4

- [ ] 🟡 `[QA]` Unit test: auto-grade logic (trắc nghiệm, điền khuyết)
- [ ] 🟡 `[QA]` Unit test: timer validation (server reject nộp muộn)
- [ ] 🟡 `[QA]` E2E test: tạo đề → HV start → submit → xem kết quả
- [ ] 🟡 `[QA]` Widget test: TakeExamScreen (countdown, navigation)

### ✅ Milestone Phase 4

- [ ] GV tạo ngân hàng câu hỏi → tạo đề thi → gán cho lớp
- [ ] HV mở app → bắt đầu thi → làm bài → nộp → xem điểm trắc nghiệm ngay
- [ ] GV vào chấm tay phần tự luận → HV xem điểm tổng

---

## PHASE 5: FINANCE & NOTIFICATION — TÀI CHÍNH & THÔNG BÁO (Tuần 13–16)

> **Mục tiêu:** Thu học phí, thanh toán online, push notification, email.

### 5.1 Database — Schema mở rộng

- [ ] 🔴 `[DB]` Prisma schema: model `Invoice`
- [ ] 🔴 `[DB]` Prisma schema: model `Payment`
- [ ] 🔴 `[DB]` Prisma schema: model `Promotion`
- [ ] 🔴 `[DB]` Prisma schema: model `Notification`
- [ ] 🔴 `[DB]` Chạy migration

### 5.2 Backend — Module Finance

- [ ] 🔴 `[BE]` API: `GET /invoices` — danh sách hóa đơn (filter: status, student, branch, date range)
- [ ] 🔴 `[BE]` API: `GET /invoices/:id` — chi tiết hóa đơn + payments
- [ ] 🔴 `[BE]` API: `POST /invoices` — tạo hóa đơn (gắn class + student)
- [ ] 🔴 `[BE]` API: `POST /invoices/:id/payments` — ghi nhận thanh toán (tiền mặt/CK)
- [ ] 🔴 `[BE]` Logic: tự động tạo hóa đơn khi thêm HV vào lớp
- [ ] 🔴 `[BE]` Logic: cập nhật status invoice (pending→partial→paid) dựa trên tổng payment
- [ ] 🟡 `[BE]` Logic: auto đánh overdue khi quá due_date (cron job chạy hàng ngày)
- [ ] 🟡 `[BE]` API: `POST /invoices/:id/cancel` — hủy hóa đơn
- [ ] 🟡 `[BE]` API: `POST /invoices/:id/refund` — hoàn tiền

### 5.3 Backend — Tích hợp VNPay

- [ ] 🔴 `[BE]` API: `POST /invoices/:id/pay-online` — tạo URL thanh toán VNPay
- [ ] 🔴 `[BE]` API: `GET /payments/vnpay/callback` — xử lý callback từ VNPay
- [ ] 🔴 `[BE]` Logic: verify checksum VNPay response
- [ ] 🔴 `[BE]` Logic: ghi nhận payment + cập nhật invoice status sau khi VNPay callback success
- [ ] 🟡 `[BE]` Tích hợp MoMo (tương tự flow VNPay)

### 5.4 Backend — Module Promotions

- [ ] 🟡 `[BE]` API: `POST /promotions` — tạo mã KM
- [ ] 🟡 `[BE]` API: `GET /promotions` — danh sách mã KM
- [ ] 🟡 `[BE]` API: `POST /promotions/validate` — kiểm tra mã KM (còn hạn, còn lượt)
- [ ] 🟡 `[BE]` Logic: áp dụng discount khi tạo invoice

### 5.5 Backend — Module Notifications

- [ ] 🔴 `[BE]` Service: gửi Push Notification qua FCM (Firebase Admin SDK)
- [ ] 🔴 `[BE]` Service: lưu notification vào DB (in-app notification)
- [ ] 🟡 `[BE]` Service: gửi Email (Nodemailer)
- [ ] 🟢 `[BE]` Service: gửi SMS
- [ ] 🔴 `[BE]` API: `GET /my/notifications` — danh sách thông báo
- [ ] 🔴 `[BE]` API: `PATCH /notifications/:id/read` — đánh dấu đã đọc
- [ ] 🔴 `[BE]` API: `POST /notifications/read-all` — đọc tất cả
- [ ] 🟡 `[BE]` API: `POST /notifications/send` — admin broadcast thông báo
- [ ] 🔴 `[BE]` API: `PUT /my/fcm-token` — cập nhật FCM token
- [ ] 🟡 `[BE]` API: `PUT /my/notification-preferences` — cấu hình nhận TB

### 5.6 Backend — Notification Triggers (Cron Jobs / Event-driven)

- [ ] 🔴 `[BE]` Trigger: vắng học → push cho phụ huynh
- [ ] 🔴 `[BE]` Trigger: deadline bài tập sắp hết (trước 24h) → push cho HV
- [ ] 🔴 `[BE]` Trigger: học phí quá hạn → push + email cho HV + phụ huynh
- [ ] 🟡 `[BE]` Trigger: nhắc lịch học ngày mai (cron chạy 8pm hàng ngày)
- [ ] 🟡 `[BE]` Trigger: lớp sắp khai giảng (trước 3 ngày)
- [ ] 🟡 `[BE]` Trigger: kết quả thi đã có → push cho HV

### 5.7 Frontend — Feature Finance

- [ ] 🔴 `[FE]` `FinanceBloc` + `FinanceRepository`
- [ ] 🔴 `[FE]` UI (Cashier): `InvoiceListScreen` (filter by status, search HV)
- [ ] 🔴 `[FE]` UI (Cashier): `InvoiceDetailScreen` (thông tin + lịch sử thanh toán)
- [ ] 🔴 `[FE]` UI (Cashier): `RecordPaymentScreen` (thu tiền mặt/CK)
- [ ] 🔴 `[FE]` UI (Student): `MyInvoicesScreen` (danh sách hóa đơn)
- [ ] 🔴 `[FE]` UI (Student): `PayOnlineScreen` (WebView mở VNPay)
- [ ] 🟡 `[FE]` UI (Parent): Xem hóa đơn/công nợ của con
- [ ] 🟡 `[FE]` UI (Cashier): In/xuất hóa đơn PDF

### 5.8 Frontend — Feature Notifications

- [ ] 🔴 `[FE]` Setup Firebase Messaging trên Flutter
  - [ ] 🔴 Cấu hình `firebase_messaging` + `flutter_local_notifications`
  - [ ] 🔴 Request notification permission
  - [ ] 🔴 Lấy FCM token → gửi lên backend
  - [ ] 🔴 Handle foreground notification (hiển thị local notification)
  - [ ] 🔴 Handle background notification
  - [ ] 🔴 Handle notification tap → navigate đến screen tương ứng
- [ ] 🔴 `[FE]` `NotificationBloc` + `NotificationRepository`
- [ ] 🔴 `[FE]` UI: `NotificationListScreen` (danh sách in-app notifications)
- [ ] 🔴 `[FE]` Widget: Badge count trên icon chuông (AppBar)
- [ ] 🟡 `[FE]` UI: `NotificationPreferencesScreen`

### 5.9 Testing — Phase 5

- [ ] 🟡 `[QA]` Unit test: invoice status transition logic
- [ ] 🟡 `[QA]` Unit test: VNPay checksum verification
- [ ] 🟡 `[QA]` Unit test: notification trigger logic
- [ ] 🟡 `[QA]` E2E test: tạo invoice → thanh toán → status cập nhật
- [ ] 🟡 `[QA]` Integration test: FCM push gửi thành công

### ✅ Milestone Phase 5

- [ ] Thu ngân tạo hóa đơn → thu tiền mặt → trạng thái thành "đã thanh toán"
- [ ] HV thanh toán online qua VNPay → hóa đơn tự cập nhật
- [ ] HV vắng học → phụ huynh nhận push notification trên điện thoại
- [ ] HV nhận thông báo nhắc deadline bài tập + nhắc học phí

---

## PHASE 6: REPORT & POLISH — BÁO CÁO & HOÀN THIỆN (Tuần 17–20)

> **Mục tiêu:** Dashboard, báo cáo, xuất file, QA toàn diện, tối ưu, go-live.

### 6.1 Backend — Module Reports

- [ ] 🔴 `[BE]` API: `GET /reports/dashboard` — overview (tổng HV, tổng lớp active, doanh thu tháng, HV mới)
- [ ] 🔴 `[BE]` API: `GET /reports/revenue` — doanh thu theo ngày/tuần/tháng/chi nhánh
- [ ] 🔴 `[BE]` API: `GET /reports/attendance` — chuyên cần theo lớp/HV/khoảng thời gian
- [ ] 🔴 `[BE]` API: `GET /reports/academic` — kết quả học tập theo lớp/HV
- [ ] 🟡 `[BE]` API: `GET /reports/debts` — công nợ (danh sách HV chưa thanh toán)
- [ ] 🟡 `[BE]` API: `GET /reports/teacher-workload` — tải giờ dạy GV
- [ ] 🟡 `[BE]` API: `GET /reports/export/:type` — xuất Excel (`exceljs`)
- [ ] 🟡 `[BE]` API: `GET /reports/export/:type/pdf` — xuất PDF (`pdfmake`)
- [ ] 🟡 `[BE]` Cache dashboard queries với Redis (TTL 5 phút)

### 6.2 Frontend — Feature Dashboard

- [ ] 🔴 `[FE]` UI (Admin): `AdminDashboardScreen`
  - [ ] Card: Tổng học viên active
  - [ ] Card: Tổng lớp đang hoạt động
  - [ ] Card: Doanh thu tháng này
  - [ ] Card: Công nợ chưa thu
  - [ ] Chart: Biểu đồ doanh thu 6 tháng (line chart)
  - [ ] Chart: Phân bổ HV theo khóa học (pie chart)
  - [ ] Table: Top 5 lớp sắp khai giảng
  - [ ] Table: Top 5 HV công nợ lớn nhất
- [ ] 🔴 `[FE]` UI (Teacher): `TeacherDashboardScreen`
  - [ ] Lịch dạy hôm nay
  - [ ] Danh sách lớp đang dạy
  - [ ] Bài tập chưa chấm (badge count)
  - [ ] Thống kê chuyên cần lớp
- [ ] 🔴 `[FE]` UI (Student): `StudentDashboardScreen`
  - [ ] Lịch học hôm nay / tuần này
  - [ ] Bài tập sắp đến hạn
  - [ ] Bài thi sắp tới
  - [ ] Tỷ lệ chuyên cần cá nhân
  - [ ] Điểm trung bình

### 6.3 Frontend — Charts & Visualization

- [ ] 🔴 `[FE]` Tích hợp `fl_chart`
- [ ] 🔴 `[FE]` Widget: `RevenueLineChart`
- [ ] 🔴 `[FE]` Widget: `StudentDistributionPieChart`
- [ ] 🟡 `[FE]` Widget: `AttendanceBarChart`
- [ ] 🟡 `[FE]` Widget: `SkillRadarChart` (điểm theo kỹ năng)

### 6.4 UI Polish & UX

- [ ] 🔴 `[FE]` Empty states cho tất cả list screens (hình minh họa + message)
- [ ] 🔴 `[FE]` Error states với nút Retry
- [ ] 🔴 `[FE]` Pull-to-refresh cho danh sách
- [ ] 🔴 `[FE]` Shimmer loading skeleton cho cards và lists
- [ ] 🟡 `[FE]` Page transition animations
- [ ] 🟡 `[FE]` Hero animations cho avatar, course thumbnail
- [ ] 🟡 `[FE]` Bottom navigation bar với badge counts
- [ ] 🟡 `[FE]` Dark mode toggle
- [ ] 🟡 `[FE]` Đa ngôn ngữ (i18n): Tiếng Việt + English
- [ ] 🟢 `[FE]` Onboarding screens (giới thiệu app lần đầu)

### 6.5 Performance Optimization

- [ ] 🔴 `[FE]` Lazy loading cho danh sách (infinite scroll pagination)
- [ ] 🔴 `[FE]` Image caching (`cached_network_image`)
- [ ] 🟡 `[FE]` Optimize rebuild (const constructors, selective BLoC listening)
- [ ] 🟡 `[BE]` Database query optimization (explain analyze slow queries)
- [ ] 🟡 `[BE]` Implement Redis caching cho hot endpoints
- [ ] 🟡 `[BE]` Compression middleware (gzip responses)
- [ ] 🟡 `[BE]` Rate limiting (throttle API calls)

### 6.6 Security Hardening

- [ ] 🔴 `[BE]` Helmet middleware (security headers)
- [ ] 🔴 `[BE]` CORS configuration (chỉ cho phép domain frontend)
- [ ] 🔴 `[BE]` Input sanitization (chống XSS)
- [ ] 🔴 `[BE]` SQL injection prevention (Prisma parameterized queries — mặc định)
- [ ] 🔴 `[BE]` Rate limiting per IP + per user
- [ ] 🟡 `[BE]` Audit log (ghi lại ai làm gì, khi nào)
- [ ] 🟡 `[BE]` Brute force protection (lock account sau 5 lần sai)

### 6.7 Testing toàn diện

- [ ] 🔴 `[QA]` Unit tests: đạt >70% coverage cho services
- [ ] 🟡 `[QA]` E2E tests: full flow cho mỗi role (admin, teacher, student)
- [ ] 🟡 `[QA]` Widget tests: tất cả screens chính
- [ ] 🟡 `[QA]` Integration tests trên Flutter (flutter_driver hoặc integration_test)
- [ ] 🔴 `[QA]` Manual testing: test trên thiết bị thật (Android + iOS)
- [ ] 🔴 `[QA]` Fix tất cả critical/major bugs
- [ ] 🟡 `[QA]` Performance testing (response time < 500ms cho API chính)

### 6.8 Deployment Preparation

- [ ] 🔴 `[OPS]` Chọn hosting cho Backend (Railway / Render / VPS / AWS EC2)
- [ ] 🔴 `[OPS]` Setup PostgreSQL production (Supabase / Neon / AWS RDS)
- [ ] 🔴 `[OPS]` Setup Redis production (Upstash / AWS ElastiCache)
- [ ] 🔴 `[OPS]` Cấu hình `.env.production`
- [ ] 🔴 `[OPS]` Setup CI/CD pipeline (GitHub Actions)
  - [ ] Lint + test on PR
  - [ ] Auto deploy on merge to main
- [ ] 🔴 `[OPS]` Build Flutter APK (Android) — test trên thiết bị thật
- [ ] 🟡 `[OPS]` Build Flutter IPA (iOS) — test trên TestFlight
- [ ] 🟡 `[OPS]` Setup domain + SSL cho API
- [ ] 🟡 `[OPS]` Setup monitoring (UptimeRobot / Sentry cho error tracking)
- [ ] 🟡 `[OPS]` Backup strategy cho PostgreSQL (daily automated backup)

### 6.9 Go-Live Checklist

- [ ] 🔴 Tất cả API endpoints hoạt động đúng trên production
- [ ] 🔴 Đăng nhập / đăng ký hoạt động trên app thật
- [ ] 🔴 Push notification hoạt động trên Android + iOS
- [ ] 🔴 Thanh toán VNPay hoạt động trên production (chuyển từ sandbox → live)
- [ ] 🔴 Seed dữ liệu production: roles, permissions, tài khoản admin
- [ ] 🔴 Tạo tài liệu hướng dẫn sử dụng cho Admin/Staff
- [ ] 🟡 Tạo tài liệu hướng dẫn cho Giáo viên
- [ ] 🟡 Tạo FAQ cho Học viên
- [ ] 🔴 Publish APK lên Google Play Store (hoặc internal testing)
- [ ] 🟡 Publish IPA lên Apple App Store (hoặc TestFlight)

### ✅ Milestone Phase 6 (FINAL)

- [ ] Admin đăng nhập web → thấy Dashboard với doanh thu, thống kê
- [ ] Xuất báo cáo Excel/PDF thành công
- [ ] App chạy mượt trên thiết bị thật, không crash
- [ ] Tất cả push notifications trigger đúng thời điểm
- [ ] 🎉 **GO LIVE — Hệ thống LMS sẵn sàng đưa vào sử dụng!**

---

## PHASE MỞ RỘNG (SAU GO-LIVE)

> Những tính năng không cần cho MVP, phát triển sau khi hệ thống ổn định.

### Chat & Trao đổi (Module 12)

- [ ] 🟢 `[BE]` WebSocket setup (Socket.IO)
- [ ] 🟢 `[BE]` Chat 1-1 (GV ↔ HV)
- [ ] 🟢 `[BE]` Chat nhóm theo lớp
- [ ] 🟢 `[BE]` Gửi file/ảnh trong chat
- [ ] 🟢 `[FE]` UI: ChatListScreen, ChatRoomScreen
- [ ] 🟢 `[FE]` Widget: MessageBubble, ImageMessage, FileMessage
- [ ] 🟢 `[FE]` Badge count tin nhắn mới

### Flashcard & Từ vựng (Module 13)

- [ ] 🟢 `[DB]` Schema: FlashcardDeck, Flashcard, FlashcardProgress
- [ ] 🟢 `[BE]` CRUD flashcard decks + cards
- [ ] 🟢 `[BE]` Thuật toán Spaced Repetition (SM-2)
- [ ] 🟢 `[FE]` UI: FlashcardDeckListScreen
- [ ] 🟢 `[FE]` UI: FlashcardStudyScreen (lật thẻ, animation)
- [ ] 🟢 `[FE]` UI: VocabularyQuizScreen (trắc nghiệm từ vựng)
- [ ] 🟢 `[FE]` Widget: FlipCard animation

### Tính năng nâng cao khác

- [ ] 🟢 Xếp lớp tự động (dựa trên placement test)
- [ ] 🟢 Đánh giá giáo viên (học viên rate sau khóa)
- [ ] 🟢 CRM: theo dõi leads, chuyển đổi tư vấn → đăng ký
- [ ] 🟢 Video call / Online classroom (tích hợp Jitsi / Agora)
- [ ] 🟢 Gamification: điểm thưởng, badges, leaderboard
- [ ] 🟢 AI: gợi ý bài học, phân tích phát âm
- [ ] 🟢 Multi-tenant: phục vụ nhiều trung tâm trên 1 hệ thống

---

## 📊 BẢNG TỔNG HỢP TIẾN ĐỘ

| Phase | Tổng tasks | Hoàn thành | Tiến độ |
|:---|:---:|:---:|:---:|
| Phase 0: Chuẩn bị | 18 | 0 | ░░░░░░░░░░ 0% |
| Phase 1: Foundation | 82 | 0 | ░░░░░░░░░░ 0% |
| Phase 2: Core Academic | 42 | 0 | ░░░░░░░░░░ 0% |
| Phase 3: Attendance & Assignment | 36 | 0 | ░░░░░░░░░░ 0% |
| Phase 4: Exam & Assessment | 40 | 0 | ░░░░░░░░░░ 0% |
| Phase 5: Finance & Notification | 48 | 0 | ░░░░░░░░░░ 0% |
| Phase 6: Report & Polish | 56 | 0 | ░░░░░░░░░░ 0% |
| **TỔNG CỘNG** | **322** | **0** | **░░░░░░░░░░ 0%** |

> **Cập nhật bảng này mỗi cuối tuần để track tiến độ tổng thể.**
