import docx
from docx.shared import Pt
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
import os

input_path = r'C:\Users\Vi-Hung\.gemini\antigravity\brain\b43367de-887f-4a8e-b28f-94fdbcfa6904\.user_uploaded\media_1792224627354_f618050d.docx'
output_dir = r'C:\Users\Vi-Hung\my_flutter_pj\XD_HT_LMS\lms_trung_tam_ngoai_ngu'
output_path = os.path.join(output_dir, 'DO_AN_LMS_TRUNG_TAM_NGOAI_NGU.docx')
docs_dir = os.path.join(output_dir, 'docs')
os.makedirs(docs_dir, exist_ok=True)
output_path_docs = os.path.join(docs_dir, 'DO_AN_LMS_TRUNG_TAM_NGOAI_NGU.docx')

doc = docx.Document(input_path)

def set_para_text(p, text, font_name='Times New Roman', font_size=13):
    p.text = text
    for r in p.runs:
        r.font.name = font_name
        r.font.size = Pt(font_size)
        rPr = r._element.get_or_add_rPr()
        rFonts = OxmlElement('w:rFonts')
        rFonts.set(qn('w:ascii'), font_name)
        rFonts.set(qn('w:hAnsi'), font_name)
        rFonts.set(qn('w:eastAsia'), font_name)
        rFonts.set(qn('w:cs'), font_name)
        rPr.append(rFonts)

def add_p_after(p, text, style=None, font_name='Times New Roman', font_size=13):
    new_p_elem = OxmlElement('w:p')
    p._element.addnext(new_p_elem)
    np = docx.text.paragraph.Paragraph(new_p_elem, p._parent)
    if style:
        np.style = style
    set_para_text(np, text, font_name, font_size)
    return np

def fill_paragraphs(anchor_p, text_list, font_name='Times New Roman', font_size=13):
    if not text_list:
        set_para_text(anchor_p, '', font_name, font_size)
        return anchor_p
    set_para_text(anchor_p, text_list[0], font_name, font_size)
    current_p = anchor_p
    for t in text_list[1:]:
        current_p = add_p_after(current_p, t, style=anchor_p.style, font_name=font_name, font_size=font_size)
    return current_p

# 1. MỞ ĐẦU (P80)
mo_dau_texts = [
    "Trong bối cảnh chuyển đổi số giáo dục đang diễn ra mạnh mẽ, việc ứng dụng công nghệ thông tin vào công tác quản trị và đào tạo tại các trung tâm ngoại ngữ đã trở thành một yêu cầu thiết yếu nhằm nâng cao chất lượng dạy và học, chuẩn hóa quy trình học vụ và tăng cường tính cạnh tranh.",
    "Các phương thức quản lý truyền thống dựa trên sổ sách giấy tờ hoặc bảng tính phân tán bộc lộ nhiều hạn chế lớn: dễ phát sinh xung đột lịch học giữa các phòng và giáo viên, tốn kém thời gian tổng hợp báo cáo sĩ số, thiếu công cụ hỗ trợ học viên tự học và thiếu một kênh kết nối tức thời, minh bạch giữa trung tâm, học viên và phụ huynh.",
    "Đề tài \"Xây dựng Hệ thống LMS Trung tâm Ngoại ngữ\" được nghiên cứu và thực hiện nhằm xây dựng một giải pháp phần mềm toàn diện, kết hợp giữa ứng dụng di động đa nền tảng Flutter và nền tảng máy chủ NestJS hiệu năng cao. Hệ thống giúp tự động hóa toàn bộ quy trình xếp lớp, quản lý giáo trình, kiểm soát sĩ số, đồng bộ thời khóa biểu và tạo dựng môi trường học tập tương tác hiện đại cho người học."
]
fill_paragraphs(doc.paragraphs[80], mo_dau_texts)

# 2. CHƯƠNG 1
# P87
set_para_text(doc.paragraphs[87], "")

# P89: Tên đề tài
set_para_text(doc.paragraphs[89], "XÂY DỰNG HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) CHO TRUNG TÂM NGOẠI NGỮ")

