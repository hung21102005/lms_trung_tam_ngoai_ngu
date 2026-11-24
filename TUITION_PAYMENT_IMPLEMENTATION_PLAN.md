# MASTER PLAN – XÂY DỰNG & HOÀN THIỆN HỆ THỐNG HỌC PHÍ, HÓA ĐƠN, ĐÓNG TIỀN & CÔNG NỢ – EDULMS

Bạn là Principal Full-stack Engineer, NestJS/Prisma Backend Architect và Flutter Bloc Specialist, đang trực tiếp phát triển hệ thống EduLMS.

**MỤC TIÊU TỔNG THỂ:** Hoàn thiện xuyên suốt (Database → Backend API → Flutter Bloc → UI Admin/Thu ngân/Học viên/Phụ huynh → Báo cáo tài chính) cho toàn bộ hệ sinh thái **Học phí – Hóa đơn – Đóng tiền – Học phí đăng ký lớp – Đối soát & Công nợ**, đảm bảo không dùng mock data, đồng bộ state tức thì không cần nhấn F5 và vượt qua đầy đủ kiểm thử tự động.

---

## 1. BÁO CÁO RÀ SOÁT HIỆN TRẠNG (AUDIT SUMMARY)

### 1.1. Những thành phần đã có sẵn trong Source Code
1. **Database (`backend/prisma/schema.prisma`)**:
   - Đã có trường định mức học phí tại `CourseLevel.tuitionFee` (Decimal 12,2), `Class.tuitionFee` (Decimal 12,2) và `ClassStudent.tuitionPaid` (Decimal 12,2).
   - Đã có bảng `Promotion` (mã khuyến mãi theo `PERCENTAGE` hoặc `FIXED_AMOUNT`, giới hạn lượt dùng, thời hạn, đơn tối thiểu, giảm tối đa).
   - Đã có bảng `Invoice` (`HD-YYYY-XXXX`, gắn `studentId`, `classId`, `subtotal`, `discount`, `totalAmount`, `paidAmount`, `balance`, `status`, `dueDate`, `promotionId`).
   - Đã có bảng `Payment` (`PT-YYYY-XXXX`, gắn `invoiceId`, `studentId`, `amount`, `method`: `CASH`, `BANK_TRANSFER`, `VNPAY`, `MOMO`, `status`: `PENDING`, `SUCCESS`, `FAILED`, `REFUNDED`, `transactionId`, `receivedById`).
2. **Backend NestJS (`backend/src/modules/finance/`)**:
   - Đã có `FinanceController` và `FinanceService` hỗ trợ: tạo hóa đơn (`POST /finance/invoices`), danh sách hóa đơn (`GET /finance/invoices`), hóa đơn cá nhân/con em (`GET /finance/my-invoices`), chi tiết hóa đơn (`GET /finance/invoices/:id`), ghi nhận thanh toán (`POST /finance/invoices/:id/payments`), hủy hóa đơn (`POST /finance/invoices/:id/cancel`), hoàn tiền (`POST /finance/invoices/:id/refund`), tạo URL VNPay (`POST /finance/invoices/:id/pay-online`), callback VNPay (`GET /finance/payments/vnpay-return`), quét quá hạn (`POST /finance/invoices/check-overdue`), và quản lý khuyến mãi (`POST/GET /finance/promotions`, `POST /finance/promotions/validate`).
   - Đã có logic tự sinh hóa đơn cơ bản khi duyệt đơn đăng ký lớp (`class-registrations.service.ts`) và khi thêm học viên vào lớp (`classes.service.ts`).
3. **Frontend Flutter (`lib/features/finance/`)**:
   - Đã có `FinanceBloc`, `FinanceRepository`, `InvoiceModel`, `PaymentModel` và các màn hình rời: `InvoiceListScreen`, `InvoiceDetailScreen`, `RecordPaymentScreen`, `PayOnlineScreen`, `MyInvoicesScreen`.

### 1.2. Các điểm đứt gãy & thiếu sót cần khắc phục triệt để (Gaps to Fix)
1. **GAP 1 – Admin Portal thiếu Trung tâm Quản lý Học phí & Thu ngân trên Sidebar**:
   - `AdminHomeScreen` hiện chưa có tab chuyên biệt cho **Học phí & Thu ngân** trên thanh điều hướng chính (hiện chỉ có tab *Báo cáo & Tài chính* mở `ReportsOverviewScreen`), khiến Admin/Cashier không có nơi thao tác hóa đơn, thu tiền, duyệt chuyển khoản và quản lý mã khuyến mãi trực tiếp trong workspace.
