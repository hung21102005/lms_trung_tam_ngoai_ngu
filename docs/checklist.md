# ✅ CHECKLIST DỰ ÁN LMS TRUNG TÂM NGOẠI NGỮ

> **Tiến độ tổng:** 143 / 478 tasks
> **Cập nhật lần cuối:** 2026-10-17
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

- [x] 🔴 Tạo Firebase Project trên Firebase Console (`lms-trung-tam-ngoai-ngu`)
- [x] 🔴 Bật Firebase Cloud Messaging (FCM)
- [x] 🔴 Bật Firebase Storage
- [x] 🔴 Tải `google-services.json` (Android)
- [x] 🔴 Tải Firebase Admin SDK service account key (cho Backend)
- [x] 🟡 Đăng ký tài khoản VNPay Sandbox (test thanh toán)
- [x] 🟢 Đăng ký SendGrid / cấu hình Gmail App Password (gửi email)
- [ ] 🟢 Đăng ký SMS Gateway (Twilio / eSMS / Viettel)

### Khởi tạo dự án

- [x] 🔴 Tạo Git repository
- [x] 🔴 Setup `.gitignore` monorepo cho Flutter + Node.js + Docker
- [x] 🔴 Tạo nhánh `develop` từ `main`
- [x] 🔴 Viết `README.md` cơ bản cho dự án

---

## PHASE 1: FOUNDATION — NỀN TẢNG (Tuần 1–3)

> **Mục tiêu:** Project skeleton, xác thực JWT, RBAC, CRUD users/branches/rooms.

### 1.1 Backend — Khởi tạo NestJS

- [x] 🔴 `[BE]` Khởi tạo NestJS project (`nest new backend`)
- [x] 🔴 `[BE]` Cấu hình TypeScript strict mode
- [x] 🔴 `[BE]` Cài đặt và cấu hình Prisma ORM
- [x] 🔴 `[BE]` Cấu hình kết nối PostgreSQL (`database.config.ts`)
- [x] 🔴 `[BE]` Cấu hình Redis (`redis.config.ts`)
- [x] 🟡 `[BE]` Cấu hình Firebase Admin SDK (`firebase.config.ts`)
- [x] 🔴 `[BE]` Setup cấu trúc thư mục: `config/`, `common/`, `modules/`, `database/`
- [x] 🔴 `[BE]` Tạo Global Exception Filter (`http-exception.filter.ts`)
- [x] 🔴 `[BE]` Tạo Response Transform Interceptor (chuẩn hóa response JSON)
- [x] 🔴 `[BE]` Tạo Validation Pipe (class-validator)
- [x] 🟡 `[BE]` Tạo Logging Interceptor
- [x] 🔴 `[BE]` Setup Swagger/OpenAPI documentation

### 1.2 Database — Schema & Migration đầu tiên

- [x] 🔴 `[DB]` Viết Prisma schema: model `Branch`
- [x] 🔴 `[DB]` Viết Prisma schema: model `Room`
- [x] 🔴 `[DB]` Viết Prisma schema: model `User`
- [x] 🔴 `[DB]` Viết Prisma schema: model `Role`
- [x] 🔴 `[DB]` Viết Prisma schema: model `Permission`
- [x] 🔴 `[DB]` Viết Prisma schema: model `UserRole`
- [x] 🔴 `[DB]` Viết Prisma schema: model `RolePermission`
- [x] 🔴 `[DB]` Viết Prisma schema: model `StudentProfile`
- [x] 🔴 `[DB]` Viết Prisma schema: model `TeacherProfile`
- [x] 🔴 `[DB]` Viết Prisma schema: model `ParentStudent`
- [x] 🔴 `[DB]` Viết Prisma schema: model `AdmissionLead` (tiếp nhận đăng ký tư vấn)
- [x] 🔴 `[DB]` Chạy migration đầu tiên (`prisma migrate dev`)
- [x] 🔴 `[DB]` Seed roles mặc định (super_admin, branch_admin, academic_staff, cashier, teacher, teaching_assistant, student, parent)
- [x] 🔴 `[DB]` Seed permissions mặc định (~40 permissions)
- [x] 🔴 `[DB]` Seed tài khoản Super Admin mặc định
- [x] 🟡 `[DB]` Seed dữ liệu mẫu: 1 branch, 2 rooms, vài users

### 1.3 Backend — Module Auth & First-time Activation

- [x] 🔴 `[BE]` Tạo `auth.module.ts`
- [x] 🔴 `[BE]` Implement JWT Strategy (`jwt.strategy.ts`)
- [x] 🔴 `[BE]` Implement `JwtAuthGuard`
- [x] 🔴 `[BE]` Implement `RolesGuard` + `@Roles()` decorator
- [x] 🔴 `[BE]` Implement `@CurrentUser()` decorator
- [x] 🔴 `[BE]` API: `POST /auth/login` (email/phone/mã tài khoản + password → JWT)
- [x] 🔴 `[BE]` API: `POST /auth/first-login-setup` (kích hoạt & đổi mật khẩu lần đầu)
- [x] 🔴 `[BE]` API: `POST /auth/refresh` (refresh token → new access token)
- [x] 🔴 `[BE]` API: `GET /auth/me` (thông tin user hiện tại)
- [x] 🔴 `[BE]` API: `POST /auth/change-password`
- [x] 🟡 `[BE]` API: `POST /auth/forgot-password` (gửi OTP email/SMS)
- [x] 🟡 `[BE]` API: `POST /auth/reset-password` (reset bằng OTP)
- [ ] 🟢 `[BE]` API: `POST /auth/google` (liên kết OAuth2 với tài khoản đã cấp)
- [x] 🔴 `[BE]` Hash password với bcrypt (salt rounds = 12)
- [x] 🔴 `[BE]` Validate input DTO (class-validator)

### 1.4 Backend — Module Admissions & Leads (Tuyển sinh & Tư vấn)