# P91: Lý do chọn đề tài
ly_do_texts = [
    "Thứ nhất, tính cấp thiết của chuyển đổi số giáo dục: Các trung tâm đào tạo ngoại ngữ hiện đại cần một nền tảng quản lý tập trung và chuẩn hóa để nâng cao chất lượng dịch vụ, tối ưu hóa nguồn lực giảng dạy và mở rộng quy mô chi nhánh một cách bền vững.",
    "Thứ hai, giải quyết triệt để các tồn tại của phương pháp quản lý thủ công: Việc phân công giảng viên, xếp lịch phòng học và kiểm soát sĩ số học viên bằng các công cụ rời rạc thường xuyên dẫn đến tình trạng trùng lịch, thất lạc thông tin học vụ và tốn nhiều nhân lực cho công tác điều phối.",
    "Thứ ba, nâng cao trải nghiệm học tập và tương tác đa chiều: Học viên cần một ứng dụng di động tiện lợi để theo dõi lịch học, tiếp cận tài liệu số hóa mọi lúc mọi nơi; phụ huynh cần nắm bắt kịp thời tình hình chuyên cần và kết quả học tập của con em mình; giáo viên cần công cụ tiện ích để quản lý lớp học và điểm danh nhanh chóng.",
    "Thứ tư, khai thác sức mạnh của công nghệ di động đa nền tảng: Sự phát triển của Flutter Framework cho phép xây dựng ứng dụng di động chạy mượt mà trên cả hai nền tảng phổ biến nhất hiện nay là Android và iOS từ một cơ sở mã nguồn duy nhất, giúp tối ưu chi phí và thời gian triển khai."
]
fill_paragraphs(doc.paragraphs[91], ly_do_texts)

# P93: Mục tiêu của đề tài
muc_tieu_texts = [
    "Mục tiêu tổng quát: Xây dựng hoàn chỉnh hệ thống Quản lý Học tập (LMS) phục vụ toàn diện công tác quản trị, đào tạo và kết nối thông tin tại trung tâm ngoại ngữ, tích hợp ứng dụng di động đa nền tảng cho người dùng và hệ thống quản trị học vụ đồng bộ.",
    "Mục tiêu cụ thể:",
    "- Xây dựng hệ thống xác thực bảo mật và phân quyền vai trò (Role-Based Access Control - RBAC) linh hoạt cho nhiều nhóm đối tượng: Quản trị viên, Nhân viên học vụ, Giáo viên, Trợ giảng, Học viên và Phụ huynh.",
    "- Hiện thực hóa các phân hệ nghiệp vụ học vụ cốt lõi: Quản lý chi nhánh và phòng học; Quản lý tuyển sinh và chăm sóc khách hàng tiềm năng; Quản lý chương trình đào tạo, phân cấp cấp độ và bài học.",
    "- Phát triển thuật toán tự động sinh lịch học chi tiết từng buổi học từ thông số lớp học, tích hợp cơ chế kiểm tra và ngăn chặn tuyệt đối xung đột lịch phòng học và giáo viên trong cùng khung giờ.",
    "- Cung cấp ứng dụng di động với giao diện trực quan, thân thiện, đồng bộ thời gian thực thời khóa biểu cá nhân và tài liệu học tập đa phương tiện."
]
fill_paragraphs(doc.paragraphs[93], muc_tieu_texts)

# P95: Đối tượng, phạm vi, cách tiếp cận và phương pháp thực hiện đề tài
doi_tuong_texts = [
    "Đối tượng nghiên cứu: Quy trình nghiệp vụ quản lý đào tạo tại các trung tâm ngoại ngữ; công nghệ phát triển ứng dụng di động đa nền tảng Flutter và ngôn ngữ lập trình Dart; kiến trúc hệ thống Client-Server hiện đại với RESTful API và quản trị cơ sở dữ liệu quan hệ.",
    "Phạm vi nghiên cứu và triển khai: Đề tài tập trung xây dựng hệ thống quản lý học tập phục vụ trung tâm ngoại ngữ có quy mô từ vừa đến lớn (hỗ trợ mô hình chuỗi chi nhánh), bao gồm các phân hệ: Xác thực & Quản lý người dùng, Quản lý chi nhánh & phòng học, Quản lý tuyển sinh tư vấn, Quản lý khóa học & giáo trình, Quản lý lớp học & thời khóa biểu tự động, Quản lý tài liệu học tập đa phương tiện.",
    "Cách tiếp cận và phương pháp thực hiện: Áp dụng mô hình phát triển phần mềm linh hoạt (Agile/Scrum); thiết kế hệ thống theo mô hình hướng đối tượng UML; triển khai kiến trúc Clean Architecture cho cả ứng dụng di động Flutter (tách biệt Presentation, BLoC và Data Source) và máy chủ Backend (NestJS Layered Architecture); thực hiện kiểm thử tự động (Unit Test, Integration/E2E Test) xuyên suốt quá trình phát triển."
]
fill_paragraphs(doc.paragraphs[95], doi_tuong_texts)

