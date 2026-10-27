# Teacher Portal: tiến độ triển khai

## Audit ngày 27/10/2026

Kiến trúc: Flutter client (`lib/features`, BLoC, Dio), NestJS API (`backend/src/modules`), Prisma/PostgreSQL (`backend/prisma/schema.prisma`), JWT và RolesGuard. Các luồng lớp học, lịch, điểm danh, bài tập, bài kiểm tra, thông báo và hồ sơ đã có module/API. Teacher Portal có màn hình dashboard, lớp, lịch, điểm danh, bài tập và kết quả bài tập. Các chức năng nâng cao trong yêu cầu 14 module chưa được chứng minh là hoàn chỉnh.

| Module | Trạng thái sau lượt này | Việc tiếp theo |
| --- | --- | --- |
| Dashboard | API `/reports/teacher/dashboard` tính lớp, học viên, lịch, bài nộp và bài thi cần chấm, thông báo; cảnh báo học viên vắng không phép từ 3 buổi trong 30 ngày. Lối tắt bài tập mở đúng lớp giảng viên | Biểu đồ kết quả và hoạt động gần đây chưa có |
| Lớp học của tôi | Màn hình giảng viên dùng `/my/classes`, tìm/lọc, mở lớp và bài tập; không hiện tạo lớp. Chi tiết lớp có tab lịch học, học viên, giáo trình và tiến độ; tài liệu học theo bài được lấy từ `/levels/:id/modules`. API chỉ trả danh sách học viên tối thiểu cho giảng viên; UI ẩn liên hệ và học phí | Thêm các tab hoạt động lớp, theo dõi kết quả học tập và kiểm thử E2E với dữ liệu thật |
| Lịch dạy | Dùng `/my/schedule`; Backend cấm giảng viên tự đổi ngày/giờ/phòng/giáo viên | UI yêu cầu đổi lịch, ghi sổ đầu bài |
| Điểm danh | Đã có luồng chọn lớp/buổi và API riêng. Lưu điểm danh và khóa buổi trong một Prisma transaction; Backend kiểm tra đủ sĩ số và tránh khóa trùng. UI gọi một lần thay vì hai lần | Rà soát lịch sử, tỷ lệ chuyên cần và đồng bộ đa vai trò |
| Bài tập và chấm | Đã có API/UI giao, nộp, chấm | Bản nháp, xuất bản, đóng nhận, công bố điểm |
| Báo cáo | API chuyên cần và học tập được giới hạn theo lớp giảng viên khi vai trò teacher gọi. Menu Teacher Portal có trang báo cáo lấy dữ liệu từ repository sẵn có, lọc theo lớp, hiển thị chuyên cần và kết quả học tập, tải lại khi lỗi | Kiểm thử E2E với PostgreSQL và bổ sung bộ lọc thời gian khi nghiệp vụ yêu cầu |
| Bài kiểm tra, sổ điểm, học viên, tài liệu, tiến độ, nhận xét, thông báo, hồ sơ | Có một số thành phần nền, chưa audit hoặc kiểm thử đầy đủ | Thực hiện lần lượt theo yêu cầu giai đoạn 4 và 5 |

## File đã sửa trong lượt này

- `backend/src/modules/reports/reports.controller.ts`, `reports.service.ts`, `reports.service.spec.ts`
- `backend/src/modules/classes/classes.service.ts`, `classes.service.spec.ts`
- `lib/features/reports/presentation/screens/teacher_dashboard_live_screen.dart`
- `lib/features/classes/presentation/screens/teacher_my_classes_screen.dart`, `class_list_screen.dart`
- `lib/features/dashboard/presentation/screens/teacher_home_screen.dart`
- `lib/core/router/app_router.dart`

## Lượt tiếp theo ngày 27/10/2026

