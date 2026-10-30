# Hướng dẫn cài đặt và chạy EduLMS

> Bản bàn giao theo source tại commit `e58c185` (30/10/2026). Các thay đổi chưa commit trong workspace chưa được xác minh như một bản phát hành. Không đưa mật khẩu, khóa JWT hay tệp `.env` lên Git.

## 1. Hệ thống và cấu trúc

EduLMS quản lý chương trình, khóa học, lớp, tuyển sinh, điểm danh, bài tập, học phí và báo cáo cho quản trị viên, học vụ, giảng viên, học viên và phụ huynh. `lib/` chứa Flutter Web/Android với Bloc và API client; `backend/src/` chứa NestJS REST API; `backend/prisma/` chứa schema, migration và seed PostgreSQL. `docker-compose.yml` khai báo PostgreSQL 16, Redis 7, Adminer và một backend container. Luồng chạy: trình duyệt/Android → Flutter → `api/v1` → NestJS → Prisma → PostgreSQL; Redis phục vụ phần việc phụ trợ. [Sơ đồ kiến trúc](diagrams/diagram1_client_server.png) và [ERD](diagrams/erd_database.png) là tài liệu tham khảo; đối chiếu [schema hiện hành](../backend/prisma/schema.prisma) khi báo cáo.

## 2. Chuẩn bị máy Windows 10/11

| Công cụ | Nguồn chính thức | Kiểm tra |
|---|---|---|
| Git | https://git-scm.com/download/win | `git --version` |
| VS Code | https://code.visualstudio.com/Download | `code --version` |
| Flutter SDK (kèm Dart) | https://docs.flutter.dev/get-started/install/windows | `flutter --version`; `flutter doctor -v` |
| Chrome | https://www.google.com/chrome/ | `flutter devices` thấy Chrome |
| Node.js LTS và npm | https://nodejs.org/ | `node --version`; `npm --version` |
| Docker Desktop (WSL 2) | https://docs.docker.com/desktop/setup/install/windows-install/ | `docker --version`; `docker compose version`; `docker info` |
| Android Studio/SDK (tùy chọn) | https://developer.android.com/studio | `flutter doctor -v`; `flutter devices` |

`pubspec.yaml` yêu cầu Dart `^3.13.2`; chọn bản Flutter mang Dart tương thích và chạy `flutter doctor -v` trước khi cài package. `backend/package.json` dùng NestJS 12, Prisma 6, TypeScript 6 và npm (`backend/package-lock.json` nếu có). Cần kiểm tra `node --version` với các package hiện hành khi cài; repo không có file khóa phiên bản Node riêng được xác minh. Flutter và Node cần nằm trong PATH: nếu lệnh không nhận diện, đóng/mở PowerShell sau khi cài và kiểm tra đường dẫn SDK. Chạy Docker Desktop trước `docker compose`.

## 3. Clone source

```powershell
git clone https://github.com/hung21102005/lms_trung_tam_ngoai_ngu.git
cd lms_trung_tam_ngoai_ngu
Get-ChildItem
code .
```

Đầu vào là quyền truy cập GitHub và Git đã cài. Kết quả mong đợi: thấy `lib`, `backend`, `docs`, `docker-compose.yml`. Trong VS Code chọn Flutter SDK tương thích; `flutter doctor -v` phải nhận SDK. Remote ở trên được đọc từ `git remote -v`, nhưng quyền truy cập remote trên máy mới chưa được kiểm chứng.

## 4. Cấu hình môi trường

```powershell
Copy-Item .env.example .env
```

Chỉnh `.env` tại **root**: đặt `POSTGRES_PASSWORD`, `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET` bằng giá trị riêng. `DATABASE_URL` khi chạy backend trên Windows phải trỏ tới `localhost` và cổng `POSTGRES_PORT` thực tế; khi chạy backend container, Compose tự tạo URL dùng host `postgres`. Prisma CLI đọc `backend/.env` qua `backend/prisma.config.ts`: tạo file `backend/.env` cục bộ với `DATABASE_URL` trỏ `localhost` trước lệnh migration/seed. Backend NestJS đọc biến môi trường qua ConfigModule; nếu chạy riêng trong `backend/`, đồng bộ các biến cần thiết từ mẫu root vào `backend/.env`. Không commit hai file này. Firebase, SMTP, VNPay chỉ cấu hình khi demo đúng tính năng tương ứng; thiếu thông tin dịch vụ ngoài có thể khiến các luồng đó không hoạt động. Xem [mẫu biến](../.env.example) và [hướng dẫn dịch vụ](huong-dan-tao-tai-khoan-dich-vu.md).