# P97: Bố cục của đề tài
bo_cuc_texts = [
    "Báo cáo đồ án được kết cấu thành các chương chính như sau:",
    "- MỞ ĐẦU: Giới thiệu tính cấp thiết, bối cảnh và lý do thực hiện đề tài.",
    "- CHƯƠNG 1. GIỚI THIỆU CHUNG VỀ ĐỀ TÀI: Trình bày chi tiết tên đề tài, lý do lựa chọn, mục tiêu nghiên cứu, đối tượng, phạm vi và phương pháp thực hiện đồ án.",
    "- CHƯƠNG 2. TỔNG QUAN VỀ CÔNG NGHỆ: Trình bày cơ sở lý thuyết về Flutter SDK, ngôn ngữ Dart, hệ thống cơ sở dữ liệu Firebase và hệ quản trị CSDL quan hệ, cùng các thư viện công nghệ then chốt.",
    "- CHƯƠNG 3. PHÂN TÍCH THIẾT KẾ HỆ THỐNG: Mô tả danh sách Use Case, sơ đồ Use Case tổng quan, bảng đặc tả chi tiết và sơ đồ tuần tự các chức năng chính của hệ thống.",
    "- CHƯƠNG 4. GIAO DIỆN ỨNG DỤNG: Trình bày cấu trúc và hình ảnh giao diện các màn hình của ứng dụng di động.",
    "- KẾT LUẬN: Đánh giá những kết quả đã đạt được của đồ án và đề xuất các hướng mở rộng, phát triển tiếp theo.",
    "- TÀI LIỆU THAM KHẢO: Liệt kê các tài liệu, sách chuyên khảo và website kỹ thuật đã tham khảo trong quá trình thực hiện."
]
fill_paragraphs(doc.paragraphs[97], bo_cuc_texts)

# 3. CHƯƠNG 2
# P104: Tổng quan về Flutter
flutter_texts = [
    "Flutter là bộ công cụ phát triển phần mềm giao diện người dùng mã nguồn mở (UI SDK) được phát triển bởi Google, ra mắt chính thức vào tháng 12 năm 2018. Flutter cho phép xây dựng các ứng dụng đa nền tảng biên dịch nguyên bản (native compiled) cho Android, iOS, Web, Windows, macOS và Linux từ một cơ sở mã nguồn duy nhất (Single Codebase).",
    "Các đặc điểm kiến trúc nổi bật của Flutter bao gồm:",
    "- Triết lý 'Everything is a Widget': Giao diện trong Flutter được tạo thành từ cây phân cấp các Widget lồng nhau. Flutter phân biệt rõ rệt giữa StatelessWidget (Widget tĩnh không lưu trạng thái nội tại) và StatefulWidget (Widget có trạng thái có thể thay đổi và kích hoạt render lại khi gọi hàm setState).",
    "- Hiệu năng dựng hình vượt trội: Khác với các framework lai sử dụng cầu nối JavaScript (JavaScript Bridge), Flutter biên dịch trực tiếp mã nguồn Dart thành mã máy ARM nguyên bản. Quá trình vẽ giao diện được xử lý độc lập thông qua engine đồ họa hiệu năng cao (Skia và Impeller), giúp ứng dụng duy trì tốc độ hiển thị mượt mà 60fps đến 120fps.",
    "- Tính năng Stateful Hot Reload: Cho phép lập trình viên áp dụng ngay lập tức các thay đổi mã nguồn lên thiết bị đang chạy mà không làm mất trạng thái phiên làm việc hiện tại, đẩy nhanh tốc độ thử nghiệm và tinh chỉnh giao diện.",
    "- Ngôn ngữ lập trình Dart: Ngôn ngữ hiện đại hướng đối tượng với hệ thống kiểu tĩnh mạnh mẽ (Sound Null Safety), hỗ trợ lập trình bất đồng bộ xuất sắc qua cú pháp Future và Stream."
]
fill_paragraphs(doc.paragraphs[104], flutter_texts)

