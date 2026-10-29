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
| 3 Class offering | Đang thực hiện | Đã bổ sung cửa sổ đăng ký và ràng buộc cơ bản khi tạo lớp; còn cần UI sửa lớp, kiểm tra phân công GV, công bố lớp và HTTP workflow. Catalog seed vẫn chờ duyệt. |
| 4 Public website | Đang thực hiện | Đã có Flutter landing/catalog/chi tiết khóa/lớp sắp khai giảng/form tư vấn trên route công khai; dùng API thật và trạng thái loading/empty/error. Chưa kiểm chứng luồng form với Backend đang chạy và dữ liệu lớp đã công bố. |
| 5 Registration/CRM | Đang thực hiện | Đã có đơn đăng ký riêng cho khách mới/học viên cũ, hàng chờ học vụ, đánh dấu liên hệ/từ chối và xác nhận nhập học có transaction ghi danh/hóa đơn. Còn thiếu kiểm chứng HTTP thành công trên lớp đã công bố thật, chuyển Lead thành tài khoản qua UI liền mạch và kiểm tra tải đồng thời với các luồng ghi danh khác. |
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

## Checkpoint tài liệu bài học (2026-10-28)

- Trong chi tiết khóa Admin/học vụ có thể chọn tệp từ máy cho bài học. Client dùng `/upload` hiện có để tải tệp thật, sau đó `POST /lessons/:id/materials` lưu URL, loại tệp và kích thước vào Database. Form kiểm tra tên, tệp và giới hạn 50 MB; hỗ trợ PDF, Office, TXT, ZIP/RAR, ảnh, âm thanh, MP4. Khi tải/lưu lỗi, form giữ dữ liệu để thử lại.
- Backend chặn thêm tài liệu vào khóa đã lưu trữ. Không thêm API hoặc migration. Test datasource xác nhận multipart upload trước khi tạo bản ghi tài liệu; widget test xác nhận form không cho lưu khi thiếu tệp. **Chưa kiểm chứng thực tế** FilePicker/Firebase Storage/DB trên thiết bị và Backend đang chạy; việc upload thành công nhưng lưu bản ghi thất bại có thể để lại tệp chưa được liên kết và cần cơ chế dọn sau.
- Flutter analyzer phạm vi thay đổi **0 issues**, widget regression chương trình/khóa/tài liệu **38/38 đạt**, `flutter build web --no-wasm-dry-run` **đạt**. Backend build **đạt**, lint **đạt** với 12 cảnh báo cũ, test backend **145/145 đạt**.
- **Điểm tiếp tục:** rà soát nội dung seed và luồng publication qua HTTP/DB, sau đó hoàn thiện mở lớp (lịch, phòng, giáo viên, học phí, cửa sổ đăng ký). Website công khai và registration/CRM vẫn Pending.

## Checkpoint audit catalog và HTTP chỉ đọc (2026-10-28)

- Thêm `npm run audit:curriculum` chỉ đọc PostgreSQL, đối chiếu đúng 7 chương trình và 47 khóa seed, liên kết chương trình, trạng thái nháp và cấu trúc cấp độ/học phần/bài học. Kết quả cục bộ: **7/7 chương trình, 47/47 khóa, 0 vấn đề cấu trúc; 47 khóa vẫn cần duyệt học thuật thủ công**. Audit tự động không đánh giá chất lượng giáo án.
- Khởi động Backend tạm để kiểm tra HTTP rồi đã dừng: `GET /public/programs` và `/public/courses` trả **200** với danh sách rỗng vì seed chưa công bố; slug không tồn tại trả **404**; `/courses` và `/programs` không JWT trả **401**. E2E test học thuật cũ được cập nhật theo hợp đồng API hiện tại và **3/3 đạt**.
- Backend build và kiểm thử seed/audit tập trung đạt. Chưa kiểm thử thao tác **ghi** qua HTTP (duyệt/công bố, tạo/sửa) để tránh thay đổi dữ liệu thật; chưa kiểm chứng thiết bị thật. Giai đoạn 01 vẫn chưa hoàn thành do 47 khóa seed cần duyệt nội dung trước khi công bố.
- **Tiếp theo:** hoàn thiện mở lớp với ràng buộc khóa/level, phòng, giáo viên, lịch, học phí, cửa sổ đăng ký; tiếp tục giữ website công khai và registration ở trạng thái Pending cho đến khi lớp được công bố an toàn.