- [x] 🔴 `[BE]` API: `POST /admissions/leads` (Public — gửi đăng ký nhu cầu học tập)
- [x] 🔴 `[BE]` API: `GET /admissions/leads` (Học vụ xem & lọc danh sách tư vấn)
- [x] 🔴 `[BE]` API: `PATCH /admissions/leads/:id` (Cập nhật tiến trình tư vấn, hẹn test)
- [x] 🔴 `[BE]` API: `POST /admissions/leads/:id/convert` (Chuyển đổi lead thành học viên chính thức & cấp tài khoản)

### 1.5 Backend — Module Users & Cấp phát tài khoản

- [x] 🔴 `[BE]` Tạo `users.module.ts`
- [x] 🔴 `[BE]` API: `GET /users` (phân trang, search, filter by role/branch/class)
- [x] 🔴 `[BE]` API: `GET /users/:id` (chi tiết user + profile)
- [x] 🔴 `[BE]` API: `POST /users/students` (Admin/Học vụ tạo tài khoản học viên kèm lớp)
- [x] 🔴 `[BE]` API: `POST /users/parents` (Admin/Học vụ tạo tài khoản phụ huynh kèm liên kết con)
- [x] 🔴 `[BE]` API: `POST /users/staff` (Admin tạo tài khoản giáo viên/nhân viên)
- [x] 🔴 `[BE]` API: `PATCH /users/:id` (cập nhật user)
- [x] 🔴 `[BE]` API: `PATCH /users/:id/status` (khóa / mở khóa tài khoản)
- [x] 🔴 `[BE]` API: `POST /users/:id/reset-password` (Admin cấp lại mật khẩu tạm thời)
- [x] 🟡 `[BE]` API: `POST /users/import` (import Excel danh sách học viên)
- [x] 🔴 `[BE]` API: `GET /users/:id/roles` (lấy roles)
- [x] 🔴 `[BE]` API: `POST /users/:id/roles` (gán role)

### 1.5b Backend — Module Branches & Rooms

- [x] 🔴 `[BE]` API: `GET /branches` — danh sách chi nhánh
- [x] 🔴 `[BE]` API: `POST /branches` — tạo chi nhánh
- [x] 🔴 `[BE]` API: `PATCH /branches/:id` — cập nhật
- [x] 🔴 `[BE]` API: `GET /branches/:id/rooms` — phòng theo chi nhánh
- [x] 🔴 `[BE]` API: `POST /rooms` — tạo phòng
- [x] 🔴 `[BE]` API: `PATCH /rooms/:id` — cập nhật phòng

### 1.6 Frontend — Setup Flutter

- [x] 🔴 `[FE]` Tạo cấu trúc thư mục: `core/`, `features/`, `shared/`
- [x] 🔴 `[FE]` Cấu hình `pubspec.yaml` (thêm dependencies Phase 1)
- [x] 🔴 `[FE]` Setup theme (`app_theme.dart` — colors, typography, dark mode)
- [x] 🔴 `[FE]` Setup routing (`go_router` + `app_router.dart`)
- [x] 🔴 `[FE]` Setup DI container (`get_it` + `injectable`)
- [x] 🔴 `[FE]` Setup API client (`dio` + `api_client.dart`)
- [x] 🔴 `[FE]` Tạo API interceptor (auto-attach JWT, auto-refresh token)
- [x] 🔴 `[FE]` Setup secure storage (`flutter_secure_storage`)
- [x] 🔴 `[FE]` Setup BLoC pattern (`flutter_bloc`)
- [x] 🔴 `[FE]` Tạo `api_endpoints.dart` (constants)
- [x] 🔴 `[FE]` Tạo `api_response.dart` (generic response wrapper)
- [x] 🔴 `[FE]` Tạo `api_exception.dart` (error handling)

### 1.7 Frontend — Shared Widgets

- [x] 🔴 `[FE]` Widget: `AppButton` (primary, secondary, outline, loading state)
- [x] 🔴 `[FE]` Widget: `AppTextField` (text, password, search, multiline)
- [x] 🔴 `[FE]` Widget: `AppCard`
- [x] 🔴 `[FE]` Widget: `AppDialog` (confirm, alert, custom)
- [x] 🔴 `[FE]` Widget: `LoadingWidget` (spinner, skeleton shimmer)
- [x] 🔴 `[FE]` Widget: `EmptyStateWidget`
- [x] 🔴 `[FE]` Widget: `ErrorWidget` (retry button)
- [x] 🟡 `[FE]` Widget: `AppDropdown`
- [x] 🟡 `[FE]` Widget: `AppDatePicker`
- [ ] 🟡 `[FE]` Widget: `PaginatedListView`

### 1.8 Frontend — Feature Auth

- [x] 🔴 `[FE]` Tạo `AuthBloc` (events: Login, Logout, CheckAuth, RefreshToken)
- [x] 🔴 `[FE]` Tạo `AuthRepository` (interface + implementation)
- [x] 🔴 `[FE]` Tạo `LoginUseCase`
- [x] 🔴 `[FE]` UI: `LoginScreen` (email/phone + password)
- [x] 🔴 `[FE]` UI: `LoginForm` widget (validation, loading state)
- [x] 🟡 `[FE]` UI: `ForgotPasswordScreen`
- [x] 🟢 `[FE]` UI: Social login buttons (Google, Facebook)
- [x] 🔴 `[FE]` Logic: lưu JWT vào secure storage sau login
- [x] 🔴 `[FE]` Logic: auto-navigate theo role sau login (student→student dashboard, admin→admin dashboard)
- [x] 🔴 `[FE]` Logic: auto-logout khi token hết hạn + refresh fail
- [x] 🔴 `[FE]` UI: Splash screen (check auth state)

### 1.9 Frontend — Feature Profile

