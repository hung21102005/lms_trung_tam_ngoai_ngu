# Mẫu duyệt: Use Case xử lý tài khoản EduLMS

**Phạm vi:** xác thực và quản lý tài khoản hiện có. **Tình trạng kiểm chứng:** đối chiếu mã nguồn Flutter, NestJS và Prisma; chưa chạy luồng với cơ sở dữ liệu thật. Sơ đồ Figma: [UC-TK – Xử lý tài khoản EduLMS](https://www.figma.com/design/cvtZDthxjC4dZHeWcCCnCH?node-id=19-3).

## 1. Cách xác định Use Case

Một hình ellipse là **một mục tiêu mà actor chủ động thực hiện**. Toàn bộ hình trong system boundary là **sơ đồ Use Case của phân hệ**, không phải 11 “sơ đồ Use Case” rời rạc. `GET /auth/me`, làm mới JWT, băm mật khẩu, tạo `UserRole` và truy vấn Prisma là bước xử lý nội bộ, không vẽ thành Use Case của người dùng. Không dùng `include`/`extend` vì các luồng hiện tại không cần quan hệ này để biểu diễn đúng mục tiêu.

“Người dùng có tài khoản” và “Tài khoản mới được cấp” là cách gọi **tình huống tham gia** cho các vai trò đã có tài khoản, không phải role mới trong RBAC. Ba actor quản trị trên sơ đồ là mã vai trò có thật: `super_admin`, `branch_admin`, `academic_staff`.

| Mã | Mục tiêu | Actor | Giao diện / API chính | Trạng thái bằng chứng |
|---|---|---|---|---|
| TK-01 | Đăng nhập | Người dùng có tài khoản | `login_screen.dart`, `POST /auth/login` | Có UI và xử lý Backend |
| TK-02 | Thiết lập mật khẩu lần đầu | Tài khoản mới được cấp | `first_login_screen.dart`, `POST /auth/first-login-setup` | Có UI và xử lý Backend |
| TK-03 | Đặt lại mật khẩu bằng OTP | Người dùng có email tài khoản | `forgot_password_screen.dart`, `POST /auth/forgot-password`, `POST /auth/reset-password` | Có UI và xử lý Backend; phụ thuộc Redis và email |
| TK-04 | Đổi mật khẩu | Người dùng đã đăng nhập | `change_password_screen.dart`, `POST /auth/change-password` | Có UI và xử lý Backend |
| TK-05 | Cập nhật hồ sơ cá nhân | Người dùng đã đăng nhập | `edit_profile_screen.dart`, `PATCH /users/profile/me` | Có UI và xử lý Backend |
| TK-06 | Tra cứu tài khoản | Super Admin, Branch Admin, Academic Staff | `users_management_view.dart`, `GET /users`, `GET /users/:id` | Có UI và xử lý Backend |
| TK-07 | Cấp tài khoản mới | Super Admin, Branch Admin, Academic Staff (học viên/phụ huynh); hai admin (nhân sự) | `users_management_view.dart`, `POST /users/students`, `/parents`, `/staff` | Có UI và xử lý Backend theo loại tài khoản |
| TK-08 | Cập nhật tài khoản | Super Admin, Branch Admin, Academic Staff | `users_management_view.dart`, `PATCH /users/:id` | Có UI và xử lý Backend |
| TK-09 | Khóa hoặc mở khóa tài khoản | Super Admin, Branch Admin | `users_management_view.dart`, `PATCH /users/:id/status` | Có UI và xử lý Backend |
| TK-10 | Cấp lại mật khẩu tạm | Super Admin, Branch Admin | `users_management_view.dart`, `POST /users/:id/reset-password` | Có UI và xử lý Backend |
| TK-11 | Xóa tài khoản chưa có lịch sử | Super Admin | `users_management_view.dart`, `DELETE /users/:id` | Có UI và xử lý Backend với điều kiện chặn |

**Nguồn chính:** `backend/src/modules/auth/auth.controller.ts`, `auth.service.ts`, `backend/src/modules/users/users.controller.ts`, `users.service.ts`, `backend/src/modules/users/dto/`, `backend/prisma/schema.prisma`, `lib/features/auth/`, `lib/features/profile/`, `lib/features/dashboard/presentation/views/users_management_view.dart`, `lib/core/router/app_router.dart`.

## 2. Đặc tả Use Case

### TK-01 — Đăng nhập

| Trường | Đặc tả |
|---|---|
| Actor | Người dùng có tài khoản. |
| Mục tiêu | Truy cập hệ thống bằng email, số điện thoại hoặc mã người dùng và mật khẩu. |
| Tiền điều kiện | Tài khoản có trong `User`; trang đăng nhập công khai. |
| Luồng chính | 1. Actor nhập `identifier` và mật khẩu. 2. Flutter gửi `POST /auth/login`. 3. Backend tìm `User` theo email/phone/userCode, đối chiếu mật khẩu băm, kiểm tra trạng thái. 4. Backend cập nhật `lastLoginAt`, trả access/refresh token, vai trò, quyền và cờ `requiresPasswordChange`. 5. Flutter chuyển tới màn hình theo trạng thái và vai trò. |
| Luồng thay thế | 1a. Thiếu identifier/mật khẩu hoặc mật khẩu dưới 6 ký tự: DTO từ chối. 3a. Không thấy tài khoản hoặc sai mật khẩu: 401 với thông báo chung. 3b. `LOCKED` hoặc `INACTIVE`: 401 với thông báo trạng thái. 5a. `isFirstLogin` hoặc `PENDING_ACTIVATION`: chuyển sang TK-02. |
| Hậu điều kiện | Đăng nhập thành công có token; `lastLoginAt` được cập nhật. Không tự tạo tài khoản. |
| Quy tắc / bằng chứng | `auth.service.ts:40–131`, `login.dto.ts`, `login_screen.dart`, `auth_bloc.dart`. |

### TK-02 — Thiết lập mật khẩu lần đầu

| Trường | Đặc tả |
|---|---|
| Actor | Người dùng vừa được cấp tài khoản hoặc bị cấp lại mật khẩu tạm. |
| Mục tiêu | Thay mật khẩu tạm để hoàn tất kích hoạt. |
| Tiền điều kiện | Đã đăng nhập và có JWT; `isFirstLogin=true` hoặc trạng thái cần kích hoạt. |
| Luồng chính | 1. Flutter hiển thị form mật khẩu mới/xác nhận. 2. Actor gửi `POST /auth/first-login-setup`. 3. Backend so khớp hai giá trị, kiểm tra tài khoản chưa kích hoạt, băm mật khẩu. 4. Cập nhật `passwordHash`, `isFirstLogin=false`, `status=ACTIVE`; trả token và user mới. |
| Luồng thay thế | 2a. Mật khẩu dưới 8 ký tự hoặc thiếu chữ hoa/chữ thường/chữ số: DTO từ chối. 3a. Xác nhận không khớp: 400. 3b. User không tồn tại: 404. 3c. User đã kích hoạt và không còn là lần đầu: 400. |
| Hậu điều kiện | Tài khoản ở `ACTIVE`, không còn cờ lần đầu. |
| Quy tắc / bằng chứng | `auth.service.ts:133–222`, `first-login-setup.dto.ts`, `first_login_screen.dart`. |

### TK-03 — Đặt lại mật khẩu bằng OTP

| Trường | Đặc tả |
|---|---|
| Actor | Chủ tài khoản có email truy cập được, chưa đăng nhập. |
| Mục tiêu | Lấy lại quyền truy cập khi quên mật khẩu. |
| Tiền điều kiện | Email đã gắn với tài khoản; Redis và dịch vụ gửi email khả dụng. |
| Luồng chính | 1. Actor nhập email, Flutter gọi `POST /auth/forgot-password`. 2. Backend tạo OTP 6 chữ số, lưu Redis 300 giây và gửi email. 3. Actor nhập OTP, mật khẩu mới và xác nhận. 4. Flutter gọi `POST /auth/reset-password`. 5. Backend kiểm tra OTP, tìm user, băm mật khẩu, đặt `isFirstLogin=false`, `status=ACTIVE`, xóa OTP. 6. Flutter quay về đăng nhập. |
| Luồng thay thế | 1a. Email không tồn tại hoặc tài khoản `LOCKED`/`INACTIVE`: API yêu cầu OTP trả thông báo trung tính, không gửi OTP. 4a. Mã sai/hết hạn: 400; không đổi mật khẩu. 4b. Mật khẩu không đạt DTO hoặc xác nhận không khớp: từ chối. 2a. Redis/email lỗi: luồng không hoàn tất, chưa có bằng chứng fallback. |
| Hậu điều kiện | Chỉ khi OTP hợp lệ: mật khẩu mới được lưu và OTP bị xóa. |
| Quy tắc / bằng chứng | `auth.service.ts:482–545`, `reset-password.dto.ts`, `forgot_password_screen.dart`. Lưu ý kiểm tra `LOCKED` chỉ ở bước xin OTP; không diễn giải rằng mọi đường đặt lại đều được bảo vệ giống nhau. |

### TK-04 — Đổi mật khẩu

| Trường | Đặc tả |
|---|---|
| Actor | Người dùng đã đăng nhập. |
| Mục tiêu | Thay mật khẩu hiện tại. |
| Tiền điều kiện | JWT hợp lệ; biết mật khẩu cũ. |
| Luồng chính | 1. Actor vào Hồ sơ → Đổi mật khẩu. 2. Nhập mật khẩu cũ và mới. 3. Flutter gọi `POST /auth/change-password`. 4. Backend đối chiếu mật khẩu cũ, băm mật khẩu mới, lưu `passwordHash` và `isFirstLogin=false`. |
| Luồng thay thế | 2a. Mật khẩu mới dưới 8 ký tự hoặc thiếu chữ hoa/chữ thường/chữ số: DTO từ chối. 4a. Mật khẩu cũ sai: 400. 4b. User không tồn tại: 404. |
| Hậu điều kiện | Mật khẩu mới có hiệu lực; service trả thông báo thành công. |
| Quy tắc / bằng chứng | `auth.service.ts:224–258`, `change-password.dto.ts`, `change_password_screen.dart`. |

### TK-05 — Cập nhật hồ sơ cá nhân

| Trường | Đặc tả |
|---|---|
| Actor | Người dùng đã đăng nhập. |
| Mục tiêu | Sửa thông tin của chính mình. |
| Tiền điều kiện | JWT hợp lệ; `CurrentUser('id')` xác định đúng tài khoản. |
| Luồng chính | 1. Actor mở form Hồ sơ và sửa trường được hỗ trợ. 2. Flutter gửi `PATCH /users/profile/me`. 3. Controller chỉ chuyển các trường hồ sơ cá nhân (`fullName`, `email`, `phone`, `avatarUrl`, `gender`, `dateOfBirth`, `address`). 4. Service kiểm tra email/phone trùng, cập nhật `User` trong transaction và trả hồ sơ mới. |
| Luồng thay thế | 3a. Email hoặc SĐT đã dùng: 409. 4a. User không tồn tại: 404. Lỗi API được Flutter hiển thị, không coi form đã lưu. |
| Hậu điều kiện | Chỉ dữ liệu của actor được cập nhật; route này không cho tự gán role hoặc đổi trạng thái. |
| Quy tắc / bằng chứng | `users.controller.ts:269–289`, `users.service.ts:671–795`, `edit_profile_screen.dart`, `profile_remote_datasource.dart`. |

### TK-06 — Tra cứu tài khoản

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin, Branch Admin, Academic Staff. |
| Mục tiêu | Tìm danh sách và xem thông tin tài khoản được phép quản lý. |
| Tiền điều kiện | JWT và role hợp lệ. Actor không phải Super Admin phải có `branchId`. |
| Luồng chính | 1. Actor mở quản lý người dùng. 2. Flutter gọi `GET /users` với trang, từ khóa, vai trò, trạng thái/chi nhánh. 3. Controller ép phạm vi chi nhánh của actor. 4. Service lọc theo tên/mã/email/SĐT, role, trạng thái, phân trang và trả dữ liệu. 5. Khi mở chi tiết, `GET /users/:id` kiểm tra quyền với tài khoản đích. |
| Luồng thay thế | 3a. Yêu cầu chi nhánh ngoài quyền: 403. 5a. Tài khoản đích không tồn tại: 404. 5b. Nhân sự chi nhánh xem tài khoản của Super/Branch Admin: 403. |
| Hậu điều kiện | Không thay đổi dữ liệu. |
| Quy tắc / bằng chứng | `users.controller.ts:65–81,247–264`, `users.service.ts:30–57,86–174`, `users_management_view.dart:297`. |

### TK-07 — Cấp tài khoản mới

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin, Branch Admin, Academic Staff khi cấp học viên/phụ huynh; chỉ hai admin khi cấp nhân sự. |
| Mục tiêu | Tạo tài khoản theo loại đối tượng nghiệp vụ được chọn. |
| Tiền điều kiện | Actor đã đăng nhập, có role phù hợp; chi nhánh đích đúng phạm vi. Role đích đã cấu hình. |
| Luồng chính | 1. Actor mở “Thêm Người Dùng Mới”, chọn loại và nhập dữ liệu. 2. Flutter gọi endpoint riêng: `/users/students`, `/users/parents` hoặc `/users/staff`. 3. Controller kiểm tra role và chi nhánh. 4. Service kiểm tra trùng email/SĐT, role đích; sinh mã và mật khẩu tạm, băm mật khẩu. 5. Transaction tạo `User`, `UserRole` và `StudentProfile`/`TeacherProfile`/liên kết `ParentStudent` khi phù hợp. 6. Trả tài khoản và mật khẩu tạm; có email thì gọi dịch vụ gửi thư chào mừng. |
| Luồng thay thế | 1a. Thiếu trường bắt buộc/định dạng email sai: form hoặc DTO từ chối. 2a. Academic Staff chọn nhân sự: API 403, dù lựa chọn này vẫn xuất hiện trong form hiện tại. 3a. Branch Admin cấp `branch_admin`: 403; `super_admin` cũng chỉ cấp bởi Super Admin. 4a. Email/SĐT trùng: 409. 4b. Role hoặc chi nhánh không tồn tại: 400/404. 5a. Với phụ huynh, `studentIds` không hợp lệ hoặc ngoài chi nhánh: từ chối. |
| Hậu điều kiện | User mới `ACTIVE`, `isFirstLogin=true`; hồ sơ chuyên biệt và quan hệ được tạo theo loại. Email chào mừng được gọi sau transaction, không phải điều kiện xác nhận transaction. |
| Quy tắc / bằng chứng | `users.controller.ts:118–201`, `users.service.ts:335–665`, DTO tạo tài khoản; `users_management_view.dart:339–573`. Phần form Flutter hiện không nhập đủ mọi trường DTO, nên chỉ mô tả dữ liệu giao diện thực gửi. |

### TK-08 — Cập nhật tài khoản

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin, Branch Admin, Academic Staff. |
| Mục tiêu | Sửa thông tin của tài khoản nằm trong phạm vi quản lý. |
| Tiền điều kiện | JWT/role hợp lệ; tài khoản đích tồn tại và qua kiểm tra chi nhánh. |
| Luồng chính | 1. Actor chọn “Chỉnh sửa thông tin” từ danh sách. 2. Flutter hiển thị dữ liệu hiện tại và gửi `PATCH /users/:id`. 3. Controller kiểm tra chi nhánh của tài khoản đích và chi nhánh mới nếu có. 4. Service kiểm tra email/SĐT trùng, cập nhật `User`, `StudentProfile` hoặc `TeacherProfile` trong transaction khi có dữ liệu tương ứng. 5. UI tải lại danh sách. |
| Luồng thay thế | 2a. Họ tên trống: form từ chối. 3a. Ngoài phạm vi chi nhánh/tài khoản admin được bảo vệ: 403. 4a. Email/SĐT trùng: 409. 4b. Không tìm thấy: 404. |
| Hậu điều kiện | Các trường hợp lệ của tài khoản đích được cập nhật; role/status không thay đổi bởi endpoint này. |
| Quy tắc / bằng chứng | `users.controller.ts:296–313`, `users.service.ts:671–795`, `users_management_view.dart:708–849`. |

### TK-09 — Khóa hoặc mở khóa tài khoản

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin, Branch Admin. |
| Mục tiêu | Ngăn hoặc cho phép tài khoản tiếp tục đăng nhập. |
| Tiền điều kiện | JWT/role hợp lệ; tài khoản đích thuộc phạm vi được quản lý. |
| Luồng chính | 1. Actor chọn Khóa/Mở khóa và xác nhận. 2. Flutter gửi `PATCH /users/:id/status` với `LOCKED` hoặc `ACTIVE`. 3. Backend kiểm tra role, chi nhánh và bảo vệ Super Admin cuối cùng. 4. Service cập nhật `User.status`; UI tải lại danh sách. |
| Luồng thay thế | 1a. Hủy xác nhận: không gửi API. 3a. Branch Admin đụng tài khoản admin được bảo vệ/ngoài chi nhánh: 403. 3b. Khóa hoặc vô hiệu hóa Super Admin duy nhất đang hoạt động: 400. 3c. Không thấy user: 404. |
| Hậu điều kiện | `User.status` đổi theo yêu cầu hợp lệ. API đăng nhập từ chối `LOCKED` và `INACTIVE`. |
| Quy tắc / bằng chứng | `users.controller.ts:316–336`, `users.service.ts:798–844`, `users_management_view.dart:1077–1130`, `auth.service.ts:76–87`. |

### TK-10 — Cấp lại mật khẩu tạm

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin, Branch Admin. |
| Mục tiêu | Cấp mật khẩu tạm cho người dùng khác. |
| Tiền điều kiện | JWT/role hợp lệ; tài khoản đích trong phạm vi quản lý. |
| Luồng chính | 1. Actor chọn Cấp lại mật khẩu và xác nhận. 2. Flutter gọi `POST /users/:id/reset-password`. 3. Backend sinh hoặc nhận mật khẩu tạm, băm và lưu `passwordHash`, đặt `isFirstLogin=true`. 4. Nếu có email, service gọi gửi thư; API trả mật khẩu tạm và UI hiển thị cho actor. 5. Lần đăng nhập kế tiếp đi vào TK-02. |
| Luồng thay thế | 1a. Hủy: không thay đổi. 2a. Ngoài chi nhánh hoặc tài khoản admin được bảo vệ: 403. 3a. User không tồn tại: 404. 4a. Email không có hoặc gửi thất bại: không khẳng định người dùng đã nhận thư; mật khẩu tạm vẫn được API trả. |
| Hậu điều kiện | Mật khẩu cũ không còn hợp lệ; `isFirstLogin=true`. |
| Quy tắc / bằng chứng | `users.controller.ts:362–379`, `users.service.ts:941–977`, `users_management_view.dart:1019–1073`. |

### TK-11 — Xóa tài khoản chưa có lịch sử

| Trường | Đặc tả |
|---|---|
| Actor | Super Admin. |
| Mục tiêu | Xóa vĩnh viễn một tài khoản không có lịch sử nghiệp vụ được service kiểm tra. |
| Tiền điều kiện | JWT role `super_admin`; tài khoản đích khác tài khoản đang đăng nhập. |
| Luồng chính | 1. Actor chọn Xóa, xác nhận theo form. 2. Flutter gọi `DELETE /users/:id`. 3. Backend kiểm tra self-delete, Super Admin cuối cùng và các bản ghi lớp, hóa đơn, điểm danh, bài nộp, bài kiểm tra, lịch giảng. 4. Nếu không có lịch sử bị chặn, transaction xóa hồ sơ, liên kết, thông báo, đăng ký, role rồi `User`. 5. UI tải lại danh sách. |
| Luồng thay thế | 1a. Hủy hoặc nhập xác nhận sai: không gọi API. 3a. Tự xóa: 400. 3b. Super Admin cuối cùng: 400. 3c. Có lịch sử vận hành: 400, UI gợi ý khóa/vô hiệu hóa. 3d. Không thấy user: 404. |
| Hậu điều kiện | Chỉ tài khoản đáp ứng điều kiện mới bị xóa vĩnh viễn. |
| Quy tắc / bằng chứng | `users.controller.ts:339–359`, `users.service.ts:847–936`, `users_management_view.dart:2442–2520`. |

## 3. Sai lệch và giới hạn phải giữ trong bản mẫu

1. **UI quản lý người dùng đang hiển thị thao tác Cấp lại mật khẩu và Khóa/Mở khóa trong bottom sheet chung**, kể cả khi actor là Academic Staff; Backend chỉ cho `super_admin` và `branch_admin`. Vì thế đường liên kết của Academic Staff trên sơ đồ **không nối TK-09/TK-10**. Đây là sai lệch UI cần sửa ở dự án, không thể viết đặc tả rằng nhân viên học vụ làm được.
2. **Form tạo mới hiển thị lựa chọn nhân sự cho Academic Staff**, nhưng `POST /users/staff` từ chối role này. TK-07 phải ghi rõ giới hạn theo loại tài khoản.
3. `POST /users/:id/roles` cho Super Admin có xử lý Backend, nhưng chưa thấy thao tác gán vai trò tương ứng trong `users_management_view.dart`; **không đưa vào sơ đồ chính thức của mẫu**. Có thể bổ sung khi xác nhận được luồng UI hoặc khi phạm vi bài cho phép Use Case chỉ có API.
4. `POST /auth/refresh` và `GET /auth/me` là bước kỹ thuật hỗ trợ phiên/hồ sơ, không phải mục tiêu độc lập của actor trong sơ đồ này.
5. Đây là **xác minh bằng đọc source**. Chưa chạy Backend cùng PostgreSQL/Redis/email và chưa kiểm thử end-to-end các luồng. Các câu “có xử lý Backend” không đồng nghĩa đã xác nhận hoạt động trong môi trường triển khai.
