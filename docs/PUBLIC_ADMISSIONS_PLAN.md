# EduLMS — chương trình, mở lớp và tuyển sinh công khai

Updated: 2026-10-28. Baseline: `aa0e376`. Tiến độ thực tế được ghi sau từng checkpoint; tài liệu này không thay thế [ADAPTIVE_UI_PLAN.md](ADAPTIVE_UI_PLAN.md).

## Thứ tự bắt buộc

1. **Chương trình tiếng Anh:** danh mục, cấp độ, học phần, nội dung và seed nháp an toàn.
2. **Mở lớp:** chọn khóa, lịch, phòng, giáo viên, học phí, cửa sổ đăng ký và điều kiện công bố.
3. **Website công khai:** trang chủ, catalog, lớp sắp khai giảng, form tư vấn.
4. **Đăng ký và tuyển sinh:** khách mới/học viên cũ, CRM, xác nhận nhập học.
5. **Đồng bộ và kiểm thử:** thành viên lớp, học phí, lịch và quyền LMS.

Không tạo lớp, học phí, giảng viên hoặc lịch vận hành từ seed catalog.

## Audit kiến trúc

| Phần | Hiện có | Khoảng trống |
| --- | --- | --- |
| Client | Flutter, `go_router`, Bloc/Repository, Adaptive UI cho bốn vai trò | Chưa có public landing/catalog/registration độc lập |
| Backend | NestJS + Prisma/PostgreSQL, JWT/RBAC | Thiếu `TrainingProgram`, publication workflow và API public chỉ đọc bản công bố |
| Học thuật | `Course → CourseLevel → Module → Lesson → LessonMaterial` | Course hiện trộn tên chương trình với khóa cụ thể; thiếu chuẩn đầu vào/đầu ra, version và phân biệt CEFR/IELTS/TOEIC |
| Lớp | `Class` tham chiếu Course/Level, Branch/Room/Teacher và có buổi học | Thiếu cửa sổ đăng ký, điều kiện công bố và chính sách phí rõ ràng |
| CRM | `AdmissionLead` + API quản lý | Lead chưa phải đơn đăng ký lớp; chưa có nguồn public hoàn chỉnh |
| Nhập học | `ClassStudent` và Student Profile | Chưa có registration/placement/approval tách biệt |
| Tài chính | Invoice/Payment gắn học viên, lớp | Chưa có chính sách giữ chỗ hoặc gắn đơn đăng ký |

`backend/prisma/seed.ts` đang tạo chi nhánh, Lead, học phí và lớp demo; một Lead dùng `create` không idempotent. Script này **không được dùng làm seed catalog vận hành**. Catalog mới phải có lệnh riêng và không sửa dữ liệu demo hay dữ liệu Admin hiện hữu.

API `GET /courses`, `GET /courses/:id` và `GET /courses/:id/levels` trước đây gắn `@Public()` nhưng chưa giới hạn trạng thái công bố. Chúng đã chuyển sang yêu cầu JWT để bản nháp không lộ cho khách vãng lai. Trước khi mở website công khai, cần thêm read API riêng chỉ trả chương trình/khóa `PUBLISHED` và đủ điều kiện hiển thị. Các tài khoản đã đăng nhập hiện vẫn dùng API nội bộ cũ.

## Mapping và thay đổi dữ liệu

| Nghiệp vụ | Entity hiện có | Hướng bổ sung |
| --- | --- | --- |
| Program | Chưa có; `Course` cũ đôi khi đóng vai trò chương trình | `TrainingProgram`, code/slug ổn định, quan hệ Course tùy chọn để không phá khóa cũ |
| Course | `Course` | `programId`, publication status, slug, version; giữ code và các quan hệ cũ |
| Level | `CourseLevel` | các chuẩn CEFR, IELTS band, TOEIC score, Cambridge qualification tách biệt; academic profile có cấu trúc |
| Học phần/bài học | `Module`, `Lesson` | tái sử dụng; thêm khóa ổn định cho seed theo `order`, không đè bài Admin sửa |
| Offering | `Class` | cửa sổ đăng ký, min capacity và kiểm tra công bố; giữ khóa/lớp tách biệt |
| Lead | `AdmissionLead` | tiếp tục là nhu cầu tư vấn, không coi là học viên |
| Registration | Chưa có | entity riêng, status và idempotency; liên kết Lead/User/Class có điều kiện |
| Enrollment | `ClassStudent` | chỉ tạo khi được duyệt, dùng transaction và ràng buộc duy nhất |

