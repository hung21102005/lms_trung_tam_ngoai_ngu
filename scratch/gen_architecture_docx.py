import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

doc = docx.Document()

# 1. Page Margins (Tiêu chuẩn đồ án: Trái 3cm, Phải 2cm, Trên 2cm, Dưới 2cm)
for section in doc.sections:
    section.top_margin = Inches(0.79)     # 2.0 cm
    section.bottom_margin = Inches(0.79)  # 2.0 cm
    section.left_margin = Inches(1.18)    # 3.0 cm
    section.right_margin = Inches(0.79)   # 2.0 cm

# Colors
PRIMARY = RGBColor(26, 82, 118)     # Deep Blue
SECONDARY = RGBColor(41, 128, 185)  # Accent Blue
DARK_GRAY = RGBColor(44, 62, 80)
TEXT_COLOR = RGBColor(33, 33, 33)

def set_para_font(p, name="Times New Roman", size=12, bold=False, italic=False, color=TEXT_COLOR):
    for r in p.runs:
        r.font.name = name
        r.font.size = Pt(size)
        r.bold = bold
        r.italic = italic
        r.font.color.rgb = color

def add_title(text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(20)
    r.bold = True
    r.font.color.rgb = PRIMARY
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(6)

def add_subtitle(text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(14)
    r.bold = True
    r.font.color.rgb = SECONDARY
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(14)

def add_h1(text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(15)
    r.bold = True
    r.font.color.rgb = PRIMARY
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)

def add_h2(text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(13)
    r.bold = True
    r.font.color.rgb = SECONDARY
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(3)

def add_h3(text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(12)
    r.bold = True
    r.italic = True
    r.font.color.rgb = DARK_GRAY
    p.paragraph_format.space_before = Pt(6)
    p.paragraph_format.space_after = Pt(2)

def add_body(text, bold_prefix="", space_after=4):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_after = Pt(space_after)
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Times New Roman"
        r_pre.font.size = Pt(12)
        r_pre.bold = True
        r_pre.font.color.rgb = TEXT_COLOR
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(12)
    r.font.color.rgb = TEXT_COLOR
    return p

def add_bullet(text, bold_prefix=""):
    p = doc.add_paragraph(style='List Bullet')
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.space_after = Pt(2)
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Times New Roman"
        r_pre.font.size = Pt(12)
        r_pre.bold = True
        r_pre.font.color.rgb = TEXT_COLOR
    r = p.add_run(text)
    r.font.name = "Times New Roman"
    r.font.size = Pt(12)
    r.font.color.rgb = TEXT_COLOR
    return p

def set_cell_border(cell, **kwargs):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(r'''
        <w:tcBorders xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:top w:val="single" w:sz="4" w:space="0" w:color="BDC3C7"/>
            <w:left w:val="single" w:sz="4" w:space="0" w:color="BDC3C7"/>
            <w:bottom w:val="single" w:sz="4" w:space="0" w:color="BDC3C7"/>
            <w:right w:val="single" w:sz="4" w:space="0" w:color="BDC3C7"/>
        </w:tcBorders>
    ''')
    tcPr.append(tcBorders)

def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def add_box(title, lines, fill_hex="F2F4F4"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    tbl.columns[0].width = Inches(6.4)
    cell = tbl.cell(0, 0)
    set_cell_background(cell, fill_hex)
    set_cell_border(cell)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(2)
    r_t = p.add_run(title)
    r_t.font.name = "Times New Roman"
    r_t.font.size = Pt(12)
    r_t.bold = True
    r_t.font.color.rgb = PRIMARY
    
    for l in lines:
        p2 = cell.add_paragraph()
        p2.paragraph_format.space_before = Pt(0)
        p2.paragraph_format.space_after = Pt(2)
        p2.paragraph_format.line_spacing = 1.15
        r2 = p2.add_run(l)
        r2.font.name = "Consolas"
        r2.font.size = Pt(10)
        r2.font.color.rgb = TEXT_COLOR
        
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_image_diagram(image_path, caption, width=Inches(6.3)):
    if os.path.exists(image_path):
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(4)
        run = p.add_run()
        run.add_picture(image_path, width=width)
        
        p_cap = doc.add_paragraph()
        p_cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_cap.paragraph_format.space_before = Pt(2)
        p_cap.paragraph_format.space_after = Pt(10)
        r_cap = p_cap.add_run(caption)
        r_cap.font.name = "Times New Roman"
        r_cap.font.size = Pt(11)
        r_cap.bold = True
        r_cap.italic = True
        r_cap.font.color.rgb = PRIMARY

print("Starting document creation...")

# Header info
add_title("BÁO CÁO THIẾT KẾ KIẾN TRÚC PHẦN MỀM (TASK #1)")
add_subtitle("ĐỀ TÀI: XÂY DỰNG HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ")

meta_lines = [
    "Môn học: Kiến trúc Phần mềm / Phân tích Thiết kế Hệ thống",
    "Đối tượng phục vụ: Trung tâm Ngoại ngữ (Admin, Học vụ, Thu ngân, Giáo viên, Học viên, Phụ huynh)",
    "Nền tảng công nghệ: Flutter (Dart) · NestJS (TypeScript) · PostgreSQL 16 · Redis 7 · Firebase Services",
    "Ngày thực hiện: 09/10/2026"
]
add_box("📋 THÔNG TIN BÀI TẬP", meta_lines, "EAF2F8")

# 1. BỐI CẢNH
add_h1("1. BỐI CẢNH NGHIỆP VỤ & CƠ SỞ LỰA CHỌN KIẾN TRÚC")
add_body("Hệ thống Quản lý Học tập (LMS) dành cho trung tâm ngoại ngữ là giải pháp chuyển đổi số toàn diện các hoạt động học vụ và đào tạo ngoại ngữ (tiếng Anh, tiếng Nhật, tiếng Hàn, tiếng Trung,...). Hệ thống phục vụ 5 nhóm người dùng chính trên nhiều nền tảng:")
add_bullet("Sử dụng Web Portal màn hình lớn để quản lý danh mục khóa học, thiết lập lớp học, phân bổ phòng/giáo viên, kiểm tra phòng trống, theo dõi công nợ học phí và xử lý học bù.", "• Quản trị viên, Học vụ, Thu ngân: ")
add_bullet("Sử dụng Mobile App và Web để điểm danh nhanh tại lớp, giao bài tập về nhà, chấm bài phát âm (nghe file âm thanh ghi âm giọng nói của học viên), nhập điểm và nhận xét.", "• Giáo viên: ")
add_bullet("Sử dụng Mobile App để xem thời khóa biểu, làm bài kiểm tra trực tuyến có bộ đếm ngược chống gian lận, nộp bài phát âm (thu âm trực tiếp trên app), theo dõi chuyên cần và thanh toán học phí qua VNPay.", "• Học viên: ")
add_bullet("Sử dụng Mobile App để theo dõi lịch học, kết quả học tập và nhận thông báo đẩy tức thời ngay khi con vắng học.", "• Phụ huynh: ")

add_body("Các yêu cầu nghiệp vụ và kỹ thuật đặc thù ảnh hưởng trực tiếp đến kiến trúc hệ thống gồm có:", bold_prefix="Đặc trưng cốt lõi: ")
add_bullet("Dữ liệu về lớp học, phòng học, học viên, kết quả học tập và hóa đơn học phí liên kết chặt chẽ; bắt buộc phải thỏa mãn tính toàn vẹn và nguyên tắc ACID của cơ sở dữ liệu quan hệ.", "1. Dữ liệu quan hệ chặt chẽ và nhất quán cao: ")
add_bullet("Học viên và phụ huynh KHÔNG tự do đăng ký tài khoản mà do trung tâm cấp phát chính thức sau khi nhập học, đảm bảo tài khoản gắn đúng mã học viên, lớp học và khóa học.", "2. Cấp phát tài khoản tập trung: ")
add_bullet("Hệ thống đào tạo ngôn ngữ đòi hỏi xử lý dung lượng lớn file âm thanh (bài nghe, bài nói phát âm MP3/M4A), tài liệu PDF và video bài giảng.", "3. Xử lý đa phương tiện (Multimedia): ")
add_bullet("Hệ thống đòi hỏi phản hồi tức thời các sự kiện: Giáo viên điểm danh vắng -> Bắn notification báo phụ huynh ngay; Hết giờ làm bài -> Hệ thống tự động thu bài; Webhook thanh toán VNPay thành công -> Cập nhật hóa đơn tự động.", "4. Xử lý thời gian thực và bất đồng bộ: ")

# 2. XÁC ĐỊNH MẪU KIẾN TRÚC
add_h1("2. XÁC ĐỊNH CÁC MẪU KIẾN TRÚC PHẦN MỀM ĐƯỢC CHỌN (YÊU CẦU a)")

add_h2("2.1. Mẫu kiến trúc chính (Primary Architecture Pattern)")
add_body("Đề tài lựa chọn kết hợp hai mẫu kiến trúc chính ở hai cấp độ thiết kế:")

add_body("Hệ thống phục vụ đa dạng thiết bị đầu cuối (Mobile App Android/iOS và Web Browser máy tính). Mô hình Khách - Chủ phân tách rành mạch trách nhiệm giữa bên yêu cầu (Client) và bên cung cấp/xử lý tài nguyên (Server). Toàn bộ dữ liệu nhạy cảm, thuật toán tính điểm, phân quyền RBAC và kiểm soát tài khoản tập trung đều được đóng gói an toàn tại máy chủ trung tâm. Giao tiếp giữa Client và Server được chuẩn hóa qua giao thức HTTPS (RESTful JSON APIs) và WSS (WebSocket).", bold_prefix="1. Cấp độ toàn hệ thống (System-level): Client-Server Architecture Pattern (Mô hình Khách - Chủ đa nền tảng). ")

add_body("Cả hai đầu Client (Flutter) và Server (NestJS) đều được tổ chức theo kiến trúc phân tầng Clean Architecture / N-Tier. Mã nguồn được chia thành các lớp có trách nhiệm độc lập: Presentation Layer (Giao diện/Controller) -> Business Logic Layer (Use Cases/Services) -> Data Access Layer (Repositories/Prisma ORM) -> Database Layer. Việc phân tầng giúp hệ thống có tính độc lập cao, dễ bảo trì, dễ viết kiểm thử tự động (Unit Test), và việc nâng cấp một tầng không làm ảnh hưởng đến các tầng khác.", bold_prefix="2. Cấp độ cấu trúc mã nguồn (Code-level): Layered Architecture Pattern (Kiến trúc phân tầng N-tier & Clean Architecture). ")

add_h2("2.2. Các mẫu kiến trúc hỗ trợ, bổ sung (Supporting Architecture Patterns)")
add_body("Để giải quyết các bài toán phi chức năng đặc thù (thông báo tức thời, luồng xử lý audio, hàng đợi nền), hệ thống kết hợp 3 mẫu kiến trúc bổ trợ:")

add_bullet("Áp dụng trong cơ chế thông báo và kích hoạt sự kiện tự động. Ví dụ: Khi Giáo viên hoàn tất điểm danh và có học viên vắng, sự kiện 'AttendanceCompletedEvent' được phát ra. Event Listener bắt sự kiện và đẩy sang dịch vụ FCM bắn thông báo cho phụ huynh trong nền, giúp giao diện điểm danh của giáo viên phản hồi ngay lập tức mà không bị nghẽn mạng.", "1. Event-Driven Architecture Pattern (Kiến trúc hướng sự kiện - EDA): ")

add_bullet("Áp dụng trong chuỗi xử lý Request/Response của NestJS: Request từ client đi qua đường ống gồm nhiều bộ lọc kế tiếp nhau (CORS -> JwtAuthGuard -> RolesGuard -> ValidationPipe -> Controller -> TransformInterceptor -> Response). Ngoài ra, luồng xử lý file ghi âm bài nói cũng áp dụng đường ống: Nhận file -> Kiểm tra định dạng (Audio/PDF) -> Giới hạn dung lượng (<50MB) -> Upload Cloud Storage -> Trả về Signed URL an toàn.", "2. Pipe-Filter Architecture Pattern (Kiến trúc đường ống và bộ lọc): ")

add_bullet("Sử dụng Redis làm Message Broker kết hợp Bull Queue điều phối các tác vụ nặng: gửi hàng loạt email thông báo lịch học, gửi broadcast thông báo toàn trung tâm, xuất báo cáo tài chính/học vụ Excel và PDF dung lượng lớn, giải phóng tài nguyên cho luồng xử lý API chính.", "3. Broker Architecture Pattern (Kiến trúc điều phối thông điệp / Message Broker): ")

# 3. BIỂU ĐỒ TRỰC QUAN
add_h1("3. BIỂU ĐỒ MÔ TẢ TRỰC QUAN CÁC KIẾN TRÚC (YÊU CẦU b)")

def get_diagram_path(filename):
    p1 = os.path.join("docs", "diagrams", filename)
    if os.path.exists(p1):
        return p1
    p2 = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "diagrams", filename)
    if os.path.exists(p2):
        return p2
    return p1

add_h2("3.1. Sơ đồ khối tổng thể Hệ thống (Client-Server Architecture)")
add_body("Sơ đồ khối mô tả sự phân tách rõ rệt giữa Tầng máy khách (Client Layer) đa nền tảng gồm Mobile App (Học viên, Phụ huynh, Giáo viên) và Web Admin Portal với Tầng máy chủ tập trung (NestJS Server Layer), kết nối tới Cơ sở dữ liệu quan hệ PostgreSQL 16, Redis 7 In-memory Cache & Broker, cùng các dịch vụ Cloud bên ngoài (Firebase Cloud Messaging, Cloud Storage, Cổng thanh toán VNPay):")
add_image_diagram(get_diagram_path("diagram1_client_server.png"), "Hình 3.1: Sơ đồ khối kiến trúc Máy khách - Máy chủ đa nền tảng (Client-Server Architecture)")

add_h2("3.2. Sơ đồ phân tầng chi tiết (Layered & Clean Architecture)")
add_body("Sơ đồ phân tầng thể hiện cấu trúc mã nguồn theo mô hình Clean Architecture & N-Tier áp dụng song song ở cả hai đầu ứng dụng. Phía Client (Flutter) chia tách thành Presentation (Screens & BLoC) -> Domain (Use Cases & Entities) -> Data (Data Sources & Dio Client). Phía Server (NestJS) chia tách thành Presentation (Controllers & DTOs) -> Business Logic (Services & RBAC) -> Data Access (Prisma ORM) -> Database (PostgreSQL 16):")
add_image_diagram(get_diagram_path("diagram2_layered.png"), "Hình 3.2: Sơ đồ phân tầng Clean Architecture trên Client (Flutter) và Server (NestJS)")

add_h2("3.3. Sơ đồ luồng xử lý hướng sự kiện (Event-Driven & Message Broker)")
add_body("Sơ đồ luồng thể hiện kiến trúc hướng sự kiện (EDA) kết hợp Message Broker (Redis & Bull Queue) cho ca sử dụng điển hình: Khi Giáo viên hoàn tất điểm danh tại lớp, hệ thống phát sinh sự kiện AttendanceCompletedEvent và xử lý bất đồng bộ qua hàng đợi tác vụ nền, kích hoạt Firebase Cloud Messaging (FCM) gửi thông báo đẩy tức thời tới điện thoại di động của phụ huynh mà không gây nghẽn tiến trình điểm danh:")
add_image_diagram(get_diagram_path("diagram3_event_driven.png"), "Hình 3.3: Sơ đồ luồng xử lý sự kiện (Event-Driven) & Hàng đợi Message Broker trong nghiệp vụ Điểm danh")

add_h2("3.4. Sơ đồ đường ống và bộ lọc (Pipe-Filter Architecture)")
add_body("Sơ đồ mô tả quy trình xử lý tuần tự qua đường ống (Pipeline) và chuỗi các bộ lọc chuyên biệt (Filters / Guards / Interceptors) trong NestJS cho mọi HTTP Request từ phía Client gửi lên máy chủ trước khi tiếp cận Business Logic Service và phản hồi JSON về Client:")
add_image_diagram(get_diagram_path("diagram4_pipe_filter.png"), "Hình 3.4: Sơ đồ đường ống và bộ lọc (Pipe-Filter Architecture) trong xử lý Request NestJS")

# 4. DANH SÁCH & MÔ TẢ THÀNH PHẦN
add_h1("4. DANH SÁCH & MÔ TẢ CHỨC NĂNG CÁC THÀNH PHẦN (YÊU CẦU c & d)")
add_body("Bảng tổng hợp chi tiết tất cả các thành phần (Components) cấu thành nên hệ thống LMS:")

tbl_comp = doc.add_table(rows=1, cols=4)
tbl_comp.alignment = WD_TABLE_ALIGNMENT.CENTER
tbl_comp.autofit = False

headers = ["STT", "Tên thành phần", "Kiến trúc", "Mô tả chức năng cụ thể"]
col_widths = [Inches(0.5), Inches(1.8), Inches(1.3), Inches(2.8)]

hdr_cells = tbl_comp.rows[0].cells
for i, h in enumerate(headers):
    hdr_cells[i].width = col_widths[i]
    set_cell_background(hdr_cells[i], "1A5276")
    p = hdr_cells[i].paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(h)
    r.font.name = "Times New Roman"
    r.font.size = Pt(11)
    r.bold = True
    r.font.color.rgb = RGBColor(255, 255, 255)

components_data = [
    ("1", "Flutter Mobile Client", "Client-Server", "Giao diện ứng dụng di động bản địa cho Học viên, Phụ huynh và Giáo viên; thực hiện điểm danh, làm bài thi online, ghi âm nộp bài nói và nhận push notification."),
    ("2", "Flutter Web Admin Portal", "Client-Server", "Giao diện quản trị web cho Admin, Học vụ và Thu ngân; quản lý chi nhánh, xếp thời khóa biểu, theo dõi công nợ, xuất báo cáo học vụ/doanh thu."),
    ("3", "BLoC State Manager", "Layered", "Điều phối luồng dữ liệu và trạng thái giao diện trên Client; phân tách hoàn toàn UI và Logic, đảm bảo phản hồi tức thì và không bị rebuild giao diện thừa."),
    ("4", "API Gateway & Router", "Client-Server", "Tiếp nhận toàn bộ yêu cầu HTTP từ client qua HTTPS, định tuyến tới các module chức năng, quản lý tiền tố `/api/v1/` và bảo mật CORS."),
    ("5", "Auth & RBAC Component", "Pipe-Filter / Layered", "Xác thực JWT token; áp dụng Role Guard kiểm tra quyền truy cập; xử lý nguyên tắc tài khoản cấp phát tập trung và kích hoạt đổi mật khẩu lần đầu."),
    ("6", "Academic Component", "Layered", "Quản lý khóa học, cấp độ, bài học; tạo lớp học, thuật toán tự sinh danh sách buổi học (sessions) và kiểm tra chống trùng lịch giáo viên/phòng học."),
    ("7", "Attendance & Makeup", "Layered / EDA", "Ghi nhận trạng thái điểm danh buổi học; phát sự kiện tự động bắn push báo phụ huynh khi vắng học; quản lý duyệt yêu cầu học bù."),
    ("8", "Assignment & Audio", "Layered / Pipe-Filter", "Quản lý bài tập; tiếp nhận bài nộp văn bản, file tài liệu và bản ghi âm bài nói; chuyển tiếp file lên Cloud Storage và chấm điểm phát âm."),
    ("9", "Online Exam Component", "Layered", "Quản lý ngân hàng câu hỏi (5 loại câu hỏi, gắn tag kỹ năng); kiểm soát đồng hồ đếm ngược phía server chống gian lận; tự động chấm trắc nghiệm."),
    ("10", "Finance & Invoices", "Layered", "Tự động sinh hóa đơn khi học viên xếp lớp; ghi nhận tiền mặt/chuyển khoản; tạo URL thanh toán VNPay và xử lý webhook xác thực chữ ký SHA-512."),
    ("11", "Notification & Queue", "Event-Driven / Broker", "Lắng nghe sự kiện hệ thống; đẩy job vào Redis Bull Queue để gửi push qua FCM, gửi email xác thực và email nhắc nợ học phí định kỳ."),
    ("12", "Prisma ORM (DAL)", "Layered", "Lớp trừu tượng hóa tương tác CSDL; thực thi các truy vấn Type-safe với TypeScript; quản lý database migration và các transaction ACID."),
    ("13", "PostgreSQL Database", "Client-Server", "Cơ sở dữ liệu quan hệ lưu trữ dữ liệu bền vững: 25+ bảng (người dùng, lớp học, điểm danh, đề thi, bài tập, hóa đơn thanh toán)."),
    ("14", "Redis Cache & Broker", "Broker / Cache", "Bộ nhớ đệm in-memory tốc độ cao để cache dữ liệu danh mục; đồng thời là Message Broker vận hành hàng đợi Bull Queue xử lý tác vụ nền."),
    ("15", "Firebase Cloud Messaging", "Client-Server", "Dịch vụ đám mây điều phối gửi thông báo đẩy thời gian thực trực tiếp đến màn hình khóa điện thoại Android và iOS."),
    ("16", "Firebase Storage", "Client-Server", "Lưu trữ đám mây phân tán cho file dung lượng lớn: file ghi âm nói (MP3/M4A), tài liệu học tập (PDF), hình ảnh bài thi và avatar.")
]

for row_data in components_data:
    row = tbl_comp.add_row()
    for col_idx, cell_value in enumerate(row_data):
        cell = row.cells[col_idx]
        cell.width = col_widths[col_idx]
        set_cell_border(cell)
        p = cell.paragraphs[0]
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.space_before = Pt(2)
        r = p.add_run(cell_value)
        r.font.name = "Times New Roman"
        r.font.size = Pt(10)
        r.font.color.rgb = TEXT_COLOR
        if col_idx == 0:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        elif col_idx in [1, 2]:
            r.bold = True

doc.add_paragraph().paragraph_format.space_after = Pt(6)

# 5. ĐẶC TẢ CÔNG NGHỆ
add_h1("5. ĐẶC TẢ CÔNG NGHỆ SỬ DỤNG (YÊU CẦU e)")

add_h2("5.1. Công nghệ phần mềm (Software Technologies)")
add_body("Hệ thống sử dụng các công nghệ mã nguồn mở hiện đại, ổn định và có cộng đồng phát triển mạnh mẽ:")

tbl_tech = doc.add_table(rows=1, cols=4)
tbl_tech.alignment = WD_TABLE_ALIGNMENT.CENTER
tbl_tech.autofit = False

tech_headers = ["Phân vùng", "Công nghệ / Thư viện", "Phiên bản", "Lý do lựa chọn & Vai trò"]
tech_widths = [Inches(1.2), Inches(1.8), Inches(1.0), Inches(2.4)]

tech_hdr_cells = tbl_tech.rows[0].cells
for i, h in enumerate(tech_headers):
    tech_hdr_cells[i].width = tech_widths[i]
    set_cell_background(tech_hdr_cells[i], "2980B9")
    p = tech_hdr_cells[i].paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(h)
    r.font.name = "Times New Roman"
    r.font.size = Pt(11)
    r.bold = True
    r.font.color.rgb = RGBColor(255, 255, 255)

tech_data = [
    ("Frontend Client", "Flutter SDK (Dart)", "3.47+ / 3.13+", "Xây dựng ứng dụng đa nền tảng (Android, iOS, Web) với một codebase duy nhất, hiệu năng cao."),
    ("Frontend Logic", "flutter_bloc & equatable", "^8.1.0", "Quản lý trạng thái theo luồng Reactive, phân tách triệt để UI và Logic nghiệp vụ."),
    ("Frontend Network", "Dio & Retrofit", "^5.4.0", "Client HTTP hỗ trợ Interceptors tự động đính kèm và làm mới JWT tokens."),
    ("Frontend Storage", "flutter_secure_storage", "^9.0.0", "Mã hóa bảo mật JWT tokens trong Android Keystore và iOS Keychain."),
    ("Frontend Audio", "record & just_audio", "^5.0 / ^0.9", "Ghi âm trực tiếp bài nói ngoại ngữ và phát mượt mà file audio bài luyện nghe."),
    ("Backend Core", "NestJS (Node.js)", "12.0+", "Framework backend hướng module enterprise, hỗ trợ Dependency Injection và TypeScript Strict."),
    ("Backend Lang", "TypeScript", "6.0+", "Kiểu dữ liệu tĩnh chặt chẽ, phát hiện lỗi lúc biên dịch, tự sinh tài liệu code."),
    ("ORM / Data", "Prisma ORM", "5.x / 6.x", "ORM Type-safe thế hệ mới, hỗ trợ migrations tự động và truy vấn cơ sở dữ liệu quan hệ an toàn."),
    ("Bảo mật API", "bcrypt, @nestjs/jwt", "^5.x / ^10.x", "Băm mật khẩu an toàn với salt rounds = 12; phát hành và xác thực JWT Access/Refresh tokens."),
    ("Validation", "class-validator", "^0.14.x", "Tự động kiểm tra tính hợp lệ của Payload DTO đầu vào trước khi thực thi nghiệp vụ."),
    ("Job Queue", "Bull & ioredis", "^4.x", "Quản lý hàng đợi nền trên Redis để xử lý gửi thông báo, gửi email và các tác vụ nặng."),
    ("API Docs", "Swagger / OpenAPI", "^7.x", "Tự sinh giao diện tài liệu tương tác API trực quan phục vụ quá trình phát triển và kiểm thử."),
    ("Cơ sở dữ liệu", "PostgreSQL (Alpine)", "16.x", "CSDL quan hệ ACID vững chắc; hỗ trợ UUID, JSONB linh hoạt cho ngân hàng đề thi."),
    ("Bộ nhớ đệm", "Redis (Alpine)", "7.x", "CSDL in-memory siêu tốc dùng làm cache dữ liệu và backend cho hàng đợi Bull."),
    ("Cloud Services", "Firebase Admin SDK", "12.x", "Bắn Push notification qua FCM và lưu trữ file audio bài nói, tài liệu PDF trên Cloud Storage."),
    ("Thanh toán", "VNPay Sandbox Gateway", "Standard", "Cổng thanh toán điện tử nội địa uy tín, tích hợp kiểm tra chữ ký an toàn SHA-512."),
    ("Container hóa", "Docker & Docker Compose", "29.x / 5.5+", "Đóng gói toàn bộ DB, Redis, Backend chạy đồng nhất giữa môi trường Dev và Production.")
]

for row_data in tech_data:
    row = tbl_tech.add_row()
    for col_idx, cell_value in enumerate(row_data):
        cell = row.cells[col_idx]
        cell.width = tech_widths[col_idx]
        set_cell_border(cell)
        p = cell.paragraphs[0]
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.space_before = Pt(2)
        r = p.add_run(cell_value)
        r.font.name = "Times New Roman"
        r.font.size = Pt(10)
        r.font.color.rgb = TEXT_COLOR
        if col_idx in [0, 2]:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        elif col_idx == 1:
            r.bold = True

doc.add_paragraph().paragraph_format.space_after = Pt(6)

add_h2("5.2. Hạ tầng & Yêu cầu phần cứng (Hardware Specifications)")
add_body("Hệ thống phân định rõ yêu cầu phần cứng giữa Máy chủ triển khai và Thiết bị đầu cuối của người dùng:")

add_body("Máy chủ đám mây ảo hóa (Cloud VPS / Dedicated Server) chạy hệ điều hành Linux (Ubuntu Server 22.04 LTS / Debian 12). Cấu hình tối thiểu: 2 vCPU, 4 GB RAM, 40 GB SSD NVMe, băng thông 100 Mbps đối xứng. Toàn bộ file tĩnh dung lượng lớn (Audio/PDF/Video) được lưu trữ trên Firebase Storage nên máy chủ không bị quá tải ổ cứng.", bold_prefix="1. Máy chủ Server (Production dự kiến): ")

add_body("Điện thoại thông minh chạy hệ điều hành Android 8.0 trở lên hoặc iPhone chạy iOS 13.0 trở lên; RAM tối thiểu 2GB; trang bị Micro để ghi âm bài tập nói ngoại ngữ và loa/tai nghe để nghe bài tập nghe.", bold_prefix="2. Thiết bị di động người dùng (Học viên, Phụ huynh, Giáo viên): ")

add_body("Máy tính để bàn hoặc Laptop chạy hệ điều hành Windows 10/11, macOS hoặc Linux; RAM tối thiểu 4GB; màn hình từ Full HD (1920x1080); trình duyệt web hiện đại (Google Chrome, Microsoft Edge, Safari).", bold_prefix="3. Máy tính quản trị (Admin, Học vụ, Thu ngân): ")

# 6. ĐÁNH GIÁ THUỘC TÍNH CHẤT LƯỢNG
add_h1("6. ĐÁNH GIÁ ĐÁP ỨNG THUỘC TÍNH CHẤT LƯỢNG PHẦN MỀM")
add_body("Sự kết hợp giữa mô hình Client-Server, Layered Clean Architecture, Event-Driven và Pipe-Filter mang lại khả năng đáp ứng toàn diện các tiêu chuẩn kỹ thuật:")
add_bullet("Logic bảo mật và kiểm tra quyền RBAC được thực thi tập trung tại Server qua các Guard độc lập (Pipe-Filter); dữ liệu nhạy cảm được mã hóa JWT và mật khẩu băm bcrypt 12 rounds; client không thể tự can thiệp hay vượt quyền.", "• Tính Bảo mật (Security): ")
add_bullet("Cơ sở dữ liệu quan hệ PostgreSQL với các ràng buộc khóa ngoại và Transaction đảm bảo tuyệt đối tính toàn vẹn khi xếp lớp, trừ công nợ và thu học phí.", "• Tính Toàn vẹn (Integrity): ")
add_bullet("Kiến trúc Event-Driven và Message Broker (Redis/Bull) tách rời các tác vụ nặng (gửi thông báo phụ huynh, gửi email) khỏi tiến trình chính, đảm bảo phản hồi API nhanh chóng dưới 200ms.", "• Hiệu năng & Khả năng mở rộng (Performance & Scalability): ")
add_bullet("Mô hình phân tầng Clean Architecture giúp mã nguồn dễ đọc, các module độc lập, dễ dàng bổ sung tính năng mới trong 6 phase phát triển mà không làm phát sinh lỗi hồi quy.", "• Khả năng bảo trì (Maintainability): ")

# Footer
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

primary_file = "docs/kien-truc-phan-mem.docx"
alt_file = "docs/kien-truc-phan-mem-co-hinh-anh.docx"

try:
    doc.save(primary_file)
    print(f"Successfully generated {primary_file}!")
except PermissionError:
    print(f"Note: {primary_file} is open in Word. Saved to {alt_file} instead.")

doc.save(alt_file)
print(f"Successfully generated {alt_file}!")
