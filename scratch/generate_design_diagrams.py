import urllib.request
import json
import os
import time

os.makedirs("docs", exist_ok=True)
os.makedirs("docs/diagrams", exist_ok=True)

def render_plantuml(puml_code, output_paths):
    data = json.dumps({
        'diagram_source': puml_code,
        'diagram_type': 'plantuml',
        'output_format': 'png'
    }).encode('utf-8')
    req = urllib.request.Request(
        'https://kroki.io',
        data=data,
        headers={'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'}
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as r:
            content = r.read()
            for path in output_paths:
                with open(path, 'wb') as f:
                    f.write(content)
                print(f"Successfully generated: {path} ({len(content)} bytes)")
    except Exception as e:
        print(f"Error rendering {output_paths}: {e}")
    time.sleep(1)

# ==============================================================================
# 1. SƠ ĐỒ USE CASE TỔNG THỂ HỆ THỐNG
# ==============================================================================
puml_usecase_overall = """@startuml
skinparam packageStyle rectangle
skinparam shadowing false
skinparam roundcorner 8
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 11
skinparam actorFontSize 12
skinparam actorFontStyle bold
skinparam usecaseFontSize 11

skinparam rectangle {
    BackgroundColor #F8F9FA
    BorderColor #2C3E50
    BorderThickness 1.5
}
skinparam usecase {
    BackgroundColor #FFFFFF
    BorderColor #2980B9
    BorderThickness 1.2
}
skinparam actor {
    BackgroundColor #EBF5FB
    BorderColor #1A5276
}
skinparam arrow {
    Color #2C3E50
    Thickness 1.1
}

left to right direction

actor "Khách vãng lai\\n(Guest)" as Guest #FFF2E6
actor "Học viên\\n(Student)" as Student #E8F8F5
actor "Phụ huynh\\n(Parent)" as Parent #FEF9E7
actor "Giáo viên\\n(Teacher)" as Teacher #EAF2F8
actor "Thu ngân\\n(Cashier)" as Cashier #FDEDEC
actor "Nhân viên Học vụ\\n(Academic Staff)" as Academic #F4ECF7
actor "Quản trị viên\\n(Admin)" as Admin #EAEDED

rectangle "HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ" {

    package "1. Xác thực & Hồ sơ cá nhân" {
        usecase "UC01: Đăng nhập hệ thống" as UC01
        usecase "UC02: Kích hoạt & Đổi mật khẩu lần đầu" as UC02
        usecase "UC03: Quản lý hồ sơ cá nhân" as UC03
        usecase "UC04: Quên & Đặt lại mật khẩu" as UC04
    }

    package "2. Tuyển sinh & Người dùng" {
        usecase "UC05: Xem danh mục khóa học & chi nhánh" as UC05
        usecase "UC06: Gửi đăng ký nhu cầu học tập (Lead)" as UC06
        usecase "UC07: Tiếp nhận & Chăm sóc Lead" as UC07
        usecase "UC08: Quản lý người dùng & Cấp tài khoản" as UC08
        usecase "UC09: Quản lý chi nhánh & phòng học" as UC09
    }

    package "3. Đào tạo & Quản lý Lớp học" {
        usecase "UC10: Quản lý khóa học & bài học" as UC10
        usecase "UC11: Quản lý lớp & Tự động sinh lịch" as UC11
        usecase "UC12: Ghi danh & Phân bổ học viên" as UC12
        usecase "UC13: Xem thời khóa biểu cá nhân" as UC13
    }

    package "4. Học tập, Điểm danh & Bài tập" {
        usecase "UC14: Điểm danh buổi học & Chuyên cần" as UC14
        usecase "UC15: Đăng ký & Duyệt học bù" as UC15
        usecase "UC16: Giao bài tập về nhà" as UC16
        usecase "UC17: Nộp bài tập & Ghi âm bài nói (Audio)" as UC17
        usecase "UC18: Chấm điểm & Nhận xét phát âm" as UC18
        usecase "UC19: Xem kết quả học tập & Nhận xét" as UC19
    }

    package "5. Thi & Khảo thí trực tuyến" {
        usecase "UC20: Quản lý ngân hàng câu hỏi" as UC20
        usecase "UC21: Tạo & Cấu hình đề thi" as UC21
        usecase "UC22: Làm bài thi trực tuyến" as UC22
        usecase "UC23: Tự động chấm & Chấm tự luận" as UC23
    }

    package "6. Học phí & Tài chính" {
        usecase "UC24: Quản lý hóa đơn học phí" as UC24
        usecase "UC25: Ghi nhận thanh toán tại quầy" as UC25
        usecase "UC26: Thanh toán học phí trực tuyến (VNPay)" as UC26
        usecase "UC27: Quản lý công nợ & Nhắc nợ" as UC27
        usecase "UC28: Xử lý hoàn tiền & Bảo lưu" as UC28
        usecase "UC29: Xuất phiếu thu & Hóa đơn PDF" as UC29
    }

    package "7. Báo cáo & Thống kê" {
        usecase "UC30: Xem báo cáo doanh thu & Dòng tiền" as UC30
        usecase "UC31: Báo cáo chuyên cần & Điểm số" as UC31
        usecase "UC32: Thống kê giờ dạy giáo viên" as UC32
    }
}

' Khach vang lai
Guest --> UC05
Guest --> UC06

' Hoc vien
Student --> UC01
Student --> UC02
Student --> UC03
Student --> UC04
Student --> UC13
Student --> UC15
Student --> UC17
Student --> UC19
Student --> UC22
Student --> UC26

' Phu huynh
Parent --> UC01
Parent --> UC02
Parent --> UC03
Parent --> UC13
Parent --> UC19
Parent --> UC26

' Giao vien
Teacher --> UC01
Teacher --> UC03
Teacher --> UC13
Teacher --> UC14
Teacher --> UC16
Teacher --> UC18
Teacher --> UC20
Teacher --> UC21
Teacher --> UC23

' Thu ngan
Cashier --> UC01
Cashier --> UC03
Cashier --> UC24
Cashier --> UC25
Cashier --> UC27
Cashier --> UC28
Cashier --> UC29
Cashier --> UC30

' Hoc vu
Academic --> UC01
Academic --> UC03
Academic --> UC07
Academic --> UC08
Academic --> UC09
Academic --> UC10
Academic --> UC11
Academic --> UC12
Academic --> UC14
Academic --> UC15
Academic --> UC31

' Admin
Admin --> UC01
Admin --> UC08
Admin --> UC09
Admin --> UC10
Admin --> UC11
Admin --> UC24
Admin --> UC27
Admin --> UC30
Admin --> UC31
Admin --> UC32

@enduml
"""

# ==============================================================================
# 2. SƠ ĐỒ USE CASE PHÂN HỆ: TUYỂN SINH, XÁC THỰC & QUẢN TRỊ NGƯỜI DÙNG
# ==============================================================================
puml_usecase_admissions = """@startuml
skinparam packageStyle rectangle
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 11
skinparam actorFontSize 12
skinparam actorFontStyle bold

skinparam rectangle {
    BackgroundColor #F8F9FA
    BorderColor #2C3E50
}
skinparam usecase {
    BackgroundColor #FFFFFF
    BorderColor #2980B9
}

left to right direction

actor "Khách vãng lai" as Guest #FFF2E6
actor "Người dùng chung" as CommonUser #EBF5FB
actor "Nhân viên Học vụ" as Academic #F4ECF7
actor "Quản trị viên" as Admin #EAEDED

rectangle "Phân hệ Tuyển sinh, Xác thực & Quản trị Người dùng" {
    usecase "Gửi form đăng ký tư vấn" as UC_SubmitLead
    usecase "Tra cứu khóa học & chi nhánh" as UC_PublicView
    
    usecase "Đăng nhập hệ thống" as UC_Login
    usecase "Xác thực JWT Token" as UC_AuthToken
    usecase "Kích hoạt & Đổi mật khẩu lần đầu" as UC_FirstLogin
    usecase "Đặt lại mật khẩu qua OTP" as UC_ForgotPass
    
    usecase "Tiếp nhận & Cập nhật trạng thái Lead" as UC_ManageLead
    usecase "Hẹn lịch kiểm tra đầu vào (Placement Test)" as UC_ScheduleTest
    usecase "Chuyển đổi Lead thành Học viên chính thức" as UC_ConvertLead
    
    usecase "Tạo & Cấp phát tài khoản Học viên" as UC_CreateStudent
    usecase "Tạo & Cấp phát tài khoản Phụ huynh" as UC_CreateParent
    usecase "Tạo tài khoản Nhân sự (GV / NV)" as UC_CreateStaff
    usecase "Khóa / Mở khóa tài khoản" as UC_LockUser
    usecase "Reset mật khẩu bởi Admin" as UC_AdminResetPass
    usecase "Import học viên từ Excel" as UC_ImportExcel
    usecase "Phân quyền vai trò (Role Assignment)" as UC_AssignRole
    usecase "Quản lý Chi nhánh & Phòng học" as UC_BranchRoom
}

Guest --> UC_PublicView
Guest --> UC_SubmitLead

CommonUser --> UC_Login
CommonUser --> UC_ForgotPass

UC_Login ..> UC_AuthToken : <<include>>
UC_Login <.. UC_FirstLogin : <<extend>>\\n(khi isFirstLogin = true)

Academic --> UC_ManageLead
Academic --> UC_ConvertLead
Academic --> UC_CreateStudent
Academic --> UC_CreateParent
Academic --> UC_ImportExcel

UC_ManageLead <.. UC_ScheduleTest : <<extend>>
UC_ConvertLead ..> UC_CreateStudent : <<include>>

Admin --> UC_CreateStaff
Admin --> UC_LockUser
Admin --> UC_AdminResetPass
Admin --> UC_AssignRole
Admin --> UC_BranchRoom
Admin --|> Academic

@enduml
"""

# ==============================================================================
# 3. SƠ ĐỒ USE CASE PHÂN HỆ: ĐÀO TẠO, LỚP HỌC & ĐIỂM DANH - BÀI TẬP
# ==============================================================================
puml_usecase_academic = """@startuml
skinparam packageStyle rectangle
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 11
skinparam actorFontSize 12
skinparam actorFontStyle bold

skinparam rectangle {
    BackgroundColor #F8F9FA
    BorderColor #2C3E50
}
skinparam usecase {
    BackgroundColor #FFFFFF
    BorderColor #27AE60
}

left to right direction

actor "Nhân viên Học vụ" as Academic #F4ECF7
actor "Giáo viên" as Teacher #EAF2F8
actor "Học viên" as Student #E8F8F5
actor "Phụ huynh" as Parent #FEF9E7

rectangle "Phân hệ Đào tạo, Lớp học, Điểm danh & Bài tập" {
    usecase "Quản lý Khóa học & Bài học" as UC_ManageCourse
    usecase "Tạo lớp học mới" as UC_CreateClass
    usecase "Tự động sinh lịch học (Sessions)" as UC_GenSessions
    usecase "Kiểm tra phòng trống & Trùng lịch" as UC_CheckConflict
    usecase "Ghi danh học viên vào lớp" as UC_Enroll
    usecase "Tự động sinh hóa đơn học phí" as UC_AutoInvoice
    
    usecase "Xem thời khóa biểu cá nhân" as UC_ViewSchedule
    usecase "Điểm danh buổi học trên App" as UC_Attendance
    usecase "Tự động gửi Push cảnh báo vắng cho PH" as UC_NotifyAbsent
    usecase "Đăng ký học bù trực tuyến" as UC_ReqMakeup
    usecase "Duyệt yêu cầu học bù" as UC_ApproveMakeup
    
    usecase "Giao bài tập về nhà" as UC_CreateAsg
    usecase "Nộp bài tập (Text / File PDF)" as UC_SubmitAsg
    usecase "Ghi âm bài nói trực tiếp (Speaking Audio)" as UC_RecordSpeaking
    usecase "Chấm điểm & Nhận xét phát âm" as UC_GradeAsg
    usecase "Xem điểm số & Lắng nghe nhận xét" as UC_ViewResult
}

Academic --> UC_ManageCourse
Academic --> UC_CreateClass
Academic --> UC_Enroll
Academic --> UC_ApproveMakeup

UC_CreateClass ..> UC_GenSessions : <<include>>
UC_CreateClass ..> UC_CheckConflict : <<include>>
UC_Enroll ..> UC_AutoInvoice : <<include>>

Teacher --> UC_ViewSchedule
Teacher --> UC_Attendance
Teacher --> UC_CreateAsg
Teacher --> UC_GradeAsg

UC_Attendance <.. UC_NotifyAbsent : <<extend>>\\n(khi có học viên vắng)

Student --> UC_ViewSchedule
Student --> UC_ReqMakeup
Student --> UC_SubmitAsg
Student --> UC_ViewResult

UC_SubmitAsg <.. UC_RecordSpeaking : <<extend>>\\n(với bài tập Speaking)

Parent --> UC_ViewSchedule
Parent --> UC_ViewResult
Parent ..> UC_NotifyAbsent : <<nhận thông báo>>

@enduml
"""

# ==============================================================================
# 4. SƠ ĐỒ USE CASE PHÂN HỆ: THI CỬ & HỌC PHÍ - TÀI CHÍNH
# ==============================================================================
puml_usecase_exam_finance = """@startuml
skinparam packageStyle rectangle
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 11
skinparam actorFontSize 12
skinparam actorFontStyle bold

skinparam rectangle {
    BackgroundColor #F8F9FA
    BorderColor #2C3E50
}
skinparam usecase {
    BackgroundColor #FFFFFF
    BorderColor #C0392B
}

left to right direction

actor "Giáo viên" as Teacher #EAF2F8
actor "Học viên" as Student #E8F8F5
actor "Phụ huynh" as Parent #FEF9E7
actor "Thu ngân" as Cashier #FDEDEC
actor "Quản trị viên" as Admin #EAEDED

rectangle "Phân hệ Thi & Kiểm tra trực tuyến (Exam)" {
    usecase "Quản lý Ngân hàng câu hỏi đa dạng" as UC_QuestionBank
    usecase "Tạo & Cấu hình đề thi trực tuyến" as UC_CreateExam
    usecase "Làm bài thi trực tuyến trên App" as UC_TakeExam
    usecase "Tự động lưu câu trả lời (Auto-save)" as UC_AutoSave
    usecase "Tự động thu bài khi hết giờ (Timer)" as UC_AutoSubmit
    usecase "Tự động chấm trắc nghiệm tức thì" as UC_AutoScoring
    usecase "Chấm điểm phần thi tự luận / nói" as UC_ManualGrading
    usecase "Xem bảng điểm phân tích kỹ năng" as UC_ViewReportScore
}

rectangle "Phân hệ Quản lý Học phí & Tài chính (Finance)" {
    usecase "Quản lý & Tra cứu hóa đơn học phí" as UC_InvoiceList
    usecase "Ghi nhận thanh toán tại quầy" as UC_RecordCash
    usecase "Đóng học phí theo đợt (Trả góp)" as UC_Installment
    usecase "Thanh toán trực tuyến qua VNPay" as UC_OnlinePay
    usecase "Xử lý hủy lớp & Hoàn tiền / Bảo lưu" as UC_Refund
    usecase "Quản lý & Cảnh báo công nợ quá hạn" as UC_DebtAlert
    usecase "In & Xuất phiếu thu PDF (QR Code)" as UC_PrintReceipt
    usecase "Xem báo cáo doanh thu & Xuất Excel" as UC_RevenueReport
}

' Teacher Exam
Teacher --> UC_QuestionBank
Teacher --> UC_CreateExam
Teacher --> UC_ManualGrading
Teacher --> UC_ViewReportScore

' Student Exam
Student --> UC_TakeExam
Student --> UC_ViewReportScore

UC_TakeExam ..> UC_AutoSave : <<include>>
UC_TakeExam <.. UC_AutoSubmit : <<extend>>\\n(hết giờ làm bài)
UC_TakeExam ..> UC_AutoScoring : <<include>>

' Cashier Finance
Cashier --> UC_InvoiceList
Cashier --> UC_RecordCash
Cashier --> UC_Installment
Cashier --> UC_Refund
Cashier --> UC_DebtAlert
Cashier --> UC_PrintReceipt
Cashier --> UC_RevenueReport

UC_RecordCash ..> UC_PrintReceipt : <<include>>

' Student / Parent Pay
Student --> UC_OnlinePay
Parent --> UC_OnlinePay

Admin --> UC_DebtAlert
Admin --> UC_RevenueReport

@enduml
"""

# ==============================================================================
# 5. SƠ ĐỒ CLASS DIAGRAM TOÀN HỆ THỐNG
# ==============================================================================
puml_class_diagram = """@startuml
skinparam classAttributeIconSize false
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 10
skinparam classFontSize 11
skinparam classFontStyle bold
skinparam packageStyle rectangle

skinparam class {
    BackgroundColor #FFFFFF
    BorderColor #2C3E50
    BorderThickness 1.2
    ArrowColor #1A5276
}

package "1. Phân hệ Cơ sở & Đào tạo" #F4F6F6 {
    class Branch {
        +String id [PK]
        +String code
        +String name
        +String address
        +String phone
        +Boolean isActive
        +createRoom()
    }

    class Room {
        +String id [PK]
        +String branchId [FK]
        +String code
        +String name
        +Int capacity
        +String equipment
        +Boolean checkAvailability(DateTime start, DateTime end)
    }

    class Course {
        +String id [PK]
        +String code
        +String title
        +String language
        +Int totalSessions
        +Decimal standardTuition
        +Boolean isActive
        +addLevel()
    }

    class CourseLevel {
        +String id [PK]
        +String courseId [FK]
        +String levelCode
        +String title
        +Int orderIndex
    }

    class Lesson {
        +String id [PK]
        +String levelId [FK]
        +String title
        +Int orderIndex
        +String description
        +addMaterial()
    }

    class LessonMaterial {
        +String id [PK]
        +String lessonId [FK]
        +String title
        +MaterialFileType fileType
        +String fileUrl
    }
}

package "2. Phân hệ Người dùng & Phân quyền" #EAF2F8 {
    abstract class User {
        +String id [PK]
        +String userCode
        +String email
        +String phone
        +String passwordHash
        +String fullName
        +UserStatus status
        +Boolean isFirstLogin
        +DateTime createdAt
        +verifyPassword(String raw)
        +changePassword(String newPass)
    }

    class Role {
        +String id [PK]
        +String name
        +String description
    }

    class StudentProfile {
        +String id [PK]
        +String userId [FK]
        +String studentCode
        +DateTime dateOfBirth
        +Gender gender
        +getEnrollments()
    }

    class TeacherProfile {
        +String id [PK]
        +String userId [FK]
        +String teacherCode
        +String certificates
        +Decimal hourlyRate
        +getTeachingSchedule()
    }

    class AdmissionLead {
        +String id [PK]
        +String fullName
        +String phone
        +String email
        +LeadStatus status
        +String targetCourseId [FK]
        +convertToStudent()
    }
}

package "3. Phân hệ Vận hành Lớp học" #E8F8F5 {
    class Class {
        +String id [PK]
        +String classCode
        +String name
        +String courseId [FK]
        +String branchId [FK]
        +String primaryRoomId [FK]
        +String teacherId [FK]
        +ClassStatus status
        +Int maxStudents
        +DateTime startDate
        +generateSessions()
        +enrollStudent(StudentProfile sp)
    }

    class ClassSession {
        +String id [PK]
        +String classId [FK]
        +String roomId [FK]
        +String teacherId [FK]
        +Int sessionNumber
        +DateTime sessionDate
        +DateTime startTime
        +DateTime endTime
        +SessionStatus status
        +markAttendance()
    }

    class Enrollment {
        +String id [PK]
        +String classId [FK]
        +String studentId [FK]
        +DateTime enrolledAt
        +EnrollmentStatus status
    }

    class AttendanceRecord {
        +String id [PK]
        +String sessionId [FK]
        +String studentId [FK]
        +AttendanceStatus status
        +String note
    }

    class MakeupRequest {
        +String id [PK]
        +String studentId [FK]
        +String originalSessionId [FK]
        +String targetSessionId [FK]
        +MakeupStatus status
        +approve()
    }
}

package "4. Phân hệ Khảo thí & Bài tập" #FEF9E7 {
    class Assignment {
        +String id [PK]
        +String classId [FK]
        +String title
        +AssignmentType type
        +DateTime deadline
        +Decimal maxScore
    }

    class AssignmentSubmission {
        +String id [PK]
        +String assignmentId [FK]
        +String studentId [FK]
        +String textContent
        +String attachmentUrl
        +String audioRecordingUrl
        +Decimal score
        +String feedback
        +SubmissionStatus status
        +grade(Decimal score, String note)
    }

    class Exam {
        +String id [PK]
        +String classId [FK]
        +String title
        +Int durationMinutes
        +Decimal passScore
        +ExamStatus status
    }

    class Question {
        +String id [PK]
        +QuestionType type
        +String promptText
        +String mediaUrl
        +Json options
        +String correctAnswer
    }

    class ExamQuestion {
        +String id [PK]
        +String examId [FK]
        +String questionId [FK]
        +Int orderIndex
        +Decimal points
    }

    class ExamAttempt {
        +String id [PK]
        +String examId [FK]
        +String studentId [FK]
        +DateTime startedAt
        +DateTime submittedAt
        +Decimal totalScore
        +AttemptStatus status
        +autoGrade()
    }
}

package "5. Phân hệ Tài chính & Học phí" #FDEDEC {
    class Invoice {
        +String id [PK]
        +String invoiceCode
        +String studentId [FK]
        +String classId [FK]
        +Decimal originalAmount
        +Decimal discountAmount
        +Decimal finalAmount
        +Decimal paidAmount
        +DateTime dueDate
        +InvoiceStatus status
        +recordPayment(Decimal amt)
    }

    class PaymentReceipt {
        +String id [PK]
        +String invoiceId [FK]
        +String receiptCode
        +Decimal amount
        +PaymentMethod method
        +String transactionRef
        +PaymentStatus status
        +DateTime paidAt
    }
}

' QUAN HỆ KẾ THỪA & THỰC THỂ
User <|-- StudentProfile
User <|-- TeacherProfile

' QUAN HỆ COMPOSITION (HỢP THÀNH)
Course "1" *-- "1..*" CourseLevel : has
CourseLevel "1" *-- "1..*" Lesson : contains
Lesson "1" *-- "0..*" LessonMaterial : attaches
Class "1" *-- "1..*" ClassSession : includes
Exam "1" *-- "1..*" ExamQuestion : comprises
Invoice "1" *-- "0..*" PaymentReceipt : generates

' QUAN HỆ AGGREGATION (THU NẠP)
Branch "1" o-- "1..*" Room : owns
Course "1" o-- "0..*" Class : templates
Class "1" o-- "0..*" Assignment : assigns
Class "1" o-- "0..*" Exam : organizes

' QUAN HỆ HIỆP HÀNH & KẾT HỢP
Class "1" -- "0..*" Enrollment
StudentProfile "1" -- "0..*" Enrollment
ClassSession "1" -- "0..*" AttendanceRecord
StudentProfile "1" -- "0..*" AttendanceRecord
Assignment "1" -- "0..*" AssignmentSubmission
StudentProfile "1" -- "0..*" AssignmentSubmission
Exam "1" -- "0..*" ExamAttempt
StudentProfile "1" -- "0..*" ExamAttempt
Question "1" -- "0..*" ExamQuestion
StudentProfile "1" -- "0..*" Invoice
Branch "1" -- "0..*" Class

@enduml
"""

# ==============================================================================
# 6. SƠ ĐỒ CƠ SỞ DỮ LIỆU QUAN HỆ (PHYSICAL RELATIONAL SCHEMA - ERD)
# ==============================================================================
puml_relational_schema = """@startuml
skinparam linetype ortho
skinparam shadowing false
skinparam defaultFontName "Segoe UI"
skinparam defaultFontSize 10
skinparam entityFontSize 11
skinparam entityFontStyle bold

skinparam entity {
    BackgroundColor #FFFFFF
    BorderColor #2C3E50
    BorderThickness 1.2
}

entity "branches" as branches {
    * id : UUID [PK]
    --
    * code : VARCHAR(30) [UQ]
    * name : VARCHAR(255)
    * address : TEXT
    phone : VARCHAR(20)
    email : VARCHAR(100)
    * is_active : BOOLEAN
    * created_at : TIMESTAMP
}

entity "rooms" as rooms {
    * id : UUID [PK]
    --
    * branch_id : UUID [FK -> branches.id]
    * code : VARCHAR(30)
    * name : VARCHAR(100)
    * capacity : INT
    equipment : TEXT
    * is_active : BOOLEAN
}

entity "users" as users {
    * id : UUID [PK]
    --
    * user_code : VARCHAR(50) [UQ]
    email : VARCHAR(255) [UQ]
    phone : VARCHAR(20) [UQ]
    * password_hash : VARCHAR(255)
    * full_name : VARCHAR(150)
    * status : VARCHAR(30)
    * is_first_login : BOOLEAN
    branch_id : UUID [FK -> branches.id]
    created_at : TIMESTAMP
}

entity "roles" as roles {
    * id : UUID [PK]
    --
    * name : VARCHAR(50) [UQ]
    description : VARCHAR(255)
}

entity "user_roles" as user_roles {
    * user_id : UUID [PK, FK -> users.id]
    * role_id : UUID [PK, FK -> roles.id]
}

entity "student_profiles" as student_profiles {
    * id : UUID [PK]
    --
    * user_id : UUID [UQ, FK -> users.id]
    * student_code : VARCHAR(50) [UQ]
    date_of_birth : DATE
    gender : VARCHAR(10)
}

entity "teacher_profiles" as teacher_profiles {
    * id : UUID [PK]
    --
    * user_id : UUID [UQ, FK -> users.id]
    * teacher_code : VARCHAR(50) [UQ]
    certificates : TEXT
    hourly_rate : DECIMAL(12,2)
}

entity "courses" as courses {
    * id : UUID [PK]
    --
    * code : VARCHAR(50) [UQ]
    * title : VARCHAR(255)
    * language : VARCHAR(50)
    * total_sessions : INT
    * standard_tuition : DECIMAL(12,2)
    * is_active : BOOLEAN
}

entity "classes" as classes {
    * id : UUID [PK]
    --
    * class_code : VARCHAR(50) [UQ]
    * name : VARCHAR(255)
    * course_id : UUID [FK -> courses.id]
    * branch_id : UUID [FK -> branches.id]
    * primary_room_id : UUID [FK -> rooms.id]
    * teacher_id : UUID [FK -> users.id]
    * status : VARCHAR(30)
    * max_students : INT
    * start_date : DATE
}

entity "class_sessions" as class_sessions {
    * id : UUID [PK]
    --
    * class_id : UUID [FK -> classes.id]
    * room_id : UUID [FK -> rooms.id]
    * teacher_id : UUID [FK -> users.id]
    * session_number : INT
    * session_date : DATE
    * start_time : TIME
    * end_time : TIME
    * status : VARCHAR(30)
}

entity "enrollments" as enrollments {
    * id : UUID [PK]
    --
    * class_id : UUID [FK -> classes.id]
    * student_id : UUID [FK -> users.id]
    * enrolled_at : TIMESTAMP
    * status : VARCHAR(30)
}

entity "attendance_records" as attendance_records {
    * id : UUID [PK]
    --
    * session_id : UUID [FK -> class_sessions.id]
    * student_id : UUID [FK -> users.id]
    * status : VARCHAR(20)
    note : TEXT
}

entity "assignments" as assignments {
    * id : UUID [PK]
    --
    * class_id : UUID [FK -> classes.id]
    * title : VARCHAR(255)
    * type : VARCHAR(30)
    * deadline : TIMESTAMP
    * max_score : DECIMAL(5,2)
}

entity "assignment_submissions" as assignment_submissions {
    * id : UUID [PK]
    --
    * assignment_id : UUID [FK -> assignments.id]
    * student_id : UUID [FK -> users.id]
    text_content : TEXT
    attachment_url : TEXT
    audio_recording_url : TEXT
    score : DECIMAL(5,2)
    feedback : TEXT
    * status : VARCHAR(30)
}

entity "exams" as exams {
    * id : UUID [PK]
    --
    * class_id : UUID [FK -> classes.id]
    * title : VARCHAR(255)
    * duration_minutes : INT
    * pass_score : DECIMAL(5,2)
    * status : VARCHAR(30)
}

entity "exam_attempts" as exam_attempts {
    * id : UUID [PK]
    --
    * exam_id : UUID [FK -> exams.id]
    * student_id : UUID [FK -> users.id]
    * started_at : TIMESTAMP
    submitted_at : TIMESTAMP
    total_score : DECIMAL(5,2)
    * status : VARCHAR(30)
}

entity "invoices" as invoices {
    * id : UUID [PK]
    --
    * invoice_code : VARCHAR(50) [UQ]
    * student_id : UUID [FK -> users.id]
    * class_id : UUID [FK -> classes.id]
    * original_amount : DECIMAL(12,2)
    discount_amount : DECIMAL(12,2)
    * final_amount : DECIMAL(12,2)
    * paid_amount : DECIMAL(12,2)
    * due_date : DATE
    * status : VARCHAR(30)
}

entity "payment_receipts" as payment_receipts {
    * id : UUID [PK]
    --
    * invoice_id : UUID [FK -> invoices.id]
    * receipt_code : VARCHAR(50) [UQ]
    * amount : DECIMAL(12,2)
    * method : VARCHAR(30)
    transaction_ref : VARCHAR(100)
    * status : VARCHAR(30)
    * paid_at : TIMESTAMP
}

' RELATIONS
branches ||--o{ rooms : "contains"
branches ||--o{ users : "assigns"
branches ||--o{ classes : "operates"

users ||--o{ user_roles : "has"
roles ||--o{ user_roles : "granted_to"
users ||--|| student_profiles : "extends"
users ||--|| teacher_profiles : "extends"

courses ||--o{ classes : "instantiates"
rooms ||--o{ classes : "hosts"
classes ||--o{ class_sessions : "schedules"
rooms ||--o{ class_sessions : "allocated"

classes ||--o{ enrollments : "registers"
users ||--o{ enrollments : "attends"

class_sessions ||--o{ attendance_records : "logs"
users ||--o{ attendance_records : "marked"

classes ||--o{ assignments : "assigns"
assignments ||--o{ assignment_submissions : "submits"
users ||--o{ assignment_submissions : "authors"

classes ||--o{ exams : "tests"
exams ||--o{ exam_attempts : "attempts"
users ||--o{ exam_attempts : "takes"

users ||--o{ invoices : "billed_to"
classes ||--o{ invoices : "for_class"
invoices ||--o{ payment_receipts : "paid_by"

@enduml
"""

# Render all
render_jobs = [
    (puml_usecase_overall, ["docs/usecase_diagram_tong_the.png", "docs/diagrams/usecase_diagram_tong_the.png"]),
    (puml_usecase_admissions, ["docs/usecase_subsystem_tuyen_sinh_nguoi_dung.png", "docs/diagrams/usecase_subsystem_tuyen_sinh_nguoi_dung.png"]),
    (puml_usecase_academic, ["docs/usecase_subsystem_dao_tao_lop_hoc.png", "docs/diagrams/usecase_subsystem_dao_tao_lop_hoc.png"]),
    (puml_usecase_exam_finance, ["docs/usecase_subsystem_thi_cu_tai_chinh.png", "docs/diagrams/usecase_subsystem_thi_cu_tai_chinh.png"]),
    (puml_class_diagram, ["docs/class_diagram.png", "docs/diagrams/class_diagram.png"]),
    (puml_relational_schema, ["docs/relational_database_schema.png", "docs/diagrams/relational_database_schema.png"])
]

for code, paths in render_jobs:
    render_plantuml(code, paths)

print("All diagrams generated successfully!")
