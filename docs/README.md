# Mục lục tài liệu EduLMS

> Kiểm kê theo cây `docs/` ngày 30/10/2026. Đây là đề xuất tổ chức; chưa xóa, di chuyển hoặc sửa tài liệu cũ. Một số tài liệu và ảnh đang **chưa commit**; kiểm tra `git status` trước khi bàn giao nhóm.

## Bắt đầu ở đây

1. [Hướng dẫn cài đặt và chạy dự án](HUONG_DAN_CAI_DAT_VA_CHAY_DU_AN.md).
2. [Kịch bản demo và báo cáo](KICH_BAN_DEMO_VA_BAO_CAO.md).
3. [README gốc](../README.md) để đọc giới thiệu; phần công nghệ/port phải đối chiếu hướng dẫn mới và source.

## Tài liệu nền và tiến độ

| Tệp | Nội dung/nhóm | Phân loại | Đề xuất và lý do |
|---|---|---|---|
| [kien-truc-phan-mem.md](kien-truc-phan-mem.md) | Kiến trúc tổng thể | KEEP | Dùng khi trình bày; đối chiếu khẳng định dịch vụ với source |
| [phan-tich-thiet-ke-he-thong.md](phan-tich-thiet-ke-he-thong.md) | Phân tích thiết kế | KEEP | Dùng trong báo cáo môn học |
| [yeu-cau-nguoi-dung.md](yeu-cau-nguoi-dung.md) | Yêu cầu | KEEP | Nguồn nghiệp vụ để đối chiếu chức năng đã triển khai |
| [chuc-nang-de-tai.md](chuc-nang-de-tai.md) | Danh sách chức năng | REVIEW | Mục tiêu có thể khác trạng thái chạy thực tế |
| [Task1_Logical_View.md](Task1_Logical_View.md), [Task2_Process_View.md](Task2_Process_View.md), [Task3_Implementation_View.md](Task3_Implementation_View.md), [Task4_Deployment_View.md](Task4_Deployment_View.md) | Bốn góc nhìn kiến trúc | KEEP | Bộ nguồn cho phần kiến trúc đồ án |
| [CURRICULUM_CATALOG_SPEC.md](CURRICULUM_CATALOG_SPEC.md) | Đặc tả chương trình/khóa | KEEP | Đối chiếu schema và dữ liệu học thuật |
| [PUBLIC_ADMISSIONS_PLAN.md](PUBLIC_ADMISSIONS_PLAN.md) | Tiến độ website/tuyển sinh | REVIEW | File đang có thay đổi chưa commit; không dùng làm bằng chứng hoàn tất |
| [ADAPTIVE_UI_PLAN.md](ADAPTIVE_UI_PLAN.md) | Tiến độ giao diện đa kích thước | REVIEW | Có checkpoint lịch sử, cần so với UI hiện tại |
| [teacher-portal-progress.md](teacher-portal-progress.md), [student-assignments-progress.md](student-assignments-progress.md) | Tiến độ từng vai trò | ARCHIVE | Hữu ích để truy vết; tránh nhầm với trạng thái cuối |
| [admin-functional-audit.md](admin-functional-audit.md), [bao-cao-tien-do-luong-hoc-tap.md](bao-cao-tien-do-luong-hoc-tap.md) | Audit và tiến độ | REVIEW | Đối chiếu với code/test trước khi trích báo cáo |
| [ACADEMIC_AUDIT_REPORT_47_COURSES.md](ACADEMIC_AUDIT_REPORT_47_COURSES.md) | Kiểm định học thuật | REVIEW | Chưa commit; cần người phụ trách học thuật xác nhận |
| [P0_INCIDENT_RECOVERY.md](P0_INCIDENT_RECOVERY.md) | Nhật ký sự cố | ARCHIVE | Giữ để truy vết, không dùng như hướng dẫn cài đặt |
| [TESTING_RULES.md](TESTING_RULES.md) | Quy tắc kiểm thử | REVIEW | Chưa commit; xác nhận với nhóm trước khi dùng |
| [env-check.md](env-check.md), [huong-dan-tao-tai-khoan-dich-vu.md](huong-dan-tao-tai-khoan-dich-vu.md) | Môi trường/dịch vụ ngoài | REVIEW | Tránh công bố credential; so với `.env.example` hiện tại |
| [plan.md](plan.md), [checklist.md](checklist.md) | Kế hoạch gốc | ARCHIVE | Giữ lịch sử, dùng README này để điều hướng bản bàn giao |

