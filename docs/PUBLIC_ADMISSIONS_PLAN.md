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
| 2 Curriculum foundation | Đang thực hiện | Migration cộng dồn đã áp dụng; seed nháp tạo 7 chương trình, 47 khóa, 47 cấp độ, 94 học phần và 188 bài học. Chạy lại seed không tạo trùng. Có API và màn hình Admin quản trị chương trình/khóa: tạo, gắn khóa có sẵn, sửa trường công khai, duyệt/công bố; màn hình sửa cấp độ qua API hiện có. Còn thiếu UI sửa học phần/bài học, biên tập học thuật chi tiết và kiểm thử HTTP thực tế. |
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

## Checkpoint API catalog và công bố (2026-10-28)

- Nội bộ có `GET/POST/PATCH /programs`, `PATCH /programs/:id/status`, `PATCH /programs/:id/visibility`, `PATCH /courses/:id/publication`. Các thao tác ghi yêu cầu vai trò quản trị/học vụ. Chuyển trạng thái theo `DRAFT → IN_REVIEW → PUBLISHED → ARCHIVED`, có kiểm tra mô tả chương trình, liên kết chương trình, nội dung cấp độ/bài học và lớp đang mở trước khi công bố/lưu trữ khóa.
- `GET /public/programs`, `GET /public/courses`, `GET /public/courses/:slug` chỉ trả bản công bố, khóa đang hoạt động và chương trình bật hiển thị. API công khai không trả bài học đầy đủ, học phí, lớp hoặc dữ liệu vận hành nội bộ.
- `npm run build`: đạt; `npm run lint`: đạt với 12 cảnh báo ngoài phạm vi. `npm run test`: 16 files, 137 tests đạt, gồm kiểm thử lọc catalog công khai và chuyển trạng thái chương trình/khóa. Vẫn cần kiểm thử Flutter UI khi triển khai.
- Chưa kiểm thử HTTP với Backend chạy, chưa có UI Admin cho duyệt, và seed hiện vẫn là đề cương chờ biên tập. Không đánh dấu giai đoạn 01 hoàn thành.

## Checkpoint chỉnh sửa cấp độ (2026-10-28)

- `PATCH /levels/:id` cho Admin/học vụ sửa tên, mã, chuẩn CEFR/IELTS/TOEIC/Cambridge, điều kiện đầu vào, tiêu chí hoàn thành và thời lượng tham khảo. Backend chặn mã trùng trong cùng khóa và khóa đã lưu trữ.
- Kiểm thử tập trung `CoursesService`: 14/14 đạt; toàn bộ backend: 16 files, 139 tests đạt; `npm run build` đạt.
- Việc sửa cấp độ hiện chưa có giao diện Admin và chưa kiểm thử HTTP. Tiếp theo: nối Admin Course UI với danh mục chương trình, cấp độ và workflow duyệt bằng API hiện có, rồi biên tập sâu học phần/bài học.

## Checkpoint tạm dừng theo yêu cầu người dùng (2026-10-28)

- Đã thêm màn hình Admin quản trị chương trình (`/admin/programs`) dùng `ProgramCatalogRepository` và `ApiClient` hiện có: danh sách, chi tiết, tạo, sửa, gửi duyệt, duyệt, trả nháp, lưu trữ và bật/tắt hiển thị công khai. Danh sách khóa trong chi tiết hiện chỉ đọc và mở sang màn hình khóa cũ. Mobile có thẻ, bottom sheet và form cuộn theo bàn phím; Desktop giữ màn hình khóa cũ, bổ sung lối vào chương trình.
- Đã sửa tràn hàng nút của màn hình khóa Desktop ở 1200 px sau khi thêm lối vào. Widget tests cho màn hình chương trình và hồi quy hai màn hình khóa: **28/28 đạt**, gồm 320/375/393/430/800/1200 px, tạo chương trình và chuyển trạng thái qua API giả trong test. Analyzer phạm vi 6 file: **0 issues**. Chưa build Web ở checkpoint này.
- Chưa kiểm chứng HTTP với Backend chạy, phân quyền thực tế, dữ liệu tạo/sửa trên DB qua UI, thiết bị thật hoặc screenshot Desktop/Mobile. Không đánh dấu giai đoạn 01 hoàn thành.
- **Điểm tiếp tục chính xác:** nối khóa học với chương trình khi tạo/sửa; cho Admin chỉnh slug, mô tả công khai và trạng thái hoạt động, duyệt khóa học qua API hiện có; sau đó UI sửa cấp độ/học phần/bài học, kiểm thử HTTP và cập nhật catalog. Không tạo thêm API trùng.

