# 📘 KẾ HOẠCH XÂY DỰNG HỆ THỐNG LMS TRUNG TÂM NGOẠI NGỮ

> **Dự án:** LMS Trung Tâm Ngoại Ngữ
> **Ngày tạo:** 2026-09-27
> **Tech Stack:** Flutter (Dart) · NestJS (Node.js/TypeScript) · PostgreSQL · Firebase Services
> **Mục tiêu:** Hệ thống quản lý học tập toàn diện cho trung tâm ngoại ngữ — từ tuyển sinh, xếp lớp, điểm danh, thi cử, đến thu học phí và báo cáo.

---

## MỤC LỤC

1. [Tổng quan kiến trúc hệ thống](#1-tổng-quan-kiến-trúc-hệ-thống)
2. [Đối tượng sử dụng & Phân quyền (RBAC)](#2-đối-tượng-sử-dụng--phân-quyền-rbac)
3. [Danh sách module chức năng](#3-danh-sách-module-chức-năng)
4. [Thiết kế cơ sở dữ liệu (ERD)](#4-thiết-kế-cơ-sở-dữ-liệu-erd)
5. [Cấu trúc thư mục Backend (NestJS)](#5-cấu-trúc-thư-mục-backend-nestjs)
6. [Cấu trúc thư mục Frontend (Flutter)](#6-cấu-trúc-thư-mục-frontend-flutter)
7. [Thiết kế API (RESTful)](#7-thiết-kế-api-restful)
8. [Tích hợp Firebase Services](#8-tích-hợp-firebase-services)
9. [Lộ trình triển khai (6 Phase)](#9-lộ-trình-triển-khai-6-phase)
10. [Cấu hình môi trường & DevOps](#10-cấu-hình-môi-trường--devops)
11. [Danh sách packages/dependencies](#11-danh-sách-packagesdependencies)

---

## 1. TỔNG QUAN KIẾN TRÚC HỆ THỐNG

```mermaid
flowchart TD
    subgraph CLIENT["📱 Client Layer"]
        MOBILE["Flutter Mobile App\n(iOS / Android)\nHọc viên · Giáo viên"]
        WEB["Flutter Web App\nAdmin · Học vụ · Thu ngân"]
    end

    subgraph API["⚙️ API Layer"]
        GATEWAY["NestJS API Gateway\n(REST + WebSocket)"]
        AUTH["Auth Module\n(JWT + Refresh Token)"]
        GUARD["Role Guard\n(RBAC Middleware)"]
    end

    subgraph DATA["💾 Data Layer"]
        PG["PostgreSQL\n(Primary Database)"]
        REDIS["Redis\n(Cache + Job Queue)"]
    end

    subgraph FIREBASE["🔥 Firebase Services"]
        FCM["Cloud Messaging\n(Push Notification)"]
        STORAGE["Cloud Storage\n(Files/Audio/PDF)"]
    end

    subgraph EXTERNAL["🌐 External Services"]
        PAYMENT["Cổng thanh toán\n(VNPay / MoMo)"]
        MAIL["Email Service\n(Nodemailer / SendGrid)"]
        SMS["SMS Gateway\n(Twilio / Viettel)"]
    end

    MOBILE --> GATEWAY
    WEB --> GATEWAY
    GATEWAY --> AUTH
    GATEWAY --> GUARD
    GATEWAY --> PG
    GATEWAY --> REDIS
    GATEWAY --> FCM
    GATEWAY --> STORAGE
    GATEWAY --> PAYMENT
    GATEWAY --> MAIL
    GATEWAY --> SMS
```

### Nguyên tắc kiến trúc

| Nguyên tắc | Mô tả |
|:---|:---|
| **Monorepo** | Một repository chứa cả `frontend/` (Flutter) và `backend/` (NestJS) để dễ quản lý version |
| **Clean Architecture** | Tách biệt rõ ràng: Presentation → Domain (Use Cases) → Data (Repository) |
| **Feature-first** | Mỗi module/feature là 1 thư mục độc lập, chứa đầy đủ model/bloc/screen/widget |
| **API Versioning** | Tất cả API bắt đầu bằng `/api/v1/` để dễ nâng cấp sau |
| **Stateless Backend** | Server không lưu session, dùng JWT để xác thực mỗi request |

---

## 2. ĐỐI TƯỢNG SỬ DỤNG & PHÂN QUYỀN (RBAC)

### 2.1 Các vai trò (Roles)

| Vai trò | Mã role | Nền tảng | Mô tả |
|:---|:---|:---|:---|
| **Super Admin** | `super_admin` | Web | Quản trị toàn hệ thống, cấu hình chung, quản lý chi nhánh |
| **Admin Chi nhánh** | `branch_admin` | Web | Quản lý 1 chi nhánh cụ thể |
| **Nhân viên Học vụ** | `academic_staff` | Web | Xếp lớp, xếp lịch, điểm danh, quản lý học viên |
| **Thu ngân** | `cashier` | Web | Quản lý học phí, hóa đơn, công nợ |
| **Giáo viên** | `teacher` | Mobile + Web | Điểm danh, nhập điểm, giao bài tập, xem lịch dạy |
| **Trợ giảng** | `teaching_assistant` | Mobile | Hỗ trợ điểm danh, quản lý lớp |
| **Học viên** | `student` | Mobile | Xem lịch học, điểm, nộp bài, làm bài thi, nhận thông báo |
| **Phụ huynh** | `parent` | Mobile | Xem điểm, chuyên cần, học phí của con |

### 2.2 Ma trận phân quyền (Permission Matrix)

```
                          SuperAdmin  BranchAdmin  AcademicStaff  Cashier  Teacher  Student  Parent
Quản lý chi nhánh              ✅          ❌            ❌          ❌       ❌       ❌       ❌
Quản lý người dùng             ✅          ✅            ❌          ❌       ❌       ❌       ❌
Quản lý khóa học               ✅          ✅            ✅          ❌       ❌       ❌       ❌
Xếp lớp / Xếp lịch            ✅          ✅            ✅          ❌       ❌       ❌       ❌
Điểm danh                      ❌          ❌            ✅          ❌       ✅       ❌       ❌
Nhập điểm / Chấm bài          ❌          ❌            ❌          ❌       ✅       ❌       ❌
Giao bài tập                  ❌          ❌            ❌          ❌       ✅       ❌       ❌
Quản lý học phí               ✅          ✅            ❌          ✅       ❌       ❌       ❌
Xem điểm / lịch học           ❌          ❌            ❌          ❌       ✅       ✅       ✅
Nộp bài tập                   ❌          ❌            ❌          ❌       ❌       ✅       ❌
Làm bài thi online            ❌          ❌            ❌          ❌       ❌       ✅       ❌
Xem báo cáo tổng hợp         ✅          ✅            ✅          ✅       ❌       ❌       ❌

### 2.3 Quy tắc quản lý tài khoản & Phân quyền nghiệp vụ

1. **Cấp phát tài khoản tập trung bởi Trung tâm:**
   - Trung tâm/Admin chịu trách nhiệm tạo và cấp tài khoản cho Quản trị viên, Giáo viên, Học viên và Phụ huynh.
   - **Học viên và Phụ huynh KHÔNG tự đăng ký tài khoản học viên chính thức** trên ứng dụng để tránh sai lệch dữ liệu lớp học, khóa học.
2. **Liên kết dữ liệu học vụ bắt buộc:**
   - Mọi tài khoản học viên khi tạo ra bắt buộc phải liên kết với Hồ sơ học viên (`student_profiles`), Lớp học (`classes`), Khóa học (`courses`), lịch học, điểm danh và học phí tương ứng.
   - Tài khoản phụ huynh bắt buộc liên kết với một hoặc nhiều học viên tương ứng (`parent_students`). Phụ huynh chỉ được theo dõi dữ liệu của con mình.
3. **Quy trình kích hoạt & Đăng nhập lần đầu:**
   - Khi được cấp tài khoản, người dùng nhận thông tin đăng nhập tạm thời.
   - Khi đăng nhập lần đầu, hệ thống yêu cầu xác thực thông tin và **bắt buộc thiết lập mật khẩu cá nhân mới** (`is_first_login = false`).
4. **Cơ chế dành cho người dùng mới (Đăng ký nhu cầu học tập):**
   - Khách vãng lai có thể gửi thông tin đăng ký tư vấn qua ứng dụng/web. Thao tác này chỉ tạo **Yêu cầu tư vấn (Lead)**, không cấp tài khoản học viên chính thức.
   - Nhân viên học vụ tiếp nhận, tư vấn, kiểm tra đầu vào, xác nhận nhập học và thực hiện thao tác **Chuyển đổi thành học viên chính thức** (hệ thống tự động sinh tài khoản, liên kết lớp và gửi thông tin kích hoạt).
5. **Quyền hạn quản trị tài khoản:**
   - Admin/Học vụ có quyền xem, chỉnh sửa, khóa/mở khóa tài khoản và **Đặt lại mật khẩu tạm thời** khi người dùng có yêu cầu hỗ trợ.

---

## 3. DANH SÁCH MODULE CHỨC NĂNG

### 🔐 Module 1: Xác thực & Bảo mật (Auth)
- [ ] Đăng nhập bằng email/phone/mã tài khoản + mật khẩu
- [ ] Quy trình kích hoạt & Đổi mật khẩu lần đầu (`is_first_login = true`)
- [ ] Đăng nhập bằng Google / Facebook (OAuth2 liên kết tài khoản đã cấp)
- [ ] JWT Access Token (15 phút) + Refresh Token (7 ngày)
- [ ] Quên mật khẩu → gửi OTP qua email/SMS
- [ ] Đổi mật khẩu cá nhân
- [ ] Phân quyền RBAC theo role + permissions
- [ ] Middleware guard kiểm tra quyền truy cập mỗi endpoint

### 🎯 Module 2: Tiếp nhận Tuyển sinh & Tư vấn (Admissions & Leads)
- [ ] Form đăng ký nhu cầu học tập cho khách vãng lai (Public Lead Form)
- [ ] Quản lý danh sách yêu cầu tư vấn (lọc theo ngày, khóa học, chi nhánh, trạng thái)
- [ ] Ghi nhận tiến trình tư vấn, kết quả test đầu vào, lớp dự kiến
- [ ] Chuyển đổi Lead thành Học viên chính thức (tự động tạo hồ sơ, sinh tài khoản, xếp lớp, tạo hóa đơn)

### 🏢 Module 3: Quản lý Chi nhánh & Phòng học (Branch & Room)
- [ ] CRUD chi nhánh (tên, địa chỉ, hotline, giờ làm việc)
- [ ] Quản lý phòng học theo chi nhánh (tên phòng, sức chứa, trang thiết bị)
- [ ] Kiểm tra phòng trống theo khung giờ
- [ ] Cấu hình riêng cho từng chi nhánh (logo, quy định)

### 👤 Module 4: Quản lý Người dùng & Cấp phát tài khoản (User Management)
- [ ] Tạo & Cấp phát tài khoản học viên (tự động sinh mã HV, tạo StudentProfile, gắn lớp học)
- [ ] Tạo & Cấp phát tài khoản phụ huynh (bắt buộc liên kết với 1 hoặc nhiều học viên)
- [ ] Tạo & Cấp phát tài khoản giáo viên/nhân viên (kèm hồ sơ chuyên môn)
- [ ] Khóa / Mở khóa tài khoản (soft delete / activate)
- [ ] Đặt lại mật khẩu bởi Admin (Admin Reset Password / cấp mật khẩu tạm thời)
- [ ] Import danh sách học viên từ Excel
- [ ] Liên kết tài khoản Phụ huynh ↔ Học viên
- [ ] Phân quyền & Quản lý vai trò (Role Assignment)

### 📚 Module 4: Quản lý Khóa học & Chương trình học (Course)
- [ ] CRUD khóa học (tên, mô tả, ngôn ngữ, trình độ, số buổi, học phí)
- [ ] Cấu trúc chương trình học theo cấp độ: Khóa học → Level → Module → Bài học
- [ ] Quản lý tài liệu/giáo trình (PDF, audio, video) gắn theo bài học
- [ ] Đặt điều kiện tiên quyết (prerequisite) giữa các level

### 🏫 Module 5: Quản lý Lớp học (Class)
- [ ] Tạo lớp học (gắn khóa học, giáo viên, phòng, ca học, ngày bắt đầu)
- [ ] Thiết lập lịch học cố định (VD: T2-T4-T6, 18:00-19:30)
- [ ] Tự động sinh danh sách buổi học (sessions) từ lịch cố định
- [ ] Thêm/xóa học viên khỏi lớp
- [ ] Xem danh sách lớp đang mở / đã kết thúc / sắp khai giảng
- [ ] Giới hạn sĩ số tối đa
- [ ] Trạng thái lớp: `waiting` → `active` → `completed` → `archived`

### ✅ Module 6: Điểm danh (Attendance)
- [ ] Giáo viên điểm danh từng buổi học trên app (có mặt / vắng có phép / vắng không phép / đi trễ)
- [ ] Học viên xem lịch sử điểm danh cá nhân
- [ ] Phụ huynh nhận thông báo khi con vắng học
- [ ] Quản lý học bù: đăng ký bù ở lớp khác cùng level
- [ ] Báo cáo tỷ lệ chuyên cần theo lớp/học viên
- [ ] Đánh dấu buổi nghỉ lễ / giáo viên nghỉ

### 📝 Module 7: Bài tập & Nộp bài (Assignment)
- [ ] Giáo viên tạo bài tập (text, file đính kèm, deadline)
- [ ] Giao bài tập cho lớp / nhóm học viên
- [ ] Học viên nộp bài (text, file, audio ghi âm cho bài nói)
- [ ] Giáo viên chấm điểm + nhận xét
- [ ] Trạng thái bài tập: `assigned` → `submitted` → `graded` → `returned`
- [ ] Thông báo nhắc deadline

### 🎓 Module 8: Thi & Kiểm tra (Exam)
- [ ] Tạo ngân hàng câu hỏi (trắc nghiệm, tự luận, điền khuyết, nối, sắp xếp câu)
- [ ] Gắn tag câu hỏi theo: kỹ năng (Listening/Reading/Writing/Speaking), level, chủ đề
- [ ] Tạo đề thi từ ngân hàng câu hỏi (ngẫu nhiên hoặc cố định)
- [ ] Cấu hình bài thi: thời gian, số câu, điểm đạt, cho phép xem lại đáp án
- [ ] Học viên làm bài thi online trên app (auto-submit khi hết giờ)
- [ ] Tự động chấm trắc nghiệm, giáo viên chấm tay tự luận
- [ ] Bảng điểm chi tiết theo từng kỹ năng

### 💰 Module 9: Quản lý Học phí & Tài chính (Finance)
- [ ] Tạo phiếu thu học phí khi học viên đăng ký lớp
- [ ] Hỗ trợ thanh toán: tiền mặt, chuyển khoản, VNPay, MoMo
- [ ] Đóng học phí theo đợt (trả góp)
- [ ] Quản lý công nợ (ai chưa đóng, quá hạn bao lâu)
- [ ] Phiếu hoàn tiền khi học viên hủy/bảo lưu
- [ ] Áp dụng mã khuyến mãi / giảm giá
- [ ] In/xuất hóa đơn PDF
- [ ] Quản lý lương giáo viên (theo giờ dạy thực tế)
- [ ] Báo cáo doanh thu theo ngày/tuần/tháng/chi nhánh

### 🔔 Module 10: Thông báo (Notification)
- [ ] Push notification qua Firebase Cloud Messaging (FCM)
- [ ] Thông báo in-app (danh sách thông báo trong ứng dụng)
- [ ] Gửi email tự động (xác nhận đăng ký, nhắc học phí, nhắc lịch học)
- [ ] Gửi SMS (tùy chọn, cho thông báo quan trọng)
- [ ] Cấu hình loại thông báo muốn nhận (preferences)
- [ ] Các trigger tự động:
  - Vắng học → thông báo phụ huynh
  - Sắp đến deadline bài tập → nhắc học viên
  - Học phí quá hạn → nhắc học viên + phụ huynh
  - Lớp sắp khai giảng → nhắc học viên

### 📊 Module 11: Báo cáo & Dashboard (Report)
- [ ] Dashboard tổng quan cho Admin: tổng học viên, tổng lớp đang hoạt động, doanh thu tháng
- [ ] Biểu đồ doanh thu theo thời gian
- [ ] Báo cáo tỷ lệ chuyên cần theo lớp
- [ ] Báo cáo kết quả học tập theo lớp/học viên
- [ ] Báo cáo công nợ (danh sách chưa thanh toán)
- [ ] Báo cáo tải giờ dạy giáo viên
- [ ] Xuất báo cáo Excel/PDF

### 💬 Module 12: Chat & Trao đổi (Messaging) — *Phase sau*
- [ ] Chat 1-1 giữa giáo viên và học viên
- [ ] Chat nhóm theo lớp học
- [ ] Gửi file/hình ảnh trong chat
- [ ] Thông báo tin nhắn mới (badge count)

### 🃏 Module 13: Flashcard & Từ vựng — *Phase sau*
- [ ] Bộ flashcard từ vựng theo bài học/chủ đề
- [ ] Chế độ học: lật thẻ, trắc nghiệm, viết lại
- [ ] Thuật toán ôn tập cách quãng (Spaced Repetition - SM2)
- [ ] Theo dõi tiến độ từ vựng đã thuộc

---

## 4. THIẾT KẾ CƠ SỞ DỮ LIỆU (ERD)

### 4.1 Sơ đồ quan hệ thực thể

```mermaid
erDiagram
    BRANCH ||--o{ ROOM : has
    BRANCH ||--o{ USER : belongs_to

    USER ||--o{ USER_ROLE : has
    ROLE ||--o{ USER_ROLE : assigned_to
    ROLE ||--o{ ROLE_PERMISSION : has
    PERMISSION ||--o{ ROLE_PERMISSION : assigned_to

    USER ||--o{ STUDENT_PROFILE : has
    USER ||--o{ TEACHER_PROFILE : has
    USER ||--o{ PARENT_STUDENT : is_parent
    USER ||--o{ PARENT_STUDENT : is_student

    COURSE ||--o{ COURSE_LEVEL : has
    COURSE_LEVEL ||--o{ MODULE : contains
    MODULE ||--o{ LESSON : contains
    LESSON ||--o{ LESSON_MATERIAL : has

    COURSE ||--o{ CLASS : offers
    CLASS ||--o{ CLASS_STUDENT : enrolls
    CLASS }o--|| ROOM : uses
    CLASS }o--|| USER : taught_by
    CLASS ||--o{ CLASS_SESSION : generates

    CLASS_SESSION ||--o{ ATTENDANCE : records
    ATTENDANCE }o--|| USER : for_student

    CLASS ||--o{ ASSIGNMENT : has
    ASSIGNMENT ||--o{ SUBMISSION : receives
    SUBMISSION }o--|| USER : submitted_by

    QUESTION_BANK ||--o{ QUESTION : contains
    EXAM ||--o{ EXAM_QUESTION : includes
    QUESTION ||--o{ EXAM_QUESTION : used_in
    EXAM ||--o{ EXAM_ATTEMPT : taken_by
    EXAM_ATTEMPT }o--|| USER : by_student
    EXAM_ATTEMPT ||--o{ EXAM_ANSWER : contains

    CLASS_STUDENT ||--o{ INVOICE : generates
    INVOICE ||--o{ PAYMENT : paid_by
    USER ||--o{ INVOICE : owes

    USER ||--o{ NOTIFICATION : receives
```

### 4.2 Chi tiết các bảng chính

#### 🏢 Bảng `branches` — Chi nhánh

```sql
CREATE TABLE branches (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    address         TEXT,
    phone           VARCHAR(20),
    email           VARCHAR(100),
    logo_url        VARCHAR(500),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

#### 🏠 Bảng `rooms` — Phòng học

```sql
CREATE TABLE rooms (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id       UUID NOT NULL REFERENCES branches(id),
    name            VARCHAR(100) NOT NULL,          -- "Phòng A1", "Phòng Lab 2"
    capacity        INT NOT NULL DEFAULT 20,
    equipment       TEXT[],                          -- {'projector','speaker','whiteboard'}
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

#### 👤 Bảng `users` — Người dùng

```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE,
    phone           VARCHAR(20) UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    avatar_url      VARCHAR(500),
    date_of_birth   DATE,
    gender          VARCHAR(10),                     -- 'male','female','other'
    address         TEXT,
    branch_id       UUID REFERENCES branches(id),
    is_active       BOOLEAN DEFAULT true,
    is_first_login  BOOLEAN DEFAULT true,            -- Bắt buộc kích hoạt & đổi MK khi đăng nhập lần đầu
    last_login_at   TIMESTAMPTZ,
    fcm_token       VARCHAR(500),                    -- Firebase token cho push notification
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng đăng ký nhu cầu học tập / Khách vãng lai (Leads)
CREATE TABLE admission_leads (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name               VARCHAR(200) NOT NULL,
    phone                   VARCHAR(20) NOT NULL,
    email                   VARCHAR(255),
    course_id               UUID REFERENCES courses(id),
    target_goal             TEXT,                            -- Mục tiêu học tập
    branch_id               UUID REFERENCES branches(id),
    status                  VARCHAR(30) DEFAULT 'new',       -- 'new','contacted','tested','enrolled','cancelled'
    notes                   TEXT,
    assigned_staff_id       UUID REFERENCES users(id),       -- Nhân viên tư vấn phụ trách
    converted_student_id    UUID REFERENCES users(id),       -- Tài khoản học viên chính thức sau khi chuyển đổi
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);
```

#### 🎭 Bảng `roles`, `permissions`, `user_roles`, `role_permissions` — RBAC

```sql
CREATE TABLE roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(50) UNIQUE NOT NULL,     -- 'super_admin','teacher','student'...
    display_name    VARCHAR(100) NOT NULL,
    description     TEXT
);

CREATE TABLE permissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) UNIQUE NOT NULL,    -- 'class.create','attendance.mark'...
    module          VARCHAR(50) NOT NULL,             -- 'class','attendance','finance'...
    description     TEXT
);

CREATE TABLE user_roles (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    branch_id       UUID REFERENCES branches(id),    -- Quyền theo chi nhánh
    PRIMARY KEY (user_id, role_id, branch_id)
);

CREATE TABLE role_permissions (
    role_id         UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id   UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
```

#### 🎓 Bảng `student_profiles` — Hồ sơ Học viên

```sql
CREATE TABLE student_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    student_code    VARCHAR(20) UNIQUE NOT NULL,      -- "SV2026-0001"
    enrollment_date DATE DEFAULT CURRENT_DATE,
    current_level   VARCHAR(20),                      -- "A1","A2","B1"...
    learning_goals  TEXT,
    notes           TEXT,
    status          VARCHAR(20) DEFAULT 'active'      -- 'active','suspended','graduated','dropped'
);
```

#### 👨‍🏫 Bảng `teacher_profiles` — Hồ sơ Giáo viên

```sql
CREATE TABLE teacher_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    teacher_code    VARCHAR(20) UNIQUE NOT NULL,
    languages       TEXT[] NOT NULL,                   -- {'english','japanese','korean'}
    certifications  JSONB,                            -- [{"name":"TESOL","year":2020}]
    hourly_rate     DECIMAL(10,2),                    -- Lương theo giờ
    bio             TEXT,
    status          VARCHAR(20) DEFAULT 'active'
);
```

#### 👨‍👩‍👦 Bảng `parent_students` — Liên kết Phụ huynh ↔ Học viên

```sql
CREATE TABLE parent_students (
    parent_id       UUID NOT NULL REFERENCES users(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    relationship    VARCHAR(20) DEFAULT 'parent',     -- 'father','mother','guardian'
    PRIMARY KEY (parent_id, student_id)
);
```

#### 📚 Bảng `courses`, `course_levels`, `modules`, `lessons` — Chương trình học

```sql
CREATE TABLE courses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,             -- "Tiếng Anh Giao Tiếp"
    language        VARCHAR(50) NOT NULL,              -- 'english','japanese','korean','chinese'
    description     TEXT,
    thumbnail_url   VARCHAR(500),
    total_sessions  INT NOT NULL,                      -- Tổng số buổi học
    tuition_fee     DECIMAL(12,2) NOT NULL,            -- Học phí gốc
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE course_levels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id       UUID NOT NULL REFERENCES courses(id),
    name            VARCHAR(50) NOT NULL,              -- "Beginner A1", "Intermediate B1"
    sort_order      INT NOT NULL,
    prerequisite_id UUID REFERENCES course_levels(id), -- Level trước cần hoàn thành
    description     TEXT
);

CREATE TABLE modules (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_id        UUID NOT NULL REFERENCES course_levels(id),
    name            VARCHAR(200) NOT NULL,             -- "Unit 1: Greetings"
    sort_order      INT NOT NULL,
    description     TEXT
);

CREATE TABLE lessons (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id       UUID NOT NULL REFERENCES modules(id),
    title           VARCHAR(200) NOT NULL,
    content         TEXT,                              -- Nội dung bài học (markdown/html)
    sort_order      INT NOT NULL,
    duration_minutes INT DEFAULT 90
);

CREATE TABLE lesson_materials (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id       UUID NOT NULL REFERENCES lessons(id),
    type            VARCHAR(20) NOT NULL,              -- 'pdf','audio','video','image'
    title           VARCHAR(200),
    file_url        VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

#### 🏫 Bảng `classes`, `class_students`, `class_sessions` — Lớp học

```sql
CREATE TABLE classes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id       UUID NOT NULL REFERENCES courses(id),
    branch_id       UUID NOT NULL REFERENCES branches(id),
    room_id         UUID REFERENCES rooms(id),
    teacher_id      UUID NOT NULL REFERENCES users(id),
    name            VARCHAR(100) NOT NULL,             -- "ENG-A1-T246-S01"
    max_students    INT NOT NULL DEFAULT 20,
    schedule_days   TEXT[] NOT NULL,                    -- {'monday','wednesday','friday'}
    start_time      TIME NOT NULL,                     -- 18:00
    end_time        TIME NOT NULL,                     -- 19:30
    start_date      DATE NOT NULL,
    end_date        DATE,
    status          VARCHAR(20) DEFAULT 'waiting',     -- waiting/active/completed/archived
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE class_students (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID NOT NULL REFERENCES classes(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    enrolled_at     TIMESTAMPTZ DEFAULT NOW(),
    status          VARCHAR(20) DEFAULT 'active',      -- active/dropped/transferred/completed
    UNIQUE (class_id, student_id)
);

CREATE TABLE class_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID NOT NULL REFERENCES classes(id),
    session_number  INT NOT NULL,
    session_date    DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    lesson_id       UUID REFERENCES lessons(id),       -- Bài học dạy buổi này
    room_id         UUID REFERENCES rooms(id),         -- Có thể đổi phòng
    teacher_id      UUID REFERENCES users(id),         -- Có thể dạy thay
    status          VARCHAR(20) DEFAULT 'scheduled',   -- scheduled/completed/cancelled/holiday
    notes           TEXT,
    UNIQUE (class_id, session_number)
);
```

#### ✅ Bảng `attendances` — Điểm danh

```sql
CREATE TABLE attendances (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES class_sessions(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    status          VARCHAR(20) NOT NULL,              -- 'present','absent','late','excused','makeup'
    check_in_time   TIMESTAMPTZ,
    notes           TEXT,
    marked_by       UUID REFERENCES users(id),         -- Giáo viên đánh dấu
    marked_at       TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (session_id, student_id)
);

-- Bảng đăng ký học bù
CREATE TABLE makeup_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES users(id),
    original_session_id UUID NOT NULL REFERENCES class_sessions(id),
    target_session_id   UUID REFERENCES class_sessions(id), -- Buổi muốn bù
    status          VARCHAR(20) DEFAULT 'pending',     -- pending/approved/rejected/completed
    reason          TEXT,
    approved_by     UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

#### 📝 Bảng `assignments`, `submissions` — Bài tập

```sql
CREATE TABLE assignments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID NOT NULL REFERENCES classes(id),
    created_by      UUID NOT NULL REFERENCES users(id),
    title           VARCHAR(200) NOT NULL,
    description     TEXT,
    type            VARCHAR(20) NOT NULL,              -- 'homework','project','speaking','writing'
    deadline        TIMESTAMPTZ,
    max_score       DECIMAL(5,2) DEFAULT 10,
    attachments     JSONB,                            -- [{"name":"file.pdf","url":"..."}]
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE submissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id   UUID NOT NULL REFERENCES assignments(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    content         TEXT,
    file_urls       JSONB,                            -- [{"type":"audio","url":"..."}]
    submitted_at    TIMESTAMPTZ DEFAULT NOW(),
    score           DECIMAL(5,2),
    feedback        TEXT,
    graded_by       UUID REFERENCES users(id),
    graded_at       TIMESTAMPTZ,
    status          VARCHAR(20) DEFAULT 'submitted',  -- submitted/graded/returned/late
    UNIQUE (assignment_id, student_id)
);
```

#### 🎓 Bảng `question_banks`, `questions`, `exams` — Thi & Kiểm tra

```sql
CREATE TABLE question_banks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(200) NOT NULL,
    course_id       UUID REFERENCES courses(id),
    level           VARCHAR(20),                      -- 'A1','A2','B1'...
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE questions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_id         UUID NOT NULL REFERENCES question_banks(id),
    type            VARCHAR(30) NOT NULL,             -- 'multiple_choice','fill_blank','matching','ordering','essay'
    skill           VARCHAR(20),                      -- 'listening','reading','writing','speaking','grammar','vocabulary'
    difficulty      VARCHAR(10) DEFAULT 'medium',     -- 'easy','medium','hard'
    content         JSONB NOT NULL,                   -- Nội dung câu hỏi (linh hoạt theo type)
    /*
      Ví dụ content cho multiple_choice:
      {
        "question": "What is the past tense of 'go'?",
        "options": ["goed","went","gone","going"],
        "correct_answer": 1,
        "explanation": "'went' is the irregular past tense of 'go'"
      }
    */
    audio_url       VARCHAR(500),                     -- File audio cho câu Listening
    image_url       VARCHAR(500),
    points          DECIMAL(5,2) DEFAULT 1,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE exams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID REFERENCES classes(id),
    title           VARCHAR(200) NOT NULL,
    type            VARCHAR(20) NOT NULL,             -- 'midterm','final','quiz','placement_test'
    duration_minutes INT NOT NULL,
    total_points    DECIMAL(5,2),
    passing_score   DECIMAL(5,2),
    shuffle_questions BOOLEAN DEFAULT false,
    show_answers_after BOOLEAN DEFAULT false,
    start_time      TIMESTAMPTZ,                     -- Thời gian mở thi
    end_time        TIMESTAMPTZ,                     -- Thời gian đóng thi
    created_by      UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE exam_questions (
    exam_id         UUID NOT NULL REFERENCES exams(id),
    question_id     UUID NOT NULL REFERENCES questions(id),
    sort_order      INT NOT NULL,
    PRIMARY KEY (exam_id, question_id)
);

CREATE TABLE exam_attempts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exam_id         UUID NOT NULL REFERENCES exams(id),
    student_id      UUID NOT NULL REFERENCES users(id),
    started_at      TIMESTAMPTZ DEFAULT NOW(),
    submitted_at    TIMESTAMPTZ,
    total_score     DECIMAL(5,2),
    status          VARCHAR(20) DEFAULT 'in_progress', -- in_progress/submitted/graded
    UNIQUE (exam_id, student_id)
);

CREATE TABLE exam_answers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id      UUID NOT NULL REFERENCES exam_attempts(id),
    question_id     UUID NOT NULL REFERENCES questions(id),
    answer          JSONB,                            -- Câu trả lời (format tùy loại câu hỏi)
    is_correct      BOOLEAN,
    score           DECIMAL(5,2),
    feedback        TEXT,                             -- Nhận xét cho tự luận
    UNIQUE (attempt_id, question_id)
);
```

#### 💰 Bảng `invoices`, `payments` — Tài chính

```sql
CREATE TABLE invoices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_code    VARCHAR(30) UNIQUE NOT NULL,      -- "INV-2026-09-0001"
    student_id      UUID NOT NULL REFERENCES users(id),
    class_id        UUID REFERENCES classes(id),
    branch_id       UUID NOT NULL REFERENCES branches(id),
    total_amount    DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    final_amount    DECIMAL(12,2) NOT NULL,
    paid_amount     DECIMAL(12,2) DEFAULT 0,
    due_date        DATE,
    status          VARCHAR(20) DEFAULT 'pending',   -- pending/partial/paid/overdue/cancelled/refunded
    notes           TEXT,
    created_by      UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id      UUID NOT NULL REFERENCES invoices(id),
    amount          DECIMAL(12,2) NOT NULL,
    method          VARCHAR(30) NOT NULL,             -- 'cash','bank_transfer','vnpay','momo','zalopay'
    transaction_id  VARCHAR(100),                     -- Mã giao dịch từ cổng thanh toán
    paid_at         TIMESTAMPTZ DEFAULT NOW(),
    received_by     UUID REFERENCES users(id),        -- Thu ngân thu tiền
    notes           TEXT
);

CREATE TABLE promotions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(30) UNIQUE NOT NULL,
    name            VARCHAR(200),
    type            VARCHAR(20) NOT NULL,             -- 'percentage','fixed_amount'
    value           DECIMAL(10,2) NOT NULL,           -- 10 (10%) hoặc 500000 (500k VND)
    max_uses        INT,
    used_count      INT DEFAULT 0,
    valid_from      TIMESTAMPTZ,
    valid_to        TIMESTAMPTZ,
    is_active       BOOLEAN DEFAULT true
);
```

#### 🔔 Bảng `notifications` — Thông báo

```sql
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    type            VARCHAR(30) NOT NULL,             -- 'attendance','payment','assignment','exam','system'
    data            JSONB,                            -- Metadata bổ sung (class_id, invoice_id, ...)
    is_read         BOOLEAN DEFAULT false,
    sent_via        TEXT[] DEFAULT '{}',              -- {'push','email','sms','in_app'}
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### 4.3 Indexes quan trọng

```sql
-- Tìm kiếm nhanh
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_branch ON users(branch_id);

-- Lọc lớp học
CREATE INDEX idx_classes_status ON classes(status);
CREATE INDEX idx_classes_branch ON classes(branch_id);
CREATE INDEX idx_classes_teacher ON classes(teacher_id);
CREATE INDEX idx_classes_course ON classes(course_id);

-- Điểm danh
CREATE INDEX idx_attendances_session ON attendances(session_id);
CREATE INDEX idx_attendances_student ON attendances(student_id);

-- Session theo lớp và ngày
CREATE INDEX idx_sessions_class_date ON class_sessions(class_id, session_date);

-- Hóa đơn
CREATE INDEX idx_invoices_student ON invoices(student_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- Thông báo chưa đọc
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = false;
```

---

## 5. CẤU TRÚC THƯ MỤC BACKEND (NestJS)

```
backend/
├── src/
│   ├── main.ts                          # Entry point
│   ├── app.module.ts                    # Root module
│   │
│   ├── config/                          # Cấu hình chung
│   │   ├── database.config.ts           # PostgreSQL connection
│   │   ├── redis.config.ts
│   │   ├── firebase.config.ts
│   │   ├── jwt.config.ts
│   │   └── app.config.ts
│   │
│   ├── common/                          # Shared utilities
│   │   ├── decorators/
│   │   │   ├── roles.decorator.ts       # @Roles('admin','teacher')
│   │   │   └── current-user.decorator.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── interceptors/
│   │   │   ├── transform.interceptor.ts # Response wrapper
│   │   │   └── logging.interceptor.ts
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts
│   │   ├── dto/
│   │   │   └── pagination.dto.ts
│   │   └── utils/
│   │       ├── hash.util.ts             # bcrypt
│   │       └── date.util.ts
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts       # POST /auth/login, /auth/register, /auth/refresh
│   │   │   ├── auth.service.ts
│   │   │   ├── strategies/
│   │   │   │   ├── jwt.strategy.ts
│   │   │   │   └── google.strategy.ts
│   │   │   └── dto/
│   │   │       ├── login.dto.ts
│   │   │       └── register.dto.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── entities/
│   │   │   │   └── user.entity.ts       # Prisma model mapping
│   │   │   └── dto/
│   │   │       ├── create-user.dto.ts
│   │   │       └── update-user.dto.ts
│   │   │
│   │   ├── branches/                    # CRUD chi nhánh
│   │   ├── rooms/                       # CRUD phòng học
│   │   ├── courses/                     # Khóa học, level, module, lesson
│   │   ├── classes/                     # Lớp học, xếp lịch, sinh sessions
│   │   ├── attendance/                  # Điểm danh, học bù
│   │   ├── assignments/                 # Bài tập, nộp bài
│   │   ├── exams/                       # Thi, ngân hàng câu hỏi
│   │   ├── finance/                     # Học phí, hóa đơn, thanh toán
│   │   ├── notifications/              # Push, email, SMS, in-app
│   │   ├── reports/                     # Dashboard, thống kê, xuất file
│   │   └── file-upload/                 # Upload lên Firebase Storage
│   │
│   ├── database/
│   │   ├── prisma/
│   │   │   └── schema.prisma            # Prisma schema definition
│   │   ├── migrations/                  # Auto-generated migrations
│   │   └── seeds/
│   │       ├── seed.ts                  # Seed data chính
│   │       ├── roles.seed.ts
│   │       └── permissions.seed.ts
│   │
│   └── jobs/                            # Background jobs (Bull Queue + Redis)
│       ├── notification.job.ts          # Gửi notification hàng loạt
│       ├── invoice-reminder.job.ts      # Nhắc học phí tự động
│       └── report-generator.job.ts      # Xuất báo cáo nặng
│
├── test/                                # E2E tests
├── .env.example
├── .env
├── docker-compose.yml                   # PostgreSQL + Redis + App
├── Dockerfile
├── nest-cli.json
├── package.json
├── tsconfig.json
└── README.md
```

---

## 6. CẤU TRÚC THƯ MỤC FRONTEND (Flutter)

```
frontend/    (hoặc chính thư mục lms_trung_tam_ngoai_ngu hiện tại)
├── lib/
│   ├── main.dart                         # Entry point
│   ├── app.dart                          # MaterialApp + Router + Theme
│   │
│   ├── core/                             # Shared infrastructure
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart        # Base URL, endpoints
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart            # ThemeData light/dark
│   │   │   └── app_typography.dart
│   │   ├── network/
│   │   │   ├── api_client.dart           # Dio instance + interceptors
│   │   │   ├── api_interceptor.dart      # Attach JWT, refresh token
│   │   │   ├── api_response.dart         # Generic response wrapper
│   │   │   └── api_exception.dart
│   │   ├── storage/
│   │   │   └── secure_storage.dart       # flutter_secure_storage
│   │   ├── router/
│   │   │   └── app_router.dart           # GoRouter configuration
│   │   ├── di/
│   │   │   └── injection.dart            # GetIt / Injectable setup
│   │   └── utils/
│   │       ├── date_formatter.dart
│   │       ├── currency_formatter.dart
│   │       └── validators.dart
│   │
│   ├── features/                         # Feature-first modules
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── login_request_model.dart
│   │   │   │   │   └── token_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login_usecase.dart
│   │   │   │       └── logout_usecase.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   ├── forgot_password_screen.dart
│   │   │       │   └── register_screen.dart
│   │   │       └── widgets/
│   │   │           ├── login_form.dart
│   │   │           └── social_login_buttons.dart
│   │   │
│   │   ├── dashboard/                    # Trang chủ theo role
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── student_dashboard_screen.dart
│   │   │       │   ├── teacher_dashboard_screen.dart
│   │   │       │   └── admin_dashboard_screen.dart
│   │   │       └── widgets/
│   │   │           ├── upcoming_classes_card.dart
│   │   │           ├── attendance_summary_card.dart
│   │   │           └── revenue_chart_card.dart
│   │   │
│   │   ├── classes/                      # Quản lý lớp học
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── screens/
│   │   │       │   ├── class_list_screen.dart
│   │   │       │   ├── class_detail_screen.dart
│   │   │       │   └── class_schedule_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── attendance/                   # Điểm danh
│   │   ├── courses/                      # Khóa học & tài liệu
│   │   ├── assignments/                  # Bài tập
│   │   ├── exams/                        # Thi online
│   │   ├── finance/                      # Học phí
│   │   ├── notifications/               # Thông báo
│   │   ├── profile/                      # Hồ sơ cá nhân
│   │   └── reports/                      # Báo cáo (Admin)
│   │
│   └── shared/                           # Reusable widgets
│       ├── widgets/
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── app_card.dart
│       │   ├── app_dialog.dart
│       │   ├── loading_widget.dart
│       │   ├── empty_state_widget.dart
│       │   └── error_widget.dart
│       └── extensions/
│           ├── context_extension.dart
│           └── string_extension.dart
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── fonts/
│   └── translations/                     # Localization files
│       ├── vi.json
│       └── en.json
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 7. THIẾT KẾ API (RESTful)

> Base URL: `http://localhost:3000/api/v1`

### 7.1 Auth APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| POST | `/auth/login` | Đăng nhập (email/phone/mã tài khoản) | Public |
| POST | `/auth/first-login-setup` | Kích hoạt & Thiết lập mật khẩu lần đầu | Authenticated (Token tạm) |
| POST | `/auth/refresh` | Refresh access token | Authenticated |
| POST | `/auth/forgot-password` | Gửi OTP reset mật khẩu | Public |
| POST | `/auth/reset-password` | Đặt lại mật khẩu qua OTP | Public |
| POST | `/auth/change-password` | Đổi mật khẩu cá nhân | Authenticated |
| POST | `/auth/google` | Đăng nhập Google (liên kết tài khoản đã cấp) | Public |
| GET | `/auth/me` | Lấy thông tin user hiện tại | Authenticated |

### 7.2 Admissions & Leads APIs (Tuyển sinh & Tư vấn)

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| POST | `/admissions/leads` | Gửi đăng ký nhu cầu học tập (Public Lead) | Public |
| GET | `/admissions/leads` | Danh sách yêu cầu tư vấn (lọc, phân trang) | Admin, Staff |
| GET | `/admissions/leads/:id` | Chi tiết yêu cầu tư vấn & lịch sử chăm sóc | Admin, Staff |
| PATCH | `/admissions/leads/:id` | Cập nhật trạng thái tư vấn, hẹn test, ghi chú | Admin, Staff |
| POST | `/admissions/leads/:id/convert` | Chuyển đổi Lead thành Học viên chính thức (cấp tài khoản) | Admin, Staff |

### 7.3 User Management APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/users` | Danh sách users (phân trang, filter theo role/branch/class) | Admin, Staff |
| GET | `/users/:id` | Chi tiết user + hồ sơ học vụ/chuyên môn | Admin, Staff |
| POST | `/users/students` | Tạo học viên chính thức (tạo StudentProfile, gắn lớp) | Admin, Staff |
| POST | `/users/parents` | Tạo tài khoản phụ huynh (bắt buộc gắn học viên) | Admin, Staff |
| POST | `/users/staff` | Tạo tài khoản giáo viên/nhân viên | Admin |
| PATCH | `/users/:id` | Cập nhật thông tin user | Admin, Staff |
| PATCH | `/users/:id/status` | Khóa / Mở khóa tài khoản (toggle active) | Admin |
| POST | `/users/:id/reset-password` | Admin đặt lại mật khẩu tạm thời cho người dùng | Admin |
| POST | `/users/import` | Import danh sách học viên từ Excel | Admin, Staff |
| GET | `/users/:id/roles` | Lấy roles của user | Admin |
| POST | `/users/:id/roles` | Gán role cho user | Admin |

### 7.3 Branch & Room APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/branches` | Danh sách chi nhánh | Admin |
| POST | `/branches` | Tạo chi nhánh | SuperAdmin |
| PATCH | `/branches/:id` | Cập nhật chi nhánh | SuperAdmin |
| GET | `/branches/:id/rooms` | Phòng học theo chi nhánh | Admin, Staff |
| POST | `/rooms` | Tạo phòng | Admin |
| PATCH | `/rooms/:id` | Cập nhật phòng | Admin |

### 7.4 Course APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/courses` | Danh sách khóa học | All |
| GET | `/courses/:id` | Chi tiết khóa học + levels | All |
| POST | `/courses` | Tạo khóa học | Admin |
| PATCH | `/courses/:id` | Cập nhật khóa học | Admin |
| GET | `/courses/:id/levels` | Danh sách level | All |
| POST | `/courses/:id/levels` | Tạo level | Admin |
| GET | `/levels/:id/modules` | Danh sách module | All |
| GET | `/modules/:id/lessons` | Danh sách bài học | All |
| POST | `/lessons/:id/materials` | Upload tài liệu bài học | Admin, Teacher |

### 7.5 Class APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/classes` | Danh sách lớp (filter: status, branch, course) | Admin, Staff |
| GET | `/classes/:id` | Chi tiết lớp + danh sách học viên | Admin, Staff, Teacher |
| POST | `/classes` | Tạo lớp mới (auto-gen sessions) | Admin, Staff |
| PATCH | `/classes/:id` | Cập nhật lớp | Admin, Staff |
| POST | `/classes/:id/students` | Thêm học viên vào lớp | Admin, Staff |
| DELETE | `/classes/:id/students/:studentId` | Xóa học viên khỏi lớp | Admin, Staff |
| GET | `/classes/:id/sessions` | Danh sách buổi học | All related |
| PATCH | `/sessions/:id` | Cập nhật buổi học (đổi phòng, GV thay) | Admin, Staff |
| GET | `/my/classes` | Lớp học của tôi (student/teacher) | Student, Teacher |
| GET | `/my/schedule` | Lịch học/dạy tuần này | Student, Teacher |

### 7.6 Attendance APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/sessions/:id/attendance` | Danh sách điểm danh 1 buổi | Teacher, Staff |
| POST | `/sessions/:id/attendance` | Điểm danh hàng loạt | Teacher |
| PATCH | `/attendance/:id` | Sửa điểm danh | Teacher, Staff |
| GET | `/students/:id/attendance` | Lịch sử chuyên cần của 1 HV | Teacher, Staff, Student, Parent |
| GET | `/classes/:id/attendance-summary` | Tỷ lệ chuyên cần cả lớp | Teacher, Staff |
| POST | `/makeup-requests` | Đăng ký học bù | Student |
| GET | `/makeup-requests` | Danh sách yêu cầu bù | Staff |
| PATCH | `/makeup-requests/:id` | Duyệt/từ chối yêu cầu bù | Staff |

### 7.7 Assignment & Submission APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/classes/:id/assignments` | Bài tập của lớp | Teacher, Student |
| POST | `/classes/:id/assignments` | Tạo bài tập | Teacher |
| GET | `/assignments/:id` | Chi tiết bài tập | Teacher, Student |
| POST | `/assignments/:id/submit` | Nộp bài | Student |
| GET | `/assignments/:id/submissions` | Danh sách bài nộp | Teacher |
| PATCH | `/submissions/:id/grade` | Chấm điểm bài | Teacher |

### 7.8 Exam APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/question-banks` | Danh sách ngân hàng câu hỏi | Teacher, Admin |
| POST | `/question-banks` | Tạo ngân hàng | Teacher, Admin |
| POST | `/question-banks/:id/questions` | Thêm câu hỏi | Teacher |
| POST | `/question-banks/:id/questions/import` | Import câu hỏi từ file | Teacher |
| GET | `/exams` | Danh sách bài thi | Teacher, Admin |
| POST | `/exams` | Tạo bài thi | Teacher |
| GET | `/exams/:id` | Chi tiết bài thi (GV xem đề) | Teacher |
| POST | `/exams/:id/start` | Bắt đầu làm bài | Student |
| POST | `/exams/:id/submit` | Nộp bài thi | Student |
| GET | `/exams/:id/results` | Kết quả thi cả lớp | Teacher |
| GET | `/my/exam-results` | Kết quả thi của tôi | Student |

### 7.9 Finance APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/invoices` | Danh sách hóa đơn (filter: status, student, branch) | Admin, Cashier |
| GET | `/invoices/:id` | Chi tiết hóa đơn | Admin, Cashier, Student |
| POST | `/invoices` | Tạo hóa đơn | Cashier, Staff |
| POST | `/invoices/:id/payments` | Ghi nhận thanh toán | Cashier |
| POST | `/invoices/:id/pay-online` | Thanh toán online (tạo URL VNPay) | Student |
| GET | `/payments/vnpay/callback` | Webhook VNPay xử lý kết quả | System |
| GET | `/my/invoices` | Hóa đơn của tôi | Student, Parent |
| GET | `/reports/revenue` | Báo cáo doanh thu | Admin |
| GET | `/reports/debts` | Báo cáo công nợ | Admin, Cashier |
| POST | `/promotions` | Tạo mã khuyến mãi | Admin |
| POST | `/promotions/validate` | Kiểm tra mã KM | Student |

### 7.10 Notification APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/my/notifications` | Danh sách thông báo của tôi | Authenticated |
| PATCH | `/notifications/:id/read` | Đánh dấu đã đọc | Authenticated |
| POST | `/notifications/read-all` | Đánh dấu tất cả đã đọc | Authenticated |
| POST | `/notifications/send` | Gửi thông báo (broadcast) | Admin |
| PUT | `/my/notification-preferences` | Cấu hình nhận thông báo | Authenticated |
| PUT | `/my/fcm-token` | Cập nhật FCM token | Authenticated |

### 7.11 Report APIs

| Method | Endpoint | Mô tả | Role |
|:---|:---|:---|:---|
| GET | `/reports/dashboard` | Dashboard overview | Admin |
| GET | `/reports/attendance` | Báo cáo chuyên cần | Admin, Staff |
| GET | `/reports/academic` | Báo cáo kết quả học tập | Admin, Staff |
| GET | `/reports/teacher-workload` | Tải giờ dạy GV | Admin |
| GET | `/reports/export/:type` | Xuất Excel/PDF | Admin |

---

## 8. TÍCH HỢP FIREBASE SERVICES

### 8.1 Firebase Cloud Messaging (FCM) — Push Notification

```
Luồng hoạt động:
1. Flutter app khởi động → lấy FCM token → gửi lên Backend (PUT /my/fcm-token)
2. Backend lưu fcm_token vào bảng users
3. Khi có sự kiện (điểm danh vắng, deadline bài tập, nhắc học phí):
   - Backend tạo record trong bảng notifications
   - Đồng thời gọi Firebase Admin SDK gửi push đến FCM token
4. Flutter app nhận push → hiển thị notification → tap vào → navigate đến screen tương ứng
```

### 8.2 Firebase Storage — Lưu trữ file

```
Tổ chức thư mục trên Storage:

lms-storage/
├── avatars/{user_id}/avatar.jpg
├── materials/
│   ├── {lesson_id}/
│   │   ├── textbook.pdf
│   │   ├── audio_unit1.mp3
│   │   └── video_lesson1.mp4
├── submissions/
│   ├── {assignment_id}/
│   │   └── {student_id}/
│   │       ├── homework.pdf
│   │       └── speaking_recording.m4a
├── exams/
│   └── {question_id}/
│       └── listening_audio.mp3
└── exports/
    └── {report_id}/report.xlsx
```

### 8.3 Firebase Security Rules (Storage)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Chỉ backend (service account) mới được write
    // Client chỉ được read với signed URL từ backend
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if false; // Client không được upload trực tiếp
    }
  }
}
```

> **Lưu ý:** Upload flow nên đi qua Backend (client gửi file lên Backend → Backend upload lên Storage → trả URL) để kiểm soát dung lượng, loại file, và virus scan.

---

## 9. LỘ TRÌNH TRIỂN KHAI (6 PHASE)

### Phase 1: Foundation — Nền tảng (Tuần 1–3)

> **Mục tiêu:** Setup project, cơ sở hạ tầng, xác thực, quản lý người dùng cơ bản.

#### Backend

- [ ] Khởi tạo NestJS project với TypeScript
- [ ] Cấu hình PostgreSQL + Prisma ORM
- [ ] Cấu hình Redis (local hoặc Docker)
- [ ] Tạo Prisma schema cho: `users`, `roles`, `permissions`, `user_roles`, `role_permissions`, `branches`, `rooms`
- [ ] Chạy migration đầu tiên
- [ ] Seed data: roles, permissions mặc định, tài khoản super_admin
- [ ] Module Auth: login, register, JWT, refresh token, change/forgot password
- [ ] Module Users: CRUD users, assign roles
- [ ] Module Branches: CRUD chi nhánh
- [ ] Module Rooms: CRUD phòng học
- [ ] Setup Swagger (OpenAPI) documentation
- [ ] Setup Docker Compose (PostgreSQL + Redis + App)

#### Frontend

- [ ] Khởi tạo Flutter project (đã có)
- [ ] Setup kiến trúc thư mục `core/`, `features/`, `shared/`
- [ ] Cấu hình theme (colors, typography, dark mode)
- [ ] Setup routing với `go_router`
- [ ] Setup DI container (`get_it` + `injectable`)
- [ ] Setup API client (`dio` + interceptors + JWT auto-attach)
- [ ] Setup secure storage (`flutter_secure_storage`)
- [ ] Setup BLoC (`flutter_bloc`)
- [ ] Feature Auth: Login screen, Forgot password screen
- [ ] Feature Profile: Xem/sửa thông tin cá nhân
- [ ] Shared widgets: AppButton, AppTextField, AppCard, LoadingWidget

#### DevOps

- [ ] Setup Git repo + branching strategy (main/develop/feature)
- [ ] Setup `.env` cho dev/staging/production
- [ ] Docker Compose chạy local

---

### Phase 2: Core Academic — Nghiệp vụ học thuật (Tuần 4–6)

> **Mục tiêu:** Quản lý khóa học, lớp học, xếp lịch, sinh buổi học.

#### Backend

- [ ] Prisma schema: `courses`, `course_levels`, `modules`, `lessons`, `lesson_materials`
- [ ] Prisma schema: `classes`, `class_students`, `class_sessions`
- [ ] Module Courses: CRUD khóa học, levels, modules, lessons
- [ ] Module Classes: Tạo lớp, thêm/xóa học viên
- [ ] Logic auto-gen sessions: từ schedule_days + start_date → tạo danh sách buổi học
- [ ] Kiểm tra trùng lịch phòng + giáo viên khi tạo lớp
- [ ] API lịch học/dạy cá nhân (`/my/classes`, `/my/schedule`)
- [ ] Module File Upload: upload tài liệu lên Firebase Storage

#### Frontend

- [ ] Feature Courses: Danh sách khóa học, chi tiết khóa học
- [ ] Feature Classes:
  - Admin: tạo lớp, xếp lịch, quản lý danh sách HV
  - Teacher: xem danh sách lớp mình dạy
  - Student: xem danh sách lớp đang học
- [ ] Màn hình Lịch học (Calendar view — dùng `table_calendar`)
- [ ] Xem tài liệu bài học (PDF viewer, audio player)

---

### Phase 3: Attendance & Assignment — Điểm danh & Bài tập (Tuần 7–9)

> **Mục tiêu:** Giáo viên điểm danh, quản lý bài tập, học viên nộp bài.

#### Backend

- [ ] Prisma schema: `attendances`, `makeup_requests`
- [ ] Module Attendance: điểm danh, sửa, thống kê
- [ ] Logic học bù: tạo/duyệt yêu cầu, ghi nhận bù ở lớp khác
- [ ] Prisma schema: `assignments`, `submissions`
- [ ] Module Assignments: tạo bài tập, nộp bài, chấm điểm
- [ ] Upload file bài tập (đặc biệt audio recording cho bài nói)
- [ ] Cron job nhắc deadline bài tập sắp hết hạn

#### Frontend

- [ ] Feature Attendance:
  - Teacher: màn hình điểm danh (danh sách HV + chọn trạng thái)
  - Student: xem lịch sử chuyên cần
  - Parent: xem chuyên cần của con
- [ ] Feature Assignments:
  - Teacher: tạo bài tập, xem bài nộp, chấm điểm
  - Student: xem bài tập, nộp bài (text/file/audio), xem điểm/nhận xét
  - Audio recorder widget cho bài nói

---

### Phase 4: Exam & Assessment — Thi & Kiểm tra (Tuần 10–12)

> **Mục tiêu:** Ngân hàng câu hỏi, thi online, tự động chấm trắc nghiệm.

#### Backend

- [ ] Prisma schema: `question_banks`, `questions`, `exams`, `exam_questions`, `exam_attempts`, `exam_answers`
- [ ] Module Question Banks: CRUD câu hỏi (hỗ trợ nhiều loại)
- [ ] Module Exams: tạo đề, bắt đầu/nộp bài, auto-grade trắc nghiệm
- [ ] Logic countdown timer (server validate thời gian)
- [ ] API kết quả thi, bảng điểm chi tiết

#### Frontend

- [ ] Feature Exams:
  - Teacher: tạo ngân hàng câu hỏi, tạo đề thi, xem kết quả
  - Student: làm bài thi online (countdown timer, multi-page)
  - Các loại câu hỏi UI: trắc nghiệm, điền khuyết, nối, sắp xếp
- [ ] Bảng điểm tổng hợp theo kỹ năng (radar chart)

---

### Phase 5: Finance & Notification — Tài chính & Thông báo (Tuần 13–16)

> **Mục tiêu:** Thu học phí, thanh toán online, push notification, email.

#### Backend

- [ ] Prisma schema: `invoices`, `payments`, `promotions`
- [ ] Module Finance: tạo hóa đơn, ghi nhận thanh toán
- [ ] Tích hợp VNPay / MoMo payment gateway
- [ ] Logic quản lý công nợ (auto đánh trạng thái overdue)
- [ ] Module Notifications: gửi push (FCM), email (Nodemailer), SMS, in-app
- [ ] Cron jobs: nhắc học phí quá hạn, nhắc lịch học ngày mai
- [ ] Module Promotions: CRUD mã khuyến mãi, validate

#### Frontend

- [ ] Feature Finance:
  - Cashier: danh sách hóa đơn, thu tiền, in phiếu
  - Student: xem hóa đơn, thanh toán online (WebView VNPay)
  - Parent: xem tình trạng học phí của con
- [ ] Feature Notifications:
  - Danh sách thông báo, đánh dấu đã đọc
  - Push notification handler (foreground/background)
  - Cấu hình nhận thông báo
- [ ] Setup FCM trên Flutter (firebase_messaging, flutter_local_notifications)

---

### Phase 6: Report & Polish — Báo cáo & Hoàn thiện (Tuần 17–20)

> **Mục tiêu:** Dashboard, báo cáo, xuất file, QA, tối ưu, go-live.

#### Backend

- [ ] Module Reports: dashboard overview, báo cáo chuyên cần/học tập/doanh thu
- [ ] Xuất báo cáo Excel (`exceljs`) / PDF (`pdfmake`)
- [ ] API phức tạp: thống kê tải giờ dạy GV, top HV, retention rate
- [ ] Optimization: caching Redis cho dashboard queries
- [ ] Security audit: rate limiting, input sanitization, SQL injection check

#### Frontend

- [ ] Feature Dashboard:
  - Admin: biểu đồ doanh thu, tổng quan HV/lớp, cảnh báo công nợ
  - Teacher: thống kê lớp, chuyên cần, kết quả
  - Student: progress overview, upcoming schedule
- [ ] Charts: `fl_chart` cho biểu đồ cột, line, pie, radar
- [ ] Export / chia sẻ báo cáo
- [ ] UI polish: animations, empty states, error handling
- [ ] Testing: unit tests, widget tests, integration tests
- [ ] Performance: lazy loading, image caching, pagination

---

## 10. CẤU HÌNH MÔI TRƯỜNG & DEVOPS

### 10.1 Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: lms_db
      POSTGRES_USER: lms_user
      POSTGRES_PASSWORD: lms_password_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://lms_user:lms_password_dev@postgres:5432/lms_db
      REDIS_URL: redis://redis:6379
      JWT_SECRET: your-jwt-secret-dev
      JWT_REFRESH_SECRET: your-refresh-secret-dev
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
```

### 10.2 Environment Variables (.env)

```env
# Database
DATABASE_URL=postgresql://lms_user:lms_password_dev@localhost:5432/lms_db

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-256-bit-jwt-secret
JWT_REFRESH_SECRET=your-256-bit-refresh-secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_STORAGE_BUCKET=your-bucket.appspot.com

# Payment
VNPAY_TMN_CODE=your-tmn-code
VNPAY_HASH_SECRET=your-hash-secret
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# App
PORT=3000
NODE_ENV=development
FRONTEND_URL=http://localhost:8080
```

### 10.3 Git Branching Strategy

```
main (production)
  └── develop (staging)
       ├── feature/auth-module
       ├── feature/class-management
       ├── feature/attendance
       ├── fix/login-token-expired
       └── release/v1.0.0
```

---

## 11. DANH SÁCH PACKAGES/DEPENDENCIES

### 11.1 Backend (NestJS) — `package.json`

```json
{
  "dependencies": {
    "@nestjs/core": "^10.x",
    "@nestjs/common": "^10.x",
    "@nestjs/platform-express": "^10.x",
    "@nestjs/jwt": "^10.x",
    "@nestjs/passport": "^10.x",
    "@nestjs/swagger": "^7.x",
    "@nestjs/bull": "^10.x",
    "@nestjs/schedule": "^4.x",
    "@nestjs/websockets": "^10.x",
    "@nestjs/platform-socket.io": "^10.x",
    "@prisma/client": "^5.x",
    "passport": "^0.7.x",
    "passport-jwt": "^4.x",
    "passport-google-oauth20": "^2.x",
    "bcrypt": "^5.x",
    "class-validator": "^0.14.x",
    "class-transformer": "^0.5.x",
    "firebase-admin": "^12.x",
    "nodemailer": "^6.x",
    "bull": "^4.x",
    "exceljs": "^4.x",
    "pdfmake": "^0.2.x",
    "dayjs": "^1.x",
    "helmet": "^7.x",
    "compression": "^1.x"
  },
  "devDependencies": {
    "prisma": "^5.x",
    "typescript": "^5.x",
    "@nestjs/cli": "^10.x",
    "@nestjs/testing": "^10.x",
    "jest": "^29.x"
  }
}
```

### 11.2 Frontend (Flutter) — `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.0
  equatable: ^2.0.0

  # Routing
  go_router: ^14.0.0

  # Networking
  dio: ^5.4.0
  retrofit: ^4.1.0

  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.3.0

  # Local Storage
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0

  # Firebase
  firebase_core: ^2.25.0
  firebase_messaging: ^14.7.0
  firebase_storage: ^11.6.0
  flutter_local_notifications: ^17.0.0

  # UI Components
  table_calendar: ^3.0.9          # Calendar view cho lịch học
  fl_chart: ^0.68.0               # Charts cho dashboard
  shimmer: ^3.0.0                 # Loading skeleton
  cached_network_image: ^3.3.0    # Image caching
  flutter_svg: ^2.0.9

  # Media
  just_audio: ^0.9.36             # Audio player cho bài nghe
  record: ^5.0.4                  # Audio recorder cho bài nói
  flutter_pdfview: ^1.3.2         # PDF viewer
  video_player: ^2.8.0

  # Forms & Validation
  formz: ^0.7.0
  image_picker: ^1.0.7

  # Utilities
  intl: ^0.19.0                   # Date/number formatting
  json_annotation: ^4.8.0
  freezed_annotation: ^2.4.0
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  freezed: ^2.4.0
  injectable_generator: ^2.4.0
  retrofit_generator: ^8.1.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
```

---

## TỔNG KẾT TIMELINE

```mermaid
flowchart LR
    P1["Phase 1\nFoundation\n3 tuần"] --> P2["Phase 2\nCore Academic\n3 tuần"]
    P2 --> P3["Phase 3\nAttendance\n& Assignment\n3 tuần"]
    P3 --> P4["Phase 4\nExam\n& Assessment\n3 tuần"]
    P4 --> P5["Phase 5\nFinance\n& Notification\n4 tuần"]
    P5 --> P6["Phase 6\nReport\n& Polish\n4 tuần"]
```

| Phase | Thời gian | Output chính |
|:---|:---|:---|
| **Phase 1** | Tuần 1–3 | Login, RBAC, CRUD users/branches/rooms, project skeleton |
| **Phase 2** | Tuần 4–6 | CRUD courses/classes, xếp lịch, auto-gen sessions |
| **Phase 3** | Tuần 7–9 | Điểm danh, học bù, bài tập, nộp bài (bao gồm audio) |
| **Phase 4** | Tuần 10–12 | Ngân hàng câu hỏi, thi online, tự động chấm |
| **Phase 5** | Tuần 13–16 | Học phí, VNPay, push notification, email, SMS |
| **Phase 6** | Tuần 17–20 | Dashboard, báo cáo, export, QA, go-live |
| **Tổng** | **~20 tuần (5 tháng)** | **MVP hoàn chỉnh** |

> [!IMPORTANT]
> Timeline trên dành cho **1 full-stack developer làm việc full-time**. Nếu có team 2–3 người (1 Backend + 1–2 Frontend), có thể rút xuống **12–14 tuần (~3.5 tháng)** vì Backend và Frontend có thể chạy song song sau Phase 1.