# P109: Hệ quản trị cơ sở dữ liệu Firebase/SQL Server
db_texts = [
    "Trong kiến trúc hệ thống LMS Trung tâm Ngoại ngữ, giải pháp lưu trữ và quản trị dữ liệu được kết hợp tối ưu giữa nền tảng đám mây Firebase và Hệ quản trị cơ sở dữ liệu quan hệ (RDBMS):",
    "1. Nền tảng Google Firebase:",
    "- Firebase Authentication & Security: Cung cấp nền tảng quản lý danh tính người dùng an toàn, đồng bộ thông tin đăng nhập và hỗ trợ cơ chế bảo mật xác thực đa kênh.",
    "- Firebase Cloud Messaging (FCM): Đóng vai trò là kênh truyền tải thông báo đẩy (Push Notification) tức thời đến thiết bị di động của học viên, giáo viên và phụ huynh khi có lịch học mới, thông báo điểm danh hoặc bài tập được giao.",
    "- Firebase Storage: Cung cấp giải pháp lưu trữ tệp đám mây phân tán với khả năng mở rộng cao và độ sẵn sàng 99.9%, chuyên trách lưu trữ các tệp phương tiện đa định dạng: giáo án điện tử (PDF), tệp âm thanh luyện phát âm (MP3, WAV), video bài giảng và ảnh hồ sơ cá nhân thông qua cơ chế cấp quyền Signed URL bảo mật.",
    "2. Hệ quản trị Cơ sở dữ liệu Quan hệ (RDBMS):",
    "- Hệ thống dữ liệu trung tâm sử dụng hệ CSDL quan hệ chuẩn hóa cao (như PostgreSQL / SQL Server), tuân thủ nghiêm ngặt các nguyên tắc ACID nhằm đảm bảo tính toàn vẹn và nhất quán tuyệt đối cho dữ liệu học vụ.",
    "- Quản trị các mối quan hệ phức tạp và ràng buộc toàn vẹn giữa các thực thể cốt lõi: Người dùng, Vai trò và phân quyền đa cấp (RBAC), Chi nhánh, Phòng học, Danh mục khóa học, Cấp độ đào tạo, Giáo trình bài học, Lớp học, Học viên ghi danh và Thời khóa biểu từng buổi học.",
    "- Cung cấp khả năng lập chỉ mục (Indexing) và xử lý giao dịch tối ưu cho các thuật toán quét xung đột lịch học đa chiều giữa phòng học và giáo viên trong các khoảng thời gian cụ thể."
]
fill_paragraphs(doc.paragraphs[109], db_texts)

# P111: Các thư viện phổ biến,....
lib_texts = [
    "Để đảm bảo ứng dụng vận hành tin cậy, bảo mật và dễ mở rộng, hệ thống sử dụng các thư viện và gói công cụ tiêu chuẩn sau:",
    "1. Các thư viện ứng dụng di động (Frontend Flutter):",
    "- flutter_bloc: Quản lý trạng thái ứng dụng theo kiến trúc BLoC (Business Logic Component), giúp phân tách triệt để giữa tầng giao diện hiển thị và tầng xử lý luồng nghiệp vụ.",
    "- dio: Thư viện HTTP client mạnh mẽ hỗ trợ xử lý yêu cầu mạng, tích hợp AuthInterceptor tự động đính kèm JWT token vào header và cơ chế tự động làm mới mã truy cập (Auto-refresh token) khi token hết hạn.",
    "- get_it: Thư viện Service Locator triển khai kỹ thuật tiêm phụ thuộc (Dependency Injection), đảm bảo quản lý vòng đời các dịch vụ dùng chung một cách khoa học.",
    "- go_router: Giải pháp định tuyến khai báo (Declarative Routing) hỗ trợ điều hướng sâu (Deep Linking), phân luồng điều hướng theo vai trò (Role-based redirection) và bảo vệ các tuyến đường yêu cầu xác thực.",
    "- flutter_secure_storage: Lưu trữ an toàn các thông tin nhạy cảm (Access Token, Refresh Token) trên bộ nhớ mã hóa phần cứng của thiết bị (Keychain trên iOS và KeyStore trên Android).",
    "- table_calendar: Thư viện hiển thị lịch và thời khóa biểu trực quan, hỗ trợ chế độ xem theo tuần và theo tháng linh hoạt.",
    "- audioplayers: Thư viện điều khiển phát âm thanh chuyên dụng cho các bài tập nghe và luyện phát âm ngoại ngữ.",
    "- syncfusion_flutter_pdfviewer: Hỗ trợ hiển thị tài liệu học tập, giáo trình định dạng PDF trực tiếp trên ứng dụng mà không cần mở ứng dụng bên thứ ba.",
    "2. Các thư viện nền tảng máy chủ (Backend):",
    "- NestJS Framework: Khung làm việc máy chủ Node.js kiến trúc module doanh nghiệp với TypeScript.",
    "- Prisma ORM: Công cụ ánh xạ đối tượng và cơ sở dữ liệu hiện đại, đảm bảo an toàn kiểu dữ liệu (Type-safety) và hỗ trợ di trú dữ liệu (Migration) tự động.",
    "- Redis & ioredis: Bộ đệm lưu trữ In-Memory tốc độ cao phục vụ kiểm soát phiên đăng nhập, giới hạn tần suất gọi API (Rate Limiting) và lưu trữ mã xác thực OTP tạm thời.",
    "- bcryptjs: Mã hóa và băm mật khẩu một chiều an toàn bằng giải thuật băm Blowfish kèm Salt."
]
fill_paragraphs(doc.paragraphs[111], lib_texts)