## 5. Khởi động dịch vụ

Từ root, khởi động riêng cơ sở dữ liệu, Redis và Adminer để chạy backend bằng npm:

```powershell
docker compose up -d postgres redis adminer
docker compose ps
docker compose logs postgres
```

Mặc định PostgreSQL ở `localhost:5432`, Redis ở `localhost:6379`, Adminer ở `http://localhost:8080`; port đổi được bằng `.env`. `docker compose up -d` không ghi tên service sẽ **khởi động cả backend container**, dễ xung đột cổng 3000 với `npm run start:dev`. `docker compose ps` phải cho thấy PostgreSQL và Redis healthy. `docker compose logs backend` chỉ dùng khi chọn chạy backend trong Compose. `docker compose down` dừng service và giữ named volumes; **không dùng `down -v`** trong quy trình thường vì xóa volume chứa database. Khởi động lại bằng `docker compose up -d postgres redis adminer`.

## 6. Cài và chạy backend

```powershell
cd backend
npm ci
npx prisma generate
npx prisma migrate deploy
npm run start:dev
```

`migrate deploy` áp dụng migration hiện có vào database đã chọn; chỉ dùng với DB mới/test hoặc sau khi kiểm tra backup và `DATABASE_URL`. Không chạy `prisma migrate reset`. Seed có thể thay đổi dữ liệu theo script, vì vậy **chỉ trên DB demo riêng** sau khi đọc `prisma/seed.ts`: `npm run seed`. `npm run seed:curriculum` và `npm run seed:learning-flow` là các script bổ sung, không mặc định cần chạy. Kết quả mong đợi: log backend tại `http://localhost:3000/api/v1`; Swagger ở `http://localhost:3000/api/docs`. Nếu chọn backend container, dùng `docker compose up -d` từ root và không mở thêm `npm run start:dev` cùng cổng.

## 7. Cài và chạy Flutter

Mở PowerShell thứ hai tại root:

```powershell
flutter pub get
flutter devices
flutter run -d chrome
```

Kết quả mong đợi: trang công khai mở trên Chrome. API client ở `lib/core/constants/api_endpoints.dart` trỏ Web tới `http://localhost:3000/api/v1`, Android emulator tới `http://10.0.2.2:3000/api/v1`. Android: khởi động emulator trước, lấy ID từ `flutter devices`, rồi chạy `flutter run -d <DEVICE_ID>`. Điện thoại thật dùng địa chỉ máy chủ trong LAN; cấu hình hiện tại không tự đổi sang địa chỉ đó. Cổng Flutter Web do `flutter run` in ra, không cố định. `flutter build web` tạo bản phân phối, không khởi chạy backend.

## 8. Thứ tự kiểm tra và xử lý lỗi

1. `docker compose ps`: PostgreSQL/Redis healthy; nếu không, xem `docker compose logs postgres`.
2. Kiểm tra `DATABASE_URL` trong `backend/.env` đúng host/port/user/database; lỗi `P1001` thường là chưa kết nối DB hoặc sai cổng.
3. Backend báo cổng 3000 đã dùng: kiểm tra tiến trình/container đang giữ cổng, chỉ chạy một backend.
4. Mở Swagger để xác nhận backend lắng nghe; nếu trang Flutter báo lỗi API, kiểm tra Network tab và URL trong `api_endpoints.dart`.
5. Nếu không có khóa/lớp công khai, kiểm tra trạng thái công bố và thời gian đăng ký trong dữ liệu; không thêm dữ liệu giả vào giao diện.
6. Tài khoản đăng nhập lần đầu có thể phải đổi mật khẩu; cần chuẩn bị trước buổi demo.
7. `flutter doctor -v` hướng dẫn sửa Android SDK/Chrome/PATH khi `flutter devices` không thấy thiết bị.

## 9. Làm việc nhóm trên Git

Trước khi làm: `git status`, `git pull --ff-only`. Tạo nhánh riêng theo nhiệm vụ, kiểm tra diff trước commit và mở PR để nhóm review. Không đưa `.env`, tệp khóa Firebase, mật khẩu demo hay dữ liệu cá nhân vào commit. Nếu `git pull` bị từ chối vì thay đổi cục bộ, trao đổi người phụ trách; không reset hoặc force push. Hướng dẫn demo ở [kịch bản báo cáo](KICH_BAN_DEMO_VA_BAO_CAO.md).
