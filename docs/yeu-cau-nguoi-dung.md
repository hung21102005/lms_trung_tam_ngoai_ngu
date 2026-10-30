# 📋 TÀI LIỆU ĐẶC TẢ YÊU CẦU NGƯỜI DÙNG (USER REQUIREMENTS SPECIFICATION)

## ĐỀ TÀI: HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ

> **Ngày tài liệu:** 26/10/2026  
> **Áp dụng cho:** Báo cáo Phân tích Thiết kế Hệ thống / Đồ án Phần mềm  
> **Căn cứ nghiệp vụ:** [chuc-nang-de-tai.md](file:///c:/Users/Vi-Hung/my_flutter_pj/XD_HT_LMS/lms_trung_tam_ngoai_ngu/docs/chuc-nang-de-tai.md)  
> **Nền tảng:** Flutter Mobile (iOS/Android), Flutter Web Portal, NestJS Backend, PostgreSQL, Redis, Firebase  

---

## 1. TỔNG QUAN & BỐI CẢNH NGHIỆP VỤ

Hệ thống LMS Trung Tâm Ngoại Ngữ phục vụ toàn diện chu trình vận hành của một cơ sở đào tạo ngoại ngữ chuyên nghiệp:
- Tiếp nhận nhu cầu học tập từ khách vãng lai, tư vấn và kiểm tra trình độ đầu vào.
- Cấp phát tài khoản tập trung, quản lý khóa học, chi nhánh, phòng học.
- Tự động sinh lịch học, chống trùng phòng và trùng giáo viên.
- Điểm danh buổi học trên di động, cảnh báo tức thời cho phụ huynh khi học viên vắng.
- Giao và nộp bài tập đa định dạng (đặc thù bài luyện nói phát âm qua ghi âm trực tiếp).
- Tổ chức thi trực tuyến, tự động đếm giờ, lưu tạm bài làm và tự động chấm điểm trắc nghiệm.
- Quản lý học phí, thu tiền tại quầy, xuất phiếu thu PDF và thanh toán trực tuyến qua VNPay.
- Báo cáo doanh thu, chuyên cần, công nợ và giờ dạy của giáo viên.

---

## 2. XÁC ĐỊNH CÁC NHÓM TÁC NHÂN (ACTORS / USER ROLES)

| STT | Tác nhân (Actor) | Nền tảng sử dụng | Trách nhiệm & Phạm vi nghiệp vụ |
|:---:|:---|:---|:---|
| 1 | **Khách vãng lai** *(Guest)* | Mobile App / Web Landing | Người chưa có tài khoản; tra cứu danh mục khóa học, địa chỉ chi nhánh, gửi form đăng ký nhu cầu học tập để trung tâm tư vấn. |
| 2 | **Học viên** *(Student)* | Flutter Mobile App | Đăng nhập tài khoản được cấp, đổi mật khẩu lần đầu, theo dõi thời khóa biểu, nộp bài tập (văn bản, PDF, ghi âm bài nói Speaking), làm bài thi trực tuyến, tra cứu điểm số, theo dõi điểm danh và thanh toán học phí. |
| 3 | **Phụ huynh** *(Parent)* | Flutter Mobile App | Đăng nhập bằng tài khoản liên kết với con em; nhận thông báo đẩy tức thời khi con vắng học; theo dõi lịch học, kết quả bài tập, điểm thi và tình hình học phí của con. |
| 4 | **Giáo viên** *(Teacher)* | Mobile App + Web Portal | Xem thời khóa biểu giảng dạy; thực hiện điểm danh buổi học tại lớp; giao bài tập về nhà; nghe bài ghi âm phát âm và chấm điểm; ra đề thi từ ngân hàng câu hỏi; chấm bài thi tự luận. |
| 5 | **Thu ngân / Kế toán** *(Cashier)* | Web Admin Portal | Quản lý danh sách hóa đơn học phí; ghi nhận tiền mặt/chuyển khoản tại quầy; xuất phiếu thu PDF có mã QR; xử lý đóng học phí theo đợt (trả góp); xử lý hoàn phí/bảo lưu; theo dõi công nợ quá hạn và xem báo cáo dòng tiền. |
| 6 | **Nhân viên Học vụ / Tuyển sinh** *(Academic Staff)* | Web Admin Portal | Tiếp nhận và chăm sóc Lead tuyển sinh; hẹn kiểm tra xếp lớp (Placement Test); chuyển đổi Lead thành học viên chính thức; quản lý lớp học, tự động sinh lịch học; ghi danh học viên; kiểm tra phòng trống; duyệt đơn xin học bù. |
| 7 | **Quản trị viên** *(Admin)* | Web Admin Portal | Toàn quyền kiểm soát hệ thống: quản lý tài khoản người dùng, phân quyền vai trò (RBAC), cấu hình chi nhánh & phòng học, thiết lập đơn giá khóa học, khóa/mở tài khoản, reset mật khẩu, xem dashboard điều hành và toàn bộ báo cáo doanh thu/học vụ. |

---

## 3. BẢNG ĐẶC TẢ YÊU CẦU NGƯỜI DÙNG (USER REQUIREMENTS MATRIX)

| Mã UR | Tác nhân | Yêu cầu người dùng (User Story) | Mục đích / Giá trị mang lại | Tiêu chí nghiệm thu (Acceptance Criteria) | Độ ưu tiên |
|:---:|:---|:---|:---|:---|:---:|
| **UR-G01** | Khách vãng lai | Tôi muốn xem danh sách các khóa học ngoại ngữ và địa chỉ các cơ sở chi nhánh. | Nắm bắt thông tin đào tạo, học phí niêm yết để lựa chọn khóa học phù hợp. | Hiển thị đầy đủ tên khóa, mô tả, số buổi học, học phí gốc, hotline và địa chỉ chi nhánh. | Must |
| **UR-G02** | Khách vãng lai | Tôi muốn điền form đăng ký thông tin tư vấn học tập trực tuyến. | Được trung tâm liên hệ tư vấn lộ trình và xếp lịch kiểm tra đầu vào. | Form yêu cầu Họ tên, SĐT, Email, Khóa học mong muốn; ghi nhận vào bảng `admission_leads` mà không tạo tài khoản tự do. | Must |
| **UR-S01** | Học viên | Tôi muốn đăng nhập bằng mã học viên/SĐT và bắt buộc đổi mật khẩu trong lần đầu truy cập. | Đảm bảo tính bảo mật cho tài khoản cá nhân do trung tâm khởi tạo sẵn. | Kiểm tra cờ `isFirstLogin = true`; chuyển hướng tới màn hình đổi mật khẩu mới; yêu cầu tối thiểu 8 ký tự. | Must |
| **UR-S02** | Học viên | Tôi muốn xem thời khóa biểu cá nhân theo ngày, tuần, tháng. | Chủ động nắm thời gian, phòng học, giáo viên phụ trách để đi học đúng giờ. | Giao diện Calendar hiển thị rõ tên lớp, ca học, phòng học, trạng thái buổi học (sắp tới, đã học). | Must |
| **UR-S03** | Học viên | Tôi muốn ghi âm trực tiếp bài nói trên ứng dụng và nộp bài tập phát âm. | Rèn luyện kỹ năng Speaking và gửi file âm thanh chất lượng cho giáo viên nhận xét. | Tích hợp công cụ ghi âm micro trên app: có nút Thu âm, Tạm dừng, Nghe lại, Thu lại và tải file nén lên Firebase Storage. | Must |
| **UR-S04** | Học viên | Tôi muốn làm bài thi trực tuyến với đồng hồ đếm ngược và tự động lưu đáp án. | Tham gia kỳ thi định kỳ thuận tiện, không lo mất dữ liệu bài làm khi mạng chập chờn. | Đếm ngược theo thời gian thực; tự động lưu câu trả lời cục bộ mỗi khi chọn; tự động nộp khi hết giờ. | Must |
| **UR-S05** | Học viên | Tôi muốn thanh toán học phí trực tuyến qua cổng thanh toán VNPay. | Tiện lợi đóng học phí từ xa mà không cần đến trực tiếp văn phòng trung tâm. | Chuyển tiếp cổng thanh toán bảo mật; tự động gạch nợ và đổi trạng thái hóa đơn sang `PAID` khi nhận IPN thành công. | Should |
| **UR-S06** | Học viên | Tôi muốn gửi đơn đăng ký học bù khi nghỉ học một buổi có phép. | Theo kịp tiến độ bài học của khóa đào tạo. | Chọn buổi học cần bù; hệ thống hiển thị các lớp cùng cấp độ còn chỗ trống; gửi yêu cầu đến Học vụ duyệt. | Should |
| **UR-P01** | Phụ huynh | Tôi muốn nhận thông báo đẩy tức thì trên điện thoại khi con tôi vắng học. | Kịp thời giám sát việc đi học chuyên cần của con. | Ngay khi giáo viên bấm hoàn tất điểm danh có trạng thái `ABSENT`, Firebase FCM gửi push notification đến máy phụ huynh. | Must |
| **UR-P02** | Phụ huynh | Tôi muốn theo dõi bảng điểm, chuyên cần và nhận xét chi tiết của giáo viên về con. | Đồng hành cùng quá trình tiến bộ ngôn ngữ của con em mình. | Hiển thị lịch sử đi học (% chuyên cần), kết quả bài tập, file nhận xét phát âm của giáo viên. | Must |
| **UR-T01** | Giáo viên | Tôi muốn thực hiện điểm danh học viên từng buổi học trực tiếp trên điện thoại. | Ghi nhận nhanh chóng sĩ số lớp học mà không cần dùng sổ giấy. | Danh sách học viên lớp với các nút chọn: Có mặt (`present`), Vắng (`absent`), Trễ (`late`), Có phép (`excused`); có nút "Có mặt tất cả". | Must |
| **UR-T02** | Giáo viên | Tôi muốn giao bài tập về nhà kèm hạn chót và tài liệu đính kèm (PDF, audio mẫu). | Giao nhiệm vụ rèn luyện sau buổi học cho học viên. | Thiết lập tiêu đề, hướng dẫn, phân loại (Writing, Speaking, Homework), deadline, thang điểm tối đa. | Must |
| **UR-T03** | Giáo viên | Tôi muốn nghe đoạn ghi âm bài nói của học viên trên app và cho điểm, nhận xét. | Đánh giá chính xác phát âm, ngữ điệu và ngữ pháp bài nói của học viên. | Trình phát âm thanh tích hợp; thanh trượt timeline; ô nhập điểm số và ô nhận xét phản hồi chi tiết. | Must |
| **UR-T04** | Giáo viên | Tôi muốn tạo đề thi từ ngân hàng câu hỏi đa dạng các kỹ năng (Nghe, Đọc, Viết, Từ vựng). | Tổ chức thi giữa khóa, cuối khóa công bằng và khoa học. | Chọn câu hỏi thủ công hoặc chọn ngẫu nhiên theo tỷ lệ độ khó; cấu hình thời gian thi, điểm đạt. | Must |
| **UR-C01** | Thu ngân | Tôi muốn tra cứu và quản lý toàn bộ danh sách hóa đơn học phí của học viên. | Kiểm soát các khoản phải thu theo từng chi nhánh, từng lớp học. | Lọc hóa đơn theo trạng thái: Chờ đóng, Đã đóng, Đóng 1 phần, Quá hạn; tìm kiếm theo tên hoặc mã học viên. | Must |
| **UR-C02** | Thu ngân | Tôi muốn ghi nhận thanh toán tiền mặt/chuyển khoản tại quầy cho học viên. | Cập nhật số tiền đã thu và trừ dần công nợ của học viên. | Nhập số tiền thu thực tế, hình thức đóng, mã tham chiếu ngân hàng; hệ thống tự động đổi trạng thái hóa đơn. | Must |
| **UR-C03** | Thu ngân | Tôi muốn xuất và in phiếu thu học phí định dạng PDF chuẩn có mã QR. | Cung cấp chứng từ nộp tiền hợp pháp cho học viên và phụ huynh. | Sinh file PDF chứa logo trung tâm, thông tin học viên, số tiền, nội dung nộp, chữ ký thu ngân và mã QR tra cứu. | Must |
| **UR-C04** | Thu ngân | Tôi muốn theo dõi danh sách học viên nợ học phí quá hạn và gửi cảnh báo nhắc nợ. | Đôn đốc thu hồi học phí đúng hạn quy định. | Phân loại công nợ: quá hạn dưới 15 ngày, 15–30 ngày, trên 30 ngày; kích hoạt gửi tin nhắc nợ tự động. | Should |
| **UR-C05** | Thu ngân | Tôi muốn xử lý yêu cầu hoàn tiền hoặc bảo lưu học phí khi học viên có đơn rút học. | Tuân thủ chính sách tài chính của trung tâm và bảo vệ quyền lợi học viên. | Nhập lý do, tính toán số tiền hoàn trả hoặc số tiền bảo lưu theo quy chế; tạo phiếu hoàn phí/bảo lưu. | Should |
| **UR-A01** | Nhân viên Học vụ | Tôi muốn tiếp nhận danh sách yêu cầu tư vấn mới và cập nhật kết quả kiểm tra đầu vào. | Phân loại nhu cầu và tư vấn lộ trình học tập chính xác cho học viên tiềm năng. | Quản lý danh sách Lead; cập nhật trạng thái (Mới, Đã liên hệ, Đã test, Chốt lớp); lưu điểm Placement test. | Must |
| **UR-A02** | Nhân viên Học vụ | Tôi muốn thực hiện chuyển đổi Lead thành học viên chính thức chỉ với 1 click. | Tiết kiệm thời gian nhập liệu và giảm sai sót dữ liệu. | Tự động tạo hồ sơ học viên, sinh mã HV, tạo tài khoản đăng nhập tạm, xếp vào lớp học, sinh hóa đơn học phí. | Must |
| **UR-A03** | Nhân viên Học vụ | Tôi muốn tạo lớp học mới với lịch học cố định và hệ thống tự động sinh các buổi học chi tiết. | Tự động hóa xếp lịch và loại trừ các ngày lễ nghỉ đã cấu hình. | Chọn khóa học, phòng, giáo viên, thứ trong tuần, giờ học; thuật toán tự sinh danh sách `class_sessions`. | Must |
| **UR-A04** | Nhân viên Học vụ | Tôi muốn hệ thống tự động cảnh báo khi có hiện tượng trùng phòng hoặc trùng lịch giáo viên. | Tránh xung đột cơ sở vật chất và thời gian giảng dạy. | Kiểm tra chéo khung giờ; hiển thị thông báo lỗi cụ thể nếu phòng hoặc giáo viên đã có lịch dạy khác. | Must |
| **UR-AD01** | Quản trị viên | Tôi muốn quản lý tập trung toàn bộ tài khoản người dùng và phân quyền theo vai trò. | Bảo vệ an toàn dữ liệu học vụ và phân định rõ trách nhiệm từng nhân sự. | Phân quyền RBAC (SuperAdmin, BranchAdmin, AcademicStaff, Cashier, Teacher, Student, Parent); khóa/mở tài khoản. | Must |
| **UR-AD02** | Quản trị viên | Tôi muốn đặt lại mật khẩu tạm thời cho người dùng khi họ quên hoặc báo mất tài khoản. | Hỗ trợ người dùng truy cập lại hệ thống nhanh chóng. | Cấp mật khẩu tạm an toàn và bật lại cờ `isFirstLogin = true` để bắt buộc người dùng đổi mật khẩu khi đăng nhập lại. | Must |
| **UR-AD03** | Quản trị viên | Tôi muốn xem Dashboard tổng quan các chỉ số điều hành (học viên, doanh thu, công nợ, lớp học). | Nắm bắt nhanh chóng tình hình hoạt động kinh doanh và đào tạo của trung tâm. | Biểu đồ trực quan doanh thu theo tháng, so sánh giữa các chi nhánh, tỷ lệ lấp đầy phòng học. | Should |

---

## 4. BẢNG PHÂN LOẠI YÊU CẦU CHỨC NĂNG (FUNCTIONAL REQUIREMENTS - FR)

Hệ thống được chuẩn hóa thành 13 nhóm chức năng theo tài liệu [chuc-nang-de-tai.md](file:///c:/Users/Vi-Hung/my_flutter_pj/XD_HT_LMS/lms_trung_tam_ngoai_ngu/docs/chuc-nang-de-tai.md):

1. **FR-AUTH (Xác thực & Bảo mật):** Đăng nhập JWT (Access Token 15p, Refresh Token 7 ngày); Kích hoạt đổi mật khẩu lần đầu; Đổi mật khẩu cá nhân; Quên mật khẩu qua OTP; Đăng xuất và hủy token; Phân quyền RBAC qua Middleware Guard.
2. **FR-LEAD (Tiếp nhận & Tuyển sinh):** Form đăng ký nhu cầu công khai; Quản lý và lọc danh sách Lead; Cập nhật tiến trình tư vấn và lịch test; Chuyển đổi Lead thành học viên chính thức (tự động tạo hồ sơ, tài khoản, xếp lớp, sinh hóa đơn).
3. **FR-USER (Quản lý Người dùng & Cấp tài khoản):** Tạo tài khoản học viên, phụ huynh (liên kết con), giáo viên, nhân viên; Tra cứu, lọc danh sách người dùng; Xem chi tiết hồ sơ; Khóa/mở khóa tài khoản; Admin reset mật khẩu; Import danh sách từ Excel; Phân quyền vai trò.
4. **FR-BRANCH (Quản lý Chi nhánh & Phòng học):** Thêm, sửa chi nhánh; Xem danh sách chi nhánh; Thêm, sửa phòng học và trang thiết bị; Kiểm tra phòng trống theo khung giờ; Vô hiệu hóa phòng/chi nhánh khi sửa chữa.
5. **FR-COURSE (Quản lý Khóa học & Chương trình học):** Tạo, cập nhật khóa học; Xem danh mục khóa học; Quản lý cấp độ (Levels) và điều kiện tiên quyết; Quản lý Module bài học; Quản lý bài học chi tiết; Quản lý và tải tài liệu học tập đa phương tiện (PDF, Audio, Video).
6. **FR-CLASS (Quản lý Lớp học & Xếp lịch):** Tạo lớp học mới; Tự động sinh danh sách buổi học (sessions); Quản lý danh sách lớp; Cập nhật thông tin lớp; Phân bổ học viên vào lớp (kiểm tra sĩ số); Can thiệp buổi học (đổi phòng đột xuất, giáo viên dạy thay); Xem lịch dạy giáo viên; Xem lịch học học viên/phụ huynh; Quản lý vòng đời trạng thái lớp (`waiting` $\rightarrow$ `active` $\rightarrow$ `completed` $\rightarrow$ `archived`).
7. **FR-ATT (Điểm danh & Chuyên cần):** Điểm danh buổi học trên app di động; Chỉnh sửa điểm danh; Xem lịch sử chuyên cần cá nhân (Calendar Heatmap); Thống kê chuyên cần toàn lớp; Đăng ký học bù trực tuyến; Duyệt yêu cầu học bù; Tự động thông báo phụ huynh khi con vắng học.
8. **FR-ASG (Bài tập & Nộp bài):** Tạo bài tập về nhà (kèm hạn nộp, tài liệu mẫu); Xem danh sách bài tập; Nộp bài tập đa định dạng (text, file PDF/hình ảnh); Ghi âm bài nói trực tiếp (Speaking Audio trên app); Quản lý danh sách bài nộp; Chấm điểm và nhận xét phát âm; Xem kết quả bài tập.
9. **FR-EXAM (Thi & Kiểm tra trực tuyến):** Quản lý ngân hàng câu hỏi; Quản lý câu hỏi đa dạng (Trắc nghiệm, Điền khuyết, Nối cặp, Sắp xếp, Tự luận); Tạo đề thi trực tuyến; Xem danh sách bài thi; Làm bài thi trực tuyến trên app (đồng hồ đếm ngược, tự động lưu câu trả lời); Nộp bài an toàn (tự động thu bài khi hết giờ); Tự động chấm điểm trắc nghiệm; Chấm thi tự luận; Xem bảng điểm phân tích kỹ năng.
10. **FR-FIN (Quản lý Học phí & Tài chính):** Tự động sinh hóa đơn học phí khi ghi danh; Xem và lọc danh sách hóa đơn; Ghi nhận thanh toán tại quầy (tiền mặt/chuyển khoản); Thanh toán học phí trực tuyến qua VNPay; Đóng học phí theo đợt (trả góp); Quản lý và cảnh báo công nợ; Xử lý hoàn tiền/bảo lưu; Quản lý mã khuyến mãi; Xem lịch sử học phí cá nhân; Xuất phiếu thu PDF có mã QR.
11. **FR-NOTI (Thông báo & Nhắc nhở):** Bắn push notification qua Firebase Cloud Messaging (FCM); Trung tâm thông báo in-app; Kịch bản tự động: Bắn push cho phụ huynh khi con vắng học; Nhắc nhở deadline bài tập trước 24h; Nhắc nhở hạn nộp học phí trước 3 ngày; Gửi thông báo truyền thông hàng loạt; Tùy chỉnh cài đặt nhận thông báo.
12. **FR-RPT (Báo cáo & Thống kê):** Dashboard tổng quan điều hành cho Admin; Báo cáo doanh thu và dòng tiền; Báo cáo chuyên cần học tập; Báo cáo kết quả học tập và điểm số; Báo cáo chi tiết công nợ học phí; Báo cáo thống kê giờ dạy giáo viên; Xuất báo cáo ra file Excel (.xlsx); Xuất báo cáo tổng kết ra file PDF.
13. **FR-PROF (Quản lý Hồ sơ cá nhân):** Xem hồ sơ cá nhân; Cập nhật thông tin cá nhân cơ bản; Cập nhật ảnh đại diện (cắt ảnh, nén lưu Cloud Storage); Đổi mật khẩu tài khoản; Trang tổng quan học tập cá nhân (Home Dashboard).

---

## 5. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS - NFR)

| Nhóm yêu cầu | Mã NFR | Nội dung đặc tả kỹ thuật | Chỉ số mục tiêu |
|:---|:---:|:---|:---|
| **Hiệu năng (Performance)** | NFR-P01 | Thời gian phản hồi của các truy vấn danh mục, lịch học, điểm danh. | $\le 500$ ms trong điều kiện mạng bình thường. |
| | NFR-P02 | Tải lên file ghi âm bài nói Speaking (nén định dạng M4A/AAC dưới 10MB). | Hoàn tất trong vòng $\le 3$ giây qua mạng 4G/WiFi. |
| | NFR-P03 | Cơ chế Auto-save câu trả lời bài thi trực tuyến. | Tự động đồng bộ câu trả lời mỗi khi người dùng chọn đáp án hoặc mỗi 15 giây. |
| **Bảo mật (Security)** | NFR-S01 | Bảo vệ truy cập API và phân quyền người dùng. | Xác thực JWT Access Token (15 phút) kết hợp Refresh Token (7 ngày); RBAC Middleware kiểm tra role chặt chẽ. |
| | NFR-S02 | Mã hóa mật khẩu người dùng trong cơ sở dữ liệu. | Bắt buộc băm mật khẩu bằng thuật toán Bcrypt với hệ số Salt Rounds = 12. |
| | NFR-S03 | Lưu trữ an toàn token trên thiết bị di động. | Lưu trữ bằng `flutter_secure_storage` (Android KeyStore và iOS Keychain). |
| | NFR-S04 | Chữ ký số xác thực thanh toán trực tuyến. | Kiểm tra tính toàn vẹn chữ ký HMAC-SHA512 của dữ liệu callback từ cổng VNPay. |
| **Độ tin cậy & Toàn vẹn (Reliability)** | NFR-R01 | Tính toàn vẹn giao dịch tài chính và học vụ. | Toàn bộ thao tác ghi nhận thanh toán, chuyển đổi lead và xếp lớp bắt buộc thực thi trong PostgreSQL Database Transactions (ACID). |
| | NFR-R02 | Tính sẵn sàng của hệ thống (Availability). | Đạt tối thiểu 99.5% thời gian hoạt động ổn định. |
| | NFR-R03 | Sao lưu dữ liệu dự phòng (Backup). | Tự động sao lưu cơ sở dữ liệu PostgreSQL hàng ngày (Daily automated backup). |
| **Khả năng sử dụng (Usability)** | NFR-U01 | Tính đáp ứng giao diện đa nền tảng (Responsive). | Ứng dụng chạy mượt mà trên màn hình điện thoại di động (Android 8+, iOS 13+) và trình duyệt Web máy tính độ phân giải từ 1366x768 trở lên. |
| | NFR-U02 | Tốc độ khung hình giao diện di động. | Đạt chuẩn 60 fps ổn định trên thiết bị di động nhờ kiến trúc BLoC quản lý trạng thái. |

---

## 6. QUY TẮC NGHIỆP VỤ BẮT BUỘC (BUSINESS RULES - BR)

- **BR-01 (Cấp phát tài khoản tập trung):** Học viên và Phụ huynh không tự đăng ký tài khoản chính thức tự do. Tài khoản chỉ được khởi tạo bởi Trung tâm (Admin/Học vụ) và bắt buộc gắn với hồ sơ học vụ (`StudentProfile`), mã học viên duy nhất và lớp học tương ứng.
- **BR-02 (Kích hoạt lần đầu):** Mọi tài khoản mới tạo đều có cờ `isFirstLogin = true`. Khi đăng nhập lần đầu bằng mật khẩu tạm, hệ thống bắt buộc người dùng xác thực thông tin và đổi mật khẩu mới thì mới được truy cập các tính năng bên trong.
- **BR-03 (Chống trùng phòng & Trùng lịch giáo viên):** Khi tạo lớp học hoặc sinh lịch học, hệ thống bắt buộc kiểm tra giao thoa thời gian: không thể xếp 2 lớp học trong cùng 1 phòng vào cùng một khung giờ, và một giáo viên không thể dạy 2 lớp tại cùng một thời điểm.
- **BR-04 (Tự động sinh hóa đơn khi xếp lớp):** Khi học viên được ghi danh chính thức vào lớp học, hệ thống tự động sinh 01 hóa đơn học phí (`INV-YYYY-MM-XXXX`) với hạn thanh toán mặc định trước ngày khai giảng 03 ngày.
- **BR-05 (Ràng buộc nộp bài ghi âm luyện nói):** Với các bài tập thuộc loại `SPEAKING`, hệ thống bắt buộc học viên phải đính kèm ít nhất 01 file ghi âm âm thanh hợp lệ (thời lượng từ 15 giây đến 5 phút) mới cho phép bấm nộp bài.
- **BR-06 (Cảnh báo vắng học thời gian thực):** Ngay khi giáo viên hoàn tất điểm danh và có học viên vắng học không phép, hệ thống kích hoạt sự kiện nền gửi thông báo đẩy (Push Notification) ngay lập tức đến thiết bị của phụ huynh liên kết.