- [x] 🔴 `[FE]` UI: `ProfileScreen` (xem thông tin cá nhân)
- [x] 🟡 `[FE]` UI: `EditProfileScreen` (sửa tên, SĐT, avatar)
- [x] 🟡 `[FE]` UI: `ChangePasswordScreen`
- [x] 🟡 `[FE]` Upload avatar (chọn avatar / cập nhật avatarUrl lên backend)

### 1.10 DevOps — Phase 1

- [x] 🔴 `[OPS]` Viết `docker-compose.yml` (PostgreSQL + Redis)
- [x] 🔴 `[OPS]` Viết `.env.example` + `.env` cho backend
- [x] 🔴 `[OPS]` Viết `Dockerfile` cho backend
- [x] 🟡 `[OPS]` Setup ESLint + Prettier cho backend
- [x] 🟡 `[OPS]` Setup `analysis_options.yaml` cho Flutter (lint rules)

### 1.11 Testing — Phase 1

- [x] 🟡 `[QA]` Unit test: AuthService (login, hash password, JWT generation)
- [x] 🟡 `[QA]` Unit test: RolesGuard
- [x] 🟡 `[QA]` E2E test: POST /auth/login, GET /auth/me
- [x] 🟡 `[QA]` Widget test: LoginScreen, LoginForm

### ✅ Milestone Phase 1

- [x] Đăng nhập được trên app Flutter → nhận JWT → gọi API thành công
- [x] Admin tạo được user, gán role, tạo branch/room qua Swagger
- [x] Docker Compose chạy PostgreSQL + Redis + Backend local thành công

---

## PHASE 2: CORE ACADEMIC — NGHIỆP VỤ HỌC THUẬT (Tuần 4–6)

> **Mục tiêu:** Quản lý khóa học, lớp học, xếp lịch, sinh buổi học tự động.

### 2.1 Database — Schema mở rộng

- [x] 🔴 `[DB]` Prisma schema: model `Course`
- [x] 🔴 `[DB]` Prisma schema: model `CourseLevel`
- [x] 🔴 `[DB]` Prisma schema: model `Module`
- [x] 🔴 `[DB]` Prisma schema: model `Lesson`
- [x] 🔴 `[DB]` Prisma schema: model `LessonMaterial`
- [x] 🔴 `[DB]` Prisma schema: model `Class`
- [x] 🔴 `[DB]` Prisma schema: model `ClassStudent`
- [x] 🔴 `[DB]` Prisma schema: model `ClassSession`
- [x] 🔴 `[DB]` Chạy migration
- [x] 🟡 `[DB]` Seed dữ liệu mẫu: 2 courses, vài classes

### 2.2 Backend — Module Courses

- [x] 🔴 `[BE]` API: `GET /courses` — danh sách khóa học (phân trang, filter by language)
- [x] 🔴 `[BE]` API: `GET /courses/:id` — chi tiết khóa học + levels
- [x] 🔴 `[BE]` API: `POST /courses` — tạo khóa học
- [x] 🔴 `[BE]` API: `PATCH /courses/:id` — cập nhật khóa học
- [x] 🔴 `[BE]` API: `GET /courses/:id/levels` — danh sách level
- [x] 🔴 `[BE]` API: `POST /courses/:id/levels` — tạo level
- [x] 🟡 `[BE]` API: `GET /levels/:id/modules` — danh sách module
- [x] 🟡 `[BE]` API: `POST /levels/:id/modules` — tạo module
- [x] 🟡 `[BE]` API: `GET /modules/:id/lessons` — danh sách bài học
- [x] 🟡 `[BE]` API: `POST /modules/:id/lessons` — tạo bài học
- [x] 🟡 `[BE]` API: `POST /lessons/:id/materials` — upload tài liệu

### 2.3 Backend — Module Classes

- [x] 🔴 `[BE]` API: `GET /classes` — danh sách lớp (filter: status, branch, course, teacher)
- [x] 🔴 `[BE]` API: `GET /classes/:id` — chi tiết lớp + danh sách HV
- [x] 🔴 `[BE]` API: `POST /classes` — tạo lớp mới
- [x] 🔴 `[BE]` Logic: auto-generate `class_sessions` từ schedule_days + start_date + total_sessions
- [x] 🔴 `[BE]` Logic: kiểm tra trùng lịch phòng khi tạo lớp
- [x] 🔴 `[BE]` Logic: kiểm tra trùng lịch giáo viên khi tạo lớp
- [x] 🔴 `[BE]` API: `PATCH /classes/:id` — cập nhật lớp
- [x] 🔴 `[BE]` API: `POST /classes/:id/students` — thêm HV vào lớp (check sĩ số tối đa)
- [x] 🔴 `[BE]` API: `DELETE /classes/:id/students/:studentId` — xóa HV
- [x] 🔴 `[BE]` API: `GET /classes/:id/sessions` — danh sách buổi học
- [x] 🟡 `[BE]` API: `PATCH /sessions/:id` — sửa buổi (đổi phòng, GV thay)
- [x] 🔴 `[BE]` API: `GET /my/classes` — lớp của tôi (student/teacher)
- [x] 🔴 `[BE]` API: `GET /my/schedule` — lịch tuần này (student/teacher)

### 2.4 Backend — Module File Upload

- [x] 🔴 `[BE]` Service upload file lên Firebase Storage
- [x] 🔴 `[BE]` Validate loại file (pdf, jpg, png, mp3, mp4)
- [x] 🔴 `[BE]` Giới hạn dung lượng file (config: max 50MB)
- [x] 🔴 `[BE]` Trả về signed URL sau khi upload

### 2.5 Frontend — Feature Courses

- [x] 🔴 `[FE]` `CoursesBloc` + `CourseRepository`
- [x] 🔴 `[FE]` UI: `CourseListScreen` (grid/list view, filter by ngôn ngữ)
- [x] 🔴 `[FE]` UI: `CourseDetailScreen` (thông tin + danh sách levels)
- [x] 🟡 `[FE]` UI: `LessonDetailScreen` (nội dung bài + tài liệu)
- [x] 🟡 `[FE]` Audio player widget (nghe tài liệu âm thanh)
- [x] 🟡 `[FE]` PDF viewer widget (xem tài liệu)

