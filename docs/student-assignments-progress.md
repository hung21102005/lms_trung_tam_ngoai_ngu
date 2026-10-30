# Student Assignments — tiến độ 27/10/2026

## Đã triển khai

- Danh sách học viên lấy bài tập đã xuất bản từ mọi lớp đang ghi danh. Không còn danh sách `ASM-*` giả khi API lỗi. Có thống kê, tiến độ, tìm kiếm, lọc trạng thái/lớp, sắp xếp hạn nộp hoặc mới nhất.
- Workspace bài làm responsive: desktop có khung đề và khung làm bài cạnh nhau; mobile xếp dọc. Giữ Voice, Text, File theo loại bài. Mô tả có link bấm được, tài liệu giáo viên có thể mở.
- Lưu nháp vào PostgreSQL qua `POST /assignments/:id/draft`; nội dung và URL tệp/ghi âm được nạp lại khi mở bài. Tệp đã upload được giữ trong form nếu lần lưu hoặc nộp tiếp theo lỗi, tránh upload trùng cùng tệp trong phiên làm bài.
- Nộp và nộp lại chỉ báo thành công sau API xác nhận. Có trạng thái nộp muộn và màn xác nhận thời gian nộp. Bài đã chấm hoặc chờ công bố không được sửa. Bài bị trả để làm lại được nộp lại.
- Giáo viên chấm rồi chủ động công bố qua `PATCH /submissions/:id/publish`; trước khi công bố, API học viên ẩn điểm, nhận xét và người chấm. Giáo viên có thể yêu cầu làm lại qua `PATCH /submissions/:id/return` kèm hướng dẫn.
- API danh sách/chi tiết học viên chỉ trả bài đã xuất bản; truy cập lớp và quyền lưu/nộp/chấm vẫn kiểm tra ở Backend. Bản nháp không được tính là bài đã nộp hoặc hiển thị trong danh sách chấm.
- Migration `20261027173000_assignment_drafts_publication` thêm trạng thái bài tập, bản nháp, thời gian công bố, cho phép `submittedAt` rỗng. Điểm đã chấm trước migration được đánh dấu đã công bố để giữ cách hiển thị cũ. Migration đã áp dụng trên database local và Prisma Client đã đọc được dữ liệu.

## Kiểm thử đã chạy

- NestJS build: đạt. Unit: 126/126 đạt; assignment service 19/19 đạt. E2E hiện có: 6/6 đạt. Lint: không có lỗi, còn cảnh báo ở module khác.
- Flutter analyze cho module bài tập: không có vấn đề. 79/79 test Flutter thông thường đạt; test mới kiểm tra lưu nháp và danh sách responsive 393 px, workspace 393/1200 px.
- Suite Flutter đầy đủ gồm các bài stress cũ chưa đạt: khi chạy đồng thời ghi nhận 42 ca thất bại trước khi dừng, chủ yếu do fixture DI thiếu `ApiClient` và một số kỳ vọng route/widget cũ. Hai fake repository đã được cập nhật để biên dịch với interface mới; các ca stress còn lại cần rà soát riêng.

## Giới hạn chưa xác nhận

- Chưa chạy hành trình ghi âm/upload thật trên thiết bị Android có micro, hoặc test HTTP ghi dữ liệu qua toàn chuỗi teacher → student → grade trên database riêng. Các API mới đã có unit test và app E2E khởi động thành công.
- Chưa bổ sung tự lưu theo thời gian và lịch sử nhiều phiên nộp; hiện lưu nháp thủ công và bản nộp vẫn dùng ràng buộc một bản ghi/học viên/bài như schema trước đó.
- Màn teacher tạo bài vẫn xuất bản ngay theo mặc định. Trạng thái nháp/đóng của bài đã có trong API nhưng chưa có nút điều khiển tương ứng ở giao diện teacher.
- Prisma Client đã được tạo lại thành công trên Windows sau khi tạm chuyển DLL cũ để tránh lỗi khóa tệp; truy vấn database bằng client mới đạt.
