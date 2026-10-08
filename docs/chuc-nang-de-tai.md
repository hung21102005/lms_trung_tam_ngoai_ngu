# 📋 CHI TIẾT CHỨC NĂNG CỦA ĐỀ TÀI

# HỆ THỐNG QUẢN LÝ HỌC TẬP (LMS) TRUNG TÂM NGOẠI NGỮ

> **Tên đề tài:** Xây dựng hệ thống quản lý học tập trực tuyến cho trung tâm ngoại ngữ  
> **Ngày cập nhật:** 2026-10-08  
> **Công nghệ:** Flutter (Dart) · NestJS (Node.js/TypeScript) · PostgreSQL · Firebase Services  

---

## MỤC LỤC

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Đối tượng sử dụng](#2-đối-tượng-sử-dụng)
3. [Quy tắc nghiệp vụ quản lý tài khoản & phân quyền](#3-quy-tắc-nghiệp-vụ-quản-lý-tài-khoản--phân-quyền)
4. [Danh sách chức năng tổng hợp](#4-danh-sách-chức-năng-tổng-hợp)
5. [Chi tiết từng nhóm chức năng](#5-chi-tiết-từng-nhóm-chức-năng)
   - 5.1. [Xác thực & Bảo mật (Auth)](#51-xác-thực--bảo-mật-auth)
   - 5.2. [Tiếp nhận Đăng ký & Tư vấn tuyển sinh (Leads / Admissions)](#52-tiếp-nhận-đăng-ký--tư-vấn-tuyển-sinh-leads--admissions)
   - 5.3. [Quản lý Người dùng & Cấp phát tài khoản (User Management)](#53-quản-lý-người-dùng--cấp-phát-tài-khoản-user-management)
   - 5.4. [Quản lý Chi nhánh & Phòng học (Branch & Room)](#54-quản-lý-chi-nhánh--phòng-học-branch--room)
   - 5.5. [Quản lý Khóa học & Chương trình học (Course & Syllabus)](#55-quản-lý-khóa-học--chương-trình-học-course--syllabus)
   - 5.6. [Quản lý Lớp học & Xếp lịch (Class & Scheduling)](#56-quản-lý-lớp-học--xếp-lịch-class--scheduling)
   - 5.7. [Điểm danh & Chuyên cần (Attendance & Makeup)](#57-điểm-danh--chuyên-cần-attendance--makeup)
   - 5.8. [Bài tập & Nộp bài (Assignments & Audio Submissions)](#58-bài-tập--nộp-bài-assignments--audio-submissions)
   - 5.9. [Thi & Kiểm tra trực tuyến (Online Exams & Question Bank)](#59-thi--kiểm-tra-trực-tuyến-online-exams--question-bank)
   - 5.10. [Quản lý Học phí & Tài chính (Finance & Invoices)](#510-quản-lý-học-phí--tài-chính-finance--invoices)
   - 5.11. [Thông báo & Nhắc nhở (Notifications & Triggers)](#511-thông-báo--nhắc-nhở-notifications--triggers)
   - 5.12. [Báo cáo & Thống kê (Reports & Analytics)](#512-báo-cáo--thống-kê-reports--analytics)
   - 5.13. [Quản lý Hồ sơ cá nhân (Personal Profile)](#513-quản-lý-hồ-sơ-cá-nhân-personal-profile)

---

## 1. TỔNG QUAN HỆ THỐNG

Hệ thống LMS Trung Tâm Ngoại Ngữ là nền tảng quản lý học tập và vận hành toàn diện, được thiết kế chuyên biệt cho các trung tâm đào tạo ngoại ngữ (tiếng Anh, tiếng Nhật, tiếng Hàn, tiếng Trung,...). Hệ thống số hóa toàn bộ chu trình: tiếp nhận nhu cầu học tập, xếp lớp, điểm danh, giao bài tập (bao gồm bài nói ghi âm), tổ chức thi kiểm tra, thu học phí và báo cáo học vụ.

### Kiến trúc nền tảng:
- **Ứng dụng di động (Flutter Mobile App):** Phục vụ Học viên, Phụ huynh và Giáo viên trên Android & iOS.
- **Cổng thông tin quản trị (Flutter Web / Web Portal):** Phục vụ Quản trị viên (Admin), Nhân viên học vụ, Tư vấn viên và Thu ngân.
- **Backend API (NestJS):** Xử lý toàn bộ logic nghiệp vụ, bảo mật, RBAC, WebSockets và tích hợp cổng thanh toán.
- **Cơ sở dữ liệu chính (PostgreSQL):** Đảm bảo tính toàn vẹn quan hệ (ACID) cho dữ liệu học vụ, tài chính, lớp học.
- **Firebase Services:** Firebase Cloud Messaging (FCM - Push notification) và Firebase Storage (lưu trữ file âm thanh, tài liệu PDF, hình ảnh).

---

## 2. ĐỐI TƯỢNG SỬ DỤNG

| STT | Vai trò | Nền tảng | Trách nhiệm & Quyền hạn |
|:---:|:---|:---|:---|
| 1 | **Quản trị viên (Admin)** | Web | Quản trị toàn bộ hệ thống, tạo và quản lý tài khoản, cấu hình chi nhánh, xem báo cáo doanh thu & học vụ toàn diện. |
| 2 | **Nhân viên Học vụ / Tư vấn** | Web | Tiếp nhận yêu cầu tư vấn, xếp lớp, quản lý hồ sơ học viên, duyệt học bù, theo dõi chuyên cần. |
| 3 | **Thu ngân** | Web | Quản lý học phí, tạo hóa đơn, thu tiền, đối soát công nợ, xuất phiếu thu/hóa đơn. |
| 4 | **Giáo viên** | Mobile + Web | Điểm danh học viên, tạo bài tập, chấm bài (nghe file ghi âm nói), ra đề thi, nhập điểm và nhận xét. |
| 5 | **Học viên** | Mobile | Kích hoạt tài khoản được cấp, xem lịch học, nộp bài tập (text/file/audio), làm bài thi trực tuyến, xem điểm số và thanh toán học phí. |
| 6 | **Phụ huynh** | Mobile | Đăng nhập tài khoản được trung tâm cấp (liên kết với con) để theo dõi lịch học, điểm danh, kết quả học tập, nhận xét của giáo viên và học phí của con. |
| 7 | **Khách vãng lai (Người dùng mới)** | Mobile / Web | Người chưa có tài khoản; chỉ có quyền gửi thông tin đăng ký nhu cầu học tập để trung tâm liên hệ tư vấn. |

---

## 3. QUY TẮC NGHIỆP VỤ QUẢN LÝ TÀI KHOẢN & PHÂN QUYỀN

Nhằm đảm bảo tính chính xác của dữ liệu học vụ và an toàn thông tin, hệ thống áp dụng các quy tắc quản lý tài khoản bắt buộc sau:

### 3.1. Nguyên tắc cấp phát tài khoản tập trung
1. **Trung tâm chịu trách nhiệm tạo và cấp phát tài khoản:**
   - Học viên và Phụ huynh **KHÔNG tự đăng ký tài khoản chính thức** trên ứng dụng.
   - Tài khoản chỉ được khởi tạo sau khi học viên đã hoàn tất thủ tục đăng ký, kiểm tra đầu vào và được xếp lớp chính thức tại trung tâm.
2. **Bắt buộc liên kết dữ liệu nghiệp vụ ngay từ khi tạo tài khoản:**
   - **Tài khoản Học viên:** Bắt buộc gắn liền với Hồ sơ học viên (`StudentProfile`), mã học viên duy nhất, chi nhánh, lớp học (`Class`), khóa học (`Course`), lộ trình học tập, lịch học, điểm danh và hóa đơn học phí.
   - **Tài khoản Phụ huynh:** Bắt buộc liên kết trực tiếp với một hoặc nhiều học viên tương ứng (`parent_students`). Phụ huynh chỉ được xem dữ liệu thuộc về con mình.
3. **Quy trình kích hoạt lần đầu (First-time Login & Activation):**
   - Khi được cấp tài khoản, người dùng nhận thông tin đăng nhập tạm thời (Mã học viên / SĐT / Email kèm mật khẩu mặc định an toàn).
   - Khi đăng nhập lần đầu, hệ thống bắt buộc người dùng: xác thực thông tin cá nhân và thiết lập mật khẩu riêng (`is_first_login = false`).

### 3.2. Cơ chế dành cho người dùng mới (Đăng ký nhu cầu học tập)
1. **Khách vãng lai gửi yêu cầu tư vấn (Lead Request):**
   - Người chưa có tài khoản có thể gửi thông tin nhu cầu học tập (họ tên, SĐT, email, ngôn ngữ/khóa học quan tâm, mục tiêu học tập).
2. **Không tự động sinh tài khoản học viên chính thức:**
   - Việc gửi thông tin chỉ tạo một bản ghi yêu cầu tư vấn (`admission_leads`), **hoàn toàn không tạo tài khoản học viên chính thức** và không cho phép truy cập vào các tính năng học tập nội bộ.
3. **Quy trình tiếp nhận và chuyển đổi của trung tâm:**
   - Tư vấn viên tiếp nhận lead, liên hệ tư vấn, hẹn kiểm tra trình độ xếp lớp.
   - Khi học viên chính thức nhập học và đóng phí, nhân viên học vụ thực hiện thao tác **Chuyển đổi thành học viên chính thức (Convert Lead to Student)**: hệ thống tự động sinh tài khoản, liên kết lớp học, tạo hóa đơn và gửi thông tin kích hoạt cho học viên/phụ huynh.

### 3.3. Quyền hạn quản trị tài khoản của Admin / Học vụ
- Có toàn quyền xem, chỉnh sửa thông tin hồ sơ, khóa/mở khóa tài khoản (soft delete / activate).
- Có quyền **Đặt lại mật khẩu (Reset Password)** và cấp mật khẩu tạm thời khi người dùng quên hoặc gặp sự cố đăng nhập.
- Phân quyền theo vai trò (RBAC) chặt chẽ: Không người dùng nào có thể tự nâng quyền hoặc tự gán mình vào lớp học nếu không qua Admin/Học vụ.

---

## 4. DANH SÁCH CHỨC NĂNG TỔNG HỢP

| STT | Nhóm chức năng | Mã nhóm | Số lượng CN | Đối tượng chính |
|:---:|:---|:---:|:---:|:---|
| 1 | Xác thực & Bảo mật | `AUTH` | 8 | Tất cả |
| 2 | Tiếp nhận Đăng ký & Tư vấn tuyển sinh | `LEAD` | 4 | Khách vãng lai, Học vụ, Admin |
| 3 | Quản lý Người dùng & Cấp phát tài khoản | `USER` | 9 | Admin, Học vụ |
| 4 | Quản lý Chi nhánh & Phòng học | `BRANCH` | 6 | Admin, Học vụ |
| 5 | Quản lý Khóa học & Chương trình học | `COURSE` | 7 | Admin, Học vụ, Giáo viên |
| 6 | Quản lý Lớp học & Xếp lịch | `CLASS` | 10 | Admin, Học vụ, Giáo viên, Học viên |
| 7 | Điểm danh & Chuyên cần | `ATT` | 7 | Giáo viên, Học vụ, Học viên, Phụ huynh |
| 8 | Bài tập & Nộp bài | `ASG` | 7 | Giáo viên, Học viên |
| 9 | Thi & Kiểm tra trực tuyến | `EXAM` | 9 | Giáo viên, Học viên |
| 10 | Quản lý Học phí & Tài chính | `FIN` | 10 | Admin, Thu ngân, Học viên, Phụ huynh |
| 11 | Thông báo & Nhắc nhở | `NOTI` | 7 | Tất cả |
| 12 | Báo cáo & Thống kê | `RPT` | 8 | Admin, Học vụ, Thu ngân |
| 13 | Quản lý Hồ sơ cá nhân | `PROF` | 5 | Tất cả |
|  | **TỔNG CỘNG** | | **97** | |

---

## 5. CHI TIẾT TỪNG NHÓM CHỨC NĂNG

---

### 5.1. XÁC THỰC & BẢO MẬT (Auth)

Nhóm chức năng quản lý việc đăng nhập, bảo vệ phiên làm việc và kiểm soát quyền truy cập dựa trên tài khoản do trung tâm cấp.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | AUTH-01 | Đăng nhập hệ thống | Người dùng đăng nhập bằng Email/SĐT/Mã tài khoản kết hợp mật khẩu được trung tâm cấp. Hệ thống kiểm tra thông tin, trạng thái tài khoản (đang hoạt động hay bị khóa) và trả về Access Token (JWT - 15 phút) cùng Refresh Token (7 ngày). | Tất cả |
| 2 | AUTH-02 | Kích hoạt & Thiết lập mật khẩu lần đầu | Áp dụng cho tài khoản mới được trung tâm cấp (`is_first_login = true`). Khi đăng nhập lần đầu bằng mật khẩu tạm, hệ thống hiển thị màn hình kích hoạt: người dùng xác nhận thông tin cá nhân và bắt buộc thiết lập mật khẩu riêng mới để hoàn tất kích hoạt. | HV, Phụ huynh, GV |
| 3 | AUTH-03 | Đăng nhập bằng mạng xã hội | Cho phép liên kết tài khoản Google / Facebook với tài khoản đã được trung tâm cấp sẵn (xác thực trùng khớp email), giúp đăng nhập nhanh mà không cần nhập mật khẩu. Hệ thống không tạo mới tài khoản tự do từ OAuth. | Tất cả |
| 4 | AUTH-04 | Quên mật khẩu & Đặt lại qua OTP | Người dùng quên mật khẩu nhập Email/SĐT đã đăng ký. Hệ thống gửi mã OTP xác thực qua email/SMS. Sau khi nhập đúng OTP trong thời hạn hiệu lực, người dùng được phép tạo mật khẩu mới. | Tất cả |
| 5 | AUTH-05 | Đổi mật khẩu cá nhân | Người dùng chủ động đổi mật khẩu định kỳ: nhập mật khẩu cũ (hệ thống kiểm tra xác thực) và nhập mật khẩu mới đảm bảo độ mạnh (tối thiểu 8 ký tự, có chữ và số). | Tất cả |
| 6 | AUTH-06 | Làm mới phiên đăng nhập (Refresh Token) | Khi Access Token hết hạn trong quá trình sử dụng, ứng dụng tự động gửi Refresh Token lên máy chủ để cấp Access Token mới ngầm dưới nền, không làm gián đoạn trải nghiệm người dùng. | Hệ thống (tự động) |
| 7 | AUTH-07 | Đăng xuất | Người dùng đăng xuất khỏi thiết bị. Hệ thống hủy Refresh Token trong cơ sở dữ liệu và gỡ bỏ FCM token của thiết bị để ngừng nhận thông báo đẩy. | Tất cả |
| 8 | AUTH-08 | Phân quyền truy cập theo vai trò (RBAC) | Toàn bộ API và giao diện được kiểm soát chặt chẽ bởi RBAC Middleware. Người dùng chỉ được truy cập dữ liệu và chức năng đúng với vai trò được trung tâm phân bổ (Admin, Học vụ, Thu ngân, Giáo viên, Học viên, Phụ huynh). | Hệ thống |

---

### 5.2. TIẾP NHẬN ĐĂNG KÝ & TƯ VẤN TUYỂN SINH (Leads / Admissions)

Nhóm chức năng phục vụ việc tiếp nhận nhu cầu học tập từ khách vãng lai, quản lý quy trình tư vấn và chuyển đổi thành học viên chính thức.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | LEAD-01 | Đăng ký nhu cầu học tập (Public Lead) | Người dùng mới hoặc phụ huynh chưa có tài khoản có thể gửi thông tin đăng ký tư vấn qua ứng dụng/web: họ tên, SĐT, email, khóa học/ngôn ngữ quan tâm, trình độ hiện tại, mục tiêu học tập. Thao tác này chỉ ghi nhận yêu cầu tư vấn, KHÔNG tạo tài khoản học viên chính thức. | Khách vãng lai |
| 2 | LEAD-02 | Xem & Lọc danh sách yêu cầu tư vấn | Nhân viên học vụ/tư vấn viên xem danh sách các yêu cầu đăng ký mới; hỗ trợ tìm kiếm, lọc theo ngày gửi, khóa học quan tâm, chi nhánh mong muốn, trạng thái tư vấn (Mới, Đã liên hệ, Đã test đầu vào, Đã chốt lớp, Hủy). | Học vụ, Admin |
| 3 | LEAD-03 | Cập nhật tiến trình tư vấn & Ghi chú | Tư vấn viên ghi nhận lịch sử chăm sóc, kết quả bài kiểm tra đầu vào (Placement Test), lớp học dự kiến, lịch hẹn tư vấn và các ghi chú đặc biệt của học viên. | Học vụ |
| 4 | LEAD-04 | Chuyển đổi thành học viên chính thức | Khi học viên xác nhận nhập học và đóng phí, nhân viên học vụ nhấn "Chuyển đổi thành học viên": hệ thống tự động tạo Hồ sơ học viên, tạo Tài khoản đăng nhập chính thức, xếp vào lớp học đã chọn, tạo hóa đơn học phí và gửi thông tin kích hoạt tài khoản qua SMS/Email. | Học vụ, Admin |

---

### 5.3. QUẢN LÝ NGƯỜI DÙNG & CẤP PHÁT TÀI KHOẢN (User Management)

Nhóm chức năng dành cho Admin và Học vụ để quản trị tập trung hồ sơ nhân sự, giáo viên, học viên và phụ huynh.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | USER-01 | Tạo & Cấp phát tài khoản học viên | Trung tâm tạo tài khoản học viên trực tiếp: nhập thông tin cá nhân, mã học viên tự sinh (ví dụ: `HV2026-0012`), tự động tạo hồ sơ học viên (`StudentProfile`), gán chi nhánh và chỉ định lớp học. Mật khẩu tạm thời được cấp để học viên kích hoạt lần đầu. | Admin, Học vụ |
| 2 | USER-02 | Tạo & Cấp phát tài khoản phụ huynh | Trung tâm tạo tài khoản cho phụ huynh và bắt buộc chọn liên kết với một hoặc nhiều học viên tương ứng (`parent_students`). Phụ huynh sau khi kích hoạt có quyền xem toàn bộ dữ liệu học tập của con. | Admin, Học vụ |
| 3 | USER-03 | Tạo & Cấp phát tài khoản giáo viên/nhân viên | Tạo tài khoản cho giáo viên kèm hồ sơ chuyên môn (ngôn ngữ giảng dạy, chứng chỉ TESOL/IELTS, bằng cấp, đơn giá giờ dạy) hoặc tài khoản nhân viên học vụ/thu ngân kèm quyền hạn theo chi nhánh. | Admin |
| 4 | USER-04 | Xem danh sách người dùng | Hiển thị danh sách tất cả tài khoản, phân trang, tìm kiếm theo tên, SĐT, mã học viên/giáo viên, lọc theo vai trò, chi nhánh, trạng thái hoạt động. | Admin, Học vụ |
| 5 | USER-05 | Xem chi tiết hồ sơ người dùng | Xem đầy đủ thông tin: hồ sơ cá nhân, các lớp học đang tham gia, lịch sử điểm danh, bảng điểm, các hóa đơn học phí, thông tin phụ huynh/học viên liên kết. | Admin, Học vụ |
| 6 | USER-06 | Khóa / Mở khóa tài khoản | Admin có quyền tạm khóa tài khoản (đặt `is_active = false`) khi học viên nghỉ học hoặc nhân viên nghỉ việc. Tài khoản bị khóa không thể đăng nhập. Có thể mở khóa lại bất kỳ lúc nào. | Admin |
| 7 | USER-07 | Đặt lại mật khẩu bởi Admin (Reset Password) | Khi người dùng quên mật khẩu và yêu cầu trung tâm hỗ trợ, Admin có quyền đặt lại mật khẩu về giá trị tạm thời và bật lại cờ `is_first_login = true` để người dùng đổi lại mật khẩu khi đăng nhập. | Admin |
| 8 | USER-08 | Import danh sách học viên từ Excel | Hỗ trợ nhập danh sách học viên hàng loạt từ file Excel (.xlsx). Hệ thống kiểm tra dữ liệu, tự động tạo hồ sơ học viên, tạo tài khoản và sinh thông tin đăng nhập tạm để gửi cho học viên. | Admin, Học vụ |
| 9 | USER-09 | Phân quyền & Quản lý vai trò (Role Assignment) | Gán một hoặc nhiều vai trò cho tài khoản (ví dụ: vừa là Giáo viên vừa là Quản lý học vụ), phân bổ phạm vi chi nhánh trực thuộc. | Admin |

---

### 5.4. QUẢN LÝ CHI NHÁNH & PHÒNG HỌC (Branch & Room)

Quản lý cơ sở vật chất và không gian giảng dạy của hệ thống trung tâm.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | BRANCH-01 | Quản lý chi nhánh | Thêm mới, cập nhật thông tin chi nhánh: tên cơ sở, địa chỉ, số hotline, email liên hệ, logo chi nhánh, trạng thái hoạt động. | Admin |
| 2 | BRANCH-02 | Xem danh sách chi nhánh | Hiển thị danh sách tất cả chi nhánh của trung tâm kèm số lượng phòng học, số lớp đang mở tại từng cơ sở. | Admin, Học vụ |
| 3 | BRANCH-03 | Quản lý phòng học | Thêm, sửa phòng học thuộc chi nhánh: tên phòng (A101, Lab 2,...), sức chứa tối đa, trang thiết bị (máy chiếu, loa nghe, TV, điều hòa) và trạng thái sẵn sàng. | Admin |
| 4 | BRANCH-04 | Xem danh sách phòng học | Xem danh sách phòng học theo từng chi nhánh, lọc theo sức chứa và trạng thái sử dụng. | Admin, Học vụ |
| 5 | BRANCH-05 | Kiểm tra phòng trống theo khung giờ | Tra cứu phòng học còn trống trong khung giờ cụ thể (ngày học, giờ bắt đầu - kết thúc) để hỗ trợ xếp lớp mới hoặc xếp lịch học bù/thi cử, tránh trùng phòng. | Admin, Học vụ |
| 6 | BRANCH-06 | Vô hiệu hóa phòng / chi nhánh | Đánh dấu tạm ngưng sử dụng phòng học hoặc chi nhánh khi sửa chữa. Hệ thống cảnh báo nếu còn lớp học đang hoạt động trong phòng đó. | Admin |

---

### 5.5. QUẢN LÝ KHÓA HỌC & CHƯƠNG TRÌNH HỌC (Course & Syllabus)

Quản lý danh mục đào tạo, lộ trình học và tài liệu giảng dạy đa phương tiện.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | COURSE-01 | Quản lý khóa học | Tạo mới, cập nhật, lưu trữ khóa học: tên khóa (IELTS Master, Tiếng Anh Giao Tiếp,...), ngôn ngữ giảng dạy, mô tả, ảnh đại diện, tổng số buổi học, học phí niêm yết, trạng thái. | Admin, Học vụ |
| 2 | COURSE-02 | Xem danh sách khóa học | Hiển thị danh sách khóa học dạng danh sách/lưới, lọc theo ngôn ngữ đào tạo, cấp độ và trạng thái tuyển sinh. | Tất cả |
| 3 | COURSE-03 | Quản lý cấp độ (Course Levels) | Phân chia khóa học thành nhiều cấp độ liên tiếp (A1, A2, B1, B2,...), thiết lập điều kiện tiên quyết (phải đạt cấp độ trước mới được lên cấp độ sau). | Admin, Học vụ |
| 4 | COURSE-04 | Quản lý Module bài học | Chia nhỏ cấp độ thành các Module/Unit học tập cụ thể (ví dụ: Unit 1: Family & Friends). Mỗi module có tên, mục tiêu và thứ tự giảng dạy. | Admin, Giáo viên |
| 5 | COURSE-05 | Quản lý bài học (Lessons) | Tạo nội dung từng bài học chi tiết: tiêu đề bài, nội dung tóm tắt, thời lượng dự kiến, liên kết với buổi học thực tế trên lớp. | Admin, Giáo viên |
| 6 | COURSE-06 | Quản lý tài liệu học tập đa phương tiện | Đăng tải và quản lý tài liệu học tập gắn theo bài học: giáo trình PDF, file âm thanh bài nghe (MP3), video bài giảng (MP4), hình ảnh. Dữ liệu lưu an toàn trên Firebase Storage. | Admin, Giáo viên |
| 7 | COURSE-07 | Xem & Tải tài liệu bài học | Học viên và giáo viên xem trực tiếp bài giảng, nghe audio luyện nghe và tải tài liệu học tập ngay trên ứng dụng di động. | Giáo viên, Học viên |

---

### 5.6. QUẢN LÝ LỚP HỌC & XẾP LỊCH (Class & Scheduling)

Quản lý việc tổ chức lớp học thực tế, phân bổ giáo viên, phòng học và sinh lịch học tự động.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | CLASS-01 | Tạo lớp học mới | Tạo lớp bằng cách chọn khóa học, chi nhánh, phòng học, giáo viên phụ trách, sĩ số tối đa, lịch học cố định trong tuần (ví dụ: T2-T4-T6, 18:00-19:30) và ngày khai giảng. Hệ thống tự động kiểm tra chống trùng lịch giáo viên và trùng phòng học. | Admin, Học vụ |
| 2 | CLASS-02 | Tự động sinh danh sách buổi học (Sessions) | Dựa trên lịch học cố định, ngày bắt đầu và tổng số buổi học của khóa, hệ thống tự động sinh toàn bộ danh sách các buổi học cụ thể (ngày, giờ, phòng, giáo viên), tự động bỏ qua các ngày nghỉ lễ đã cấu hình. | Hệ thống (tự động) |
| 3 | CLASS-03 | Quản lý danh sách lớp học | Hiển thị danh sách lớp, hỗ trợ lọc theo trạng thái (Chờ khai giảng, Đang học, Đã hoàn thành, Hủy), chi nhánh, khóa học, giáo viên phụ trách. | Admin, Học vụ |
| 4 | CLASS-04 | Cập nhật thông tin lớp học | Sửa thông tin lớp (đổi phòng cố định, đổi giáo viên phụ trách, điều chỉnh lịch học). Khi thay đổi lịch, hệ thống cập nhật đồng bộ các buổi học chưa diễn ra. | Admin, Học vụ |
| 5 | CLASS-05 | Phân bổ học viên vào lớp | Thêm học viên vào lớp (kiểm tra giới hạn sĩ số tối đa; tự động tạo hóa đơn học phí tương ứng). Chuyển lớp hoặc rút học viên khỏi lớp khi có đơn xin chuyển. | Admin, Học vụ |
| 6 | CLASS-06 | Quản lý buổi học chi tiết | Xem danh sách từng buổi học. Cho phép can thiệp riêng từng buổi: đổi phòng học đột xuất, chỉ định giáo viên dạy thay (substitute teacher), hủy buổi do thời tiết/lễ và dời lịch bù. | Admin, Học vụ, GV |
| 7 | CLASS-07 | Xem lịch dạy cá nhân | Giáo viên xem thời khóa biểu giảng dạy của mình theo tuần/tháng trên giao diện Calendar trực quan, xem chi tiết lớp, phòng, số lượng học viên. | Giáo viên |
| 8 | CLASS-08 | Xem lịch học cá nhân | Học viên và phụ huynh xem lịch học các lớp đang tham gia theo ngày/tuần/tháng, hiển thị rõ ràng phòng học, ca học, giáo viên và bài học tương ứng. | Học viên, Phụ huynh |
| 9 | CLASS-09 | Quản lý vòng đời trạng thái lớp | Quản lý trạng thái lớp theo luồng: `waiting` (Chờ khai giảng) $\rightarrow$ `active` (Đang học) $\rightarrow$ `completed` (Kết thúc khóa) $\rightarrow$ `archived` (Lưu trữ). | Admin, Học vụ |
| 10 | CLASS-10 | Xem tổng quan chi tiết lớp học | Xem toàn bộ thông tin lớp: danh sách học viên, tiến độ hoàn thành các buổi học, tỷ lệ chuyên cần trung bình của lớp, danh sách bài tập và đề thi đã giao. | Admin, Học vụ, GV |

---

### 5.7. ĐIỂM DANH & CHUYÊN CẦN (Attendance & Makeup)

Quản lý việc điểm danh từng buổi, theo dõi chuyên cần và giải quyết nhu cầu học bù.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | ATT-01 | Điểm danh buổi học trên ứng dụng | Giáo viên mở ứng dụng di động tại lớp, chọn buổi học, hiển thị danh sách học viên trong lớp. Giáo viên đánh dấu trạng thái từng học viên: Có mặt (`present`), Vắng có phép (`excused`), Vắng không phép (`absent`), Đi trễ (`late`). Hỗ trợ nút "Có mặt tất cả" để thao tác nhanh. | Giáo viên |
| 2 | ATT-02 | Chỉnh sửa điểm danh | Giáo viên hoặc nhân viên học vụ có thể sửa trạng thái điểm danh khi học viên nộp phép muộn. Hệ thống lưu vết người sửa và thời gian chỉnh sửa. | Giáo viên, Học vụ |
| 3 | ATT-03 | Xem lịch sử chuyên cần cá nhân | Học viên xem tỷ lệ đi học của mình trên ứng dụng (hiển thị dạng Calendar Heatmap: xanh là có mặt, đỏ là vắng, vàng là trễ). Phụ huynh theo dõi chính xác từng buổi đi học của con. | Học viên, Phụ huynh |
| 4 | ATT-04 | Thống kê chuyên cần toàn lớp | Báo cáo tỷ lệ chuyên cần theo từng lớp: tổng buổi, số buổi có mặt, vắng, tỷ lệ %. Hệ thống tự động highlight cảnh báo các học viên có tỷ lệ chuyên cần dưới 80%. | Giáo viên, Học vụ |
| 5 | ATT-05 | Đăng ký học bù trực tuyến | Học viên vắng một buổi có thể tạo yêu cầu học bù: chọn buổi học ở lớp khác cùng cấp độ và nội dung bài học. Hệ thống kiểm tra lớp bù còn chỗ trống hay không trước khi gửi yêu cầu. | Học viên |
| 6 | ATT-06 | Duyệt yêu cầu học bù | Nhân viên học vụ kiểm tra lý do, kiểm tra sĩ số lớp bù và duyệt hoặc từ chối yêu cầu. Khi duyệt, học viên được tự động thêm vào danh sách điểm danh của buổi học bù đó. | Học vụ |
| 7 | ATT-07 | Tự động thông báo khi học viên vắng | Khi giáo viên bấm hoàn thành điểm danh và có học viên vắng không phép, hệ thống tự động bắn push notification ngay lập tức về điện thoại của phụ huynh liên kết để kịp thời nắm bắt. | Hệ thống (tự động) |

---

### 5.8. BÀI TẬP & NỘP BÀI (Assignments & Audio Submissions)

Quản lý việc giao và nộp bài tập, hỗ trợ tính năng ghi âm luyện phát âm và kỹ năng nói ngoại ngữ.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | ASG-01 | Tạo bài tập về nhà | Giáo viên tạo bài tập cho lớp: tiêu đề, hướng dẫn yêu cầu, phân loại (Writing, Speaking, Homework, Mini-project), hạn nộp (deadline), thang điểm tối đa, đính kèm file đề bài (PDF, hình ảnh, audio mẫu). | Giáo viên |
| 2 | ASG-02 | Xem danh sách bài tập | Hiển thị danh sách bài tập theo từng lớp, trạng thái (đang mở, sắp hết hạn, đã đóng), tỷ lệ học viên đã nộp. Học viên xem danh sách kèm đồng hồ đếm ngược thời gian còn lại. | Giáo viên, Học viên |
| 3 | ASG-03 | Nộp bài tập đa định dạng | Học viên nộp bài: gõ văn bản trực tiếp, đính kèm file tài liệu (PDF, Word, hình ảnh chụp bài tập) hoặc đính kèm bản ghi âm. Hệ thống đánh dấu nộp đúng hạn hoặc nộp muộn (`late`). | Học viên |
| 4 | ASG-04 | Ghi âm bài nói trực tiếp (Speaking Audio) | **Tính năng đặc thù cho ngoại ngữ:** Học viên sử dụng công cụ ghi âm tích hợp sẵn trên ứng dụng để thu âm bài nói/phát âm của mình. Hỗ trợ ghi âm, dừng, nghe lại, thu lại và nén file audio tải lên Firebase Storage. | Học viên |
| 5 | ASG-05 | Quản lý danh sách bài nộp | Giáo viên xem danh sách bài nộp của cả lớp: tên học viên, thời gian nộp, file đính kèm, trạng thái (chưa chấm / đã chấm). Bấm vào để nghe audio hoặc xem tài liệu. | Giáo viên |
| 6 | ASG-06 | Chấm điểm & Nhận xét phát âm | Giáo viên nhập điểm số, viết nhận xét chi tiết. Đối với bài nói, giáo viên nghe đoạn ghi âm trực tiếp trên app và nhận xét về phát âm, ngữ điệu, từ vựng và ngữ pháp. | Giáo viên |
| 7 | ASG-07 | Xem kết quả & Nhận xét bài tập | Học viên và phụ huynh xem điểm số và nhận xét chi tiết của giáo viên ngay trên ứng dụng; nhận thông báo khi bài tập được chấm xong. | Học viên, Phụ huynh |

---

### 5.9. THI & KIỂM TRA TRỰC TUYẾN (Online Exams & Question Bank)

Tổ chức các kỳ thi kiểm tra định kỳ (Placement test, Midterm, Final test) với ngân hàng câu hỏi đa dạng và chấm điểm tự động.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | EXAM-01 | Quản lý ngân hàng câu hỏi | Giáo viên và Admin tạo, quản lý ngân hàng câu hỏi phân loại theo khóa học, cấp độ (A1, A2, B1,...), chủ đề. | Giáo viên, Admin |
| 2 | EXAM-02 | Quản lý câu hỏi đa dạng hình thức | Tạo, sửa, xóa câu hỏi hỗ trợ 5 dạng chính: **Trắc nghiệm** (Multiple Choice), **Điền khuyết** (Fill in the blank), **Nối cặp** (Matching), **Sắp xếp câu** (Ordering), **Tự luận** (Essay). Phân loại theo 4 kỹ năng (Nghe, Đọc, Viết, Nói, Ngữ pháp, Từ vựng) và độ khó; câu hỏi nghe có đính kèm file audio. | Giáo viên |
| 3 | EXAM-03 | Tạo đề thi | Giáo viên tạo đề thi: chọn câu hỏi từ ngân hàng (thủ công hoặc random theo tỷ lệ kỹ năng/độ khó), cấu hình thời gian làm bài (phút), điểm đạt, trộn thứ tự câu hỏi, cho phép xem đáp án sau khi nộp, khung giờ mở/đóng đề thi. | Giáo viên |
| 4 | EXAM-04 | Xem danh sách bài thi | Hiển thị bài thi theo lớp: bài thi sắp tới, đang diễn ra, đã kết thúc. Học viên xem danh sách bài thi được chỉ định làm. | Giáo viên, Học viên |
| 5 | EXAM-05 | Làm bài thi trực tuyến trên ứng dụng | Học viên tham gia thi trực tuyến: đồng hồ đếm ngược thời gian thực, điều hướng danh sách câu hỏi, đánh dấu câu cần xem lại (`review`), tự động lưu câu trả lời (`auto-save`) mỗi khi chọn đáp án để phòng ngừa sự cố mất kết nối mạng. | Học viên |
| 6 | EXAM-06 | Nộp bài thi an toàn | Học viên chủ động nộp bài hoặc hệ thống tự động thu bài khi hết giờ. Server xác thực thời gian làm bài để chống gian lận. | Học viên, Hệ thống |
| 7 | EXAM-07 | Tự động chấm điểm trắc nghiệm | Hệ thống tự động so khớp đáp án và chấm điểm ngay lập tức đối với các câu hỏi trắc nghiệm, điền từ, nối cặp, sắp xếp sau khi học viên nộp bài. | Hệ thống (tự động) |
| 8 | EXAM-08 | Chấm thi tự luận | Đối với phần thi tự luận (Writing), giáo viên vào giao diện chấm thi để đọc bài làm của học viên, cho điểm từng câu và ghi chú nhận xét. Điểm tổng kết được cập nhật sau khi chấm xong. | Giáo viên |
| 9 | EXAM-09 | Xem kết quả & Bảng điểm kỹ năng | Học viên xem điểm thi tổng, đáp án đúng (nếu được mở), biểu đồ Radar phân tích điểm mạnh/yếu theo từng kỹ năng. Giáo viên xem bảng tổng hợp kết quả cả lớp, tỷ lệ đạt/trượt. | Giáo viên, Học viên |

---

### 5.10. QUẢN LÝ HỌC PHÍ & TÀI CHÍNH (Finance & Invoices)

Quản lý doanh thu, tạo hóa đơn, thu tiền, đối soát công nợ và hỗ trợ thanh toán trực tuyến.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | FIN-01 | Tự động tạo hóa đơn học phí | Khi học viên được xếp vào lớp học, hệ thống tự động tạo hóa đơn học phí tương ứng (`INV-YYYY-MM-XXXX`) bao gồm: thông tin học viên, lớp, học phí gốc, chiết khấu khuyến mãi (nếu có), số tiền phải nộp, hạn thanh toán (`due_date`). | Thu ngân, Hệ thống |
| 2 | FIN-02 | Xem & Lọc danh sách hóa đơn | Thu ngân và Admin xem danh sách toàn bộ hóa đơn; hỗ trợ lọc theo trạng thái (Chờ thanh toán, Thanh toán 1 phần, Đã thanh toán, Quá hạn, Đã hủy), chi nhánh, khoảng thời gian. | Admin, Thu ngân |
| 3 | FIN-03 | Ghi nhận thanh toán tại quầy | Thu ngân ghi nhận khi học viên/phụ huynh đóng tiền mặt hoặc chuyển khoản ngân hàng: nhập số tiền thu, phương thức, mã tham chiếu, ghi chú. Trạng thái hóa đơn tự động cập nhật tương ứng với số tiền đã thu. | Thu ngân |
| 4 | FIN-04 | Thanh toán học phí trực tuyến | Học viên hoặc phụ huynh có thể thanh toán trực tiếp trên ứng dụng qua cổng VNPay / MoMo. Ứng dụng tích hợp WebView thanh toán, hệ thống nhận callback webhook an toàn để xác thực và tự động cập nhật hóa đơn sang "Đã thanh toán". | Học viên, Phụ huynh |
| 5 | FIN-05 | Đóng học phí theo đợt (Trả góp) | Hỗ trợ học viên đóng học phí thành nhiều lần (ví dụ: đợt 1 đóng 50%, đợt 2 đóng 50% trước ngày thi giữa kỳ). Hóa đơn ghi nhận lịch sử từng lần nộp tiền và công nợ còn lại. | Thu ngân, HV |
| 6 | FIN-06 | Quản lý & Cảnh báo công nợ | Danh sách theo dõi các học viên còn nợ học phí kèm số ngày quá hạn. Hệ thống tự động chuyển trạng thái hóa đơn sang "Quá hạn" (`overdue`) khi qua ngày `due_date`. | Admin, Thu ngân |
| 7 | FIN-07 | Xử lý hủy lớp & Hoàn tiền / Bảo lưu | Khi học viên có nhu cầu bảo lưu hoặc rút học phí theo quy chế trung tâm, thu ngân tạo phiếu hoàn phí/bảo lưu, ghi nhận lý do và cập nhật trạng thái hóa đơn. | Thu ngân, Admin |
| 8 | FIN-08 | Quản lý mã khuyến mãi / Học bổng | Tạo và quản lý mã giảm giá: mã code, loại giảm (phần trăm % hoặc số tiền cố định), số lượt dùng tối đa, thời hạn hiệu lực. Áp dụng giảm trừ khi lập hóa đơn cho học viên. | Admin |
| 9 | FIN-09 | Xem lịch sử học phí cá nhân | Học viên và phụ huynh theo dõi toàn bộ các khoản học phí, số tiền đã đóng, công nợ còn lại và lịch sử các lần thanh toán trên ứng dụng. | Học viên, Phụ huynh |
| 10 | FIN-10 | Xuất phiếu thu & Hóa đơn PDF | Thu ngân xuất và in phiếu thu/hóa đơn học phí định dạng PDF chuẩn (chứa thông tin trung tâm, mã hóa đơn, thông tin học viên, số tiền, mã QR tra cứu). | Thu ngân |

---

### 5.11. THÔNG BÁO & NHẮC NHỞ (Notifications & Triggers)

Hệ thống thông báo đa kênh (Push Notification FCM, In-app, Email, SMS) với các kịch bản nhắc nhở tự động.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | NOTI-01 | Thông báo đẩy (FCM Push Notification) | Gửi thông báo đẩy về thiết bị di động của người dùng qua Firebase Cloud Messaging. Thông báo hiển thị trên màn hình khóa/thanh thông báo; chạm vào thông báo sẽ mở ứng dụng và điều hướng trực tiếp đến màn hình chi tiết liên quan. | Hệ thống $\rightarrow$ Tất cả |
| 2 | NOTI-02 | Trung tâm thông báo trong ứng dụng (In-app) | Lưu trữ toàn bộ lịch sử thông báo của người dùng trong cơ sở dữ liệu. Hiển thị danh sách, phân loại theo nhóm, hỗ trợ đánh dấu đã đọc / đọc tất cả; biểu tượng chuông hiển thị badge đếm số tin chưa đọc. | Tất cả |
| 3 | NOTI-03 | Tự động thông báo phụ huynh khi con vắng học | Kịch bản tự động: Ngay khi giáo viên hoàn tất điểm danh và ghi nhận học viên vắng không phép, hệ thống kích hoạt gửi thông báo đẩy đến tài khoản phụ huynh kèm tên lớp, ngày vắng. | Hệ thống $\rightarrow$ Phụ huynh |
| 4 | NOTI-04 | Nhắc nhở hạn nộp bài tập | Tự động gửi thông báo nhắc nhở cho các học viên chưa nộp bài trước khi đến hạn 24 giờ và 2 giờ. | Hệ thống $\rightarrow$ Học viên |
| 5 | NOTI-05 | Nhắc nhở hạn nộp học phí | Tự động gửi thông báo push và email nhắc nhở cho học viên và phụ huynh trước hạn đóng học phí 3 ngày, và cảnh báo khi hóa đơn bị quá hạn. | Hệ thống $\rightarrow$ HV, Phụ huynh |
| 6 | NOTI-06 | Gửi thông báo truyền thông hàng loạt | Admin và nhân viên học vụ có thể soạn và phát sóng (broadcast) thông báo tùy chỉnh đến toàn trung tâm, theo từng chi nhánh, hoặc theo từng lớp học (thông báo lịch nghỉ lễ, hội thảo, sự kiện). | Admin, Học vụ |
| 7 | NOTI-07 | Tùy chỉnh cài đặt nhận thông báo | Người dùng có thể bật/tắt các kênh nhận thông báo theo nhu cầu cá nhân (nhận push, nhận email, nhận SMS). | Tất cả |

---

### 5.12. BÁO CÁO & THỐNG KÊ (Reports & Analytics)

Cung cấp số liệu tổng quan và báo cáo chuyên sâu phục vụ công tác quản trị và ra quyết định.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | RPT-01 | Dashboard tổng quan điều hành | Dành riêng cho Admin: biểu đồ trực quan về các chỉ số trọng yếu: tổng học viên đang học, số lớp đang mở, doanh thu tháng này, tổng công nợ chưa thu, số học viên mới trong tháng. | Admin |
| 2 | RPT-02 | Báo cáo doanh thu & Dòng tiền | Thống kê doanh thu theo ngày, tuần, tháng, quý hoặc năm; so sánh doanh thu giữa các chi nhánh và giữa các khóa học đào tạo. | Admin, Thu ngân |
| 3 | RPT-03 | Báo cáo chuyên cần học tập | Báo cáo tỷ lệ đi học trung bình theo lớp, theo giáo viên và theo chi nhánh. Liệt kê danh sách học viên có nguy cơ rớt môn do nghỉ học quá số buổi quy định. | Admin, Học vụ |
| 4 | RPT-04 | Báo cáo kết quả học tập & Điểm số | Thống kê kết quả thi, phổ điểm các kỹ năng (Nghe, Nói, Đọc, Viết) theo từng lớp, tỷ lệ hoàn thành khóa học và tỷ lệ đạt chứng chỉ đầu ra. | Admin, Học vụ, GV |
| 5 | RPT-05 | Báo cáo chi tiết công nợ học phí | Danh sách tổng hợp các khoản học phí chưa thanh toán, phân loại theo số ngày quá hạn (dưới 15 ngày, 15-30 ngày, trên 30 ngày) để đội ngũ học vụ liên hệ xử lý. | Admin, Thu ngân |
| 6 | RPT-06 | Báo cáo thống kê giờ dạy giáo viên | Báo cáo tổng số giờ dạy thực tế của từng giáo viên trong tháng, số buổi dạy thay, tổng tiền thù lao dự kiến dựa trên đơn giá giờ dạy, phục vụ thanh toán lương. | Admin |
| 7 | RPT-07 | Xuất báo cáo ra file Excel (.xlsx) | Cho phép xuất dữ liệu của các báo cáo (doanh thu, chuyên cần, công nợ, học viên, giờ dạy) ra định dạng file Excel để lưu trữ hoặc xử lý kế toán nội bộ. | Admin, Học vụ, Thu ngân |
| 8 | RPT-08 | Xuất báo cáo tổng kết ra file PDF | Xuất báo cáo tổng quan định dạng PDF chuẩn, kèm tiêu đề trung tâm, biểu đồ và bảng số liệu để in ấn hoặc báo cáo ban giám đốc. | Admin |

---

### 5.13. QUẢN LÝ HỒ SƠ CÁ NHÂN (Personal Profile)

Quản lý thông tin tài khoản cá nhân của từng người dùng trong hệ thống.

| STT | Mã CN | Tên chức năng | Mô tả chi tiết | Đối tượng |
|:---:|:---|:---|:---|:---|
| 1 | PROF-01 | Xem hồ sơ cá nhân | Xem thông tin chi tiết: họ tên, mã tài khoản, email, số điện thoại, ngày sinh, giới tính, ảnh đại diện, chi nhánh trực thuộc, vai trò trong hệ thống. | Tất cả |
| 2 | PROF-02 | Cập nhật thông tin cá nhân | Người dùng tự cập nhật một số thông tin: số điện thoại liên hệ, địa chỉ, ngày sinh. Các trường quan trọng (email định danh, mã số, vai trò) được khóa và chỉ Admin mới có quyền sửa. | Tất cả |
| 3 | PROF-03 | Cập nhật ảnh đại diện (Avatar) | Chụp ảnh mới hoặc chọn ảnh từ thư viện, hỗ trợ cắt ảnh vuông (1:1), tự động nén dung lượng và lưu trên Firebase Storage. | Tất cả |
| 4 | PROF-04 | Đổi mật khẩu tài khoản | Đổi mật khẩu định kỳ với yêu cầu nhập mật khẩu cũ để xác thực, kiểm tra mật khẩu mới khớp chuẩn bảo mật. | Tất cả |
| 5 | PROF-05 | Trang tổng quan học tập cá nhân | Màn hình Home dành riêng cho học viên và phụ huynh: tóm tắt lớp đang học hôm nay, tỷ lệ chuyên cần cá nhân, bài tập cần nộp sắp tới, lịch thi và thông báo mới nhất. | Học viên, Phụ huynh |

---

## 6. BẢNG TỔNG HỢP SỐ LƯỢNG CHỨC NĂNG THEO MÃ

| STT | Nhóm chức năng | Mã nhóm | Số lượng chức năng | Tỷ lệ (%) |
|:---:|:---|:---:|:---:|:---:|
| 1 | Xác thực & Bảo mật | `AUTH` | 8 | 8.2% |
| 2 | Tiếp nhận Đăng ký & Tư vấn tuyển sinh | `LEAD` | 4 | 4.1% |
| 3 | Quản lý Người dùng & Cấp phát tài khoản | `USER` | 9 | 9.3% |
| 4 | Quản lý Chi nhánh & Phòng học | `BRANCH` | 6 | 6.2% |
| 5 | Quản lý Khóa học & Chương trình học | `COURSE` | 7 | 7.2% |
| 6 | Quản lý Lớp học & Xếp lịch | `CLASS` | 10 | 10.3% |
| 7 | Điểm danh & Chuyên cần | `ATT` | 7 | 7.2% |
| 8 | Bài tập & Nộp bài | `ASG` | 7 | 7.2% |
| 9 | Thi & Kiểm tra trực tuyến | `EXAM` | 9 | 9.3% |
| 10 | Quản lý Học phí & Tài chính | `FIN` | 10 | 10.3% |
| 11 | Thông báo & Nhắc nhở | `NOTI` | 7 | 7.2% |
| 12 | Báo cáo & Thống kê | `RPT` | 8 | 8.2% |
| 13 | Quản lý Hồ sơ cá nhân | `PROF` | 5 | 5.2% |
|  | **TỔNG CỘNG** | | **97** | **100%** |