Migration chỉ thêm bảng/cột, nullable hoặc default an toàn. Không xóa/đổi code khóa cũ. Mọi khóa mới từ seed bắt đầu `DRAFT` và không xuất hiện công khai.

## Phụ thuộc và kiểm thử

- Chương trình → khóa/level/modules → lớp → public catalog → registration → CRM/approval → ClassStudent/Invoice/LMS.
- Seed: chạy hai lần không tạo trùng; giữ nguyên record Admin đã sửa; báo cáo created/skipped; không tạo lớp.
- Publication: khóa nháp vắng mặt ở public API; role thường không xem dữ liệu nội bộ.
- Mở lớp: kiểm tra course/level thuộc nhau, branch-room, giáo viên/phòng trùng lịch, capacity, học phí và cửa sổ đăng ký.
- Registration: chống trùng và vượt sĩ số kể cả đồng thời; xác minh người dùng trước khi liên kết hồ sơ; không tự xác nhận thanh toán.
- E2E: public → tư vấn/đăng ký → CRM → duyệt → ClassStudent → lịch/học phí/giảng viên/học viên.

## Tiến độ

| Checkpoint | Trạng thái | Kết quả / giới hạn |
| --- | --- | --- |
| 1 Audit | Hoàn thành vòng đầu | Đã xác định các entity/API/seed hiện tại và nguồn demo; các bước còn lại được ghi theo module. |
| 2 Curriculum foundation | Đang thực hiện | Migration cộng dồn đã áp dụng; seed nháp tạo 7 chương trình, 47 khóa, 47 cấp độ, 94 học phần và 188 bài học. Chạy lại seed không tạo trùng. Đã kiểm tra quan hệ Course/Level khi mở lớp và đóng các read API khóa học công khai cũ. Còn thiếu API/UI quản trị chương trình, quy trình duyệt/công bố, nội dung học thuật chi tiết và kiểm thử duyệt thực tế. |
| 3 Class offering | Pending | Chờ catalog ổn định |
| 4 Public website | Pending | Chờ publication API |
| 5 Registration/CRM | Pending | Chờ lớp công bố và public API |
| 6 Đồng bộ/kiểm thử | Pending | Chờ luồng đăng ký |

## Rủi ro và điều chưa kiểm chứng

Chưa có cấu hình học phí, lịch, giáo viên và chính sách thực tế; các trường này phải để chưa cấu hình/chờ duyệt. Migration và seed đã được kiểm chứng trên PostgreSQL cục bộ ngày 2026-10-28, nhưng chưa kiểm chứng E2E với Backend đang chạy hoặc trên môi trường khác. Không tự động chuyển dữ liệu demo sang catalog mới. Migration giữ các khóa cũ đang hoạt động ở trạng thái `PUBLISHED` để không chặn lớp hiện hữu; Admin cần rà soát chất lượng và điều kiện công bố trước khi đưa lên website công khai. Các nguồn chuẩn khảo thí chỉ dùng để tham chiếu mục tiêu năng lực, không thể hiện sự chứng nhận của các tổ chức đó.

## Kiểm chứng checkpoint nền tảng (2026-10-28)

- `npx prisma validate`, `npx prisma generate`, `npx prisma migrate deploy` và `npx prisma migrate status`: đạt; database cục bộ cập nhật đủ 7 migrations.
- `npm run seed:curriculum` chạy hai lần: lần đầu tạo 7/47/47/94/188, lần hai tạo 0 và bỏ qua 7 chương trình/47 khóa.
- `npm run build`: đạt. `npm run lint`: đạt với 12 cảnh báo ở code ngoài phạm vi mới. `npm run test`: 16 files, 130 tests đạt (chạy ngoài sandbox vì Vitest gặp lỗi quyền ghi cache tạm trong sandbox).
- Chưa kiểm thử API qua HTTP, Flutter UI, publication workflow hoặc dữ liệu trên môi trường triển khai. Những mục này vẫn Pending.