## Checkpoint mở lớp: thời gian đăng ký và kiểm tra dữ liệu (2026-10-28)

- Migration cộng dồn `20261028231500_class_registration_window` thêm `registrationOpenAt` và `registrationCloseAt` vào lớp, đã áp dụng thành công trên PostgreSQL local; không thay đổi dữ liệu lớp cũ. API `POST/PATCH /classes` nhận hai ngày này và kiểm tra nhập đủ cặp, thứ tự ngày, hạn đăng ký không sau ngày khai giảng.
- Khi tạo lớp, Backend từ chối phòng thuộc chi nhánh khác, giờ kết thúc không sau giờ bắt đầu, ngày học rỗng hoặc trùng. Form mở lớp Admin đã có chọn khoảng đăng ký, giữ trạng thái lớp `PLANNING`; chi tiết lớp hiển thị khoảng đã lưu cho quản trị/học vụ. Dữ liệu đi qua Bloc/Repository/API hiện có.
- Backend build đạt, lint đạt (cảnh báo cũ), toàn bộ test **153/153 đạt**. Flutter analyzer phạm vi lớp **0 issues**; widget regression form/danh sách/chi tiết lớp **28/28 đạt** tại 320–1200 px và bàn phím mở. `flutter build web --no-wasm-dry-run` đạt. Thao tác tạo lớp thật qua HTTP chưa kiểm chứng.
- **Còn thiếu:** giao diện sửa thông tin lớp và khoảng đăng ký; kiểm tra giáo viên hợp lệ/thuộc chi nhánh, xung đột trợ giảng, quy trình công bố lớp; public API danh sách lớp; đăng ký từ khách/học viên cũ; đồng bộ CRM. Không thể mở lớp từ 47 khóa seed cho đến khi được duyệt học thuật và công bố; không tự công bố seed.

## Checkpoint ràng buộc phân công mở lớp (2026-10-28)

- `POST /classes` chỉ nhận phòng đang hoạt động, cùng chi nhánh và có đủ sức chứa cho sĩ số lớp. Giáo viên chính/trợ giảng được chọn phải có vai trò `teacher`, đang hoạt động và thuộc chi nhánh lớp; hai vai trò không thể dùng cùng một tài khoản. Những điều kiện này được kiểm tra tại Backend dù client gửi ID trực tiếp.
- Sinh ngày học và kiểm tra trùng lịch theo UTC để tránh lệch ngày khi máy chủ chạy ở múi giờ khác. Backend build đạt, lint đạt với 8 cảnh báo cũ ngoài phạm vi, test toàn bộ **157/157 đạt**. Chưa kiểm chứng tạo lớp qua HTTP với dữ liệu thật; không thay đổi lớp đã tồn tại.
- **Tiếp tục:** UI sửa thông tin lớp/cửa sổ đăng ký và an toàn khi đổi lịch; kiểm tra trùng lịch với trợ giảng và các vai trò phân công; thiết kế trạng thái/công bố lớp, public API lớp sắp khai giảng. Catalog seed vẫn chưa được duyệt học thuật nên không được tự mở lớp từ dữ liệu đó.

## Checkpoint sửa lớp và mở tuyển sinh (2026-10-28)