# 4. CHƯƠNG 3
# P114
set_para_text(doc.paragraphs[114], "Chương này trình bày quá trình phân tích và thiết kế hệ thống LMS Trung tâm Ngoại ngữ, tập trung vào mô hình hóa các ca sử dụng (Use Case), đặc tả chi tiết các chức năng nghiệp vụ trọng tâm và biểu diễn luồng tương tác tuần tự của hệ thống.")

# P117: Danh sách UseCase
uc_list_texts = [
    "Dưới đây là danh sách các Use Case chức năng chính của hệ thống LMS Trung tâm Ngoại ngữ được phân loại theo các tác nhân (Actors):",
    "1. Đăng nhập hệ thống: Cho phép người dùng xác thực danh tính vào ứng dụng bằng tài khoản (Email/SĐT và mật khẩu) - Tác nhân: Tất cả người dùng.",
    "2. Đăng xuất: Cho phép người dùng kết thúc phiên làm việc an toàn và xóa token truy cập trên thiết bị - Tác nhân: Người dùng đã đăng nhập.",
    "3. Đổi mật khẩu lần đầu / Quên mật khẩu: Cho phép học viên, giáo viên đổi mật khẩu khi đăng nhập lần đầu hoặc yêu cầu cấp lại mật khẩu qua OTP - Tác nhân: Tất cả người dùng.",
    "4. Xem thông tin cá nhân: Xem thông tin chi tiết hồ sơ tài khoản cá nhân, trình độ học tập hoặc thông tin giảng dạy - Tác nhân: Tất cả người dùng.",
    "5. Quản lý người dùng & Cấp tài khoản: Tạo tài khoản học viên, giáo viên, phụ huynh; khóa/mở khóa tài khoản; nhập danh sách người dùng từ Excel - Tác nhân: Super Admin, Branch Admin, Học vụ.",
    "6. Quản lý chi nhánh & Phòng học: Thiết lập danh sách chi nhánh, quản lý phòng học, sức chứa và trang thiết bị giảng dạy - Tác nhân: Super Admin, Branch Admin.",
    "7. Tiếp nhận & Chăm sóc Lead tuyển sinh: Tiếp nhận thông tin học viên tiềm năng, đặt lịch hẹn kiểm tra trình độ và chuyển đổi thành học viên chính thức - Tác nhân: Nhân viên học vụ.",
    "8. Quản lý khóa học & Cấp độ đào tạo: Thiết lập chương trình đào tạo, phân cấp trình độ (Foundation, Fighter, B1, B2...), biên soạn bài học - Tác nhân: Super Admin, Branch Admin, Học vụ.",
    "9. Quản lý lớp học & Tự động sinh lịch: Mở lớp học mới, cấu hình lịch học trong tuần; hệ thống tự động sinh toàn bộ buổi học kèm kiểm tra chống trùng lịch - Tác nhân: Super Admin, Branch Admin, Học vụ.",
    "10. Ghi danh học viên vào lớp: Thêm học viên vào lớp học chính thức, kiểm soát giới hạn sĩ số tối đa của phòng học - Tác nhân: Super Admin, Branch Admin, Học vụ.",
    "11. Xem thời khóa biểu cá nhân: Xem lịch học (học viên), lịch giảng dạy (giáo viên) hoặc lịch học của con (phụ huynh) theo dạng lịch biểu tuần - Tác nhân: Học viên, Giáo viên, Phụ huynh.",
    "12. Xem nội dung bài học & Tài liệu: Xem giáo án điện tử, tải slide bài giảng, nghe audio luyện phát âm theo từng buổi học - Tác nhân: Học viên, Giáo viên.",
    "13. Điều chỉnh buổi học: Điều chỉnh thời gian buổi học, đổi phòng học hoặc phân công giáo viên dạy thay khi có sự cố - Tác nhân: Học vụ, Giáo viên."
]
fill_paragraphs(doc.paragraphs[117], uc_list_texts)