- Sửa `backend/src/modules/reports/reports.service.ts` và test để bổ sung số lượt thi chờ chấm, nhóm học viên vắng ít nhất ba buổi trong 30 ngày theo lớp được phân công.
- Sửa `lib/features/reports/presentation/screens/teacher_dashboard_live_screen.dart` để hiển thị các chỉ số và cảnh báo mới.
- Sửa `backend/src/modules/attendance/attendance.service.ts`, DTO và test: `POST /sessions/:id/attendance` nhận thêm `lock`, ghi bản điểm danh và chuyển buổi học sang `COMPLETED` trong cùng giao dịch; không thêm API hoặc bảng mới.
- Sửa Attendance Repository/DataSource, `teacher_attendance_view.dart` và test Flutter để gửi `lock: true` một lần.
- Sửa route và lối tắt bài tập giảng viên trong `app_router.dart`, `route_names.dart`, `teacher_my_classes_screen.dart`.
- Ẩn nút điều chỉnh lịch khỏi giảng viên ở `class_detail_screen.dart` để giao diện khớp với quyền Backend; vẫn có lối vào điểm danh.
- Thêm tab giáo trình và tiến độ vào chi tiết lớp từ API hiện có; hiển thị bài đã dạy theo buổi học hoàn thành, tài liệu của từng bài và trạng thái lỗi/tải lại.
- Giới hạn dữ liệu danh sách học viên trong `GET /classes/:id` đối với giảng viên; ẩn học phí/liên hệ trên chi tiết lớp. Sửa nút bài tập từ chi tiết lớp để mở đúng chế độ giảng viên.
- Thêm trang `teacher_reports_screen.dart` và mục menu báo cáo trong `teacher_home_screen.dart`, tái sử dụng `ReportsRepository` cùng API `/reports/attendance`, `/reports/academic`; không tạo API trùng.

Kiểm thử lượt này: `npm run build` đạt; `npm run test -- classes.service.spec.ts reports.service.spec.ts attendance.service.spec.ts` 44/44 đạt; `flutter test --no-pub test/teacher_attendance_functional_test.dart test/attendance_mark_screen_test.dart test/remote_datasources_parsing_adversarial_test.dart` 37/37 đạt; `flutter test --no-pub test/teacher_class_workflow_view_test.dart test/teacher_attendance_functional_test.dart test/attendance_mark_screen_test.dart` 5/5 đạt; `flutter test --no-pub test/teacher_reports_screen_test.dart` 1/1 đạt. `flutter analyze` phần Dashboard, Attendance, route, chi tiết lớp và báo cáo không có lỗi. Đã sửa setup GetIt trong `challenger_m3_attendance_logbook_test.dart`; ca 1.1 vẫn thất bại vì kỳ vọng nhãn giao diện cũ `Điểm Danh & Sổ Đầu Bài`. Suite này cần viết lại các kỳ vọng theo luồng hiện tại, không dùng làm cổng kiểm thử cho thay đổi mới.

## Kiểm thử

- Backend `npm run build`: đạt.
- `npm run test -- classes.service.spec.ts reports.service.spec.ts`: 29 bài đạt.
- Flutter analyze các màn hình mới và điều hướng: không có lỗi.
- `flutter test --no-pub test/teacher_class_workflow_view_test.dart test/teacher_attendance_functional_test.dart`: 4 bài đạt.
- Chưa chạy E2E với PostgreSQL vì backend được yêu cầu giữ ở trạng thái dừng trong phiên trước. Chưa xác nhận dữ liệu API trực tiếp bằng tài khoản giảng viên.

## Quyết định và giới hạn

- Dashboard cũ còn trong repo để tránh phá các phụ thuộc chưa rà soát; route giảng viên hiện dùng màn hình mới.
- Không tạo migration hoặc thay đổi cấu hình bảo mật.
- Không đánh dấu toàn bộ Teacher Portal hoàn tất. Cần tiếp tục audit, triển khai và kiểm thử từng module trong danh sách trên.

## Rà soát giao diện mobile ngày 27/10/2026