- `PATCH /classes/:id` cho sửa tên, sức chứa, học phí, ghi chú, cửa sổ đăng ký và trạng thái; chặn sửa các trường lịch/khóa/phòng/giáo viên tại endpoint này vì các buổi học đã sinh sẽ không tự cập nhật. Sĩ số mới không được thấp hơn số đang học hay vượt sức chứa phòng. Chỉ mở đăng ký khi có đủ ngày, phòng, giáo viên chính, học phí dương và khóa đã công bố; kiểm tra tương tự khi `POST /classes` tạo thẳng trạng thái mở.
- Chi tiết lớp có nút sửa cho quản trị/học vụ. Mobile dùng sheet cuộn theo bàn phím, Desktop dùng dialog, giữ form khi API lỗi và tải lại lớp sau khi lưu. Sử dụng `ClassesRepository`/API sẵn có, không thêm endpoint.
- Backend build/lint đạt (8 cảnh báo cũ), **162/162 tests đạt**. Flutter scoped analyzer **0 issues**, widget regression tạo/danh sách/chi tiết/sửa lớp **31/31 đạt** tại 320–1200 px, gồm trường hợp bàn phím và API lỗi; Web build đạt.
- `flutter test` toàn dự án **chưa đạt**: trước khi dừng tại ~70 giây, ghi nhận 45 lỗi ở các stress/route tests và kẹt tại test báo cáo giảng viên. Kiểm tra riêng `challenger_m1_stress_test.dart` thấy test thiếu đăng ký `ApiClient` trong GetIt, giả định route cũ và `pumpAndSettle` timeout; chưa quy kết các lỗi này cho module lớp. Không ghi là full Flutter suite pass.
- **Còn thiếu:** HTTP end-to-end tạo/sửa/mở lớp trên dữ liệu thật, dời lịch hàng loạt an toàn, kiểm tra xung đột trợ giảng, public API lớp sắp khai giảng và đăng ký/CRM. Chưa kiểm thử thiết bị thật; 47 khóa seed chưa được duyệt nên không mở tuyển sinh từ chúng.

## Checkpoint API lớp công khai (2026-10-28)

- `GET /public/classes` và `GET /public/classes/:id` không yêu cầu JWT, chỉ trả lớp `OPEN_FOR_ENROLLMENT` có ngày nhận đăng ký hiện hành, ngày khai giảng chưa qua, học phí dương, phòng/chi nhánh/giáo viên đang hoạt động và khóa thuộc chương trình đã công bố công khai. Danh sách có phân trang, lọc theo chi nhánh/khóa và số chỗ còn lại; projection không chọn học viên hay dữ liệu buổi học nội bộ.
- Backend build/lint đạt (8 cảnh báo cũ), toàn bộ unit test **164/164 đạt**; E2E HTTP không JWT **4/4 đạt** trên app/DB cục bộ. Chưa có lớp mới đủ điều kiện trong catalog seed, nên E2E hiện chỉ xác nhận hợp đồng API và danh sách rỗng; chưa kiểm chứng lớp xuất hiện sau quy trình công bố thật.
- **Tiếp theo:** xây trang chủ/khóa học/lớp sắp khai giảng Flutter công khai dùng các API `/public/*`, rồi form tư vấn và đăng ký mới/cũ đồng bộ CRM. Không giả lập kết quả thành công và không công bố seed chưa duyệt.

## Checkpoint website công khai Flutter (2026-10-28)

- Route `/gioi-thieu`, `/khoa-hoc-cong-khai`, `/khoa-hoc-cong-khai/:slug`, `/lop-sap-khai-giang`, `/tu-van` cho khách chưa đăng nhập. Trang đăng nhập có lối vào website; route `/` và luồng khôi phục phiên đăng nhập hiện tại được giữ nguyên để tránh hồi quy xác thực. Mobile có điều hướng dưới, Desktop có điều hướng đầu trang; danh sách dùng bố cục theo 1/2/3 cột.
- `PublicCatalogRepository` dùng các API công khai hiện có và `POST /admissions/leads`. Form kiểm tra họ tên, điện thoại, email; vô hiệu nút lúc gửi; chỉ hiện xác nhận khi POST thành công và giữ dữ liệu khi lỗi. Khóa/lớp chưa công bố hiển thị trạng thái trống từ API, không tạo mock data trong sản phẩm.
- Kiểm thử: `flutter analyze` phạm vi Public + route/login/test **0 issues**; widget tests **5/5 đạt** trên 320/375/393/430/800/1200 logical px, dữ liệu trống/thực từ fake API, gửi thành công/thất bại và bàn phím mở; `flutter build web --no-wasm-dry-run` **đạt**. HTTP thật cho public catalog đã kiểm tra ở checkpoint trước với database local nhưng hiện không có bản ghi được công bố. POST lead từ giao diện đến Backend thật, trình duyệt/thiết bị thật và visual QA Desktop/Mobile **chưa kiểm chứng**.
- **Tiếp tục:** xây đăng ký lớp cho khách mới và học viên cũ dưới dạng entity riêng, xử lý chống trùng/giữ chỗ/chuyển CRM và duyệt nhập học trước khi tạo `ClassStudent`. Cần dữ liệu lớp thật được Admin/học vụ công bố để kiểm thử đầy đủ luồng public → enrollment; không tự công bố 47 khóa seed.

