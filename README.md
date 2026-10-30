# 🏫 Hệ Thống Quản Lý Học Tập Trung Tâm Ngoại Ngữ (LMS)

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![NestJS](https://img.shields.io/badge/NestJS-12+-E0234E?logo=nestjs&logoColor=white)](https://nestjs.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white)](https://redis.io)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker&logoColor=white)](https://www.docker.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM%20%7C%20Storage-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)

Hệ thống Quản lý Học tập (**Learning Management System - LMS**) chuyên biệt dành cho trung tâm đào tạo ngoại ngữ (tiếng Anh, tiếng Nhật, tiếng Hàn, tiếng Trung,...). Hệ thống số hóa toàn diện quy trình học vụ, thi cử trực tuyến, luyện phát âm, quản lý học phí và tương tác thời gian thực giữa trung tâm, giáo viên, học viên và phụ huynh.

---

## 📌 Mục Tiêu & Đối Tượng Sử Dụng

Hệ thống phục vụ **5 nhóm người dùng** với các chức năng chuyên biệt:

1. **Quản trị viên (Admin):** Quản lý chi nhánh, phòng học, phân quyền nhân sự, cấu hình hệ thống và thống kê tổng quan.
2. **Nhân viên Học vụ & Thu ngân:** Quản lý danh mục khóa học, xếp thời khóa biểu, sắp xếp lớp, xử lý học bù, quản lý công nợ học phí và xuất hóa đơn.
3. **Giáo viên:** Điểm danh lớp học, giao bài tập về nhà, chấm bài kiểm tra phát âm (nghe file ghi âm giọng nói của học viên), nhập điểm và nhận xét chuyên cần.
4. **Học viên:** Xem thời khóa biểu, làm bài kiểm tra trắc nghiệm/tự luận có bộ đếm thời gian chống gian lận, nộp bài phát âm trực tiếp từ điện thoại, theo dõi lịch sử học tập và đóng học phí qua VNPay.
5. **Phụ huynh:** Theo dõi lịch học, nhận thông báo tức thời ngay khi con vắng học (Push Notification), xem kết quả thi và tình trạng đóng học phí.

---

## 🏗️ Kiến Trúc Hệ Thống (Architecture)

Hệ thống được thiết kế theo sự kết hợp của các mẫu kiến trúc hiện đại:

* **Mẫu kiến trúc chính:**
  * **Client-Server Architecture:** Phân tách rành mạch giữa Tầng máy khách đa nền tảng (Mobile/Web) và Tầng máy chủ tập trung (NestJS RESTful APIs & WebSocket).
  * **Layered Architecture (Clean Architecture / N-Tier):** Tách bạch Presentation Layer $\rightarrow$ Business Logic Layer $\rightarrow$ Data Access Layer $\rightarrow$ Database Layer.
* **Mẫu kiến trúc hỗ trợ:**
  * **Event-Driven Architecture (EDA):** Tự động phát sinh và bắt sự kiện trong các luồng như điểm danh vắng, webhook thanh toán thành công, nhắc nhở hạn nộp bài.
  * **Pipe-Filter Architecture:** Chuỗi bộ lọc tuần tự kiểm soát dữ liệu đầu vào tại Backend (`CORS` $\rightarrow$ `JwtAuthGuard` $\rightarrow$ `RolesGuard` $\rightarrow$ `ValidationPipe` $\rightarrow$ `Controller` $\rightarrow$ `TransformInterceptor`).
  * **Broker Architecture:** Sử dụng Redis và Bull Queue điều phối các tác vụ nền nặng (gửi email hàng loạt, xuất file báo cáo Excel/PDF lớn).

> 📄 **Xem chi tiết tài liệu kiến trúc:** [docs/kien-truc-phan-mem.docx](docs/kien-truc-phan-mem.docx) hoặc [docs/kien-truc-phan-mem.md](docs/kien-truc-phan-mem.md).

---

## 💻 Công Nghệ Sử Dụng (Tech Stack)

| Thành phần | Công nghệ / Nền tảng | Phiên bản | Ghi chú |
|:---|:---|:---:|:---|
| **Mobile App** | Flutter / Dart | Flutter 3.47+ / Dart 3.13+ | Hỗ trợ cả Android & iOS, quản lý trạng thái bằng BLoC |
| **Web Admin** | Flutter Web | Flutter 3.47+ | Giao diện quản trị trên trình duyệt máy tính |
| **Backend API** | NestJS / TypeScript | NestJS 12.x / Node.js 24.x | Cấu trúc module Clean Architecture, RESTful API |
| **ORM** | Prisma ORM | Latest | Quản lý schema, migrations và truy vấn type-safe |
| **Cơ sở dữ liệu** | PostgreSQL (Alpine) | 16.x | CSDL quan hệ chính (ACID), lưu trữ giao dịch và dữ liệu học vụ |
| **Bộ nhớ đệm & Queue**| Redis (Alpine) | 7.x | In-memory cache và backend cho hàng đợi Bull Queue |
| **DB Manager Web** | Adminer | 4.8.x | Quản trị giao diện CSDL trực quan tại `http://localhost:8080` |
| **Container hóa** | Docker & Docker Compose | 29.x / 5.5+ | Đồng nhất môi trường chạy DB, Redis |
| **Push Notification** | Firebase Cloud Messaging (FCM) | Admin SDK 12.x | Bắn thông báo đẩy tức thời tới ứng dụng di động |
| **Cloud Storage** | Firebase Cloud Storage | Admin SDK 12.x | Lưu trữ file âm thanh phát âm (MP3/M4A), tài liệu PDF |
| **Cổng thanh toán** | VNPay Sandbox Gateway | Standard API | Tích hợp thanh toán học phí trực tuyến an toàn |
| **Email Service** | Google SMTP (Gmail) | Nodemailer | Gửi email thông báo tài khoản, lịch học, biên lai |

---

## 📁 Cấu Trúc Thư Mục Dự Án (Project Structure)

```text
lms_trung_tam_ngoai_ngu/
├── android/                 # Cấu hình native Android app
├── ios/                     # Cấu hình native iOS app
├── web/                     # Cấu hình Flutter Web Portal
├── lib/                     # Mã nguồn ứng dụng Flutter (Mobile & Web)
│   ├── firebase_options.dart # Cấu hình kết nối Firebase đa nền tảng
│   └── main.dart            # Điểm khởi chạy ứng dụng Flutter
├── backend/                 # Mã nguồn máy chủ NestJS
│   ├── src/                 # Controllers, Services, Modules, DTOs
│   ├── secrets/             # Service Account JSON (bảo mật, ignore git)
│   ├── package.json         # Danh sách thư viện và scripts của Backend
│   └── tsconfig.json        # Cấu hình TypeScript
├── docs/                    # Tài liệu đặc tả và hướng dẫn dự án
│   ├── checklist.md         # Bảng tiến độ theo dõi 280 tasks của dự án
│   ├── huong-dan-tao-tai-khoan-dich-vu.md # Hướng dẫn thiết lập tài khoản & dịch vụ
│   ├── kien-truc-phan-mem.docx # Báo cáo thiết kế kiến trúc phần mềm (Task #1)
│   ├── kien-truc-phan-mem.md   # Bản Markdown của báo cáo kiến trúc
│   └── diagrams/            # Các sơ đồ khối kiến trúc độ phân giải cao (PNG)
├── docker-compose.yml       # Cấu hình dịch vụ Docker (PostgreSQL 16, Redis 7, Adminer)
├── .env.example             # File mẫu khai báo các biến môi trường
├── .env                     # File biến môi trường cục bộ (được gitignore)
├── pubspec.yaml             # Cấu hình thư viện và tài nguyên Flutter
└── README.md                # Tài liệu hướng dẫn tổng quan dự án
```

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy (Getting Started)

### 1. Yêu cầu tiên quyết (Prerequisites)

* **Git:** >= 2.40
* **Node.js:** >= 20.x (Khuyến nghị 24.x) & npm >= 10.x
* **Flutter SDK:** >= 3.47.x & Dart >= 3.13.x
* **Docker Desktop:** Đã bật và đang chạy Docker Daemon

---

### 2. Thiết lập Biến Môi Trường (Environment Variables)

Sao chép file cấu hình mẫu `.env.example` thành file `.env` ở thư mục gốc:

```bash
# Trên Windows PowerShell
Copy-Item .env.example .env

# Trên macOS / Linux
cp .env.example .env
```

Mở file `.env` và điền/kiểm tra các thông tin dịch vụ (Database, Redis, Firebase, VNPay Sandbox, Gmail SMTP).

---

### 3. Khởi động Cơ sở dữ liệu & Dịch vụ Nền (Docker)

Tại thư mục gốc của dự án, khởi chạy PostgreSQL 16, Redis 7 và Adminer:

```bash
# Khởi động các container dưới dạng chạy nền
docker compose up -d

# Kiểm tra trạng thái các container
docker compose ps
```

* **PostgreSQL:** Chạy tại cổng `localhost:5432`
* **Redis:** Chạy tại cổng `localhost:6379`
* **Adminer Web UI:** Truy cập quản lý DB trực quan tại [http://localhost:8080](http://localhost:8080)
  * *Hệ thống:* PostgreSQL
  * *Máy chủ:* `postgres`
  * *Tài khoản:* `lms_user`
  * *Mật khẩu:* `lms_password_dev` (hoặc cấu hình trong `.env`)
  * *Cơ sở dữ liệu:* `lms_db`

---

### 4. Cài đặt và Chạy Backend (NestJS)

Di chuyển vào thư mục `backend/` và khởi chạy máy chủ phát triển:

```bash
# Di chuyển vào thư mục backend
cd backend

# Cài đặt các gói phụ thuộc
npm install

# Khởi chạy máy chủ ở chế độ Development (Hot Reload)
npm run start:dev
```

* **Backend API Base URL:** [http://localhost:3000/api/v1](http://localhost:3000/api/v1)
* **Swagger API Docs (dự kiến):** [http://localhost:3000/api/docs](http://localhost:3000/api/docs)

---

### 5. Cài đặt và Chạy Ứng Dụng Flutter (Frontend)

Mở một cửa sổ Terminal mới tại thư mục gốc của dự án:

```bash
# Tải các package của Flutter
flutter pub get

# Kiểm tra thiết bị kết nối (máy ảo Android / iOS / Chrome Web)
flutter devices

# Khởi chạy trên thiết bị mong muốn
# Chạy trên Chrome Web:
flutter run -d chrome

# Hoặc chạy trên Android Emulator:
flutter run -d android
```

---

## 🧪 Kiểm Thử (Testing)

### Backend Testing (Vitest & Supertest)
```bash
cd backend
npm run test         # Chạy Unit Tests
npm run test:cov     # Chạy Unit Tests và xuất độ phủ (Coverage)
npm run test:e2e     # Chạy End-to-End Tests
```

### Frontend Testing (Flutter Test)
```bash
flutter test         # Chạy Widget và Unit Tests của Flutter
```

---

## 📑 Tài Liệu Kèm Theo

* **[Checklist Tiến Độ Dự Án (280 Tasks)](docs/checklist.md):** Kế hoạch chi tiết từ Phase 0 đến Phase 6.
* **[Hướng Dẫn Thiết Lập Tài Khoản & Dịch Vụ](docs/huong-dan-tao-tai-khoan-dich-vu.md):** Hướng dẫn chi tiết tạo Firebase, VNPay Sandbox, Gmail App Password.
* **[Báo Cáo Kiến Trúc Phần Mềm (Task #1)](docs/kien-truc-phan-mem.docx):** Báo cáo đầy đủ kèm 4 sơ đồ khối hệ thống.

---

## 👥 Đội Ngũ Phát Triển & Bản Quyền

* **Đề tài:** Hệ Thống Quản Lý Học Tập (LMS) Trung Tâm Ngoại Ngữ
* **Dự án phục vụ:** Học phần Phân tích Thiết kế Hệ thống / Kiến trúc Phần mềm
* **Bản quyền:** © 2026 Nhóm phát triển dự án. Tất cả quyền được bảo lưu.