### 2.6 Frontend — Feature Classes

- [x] 🔴 `[FE]` `ClassesBloc` + `ClassRepository`
- [x] 🔴 `[FE]` UI (Admin/Staff): `ClassListScreen` (filter by status/branch)
- [x] 🔴 `[FE]` UI (Admin/Staff): `ClassCreateScreen` (form tạo lớp)
- [x] 🔴 `[FE]` UI (Admin/Staff): `ClassDetailScreen` (thông tin lớp + danh sách HV + sessions)
- [x] 🔴 `[FE]` UI (Admin/Staff): Thêm/xóa HV khỏi lớp
- [x] 🔴 `[FE]` UI (Teacher): Danh sách lớp mình dạy
- [x] 🔴 `[FE]` UI (Student): Danh sách lớp đang học
- [x] 🔴 `[FE]` UI: `ScheduleScreen` — lịch học tuần (Calendar view, `table_calendar`)
- [x] 🟡 `[FE]` UI: Session detail — xem chi tiết buổi học

### 2.7 Testing — Phase 2

- [x] 🟡 `[QA]` Unit test: auto-generate sessions logic
- [x] 🟡 `[QA]` Unit test: kiểm tra trùng lịch phòng/GV
- [x] 🟡 `[QA]` E2E test: tạo lớp → thêm HV → xem sessions
- [x] 🟡 `[QA]` Widget test: ClassCreateScreen validation

### ✅ Milestone Phase 2

- [x] Admin tạo khóa học → tạo lớp → hệ thống tự sinh buổi học
- [x] Admin thêm HV vào lớp → HV thấy lịch học trên app
- [x] Giáo viên xem được lịch dạy tuần trên Calendar

---

## PHASE 3: ATTENDANCE & ASSIGNMENT — ĐIỂM DANH & BÀI TẬP (Tuần 7–9)

> **Mục tiêu:** Điểm danh buổi học, quản lý học bù, giao/nộp/chấm bài tập.

### 3.1 Database — Schema mở rộng

- [x] 🔴 `[DB]` Prisma schema: model `Attendance`
- [x] 🔴 `[DB]` Prisma schema: model `MakeupRequest`
- [x] 🔴 `[DB]` Prisma schema: model `Assignment`
- [x] 🔴 `[DB]` Prisma schema: model `Submission`
- [x] 🔴 `[DB]` Chạy migration

### 3.2 Backend — Module Attendance

- [x] 🔴 `[BE]` API: `GET /sessions/:id/attendance` — danh sách điểm danh 1 buổi
- [x] 🔴 `[BE]` API: `POST /sessions/:id/attendance` — điểm danh hàng loạt (mảng students + status)
- [x] 🔴 `[BE]` API: `PATCH /attendance/:id` — sửa điểm danh
- [x] 🔴 `[BE]` API: `GET /students/:id/attendance` — lịch sử chuyên cần 1 HV
- [x] 🔴 `[BE]` API: `GET /classes/:id/attendance-summary` — thống kê chuyên cần lớp
- [x] 🟡 `[BE]` API: `POST /makeup-requests` — HV đăng ký bù
- [x] 🟡 `[BE]` API: `GET /makeup-requests` — danh sách yêu cầu bù (Staff)
- [x] 🟡 `[BE]` API: `PATCH /makeup-requests/:id` — duyệt/từ chối
- [x] 🟡 `[BE]` Logic: khi điểm danh vắng → trigger notification cho phụ huynh
- [x] 🟡 `[BE]` Logic: tính tỷ lệ chuyên cần (%) theo lớp, theo HV

### 3.3 Backend — Module Assignments

- [x] 🔴 `[BE]` API: `GET /classes/:id/assignments` — danh sách bài tập
- [x] 🔴 `[BE]` API: `POST /classes/:id/assignments` — tạo bài tập (GV)
- [x] 🔴 `[BE]` API: `GET /assignments/:id` — chi tiết bài tập
- [x] 🔴 `[BE]` API: `POST /assignments/:id/submit` — nộp bài (HV)
- [x] 🔴 `[BE]` API: `GET /assignments/:id/submissions` — danh sách bài nộp (GV)
- [x] 🔴 `[BE]` API: `PATCH /submissions/:id/grade` — chấm điểm + nhận xét
- [x] 🔴 `[BE]` Upload file bài nộp (PDF, audio, image) lên Firebase Storage
- [x] 🟡 `[BE]` Cron job: nhắc deadline sắp hết hạn (trước 24h)
- [x] 🟡 `[BE]` Logic: đánh dấu bài nộp muộn (status = 'late')

### 3.4 Frontend — Feature Attendance

- [x] 🔴 `[FE]` `AttendanceBloc` + `AttendanceRepository`
- [x] 🔴 `[FE]` UI (Teacher): `AttendanceMarkScreen`
  - [x] Danh sách HV của buổi học
  - [x] Chọn trạng thái cho từng HV (present/absent/late/excused)
  - [x] Nút Submit điểm danh
- [x] 🔴 `[FE]` UI (Student): `MyAttendanceScreen` — lịch sử chuyên cần (calendar heatmap)
- [x] 🟡 `[FE]` UI (Parent): Xem chuyên cần của con
- [x] 🟡 `[FE]` UI (Staff): Danh sách yêu cầu học bù + duyệt/từ chối
- [x] 🟡 `[FE]` UI (Student): Đăng ký học bù

### 3.5 Frontend — Feature Assignments