## Checkpoint tiếp nhận đăng ký lớp (2026-10-29)

- Migration cộng dồn `20261029001000_class_registrations` thêm `ClassRegistration` và trạng thái riêng. Đã áp dụng trên PostgreSQL local, không reset DB. Đơn giữ `classId`, định danh applicant, liên kết tùy chọn tới `AdmissionLead` hoặc `User`; chưa tạo `ClassStudent` hay hóa đơn khi gửi đơn.
- `POST /public/registrations` nhận khách mới chỉ khi lớp đang công khai, còn chỗ; chuẩn hóa số điện thoại, chống gửi trùng theo lớp/số điện thoại và tạo Lead + đơn cùng transaction. `POST /my/registrations` lấy danh tính từ JWT và chỉ nhận vai trò học viên; `GET /my/registrations` trả đơn của chính học viên; `GET /admissions/registrations` giới hạn vai trò quản trị/học vụ và chi nhánh. Flutter route `/dang-ky-lop/:id` tải chi tiết lớp thật, form khách mới hoặc đăng ký bằng tài khoản học viên đang đăng nhập; thông báo chỉ xuất hiện khi API thành công.
- Kiểm thử: Prisma validate/generate đạt, migration local đạt; Backend build/lint đạt (8 cảnh báo cũ), unit **169/169 đạt**; HTTP E2E academic **5/5 đạt** gồm DTO 400, lớp không tồn tại 404 và endpoint học viên/học vụ yêu cầu JWT 401. Flutter scoped analyzer **0 issues**, Public widget **7/7 đạt** gồm form khách mới/học viên; Web build đạt. Chưa có lớp công bố thật nên chưa kiểm chứng HTTP 201 ghi đơn, rollback transaction với DB thật, mobile/desktop screenshot và thiết bị thật. Full Flutter suite vẫn chưa đạt như ghi ở checkpoint trước.
- **Điểm tiếp tục:** hoàn thiện API/giao diện học vụ xem, liên hệ, từ chối và duyệt đơn; duyệt phải chống vượt sĩ số đồng thời, liên kết tài khoản đã xác minh hoặc chuyển Lead thành học viên an toàn, tạo `ClassStudent` và hóa đơn trong transaction. Không được đổi đơn sang `APPROVED` khi chưa ghi danh thành công. Sau đó chạy E2E trên lớp vận hành đã được duyệt học thuật, không tự công bố seed.

## Checkpoint xử lý đơn và xác nhận nhập học (2026-10-29)

