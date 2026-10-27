import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

DIAG_DIR = r"c:\Users\Vi-Hung\my_flutter_pj\XD_HT_LMS\lms_trung_tam_ngoai_ngu\docs\diagrams_generated"
DOCS_DIR = r"c:\Users\Vi-Hung\my_flutter_pj\XD_HT_LMS\lms_trung_tam_ngoai_ngu\docs"

def create_doc():
    doc = docx.Document()
    for sec in doc.sections:
        sec.top_margin = Inches(1.0)
        sec.bottom_margin = Inches(1.0)
        sec.left_margin = Inches(1.0)
        sec.right_margin = Inches(1.0)
    return doc

def p_title(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(10)
    p.paragraph_format.line_spacing = 1.2
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(14)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0, 0, 0)
    return p

def p_h1(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.2
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(14)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0, 0, 0)
    return p

def p_h2(doc, text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.2
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(14)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0, 0, 0)
    return p

def p_body(doc, text, bold_prefix="", italic=False):
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.2
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = 'Times New Roman'
        r_pre.font.size = Pt(13)
        r_pre.font.bold = True
        r_pre.font.color.rgb = RGBColor(0, 0, 0)
    r_body = p.add_run(text)
    r_body.font.name = 'Times New Roman'
    r_body.font.size = Pt(13)
    r_body.font.italic = italic
    r_body.font.color.rgb = RGBColor(0, 0, 0)
    return p

def p_bullet(doc, text, bold_prefix=""):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.2
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = 'Times New Roman'
        r_pre.font.size = Pt(13)
        r_pre.font.bold = True
        r_pre.font.color.rgb = RGBColor(0, 0, 0)
    r_body = p.add_run(text)
    r_body.font.name = 'Times New Roman'
    r_body.font.size = Pt(13)
    r_body.font.color.rgb = RGBColor(0, 0, 0)
    return p

def p_image(doc, image_name, caption_text, width_inches=6.2):
    img_path = os.path.join(DIAG_DIR, image_name)
    if os.path.exists(img_path):
        p_img = doc.add_paragraph()
        p_img.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(8)
        p_img.paragraph_format.space_after = Pt(4)
        run_img = p_img.add_run()
        run_img.add_picture(img_path, width=Inches(width_inches))
        
        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_after = Pt(8)
        run_cap = p_cap.add_run(caption_text)
        run_cap.font.name = 'Times New Roman'
        run_cap.font.size = Pt(12)
        run_cap.font.italic = True
        run_cap.font.color.rgb = RGBColor(0, 0, 0)
    else:
        print(f"Warning: Image not found: {img_path}")