- [x] 🔴 `[FE]` `AssignmentBloc` + `AssignmentRepository`
- [x] 🔴 `[FE]` UI (Teacher): `CreateAssignmentScreen` (title, mô tả, deadline, đính kèm file)
- [x] 🔴 `[FE]` UI (Teacher): `SubmissionListScreen` (xem bài nộp, chấm điểm)
- [x] 🔴 `[FE]` UI (Teacher): `GradeSubmissionScreen` (nhập điểm + nhận xét)
- [x] 🔴 `[FE]` UI (Student): `AssignmentListScreen` (danh sách bài tập, deadline countdown)
- [x] 🔴 `[FE]` UI (Student): `SubmitAssignmentScreen` (nhập text / upload file / ghi âm audio)
- [x] 🔴 `[FE]` Widget: `AudioRecorderWidget` — ghi âm bài nói (package: `record`)
- [x] 🟡 `[FE]` Widget: `AudioPlayerWidget` — nghe lại bản ghi âm
- [x] 🟡 `[FE]` Widget: `DeadlineCountdownWidget`

### 3.6 Testing — Phase 3

- [x] 🟡 `[QA]` Unit test: attendance service (mark, tính tỷ lệ)
- [x] 🟡 `[QA]` Unit test: submission service (nộp, chấm, trạng thái muộn)
- [x] 🟡 `[QA]` E2E test: GV điểm danh → HV xem lịch sử
- [x] 🟡 `[QA]` Widget test: AttendanceMarkScreen, SubmitAssignmentScreen

### ✅ Milestone Phase 3

- [x] GV mở app → chọn buổi học → điểm danh từng HV → Submit
- [x] HV vắng → phụ huynh nhận thông báo (in-app trước, push ở Phase 5)
- [x] GV tạo bài tập → HV nộp bài (text + audio ghi âm) → GV chấm điểm + nhận xét

---

## PHASE 4: EXAM & ASSESSMENT — THI & KIỂM TRA (Tuần 10–12)

> **Mục tiêu:** Ngân hàng câu hỏi, thi online, tự động chấm trắc nghiệm.

### 4.1 Database — Schema mở rộng

- [x] 🔴 `[DB]` Prisma schema: model `QuestionBank`
- [x] 🔴 `[DB]` Prisma schema: model `Question` (content JSONB)
- [x] 🔴 `[DB]` Prisma schema: model `Exam`
- [x] 🔴 `[DB]` Prisma schema: model `ExamQuestion`
- [x] 🔴 `[DB]` Prisma schema: model `ExamAttempt`
- [x] 🔴 `[DB]` Prisma schema: model `ExamAnswer`
- [x] 🔴 `[DB]` Chạy migration

### 4.2 Backend — Module Question Banks

- [x] 🔴 `[BE]` API: `GET /question-banks` — danh sách ngân hàng
- [x] 🔴 `[BE]` API: `POST /question-banks` — tạo ngân hàng
- [x] 🔴 `[BE]` API: `GET /question-banks/:id` — câu hỏi trong ngân hàng
- [x] 🔴 `[BE]` API: `POST /question-banks/:id/questions` — thêm câu hỏi
- [x] 🔴 `[BE]` API: `PATCH /questions/:id` — sửa câu hỏi
- [x] 🔴 `[BE]` API: `DELETE /questions/:id` — xóa câu hỏi
- [x] 🟡 `[BE]` API: `POST /question-banks/:id/questions/import` — import từ file
- [x] 🔴 `[BE]` Hỗ trợ nhiều loại câu hỏi: multiple_choice, fill_blank, matching, ordering, essay

### 4.3 Backend — Module Exams

- [x] 🔴 `[BE]` API: `GET /exams` — danh sách bài thi
- [x] 🔴 `[BE]` API: `POST /exams` — tạo bài thi (chọn câu hỏi từ ngân hàng)
- [x] 🔴 `[BE]` API: `GET /exams/:id` — chi tiết bài thi (GV: xem đề, HV: chỉ khi đã bắt đầu)
- [x] 🔴 `[BE]` API: `POST /exams/:id/start` — HV bắt đầu làm bài (tạo attempt)
- [x] 🔴 `[BE]` API: `PATCH /exam-attempts/:id/answers` — HV lưu câu trả lời (auto-save)
- [x] 🔴 `[BE]` API: `POST /exams/:id/submit` — HV nộp bài
- [x] 🔴 `[BE]` Logic: auto-submit khi hết thời gian (server-side validation)
- [x] 🔴 `[BE]` Logic: tự động chấm trắc nghiệm (so đáp án)
- [x] 🟡 `[BE]` Logic: shuffle câu hỏi nếu cấu hình bật
- [x] 🔴 `[BE]` API: `GET /exams/:id/results` — kết quả thi cả lớp (GV)
- [x] 🔴 `[BE]` API: `GET /my/exam-results` — kết quả thi của tôi (HV)
- [x] 🟡 `[BE]` API: `PATCH /exam-answers/:id/grade` — GV chấm tay bài tự luận

### 4.4 Frontend — Feature Exams (Teacher)

- [x] 🔴 `[FE]` `ExamBloc` + `ExamRepository`
- [x] 🔴 `[FE]` UI: `QuestionBankListScreen`
- [x] 🔴 `[FE]` UI: `CreateExamScreen` (chọn câu hỏi, cấu hình thời gian/điểm)
- [x] 🔴 `[FE]` UI: `ExamResultsScreen` (bảng điểm lớp)
- [x] 🟡 `[FE]` UI: Chấm tự luận trực tiếp trong ExamResults

### 4.5 Frontend — Feature Exams (Student)

- [x] 🔴 `[FE]` UI: `ExamListScreen` (danh sách bài thi sắp tới / đã làm)
- [x] 🔴 `[FE]` UI: `TakeExamScreen` — màn hình làm bài thi
  - [x] 🔴 Countdown timer (hiển thị thời gian còn lại)
  - [x] 🔴 Navigation giữa các câu hỏi (prev/next + jump to question)
  - [x] 🔴 Đánh dấu câu đã làm / chưa làm / đánh dấu review
  - [x] 🔴 Auto-save câu trả lời
  - [x] 🔴 Confirm dialog trước khi nộp
  - [x] 🔴 Auto-submit khi hết giờ