`docs/kientructhietkephanmem/` chứa bản DOCX của bốn Task và kiến trúc; `docs/phantichthietkehethong/` chứa DOCX yêu cầu và hình use case/class/schema. Chọn một bản đã được nhóm duyệt cho báo cáo; các bản Markdown có thể tiện review hơn, DOCX có thể là bản nộp chính thức. Không tự xóa bản nào.

## Hình và sơ đồ

| Nhóm | Tệp điển hình | Phân loại | Ghi chú |
|---|---|---|---|
| Kiến trúc | [client-server](diagrams/diagram1_client_server.png), [layered](diagrams/diagram2_layered.png), [event-driven](diagrams/diagram3_event_driven.png), [pipe-filter](diagrams/diagram4_pipe_filter.png) | KEEP | Kiểm tra đúng với bản vẽ báo cáo |
| Database | [ERD](diagrams/erd_database.png), [schema quan hệ](diagrams/relational_database_schema.png), `erd_database.png` | REVIEW | Có bản sao ở root docs và `diagrams/`; đối chiếu schema Prisma trước khi chọn |
| Sequence | [đăng nhập](diagrams/sequence_01_login_first_time.png), [xếp lịch](diagrams/sequence_02_class_scheduling.png), [điểm danh](diagrams/sequence_03_attendance_fcm_notification.png), [bài nói](diagrams/sequence_04_speaking_assignment_submission.png), [thi](diagrams/sequence_05_online_exam_autosubmit.png), [học phí](diagrams/sequence_06_tuition_payment_vnpay.png) | REVIEW | Có bản sao root docs và `diagrams/`; xác minh FCM/VNPay trước khi mô tả là hoạt động |
| Use case/class | `diagrams/usecase_*`, `diagrams/class_diagram.png`, `phantichthietkehethong/*.png` | KEEP/REVIEW | Chọn bản khớp tài liệu phân tích |
| Hình Task | `diagrams_generated/*.png` | REVIEW | Ảnh sinh cho bốn góc nhìn; xác nhận hình nào được tham chiếu trong DOCX |

## Việc dọn dẹp sau khi nhóm duyệt

- So sánh hash/nội dung giữa ảnh root docs và `diagrams/` trước khi chọn bản chính; **chưa xóa** bản lặp. Kiểm tra `docs/~$sk1_Logical_View.docx`: tên cho thấy có thể là file khóa tạm của Word, nhưng cần kiểm tra người đang mở trước khi đưa vào danh sách REMOVE CANDIDATE.
- Rà lại liên kết trong README gốc, các Markdown và DOCX. README gốc mô tả một số dịch vụ như Firebase/VNPay/queue là khả dụng; source có package/cấu hình nhưng demo thực tế còn cần credential và kiểm thử. Không suy ra tính năng hoàn thiện chỉ từ sơ đồ hay kế hoạch.
- Rà các file có đường dẫn Windows tuyệt đối, URL nội bộ, email, mật khẩu mẫu, token và service account trước khi chia sẻ. `backend/prisma/seed.ts` có mật khẩu mẫu dạng literal; không đưa mật khẩu vào tài liệu bàn giao. `docs/huong-dan-tao-tai-khoan-dich-vu.md` và `env-check.md` cần review bảo mật trước khi công khai.
- Các tệp ảnh `docs/diagrams/erd_database.png`, một số `sequence_*.png` và tài liệu audit hiện chưa commit trong workspace. Chỉ thêm Git sau khi người phụ trách xác nhận phiên bản; nhiệm vụ handoff này không commit.

Phân loại ARCHIVE/REVIEW là **đề xuất**, không phải quyết định xóa. Nguồn vận hành cần ưu tiên là [schema Prisma](../backend/prisma/schema.prisma), [Compose](../docker-compose.yml), [backend package](../backend/package.json) và [Flutter package](../pubspec.yaml).