2. **GAP 2 – Luồng Duyệt đơn đăng ký lớp & Ghi danh học viên vào lớp chưa cho phép cấu hình học phí/ưu đãi/thu tiền ngay**:
   - Khi duyệt đơn đăng ký (`POST /admissions/registrations/:id/approve`) hoặc ghi danh học viên vào lớp (`POST /classes/:id/students`), hệ thống đang tự tạo hóa đơn 100% nguyên giá (`discount = 0`), chưa hỗ trợ áp mã khuyến mãi (`promotionCode`), giảm giá học bổng (`discount`), chọn hạn đóng (`dueDate`), hoặc ghi nhận khoản thu đợt 1/tiền cọc (`initialPaymentAmount`, `paymentMethod`) ngay trong cùng giao dịch.
3. **GAP 3 – Chi tiết Lớp học (`ClassDetailScreen`) thiếu thông tin công nợ học phí của từng học viên**:
   - Danh sách học viên trong lớp chưa hiển thị rõ trạng thái đóng học phí (`Đã đóng đủ`, `Đóng 1 phần`, `Chưa đóng`, `Quá hạn`), số tiền đã đóng / còn nợ, và chưa có nút thao tác nhanh **Thu học phí** / **Xem hóa đơn** ngay tại dòng học viên.
4. **GAP 4 – Luồng Học viên/Phụ huynh chuyển khoản VietQR chưa có cơ chế gửi yêu cầu xác nhận & chờ Thu ngân đối soát**:
   - Trên `PayOnlineScreen`, học viên quét mã VietQR xong bấm *"Tôi đã chuyển khoản"* nhưng hệ thống chỉ tải lại hóa đơn chứ chưa tạo bản ghi thanh toán chờ duyệt (`PaymentStatus.PENDING` kèm `transactionId` / nội dung chuyển khoản) để Thu ngân kiểm tra và bấm **Xác nhận đã nhận tiền** hoặc **Từ chối**.
5. **GAP 5 – Góc Phụ huynh (`ParentHomeScreen`) nút "Thanh Toán Học Phí" bị bỏ trống (`onTap: null`)**:
   - Phụ huynh bấm vào ô *Thanh Toán Học Phí* trên cả Web và Mobile chưa mở được danh sách hóa đơn của con em, chưa hiển thị rõ hóa đơn thuộc người con nào để thanh toán.
6. **GAP 6 – Thiếu giao diện Tạo Hóa đơn mới & Quản lý Mã khuyến mãi (`Promotions`) cho Admin/Thu ngân**:
   - Backend đã có API tạo hóa đơn và tạo/kiểm tra mã khuyến mãi nhưng Flutter chưa có Dialog/Screen tạo hóa đơn học phí/phụ phí (có tra cứu học viên, chọn lớp, áp mã khuyến mãi) và chưa có tab quản lý chương trình khuyến mãi.
7. **GAP 7 – Đồng bộ State đa tầng (Real-time UI Sync không cần F5)**:
   - Mọi thao tác: Duyệt đơn tạo hóa đơn, Tạo hóa đơn lẻ, Thu tiền tại quầy, Học viên gửi xác nhận chuyển khoản, Thu ngân duyệt chuyển khoản, Hủy hóa đơn, Hoàn tiền phải cập nhật tức thì trên `FinanceBloc`, `ClassesBloc` (danh sách học viên lớp & `tuitionPaid`) và `ReportsBloc` (KPI doanh thu/công nợ) mà không cần tải lại trang.

---

## 2. YÊU CẦU TRIỂN KHAI CHI TIẾT THEO 4 PHÂN HỆ

### PHÂN HỆ 1 – HỌC PHÍ KHI ĐĂNG KÝ LỚP & GHI DANH HỌC VIÊN (ADMISSIONS & CLASS ENROLLMENT TUITION)