def p_table(doc, headers, data, col_widths=None):
    table = doc.add_table(rows=len(data) + 1, cols=len(headers))
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    # Header row
    hdr_cells = table.rows[0].cells
    for c_idx, title in enumerate(headers):
        hdr_cells[c_idx].text = title
        p = hdr_cells[c_idx].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.15
        for r in p.runs:
            r.font.name = 'Times New Roman'
            r.font.size = Pt(12)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0, 0, 0)
            
    # Data rows
    for r_idx, row in enumerate(data):
        row_cells = table.rows[r_idx + 1].cells
        for c_idx, val in enumerate(row):
            row_cells[c_idx].text = val
            p = row_cells[c_idx].paragraphs[0]
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            for r in p.runs:
                r.font.name = 'Times New Roman'
                r.font.size = Pt(11.5)
                r.font.color.rgb = RGBColor(0, 0, 0)

    if col_widths:
        for row in table.rows:
            for idx, width in enumerate(col_widths):
                row.cells[idx].width = Inches(width)

    # Black borders
    tblPr = table._tbl.tblPr
    tblBorders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="single" w:sz="6" w:space="0" w:color="000000"/>
            <w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/>
            <w:left w:val="single" w:sz="6" w:space="0" w:color="000000"/>
            <w:right w:val="single" w:sz="6" w:space="0" w:color="000000"/>
            <w:insideH w:val="single" w:sz="4" w:space="0" w:color="666666"/>
            <w:insideV w:val="single" w:sz="4" w:space="0" w:color="666666"/>
        </w:tblBorders>
    ''')
    tblPr.append(tblBorders)
    
    p_after = doc.add_paragraph()
    p_after.paragraph_format.space_after = Pt(6)

# ==============================================================================
# BUILD TASK 1
# ==============================================================================
def build_task1():
    doc = create_doc()
    p_title(doc, "BÀI TẬP TRÊN LỚP SỐ 3 - THIẾT KẾ CÁC KHUNG NHÌN KIẾN TRÚC\nTASK #1: THIẾT KẾ VIEW KIẾN TRÚC LOGIC (LOGICAL VIEWS)\nHỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ")
    
    p_h1(doc, "1. Biểu đồ lớp (Class Diagram)")
    p_body(doc, "Biểu đồ lớp dưới đây thể hiện cấu trúc tĩnh tổng thể của hệ thống LMS Trung tâm Ngoại ngữ, mô hình hóa các lớp nghiệp vụ cốt lõi và các quan hệ theo chuẩn UML 2.5:")
    p_bullet(doc, "Lớp cha BaseEntity làm nền tảng cho các thực thể; lớp User được chuyên biệt hóa thành StudentProfile, TeacherProfile, ParentProfile.", "Quan hệ Kế thừa (Generalization): ")
    p_bullet(doc, "Lớp Class hợp thành các Session (buổi học gắn liền vòng đời với lớp học); lớp Exam hợp thành các ExamQuestion; lớp Invoice hợp thành PaymentReceipt.", "Quan hệ Hợp thành (Composition): ")
    p_bullet(doc, "Chi nhánh Branch kết tập các Room (phòng học); Course kết tập các Class; Class kết tập các Enrollment.", "Quan hệ Kết tập (Aggregation): ")
    p_bullet(doc, "Học viên liên kết với Lớp học qua Enrollment; Giáo viên phụ trách giảng dạy Class và chấm bài nộp AssignmentSubmission.", "Quan hệ Liên kết (Association): ")
    
    p_image(doc, "task1_class_diagram.png", "Hình 1.1: Biểu đồ lớp UML tổng thể hệ thống LMS Trung tâm Ngoại ngữ", width_inches=6.3)
    
    p_h2(doc, "1.1. Biểu đồ phân tầng Package trong kiến trúc")
    p_body(doc, "Hệ thống áp dụng kiến trúc phân tầng 3 lớp chuẩn: Tầng Presentation (giao diện, điều khiển) gọi tầng Business Logic (dịch vụ nghiệp vụ), và tầng Business Logic gọi tầng Data Access (truy xuất cơ sở dữ liệu qua Prisma ORM):")
    p_image(doc, "task1_package_diagram.png", "Hình 1.2: Biểu đồ phân tầng Package trong Logical View", width_inches=5.8)

    p_h2(doc, "1.2. Nội dung giới thiệu chi tiết cho từng lớp trong hệ thống")
    headers_classes = ["STT", "Tên Lớp (Class)", "Phân tầng", "Trách nhiệm chính", "Thuộc tính & Phương thức trọng yếu"]
    data_classes = [
        ["1", "BaseEntity", "Domain Core", "Cung cấp định danh cơ sở id, thời gian tạo createdAt, updatedAt cho toàn bộ các thực thể.", "id: String, createdAt: DateTime, delete(): void"],
        ["2", "User", "Domain / Auth", "Quản lý định danh tài khoản tập trung, bảo mật mật khẩu, phân quyền vai trò RBAC và cờ kích hoạt tài khoản lần đầu.", "username, email, phone, passwordHash, role, status, isFirstLogin, verifyPassword(), changePassword()"],
        ["3", "StudentProfile", "Domain / Academic", "Lưu trữ hồ sơ học viên, mã số học viên, ngày sinh, giới tính và theo dõi danh sách lớp học tham gia.", "studentCode, dateOfBirth, gender, address, getEnrolledClasses(), getTuitionDebt()"],
        ["4", "TeacherProfile", "Domain / Academic", "Quản lý hồ sơ giảng viên, trình độ chuyên môn ngoại ngữ, khung giờ giảng dạy và mức thù lao tiết dạy.", "teacherCode, specialization, bio, hourlyRate, getAssignedClasses()"],
        ["5", "ParentProfile", "Domain / Academic", "Quản lý hồ sơ phụ huynh, thiết lập liên kết giám sát với một hoặc nhiều hồ sơ con em theo học.", "parentCode, relationship, getChildren()"],
        ["6", "Branch", "Domain / Org", "Đại diện cho cơ sở/chi nhánh đào tạo vật lý của trung tâm ngoại ngữ, quản lý danh sách phòng học.", "code, name, address, hotline, addRoom()"],
        ["7", "Room", "Domain / Logistics", "Đại diện cho phòng học tại chi nhánh, quản lý sức chứa tối đa và kiểm tra khung giờ trống khả dụng.", "roomNumber, capacity, roomType, isAvailable()"],
        ["8", "Course", "Domain / Academic", "Quản lý khung chương trình đào tạo tổng quát (IELTS, TOEIC, Giao tiếp), số giờ học chuẩn và học phí cơ sở.", "code, title, description, basePrice, totalHours, createClass()"],
        ["9", "Class", "Domain / Academic", "Lớp học cụ thể được mở theo kỳ. Phân bổ giáo viên, phòng học, ngưỡng sĩ số tối thiểu/tối đa và các buổi học.", "classCode, name, status, minStudents, maxStudents, startDate, generateSessions(), enrollStudent()"],
        ["10", "Session", "Domain / Academic", "Đại diện cho một buổi học cụ thể trên thời khóa biểu, lưu vết ngày học, ca học, phòng học và chuyên cần.", "sessionNumber, date, startTime, endTime, status, markAttendance()"],
        ["11", "Enrollment", "Domain / Academic", "Quản lý mối quan hệ ghi danh giữa học viên và lớp học, theo dõi bảo lưu, chuyển lớp và điểm tổng kết.", "enrolledAt, status, finalGrade, updateStatus()"],
        ["12", "AttendanceRecord", "Domain / Attendance", "Lưu vết chuyên cần chi tiết của từng học viên trong từng buổi (Có mặt, Đi trễ, Vắng có phép, Vắng không phép).", "status, note, markedAt, updateStatus()"],
        ["13", "Assignment", "Domain / Assessment", "Quản lý bài tập về nhà do giáo viên giao, thời hạn chót nộp bài, tiêu chí điểm và cờ cho phép nộp audio.", "title, description, deadline, maxScore, allowAudioSubmission, isPastDeadline()"],
        ["14", "AssignmentSubmission", "Domain / Assessment", "Bài làm nộp của học viên, lưu văn bản, đường dẫn file tài liệu hoặc file âm thanh ghi âm phát âm.", "textContent, fileAttachmentUrl, audioRecordingUrl, score, teacherFeedback, gradeSubmission()"],
        ["15", "Exam", "Domain / Assessment", "Quản lý bài thi / bài kiểm tra định kỳ (Placement, Midterm, Final) với thời lượng quy định và đếm giờ server.", "title, type, durationMinutes, totalScore, status, publishExam(), startAttempt()"],
        ["16", "ExamQuestion", "Domain / Assessment", "Câu hỏi thành phần trong đề thi (Trắc nghiệm, Điền từ, Nối câu, Nghe đoạn hội thoại).", "orderNumber, type, promptText, optionsJson, correctAnswer, points, validateAnswer()"],
        ["17", "ExamAttempt", "Domain / Assessment", "Phiên làm bài thi trực tuyến của học viên, quản lý giờ bắt đầu, tự động nộp bài và tính điểm trắc nghiệm.", "startedAt, submittedAt, earnedScore, status, autoGradeObjective(), finalizeScore()"],
        ["18", "Invoice", "Domain / Finance", "Quản lý nghĩa vụ tài chính học phí của học viên khi vào lớp, hạn nộp học phí và trạng thái thanh toán.", "invoiceCode, amount, status, dueDate, createPaymentTransaction(), markAsPaid()"],
        ["19", "PaymentReceipt", "Domain / Finance", "Biên lai thanh toán thành công, ghi nhận mã giao dịch ngân hàng/VNPay hoặc phiếu thu tiền mặt tại quầy.", "transactionRef, paidAmount, paymentMethod, paymentDate, gatewayResponse"],
        ["20", "ClassService", "Business Logic", "Dịch vụ điều phối nghiệp vụ xếp lớp, thuật toán tự sinh các buổi học và kiểm tra chống trùng lịch.", "createClassWithSessions(), validateNoScheduleConflict(), enrollStudentWithCapacityCheck()"],
        ["21", "AttendanceService", "Business Logic", "Dịch vụ xử lý điểm danh chuyên cần, phát sinh sự kiện thông báo thời gian thực đến phụ huynh khi học viên vắng.", "submitSessionAttendance(), emitAttendanceAlertEvent(), processMakeupRequest()"],
        ["22", "ExamService", "Business Logic", "Dịch vụ tổ chức thi trực tuyến, quản lý đồng hồ đếm ngược server chống gian lận và tự động chấm điểm tức thì.", "startExamSession(), submitExamAnswers(), autoGradeAndPublish()"],
        ["23", "FinanceService", "Business Logic", "Dịch vụ quản lý dòng tiền học phí, khởi tạo URL thanh toán VNPay SHA-512 và xác thực Webhook đối soát IPN.", "generateInvoice(), createVNPayPaymentUrl(), handlePaymentCallbackIPN()"]
    ]
    p_table(doc, headers_classes, data_classes, col_widths=[0.4, 1.4, 1.1, 1.9, 1.5])

    p_h1(doc, "2. Biểu đồ trạng thái (State Diagram)")
    p_body(doc, "Trong hệ thống LMS Trung tâm Ngoại ngữ, hai thực thể mang tính nghiệp vụ nòng cốt và có chu trình trạng thái phức tạp nhất là Lớp học (Class) và Phiên làm bài thi trực tuyến của học viên (ExamAttempt).")
    
    p_h2(doc, "2.1. Biểu đồ trạng thái Vòng đời Lớp học (Class Lifecycle)")
    p_body(doc, "Biểu đồ mô tả toàn bộ vòng đời của một lớp học từ giai đoạn dự thảo đến khi hoàn tất lưu trữ:")
    p_image(doc, "task1_state_class.png", "Hình 1.3: Biểu đồ trạng thái Vòng đời Lớp học (Class Lifecycle State Machine)", width_inches=6.0)
    
    p_body(doc, "Chi tiết các trạng thái của Lớp học:", bold_prefix="Mô tả các trạng thái: ")
    p_bullet(doc, "Lớp học vừa được nhân viên học vụ tạo dự thảo; đang thương thảo lịch dạy với giảng viên và phân bổ phòng học. Điều kiện chuyển tiếp: Khi đã gán đủ giáo viên và phòng học hợp lệ -> chuyển sang OPEN_FOR_ENROLLMENT.", "Trạng thái PLANNING (Lên kế hoạch): ")
    p_bullet(doc, "Lớp học mở công khai để tuyển sinh và ghi danh học viên. Mỗi khi có học viên đóng phí, sĩ số tăng lên 1. Nếu đến hạn mở lớp mà sĩ số không đạt min_students -> chuyển sang CANCELLED (hủy lớp, hoàn phí). Nếu đủ sĩ số và đến ngày startDate -> chuyển sang IN_PROGRESS.", "Trạng thái OPEN_FOR_ENROLLMENT (Mở tuyển sinh): ")
    p_bullet(doc, "Lớp học chính thức bước vào đào tạo thực tế. Bao gồm các trạng thái con: Giảng dạy các buổi học (TEACHING_SESSION), Giáo viên điểm danh (ATTENDANCE_MARKED), và Thi giữa kỳ (MIDTERM_EXAM). Khi hoàn tất buổi học cuối cùng và nộp bảng điểm tổng kết -> chuyển sang COMPLETED.", "Trạng thái IN_PROGRESS (Đang diễn ra đào tạo): ")
    p_bullet(doc, "Lớp học đã hoàn tất toàn bộ chương trình đào tạo. Hệ thống tự động tính điểm chuyên cần, chốt điểm thi cuối kỳ và xuất chứng nhận hoàn thành khóa học.", "Trạng thái COMPLETED (Hoàn thành): ")
    p_bullet(doc, "Lớp học bị hủy do không đủ sĩ số tối thiểu hoặc do sự cố bất khả kháng. Hệ thống tự động kích hoạt hoàn tiền hoặc chuyển lớp cho học viên.", "Trạng thái CANCELLED (Đã hủy): ")
    p_bullet(doc, "Sau 90 ngày kết thúc khóa học, dữ liệu lớp học được đóng băng và chuyển sang chế độ chỉ đọc để lưu trữ hồ sơ học vụ lịch sử.", "Trạng thái ARCHIVED (Lưu trữ): ")

    p_h2(doc, "2.2. Biểu đồ trạng thái Vòng đời Bài thi trực tuyến (Exam Attempt Lifecycle)")
    p_body(doc, "Biểu đồ mô tả quy trình làm bài kiểm tra trực tuyến của học viên trên ứng dụng di động:")
    p_image(doc, "task1_state_exam.png", "Hình 1.4: Biểu đồ trạng thái Vòng đời Bài thi trực tuyến (Exam Attempt State Machine)", width_inches=6.0)
    
    p_body(doc, "Chi tiết các trạng thái của Bài thi:", bold_prefix="Mô tả các trạng thái: ")
    p_bullet(doc, "Học viên vào phòng thi, màn hình hiển thị quy chế thi, số lượng câu hỏi và tổng thời lượng. Đề thi được tải trước về máy khách.", "Trạng thái READY (Sẵn sàng): ")
    p_bullet(doc, "Học viên bấm Bắt đầu làm bài; đồng hồ đếm ngược phía server chính thức kích hoạt. Trạng thái con SAVING_TEMP tự động lưu đáp án cục bộ mỗi 15 giây. Khi mất kết nối (NETWORK_LOST), học viên vẫn tiếp tục làm bài và đồng bộ lại khi có mạng.", "Trạng thái IN_PROGRESS (Đang làm bài): ")
    p_bullet(doc, "Học viên bấm nộp bài chủ động, hoặc đồng hồ server hết giờ và tự động thu bài cưỡng chế. Toàn bộ đáp án được chốt và khóa quyền chỉnh sửa.", "Trạng thái SUBMITTED (Đã nộp bài): ")
    p_bullet(doc, "Động cơ máy tính tự động so khớp các câu hỏi trắc nghiệm khách quan với bảng đáp án chuẩn trong vòng dưới 1 giây. Nếu đề thi thuần trắc nghiệm -> chuyển sang GRADED. Nếu có câu hỏi thu âm phát âm hoặc viết luận -> chuyển sang PENDING_TEACHER_REVIEW.", "Trạng thái AUTO_GRADING (Chấm tự động): ")
    p_bullet(doc, "Bài thi được đưa vào hàng đợi của giáo viên để nghe file ghi âm phát âm, chấm bài luận theo thang tiêu chí và ghi nhận xét.", "Trạng thái PENDING_TEACHER_REVIEW (Chờ giáo viên chấm): ")
    p_bullet(doc, "Toàn bộ điểm thành phần đã được giáo viên chấm và xác nhận chốt điểm chính thức.", "Trạng thái GRADED (Đã có điểm): ")
    p_bullet(doc, "Điểm số được công khai trên ứng dụng của học viên và gửi thông báo Notification đến phụ huynh; cập nhật điểm vào sổ điểm lớp học.", "Trạng thái PUBLISHED (Đã công bố kết quả): ")

    out_path = os.path.join(DOCS_DIR, "Task1_Logical_View.docx")
    doc.save(out_path)
    print(f"Task 1 DOCX built: {out_path}")

# ==============================================================================
# BUILD TASK 2
# ==============================================================================
def build_task2():
    doc = create_doc()
    p_title(doc, "BÀI TẬP TRÊN LỚP SỐ 3 - THIẾT KẾ CÁC KHUNG NHÌN KIẾN TRÚC\nTASK #2: THIẾT KẾ VIEW KIẾN TRÚC TIẾN TRÌNH (PROCESS VIEWS)\nHỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ")

    p_h1(doc, "1. Xác định các Process trong dự án")
    p_body(doc, "Trong hệ thống LMS Trung tâm Ngoại ngữ, có 6 tiến trình (OS Processes) chạy độc lập trên các môi trường phân tán:")
    p_bullet(doc, "Ứng dụng di động chạy trên thiết bị Android hoặc iOS của Học viên, Giáo viên và Phụ huynh; đảm nhiệm render giao diện, ghi âm bài nói phát âm và nhận thông báo đẩy.", "P1: FlutterMobileApp - ")
    p_bullet(doc, "Ứng dụng Web chạy trên trình duyệt (Chrome, Edge, Safari) của Quản trị viên, Nhân viên học vụ và Thu ngân; đảm nhiệm xếp lớp, quản lý công nợ và xuất báo cáo.", "P2: FlutterWebPortal - ")
    p_bullet(doc, "Tiến trình máy chủ Node.js trung tâm; tiếp nhận mọi HTTP/REST request từ client, xử lý xác thực JWT, phân quyền RBAC, kiểm tra trùng lịch và tính điểm thi.", "P3: NestJS_APIServer - ")
    p_bullet(doc, "Tiến trình chạy ngầm chuyên biệt; lắng nghe hàng đợi Bull Queue từ Redis để thực thi các tác vụ nặng: bắn push notification qua FCM, gửi email, quét cron job định kỳ.", "P4: BullQueue_BackgroundWorker - ")
    p_bullet(doc, "Hệ quản trị cơ sở dữ liệu quan hệ PostgreSQL; quản lý dữ liệu bền vững, thực thi các truy vấn ACID, khóa giao dịch chống tranh chấp dữ liệu.", "P5: PostgreSQL_DatabaseEngine - ")
    p_bullet(doc, "Máy chủ In-memory tốc độ cao; quản lý phiên làm việc (Session Store), cache danh mục dữ liệu và đóng vai trò Message Broker cho hàng đợi công việc.", "P6: Redis_Server - ")

    p_image(doc, "task2_process_overview.png", "Hình 2.1: Sơ đồ các Process tổng thể trong hệ thống LMS", width_inches=6.0)

    p_h1(doc, "2. Các Thread bên trong từng Process")
    p_body(doc, "Mỗi tiến trình trong hệ thống đều được cấu trúc đa luồng chuyên biệt nhằm tối ưu hóa hiệu năng và độ phản hồi:")
    
    p_h2(doc, "2.1. Phân rã luồng trong P1: FlutterMobileApp")
    p_bullet(doc, "Chạy trên luồng chính của Dart, thực thi code ứng dụng, lắng nghe sự kiện cảm ứng chạm, tính toán bố cục layout và chỉ thị GPU render giao diện 60fps hoặc 120fps.", "UI Thread / Main Isolate: ")
    p_bullet(doc, "Dart Isolate độc lập sở hữu bộ nhớ riêng; tiếp nhận luồng âm thanh từ microphone khi học viên làm bài thi nói, thực hiện nén chuẩn AAC/M4A trước khi tải lên Cloud Storage, không làm nghẽn UI.", "Audio Recorder Worker Isolate: ")
    p_bullet(doc, "Thực thi các thao tác đọc/ghi bất đồng bộ xuống cơ sở dữ liệu cục bộ SQLite (sqflite) để lưu tạm thời khóa biểu và đáp án làm bài khi mất kết nối mạng.", "SQLite Local Storage Thread: ")

    p_h2(doc, "2.2. Phân rã luồng trong P3: NestJS_APIServer")
    p_bullet(doc, "Vận hành theo mô hình Non-blocking I/O đơn luồng; tiếp nhận hàng nghìn kết nối HTTP song song, điều phối request qua Guard, Pipe, Interceptor đến đúng Controller và Service.", "Node.js Main Event Loop Thread: ")
    p_bullet(doc, "Nhóm luồng gồm 4 worker threads mặc định; xử lý các tác vụ CPU-intensive như băm mật khẩu bcrypt (salt rounds = 12), xác thực chữ ký mã hóa JWT và đối soát chữ ký SHA-512 của cổng VNPay.", "Libuv Worker Thread Pool: ")
    p_bullet(doc, "Quản lý đồng thời tập hợp các kết nối mạng TCP socket đến PostgreSQL (Connection Pooling), tái sử dụng kết nối nhằm giảm chi phí thiết lập bắt tay ba bước.", "Prisma Database Connection Pool: ")

    p_h2(doc, "2.3. Phân rã luồng trong P4: BullQueue_BackgroundWorker")
    p_bullet(doc, "Liên tục thăm dò và nhặt các job từ Redis server qua lệnh blocking pop (BRPOPLPUSH).", "Queue Dispatcher Thread: ")
    p_bullet(doc, "Kết nối song song đến máy chủ Google FCM để gửi thông báo điểm danh, nhắc lịch học tức thì tới điện thoại phụ huynh.", "FCM Push Notification Worker Thread: ")
    p_bullet(doc, "Thiết lập kết nối TLS với máy chủ Google SMTP để gửi email kích hoạt tài khoản và hóa đơn học phí dạng hàng loạt.", "SMTP Mailer Worker Thread: ")
    p_bullet(doc, "Thực thi định kỳ lúc 00:00 hàng ngày để quét các bài tập sắp hết hạn trong 24 giờ và tự động khóa các lớp học đã hoàn thành.", "Scheduled Cron Thread: ")

    p_h2(doc, "2.4. Phân rã luồng trong P5: PostgreSQL Database Engine")
    p_bullet(doc, "Lắng nghe trên cổng 5432, cấp phát và quản lý các tiến trình kết nối con từ máy chủ backend.", "Postmaster Listener Process: ")
    p_bullet(doc, "Mỗi kết nối từ NestJS được phục vụ bởi một worker riêng biệt, thực thi phân tích cú pháp SQL và truy vấn bảng dữ liệu.", "Backend Query Workers: ")
    p_bullet(doc, "Ghi tuần tự các thay đổi dữ liệu vào nhật ký WAL trước khi cập nhật dữ liệu đĩa, đảm bảo nguyên lý bền vững (Durability) của ACID.", "WAL (Write-Ahead Logging) Writer: ")
    p_bullet(doc, "Định kỳ đẩy các trang dữ liệu bẩn (dirty buffers) từ RAM xuống ổ đĩa cứng vật lý.", "Checkpointer & Background Writer: ")
    p_bullet(doc, "Tự động thu hồi không gian bộ nhớ của các bản ghi đã bị xóa (dead tuples) và cập nhật thống kê query planner.", "Autovacuum Worker: ")

    p_h2(doc, "2.5. Phân rã luồng trong P6: Redis Server")
    p_bullet(doc, "Thực thi tuần tự toàn bộ các lệnh đọc/ghi bộ nhớ in-memory (GET, SET, LPUSH, RPOP, INCR) với độ trễ cực nhỏ dưới 1 miligiây theo mô hình Reactor.", "Main Event Loop Thread: ")
    p_bullet(doc, "Đảm nhiệm việc đọc/ghi dữ liệu thô trên socket mạng từ hàng trăm client đồng thời, giải phóng gánh nặng cho luồng Event Loop chính.", "Network I/O Socket Threads: ")
    p_bullet(doc, "Chạy ngầm các tác vụ nặng: đóng tệp (bio_close_file), ghi dữ liệu xuống đĩa (bio_aof_fsync), giải phóng cấu trúc dữ liệu khổng lồ (bio_lazy_free).", "Background Bio Threads: ")

    p_image(doc, "task2_threads_breakdown.png", "Hình 2.2: Sơ đồ phân rã các Thread bên trong các Process chính", width_inches=6.0)

    p_h1(doc, "3. Bảng ánh xạ từ Logical Classes sang Processes (Theo Slide 40)")
    headers_proc = ["Nhóm Lớp trong Logical View", "Tiến trình sở hữu (Assigned Process)", "Stereotype", "Giao thức truyền thông liên tiến trình"]
    data_proc = [
        ["LoginScreen, ExamScreen, AudioRecorderWidget, ClassBloc", "P1: FlutterMobileApp", "«process»", "Tương tác cục bộ trong bộ nhớ máy khách"],
        ["AdminDashboardScreen, ClassManagerScreen, InvoiceScreen", "P2: FlutterWebPortal", "«process»", "Web Browser DOM / JavaScript V8 Engine"],
        ["AuthController, ClassController, AttendanceController, ExamController, FinanceController", "P3: NestJS_APIServer", "«process»", "Nhận request từ P1/P2 qua HTTPS (REST/JSON)"],
        ["AuthService, ClassService, AttendanceService, ExamService, FinanceService", "P3: NestJS_APIServer", "«process»", "Thực thi nghiệp vụ đồng bộ trong Node.js Runtime"],
        ["NotificationJobConsumer, EmailJobConsumer, ReportWorker", "P4: BullQueue_BackgroundWorker", "«process»", "Lắng nghe hàng đợi từ P6 qua giao thức Redis RESP"],
        ["PrismaClient, UserRepository, ClassRepository, ExamRepository, InvoiceRepository", "P3: NestJS_APIServer & P5: PostgreSQL", "«process»", "Truy vấn cơ sở dữ liệu qua TCP/IP (Port 5432)"],
        ["SessionCache, DistributedLock, BullJobQueue", "P6: Redis_Server", "«process»", "Giao tiếp bộ nhớ đệm qua TCP/IP (Port 6379)"]
    ]
    p_table(doc, headers_proc, data_proc, col_widths=[1.8, 1.6, 0.9, 1.9])

    p_h1(doc, "4. Tài nguyên và dữ liệu cần giải quyết xung đột: Đồng bộ hay Bất đồng bộ?")
    
    p_h2(doc, "4.1. Xung đột 1: Tranh chấp giữ chỗ khi Lớp học chạm ngưỡng sĩ số tối đa (max_students)")
    p_body(doc, "Một lớp học ngoại ngữ chỉ còn đúng 1 suất cuối cùng (sĩ số hiện tại là 19, tối đa là 20). Hai học viên A và B cùng lúc bấm xác nhận thanh toán/ghi danh trên điện thoại. Nếu hệ thống đọc dữ liệu thông thường, cả hai luồng đều thấy còn chỗ và cùng ghi nhận thành công, dẫn đến sĩ số bị đội lên 21 học viên (lỗi Overbooking / Race Condition).", bold_prefix="Vấn đề: ")
    p_body(doc, "ĐỒNG BỘ (Synchronous RPC) kết hợp cơ chế KHÓA GUARDED (Pessimistic Locking / SELECT ... FOR UPDATE trong Transaction).", bold_prefix="Giải pháp: ")
    p_body(doc, "Thao tác đăng ký và trừ chỗ liên quan trực tiếp đến tiền học phí, phải trả lời kết quả ngay lập tức cho học viên (Thành công hay Lớp đã đầy), không thể đưa vào hàng đợi xử lý sau. Sử dụng transaction cô lập của PostgreSQL, luồng của học viên A vào trước sẽ khóa dòng dữ liệu của lớp học; luồng của học viên B phải chờ. Khi giao dịch A hoàn tất tăng sĩ số lên 20, luồng B mới được đọc dữ liệu và phát hiện lớp đã đầy, hệ thống lập tức rollback và trả về mã lỗi 409 Conflict.", bold_prefix="Giải thích: ")

    p_h2(doc, "4.2. Xung đột 2: Xếp lịch buổi học (Session) - Trùng phòng học hoặc trùng giáo viên")
    p_body(doc, "Hai nhân viên học vụ cùng lúc thao tác trên Web Portal xếp 2 lớp khác nhau vào cùng một phòng học hoặc cùng một giáo viên tại cùng một khung giờ.", bold_prefix="Vấn đề: ")
    p_body(doc, "ĐỒNG BỘ (Synchronous RPC) kết hợp RÀNG BUỘC TOÀN VẸN CƠ SỞ DỮ LIỆU (Guarded Constraint).", bold_prefix="Giải pháp: ")
    p_body(doc, "Nhân viên học vụ cần nhận kết quả ngay trên màn hình để kịp thời chọn phòng hoặc giảng viên khác. Áp dụng mức cô lập SERIALIZABLE và ràng buộc loại trừ PostgreSQL Exclusion Constraint (EXCLUDE USING gist với toán tử trùng khoảng thời gian &&). Khi phát hiện trùng giờ, cơ sở dữ liệu tự động từ chối giao dịch thứ hai và ném lỗi 400 Bad Request.", bold_prefix="Giải thích: ")

    p_h2(doc, "4.3. Xung đột 3: Điểm danh buổi học và Gửi thông báo phụ huynh khi học viên vắng")
    p_body(doc, "Giáo viên bấm Hoàn thành điểm danh lớp học có 30 học viên, trong đó có 3 học viên vắng không phép. Hệ thống vừa phải ghi nhận chuyên cần vào CSDL, vừa phải gọi API Google FCM bắn thông báo đẩy tới điện thoại phụ huynh và gửi email cảnh báo. Nếu thực hiện đồng bộ toàn bộ, giáo viên phải chờ 3-8 giây do độ trễ mạng ngoại vi, gây đơ giao diện.", bold_prefix="Vấn đề: ")
    p_body(doc, "MÔ HÌNH LAI (HYBRID MODEL): ĐỒNG BỘ TRONG GHI NHẬN HỌC VỤ + BẤT ĐỒNG BỘ TRONG TRUYỀN THÔNG BÁO.", bold_prefix="Giải pháp: ")
    p_body(doc, "Ghi nhận 30 bản ghi điểm danh vào PostgreSQL được thực thi ĐỒNG BỘ trong transaction ngắn và trả về mã 200 OK ngay lập tức cho giáo viên (dưới 50ms). Sau đó, hệ thống phát sinh sự kiện nội bộ và đẩy 3 tác vụ thông báo vào hàng đợi Redis Bull Queue. Tiến trình Background Worker nhặt job xử lý BẤT ĐỒNG BỘ trong nền, độc lập hoàn toàn với giáo viên. Nếu điện thoại phụ huynh tạm mất sóng, Bull Queue tự động thử lại (retry) mà không ảnh hưởng hệ thống chính.", bold_prefix="Giải thích: ")

    p_h2(doc, "4.4. Xung đột 4: Webhook Thanh toán VNPay IPN vs Thu tiền mặt tại quầy")
    p_body(doc, "Học viên quét mã QR VNPay để thanh toán, cùng lúc nhân viên thu ngân tại trung tâm cũng bấm Xác nhận thu tiền mặt cho cùng một hóa đơn.", bold_prefix="Vấn đề: ")
    p_body(doc, "ĐỒNG BỘ kết hợp IDEMPOTENCY KEY và GUARDED REDIS LOCK.", bold_prefix="Giải pháp: ")
    p_body(doc, "Hệ thống tạo khóa phân tán Redis Mutex trên key lock:invoice:id trong 5 giây. Luồng nào giành được khóa trước sẽ kiểm tra trạng thái hóa đơn; nếu đã PAID thì từ chối giao dịch sau, đảm bảo hóa đơn không bao giờ bị ghi nhận thanh toán hai lần.", bold_prefix="Giải thích: ")

    p_h1(doc, "5. Các biểu đồ UML Process View và giải thích kèm theo")
    
    p_h2(doc, "5.1. Biểu đồ Active Class & Process Interaction tổng thể")
    p_body(doc, "Biểu đồ thể hiện các Active Objects mang luồng điều khiển riêng (ký hiệu đường viền kép) và các giao thức truyền thông liên tiến trình:")
    p_image(doc, "task2_active_class_process.png", "Hình 2.3: Biểu đồ Active Class & Process Interaction tổng thể", width_inches=6.0)

    p_h2(doc, "5.2. Biểu đồ Sequence Diagram: Luồng Điểm danh và Thông báo phụ huynh")
    p_body(doc, "Minh họa ranh giới rõ ràng giữa pha Đồng bộ (Sync RPC dưới 50ms) để phản hồi nhanh cho giáo viên và pha Bất đồng bộ (Async Queue) để gửi thông báo nền cho phụ huynh:")
    p_image(doc, "task2_seq_attendance.png", "Hình 2.4: Biểu đồ Sequence luồng Điểm danh và Thông báo phụ huynh (Đồng bộ vs Bất đồng bộ)", width_inches=6.0)

    p_h2(doc, "5.3. Biểu đồ Sequence Diagram: Xử lý tranh chấp giữ chỗ lớp học")
    p_body(doc, "Minh họa cơ chế Guarded Lock (Pessimistic Row-level Locking với SELECT ... FOR UPDATE) giải quyết triệt để tranh chấp suất học giữa 2 học viên A và B:")
    p_image(doc, "task2_seq_concurrency_lock.png", "Hình 2.5: Biểu đồ Sequence xử lý tranh chấp giữ chỗ lớp học (Pessimistic Guarded Lock)", width_inches=6.0)

    out_path = os.path.join(DOCS_DIR, "Task2_Process_View.docx")
    doc.save(out_path)
    print(f"Task 2 DOCX built: {out_path}")

# ==============================================================================
# BUILD TASK 3
# ==============================================================================
def build_task3():
    doc = create_doc()
    p_title(doc, "BÀI TẬP TRÊN LỚP SỐ 3 - THIẾT KẾ CÁC KHUNG NHÌN KIẾN TRÚC\nTASK #3: THIẾT KẾ VIEW KIẾN TRÚC CÀI ĐẶT (IMPLEMENTATION VIEWS)\nHỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ")

    p_h1(doc, "1. Mô tả cách tổ chức các đối tượng và mối quan hệ giữa các đối tượng lúc cài đặt code")
    p_body(doc, "Để phục vụ cho lập trình viên cài đặt mã nguồn chuẩn xác, hệ thống LMS Trung tâm Ngoại ngữ áp dụng mô hình phân rã module chuẩn: Feature-First Clean Architecture trên Client (Flutter) và Module-Based Layered Architecture trên Server (NestJS):")
    
    p_h2(doc, "1.1. Cấu trúc tổ chức mã nguồn phía Client (Flutter)")
    p_bullet(doc, "Chứa hạ tầng mạng dùng chung (cấu hình Dio Client, Interceptors gắn JWT token tự động), bộ theme màu sắc, bộ định dạng tiền tệ VND, ngày giờ và các hằng số hệ thống.", "Thư mục lib/core/: ")
    p_bullet(doc, "Mỗi tính năng nghiệp vụ được đóng gói thành một thư mục khép kín gồm 3 tầng: Tầng Presentation (Screens, Widgets, BLoC quản lý trạng thái); Tầng Domain (Entities thuần Dart, Use Cases nghiệp vụ, Repository Interfaces); Tầng Data (DataSources gọi REST API, DTOs JSON, Repository Implementations).", "Thư mục lib/features/: ")
    p_bullet(doc, "Chứa các UI components dùng chung toàn ứng dụng như nút bấm AppButton, thanh phát âm thanh AudioPlayerBar, hộp thoại thông báo CustomDialog.", "Thư mục lib/shared/: ")

    p_h2(doc, "1.2. Cấu trúc tổ chức mã nguồn phía Backend (NestJS)")
    p_bullet(doc, "Chứa tệp schema.prisma - nguồn chân lý duy nhất (Single Source of Truth) định nghĩa cấu trúc 25+ bảng CSDL quan hệ và thư mục migrations quản lý lịch sử thay đổi.", "Thư mục prisma/: ")
    p_bullet(doc, "Chứa các chốt chặn an ninh: JwtAuthGuard (xác thực token), RolesGuard (kiểm tra quyền RBAC), HttpExceptionFilter (chuẩn hóa mã lỗi JSON) và ValidationPipe (kiểm tra tính hợp lệ của DTO đầu vào).", "Thư mục src/common/: ")
    p_bullet(doc, "Chứa PrismaService trừu tượng hóa toàn bộ kết nối và truy vấn CSDL PostgreSQL.", "Thư mục src/database/: ")
    p_bullet(doc, "Mỗi module nghiệp vụ (auth, classes, attendance, exams, finance, notifications) được tổ chức độc lập gồm: Controller (tiếp nhận HTTP request), Service (thực thi logic nghiệp vụ), DTOs (định nghĩa dữ liệu truyền tải) và Module definition.", "Thư mục src/modules/: ")

    p_h2(doc, "1.3. Nguyên tắc thiết kế khi cài đặt code")
    p_body(doc, "Mã nguồn tuân thủ nghiêm ngặt nguyên tắc Đảo ngược Phụ thuộc (Dependency Inversion Principle - DIP). Tầng điều khiển (Controller) và tầng nghiệp vụ (Service) chỉ phụ thuộc vào các giao diện trừu tượng (Interfaces), không phụ thuộc vào triển khai cụ thể của tầng lưu trữ. Nhờ vậy, khi thay đổi hệ quản trị CSDL hoặc thư viện giao diện, toàn bộ logic nghiệp vụ cốt lõi được bảo toàn tuyệt đối.")

    p_h1(doc, "2. Bảng ánh xạ Logical Classes sang Source Components (Theo Slide 41)")
    headers_map = ["Nhóm chức năng", "Tên Lớp trong Logical View", "Tệp mã nguồn vật lý (Source Component)", "Vai trò cài đặt cụ thể"]
    data_map = [
        ["Xác thực & Bảo mật", "User, StudentProfile, TeacherProfile", "src/modules/auth/entities/user.entity.ts\nprisma/schema.prisma", "Định nghĩa thuộc tính người dùng và lược đồ bảng dữ liệu người dùng."],
        ["Xác thực & Bảo mật", "AuthService, JwtAuthGuard", "src/modules/auth/auth.service.ts\nsrc/common/guards/jwt-auth.guard.ts", "Cài đặt logic băm mật khẩu bcrypt, phát hành JWT token và bảo vệ endpoint."],
        ["Xác thực & Bảo mật", "AuthController", "src/modules/auth/auth.controller.ts", "Định nghĩa các endpoint REST: /auth/login, /auth/first-login."],
        ["Quản lý Lớp & Lịch học", "Class, Session, Course, Room", "src/modules/classes/dto/create-class.dto.ts\nprisma/schema.prisma", "Định nghĩa DTO xác thực đầu vào và bảng quan hệ lớp học, phòng học."],
        ["Quản lý Lớp & Lịch học", "ClassService", "src/modules/classes/classes.service.ts", "Cài đặt thuật toán tự sinh các buổi học (sessions) và kiểm tra chống trùng lịch."],
        ["Quản lý Lớp & Lịch học", "ClassController", "src/modules/classes/classes.controller.ts", "Định nghĩa các endpoint quản lý lớp học và xuất thời khóa biểu."],
        ["Điểm danh & Chuyên cần", "AttendanceRecord", "src/modules/attendance/dto/mark-attendance.dto.ts", "Cấu trúc dữ liệu ghi nhận điểm danh (status, note)."],
        ["Điểm danh & Chuyên cần", "AttendanceService", "src/modules/attendance/attendance.service.ts", "Ghi nhận điểm danh vào CSDL và phát sinh sự kiện thông báo phụ huynh."],
        ["Điểm danh & Chuyên cần", "AttendanceController", "src/modules/attendance/attendance.controller.ts", "Tiếp nhận yêu cầu điểm danh từ ứng dụng di động giáo viên."],
        ["Bài tập & Luyện nói", "Assignment, AssignmentSubmission", "src/modules/assignments/assignments.service.ts", "Quản lý giao bài tập và xử lý liên kết file âm thanh ghi âm nộp bài."],
        ["Bài tập & Luyện nói", "UploadService", "src/modules/upload/upload.service.ts", "Cung cấp interface tải file ghi âm lên Google Firebase Cloud Storage."],
        ["Thi online & Chấm điểm", "Exam, ExamQuestion, ExamAttempt", "src/modules/exams/exams.service.ts\nsrc/modules/exams/scoring.service.ts", "Cài đặt bộ đếm giờ server, thuật toán tự động so khớp đáp án trắc nghiệm."],
        ["Thi online & Chấm điểm", "ExamController", "src/modules/exams/exams.controller.ts", "Định nghĩa endpoint nộp bài thi /exams/:id/submit."],
        ["Học phí & Thanh toán", "Invoice, PaymentReceipt", "src/modules/finance/finance.service.ts", "Quản lý công nợ học phí, tự động tính tổng tiền khi xếp lớp."],
        ["Học phí & Thanh toán", "VNPayService", "src/modules/finance/vnpay.service.ts", "Khởi tạo URL thanh toán VNPay và kiểm tra chữ ký SHA-512."],
        ["Học phí & Thanh toán", "FinanceController", "src/modules/finance/finance.controller.ts", "Endpoint tiếp nhận Webhook đối soát IPN từ cổng thanh toán."],
        ["Thông báo & Tác vụ nền", "NotificationService, QueueEngine", "src/modules/notifications/notifications.consumer.ts\nsrc/modules/notifications/fcm.service.ts", "Tiến trình công nhân lắng nghe Bull Queue và gọi FCM API bắn thông báo."],
        ["Giao diện Client Mobile", "LoginScreen, ExamScreen, ExamBloc", "lib/features/exams/presentation/exam_screen.dart\nlib/features/exams/presentation/exam_bloc.dart", "Giao diện làm bài thi trực tuyến và khối quản lý trạng thái Reactive BLoC."]
    ]
    p_table(doc, headers_map, data_map, col_widths=[1.3, 1.6, 1.8, 1.5])

    p_h1(doc, "3. Phân loại ba nhóm Component chuẩn UML (Theo Slide 25)")
    p_bullet(doc, "Toàn bộ mã nguồn do lập trình viên trực tiếp xây dựng: các tệp .dart (Screens, BLoC), các tệp .ts (Controllers, Services), tệp schema.prisma và các tệp cấu hình .env.", "Work product components (Thành phần phát triển): ")
    p_bullet(doc, "Các gói phần mềm hoàn chỉnh đủ để hệ thống thực thi: lms_mobile_app.apk (bản cài đặt Android), lms_web_portal/ (bản web tĩnh), dist/main.js (backend JavaScript đã biên dịch), các thư viện phụ thuộc trong node_modules và Docker containers.", "Deployment components (Thành phần triển khai): ")
    p_bullet(doc, "Các thực thể đối tượng chỉ tồn tại trong bộ nhớ RAM lúc tiến trình đang chạy: Pool kết nối PrismaClient, Kết nối Redis Socket, Đối tượng NestApplication lắng nghe cổng 3000.", "Execution components (Thành phần lúc chạy): ")

    p_h1(doc, "4. Các biểu đồ UML Component View")
    
    p_h2(doc, "4.1. Biểu đồ phụ thuộc mã nguồn giữa các tệp (Slide 42)")
    p_body(doc, "Biểu diễn các tệp mã nguồn nguyên bản («source» components) và quan hệ phụ thuộc «import» giữa các tầng Controller -> Service -> Repository / Prisma:")
    p_image(doc, "task3_source_dependency.png", "Hình 3.1: Biểu đồ phụ thuộc mã nguồn giữa các tệp (Source Code Dependency Diagram)", width_inches=6.0)

    p_h2(doc, "4.2. Biểu đồ Component phân tầng với Interfaces (Slide 28)")
    p_body(doc, "Mô tả vai trò của Interface như chất keo liên kết giữa các thành phần phần mềm. Thể hiện các giao diện cốt lõi: ICoreService, IDataPersistence, INotificationQueue, IPaymentProvider:")
    p_image(doc, "task3_component_interfaces.png", "Hình 3.2: Biểu đồ Component phân tầng liên kết qua Interface (Lollipop / Socket)", width_inches=6.0)

    p_h2(doc, "4.3. Biểu đồ Bản phát hành thực thi (Slide 43)")
    p_body(doc, "Mô tả cách thức các tệp thực thi cuối cùng («executable») liên kết («link») với các thư viện nhị phân («binary», «library»):")
    p_image(doc, "task3_executable_release.png", "Hình 3.3: Biểu đồ Bản phát hành thực thi (Executable Release Diagram)", width_inches=5.8)

    p_h2(doc, "4.4. Biểu đồ Phân tích tác động khi thay đổi mã nguồn (Slide 30)")
    p_body(doc, "Mô tả quy trình lần vết và phạm vi ảnh hưởng khi cập nhật tệp định nghĩa CSDL schema.prisma (thêm trường maxStudents): Kích hoạt biên dịch lại @prisma/client -> cập nhật DTO -> sửa Service -> biên dịch lại Controller -> build lại file thực thi backend -> cập nhật Model và UI trên Client:")
    p_image(doc, "task3_change_impact.png", "Hình 3.4: Biểu đồ phân tích tác động khi thay đổi mã nguồn (Change Impact Analysis)", width_inches=5.6)

    out_path = os.path.join(DOCS_DIR, "Task3_Implementation_View.docx")
    doc.save(out_path)
    print(f"Task 3 DOCX built: {out_path}")

# ==============================================================================
# BUILD TASK 4
# ==============================================================================
def build_task4():
    doc = create_doc()
    p_title(doc, "BÀI TẬP TRÊN LỚP SỐ 3 - THIẾT KẾ CÁC KHUNG NHÌN KIẾN TRÚC\nTASK #4: THIẾT KẾ VIEW KIẾN TRÚC TRIỂN KHAI / VẬT LÝ (DEPLOYMENT VIEWS)\nHỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ")

    p_h1(doc, "1. Thể hiện các Node phần cứng trong hệ thống")
    p_body(doc, "Hệ thống LMS Trung tâm Ngoại ngữ được cấu hình trên mô hình hạ tầng mạng đa phân vùng, bao gồm 7 Node tính toán và môi trường thực thi chuyên trách:")
    p_bullet(doc, "Thiết bị di động của Học viên, Giáo viên và Phụ huynh; xử lý giao diện di động và thu âm bài nói.", "Node 1: Mobile Client Devices - ")
    p_bullet(doc, "Máy tính trạm để bàn của Quản trị viên, Nhân viên học vụ và Thu ngân tại trung tâm; hiển thị màn hình web độ phân giải cao phục vụ xếp lịch và quản lý tài chính.", "Node 2: Admin Workstation - ")
    p_bullet(doc, "Máy chủ Nginx đặt tại phân vùng mạng vành đai (DMZ); làm nhiệm vụ tiếp nhận toàn bộ lưu lượng Internet, giải mã SSL/TLS 1.3 và phân phối tải.", "Node 3: Edge Reverse Proxy & Load Balancer Server - ")
    p_bullet(doc, "Máy chủ dịch vụ nội bộ chạy Docker Engine; lưu trữ và thực thi các container NestJS API Server và Background Worker.", "Node 4: Application Server Host - ")
    p_bullet(doc, "Máy chủ bộ nhớ đệm In-memory Redis Server; quản lý phiên làm việc, hàng đợi công việc Bull Queue và khóa phân tán.", "Node 5: In-Memory Cache Server - ")
    p_bullet(doc, "Máy chủ cơ sở dữ liệu quan hệ PostgreSQL 16; quản lý dữ liệu bền vững chuẩn ACID, trang bị mảng đĩa cứng NVMe cấu hình RAID-10.", "Node 6: Primary Database Server - ")
    p_bullet(doc, "Dịch vụ Firebase Cloud Messaging (bắn push notification thời gian thực), Firebase Cloud Storage (lưu trữ file âm thanh và PDF) và Cổng thanh toán trực tuyến VNPay.", "Node 7 & Node 8: External Cloud Platforms - ")

    p_h1(doc, "2. Thông tin chi tiết và các thành phần phần mềm trên mỗi Node (Slide 34, 35)")
    
    p_h2(doc, "2.1. Node 1: «device» Mobile Client Device")
    p_bullet(doc, "CPU Quad-Core 1.8 GHz (ARM64), RAM tối thiểu 2 GB (khuyến nghị 4 GB), lưu trữ khả dụng 500 MB; trang bị Microphone, Camera, Loa ngoài; Hệ điều hành Android 8.0+ hoặc iOS 13.0+; Kết nối 4G/5G hoặc Wi-Fi.", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys lms_mobile_app.apk (Android) / lms_mobile_app.ipa (iOS); Deploys SQLite Local Storage (lưu cache bài học và đáp án thi offline); Deploys Firebase Messaging SDK (nhận push notification).", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.2. Node 2: «device» Admin Workstation")
    p_bullet(doc, "CPU Intel Core i3 / AMD Ryzen 3 trở lên, RAM tối thiểu 4 GB (khuyến nghị 8 GB), Màn hình Full HD (1920x1080); Hệ điều hành Windows 10/11 hoặc macOS; Trình duyệt Google Chrome, Edge, Safari.", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys lms_web_portal (chạy trên trình duyệt Web qua môi trường DOM và V8 JavaScript Engine).", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.3. Node 3: «processor» S1 :ReverseProxyServer [Phân vùng DMZ]")
    p_bullet(doc, "Địa chỉ IP tĩnh Public; CPU 2 vCPU Intel Xeon 2.4 GHz, RAM 2 GB DDR4, Ổ cứng 20 GB SSD NVMe; Hệ điều hành Ubuntu Server 22.04 LTS; Cổng mở công khai 80 (chuyển hướng HTTPS) và 443 (HTTPS/WSS).", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys Nginx 1.24 (bộ cân bằng tải và giải mã SSL/TLS 1.3); Deploys Certbot SSL Manager (tự động gia hạn chứng chỉ số); Deploys tài nguyên tĩnh /web_dist; Deploys tường lửa UFW.", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.4. Node 4: «processor» S2 :ApplicationServer [Phân vùng Private LAN]")
    p_bullet(doc, "Địa chỉ IP nội bộ 10.0.1.10 (không công khai ra Internet); CPU 4 vCPU 3.0 GHz, RAM 8 GB ECC DDR4, Ổ cứng 80 GB SSD NVMe; Hệ điều hành Ubuntu 22.04 LTS với Docker Engine 24.x; Cổng nội bộ 3000 (API), 3001 (WebSocket).", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys lms_api_server_container (chạy tệp dist/main.js NestJS); Deploys lms_background_worker_container (chạy tệp dist/worker.js xử lý Bull Queue); Deploys prisma_query_engine.so.", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.5. Node 5: «processor» S3 :CacheServer [Phân vùng Database LAN]")
    p_bullet(doc, "Địa chỉ IP nội bộ 10.0.1.20; CPU 2 vCPU 2.8 GHz, RAM 4 GB High-Speed RAM, Ổ cứng 30 GB SSD; Hệ điều hành Alpine Linux; Cổng nội bộ 6379 (bảo vệ bằng mật khẩu requirepass).", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys Redis Server 7.2 (quản lý session store, hàng đợi công việc bull_job_queue và khóa phân tán distributed_lock).", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.6. Node 6: «processor» S4 :DatabaseServer [Phân vùng Database LAN]")
    p_bullet(doc, "Địa chỉ IP nội bộ 10.0.1.30 (cô lập tuyệt đối với Internet); CPU 4 vCPU 3.2 GHz, RAM 8 GB ECC DDR4 (4GB cho shared_buffers), Ổ cứng 150 GB Enterprise NVMe SSD cấu hình mảng đĩa RAID-10 (đảm bảo tốc độ I/O và dung sai hỏng đĩa); Hệ điều hành RHEL 9 / Ubuntu 22.04; Cổng nội bộ 5432 (chỉ mở cho IP 10.0.1.10 qua pg_hba.conf).", "Thông số phần cứng: ")
    p_bullet(doc, "Deploys PostgreSQL 16.2 Engine; Deploys lms_production_db (25+ bảng dữ liệu quan hệ); Deploys wal_continuous_archiver (sao lưu nhật ký giao dịch liên tục).", "Thành phần triển khai (Deploys): ")

    p_h2(doc, "2.7. Node 7 & 8: «cloud environment» External Cloud Services")
    p_bullet(doc, "Hạ tầng đám mây Google: Deploys Firebase Cloud Messaging (cụm máy chủ duy trì socket ngầm bắn push notification đến điện thoại phụ huynh); Deploys Firebase Cloud Storage (lưu trữ tệp âm thanh ghi âm phát âm .m4a, bài nghe .mp3, giáo trình .pdf, giúp giảm tải 95% ổ cứng máy chủ nội bộ).", "Google Firebase Platform: ")
    p_bullet(doc, "Hạ tầng thanh toán VNPay: Deploys VNPay Payment Gateway tiếp nhận giao dịch thẻ ATM/Visa/QR; phản hồi kết quả đối soát qua Webhook IPN an toàn bằng chữ ký HMAC SHA-512.", "VNPay Payment Gateway: ")

    p_h1(doc, "3. Mối quan hệ và Giao thức truyền thông giữa các Node")
    headers_proto = ["Nguồn -> Đích", "Giao thức truyền thông", "Cổng (Port)", "Định dạng dữ liệu", "Biện pháp bảo mật & Ràng buộc"]
    data_proto = [
        ["Mobile -> Reverse Proxy", "HTTPS (TLS 1.3)", "443", "JSON (REST API)", "Mã hóa đường truyền; xác thực người dùng bằng JWT Bearer Token."],
        ["Mobile -> Reverse Proxy", "WSS (WebSocket Secure)", "443", "JSON (Socket frame)", "Kết nối 2 chiều thời gian thực cập nhật đồng hồ thi và thông báo."],
        ["Admin PC -> Reverse Proxy", "HTTPS (TLS 1.3)", "443", "HTML, CSS, JS, JSON", "Tải giao diện quản trị Web Portal qua đường truyền mã hóa."],
        ["Reverse Proxy -> App Server", "HTTP (Nội bộ LAN)", "3000", "JSON Forwarded", "Chuyển tiếp sau khi giải mã SSL; bổ sung X-Forwarded-For ghi vết IP."],
        ["App Server -> PostgreSQL", "TCP/IP (Postgres Wire)", "5432", "SQL Binary Protocol", "Mạng LAN riêng tư; khóa cổng bằng pg_hba.conf; mật khẩu SCRAM-SHA-256."],
        ["App Server -> Redis Server", "TCP/IP (RESP Protocol)", "6379", "Chuỗi nhị phân Redis", "Mạng LAN riêng tư; xác thực mật khẩu requirepass; độ trễ < 1ms."],
        ["App Server -> Firebase Cloud", "HTTPS / REST", "443", "Admin Protobuf/JSON", "Xác thực bằng Google Service Account Private Key."],
        ["App Server -> VNPay Gateway", "HTTPS / REST", "443", "URL-encoded / JSON", "Kiểm định tính toàn vẹn giao dịch tài chính bằng chữ ký HMAC SHA-512."],
        ["Mobile App -> Firebase Storage", "HTTPS / CDN", "443", "Audio Binary (AAC/MP3)", "Tải trực tiếp file âm thanh nghe/nói qua chữ ký an toàn có thời hạn (Signed URLs)."]
    ]
    p_table(doc, headers_proto, data_proto, col_widths=[1.5, 1.3, 0.7, 1.3, 1.4])

    p_h1(doc, "4. Biểu đồ Triển khai (Deployment Diagram) tổng thể")
    p_body(doc, "Biểu đồ dưới đây được thiết kế theo chuẩn UML 2.5 với các nút lập phương 3D thể hiện thuộc tính kỹ thuật, danh sách artifact phần mềm và các đường truyền mạng:")
    p_image(doc, "task4_deployment_diagram.png", "Hình 4.1: Biểu đồ Triển khai UML tổng thể hệ thống LMS Trung tâm Ngoại ngữ", width_inches=6.3)

    p_h2(doc, "4.1. Sơ đồ phân tầng mạng bảo mật 3 lớp (DMZ Architecture)")
    p_body(doc, "Hạ tầng được bảo vệ bằng mô hình 3 lớp phân vùng mạng: Lớp 1 (Public DMZ với Nginx tiếp nhận 80/443), Lớp 2 (Internal Application LAN chạy API), Lớp 3 (Isolated Database LAN cô lập tuyệt đối CSDL khỏi Internet):")
    p_image(doc, "task4_network_architecture.png", "Hình 4.2: Sơ đồ kiến trúc phân tầng mạng bảo mật 3 lớp DMZ", width_inches=6.0)

    p_h2(doc, "4.2. Mối quan hệ ăn khớp giữa 4 khung nhìn kiến trúc (Slide 45)")
    p_body(doc, "Bốn khung nhìn kiến trúc trong đồ án được thiết kế ăn khớp chặt chẽ và nhất quán với nhau:")
    p_image(doc, "task4_views_alignment.png", "Hình 4.3: Mối quan hệ ăn khớp giữa 4 khung nhìn kiến trúc theo mô hình 4+1", width_inches=5.8)

    p_body(doc, "Bảng đối chiếu tổng hợp 4 khung nhìn kiến trúc (Slide 45):", bold_prefix="Đối chiếu tổng hợp: ")
    headers_4v = ["Khung nhìn", "Câu hỏi trả lời", "Phần tử cốt lõi", "Sơ đồ UML sử dụng", "Thể hiện trong hệ thống LMS"]
    data_4v = [
        ["Logical View (Task #1)", "Hệ thống cung cấp chức năng gì cho người dùng?", "Class, Object, Package, Quan hệ", "Class Diagram, State Diagram", "23 Lớp nghiệp vụ (User, Class, Exam, Invoice); Vòng đời Lớp học và Vòng đời Bài thi."],
        ["Process View (Task #2)", "Hệ thống chạy đồng thời và đồng bộ thế nào lúc runtime?", "Process, Thread, Active Object, IPC", "Active Class Diagram, Sequence Diagram", "6 Tiến trình (P1-P6); Cơ chế Guarded Lock giữ chỗ và mô hình kết hợp Sync điểm danh + Async FCM queue."],
        ["Implementation View (Task #3)", "Mã nguồn, thư viện và file thực thi tổ chức ra sao?", "Component, Interface, Dependency", "Component Diagram", "Clean Architecture & NestJS Modules; bảng ánh xạ sang *.ts/*.dart; sơ đồ «import» và «link» ra .apk, main.js."],
        ["Deployment View (Task #4)", "Phần mềm được đặt lên phần cứng nào?", "Node, Kết nối mạng, Distribution Unit", "Deployment Diagram", "7 Nút tính toán (Mobile, Web PC, Reverse Proxy, App Server, Cache, DB, Cloud); phân vùng 3 lớp DMZ; RAID-10."]
    ]
    p_table(doc, headers_4v, data_4v, col_widths=[1.2, 1.4, 1.2, 1.2, 1.2])

    out_path = os.path.join(DOCS_DIR, "Task4_Deployment_View.docx")
    doc.save(out_path)
    print(f"Task 4 DOCX built: {out_path}")

if __name__ == "__main__":
    build_task1()
    build_task2()
    build_task3()
    build_task4()
    print("All 4 clean DOCX files generated successfully!")