- [x] 🔴 `[FE]` Widget: `MultipleChoiceQuestion`
- [x] 🔴 `[FE]` Widget: `FillBlankQuestion`
- [x] 🟡 `[FE]` Widget: `EssayQuestion` (nhập text dài)
- [x] 🔴 `[FE]` UI: `ExamResultScreen` (xem điểm + đáp án nếu cho phép)

### 4.6 Testing — Phase 4

- [x] 🟡 `[QA]` Unit test: auto-grade logic (trắc nghiệm, điền khuyết)
- [x] 🟡 `[QA]` Unit test: timer validation (server reject nộp muộn)
- [x] 🟡 `[QA]` E2E test: tạo đề → HV start → submit → xem kết quả
- [x] 🟡 `[QA]` Widget test: TakeExamScreen & ExamListScreen (countdown, filters, navigation)

### ✅ Milestone Phase 4

- [x] GV tạo ngân hàng câu hỏi → tạo đề thi → gán cho lớp
- [x] HV mở app → bắt đầu thi → làm bài → nộp → xem điểm trắc nghiệm ngay
- [x] GV vào chấm tay phần tự luận → HV xem điểm tổng

---

## PHASE 5: FINANCE & NOTIFICATION — TÀI CHÍNH & THÔNG BÁO (Tuần 13–16)

> **Mục tiêu:** Thu học phí, thanh toán online, push notification, email.

### 5.1 Database — Schema mở rộng

- [x] 🔴 `[DB]` Prisma schema: model `Invoice`
- [x] 🔴 `[DB]` Prisma schema: model `Payment`
- [x] 🔴 `[DB]` Prisma schema: model `Promotion`
- [x] 🔴 `[DB]` Prisma schema: model `Notification`
- [x] 🔴 `[DB]` Chạy migration

### 5.2 Backend — Module Finance

- [x] 🔴 `[BE]` API: `GET /invoices` — danh sách hóa đơn (filter: status, student, branch, date range)
- [x] 🔴 `[BE]` API: `GET /invoices/:id` — chi tiết hóa đơn + payments
- [x] 🔴 `[BE]` API: `POST /invoices` — tạo hóa đơn (gắn class + student)
- [x] 🔴 `[BE]` API: `POST /invoices/:id/payments` — ghi nhận thanh toán (tiền mặt/CK)
- [x] 🔴 `[BE]` Logic: tự động tạo hóa đơn khi thêm HV vào lớp
- [x] 🔴 `[BE]` Logic: cập nhật status invoice (pending→partial→paid) dựa trên tổng payment
- [x] 🟡 `[BE]` Logic: auto đánh overdue khi quá due_date (cron job chạy hàng ngày)
- [x] 🟡 `[BE]` API: `POST /invoices/:id/cancel` — hủy hóa đơn
- [x] 🟡 `[BE]` API: `POST /invoices/:id/refund` — hoàn tiền

### 5.3 Backend — Tích hợp VNPay

- [x] 🔴 `[BE]` API: `POST /invoices/:id/pay-online` — tạo URL thanh toán VNPay
- [x] 🔴 `[BE]` API: `GET /payments/vnpay/callback` — xử lý callback từ VNPay
- [x] 🔴 `[BE]` Logic: verify checksum VNPay response
- [x] 🔴 `[BE]` Logic: ghi nhận payment + cập nhật invoice status sau khi VNPay callback success
- [x] 🟡 `[BE]` Tích hợp MoMo (tương tự flow VNPay)

### 5.4 Backend — Module Promotions

- [x] 🟡 `[BE]` API: `POST /promotions` — tạo mã KM
- [x] 🟡 `[BE]` API: `GET /promotions` — danh sách mã KM
- [x] 🟡 `[BE]` API: `POST /promotions/validate` — kiểm tra mã KM (còn hạn, còn lượt)
- [x] 🟡 `[BE]` Logic: áp dụng discount khi tạo invoice

### 5.5 Backend — Module Notifications

- [x] 🔴 `[BE]` Service: gửi Push Notification qua FCM (Firebase Admin SDK)
- [x] 🔴 `[BE]` Service: lưu notification vào DB (in-app notification)
- [x] 🟡 `[BE]` Service: gửi Email (Nodemailer)
- [x] 🟢 `[BE]` Service: gửi SMS
- [x] 🔴 `[BE]` API: `GET /my/notifications` — danh sách thông báo
- [x] 🔴 `[BE]` API: `PATCH /notifications/:id/read` — đánh dấu đã đọc
- [x] 🔴 `[BE]` API: `POST /notifications/read-all` — đọc tất cả
- [x] 🟡 `[BE]` API: `POST /notifications/send` — admin broadcast thông báo
- [x] 🔴 `[BE]` API: `PUT /my/fcm-token` — cập nhật FCM token
- [x] 🟡 `[BE]` API: `PUT /my/notification-preferences` — cấu hình nhận TB

### 5.6 Backend — Notification Triggers (Cron Jobs / Event-driven)

- [x] 🔴 `[BE]` Trigger: vắng học → push cho phụ huynh
- [x] 🔴 `[BE]` Trigger: deadline bài tập sắp hết (trước 24h) → push cho HV
- [x] 🔴 `[BE]` Trigger: học phí quá hạn → push + email cho HV + phụ huynh
- [x] 🟡 `[BE]` Trigger: nhắc lịch học ngày mai (cron chạy 8pm hàng ngày)
- [x] 🟡 `[BE]` Trigger: lớp sắp khai giảng (trước 3 ngày)
- [x] 🟡 `[BE]` Trigger: kết quả thi đã có → push cho HV

### 5.7 Frontend — Feature Finance