#### 1.1. Backend (`admissions` & `classes` & `finance`)
1. **Nâng cấp `ApproveClassRegistrationDto` & `ClassRegistrationsService.approve`**:
   - Cho phép truyền tùy chọn khi duyệt đơn đăng ký lớp:
     - `promotionCode?: string`
     - `discountAmount?: number`
     - `dueDate?: string`
     - `initialPaymentAmount?: number` (số tiền học viên đóng ngay khi làm thủ tục nhập học, nếu có)
     - `paymentMethod?: PaymentMethod` (`CASH`, `BANK_TRANSFER`, ...)
     - `transactionId?: string`
     - `invoiceNotes?: string`
   - Trong cùng 1 transaction `Serializable`:
     - Tính toán `subtotal = Number(class.tuitionFee)`.
     - Nếu có `promotionCode`, kiểm tra tính hợp lệ của mã khuyến mãi, tính `discount`, tăng `usedCount`. Nếu có `discountAmount` hợp lệ thì áp dụng giảm trừ.
     - Tạo `Invoice` với `totalAmount = Math.max(0, subtotal - discount)`.
     - Nếu `initialPaymentAmount > 0`: tự động tạo luôn phiếu thu `Payment` (`PT-YYYY-XXXX`, `status: SUCCESS`), cập nhật `invoice.paidAmount`, `invoice.balance`, `invoice.status` (`PAID` hoặc `PARTIALLY_PAID`) và cập nhật `ClassStudent.tuitionPaid = initialPaymentAmount`.
     - Trả về đầy đủ thông tin `{ registration, enrollment, invoice, payment }` để Frontend đồng bộ ngay.
2. **Nâng cấp `EnrollStudentDto` & `ClassesService.enrollStudent`**:
   - Hỗ trợ tương tự các tham số `promotionCode`, `discountAmount`, `dueDate`, `tuitionPaid` / `paymentMethod` để khi thêm học viên trực tiếp vào lớp, nếu `tuitionPaid > 0` thì hệ thống không chỉ tạo `Invoice` mà còn tạo luôn bản ghi `Payment` tương ứng để sổ quỹ và lịch sử phiếu thu khớp 100% với `invoice.paidAmount`.
3. **Bổ sung thông tin hóa đơn học phí trong `ClassesService.findOne` (Chi tiết lớp học)**:
   - Khi lấy danh sách `students` của lớp, trả kèm thông tin hóa đơn học phí của học viên tại lớp đó (`invoiceId`, `invoiceCode`, `totalAmount`, `paidAmount`, `balance`, `invoiceStatus`, `dueDate`) để UI hiển thị chính xác trạng thái công nợ từng học viên.

#### 1.2. Frontend (`AdmissionsCrmView` & `ClassDetailScreen`)
1. **Hộp thoại Duyệt & Ghi danh học viên (`AdmissionsCrmView`)**:
   - Khi Admin bấm **"Duyệt & Ghi danh"** trên một đơn đăng ký lớp:
     - Hiển thị thông tin lớp học và **Học phí chuẩn của lớp**.
     - Cho phép nhập **Mã khuyến mãi** (có nút *"Áp dụng"* gọi API `/finance/promotions/validate` để hiển thị ngay số tiền được giảm) hoặc nhập **Số tiền giảm trừ trực tiếp**.
     - Cho phép chọn **Hạn thanh toán** (mặc định là ngày khai giảng lớp).
     - Cho phép tích chọn **"Thu học phí ngay tại quầy"** (nhập số tiền đóng đợt 1 hoặc đóng toàn bộ, chọn Tiền mặt / Chuyển khoản).
     - Hiển thị rõ tổng tiền phải thu, số tiền đóng ngay và số dư còn nợ trước khi bấm **"Xác nhận Ghi danh & Xuất hóa đơn"**.
2. **Tab Học viên trong Chi tiết Lớp học (`ClassDetailScreen`)**:
   - Trên mỗi dòng học viên của lớp, hiển thị rõ:
     - Badge trạng thái học phí: `Đã đóng đủ` (Xanh lá), `Đóng 1 phần` (Cam), `Chưa đóng` (Đỏ/Xám), `Quá hạn` (Đỏ đậm), hoặc `Miễn phí` (nếu học phí = 0).
     - Số tiền: `Đã đóng / Tổng học phí` (và `Còn nợ: ...`).
     - Nút thao tác nhanh: **"Thu phí"** (mở ngay dialog/màn hình thu tiền cho hóa đơn đó) và **"Xem HĐ"** (mở chi tiết hóa đơn).
   - Khi thêm học viên vào lớp từ `ClassDetailScreen`, cho phép nhập số tiền thu ngay, mã khuyến mãi và phương thức thanh toán.

