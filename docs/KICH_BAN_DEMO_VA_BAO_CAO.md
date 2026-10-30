# Kịch bản demo và báo cáo EduLMS

> Dùng database **demo riêng** và kiểm tra dữ liệu thật trước buổi báo cáo. Tài liệu mô tả thao tác có trong source; kết quả trên máy của nhóm cần được xác nhận tại chỗ. Không công khai mật khẩu trong tài liệu chia sẻ.

## 1. Phân vai và chuẩn bị (20–30 phút)

Một người thuyết trình kiến trúc, một người thao tác Admin, một người thao tác Teacher/Student, một người theo dõi backend và phương án dự phòng. Mở Chrome desktop và cửa sổ Mobile DevTools hoặc Android emulator. Chạy Docker, backend, Flutter theo [hướng dẫn cài đặt](HUONG_DAN_CAI_DAT_VA_CHAY_DU_AN.md). Mở Swagger `http://localhost:3000/api/docs` để chứng minh API. Chuẩn bị sẵn **một khóa đã công bố, một lớp đang tuyển sinh, một lớp có học viên/giảng viên, một bài tập đã giao, một bài đã nộp và một bài đã chấm**; xác minh chúng trong DB demo, không giả lập trên UI.

### Tài khoản tìm thấy trong seed

| Vai trò | Mã / email trong `backend/prisma/seed.ts` | Trạng thái cần kiểm tra |
|---|---|---|
| Super Admin | `AD-000001` / `admin@lms-edu.vn` | Có trong DB sau seed; mật khẩu seed phải chia sẻ riêng và đổi trên môi trường khác demo |
| Giảng viên | `GV-0001` / `teacher@lms-edu.vn` | Có trong seed; kiểm tra lớp được phân công |
| Học vụ | `HVU-0001` / `academic@lms-edu.vn` | Có trong seed; kiểm tra quyền thực tế |
| Học viên | `HV-2026-0001` / `student@lms-edu.vn` | Seed đặt `isFirstLogin=true`; chuẩn bị luồng đổi mật khẩu |
| Phụ huynh | `PH-0001` / `parent@lms-edu.vn` | Seed đặt `isFirstLogin=true`; xác minh liên kết con |

Seed còn có tài khoản và dữ liệu bổ sung trong các script `seed-learning-flow.ts`, `seed-curriculum-catalog.ts`; không giả định chúng đã chạy trên DB demo. **Mật khẩu hiện tại của mọi tài khoản phải lấy từ người quản trị DB demo qua kênh riêng**, không suy luận từ mã hoặc ghi vào Git. Nếu mật khẩu đã đổi, giá trị trong seed không còn đúng.

## 2. Trình tự demo khách vãng lai (3–4 phút)

1. Mở route `/`; giới thiệu chương trình, khóa học và lớp đang mở lấy từ Public API. Chọn **Chương trình** → **Khóa học** → chi tiết/lộ trình; quay về trang chủ. Kết quả mong đợi: chỉ thấy khóa đã công bố.
2. Vào **Lớp khai giảng**; chọn một lớp còn chỗ và còn thời gian đăng ký. Xem lịch/giảng viên/học phí trước khi đăng ký. Nếu danh sách trống, nói rõ dữ liệu hiện chưa có lớp hợp lệ.
3. Vào **Tư vấn**, nhập thông tin thử nghiệm được nhóm chuẩn bị và gửi một lần. Mở CRM bằng tài khoản có quyền để chỉ ra Lead vừa tạo. Chỉ gửi trên DB demo; không nhập thông tin cá nhân thật.
4. Với lớp hợp lệ, thực hiện đăng ký mới rồi đối chiếu đơn đăng ký ở Admin. **Không hứa tự động ghi danh trước bước duyệt**; trạng thái thực tế trên UI/API quyết định lời thuyết trình.

## 3. Demo Admin và học vụ (5–7 phút)

Đăng nhập Admin → giới thiệu Dashboard (số liệu chỉ được gọi là dữ liệu thật khi API/DB đã phản hồi). Mở **Chương trình/Khóa học**, xem trạng thái Draft/Published, chi tiết và lộ trình. Nếu dữ liệu kiểm duyệt đã chuẩn bị, trình bày preview/validate/publish; không tự công bố khóa seed chưa duyệt. Mở **Lớp học & Xếp lịch** để chỉ ra khóa, giảng viên, phòng, lịch và sĩ số. Mở **Tuyển sinh/CRM** xem Lead và **Đơn đăng ký lớp** để trình bày chuyển đổi/duyệt/ghi danh theo trạng thái thật. Cuối cùng mở người dùng, học phí/hóa đơn và báo cáo. Tránh thao tác xóa hay thanh toán thật trong buổi demo.

## 4. Demo giảng viên (4–5 phút)

