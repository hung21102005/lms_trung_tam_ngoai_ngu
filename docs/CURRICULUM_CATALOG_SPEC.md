# EduLMS English Curriculum Catalog — đặc tả v1

Updated: 2026-10-28. Catalog là chương trình **do trung tâm xây dựng**, tham chiếu các khung/định dạng khảo thí; không phải chương trình được đơn vị khảo thí chứng nhận.

## Cấu trúc

`TrainingProgram` (dòng chương trình) → `Course` (khóa cụ thể) → `CourseLevel` (đích/đường học) → `Module` (học phần) → `Lesson` (bài học). Một `Course` có thể mở nhiều `Class`; giáo viên, phòng, học phí và lịch nằm ở `Class`.

Code ổn định, không phụ thuộc tên hiển thị. Publication là `DRAFT → IN_REVIEW → PUBLISHED → ARCHIVED`; `isActive` hiện hữu tiếp tục là trạng thái vận hành, **không thay** quyền công bố. Dữ liệu seed là DRAFT, không tự chuyển PUBLISHED. Version học thuật lưu riêng để bảo toàn khóa/lớp đã mở.

Các trường chuẩn đích tách biệt: `cefrLevel` (Pre-A1/A1…C2), `ieltsTargetBand` (0–9), `toeicTargetScore` (TOEIC L&R), `cambridgeQualification` (Starters/Movers/Flyers/Key…). Không dùng một trường `level` cho mọi thang. Mô tả năng lực, điều kiện đầu vào, kỹ năng, đánh giá và tiêu chí hoàn thành lưu cấu trúc có version, sau đó Admin duyệt.

## Danh mục chương trình và mã

| Code | Chương trình | Khóa học dự kiến |
| --- | --- | --- |
| `PRG-GEN` | General English | Pre-A1, A1, A2, B1, B2, C1, C2 |
| `PRG-IELTS` | IELTS Preparation | Foundation, Pre-IELTS, Target 4.5/5.5/6.5/7.5+, Intensive 6.5, Writing Intensive, Speaking Intensive |
| `PRG-TOEIC` | TOEIC Preparation | Foundation, Target 450/650/850+, Listening/Reading Intensive, Speaking & Writing |
| `PRG-COMM` | English Communication | Beginner/Intermediate/Advanced, Everyday, Pronunciation, Speaking Confidence, Business, Job Interviews, Workplace |
| `PRG-YOUNG` | Young Learners | Pre A1 Starters, A1 Movers, A2 Flyers preparation |
| `PRG-TEEN` | Teen English / Cambridge | A2 Key, B1 Preliminary, B2 First, C1 Advanced, C2 Proficiency preparation; for Schools khi phù hợp |
| `PRG-SKILLS` | Specialized Skills | Pronunciation, Academic Writing/Reading, Listening, Presentation, Interview, English for Work |

Mỗi khóa cần: tên Việt/Anh, đối tượng, entry, outcomes theo kỹ năng, mục tiêu từ vựng/ngữ pháp/giao tiếp, học phần và bài học khác nhau thực chất, đánh giá, tiêu chí hoàn thành, thời lượng **tham khảo** và prerequisite. Không tự tạo học phí chính thức, ngày khai giảng, giáo viên hay tài liệu thương mại.

## Quy tắc học thuật

- **General English:** Pre-A1/A1 ưu tiên tương tác đơn giản; A2 xử lý tình huống quen thuộc; B1 diễn đạt ý kiến và mạch nội dung; B2 lập luận chi tiết; C1/C2 nâng độ chính xác, sắc thái và tổng hợp nguồn. Mỗi khóa ngắn chỉ cam kết nội dung học, không bảo đảm tăng nhiều bậc CEFR.
- **IELTS:** phân biệt Academic/General Training cho Reading/Writing; Listening/Speaking dùng cùng cấu trúc bài thi. Foundation/Pre-IELTS xây nền; Intensive 6.5 đòi hỏi đầu vào phù hợp và không cam kết band đạt được.
- **TOEIC:** L&R là hai kỹ năng tiếp nhận và thang điểm riêng; Speaking & Writing là bài thi riêng. Không dùng band IELTS cho TOEIC.
- **Young Learners:** hoạt động theo lứa tuổi, đánh giá hỗ trợ tiến bộ, không tạo áp lực điểm/band người lớn.
- **Cambridge:** khóa chỉ là preparation, ghi rõ for Schools nếu áp dụng; chứng chỉ do đơn vị khảo thí cấp sau kỳ thi riêng.

## Nguồn tham chiếu chính thức

- [Council of Europe — CEFR và sáu bậc A1–C2](https://www.coe.int/en/web/common-european-framework-reference-languages/introduction-and-context).
- [Cambridge English — lộ trình Young Learners và for Schools](https://www.cambridgeenglish.org/in/exams-and-tests/qualifications/schools/).
- [IELTS — Academic và General Training khác ở Reading/Writing](https://ielts.org/take-a-test/test-types/ielts-general-training-test).
- [ETS — TOEIC Listening & Reading](https://www.ets.org/content/ets-org/ca/en/toeic/test-takers/about/listening-reading.html) và [TOEIC Speaking & Writing](https://www.ets.org/toeic/about/speaking-writing.html).

Các đề cương và seed phải viết nội dung gốc, không sao chép bài thi, sách hoặc tài liệu có bản quyền.

## Seed và duyệt

Import theo code cố định: `create` nếu chưa có, `skip` nếu đã có; không update record do Admin chỉnh, không xóa dữ liệu và không sinh lớp. Chạy `npm run seed:curriculum` trong `backend/` sau khi áp dụng migration. Trên PostgreSQL cục bộ, lần đầu tạo 7 chương trình, 47 khóa, 47 cấp độ, 94 học phần, 188 bài học; lần thứ hai tạo 0 và bỏ qua 7/47 bản ghi đã có. Đây là đề cương bốn bài học mẫu có cấu trúc cho từng khóa, cần biên tập thêm giáo án, tài liệu, hoạt động và tiêu chí đánh giá trước khi công bố. API nội bộ đã hỗ trợ duyệt và công bố có điều kiện; giao diện Admin và kiểm thử qua HTTP vẫn chưa hoàn thành. Admin cần rà soát học thuật trước khi chuyển bản nháp sang công bố.

Màn hình Admin chương trình đã nối API cho danh sách, tạo/sửa và các bước duyệt/công khai. Trong chi tiết chương trình đã có tạo/gắn khóa, biên tập dữ liệu công khai và duyệt khóa qua API hiện có; chi tiết khóa có form sửa cấp độ. Vẫn cần biên tập học phần/bài học, kiểm thử HTTP và rà soát nội dung học thuật trước khi công bố seed nháp.

Checkpoint tiếp theo bổ sung API và form sửa học phần/bài học. Việc tạo học phần/bài học bằng giao diện, bổ sung tài liệu học thuật, rà soát nội dung seed và kiểm thử publication qua HTTP vẫn chưa hoàn tất.