- Sửa ô chọn lớp ở Bài tập & Chấm bài theo ảnh người dùng: `isExpanded` giữ nhãn dài trong chiều rộng khả dụng. Áp dụng cùng cách cho ô chọn lớp, báo cáo, buổi học, hồ sơ, tài chính và các form quản trị có cùng cấu trúc.
- Sửa các bộ lọc lớp/khóa học và nhãn dài ở sidebar Admin; sửa bộ lọc và các thẻ KPI của màn hình sổ điểm cũ để không tràn ngang trong kiểm thử 393×852.
- Thêm ca kiểm thử tên lớp dài ở 393×852 vào `teacher_class_workflow_view_test.dart`.
- Bộ `challenger_m2_responsive_stress_test.dart` sau sửa không ghi nhận `RenderFlex overflowed` trong log; suite vẫn thất bại ở các giả định cũ về widget `BottomNavigationBar`/breakpoint. Chạy riêng widget sổ điểm ở 393×852 cũng không còn log tràn, nhưng ca kiểm thử cũ thất bại do nội dung kỳ vọng không khớp. 9/9 ca hồi quy lớp, lịch, báo cáo chọn lọc đạt. Chưa có cơ sở khẳng định mọi màn hình và mọi cỡ chữ/thiết bị đều hết tràn.

## Sửa báo cáo và tách kết quả bài tập ngày 27/10/2026

- `GET /reports/academic` trước đây yêu cầu `ExamAttempt.percentage`, trường không tồn tại trong Prisma schema, nên trả 500. Dùng `score/maxScore` để tính phần trăm, phân loại và danh sách học viên điểm cao; thêm test dựa trên hai trường thật.
- `Bài tập & Chấm bài` giữ luồng giao bài và mở chi tiết để chấm. `Kết quả bài tập` giờ gọi API danh sách bài nộp của từng bài đã chấm, chỉ hiện học viên có điểm, số điểm và nhận xét; không có nút giao bài hay thao tác chấm.
- Trang báo cáo hiển thị lỗi máy chủ ngắn gọn cùng nút thử lại, thay cho stack trace Prisma dài trong giao diện.
- Backend build đạt, `reports.service.spec.ts` 13/13 đạt; Flutter test cho workflow và báo cáo 5/5 đạt. Chưa kiểm thử trực tiếp với DB đang chạy vì Backend được giữ dừng theo yêu cầu trước đó.

## Đồng bộ tình trạng nộp bài ngày 27/10/2026

- API chi tiết bài tập trả `stats.submittedCount`, còn Flutter model từng chỉ đọc `stats.totalSubmissions`, khiến thẻ chi tiết ghi 0 dù danh sách và màn hình chấm có 4 bài nộp. Model nay đọc `submittedCount` trước và vẫn hỗ trợ `totalSubmissions` ở API danh sách. API chi tiết bổ sung alias `totalSubmissions` để hợp nhất hợp đồng dữ liệu.
- Thẻ tình trạng hiển thị riêng số đã nộp, đã chấm, chưa chấm. Với dữ liệu ảnh người dùng: 4 đã nộp, 3 đã chấm, 1 chưa chấm.
- Backend build đạt, `assignments.service.spec.ts` 12/12 đạt; Flutter test model và sửa bài tập 6/6 đạt; analyzer các file đã sửa không có lỗi.

## Phân quyền giao diện Khóa học của học viên ngày 27/10/2026

- Student Portal trước đây nhúng `CourseListScreen` của quản trị, nên hiển thị tạo khóa học, xuất khung đào tạo và thống kê toàn hệ thống. Đã thay bằng `StudentCoursesScreen` chỉ lấy lớp ghi danh từ `/my/classes`, mở giáo trình của cấp độ lớp và tính tiến độ bằng buổi học đã hoàn thành. Không có thao tác tạo/sửa/xuất.
- Route `/courses` và `/courses/:id` chuyển tài khoản học viên về trang riêng theo vai trò. API tạo/sửa khóa học vốn đã dùng JWT và `RolesGuard` cho admin/học vụ; không thêm endpoint hoặc migration.
- Kiểm thử widget ở 393×852 xác nhận lớp ghi danh, tiến độ 1/2 và không có nút quản trị. Bộ chọn lọc khóa học/lịch/nộp bài 9/9 đạt; analyzer các file mới và điều hướng không có lỗi. Chưa chạy E2E với tài khoản học viên và PostgreSQL.