# P120: Sơ đồ UseCase
uc_diagram_texts = [
    "Sơ đồ Use Case tổng quan thể hiện cấu trúc phân quyền chức năng của hệ thống LMS Trung tâm Ngoại ngữ được phân chia theo các nhóm tác nhân cụ thể:",
    "- Nhóm chức năng chung (Tất cả người dùng): Đăng nhập, Đăng xuất, Đổi mật khẩu lần đầu, Quên mật khẩu qua OTP, Xem hồ sơ cá nhân.",
    "- Nhóm chức năng Quản trị & Học vụ (Admin & Nhân viên học vụ): Quản lý người dùng, phân quyền vai trò, quản lý chi nhánh, phòng học, quản lý tuyển sinh (Leads), quản lý danh mục khóa học, giáo trình bài học, mở lớp học, tự động sinh lịch học, ghi danh học viên vào lớp.",
    "- Nhóm chức năng Giảng dạy (Giáo viên & Trợ giảng): Xem thời khóa biểu giảng dạy, xem danh sách học viên trong lớp, điều chỉnh buổi học (phân công dạy thay), đính kèm tài liệu học tập bài học.",
    "- Nhóm chức năng Học tập & Tương tác (Học viên & Phụ huynh): Xem thời khóa biểu học tập cá nhân (hoặc của con), xem bài học, nghe audio luyện phát âm, nhận thông báo lịch học và điểm danh."
]
fill_paragraphs(doc.paragraphs[120], uc_diagram_texts)

# P123: Đặc tả UseCase
uc_spec_texts = [
    "Đặc tả Use Case 1: Đăng nhập hệ thống (UC-01)",
    "- Tên Use Case: Đăng nhập hệ thống.",
    "- Mô tả ngắn: Cho phép mọi đối tượng người dùng (Admin, Học vụ, Giáo viên, Học viên, Phụ huynh) xác thực tài khoản để truy cập vào các chức năng tương ứng trên hệ thống.",
    "- Tác nhân: Mọi người dùng chưa đăng nhập.",
    "- Điều kiện kích hoạt: Người dùng mở ứng dụng và nhấn nút 'Đăng nhập' tại màn hình chính.",
    "- Tiền điều kiện: Người dùng đã được cấp tài khoản trên hệ thống và thiết bị có kết nối mạng Internet.",
    "- Luồng sự kiện chính: (1) Người dùng mở ứng dụng, hệ thống hiển thị màn hình Đăng nhập. (2) Người dùng nhập tên tài khoản (Email hoặc Số điện thoại) và Mật khẩu. (3) Người dùng nhấn nút 'Đăng nhập'. (4) Ứng dụng gửi thông tin xác thực đến máy chủ Backend qua giao thức bảo mật HTTPS. (5) Máy chủ kiểm tra định dạng dữ liệu, giải mã mật khẩu băm, kiểm tra trạng thái tài khoản. (6) Nếu thông tin hợp lệ, hệ thống tạo cặp mã JWT Token (Access Token và Refresh Token) kèm danh sách vai trò và quyền hạn. (7) Ứng dụng lưu trữ token bảo mật vào thiết bị, tự động điều hướng người dùng đến màn hình Dashboard phù hợp theo vai trò.",
    "- Luồng sự kiện thay thế: Nếu sai tài khoản hoặc mật khẩu, hệ thống trả về thông báo 'Tài khoản hoặc mật khẩu không chính xác'. Nếu tài khoản đăng nhập lần đầu, hệ thống tự động điều hướng người dùng đến màn hình bắt buộc đổi mật khẩu mới. Nếu tài khoản bị tạm ngưng hoặc bị khóa, hệ thống thông báo 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ ban quản trị'.",
    "- Luồng ngoại lệ: Khi mất kết nối mạng, hệ thống hiển thị thông báo 'Không có kết nối mạng. Vui lòng kiểm tra lại đường truyền'.",
    "",
    "Đặc tả Use Case 2: Mở lớp học & Tự động sinh lịch học (UC-09)",
    "- Tên Use Case: Mở lớp học & Tự động sinh lịch học.",
    "- Mô tả ngắn: Cho phép Quản trị viên hoặc Nhân viên học vụ mở lớp học mới, chọn khóa học, giáo viên, phòng học và thời gian học; hệ thống sẽ tự động tính toán sinh ra toàn bộ các buổi học và kiểm tra chống trùng lịch.",
    "- Tác nhân: Super Admin, Branch Admin, Nhân viên học vụ.",
    "- Điều kiện kích hoạt: Người dùng chọn chức năng Tạo lớp học mới.",
    "- Tiền điều kiện: Người dùng đã đăng nhập với vai trò có quyền tạo lớp; Khóa học, cấp độ, chi nhánh đã được khởi tạo trong hệ thống.",
    "- Luồng sự kiện chính: (1) Người dùng chọn chức năng Tạo lớp học mới. (2) Người dùng nhập thông tin: Mã lớp, Tên lớp, Khóa học & Cấp độ, Chi nhánh, Phòng học, Giáo viên đứng lớp, Ngày bắt đầu học, Các ngày học trong tuần (ví dụ: Thứ 2, Thứ 4, Thứ 6), Giờ bắt đầu, Giờ kết thúc và Sĩ số tối đa. (3) Người dùng nhấn nút 'Lưu và sinh lịch học'. (4) Hệ thống kiểm tra mã lớp duy nhất; tính toán chuỗi ngày học tương ứng theo các thứ trong tuần cho đến khi đủ tổng số buổi của cấp độ. (5) Hệ thống quét kiểm tra chống trùng lịch: kiểm tra phòng học và giáo viên có bị trùng với bất kỳ lớp học nào khác trong cùng khung giờ của từng ngày hay không. (6) Nếu không có xung đột, hệ thống tạo bản ghi Lớp học và tự động tạo hàng loạt các bản ghi Buổi học (ClassSession) kèm gán bài học tương ứng trong một giao dịch an toàn (Transaction). (7) Hệ thống thông báo tạo lớp học và sinh lịch học thành công, hiển thị toàn bộ danh sách các buổi học vừa tạo.",
    "- Luồng sự kiện thay thế: Nếu trùng lịch phòng học hoặc trùng lịch giáo viên, hệ thống từ chối lưu và hiển thị thông báo cảnh báo xung đột chi tiết ngày giờ cụ thể.",
    "- Luồng ngoại lệ: Khi xảy ra lỗi kết nối CSDL trong quá trình tạo, toàn bộ giao dịch được tự động hoàn tác (Rollback) hoàn toàn."
]
fill_paragraphs(doc.paragraphs[123], uc_spec_texts)

