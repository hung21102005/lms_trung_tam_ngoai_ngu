# Rà soát chức năng Admin (27/10/2026)

Tài liệu này ghi nhận trạng thái source hiện tại. Chỉ đánh dấu chức năng đã kết nối khi luồng gọi API thật và xử lý kết quả hoặc lỗi. Chưa chạy kiểm thử tích hợp với PostgreSQL vì backend đang dừng theo yêu cầu trước đó.

| Module | Trạng thái | Việc còn thiếu |
| --- | --- | --- |
| Dashboard tổng quan | Dữ liệu lấy từ `GET /reports/dashboard`; widget test chạy được | Chưa xác minh số liệu trực tiếp với PostgreSQL; bộ lọc chi nhánh chưa áp dụng ở backend |
| Người dùng | Danh sách, tạo, sửa, khóa/mở khóa, đặt lại mật khẩu, nhập/xuất Excel đã gọi API; danh sách tải đủ trang từ API và có phân trang hiển thị | Chưa có xóa, giao diện gán vai trò/quan hệ phụ huynh và bộ lọc/sắp xếp phía server đầy đủ |
| Chi nhánh & phòng | Tạo, đọc, sửa và đổi trạng thái dùng API; xuất CSV từ dữ liệu phòng từng chi nhánh | Thiết bị và nhật ký bảo trì chưa có mô hình/API lưu bền; chưa có xóa và phân trang |
| Tuyển sinh CRM | Tạo lead, xem chi tiết, chuyển trạng thái, chuyển thành học viên, xuất Excel dùng API; lấy đủ trang | Chưa có giao diện sửa/xóa lead đầy đủ; phân trang hiển thị và bộ lọc phía server còn thiếu |
| Khóa học & cấp độ | Danh sách/tạo qua Bloc và API | Học phí/thời lượng trong form tạo khóa học chưa được lưu; thiếu xóa và một số thao tác chương trình |
| Lớp học & xếp lịch | Nút tạo lớp mở form thật; khóa học, cấp độ, chi nhánh, phòng, giáo viên được chọn từ dữ liệu API thay vì gõ ID. Ghi danh học viên và đổi phòng/giáo viên buổi học cũng có danh sách tìm kiếm | Cần kiểm thử tích hợp với PostgreSQL, đặc biệt sắp xếp/xuất thời khóa biểu và phân quyền theo chi nhánh |
| Điểm danh | Có API và màn hình điểm danh từ trước | Cần kiểm thử tích hợp với dữ liệu lớp thực, khóa buổi và phân quyền |
| Báo cáo & tài chính | Dashboard, xuất Excel, tạo hóa đơn và xem chi tiết hóa đơn đã gọi API | Bộ lọc thời gian/chi nhánh/cổng thanh toán chưa áp dụng đầy đủ; bảng đang lấy công nợ để trình bày như giao dịch; chưa có in biên lai; đối soát cổng thanh toán chưa triển khai |
| Cài đặt hệ thống | Thông tin chi nhánh được lưu qua API, báo lỗi thật | RBAC, mẫu thông báo, cổng thanh toán, bảo mật và sao lưu chủ yếu là trạng thái cục bộ; không có API/schema tương ứng. Nút sao lưu giả đã được vô hiệu và bản sao lưu giả đã bị bỏ |

## Các API được bổ sung hoặc gia cố

- `GET /users/export/xlsx` và `GET /admissions/leads/export/xlsx` xuất dữ liệu PostgreSQL.
- Các API quản lý người dùng và lead giới hạn truy cập theo chi nhánh; cập nhật hồ sơ cá nhân chỉ chấp nhận trường cá nhân; nhân viên không được cấp/quản lý tài khoản quản trị cấp cao.
- `GET /users/teachers/lookup` trả về ID, mã và tên giáo viên đang hoạt động trong chi nhánh cho form phân công, cho phép giảng viên tra cứu tối thiểu mà không được xem danh sách tài khoản đầy đủ.

## Kiểm tra đã chạy

- `backend/npm run build`: qua.
- Unit test Users, Admissions, Reports: 23/23 qua.
- `flutter test test/admin_dashboard_screen_test.dart`: qua.
- `flutter analyze --no-pub`: không còn lỗi biên dịch, còn cảnh báo/info lint trong nhiều màn hình.

## Giới hạn xác minh

Không có xác minh CRUD end-to-end với PostgreSQL trong lượt này. Không xem các mục còn thiếu ở bảng trên là đã hoàn thành.