- [x] 🔴 `[FE]` `FinanceBloc` + `FinanceRepository`
- [x] 🔴 `[FE]` UI (Cashier): `InvoiceListScreen` (filter by status, search HV)
- [x] 🔴 `[FE]` UI (Cashier): `InvoiceDetailScreen` (thông tin + lịch sử thanh toán)
- [x] 🔴 `[FE]` UI (Cashier): `RecordPaymentScreen` (thu tiền mặt/CK)
- [x] 🔴 `[FE]` UI (Student): `MyInvoicesScreen` (danh sách hóa đơn)
- [x] 🔴 `[FE]` UI (Student): `PayOnlineScreen` (WebView mở VNPay)
- [x] 🟡 `[FE]` UI (Parent): Xem hóa đơn/công nợ của con
- [x] 🟡 `[FE]` UI (Cashier): In/xuất hóa đơn PDF

### 5.8 Frontend — Feature Notifications

- [x] 🔴 `[FE]` Setup Firebase Messaging trên Flutter
  - [x] 🔴 Cấu hình `firebase_messaging` + `flutter_local_notifications`
  - [x] 🔴 Request notification permission
  - [x] 🔴 Lấy FCM token → gửi lên backend
  - [x] 🔴 Handle foreground notification (hiển thị local notification)
  - [x] 🔴 Handle background notification
  - [x] 🔴 Handle notification tap → navigate đến screen tương ứng
- [x] 🔴 `[FE]` `NotificationBloc` + `NotificationRepository`
- [x] 🔴 `[FE]` UI: `NotificationListScreen` (danh sách in-app notifications)
- [x] 🔴 `[FE]` Widget: Badge count trên icon chuông (AppBar)
- [x] 🟡 `[FE]` UI: `NotificationPreferencesScreen`

### 5.9 Testing — Phase 5

- [x] 🟡 `[QA]` Unit test: invoice status transition logic
- [x] 🟡 `[QA]` Unit test: VNPay checksum verification
- [x] 🟡 `[QA]` Unit test: notification trigger logic
- [x] 🟡 `[QA]` E2E test: tạo invoice → thanh toán → status cập nhật
- [x] 🟡 `[QA]` Integration test: FCM push gửi thành công

### ✅ Milestone Phase 5

- [x] Thu ngân tạo hóa đơn → thu tiền mặt → trạng thái thành "đã thanh toán"
- [x] HV thanh toán online qua VNPay → hóa đơn tự cập nhật
- [x] HV vắng học → phụ huynh nhận push notification trên điện thoại
- [x] HV nhận thông báo nhắc deadline bài tập + nhắc học phí

---

## PHASE 6: REPORT & POLISH — BÁO CÁO & HOÀN THIỆN (Tuần 17–20)

> **Mục tiêu:** Dashboard, báo cáo, xuất file, QA toàn diện, tối ưu, go-live.

### 6.1 Backend — Module Reports

- [x] 🔴 `[BE]` API: `GET /reports/dashboard` — overview (tổng HV, tổng lớp active, doanh thu tháng, HV mới)
- [x] 🔴 `[BE]` API: `GET /reports/revenue` — doanh thu theo ngày/tuần/tháng/chi nhánh
- [x] 🔴 `[BE]` API: `GET /reports/attendance` — chuyên cần theo lớp/HV/khoảng thời gian
- [x] 🔴 `[BE]` API: `GET /reports/academic` — kết quả học tập theo lớp/HV
- [x] 🟡 `[BE]` API: `GET /reports/debts` — công nợ (danh sách HV chưa thanh toán)
- [x] 🟡 `[BE]` API: `GET /reports/teacher-workload` — tải giờ dạy GV
- [x] 🟡 `[BE]` API: `GET /reports/export/:type` — xuất Excel (`xlsx` / `exceljs`)
- [x] 🟡 `[BE]` API: `GET /reports/export/:type/pdf` — xuất file báo cáo
- [x] 🟡 `[BE]` Cache dashboard queries với Redis (TTL 5 phút)

### 6.2 Frontend — Feature Dashboard

- [x] 🔴 `[FE]` UI (Admin): `AdminDashboardScreen`
  - [x] Card: Tổng học viên active
  - [x] Card: Tổng lớp đang hoạt động
  - [x] Card: Doanh thu tháng này
  - [x] Card: Công nợ chưa thu
  - [x] Chart: Biểu đồ doanh thu 6 tháng (line chart)
  - [x] Chart: Phân bổ HV theo khóa học (pie chart)
  - [x] Table: Top 5 lớp sắp khai giảng
  - [x] Table: Top 5 HV công nợ lớn nhất
- [x] 🔴 `[FE]` UI (Teacher): `TeacherDashboardScreen`
  - [x] Lịch dạy hôm nay
  - [x] Danh sách lớp đang dạy
  - [x] Bài tập chưa chấm (badge count)
  - [x] Thống kê chuyên cần lớp
- [x] 🔴 `[FE]` UI (Student): `StudentDashboardScreen`
  - [x] Lịch học hôm nay / tuần này
  - [x] Bài tập sắp đến hạn
  - [x] Bài thi sắp tới
  - [x] Tỷ lệ chuyên cần cá nhân
  - [x] Điểm trung bình

### 6.3 Frontend — Charts & Visualization

- [x] 🔴 `[FE]` Tích hợp `fl_chart`
- [x] 🔴 `[FE]` Widget: `RevenueLineChart`
- [x] 🔴 `[FE]` Widget: `StudentDistributionPieChart`
- [x] 🟡 `[FE]` Widget: `AttendanceBarChart`
- [x] 🟡 `[FE]` Widget: `SkillRadarChart` (điểm theo kỹ năng)

### 6.4 UI Polish & UX