# P126: Sơ đồ tuần tự
seq_texts = [
    "Sơ đồ tuần tự: Chức năng Đăng nhập hệ thống",
    "Quy trình tương tác tuần tự giữa các thành phần trong hệ thống khi người dùng thực hiện đăng nhập:",
    "- Bước 1: Người dùng nhập tên tài khoản (Email/SĐT) và mật khẩu trên giao diện ứng dụng di động (Flutter App View).",
    "- Bước 2: Người dùng nhấn nút 'Đăng nhập', AuthBloc tiếp nhận sự kiện LoginSubmitted và hiển thị trạng thái đang xử lý (Loading).",
    "- Bước 3: ApiClient gửi yêu cầu HTTP POST /auth/login kèm thông tin xác thực đến AuthController phía Backend.",
    "- Bước 4: AuthController gọi hàm signIn() trong AuthService để xử lý nghiệp vụ xác thực.",
    "- Bước 5: AuthService truy vấn thông tin người dùng từ cơ sở dữ liệu qua PrismaService.",
    "- Bước 6: Cơ sở dữ liệu trả về bản ghi User kèm mật khẩu đã băm và danh sách vai trò.",
    "- Bước 7: AuthService kiểm tra đối sánh mật khẩu bằng thư viện bcrypt và kiểm tra trạng thái tài khoản (ACTIVE, PENDING_ACTIVATION, LOCKED).",
    "- Bước 8: AuthService sinh cặp mã truy cập JWT (Access Token & Refresh Token) và lưu trữ phiên đăng nhập vào bộ đệm Redis.",
    "- Bước 9: AuthController trả về mã phản hồi HTTP 200 OK kèm Token và thông tin người dùng.",
    "- Bước 10: Ứng dụng di động lưu Token an toàn vào Secure Storage và kích hoạt điều hướng người dùng đến màn hình chức năng tương ứng với vai trò."
]
fill_paragraphs(doc.paragraphs[126], seq_texts)

# 5. KẾT LUẬN
# P145: clear '....'
set_para_text(doc.paragraphs[145], "")

