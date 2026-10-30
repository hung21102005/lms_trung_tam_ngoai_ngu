import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._element.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m_name, m_val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m_name}')
        node.set(qn('w:w'), str(m_val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def add_clean_paragraph(container, text, align=WD_ALIGN_PARAGRAPH.LEFT, space_before=2, space_after=2, size=11):
    p = container.add_paragraph() if hasattr(container, 'add_paragraph') else container.paragraphs[0]
    p.alignment = align
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(size)
    run.font.bold = False
    run.font.italic = False
    run.font.color.rgb = RGBColor(0, 0, 0)
    return p

def set_table_borders(table):
    table.style = 'Table Grid'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    tblPr = table._element.xpath('w:tblPr')
    if tblPr:
        tblBorders = OxmlElement('w:tblBorders')
        for border_name in ['top', 'left', 'bottom', 'right', 'insideH', 'insideV']:
            border = OxmlElement(f'w:{border_name}')
            border.set(qn('w:val'), 'single')
            border.set(qn('w:sz'), '4')
            border.set(qn('w:space'), '0')
            border.set(qn('w:color'), '000000')
            tblBorders.append(border)
        tblPr[0].append(tblBorders)

def create_table_with_data(doc, headers, rows_data, col_widths=None):
    table = doc.add_table(rows=len(rows_data) + 1, cols=len(headers))
    set_table_borders(table)
    
    # Headers
    for c_idx, header_text in enumerate(headers):
        cell = table.cell(0, c_idx)
        set_cell_margins(cell, top=120, bottom=120, left=120, right=120)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        run = p.add_run(header_text)
        run.font.name = 'Times New Roman'
        run.font.size = Pt(10.5)
        run.font.bold = False
        run.font.color.rgb = RGBColor(0, 0, 0)
        
    # Rows
    for r_idx, row_vals in enumerate(rows_data):
        for c_idx, cell_value in enumerate(row_vals):
            cell = table.cell(r_idx + 1, c_idx)
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            # Center if short text or index
            if c_idx == 0 or cell_value in ['Must', 'Should', 'Could', 'Nam', 'Nữ']:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            run = p.add_run(str(cell_value))
            run.font.name = 'Times New Roman'
            run.font.size = Pt(10)
            run.font.bold = False
            run.font.color.rgb = RGBColor(0, 0, 0)
            
    # Set widths if provided
    if col_widths:
        for row in table.rows:
            for idx, width in enumerate(col_widths):
                row.cells[idx].width = width
                
    doc.add_paragraph().paragraph_format.space_after = Pt(6)
    return table

# Khởi tạo Document
doc = docx.Document()

# Thiết lập lề trang chuẩn A4
sections = doc.sections
for s in sections:
    s.top_margin = Inches(0.8)
    s.bottom_margin = Inches(0.8)
    s.left_margin = Inches(0.8)
    s.right_margin = Inches(0.8)

# Thiết lập style mặc định
style_normal = doc.styles['Normal']
style_normal.font.name = 'Times New Roman'
style_normal.font.size = Pt(11)
style_normal.font.bold = False
style_normal.font.color.rgb = RGBColor(0, 0, 0)

# BẢNG TIÊU ĐỀ TÀI LIỆU (KẺ BẢNG)
title_headers = ["THÔNG TIN TÀI LIỆU ĐẶC TẢ YÊU CẦU NGƯỜI DÙNG"]
title_rows = [
    ["Đề tài: HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ"],
    ["Ngày tài liệu: 26/10/2026 | Phiên bản: 1.0"],
    ["Căn cứ nghiệp vụ: chuc-nang-de-tai.md"],
    ["Nền tảng công nghệ: Flutter Mobile (iOS/Android), Flutter Web, NestJS, PostgreSQL, Redis, Firebase"]
]
t_title = create_table_with_data(doc, title_headers, title_rows, col_widths=[Inches(6.8)])

# PHẦN 1: TỔNG QUAN & BỐI CẢNH NGHIỆP VỤ (KẺ BẢNG)
p1 = add_clean_paragraph(doc, "1. TỔNG QUAN VÀ BỐI CẢNH NGHIỆP VỤ", size=12)

sec1_headers = ["STT", "Nội dung quy trình nghiệp vụ hệ thống"]
sec1_rows = [
    ["1", "Tiếp nhận nhu cầu học tập từ khách vãng lai, tư vấn chương trình và tổ chức kiểm tra trình độ đầu vào (Placement Test)."],
    ["2", "Cấp phát tài khoản tập trung, quản lý khóa học, cấp độ đào tạo, chi nhánh và phòng học."],
    ["3", "Tự động sinh lịch học theo thời khóa biểu cố định, tự động kiểm tra chống trùng phòng học và trùng giờ dạy giáo viên."],
    ["4", "Điểm danh buổi học trực tiếp trên ứng dụng di động, tự động gửi cảnh báo tức thời cho phụ huynh khi học viên vắng học."],
    ["5", "Giao bài tập và tiếp nhận bài nộp đa định dạng, đặc thù có công cụ ghi âm trực tiếp bài nói (Speaking Audio) trên điện thoại."],
    ["6", "Tổ chức thi và kiểm tra trực tuyến với bộ đếm giờ thời gian thực, cơ chế tự động lưu câu trả lời và tự động chấm điểm trắc nghiệm."],
    ["7", "Quản lý học phí, thu tiền tại quầy, xuất phiếu thu PDF có mã QR và hỗ trợ thanh toán học phí trực tuyến qua cổng VNPay."],
    ["8", "Thống kê báo cáo doanh thu, đối soát công nợ, tỷ lệ chuyên cần học tập và tổng kết giờ dạy thực tế của giáo viên."]
]
create_table_with_data(doc, sec1_headers, sec1_rows, col_widths=[Inches(0.6), Inches(6.2)])

# PHẦN 2: XÁC ĐỊNH CÁC NHÓM TÁC NHÂN (ACTORS) (KẺ BẢNG)
p2 = add_clean_paragraph(doc, "2. XÁC ĐỊNH CÁC NHÓM TÁC NHÂN (ACTORS / USER ROLES)", size=12)

sec2_headers = ["STT", "Tác nhân (Actor)", "Nền tảng sử dụng", "Trách nhiệm và Phạm vi nghiệp vụ"]
sec2_rows = [
    ["1", "Khách vãng lai (Guest)", "Mobile App / Web", "Người chưa có tài khoản; tra cứu danh mục khóa học, địa chỉ chi nhánh, gửi form đăng ký nhu cầu học tập để trung tâm liên hệ tư vấn."],
    ["2", "Học viên (Student)", "Flutter Mobile App", "Đăng nhập tài khoản được cấp, đổi mật khẩu lần đầu, theo dõi thời khóa biểu, nộp bài tập (văn bản, PDF, ghi âm bài nói Speaking), làm bài thi trực tuyến, tra cứu điểm số, theo dõi điểm danh và thanh toán học phí."],
    ["3", "Phụ huynh (Parent)", "Flutter Mobile App", "Đăng nhập bằng tài khoản liên kết với con em; nhận thông báo đẩy tức thời khi con vắng học; theo dõi lịch học, kết quả bài tập, điểm thi và tình hình học phí của con."],
    ["4", "Giáo viên (Teacher)", "Mobile App + Web", "Xem thời khóa biểu giảng dạy; thực hiện điểm danh buổi học tại lớp; giao bài tập về nhà; nghe bài ghi âm phát âm và chấm điểm; ra đề thi từ ngân hàng câu hỏi; chấm bài thi tự luận."],
    ["5", "Thu ngân / Kế toán (Cashier)", "Web Admin Portal", "Quản lý danh sách hóa đơn học phí; ghi nhận tiền mặt/chuyển khoản tại quầy; xuất phiếu thu PDF có mã QR; xử lý đóng học phí theo đợt (trả góp); xử lý hoàn phí/bảo lưu; theo dõi công nợ quá hạn và xem báo cáo dòng tiền."],
    ["6", "Nhân viên Học vụ / Tuyển sinh (Academic Staff)", "Web Admin Portal", "Tiếp nhận và chăm sóc Lead tuyển sinh; hẹn kiểm tra xếp lớp (Placement Test); chuyển đổi Lead thành học viên chính thức; quản lý lớp học, tự động sinh lịch học; ghi danh học viên; kiểm tra phòng trống; duyệt đơn xin học bù."],
    ["7", "Quản trị viên (Admin)", "Web Admin Portal", "Toàn quyền kiểm soát hệ thống: quản lý tài khoản người dùng, phân quyền vai trò (RBAC), cấu hình chi nhánh và phòng học, thiết lập đơn giá khóa học, khóa/mở tài khoản, reset mật khẩu, xem dashboard điều hành và toàn bộ báo cáo doanh thu/học vụ."]
]
create_table_with_data(doc, sec2_headers, sec2_rows, col_widths=[Inches(0.5), Inches(1.5), Inches(1.3), Inches(3.5)])

# PHẦN 3: BẢNG ĐẶC TẢ YÊU CẦU NGƯỜI DÙNG (USER REQUIREMENTS MATRIX) (KẺ BẢNG)
p3 = add_clean_paragraph(doc, "3. BẢNG ĐẶC TẢ YÊU CẦU NGƯỜI DÙNG (USER REQUIREMENTS MATRIX)", size=12)

sec3_headers = ["Mã UR", "Tác nhân", "Yêu cầu người dùng (User Story)", "Mục đích / Giá trị mang lại", "Tiêu chí nghiệm thu (Acceptance Criteria)", "Độ ưu tiên"]
sec3_rows = [
    ["UR-G01", "Khách vãng lai", "Xem danh sách các khóa học ngoại ngữ và địa chỉ các cơ sở chi nhánh.", "Nắm bắt thông tin đào tạo, học phí niêm yết để lựa chọn khóa học phù hợp.", "Hiển thị đầy đủ tên khóa, mô tả, số buổi học, học phí gốc, hotline và địa chỉ chi nhánh.", "Must"],
    ["UR-G02", "Khách vãng lai", "Điền form đăng ký thông tin tư vấn học tập trực tuyến.", "Được trung tâm liên hệ tư vấn lộ trình và xếp lịch kiểm tra đầu vào.", "Form yêu cầu Họ tên, SĐT, Email, Khóa học mong muốn; lưu vào admission_leads mà không tạo tài khoản tự do.", "Must"],
    ["UR-S01", "Học viên", "Đăng nhập bằng mã học viên/SĐT và bắt buộc đổi mật khẩu trong lần đầu truy cập.", "Đảm bảo tính bảo mật cho tài khoản cá nhân do trung tâm khởi tạo sẵn.", "Kiểm tra cờ isFirstLogin = true; chuyển hướng tới màn hình đổi mật khẩu mới; yêu cầu tối thiểu 8 ký tự.", "Must"],
    ["UR-S02", "Học viên", "Xem thời khóa biểu cá nhân theo ngày, tuần, tháng.", "Chủ động nắm thời gian, phòng học, giáo viên phụ trách để đi học đúng giờ.", "Giao diện Calendar hiển thị rõ tên lớp, ca học, phòng học, trạng thái buổi học (sắp tới, đã học).", "Must"],
    ["UR-S03", "Học viên", "Ghi âm trực tiếp bài nói trên ứng dụng và nộp bài tập phát âm.", "Rèn luyện kỹ năng Speaking và gửi file âm thanh chất lượng cho giáo viên nhận xét.", "Tích hợp công cụ ghi âm micro trên app: có nút Thu âm, Tạm dừng, Nghe lại, Thu lại và tải file nén lên Firebase Storage.", "Must"],
    ["UR-S04", "Học viên", "Làm bài thi trực tuyến với đồng hồ đếm ngược và tự động lưu đáp án.", "Tham gia kỳ thi định kỳ thuận tiện, không lo mất dữ liệu bài làm khi mạng chập chờn.", "Đếm ngược theo thời gian thực; tự động lưu câu trả lời cục bộ mỗi khi chọn; tự động nộp khi hết giờ.", "Must"],
    ["UR-S05", "Học viên", "Thanh toán học phí trực tuyến qua cổng thanh toán VNPay.", "Tiện lợi đóng học phí từ xa mà không cần đến trực tiếp văn phòng trung tâm.", "Chuyển tiếp cổng thanh toán bảo mật; tự động gạch nợ và đổi trạng thái hóa đơn sang PAID khi nhận IPN thành công.", "Should"],
    ["UR-S06", "Học viên", "Gửi đơn đăng ký học bù khi nghỉ học một buổi có phép.", "Theo kịp tiến độ bài học của khóa đào tạo.", "Chọn buổi học cần bù; hệ thống hiển thị các lớp cùng cấp độ còn chỗ trống; gửi yêu cầu đến Học vụ duyệt.", "Should"],
    ["UR-P01", "Phụ huynh", "Nhận thông báo đẩy tức thì trên điện thoại khi con tôi vắng học.", "Kịp thời giám sát việc đi học chuyên cần của con.", "Ngay khi giáo viên bấm hoàn tất điểm danh có trạng thái ABSENT, Firebase FCM gửi push notification đến máy phụ huynh.", "Must"],
    ["UR-P02", "Phụ huynh", "Theo dõi bảng điểm, chuyên cần và nhận xét chi tiết của giáo viên về con.", "Đồng hành cùng quá trình tiến bộ ngôn ngữ của con em mình.", "Hiển thị lịch sử đi học (% chuyên cần), kết quả bài tập, file nhận xét phát âm của giáo viên.", "Must"],
    ["UR-T01", "Giáo viên", "Thực hiện điểm danh học viên từng buổi học trực tiếp trên điện thoại.", "Ghi nhận nhanh chóng sĩ số lớp học mà không cần dùng sổ giấy.", "Danh sách học viên lớp với các nút chọn: Có mặt (present), Vắng (absent), Trễ (late), Có phép (excused); có nút Có mặt tất cả.", "Must"],
    ["UR-T02", "Giáo viên", "Giao bài tập về nhà kèm hạn chót và tài liệu đính kèm (PDF, audio mẫu). " ,"Giao nhiệm vụ rèn luyện sau buổi học cho học viên.", "Thiết lập tiêu đề, hướng dẫn, phân loại (Writing, Speaking, Homework), deadline, thang điểm tối đa.", "Must"],
    ["UR-T03", "Giáo viên", "Nghe đoạn ghi âm bài nói của học viên trên app và cho điểm, nhận xét.", "Đánh giá chính xác phát âm, ngữ điệu và ngữ pháp bài nói của học viên.", "Trình phát âm thanh tích hợp; thanh trượt timeline; ô nhập điểm số và ô nhận xét phản hồi chi tiết.", "Must"],
    ["UR-T04", "Giáo viên", "Tạo đề thi từ ngân hàng câu hỏi đa dạng các kỹ năng (Nghe, Đọc, Viết, Từ vựng).", "Tổ chức thi giữa khóa, cuối khóa công bằng và khoa học.", "Chọn câu hỏi thủ công hoặc chọn ngẫu nhiên theo tỷ lệ độ khó; cấu hình thời gian thi, điểm đạt.", "Must"],
    ["UR-C01", "Thu ngân", "Tra cứu và quản lý toàn bộ danh sách hóa đơn học phí của học viên.", "Kiểm soát các khoản phải thu theo từng chi nhánh, từng lớp học.", "Lọc hóa đơn theo trạng thái: Chờ đóng, Đã đóng, Đóng 1 phần, Quá hạn; tìm kiếm theo tên hoặc mã học viên.", "Must"],
    ["UR-C02", "Thu ngân", "Ghi nhận thanh toán tiền mặt/chuyển khoản tại quầy cho học viên.", "Cập nhật số tiền đã thu và trừ dần công nợ của học viên.", "Nhập số tiền thu thực tế, hình thức đóng, mã tham chiếu ngân hàng; hệ thống tự động đổi trạng thái hóa đơn.", "Must"],
    ["UR-C03", "Thu ngân", "Xuất và in phiếu thu học phí định dạng PDF chuẩn có mã QR.", "Cung cấp chứng từ nộp tiền hợp pháp cho học viên và phụ huynh.", "Sinh file PDF chứa logo trung tâm, thông tin học viên, số tiền, nội dung nộp, chữ ký thu ngân và mã QR tra cứu.", "Must"],
    ["UR-C04", "Thu ngân", "Theo dõi danh sách học viên nợ học phí quá hạn và gửi cảnh báo nhắc nợ.", "Đôn đốc thu hồi học phí đúng hạn quy định.", "Phân loại công nợ: quá hạn dưới 15 ngày, 15-30 ngày, trên 30 ngày; kích hoạt gửi tin nhắc nợ tự động.", "Should"],
    ["UR-C05", "Thu ngân", "Xử lý yêu cầu hoàn tiền hoặc bảo lưu học phí khi học viên có đơn rút học.", "Tuân thủ chính sách tài chính của trung tâm và bảo vệ quyền lợi học viên.", "Nhập lý do, tính toán số tiền hoàn trả hoặc số tiền bảo lưu theo quy chế; tạo phiếu hoàn phí/bảo lưu.", "Should"],
    ["UR-A01", "Học vụ", "Tiếp nhận danh sách yêu cầu tư vấn mới và cập nhật kết quả kiểm tra đầu vào.", "Phân loại nhu cầu và tư vấn lộ trình học tập chính xác cho học viên tiềm năng.", "Quản lý danh sách Lead; cập nhật trạng thái (Mới, Đã liên hệ, Đã test, Chốt lớp); lưu điểm Placement test.", "Must"],
    ["UR-A02", "Học vụ", "Thực hiện chuyển đổi Lead thành học viên chính thức chỉ với 1 click.", "Tiết kiệm thời gian nhập liệu và giảm sai sót dữ liệu.", "Tự động tạo hồ sơ học viên, sinh mã HV, tạo tài khoản đăng nhập tạm, xếp vào lớp học, sinh hóa đơn học phí.", "Must"],
    ["UR-A03", "Học vụ", "Tạo lớp học mới với lịch học cố định và hệ thống tự động sinh các buổi học chi tiết.", "Tự động hóa xếp lịch và loại trừ các ngày lễ nghỉ đã cấu hình.", "Chọn khóa học, phòng, giáo viên, thứ trong tuần, giờ học; thuật toán tự sinh danh sách class_sessions.", "Must"],
    ["UR-A04", "Học vụ", "Hệ thống tự động cảnh báo khi có hiện tượng trùng phòng hoặc trùng lịch giáo viên.", "Tránh xung đột cơ sở vật chất và thời gian giảng dạy.", "Kiểm tra chéo khung giờ; hiển thị thông báo lỗi cụ thể nếu phòng hoặc giáo viên đã có lịch dạy khác.", "Must"],
    ["UR-AD01", "Quản trị viên", "Quản lý tập trung toàn bộ tài khoản người dùng và phân quyền theo vai trò.", "Bảo vệ an toàn dữ liệu học vụ và phân định rõ trách nhiệm từng nhân sự.", "Phân quyền RBAC (SuperAdmin, BranchAdmin, AcademicStaff, Cashier, Teacher, Student, Parent); khóa/mở tài khoản.", "Must"],
    ["UR-AD02", "Quản trị viên", "Đặt lại mật khẩu tạm thời cho người dùng khi họ quên hoặc báo mất tài khoản.", "Hỗ trợ người dùng truy cập lại hệ thống nhanh chóng.", "Cấp mật khẩu tạm an toàn và bật lại cờ isFirstLogin = true để bắt buộc người dùng đổi mật khẩu khi đăng nhập lại.", "Must"],
    ["UR-AD03", "Quản trị viên", "Xem Dashboard tổng quan các chỉ số điều hành (học viên, doanh thu, công nợ, lớp học).", "Nắm bắt nhanh chóng tình hình hoạt động kinh doanh và đào tạo của trung tâm.", "Biểu đồ trực quan doanh thu theo tháng, so sánh giữa các chi nhánh, tỷ lệ lấp đầy phòng học.", "Should"]
]
create_table_with_data(doc, sec3_headers, sec3_rows, col_widths=[Inches(0.7), Inches(1.1), Inches(1.6), Inches(1.4), Inches(1.4), Inches(0.6)])

# PHẦN 4: PHÂN LOẠI YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS - FR) (KẺ BẢNG)
p4 = add_clean_paragraph(doc, "4. BẢNG PHÂN LOẠI YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS - FR)", size=12)

sec4_headers = ["STT", "Nhóm chức năng (Mã nhóm)", "Nội dung đặc tả chức năng chi tiết"]
sec4_rows = [
    ["1", "Xác thực & Bảo mật (AUTH)", "Đăng nhập JWT (Access Token 15p, Refresh Token 7 ngày); Kích hoạt đổi mật khẩu lần đầu; Đổi mật khẩu cá nhân; Quên mật khẩu qua OTP; Đăng xuất và hủy token; Phân quyền RBAC qua Middleware Guard."],
    ["2", "Tiếp nhận & Tuyển sinh (LEAD)", "Form đăng ký nhu cầu công khai; Quản lý và lọc danh sách Lead; Cập nhật tiến trình tư vấn và lịch test; Chuyển đổi Lead thành học viên chính thức (tự động tạo hồ sơ, tài khoản, xếp lớp, sinh hóa đơn)."],
    ["3", "Quản lý Người dùng (USER)", "Tạo tài khoản học viên, phụ huynh (liên kết con), giáo viên, nhân viên; Tra cứu, lọc danh sách người dùng; Xem chi tiết hồ sơ; Khóa/mở khóa tài khoản; Admin reset mật khẩu; Import danh sách từ Excel; Phân quyền vai trò."],
    ["4", "Chi nhánh & Phòng học (BRANCH)", "Thêm, sửa chi nhánh; Xem danh sách chi nhánh; Thêm, sửa phòng học và trang thiết bị; Kiểm tra phòng trống theo khung giờ; Vô hiệu hóa phòng/chi nhánh khi sửa chữa."],
    ["5", "Khóa học & Giáo trình (COURSE)", "Tạo, cập nhật khóa học; Xem danh mục khóa học; Quản lý cấp độ (Levels) và điều kiện tiên quyết; Quản lý Module bài học; Quản lý bài học chi tiết; Quản lý và tải tài liệu học tập đa phương tiện (PDF, Audio, Video)."],
    ["6", "Lớp học & Xếp lịch (CLASS)", "Tạo lớp học mới; Tự động sinh danh sách buổi học (sessions); Quản lý danh sách lớp; Cập nhật thông tin lớp; Phân bổ học viên vào lớp (kiểm tra sĩ số); Can thiệp buổi học (đổi phòng đột xuất, giáo viên dạy thay); Xem lịch dạy; Xem lịch học; Quản lý vòng đời trạng thái lớp."],
    ["7", "Điểm danh & Chuyên cần (ATT)", "Điểm danh buổi học trên app di động; Chỉnh sửa điểm danh; Xem lịch sử chuyên cần cá nhân (Calendar Heatmap); Thống kê chuyên cần toàn lớp; Đăng ký học bù trực tuyến; Duyệt yêu cầu học bù; Tự động thông báo phụ huynh khi con vắng học."],
    ["8", "Bài tập & Luyện nói (ASG)", "Tạo bài tập về nhà (kèm hạn nộp, tài liệu mẫu); Xem danh sách bài tập; Nộp bài tập đa định dạng (text, file PDF/hình ảnh); Ghi âm bài nói trực tiếp (Speaking Audio trên app); Quản lý danh sách bài nộp; Chấm điểm và nhận xét phát âm; Xem kết quả bài tập."],
    ["9", "Thi & Khảo thí (EXAM)", "Quản lý ngân hàng câu hỏi; Quản lý câu hỏi đa dạng (Trắc nghiệm, Điền khuyết, Nối cặp, Sắp xếp, Tự luận); Tạo đề thi trực tuyến; Xem danh sách bài thi; Làm bài thi trực tuyến trên app (đồng hồ đếm ngược, tự động lưu câu trả lời); Nộp bài an toàn (tự động thu bài khi hết giờ); Tự động chấm điểm trắc nghiệm; Chấm thi tự luận; Xem bảng điểm phân tích kỹ năng."],
    ["10", "Học phí & Tài chính (FIN)", "Tự động sinh hóa đơn học phí khi ghi danh; Xem và lọc danh sách hóa đơn; Ghi nhận thanh toán tại quầy (tiền mặt/chuyển khoản); Thanh toán học phí trực tuyến qua VNPay; Đóng học phí theo đợt (trả góp); Quản lý và cảnh báo công nợ; Xử lý hoàn tiền/bảo lưu; Quản lý mã khuyến mãi; Xem lịch sử học phí cá nhân; Xuất phiếu thu PDF có mã QR."],
    ["11", "Thông báo & Nhắc nhở (NOTI)", "Bắn push notification qua Firebase Cloud Messaging (FCM); Trung tâm thông báo in-app; Kịch bản tự động: Bắn push cho phụ huynh khi con vắng học; Nhắc nhở deadline bài tập trước 24h; Nhắc nhở hạn nộp học phí trước 3 ngày; Gửi thông báo truyền thông hàng loạt; Tùy chỉnh cài đặt nhận thông báo."],
    ["12", "Báo cáo & Thống kê (RPT)", "Dashboard tổng quan điều hành cho Admin; Báo cáo doanh thu và dòng tiền; Báo cáo chuyên cần học tập; Báo cáo kết quả học tập và điểm số; Báo cáo chi tiết công nợ học phí; Báo cáo thống kê giờ dạy giáo viên; Xuất báo cáo ra file Excel (.xlsx); Xuất báo cáo tổng kết ra file PDF."],
    ["13", "Hồ sơ cá nhân (PROF)", "Xem hồ sơ cá nhân; Cập nhật thông tin cá nhân cơ bản; Cập nhật ảnh đại diện (cắt ảnh, nén lưu Cloud Storage); Đổi mật khẩu tài khoản; Trang tổng quan học tập cá nhân (Home Dashboard)."]
]
create_table_with_data(doc, sec4_headers, sec4_rows, col_widths=[Inches(0.5), Inches(1.8), Inches(4.5)])

# PHẦN 5: YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS - NFR) (KẺ BẢNG)
p5 = add_clean_paragraph(doc, "5. BẢNG YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS - NFR)", size=12)

sec5_headers = ["Nhóm yêu cầu", "Mã NFR", "Nội dung đặc tả kỹ thuật", "Chỉ số mục tiêu"]
sec5_rows = [
    ["Hiệu năng (Performance)", "NFR-P01", "Thời gian phản hồi của các truy vấn danh mục, lịch học, điểm danh.", "Dưới 500 ms trong điều kiện mạng bình thường."],
    ["Hiệu năng (Performance)", "NFR-P02", "Tải lên file ghi âm bài nói Speaking (nén định dạng M4A/AAC dưới 10MB).", "Hoàn tất trong vòng 3 giây qua mạng 4G/WiFi."],
    ["Hiệu năng (Performance)", "NFR-P03", "Cơ chế Auto-save câu trả lời bài thi trực tuyến.", "Tự động đồng bộ câu trả lời mỗi khi chọn đáp án hoặc mỗi 15 giây."],
    ["Bảo mật (Security)", "NFR-S01", "Bảo vệ truy cập API và phân quyền người dùng.", "Xác thực JWT Access Token (15 phút) kết hợp Refresh Token (7 ngày); RBAC Middleware kiểm tra role."],
    ["Bảo mật (Security)", "NFR-S02", "Mã hóa mật khẩu người dùng trong cơ sở dữ liệu.", "Bắt buộc băm mật khẩu bằng thuật toán Bcrypt với hệ số Salt Rounds = 12."],
    ["Bảo mật (Security)", "NFR-S03", "Lưu trữ an toàn token trên thiết bị di động.", "Lưu trữ bằng flutter_secure_storage (Android KeyStore và iOS Keychain)."],
    ["Bảo mật (Security)", "NFR-S04", "Chữ ký số xác thực thanh toán trực tuyến.", "Kiểm tra tính toàn vẹn chữ ký HMAC-SHA512 của dữ liệu callback từ cổng VNPay."],
    ["Toàn vẹn (Reliability)", "NFR-R01", "Tính toàn vẹn giao dịch tài chính và học vụ.", "Thao tác ghi nhận thanh toán, chuyển đổi lead và xếp lớp bắt buộc thực thi trong PostgreSQL Database Transactions."],
    ["Toàn vẹn (Reliability)", "NFR-R02", "Tính sẵn sàng của hệ thống (Availability).", "Đạt tối thiểu 99.5% thời gian hoạt động ổn định."],
    ["Toàn vẹn (Reliability)", "NFR-R03", "Sao lưu dữ liệu dự phòng (Backup).", "Tự động sao lưu cơ sở dữ liệu PostgreSQL hàng ngày (Daily automated backup)."],
    ["Khả dụng (Usability)", "NFR-U01", "Tính đáp ứng giao diện đa nền tảng (Responsive).", "Ứng dụng chạy trên màn hình điện thoại di động (Android 8+, iOS 13+) và trình duyệt Web độ phân giải từ 1366x768."],
    ["Khả dụng (Usability)", "NFR-U02", "Tốc độ khung hình giao diện di động.", "Đạt chuẩn 60 fps ổn định trên thiết bị di động nhờ kiến trúc BLoC quản lý trạng thái."]
]
create_table_with_data(doc, sec5_headers, sec5_rows, col_widths=[Inches(1.5), Inches(0.8), Inches(3.0), Inches(1.5)])

# PHẦN 6: QUY TẮC NGHIỆP VỤ BẮT BUỘC (BUSINESS RULES - BR) (KẺ BẢNG)
p6 = add_clean_paragraph(doc, "6. BẢNG QUY TẮC NGHIỆP VỤ BẮT BUỘC (BUSINESS RULES - BR)", size=12)

sec6_headers = ["Mã quy tắc", "Tên quy tắc", "Nội dung ràng buộc nghiệp vụ"]
sec6_rows = [
    ["BR-01", "Cấp phát tài khoản tập trung", "Học viên và Phụ huynh không tự đăng ký tài khoản chính thức tự do. Tài khoản chỉ được khởi tạo bởi Trung tâm (Admin/Học vụ) và bắt buộc gắn với hồ sơ học vụ (StudentProfile), mã học viên duy nhất và lớp học tương ứng."],
    ["BR-02", "Kích hoạt lần đầu", "Mọi tài khoản mới tạo đều có cờ isFirstLogin = true. Khi đăng nhập lần đầu bằng mật khẩu tạm, hệ thống bắt buộc người dùng xác thực thông tin và đổi mật khẩu mới thì mới được truy cập các tính năng bên trong."],
    ["BR-03", "Chống trùng phòng và trùng giáo viên", "Khi tạo lớp học hoặc sinh lịch học, hệ thống bắt buộc kiểm tra giao thoa thời gian: không thể xếp 2 lớp học trong cùng 1 phòng vào cùng một khung giờ, và một giáo viên không thể dạy 2 lớp tại cùng một thời điểm."],
    ["BR-04", "Tự động sinh hóa đơn khi xếp lớp", "Khi học viên được ghi danh chính thức vào lớp học, hệ thống tự động sinh 01 hóa đơn học phí (INV-YYYY-MM-XXXX) với hạn thanh toán mặc định trước ngày khai giảng 03 ngày."],
    ["BR-05", "Ràng buộc nộp bài ghi âm luyện nói", "Với các bài tập thuộc loại SPEAKING, hệ thống bắt buộc học viên phải đính kèm ít nhất 01 file ghi âm âm thanh hợp lệ (thời lượng từ 15 giây đến 5 phút) mới cho phép bấm nộp bài."],
    ["BR-06", "Cảnh báo vắng học thời gian thực", "Ngay khi giáo viên hoàn tất điểm danh và có học viên vắng học không phép, hệ thống kích hoạt sự kiện nền gửi thông báo đẩy (Push Notification) ngay lập tức đến thiết bị của phụ huynh liên kết."]
]
create_table_with_data(doc, sec6_headers, sec6_rows, col_widths=[Inches(0.9), Inches(1.7), Inches(4.2)])

# Lưu file Word
output_path = "docs/yeu-cau-nguoi-dung.docx"
doc.save(output_path)
print(f"Exported successfully to {output_path}")