---

### PHÂN HỆ 2 – TRUNG TÂM HỌC PHÍ & THU NGÂN TRÊN ADMIN PORTAL (ADMIN & CASHIER FINANCE HUB)

#### 2.1. Backend (`finance`)
1. **Luồng Học viên/Phụ huynh gửi xác nhận chuyển khoản VietQR & Thu ngân đối soát**:
   - Thêm endpoint `POST /api/v1/finance/invoices/:id/submit-transfer`:
     - Dành cho `student`, `parent` (chỉ được gửi cho hóa đơn của chính mình hoặc con mình) hoặc nhân viên.
     - Nhận `{ amount: number, transactionId?: string, notes?: string }`.
     - Kiểm tra `amount > 0` và `amount <= invoice.balance`.
     - Kiểm tra tránh gửi trùng nếu hóa đơn đã có 1 giao dịch `PENDING` chờ duyệt.
     - Tạo bản ghi `Payment` với `method: PaymentMethod.BANK_TRANSFER`, `status: PaymentStatus.PENDING`, `amount`, `transactionId`, `notes`.
     - Gửi thông báo cho Admin/Cashier hoặc lưu trạng thái để hiển thị trên danh sách chờ đối soát.
   - Thêm endpoint `POST /api/v1/finance/payments/:paymentId/approve`:
     - Dành cho `super_admin`, `branch_admin`, `cashier`.
     - Trong 1 transaction: chuyển `Payment` từ `PENDING` sang `SUCCESS`, gán `receivedById = req.user.id`, cộng `payment.amount` vào `invoice.paidAmount`, trừ `invoice.balance`, cập nhật `invoice.status` (`PAID` / `PARTIALLY_PAID`), cộng `ClassStudent.tuitionPaid`, và gửi thông báo xác nhận cho học viên.
   - Thêm endpoint `POST /api/v1/finance/payments/:paymentId/reject`:
     - Dành cho `super_admin`, `branch_admin`, `cashier`.
     - Chuyển `Payment` từ `PENDING` sang `FAILED`, ghi chú lý do từ chối và gửi thông báo cho học viên/phụ huynh biết để kiểm tra lại giao dịch.
2. **Nâng cấp `GET /api/v1/finance/invoices`**:
   - Bổ sung bộ lọc `branchId` và cờ `hasPendingTransfer` (các hóa đơn đang có giao dịch chuyển khoản `PaymentStatus.PENDING` chờ thu ngân duyệt).
   - Trong `summary`, trả thêm:
     - `pendingTransferCount`: số giao dịch chuyển khoản đang chờ đối soát.
     - `overdueCount`: số hóa đơn đang quá hạn.
3. **Quản lý Mã khuyến mãi (`Promotions`)**:
   - Bổ sung endpoint `PATCH /api/v1/finance/promotions/:id/toggle` (hoặc cập nhật `isActive`) để Admin bật/tắt mã khuyến mãi.

#### 2.2. Frontend (`AdminHomeScreen` & `InvoiceListScreen` & `InvoiceDetailScreen`)
1. **Đưa mục "Học phí & Hóa đơn" lên Sidebar của `AdminHomeScreen`**:
   - Bổ sung mục điều hướng **"Học phí & Hóa đơn"** (icon `Icons.receipt_long_rounded`) trên Sidebar của Admin/Cashier/Academic Staff để mở trực tiếp workspace quản lý học phí mà không phải đi vòng.
2. **Nâng cấp toàn diện `InvoiceListScreen` (hỗ trợ cả Desktop Table/Grid & Mobile Card)**:
   - Hiển thị 4 thẻ KPI tổng quan:
     1. **Tổng phải thu** (`totalRevenue`)
     2. **Thực thu** (`paidRevenue`)
     3. **Công nợ còn lại** (`outstandingRevenue`)
     4. **Chờ đối soát CK / Quá hạn** (`pendingTransferCount` / `overdueCount`)
   - Thanh công cụ (Toolbar) cho Admin/Cashier:
     - Nút **"+ Tạo hóa đơn học phí"**: Mở dialog tạo hóa đơn mới (chọn Học viên, chọn Lớp học đang theo học hoặc tạo hóa đơn thu phụ phí/giáo trình, tự động điền học phí lớp, cho phép áp dụng Mã khuyến mãi, nhập hạn thanh toán).
     - Nút **"Mã khuyến mãi"**: Mở dialog/panel quản lý danh sách mã khuyến mãi (Xem danh sách mã, Tạo mã khuyến mãi mới theo `%` hoặc `VNĐ`, Bật/Tắt mã).
     - Nút **"Quét & Nhắc nợ quá hạn"**: Gọi `POST /finance/invoices/check-overdue`, cập nhật ngay trạng thái các hóa đơn quá hạn sang `OVERDUE` và hiển thị số lượng học viên đã được gửi thông báo nhắc nợ.
   - Các tab lọc trạng thái:
     - `Tất cả`, `Chờ nộp (PENDING)`, `Đóng 1 phần (PARTIALLY_PAID)`, `Chờ duyệt CK (PENDING_TRANSFER)`, `Đã hoàn tất (PAID)`, `Quá hạn (OVERDUE)`, `Đã hủy / Hoàn tiền`.