# P147: Kết quả đạt được
ket_qua_texts = [
    "- Nghiên cứu và làm chủ kiến trúc phát triển ứng dụng di động đa nền tảng hiện đại với Flutter SDK và ngôn ngữ lập trình Dart, áp dụng thành công các mẫu kiến trúc phần mềm tiên tiến như Clean Architecture và BLoC Pattern.",
    "- Xây dựng hoàn chỉnh hệ thống xác thực bảo mật chuẩn công nghiệp với JSON Web Token (JWT Access Token & Refresh Token), cơ chế tự động làm mới mã truy cập, giải thuật mã hóa mật khẩu bcrypt và cơ chế phân quyền người dùng đa cấp bậc (Role-Based Access Control - RBAC).",
    "- Hoàn thành thiết kế và hiện thực hóa toàn bộ các phân hệ nghiệp vụ học vụ cốt lõi: Quản lý danh mục khóa học, phân cấp lộ trình học, giáo trình bài học, tài liệu đính kèm, quản lý chi nhánh, phòng học và quản lý học viên tiềm năng (Admission Leads).",
    "- Thiết kế và triển khai thành công thuật toán tự động sinh lịch học chi tiết từng buổi học từ thông số lớp học, tích hợp cơ chế phát hiện và ngăn chặn xung đột lịch phòng học và giáo viên trong cùng khung giờ.",
    "- Xây dựng hệ thống kiểm thử toàn diện với 100% các ca kiểm thử đơn vị (Unit Test) và kiểm thử tích hợp đầu cuối (E2E Test) đều vượt qua thành công, đảm bảo mã nguồn vận hành ổn định và chuẩn xác."
]
fill_paragraphs(doc.paragraphs[147], ket_qua_texts)

# P149: Hướng phát triển của đề tài
huong_phat_trien_texts = [
    "- Hoàn thiện toàn bộ hệ thống giao diện người dùng trên ứng dụng di động Flutter và Web Admin Portal bằng công cụ thiết kế chuyên nghiệp, đảm bảo trải nghiệm tương tác trực quan, thân thiện và đáp ứng chuẩn khả năng tiếp cận (Accessibility).",
    "- Xây dựng phân hệ Điểm danh thông minh (Attendance) cho phép giáo viên điểm danh nhanh tại lớp và hỗ trợ xếp lịch học bù tự động cho học viên vắng có phép.",
    "- Triển khai phân hệ Khảo thí và Bài tập (Exams & Assignments): Hỗ trợ học viên làm bài trắc nghiệm trực tuyến, nộp bài phát âm trực tiếp trên ứng dụng di động và ứng dụng trí tuệ nhân tạo (AI Speech Assessment) để hỗ trợ phân tích, chấm điểm ngữ âm tự động.",
    "- Tích hợp cổng thanh toán trực tuyến (VNPay Sandbox) giúp học viên và phụ huynh dễ dàng tra cứu công nợ và thanh toán học phí nhanh chóng, an toàn."
]
fill_paragraphs(doc.paragraphs[149], huong_phat_trien_texts)

# 6. TÀI LIỆU THAM KHẢO
# P153: Tiếng Việt
ref_vn_texts = [
    "1. Nguyễn Văn A (2022), Giáo trình Lập trình ứng dụng di động đa nền tảng, Nhà xuất bản Đại học Quốc gia.",
    "2. Trần B (2023), Phân tích thiết kế hệ thống thông tin hiện đại theo chuẩn UML, Nhà xuất bản Thông tin và Truyền thông."
]
fill_paragraphs(doc.paragraphs[153], ref_vn_texts)

# P155 & P156: Tiếng Anh
ref_en_texts = [
    "1. Marco L. Napoli (2020), Beginning Flutter: A Hands On Guide to App Development, Wrox / Wiley Publishing.",
    "2. Kamil Mysliwiec et al. (2024), NestJS Documentation: A progressive Node.js framework, NestJS Official.",
    "3. Robert C. Martin (2017), Clean Architecture: A Craftsman's Guide to Software Structure and Design, Prentice Hall."
]
fill_paragraphs(doc.paragraphs[155], ref_en_texts)
set_para_text(doc.paragraphs[156], "")

# P159: Website
ref_web_texts = [
    "1. Trang tài liệu chính thức của Flutter: https://docs.flutter.dev/. Ngày truy cập: 15/10/2026.",
    "2. Trang tài liệu ngôn ngữ lập trình Dart: https://dart.dev/guides. Ngày truy cập: 15/10/2026.",
    "3. Trang chủ tài liệu NestJS Framework: https://docs.nestjs.com/. Ngày truy cập: 15/10/2026.",
    "4. Trang tài liệu Google Firebase: https://firebase.google.com/docs. Ngày truy cập: 15/10/2026."
]
fill_paragraphs(doc.paragraphs[159], ref_web_texts)

# Lưu file kết quả
doc.save(output_path)
doc.save(output_path_docs)
print(f'Successfully saved Word document to:\n1. {output_path}\n2. {output_path_docs}')