- Học vụ/Admin có màn hình hàng chờ đăng ký lớp nối `GET /admissions/registrations`, lọc trạng thái, làm mới, đánh dấu đã liên hệ và từ chối. Từ CRM có lối vào đơn và quay lại tìm Lead theo số điện thoại để tiếp tục quy trình chuyển đổi tài khoản. Học viên có trang `/student/don-dang-ky` đọc `GET /my/registrations` và xem trạng thái từ backend.
- Thêm `PATCH /admissions/registrations/:id/review` và `POST /admissions/registrations/:id/approve`, giới hạn vai trò và chi nhánh. Duyệt yêu cầu tài khoản học viên đang hoạt động có hồ sơ/vai trò học viên; đơn khách mới đối chiếu số điện thoại với tài khoản/Lead đã chuyển. Transaction Serializable kiểm tra trạng thái lớp, sĩ số, đơn/học viên trùng, rồi ghi danh, lập hóa đơn học phí nếu cần và cập nhật Lead. Lỗi làm transaction rollback, đơn không được báo duyệt thành công khi ghi danh thất bại.
- Kiểm thử: Backend build đạt, lint đạt với 8 cảnh báo cũ, unit **173/173 đạt**, academic HTTP E2E **5/5 đạt** cho xác thực/validation và đơn không tồn tại. Flutter scoped analyzer **0 issues**; widget public + hàng chờ **9/9 đạt** trên 320/375/393/430/800/1200 logical px; Web build đạt. `git diff --check` không báo lỗi nội dung.
- **Chưa kiểm chứng:** HTTP tạo đơn và duyệt thành công với lớp vận hành đã công bố, hành vi cạnh tranh sĩ số khi ghi danh đồng thời qua nhiều endpoint, trình duyệt/thiết bị thật, gửi tệp và giao diện CRM toàn luồng. Database hiện không có lớp công khai đủ điều kiện; không tự công bố 47 khóa seed nháp để tạo kết quả kiểm thử giả.
- **Điểm tiếp tục:** kiểm thử end-to-end khi học vụ có lớp thật được duyệt; nối chuyển Lead → tài khoản học viên và xác nhận đơn trong cùng trải nghiệm CRM; rà soát tương tác với các đường ghi danh thủ công để bảo toàn sĩ số; tiếp tục đồng bộ tài chính/lịch học và Adaptive UI còn Pending.

### Bổ sung hàng chờ sau checkpoint

- `GET /admissions/registrations` trả trạng thái `lead.convertedUserId` cho học vụ. Nút xác nhận nhập học của đơn khách mới chỉ hoạt động sau khi Lead đã gắn với tài khoản học viên; học vụ dùng lối vào CRM để chuyển Lead rồi làm mới hàng chờ. Không yêu cầu nhập UUID thủ công trên giao diện.
- Backend build và 9 kiểm thử service đạt; Flutter analyzer 0 lỗi và 2 kiểm thử widget hàng chờ đạt, gồm trạng thái khóa/mở nút duyệt. Chưa kiểm chứng HTTP tạo và duyệt đơn thật vì chưa có lớp công khai hợp lệ.

## Checkpoint đồng bộ ghi danh thủ công và duyệt đơn (2026-10-29)

- `ClassesService.enrollStudent` nay kiểm tra sĩ số, ghi danh và tạo hóa đơn trong một Prisma transaction `Serializable`, cùng mức cách ly với duyệt đơn đăng ký. Lỗi tranh chấp `P2034` được thử lại tối đa 3 lần; mã hóa đơn dùng định danh ngẫu nhiên thay cho phép đếm dễ trùng. Nếu một bước thất bại, transaction không xác nhận ghi danh riêng lẻ.
- Backend build đạt; lint đạt với 8 cảnh báo cũ; toàn bộ unit **175/175 đạt**, gồm 2 hồi quy mới cho transaction và retry; `git diff --check` đạt. Chưa kiểm chứng tải đồng thời thật với PostgreSQL, HTTP ghi danh thành công trên lớp đã công bố, hoặc luồng thiết bị thật.
- **Điểm tiếp tục:** kết nối chuyển Lead thành học viên với xác nhận đơn trong CRM, rồi chạy HTTP E2E trên lớp đã được học vụ duyệt học thuật. Không tự công bố seed nháp. Đồng thời rà soát các luồng điều chỉnh sĩ số và hóa đơn khác trước khi đánh dấu toàn bộ tuyển sinh hoàn thành.

## Checkpoint an toàn chuyển Lead thành tài khoản (2026-10-29)