Đăng nhập `GV-0001` bằng mật khẩu do nhóm cung cấp riêng. Mở **Lớp học của tôi**, chọn lớp đã phân công; xác nhận danh sách học viên và lịch dạy. Chọn buổi học phù hợp trong **Điểm danh**, đánh dấu một học viên trong DB demo rồi lưu, tải lại để xác nhận dữ liệu. Mở **Bài tập & Chấm bài**, xem bài đã giao, danh sách trạng thái nộp; chọn **Xem bài làm**, nhập điểm/nhận xét cho bài đã nộp và kiểm tra kết quả. Báo cáo giảng dạy và Excel chỉ demo khi API thực tế đã được kiểm chứng trên máy trình bày.

## 5. Demo học viên (4–5 phút)

Đăng nhập tài khoản học viên đã ghi danh; nếu là lần đầu, thực hiện màn hình đổi mật khẩu với thông tin do quản trị demo cấp. Xem khóa/lớp và lịch học. Mở bài tập đã giao, thử nội dung văn bản hoặc tệp hợp lệ; với Speaking thử ghi âm/nghe lại **chỉ khi thiết bị và quyền micro đã kiểm tra trước**. Nộp bài, quay lại danh sách và xác nhận trạng thái đã nộp. Nếu còn hạn và nghiệp vụ cho phép, sửa/nộp lại, sau đó xem điểm và nhận xét của bài đã được giảng viên công bố. Không gắn nhãn “đã chấm” cho bài chưa công bố.

## 6. Demo phụ huynh và phân quyền (2–3 phút)

Đăng nhập `PH-0001` nếu DB demo có liên kết con hợp lệ; chọn con và xem lịch, điểm danh, điểm/học phí theo dữ liệu có thật. Tài khoản học viên không được thấy hành động quản trị; thử truy cập route quản trị và quan sát phản hồi. Kiểm tra backend guard/JWT bằng Swagger chỉ với tài khoản test, không chia sẻ token trên màn chiếu.

## 7. Ba luồng xuyên vai trò

| Luồng | Thao tác | Bằng chứng cần chỉ ra |
|---|---|---|
| Tuyển sinh | Khách xem lớp → gửi đăng ký → CRM xử lý → Admin duyệt → học viên vào lớp | Mã Lead/đơn, trạng thái và sĩ số sau tải lại |
| Học tập | Giảng viên giao bài → học viên nộp → giảng viên chấm → học viên xem kết quả | Trạng thái nộp, điểm và nhận xét thật |
| Chuyên cần | Giảng viên điểm danh → học viên/phụ huynh xem | Cùng một buổi học và trạng thái sau tải lại |

Các bước phụ thuộc dữ liệu và quyền hiện hành. Nếu API hoặc thiết bị không đáp ứng, trình bày trạng thái đã kiểm chứng và dùng ảnh/video ghi từ lần chạy thật, ghi rõ thời điểm ghi hình.

## 8. Sự cố thường gặp

| Hiện tượng | Kiểm tra nhanh | Cách xử lý khi báo cáo |
|---|---|---|
| API mất kết nối | `docker compose ps`, backend log, Swagger | Khởi động lại đúng service; không che lỗi bằng thông báo giả |
| Không thấy khóa/lớp | Trạng thái công bố, hạn đăng ký, chỗ trống | Chuyển sang bản ghi demo đã duyệt; không tự publish toàn bộ seed |
| Tài khoản không có lớp/bài | Liên kết ghi danh và phân công trong DB demo | Dùng tài khoản/lớp đã chuẩn bị |
| Điểm không hiện | Trạng thái chấm và công bố kết quả | Chọn bài đã công bố hoặc giải thích trạng thái chờ |
| File/ghi âm lỗi | Loại file, dung lượng, quyền micro, API upload | Dùng tệp mẫu hợp lệ; ghi nhận giới hạn thiết bị |
| Chrome không mở / UI cũ | `flutter devices`, URL/port, refresh | Mở lại Flutter Web sau khi xác nhận backend |

## 9. Checklist trước giờ báo cáo

- [ ] Docker healthy; Backend, Swagger và Flutter Web mở được.
- [ ] Admin, Teacher, Student và Parent (nếu dùng) đăng nhập được; tài khoản lần đầu đã được chuẩn bị.
- [ ] Có khóa đã công bố và lớp đang tuyển sinh hợp lệ.
- [ ] Có lớp với giảng viên, học viên và buổi học; dữ liệu lịch không trùng ngoài ý muốn.
- [ ] Có Lead/đơn để trình bày; có bài tập, bài nộp và điểm đã công bố.
- [ ] Kiểm tra micro, tệp mẫu, mạng và quyền trình duyệt.
- [ ] Kiểm tra riêng các màn hình/luồng sẽ chiếu; chuẩn bị ảnh hoặc video từ lần chạy thật.
- [ ] Thống nhất người thao tác, thứ tự tài khoản và kênh chia sẻ mật khẩu an toàn.

**Chưa kiểm chứng trong lượt viết tài liệu:** đăng nhập, thao tác E2E với DB demo, Android thật, upload/voice, Excel và thanh toán ngoài. Các kết quả test lịch sử trong repo không thay thế được buổi rehearsal trên máy trình bày.