3. **Nâng cấp `InvoiceDetailScreen` & Đối soát chuyển khoản**:
   - Nếu hóa đơn có khoản thanh toán `PaymentStatus.PENDING` (học viên vừa báo đã chuyển khoản VietQR):
     - Hiển thị thẻ cảnh báo nổi bật **"Khoản chuyển khoản chờ thu ngân xác nhận"** kèm số tiền, mã giao dịch, thời gian.
     - Cung cấp 2 nút cho Admin/Cashier: **"Xác nhận đã nhận tiền"** (`approve`) và **"Từ chối"** (`reject` kèm lý do).
   - Hỗ trợ đầy đủ thao tác:
     - **Ghi nhận thu tiền mặt / chuyển khoản** (`RecordPaymentScreen` hoặc Quick Modal).
     - **Hoàn tiền học phí (`Refund`)** khi hóa đơn đã có `paidAmount > 0` (nhập số tiền hoàn & lý do hoàn tiền).
     - **Hủy hóa đơn (`Cancel`)** khi `paidAmount == 0` (nhập lý do hủy).
     - **Xem / Xuất biên lai phiếu thu** rõ ràng cho từng lần đóng tiền (`PT-YYYY-XXXX`).

---

### PHÂN HỆ 3 – CỔNG HỌC PHÍ & ĐÓNG TIỀN CHO HỌC VIÊN & PHỤ HUYNH (STUDENT & PARENT TUITION PORTAL)

#### 3.1. Cổng Học viên (`StudentHomeScreen` → `MyInvoicesScreen` → `PayOnlineScreen`)
1. **Trang Học phí của tôi (`MyInvoicesScreen`)**:
   - Hiển thị tổng công nợ cần thanh toán, tổng số tiền đã đóng, số hóa đơn đang chờ và cảnh báo nếu có hóa đơn sắp đến hạn / quá hạn.
   - Trên mỗi hóa đơn, hiển thị rõ tiến độ thanh toán (Progress bar: `Đã đóng / Tổng tiền`), hạn nộp, danh sách các đợt đã đóng và trạng thái nếu đang có giao dịch `"Đang chờ thu ngân xác nhận chuyển khoản"`.
2. **Luồng Thanh toán trực tuyến (`PayOnlineScreen`)**:
   - **Tab 1 – Chuyển khoản VietQR**:
     - Hiển thị mã QR động theo số tiền cần đóng (cho phép học viên/phụ huynh chọn **Đóng toàn bộ dư nợ** hoặc **Đóng một phần / Đóng theo đợt**).
     - Bổ sung form **"Xác nhận đã chuyển khoản"**: cho phép nhập số tiền vừa chuyển, mã giao dịch ngân hàng (tùy chọn) và ghi chú, sau đó bấm **"Gửi xác nhận đã chuyển khoản"**.
     - Khi gửi thành công (`POST /finance/invoices/:id/submit-transfer`), cập nhật ngay trạng thái trên hóa đơn thành `"Đang chờ thu ngân đối soát"` mà không cần F5.
   - **Tab 2 – Cổng thanh toán VNPay**:
     - Tạo URL thanh toán VNPay và hướng dẫn thanh toán / kiểm tra kết quả.

#### 3.2. Cổng Phụ huynh (`ParentHomeScreen`)
1. **Kích hoạt tính năng "Thanh Toán Học Phí" trên cả Desktop/Web và Mobile (`ParentHomeScreen`)**:
   - Gắn `onTap: () => context.push(RouteNames.myInvoices)` cho thẻ **"Thanh Toán Học Phí"** trên cả giao diện Web và Mobile của Phụ huynh.
