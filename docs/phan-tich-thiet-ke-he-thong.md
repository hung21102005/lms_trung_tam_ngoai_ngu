# 🏛️ BÁO CÁO PHÂN TÍCH & THIẾT KẾ HỆ THỐNG
## HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ

> **Đề tài:** Xây dựng hệ thống quản lý học tập trực tuyến cho trung tâm ngoại ngữ  
> **Căn cứ tài liệu nghiệp vụ:** [chuc-nang-de-tai.md](file:///c:/Users/Vi-Hung/my_flutter_pj/XD_HT_LMS/lms_trung_tam_ngoai_ngu/docs/chuc-nang-de-tai.md)  
> **Tài liệu yêu cầu người dùng:** [yeu-cau-nguoi-dung.md](file:///c:/Users/Vi-Hung/my_flutter_pj/XD_HT_LMS/lms_trung_tam_ngoai_ngu/docs/yeu-cau-nguoi-dung.md)  
> **Ngày thực hiện:** 26/10/2026  

---

## MỤC LỤC BÁO CÁO THEO 4 TIÊU CHÍ ĐÁNH GIÁ

1. [YÊU CẦU 1: YÊU CẦU NGƯỜI DÙNG (10 ĐIỂM)](#1-yêu-cầu-1-yêu-cầu-người-dùng)
2. [YÊU CẦU 2: MÔ HÌNH HÓA CHỨC NĂNG QUA USE CASE DIAGRAM (15 ĐIỂM)](#2-yêu-cầu-2-mô-hình-hóa-chức-năng-hệ-thống-qua-use-case-diagram)
3. [YÊU CẦU 3: MÔ HÌNH HÓA CẤU TRÚC QUA CLASS DIAGRAM (10 ĐIỂM)](#3-yêu-cầu-3-mô-hình-hóa-cấu-trúc-của-hệ-thống-qua-class-diagram)
4. [YÊU CẦU 4: THIẾT KẾ SƠ ĐỒ CSDL QUAN HỆ TỪ CLASS DIAGRAM (15 ĐIỂM)](#4-yêu-cầu-4-thiết-kế-sơ-đồ-csdl-quan-hệ-từ-class-diagram)

---

## 1. YÊU CẦU 1: YÊU CẦU NGƯỜI DÙNG

*Nội dung chi tiết được lưu trữ và quản lý độc lập tại file:* [yeu-cau-nguoi-dung.md](file:///c:/Users/Vi-Hung/my_flutter_pj/XD_HT_LMS/lms_trung_tam_ngoai_ngu/docs/yeu-cau-nguoi-dung.md)

### 1.1. Các nhóm tác nhân (Actors):
1. **Khách vãng lai (Guest):** Tra cứu thông tin khóa học, địa chỉ chi nhánh, gửi form đăng ký tư vấn học tập.
2. **Học viên (Student):** Đăng nhập tài khoản được cấp, kích hoạt đổi mật khẩu lần đầu, theo dõi thời khóa biểu, nộp bài tập (văn bản/PDF/file ghi âm Speaking), làm bài thi online, theo dõi điểm danh và thanh toán học phí qua VNPay.
3. **Phụ huynh (Parent):** Theo dõi lịch học, kết quả bài tập, điểm thi của con; nhận thông báo tức thời khi con vắng học; theo dõi hóa đơn và thanh toán học phí cho con.
4. **Giáo viên (Teacher):** Xem lịch dạy; điểm danh tại lớp trên ứng dụng; giao bài tập về nhà; nghe bài ghi âm nói và chấm điểm/nhận xét; ra đề thi; chấm điểm bài thi tự luận.
5. **Thu ngân / Kế toán (Cashier):** Quản lý hóa đơn học phí; thu tiền mặt/chuyển khoản tại quầy; xuất phiếu thu PDF có mã QR; đóng học phí theo đợt (trả góp); xử lý hoàn tiền/bảo lưu; theo dõi công nợ quá hạn và xem báo cáo dòng tiền.
6. **Nhân viên Học vụ / Tuyển sinh (Academic Staff):** Tiếp nhận và chăm sóc Lead tư vấn; hẹn lịch kiểm tra đầu vào (Placement Test); chuyển đổi Lead thành học viên chính thức; quản lý lớp học và tự động sinh lịch học; kiểm tra phòng trống; duyệt học bù.
7. **Quản trị viên (Admin):** Quản lý toàn bộ người dùng, phân quyền vai trò (RBAC), quản lý chi nhánh và phòng học, quản lý danh mục khóa học, khóa/mở tài khoản, reset mật khẩu, xem dashboard điều hành và toàn bộ báo cáo doanh thu/học vụ.

---

## 2. YÊU CẦU 2: MÔ HÌNH HÓA CHỨC NĂNG HỆ THỐNG QUA USE CASE DIAGRAM

### 2.1. Sơ đồ Use Case tổng thể toàn hệ thống

![Sơ đồ Use Case tổng thể toàn hệ thống](usecase_diagram_tong_the.png)

### 2.2. Các sơ đồ Use Case phân hệ chi tiết

#### a. Phân hệ Tuyển sinh, Xác thực & Quản trị Người dùng
![Sơ đồ Use Case Tuyển sinh & Người dùng](usecase_subsystem_tuyen_sinh_nguoi_dung.png)

#### b. Phân hệ Đào tạo, Lớp học, Điểm danh & Bài tập
![Sơ đồ Use Case Đào tạo & Lớp học](usecase_subsystem_dao_tao_lop_hoc.png)

#### c. Phân hệ Khảo thí & Học phí - Tài chính
![Sơ đồ Use Case Thi cử & Tài chính](usecase_subsystem_thi_cu_tai_chinh.png)

### 2.3. Bảng đặc tả Use Case tiêu biểu (Use Case Specifications)

#### Đặc tả UC-01: Đăng nhập hệ thống (Login)
- **Actor chính:** Tất cả người dùng (Học viên, Phụ huynh, Giáo viên, Thu ngân, Học vụ, Admin).
- **Tiền điều kiện:** Tài khoản đã được trung tâm khởi tạo và kích hoạt trong hệ thống (`status != LOCKED`).
- **Luồng chính (Main Flow):**
  1. Người dùng nhập Mã tài khoản/Email/SĐT và mật khẩu.
  2. Hệ thống kiểm tra thông tin đăng nhập trong bảng `users`.
  3. Hệ thống kiểm tra mật khẩu băm bằng Bcrypt.
  4. Nếu cờ `isFirstLogin = true`, hệ thống chuyển hướng người dùng sang màn hình bắt buộc đổi mật khẩu mới (*extend* `UC_FirstLogin`).
  5. Nếu `isFirstLogin = false`, hệ thống phát hành JWT Access Token (15 phút) và Refresh Token (7 ngày).
  6. Ứng dụng lưu token vào Secure Storage và chuyển người dùng đến giao diện tương ứng theo vai trò RBAC.
- **Luồng ngoại lệ (Alternative Flow):**
  - Nhập sai mật khẩu quá 5 lần: Khóa tài khoản tạm thời 15 phút để chống tấn công brute-force.
  - Tài khoản đang bị khóa (`LOCKED`): Hiển thị thông báo "Tài khoản của bạn đã bị khóa, vui lòng liên hệ trung tâm".
- **Hậu điều kiện:** Người dùng có phiên làm việc hợp lệ và truy cập các chức năng theo đúng vai trò.

#### Đặc tả UC-14: Điểm danh buổi học trên ứng dụng di động (Attendance)
- **Actor chính:** Giáo viên.
- **Tiền điều kiện:** Giáo viên đã đăng nhập; buổi học (`class_sessions`) đang diễn ra hoặc đã đến ngày học.
- **Luồng chính (Main Flow):**
  1. Giáo viên mở màn hình điểm danh buổi học trên app.
  2. Hệ thống tải danh sách học viên đang theo học trong lớp (`enrollments`).
  3. Mặc định trạng thái có thể bấm "Có mặt tất cả" để tiết kiệm thời gian.
  4. Giáo viên tích chọn trạng thái từng học viên: Có mặt (`PRESENT`), Vắng không phép (`ABSENT`), Vắng có phép (`EXCUSED`), Đi muộn (`LATE`).
  5. Giáo viên bấm "Hoàn tất điểm danh".
  6. Hệ thống lưu các bản ghi vào bảng `attendance_records` và cập nhật buổi học sang trạng thái `COMPLETED`.
  7. Nếu có học viên vắng (`ABSENT`), hệ thống kích hoạt sự kiện nền (*extend* `UC_NotifyAbsent`) để gửi push notification tức thì qua FCM về điện thoại của phụ huynh.
- **Hậu điều kiện:** Dữ liệu chuyên cần được ghi nhận, tỷ lệ chuyên cần của lớp được cập nhật tự động.

#### Đặc tả UC-25: Ghi nhận thanh toán tại quầy (Record Payment)
- **Actor chính:** Thu ngân.
- **Tiền điều kiện:** Thu ngân đã đăng nhập Web Admin Portal; hóa đơn học phí của học viên đang ở trạng thái `PENDING`, `PARTIALLY_PAID` hoặc `OVERDUE`.
- **Luồng chính (Main Flow):**
  1. Thu ngân tìm kiếm hóa đơn theo mã học viên, họ tên hoặc mã hóa đơn.
  2. Hệ thống hiển thị chi tiết hóa đơn: số tiền gốc, số tiền đã giảm trừ, số tiền đã đóng, công nợ còn lại.
  3. Thu ngân bấm nút "Thu tiền tại quầy".
  4. Nhập số tiền thực thu, chọn hình thức thanh toán (Tiền mặt / Chuyển khoản ngân hàng / Quẹt thẻ POS) và nhập ghi chú/mã giao dịch.
  5. Bấm "Xác nhận thu tiền".
  6. Hệ thống thực thi Database Transaction: tạo bản ghi `payment_receipts`, cộng dồn `paid_amount` trong bảng `invoices`.
  7. Nếu `paid_amount >= final_amount`, cập nhật trạng thái hóa đơn sang `PAID`; nếu đóng một phần thì chuyển sang `PARTIALLY_PAID`.
  8. Hệ thống tự động sinh và hiển thị nút "Xuất phiếu thu PDF" (*include* `UC_PrintReceipt`) để in cho học viên.
- **Hậu điều kiện:** Hóa đơn được gạch nợ, doanh thu được ghi nhận vào báo cáo tài chính ngày.

---

## 3. YÊU CẦU 3: MÔ HÌNH HÓA CẤU TRÚC CỦA HỆ THỐNG QUA CLASS DIAGRAM

### 3.1. Sơ đồ Class Diagram tổng thể

![Sơ đồ Class Diagram](class_diagram.png)

### 3.2. Bảng mô tả các Lớp thực thể (Class Dictionary)

| Nhóm nghiệp vụ | Tên Lớp (Class) | Trách nhiệm chính trong hệ thống | Thuộc tính chính | Phương thức chính |
|:---|:---|:---|:---|:---|
| **Cơ sở vật chất & Đào tạo** | `Branch` | Quản lý thông tin chi nhánh trung tâm | `id, code, name, address, phone, isActive` | `createRoom()` |
| | `Room` | Quản lý phòng học thuộc chi nhánh | `id, branchId, code, name, capacity, equipment` | `checkAvailability()` |
| | `Course` | Quản lý danh mục khóa học đào tạo | `id, code, title, language, totalSessions, standardTuition` | `addLevel()` |
| | `CourseLevel` | Quản lý các cấp độ học (A1, A2, B1...) | `id, courseId, levelCode, title, orderIndex` | `getLessons()` |
| | `Lesson` | Quản lý nội dung bài học cụ thể | `id, levelId, title, orderIndex, description` | `addMaterial()` |
| | `LessonMaterial` | Quản lý tài liệu học tập đa phương tiện | `id, lessonId, title, fileType, fileUrl` | `downloadFile()` |
| **Người dùng & Phân quyền** | `User` *(Abstract)* | Thực thể người dùng nền tảng | `id, userCode, email, phone, passwordHash, status, isFirstLogin` | `verifyPassword()`, `changePassword()` |
| | `Role` | Quản lý vai trò bảo mật RBAC | `id, name, description` | `assignPermission()` |
| | `StudentProfile` | Hồ sơ chuyên biệt của học viên | `id, userId, studentCode, dateOfBirth, gender` | `getEnrollments()` |
| | `TeacherProfile` | Hồ sơ chuyên môn của giáo viên | `id, userId, teacherCode, certificates, hourlyRate` | `getTeachingSchedule()` |
| | `AdmissionLead` | Hồ sơ khách đăng ký tư vấn tuyển sinh | `id, fullName, phone, email, status, targetCourseId` | `convertToStudent()` |
| **Vận hành Lớp học** | `Class` | Quản lý lớp học cụ thể | `id, classCode, name, courseId, branchId, roomId, teacherId, status, maxStudents` | `generateSessions()`, `enrollStudent()` |
| | `ClassSession` | Quản lý từng buổi học thực tế | `id, classId, roomId, teacherId, sessionNumber, sessionDate, startTime, endTime` | `markAttendance()` |
| | `Enrollment` | Quản lý việc ghi danh của học viên vào lớp | `id, classId, studentId, enrolledAt, status` | `transferClass()`, `dropClass()` |
| | `AttendanceRecord` | Bản ghi trạng thái điểm danh học viên | `id, sessionId, studentId, status, note` | `updateStatus()` |
| | `MakeupRequest` | Đơn đăng ký học bù của học viên | `id, studentId, originalSessionId, targetSessionId, status` | `approve()`, `reject()` |
| **Khảo thí & Bài tập** | `Assignment` | Quản lý bài tập về nhà được giao | `id, classId, title, type, deadline, maxScore` | `closeAssignment()` |
| | `AssignmentSubmission` | Bài làm do học viên nộp | `id, assignmentId, studentId, attachmentUrl, audioRecordingUrl, score, feedback` | `grade()` |
| | `Exam` | Quản lý kỳ thi/đề thi trực tuyến | `id, classId, title, durationMinutes, passScore, status` | `publishExam()` |
| | `Question` | Ngân hàng câu hỏi đa dạng kỹ năng | `id, type, promptText, mediaUrl, options, correctAnswer` | `validateAnswer()` |
| | `ExamQuestion` | Câu hỏi được chọn trong đề thi | `id, examId, questionId, orderIndex, points` | `calculatePoints()` |
| | `ExamAttempt` | Lượt làm bài thi của học viên | `id, examId, studentId, startedAt, submittedAt, totalScore, status` | `autoGrade()` |
| **Tài chính & Học phí** | `Invoice` | Hóa đơn học phí học viên | `id, invoiceCode, studentId, classId, originalAmount, discountAmount, finalAmount, paidAmount, dueDate, status` | `recordPayment()`, `checkOverdue()` |
| | `PaymentReceipt` | Biên lai/Phiếu thu tiền mặt hoặc online | `id, invoiceId, receiptCode, amount, method, transactionRef, status, paidAt` | `generatePdfReceipt()` |

---

## 4. YÊU CẦU 4: THIẾT KẾ SƠ ĐỒ CSDL QUAN HỆ TỪ CLASS DIAGRAM

### 4.1. Sơ đồ CSDL quan hệ vật lý (Physical Relational Database Schema / ERD)

![Sơ đồ CSDL quan hệ vật lý](relational_database_schema.png)

### 4.2. Quy tắc ánh xạ từ Class Diagram sang CSDL quan hệ

1. **Ánh xạ Kế thừa (Inheritance Mapping):**  
   Áp dụng chiến lược **Table-per-Type (TPT)**. Bảng cha `users` lưu trữ toàn bộ thông tin đăng nhập, xác thực và trạng thái hoạt động chung. Các bảng con `student_profiles` và `teacher_profiles` lưu trữ thông tin nghiệp vụ đặc thù, liên kết với `users.id` qua quan hệ $1:1$ với ràng buộc `UNIQUE` và khóa ngoại `ON DELETE CASCADE`.
2. **Ánh xạ Quan hệ Hợp thành (Composition):**  
   - `Class` *-- `ClassSession`: Bảng `class_sessions` có cột `class_id` [FK] tham chiếu `classes.id` với ràng buộc `ON DELETE CASCADE`.
   - `Exam` *-- `ExamQuestion`: Bảng `exam_questions` có cột `exam_id` [FK] tham chiếu `exams.id` với `ON DELETE CASCADE`.
   - `Invoice` *-- `PaymentReceipt`: Bảng `payment_receipts` có cột `invoice_id` [FK] tham chiếu `invoices.id`.
3. **Ánh xạ Quan hệ Thu nạp (Aggregation) & Kết hợp (Association):**  
   - `Branch` o-- `Room`: `rooms.branch_id` [FK $\rightarrow$ `branches.id`].
   - `Course` o-- `Class`: `classes.course_id` [FK $\rightarrow$ `courses.id`].
   - `Class` o-- `Assignment`: `assignments.class_id` [FK $\rightarrow$ `classes.id`].
4. **Ánh xạ Quan hệ Nhiều - Nhiều ($N-N$):**  
   - Bảng `user_roles` làm bảng nối giữa `users` và `roles` (Khóa chính phức hợp: `[user_id, role_id]`).
   - Bảng `enrollments` làm bảng nối ghi danh giữa `classes` và `users` (học viên).
   - Bảng `parent_students` làm bảng nối liên kết giữa phụ huynh và các con.

### 4.3. Từ điển dữ liệu chi tiết các bảng trọng yếu (Data Dictionary)

#### 1. Bảng `branches` (Chi nhánh trung tâm)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính duy nhất của chi nhánh |
| `code` | VARCHAR(30) | NOT NULL, UNIQUE | Mã chi nhánh (ví dụ: `BR-Q1`, `BR-BT`) |
| `name` | VARCHAR(255) | NOT NULL | Tên cơ sở chi nhánh |
| `address` | TEXT | NOT NULL | Địa chỉ chi nhánh |
| `phone` | VARCHAR(20) | NULL | Số hotline chi nhánh |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT true | Trạng thái hoạt động |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Thời điểm tạo |

#### 2. Bảng `rooms` (Phòng học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính phòng học |
| `branch_id` | UUID | NOT NULL, FK $\rightarrow$ branches(id) | Thuộc chi nhánh nào |
| `code` | VARCHAR(30) | NOT NULL | Mã phòng (P101, LAB-02) |
| `name` | VARCHAR(100) | NOT NULL | Tên phòng học |
| `capacity` | INT | NOT NULL, DEFAULT 25 | Sức chứa học viên tối đa |
| `equipment` | TEXT | NULL | Danh sách trang thiết bị |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT true | Sẵn sàng sử dụng |

#### 3. Bảng `users` (Tài khoản người dùng tập trung)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính tài khoản |
| `user_code` | VARCHAR(50) | NOT NULL, UNIQUE | Mã định danh duy nhất (HV-2026-001, GV-001) |
| `email` | VARCHAR(255) | NULL, UNIQUE | Email liên lạc và đăng nhập |
| `phone` | VARCHAR(20) | NULL, UNIQUE | Số điện thoại nhận OTP và liên lạc |
| `password_hash` | VARCHAR(255) | NOT NULL | Mật khẩu mã hóa Bcrypt (Salt rounds = 12) |
| `full_name` | VARCHAR(150) | NOT NULL | Họ và tên đầy đủ |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'PENDING_ACTIVATION' | Trạng thái tài khoản |
| `is_first_login` | BOOLEAN | NOT NULL, DEFAULT true | Cờ bắt buộc đổi mật khẩu lần đầu |
| `branch_id` | UUID | NULL, FK $\rightarrow$ branches(id) | Chi nhánh trực thuộc (cho nhân sự) |

#### 4. Bảng `classes` (Lớp học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính lớp học |
| `class_code` | VARCHAR(50) | NOT NULL, UNIQUE | Mã lớp học (IELTS-2026-A1) |
| `name` | VARCHAR(255) | NOT NULL | Tên lớp học hiển thị |
| `course_id` | UUID | NOT NULL, FK $\rightarrow$ courses(id) | Khóa học đào tạo |
| `branch_id` | UUID | NOT NULL, FK $\rightarrow$ branches(id) | Chi nhánh tổ chức |
| `primary_room_id` | UUID | NOT NULL, FK $\rightarrow$ rooms(id) | Phòng học cố định |
| `teacher_id` | UUID | NOT NULL, FK $\rightarrow$ users(id) | Giáo viên chủ nhiệm phụ trách |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'PLANNING' | Trạng thái vòng đời lớp học |
| `max_students` | INT | NOT NULL, DEFAULT 20 | Sĩ số học viên tối đa |
| `start_date` | DATE | NOT NULL | Ngày chính thức khai giảng |

#### 5. Bảng `class_sessions` (Danh sách các buổi học)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính buổi học |
| `class_id` | UUID | NOT NULL, FK $\rightarrow$ classes(id) ON DELETE CASCADE | Thuộc lớp học nào |
| `room_id` | UUID | NOT NULL, FK $\rightarrow$ rooms(id) | Phòng diễn ra buổi học |
| `teacher_id` | UUID | NOT NULL, FK $\rightarrow$ users(id) | Giáo viên đứng lớp |
| `session_number` | INT | NOT NULL | Buổi thứ mấy trong khóa (1, 2, 3...) |
| `session_date` | DATE | NOT NULL | Ngày diễn ra buổi học |
| `start_time` | TIME | NOT NULL | Giờ bắt đầu (ví dụ: 18:00) |
| `end_time` | TIME | NOT NULL | Giờ kết thúc (ví dụ: 19:30) |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'SCHEDULED' | Trạng thái buổi học |

#### 6. Bảng `attendance_records` (Sổ điểm danh)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính bản ghi điểm danh |
| `session_id` | UUID | NOT NULL, FK $\rightarrow$ class_sessions(id) | Điểm danh cho buổi học nào |
| `student_id` | UUID | NOT NULL, FK $\rightarrow$ users(id) | Học viên được điểm danh |
| `status` | VARCHAR(20) | NOT NULL | Trạng thái: PRESENT, ABSENT, LATE, EXCUSED |
| `note` | TEXT | NULL | Ghi chú của giáo viên |

#### 7. Bảng `invoices` (Hóa đơn học phí)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính hóa đơn |
| `invoice_code` | VARCHAR(50) | NOT NULL, UNIQUE | Mã hóa đơn chuẩn (INV-2026-10-001) |
| `student_id` | UUID | NOT NULL, FK $\rightarrow$ users(id) | Học viên nộp học phí |
| `class_id` | UUID | NOT NULL, FK $\rightarrow$ classes(id) | Học phí cho lớp học nào |
| `original_amount` | DECIMAL(12,2) | NOT NULL | Học phí niêm yết ban đầu |
| `discount_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Số tiền được giảm giá / khuyến mãi |
| `final_amount` | DECIMAL(12,2) | NOT NULL | Số tiền thực tế phải nộp |
| `paid_amount` | DECIMAL(12,2) | NOT NULL, DEFAULT 0 | Số tiền đã thanh toán lũy kế |
| `due_date` | DATE | NOT NULL | Hạn chót thanh toán học phí |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'PENDING' | Trạng thái hóa đơn |

#### 8. Bảng `payment_receipts` (Phiếu thu / Biên lai thanh toán)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Mô tả nghiệp vụ |
|:---|:---|:---|:---|
| `id` | UUID | PK, DEFAULT uuid_generate_v4() | Khóa chính phiếu thu |
| `invoice_id` | UUID | NOT NULL, FK $\rightarrow$ invoices(id) | Thu tiền cho hóa đơn nào |
| `receipt_code` | VARCHAR(50) | NOT NULL, UNIQUE | Mã phiếu thu (REC-2026-10-001) |
| `amount` | DECIMAL(12,2) | NOT NULL | Số tiền thu trong đợt này |
| `method` | VARCHAR(30) | NOT NULL | CASH, BANK_TRANSFER, VNPAY, MOMO |
| `transaction_ref` | VARCHAR(100) | NULL | Mã giao dịch ngân hàng / cổng thanh toán |
| `status` | VARCHAR(30) | NOT NULL, DEFAULT 'SUCCESS' | Trạng thái giao dịch |
| `paid_at` | TIMESTAMP | NOT NULL, DEFAULT NOW() | Thời điểm giao dịch thành công |