## Checkpoint UI khóa học và cấp độ (2026-10-28)

- Trong chi tiết chương trình, Admin/học vụ có thể tạo khóa gắn chương trình, tìm và gắn khóa chưa thuộc chương trình, sửa slug/mô tả công khai/trạng thái hoạt động, gửi duyệt/duyệt công bố/lưu trữ khóa. Chi nhánh chỉ đọc. Những thao tác này dùng `/courses` và `/courses/:id/publication` hiện có, không tạo API mới.
- Chi tiết khóa học có form sửa cấp độ trên Mobile (bottom sheet cuộn theo bàn phím) và Desktop (dialog), gồm chuẩn CEFR/IELTS/TOEIC/Cambridge, điều kiện đầu vào, tiêu chí hoàn thành và thời lượng. Form dùng `CoursesBloc` và `PATCH /levels/:id`; vai trò không đủ quyền không thấy nút sửa.
- Widget tests chương trình và khóa học: **33/33 đạt**; scoped analyzer: **0 issues**; `flutter build web --no-wasm-dry-run`: **đạt**. Kiểm chứng API/DB qua HTTP và thiết bị thật vẫn **chưa kiểm chứng**.
- **Tiếp theo:** hoàn thiện UI biên tập học phần/bài học bằng API hiện có hoặc bổ sung API phù hợp nếu thiếu; biên tập nội dung học thuật seed trước khi công bố. Sau đó kiểm thử HTTP end-to-end cho publication và catalog. Giai đoạn 01 vẫn **chưa hoàn thành**.

## Checkpoint biên tập học phần và bài học (2026-10-28)

- Bổ sung `PATCH /modules/:id` và `PATCH /lessons/:id` cho Super Admin/học vụ. Hai API dùng DTO partial theo create DTO hiện có, xác nhận đối tượng tồn tại và chặn sửa khi khóa đã lưu trữ. Không thêm migration hoặc seed.
- Chi tiết khóa học cho phép mở form sửa học phần/bài học. Mobile dùng sheet có SafeArea, cuộn theo bàn phím; Desktop dùng dialog. Dữ liệu đi qua `CoursesBloc`/repository rồi tải lại chi tiết khóa sau khi lưu. Form giữ nội dung nhập khi API lỗi để có thể thử lại.
- Backend `npm run build`: **đạt**; `npm run lint`: **đạt** với 12 cảnh báo đã có ngoài phần vừa sửa; `npm run test`: **142/142 đạt**. Scoped Flutter analyzer: **0 issues**; widget regression chương trình/khóa học: **34/34 đạt**; `flutter build web --no-wasm-dry-run`: **đạt**.
- Còn thiếu giao diện **tạo** học phần/bài học, quản lý tài liệu học thuật và rà soát nội dung seed. Chưa kiểm chứng HTTP/DB qua ứng dụng đang chạy hoặc thiết bị thật. Tiếp tục các mục đó trước khi công bố catalog.

## Checkpoint tạo nội dung học thuật (2026-10-28)

- Chi tiết khóa học có nút tạo học phần trong từng cấp độ và tạo bài học trong từng học phần. Form Mobile/Desktop dùng chung dữ liệu qua `CoursesBloc` và API POST sẵn có; có validation tiêu đề, thứ tự, thời lượng bài học và trạng thái đang lưu. Sau khi tạo, màn hình tải lại khóa học từ server.
- Backend từ chối **tạo lẫn sửa** học phần/bài học khi khóa đã lưu trữ; giao diện ẩn các thao tác này cho khóa lưu trữ và người không đủ quyền. Không có migration hoặc seed mới.
- Backend build **đạt**, lint **đạt** với 12 cảnh báo cũ ngoài phạm vi, toàn bộ backend test **144/144 đạt**. Flutter analyzer phạm vi thay đổi **0 issues**, widget regression chương trình/khóa **36/36 đạt**; `flutter build web --no-wasm-dry-run` **đạt**.
- **Tiếp theo:** quản lý tài liệu bài học, rà soát nội dung seed, kiểm thử HTTP/DB của luồng công bố và catalog; sau đó mới chuyển hoàn toàn sang mở lớp. API chạy thật và thiết bị thật chưa kiểm chứng.