2. **Hiển thị rõ tên & mã học viên (con em) trên từng thẻ hóa đơn trong `MyInvoicesScreen`**:
   - Khi người đăng nhập là Phụ huynh (hoặc hóa đơn có thông tin `student`), hiển thị rõ badge **"Học viên: [Họ tên con] ([Mã HV])"** trên từng thẻ hóa đơn để phụ huynh có nhiều con theo học phân biệt chính xác hóa đơn của từng bé và thanh toán ngay.

---

### PHÂN HỆ 4 – ĐỒNG BỘ STATE TỨC THÌ & KIỂM THỬ TỰ ĐỘNG (STATE SYNC & AUTOMATED TESTING)

#### 4.1. Đồng bộ State không cần F5
- Bất kỳ mutation nào trong `FinanceBloc` (`CreateInvoiceEvent`, `RecordPaymentEvent`, `SubmitTransferPaymentEvent`, `ApprovePendingPaymentEvent`, `RejectPendingPaymentEvent`, `CancelInvoiceEvent`, `RefundInvoiceEvent`, `CheckOverdueInvoicesEvent`, `CreatePromotionEvent`, `TogglePromotionEvent`):
  - Phải cập nhật ngay `_cachedInvoicesResponse`, `_cachedInvoiceDetails` và danh sách `myInvoices` trong `FinanceBloc`.
  - Khi thao tác từ màn hình chi tiết lớp hoặc duyệt đơn tuyển sinh, bắn sự kiện làm mới `FinanceBloc`, `ClassesBloc` và `ReportsBloc` để số liệu công nợ, sĩ số, `tuitionPaid` và biểu đồ doanh thu đồng bộ ngay lập tức.
- Mọi lỗi từ API (`400`, `403`, `404`, `409`, `500`) phải hiển thị thông báo tiếng Việt thân thiện, không hiển thị raw exception.

#### 4.2. Kiểm thử tự động bắt buộc
- Xây dựng bộ test tự động kiểm tra đầy đủ các luồng:
  1. Duyệt đơn đăng ký lớp có áp dụng giảm giá / thu tiền đợt 1 → tự động sinh `Invoice` và `Payment` chính xác.
  2. Admin tạo hóa đơn mới, áp mã khuyến mãi, ghi nhận thu tiền nhiều đợt (`PARTIALLY_PAID` → `PAID`), hoàn tiền (`REFUNDED`) và hủy hóa đơn (`CANCELLED`).
  3. Học viên/Phụ huynh gửi xác nhận chuyển khoản VietQR (`PENDING`) → Thu ngân bấm duyệt (`SUCCESS`) → số dư hóa đơn giảm ngay không cần F5.
  4. Phụ huynh mở Góc Phụ huynh → bấm *Thanh Toán Học Phí* → xem được hóa đơn của con em và mở màn hình thanh toán.
  5. Kiểm tra responsive không tràn layout (overflow) trên cả Mobile (`375px`, `430px`) và Desktop (`1280px`).
- Đảm bảo `dart analyze` và build Backend TypeScript đạt **0 errors**.

---

## 3. ĐỊNH DẠNG BÁO CÁO KHI HOÀN THÀNH

Sau khi thực hiện xong toàn bộ kế hoạch trên, hãy báo cáo theo đúng 8 mục:
1. Tóm tắt kiến trúc & các luồng nghiệp vụ Học phí – Thanh toán đã hoàn thiện.
2. Danh sách các API Endpoint Backend đã thêm mới và nâng cấp.
3. Chi tiết luồng Học phí khi Duyệt đơn đăng ký & Ghi danh lớp học.
4. Chi tiết Trung tâm Học phí & Thu ngân trên Admin Portal (Hóa đơn, Thu tiền, Đối soát VietQR, Hoàn tiền, Khuyến mãi).
5. Chi tiết Cổng Học phí dành cho Học viên & Phụ huynh.
6. Cơ chế đồng bộ State tức thì không cần F5 giữa `FinanceBloc`, `ClassesBloc`, `AdmissionsCrmView` và `ReportsBloc`.
7. Danh sách tất cả các file Backend, Frontend và Test đã thêm/sửa.
8. Kết quả Build, Static Analysis (`0 errors`) và Widget/Unit Tests.