- Tái sử dụng `POST /admissions/leads/:id/convert`. Tạo tài khoản và cập nhật Lead trong transaction `Serializable`; chỉ cập nhật khi Lead chưa liên kết học viên. Cạnh tranh mã học viên (`P2002`) hoặc transaction (`P2034`) được thử lại tối đa 3 lần, rồi trả lỗi xung đột rõ ràng. Mật khẩu tạm sinh bằng `crypto.randomInt` thay vì `Math.random`.
- Nếu email chào mừng lỗi sau khi transaction đã commit, API vẫn trả thành công cùng thông tin tài khoản cho học vụ; ghi cảnh báo gửi email để không tạo tài khoản xong rồi báo sai là chuyển đổi thất bại.
- Backend build đạt, lint đạt với 8 cảnh báo cũ, toàn bộ unit **178/178 đạt**; 3 hồi quy mới kiểm tra transaction, hai lượt chuyển cùng Lead và lỗi email. Chưa kiểm chứng SMTP thật, HTTP chuyển Lead thành công trên database thật hoặc tải đồng thời thật.
- **Tiếp theo:** hoàn thiện trải nghiệm đi từ đơn đăng ký → Lead → quay lại duyệt trong CRM; kiểm thử HTTP toàn chuỗi khi có lớp vận hành và chương trình đã duyệt. Giữ trạng thái công bố của 47 khóa seed nháp; không tự tạo dữ liệu kinh doanh giả.

## Checkpoint nối hành trình CRM và hàng chờ đơn (2026-10-29)

- Từ đơn khách mới, học vụ chọn **Tìm Lead trong CRM** để lọc đúng số điện thoại. Sau khi chuyển Lead đó thành tài khoản và đóng hộp thoại chứa thông tin cấp tài khoản, CRM tự mở lại hàng chờ; trạng thái học viên liên kết được tải lại từ API, cho phép xác nhận nhập học. Các API và quy tắc duyệt hiện có được tái sử dụng.
- Widget test mô phỏng toàn bộ điều hướng và chuyển Lead trên Mobile, bên cạnh kiểm tra CRM ở 320/375/393/430/800/1200 px. Analyzer phạm vi CRM/test **0 issues**; hồi quy UI Public + CRM + đơn đăng ký **18/18 đạt**; `flutter build web --no-wasm-dry-run` **đạt**.
- **Chưa kiểm chứng:** HTTP thành công với lớp hợp lệ, trình duyệt/thiết bị thật và nhận email thật. Chưa đánh dấu giai đoạn tuyển sinh hay Adaptive UI hoàn thành.

## Checkpoint trạng thái đơn cho học viên được chuyển từ Lead (2026-10-29)

- `GET /my/registrations` nay trả cả đơn đăng ký bằng tài khoản và đơn khách mới có Lead đã liên kết với tài khoản học viên hiện tại. Khi học viên đăng ký lại cùng lớp sau khi được tạo tài khoản, `POST /my/registrations` trả đơn khách cũ thay vì tạo bản sao mới. Trạng thái vẫn là `PENDING` hoặc `CONTACTED` cho đến khi học vụ duyệt và ghi danh thật.
- Backend build đạt, lint đạt với 8 cảnh báo cũ, unit **180/180 đạt**, gồm 2 hồi quy mới cho truy vấn và chống trùng. Chưa kiểm chứng HTTP thực tế với lớp hợp lệ và tài khoản chuyển đổi thật; không công bố seed nháp để ép dữ liệu thử.
- **Điểm tiếp tục:** HTTP end-to-end trên lớp thật do học vụ mở; kiểm tra tải đồng thời PostgreSQL, hóa đơn/lịch học sau duyệt, gửi email thật và thiết bị Mobile. Tiếp tục các mục Adaptive UI Pending trong `docs/ADAPTIVE_UI_PLAN.md`.
- Kiểm tra chỉ đọc ngày 2026-10-29: PostgreSQL cấu hình tại `localhost:5433` hiện không phản hồi (`Please make sure your database server is running`), nên không thể xác nhận số lớp công khai hiện tại hoặc chạy HTTP ghi đơn/duyệt thành công. Không reset database hay tự công bố khóa seed để vượt qua giới hạn này.