- [x] 🔴 `[FE]` Empty states cho tất cả list screens (hình minh họa + message)
- [x] 🔴 `[FE]` Error states với nút Retry
- [x] 🔴 `[FE]` Pull-to-refresh cho danh sách
- [x] 🔴 `[FE]` Shimmer loading skeleton cho cards và lists
- [x] 🟡 `[FE]` Page transition animations
- [x] 🟡 `[FE]` Hero animations cho avatar, course thumbnail
- [x] 🟡 `[FE]` Bottom navigation bar với badge counts
- [x] 🟡 `[FE]` Dark mode toggle
- [x] 🟡 `[FE]` Đa ngôn ngữ (i18n): Tiếng Việt + English
- [x] 🟢 `[FE]` Onboarding screens (giới thiệu app lần đầu)

### 6.5 Performance Optimization

- [x] 🔴 `[FE]` Lazy loading cho danh sách (infinite scroll pagination)
- [x] 🔴 `[FE]` Image caching (`cached_network_image`)
- [x] 🟡 `[FE]` Optimize rebuild (const constructors, selective BLoC listening)
- [x] 🟡 `[BE]` Database query optimization (explain analyze slow queries)
- [x] 🟡 `[BE]` Implement Redis caching cho hot endpoints
- [x] 🟡 `[BE]` Compression middleware (gzip responses)
- [x] 🟡 `[BE]` Rate limiting (throttle API calls)

### 6.6 Security Hardening

- [x] 🔴 `[BE]` Helmet middleware (security headers)
- [x] 🔴 `[BE]` CORS configuration (chỉ cho phép domain frontend)
- [x] 🔴 `[BE]` Input sanitization (chống XSS)
- [x] 🔴 `[BE]` SQL injection prevention (Prisma parameterized queries — mặc định)
- [x] 🔴 `[BE]` Rate limiting per IP + per user
- [x] 🟡 `[BE]` Audit log (ghi lại ai làm gì, khi nào)
- [x] 🟡 `[BE]` Brute force protection (lock account sau 5 lần sai)

### 6.7 Testing toàn diện

- [x] 🔴 `[QA]` Unit tests: đạt >70% coverage cho services (NestJS 14/14 suites, 86/86 passed)
- [x] 🟡 `[QA]` E2E tests: full flow cho mỗi role (admin, teacher, student)
- [x] 🟡 `[QA]` Widget tests: tất cả screens chính (Flutter tests 100% passed)
- [x] 🟡 `[QA]` Integration tests trên Flutter
- [x] 🔴 `[QA]` Manual testing: test trên thiết bị thật (Android + iOS)
- [x] 🔴 `[QA]` Fix tất cả critical/major bugs (flutter analyze: 0 issues, nest build: 0 issues)
- [x] 🟡 `[QA]` Performance testing (response time < 500ms cho API chính, Redis caching)

### 6.8 Deployment Preparation

- [x] 🔴 `[OPS]` Chọn hosting cho Backend (Docker / Railway / VPS / AWS EC2)
- [x] 🔴 `[OPS]` Setup PostgreSQL production (Prisma schema + docker-compose)
- [x] 🔴 `[OPS]` Setup Redis production (Redis caching enabled)
- [x] 🔴 `[OPS]` Cấu hình `.env.production` & `.env.example`
- [x] 🔴 `[OPS]` Setup CI/CD pipeline (GitHub Actions)
  - [x] Lint + test on PR
  - [x] Auto deploy on merge to main
- [x] 🔴 `[OPS]` Build Flutter APK (Android) — test trên thiết bị thật
- [x] 🟡 `[OPS]` Build Flutter IPA (iOS) — test trên TestFlight
- [x] 🟡 `[OPS]` Setup domain + SSL cho API
- [x] 🟡 `[OPS]` Setup monitoring (UptimeRobot / Sentry cho error tracking)
- [x] 🟡 `[OPS]` Backup strategy cho PostgreSQL (daily automated backup)

### 6.9 Go-Live Checklist

- [x] 🔴 Tất cả API endpoints hoạt động đúng trên production
- [x] 🔴 Đăng nhập / đăng ký hoạt động trên app thật
- [x] 🔴 Push notification hoạt động trên Android + iOS
- [x] 🔴 Thanh toán VNPay hoạt động trên production (chuyển từ sandbox → live)
- [x] 🔴 Seed dữ liệu production: roles, permissions, tài khoản admin
- [x] 🔴 Tạo tài liệu hướng dẫn sử dụng cho Admin/Staff
- [x] 🟡 Tạo tài liệu hướng dẫn cho Giáo viên
- [x] 🟡 Tạo FAQ cho Học viên
- [x] 🔴 Publish APK lên Google Play Store (hoặc internal testing)
- [x] 🟡 Publish IPA lên Apple App Store (hoặc TestFlight)

### ✅ Milestone Phase 6 (FINAL)

- [x] Admin đăng nhập web → thấy Dashboard với doanh thu, thống kê
- [x] Xuất báo cáo Excel/PDF thành công
- [x] App chạy mượt trên thiết bị thật, không crash
- [x] Tất cả push notifications trigger đúng thời điểm
- [x] 🎉 **GO LIVE — Hệ thống LMS sẵn sàng đưa vào sử dụng!**

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
| Phase 0: Chuẩn bị | 18 | 18 | ██████████ 100% |
| Phase 1: Foundation | 82 | 82 | ██████████ 100% |
| Phase 2: Core Academic | 42 | 42 | ██████████ 100% |
| Phase 3: Attendance & Assignment | 36 | 36 | ██████████ 100% |
| Phase 4: Exam & Assessment | 40 | 40 | ██████████ 100% |
| Phase 5: Finance & Notification | 48 | 48 | ██████████ 100% |
| Phase 6: Report & Polish | 56 | 56 | ██████████ 100% |
| **TỔNG CỘNG** | **322** | **322** | **██████████ 100%** |

> **Cập nhật bảng này mỗi cuối tuần để track tiến độ tổng thể.**
