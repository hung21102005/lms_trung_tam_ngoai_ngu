# 🛠️ HƯỚNG DẪN TẠO TÀI KHOẢN & CẤU HÌNH CÁC DỊCH VỤ NGOÀI

> **Dự án:** LMS Trung Tâm Ngoại Ngữ  
> **Cập nhật:** 09/10/2026  
> **Mục tiêu:** Hướng dẫn chi tiết từng bước tạo tài khoản, lấy API key/file cấu hình và gắn vào dự án cho Firebase, VNPay Sandbox, và Email Service.

---

## 1. DỊCH VỤ FIREBASE (BẮT BUỘC 🔴)

Firebase phụ trách 2 dịch vụ trọng yếu của hệ thống:
- **Cloud Messaging (FCM):** Bắn thông báo đẩy (push notification) cho học viên, giáo viên, phụ huynh.
- **Cloud Storage:** Lưu trữ bài giảng PDF, file âm thanh ghi âm nói (MP3/M4A), hình ảnh bài thi, avatar.

### Bước 1.1: Tạo Project trên Firebase Console
1. Truy cập [Firebase Console](https://console.firebase.google.com/) bằng tài khoản Google.
2. Bấm **Add project** (Tạo dự án).
3. Đặt tên dự án: ví dụ `lms-ngoai-ngu` (hoặc tên tùy chọn).
4. Bấm **Continue** $\rightarrow$ Có thể tắt Google Analytics (để tạo nhanh) $\rightarrow$ Bấm **Create project**.

---

### Bước 1.2: Bật Firebase Storage
1. Ở menu bên trái, chọn **Build** $\rightarrow$ **Storage**.
2. Bấm **Get started**.
3. Chọn chế độ:
   - **Start in test mode** (để dev/test tiện lợi trong 30 ngày đầu, hoặc cấu hình rules sau).
4. Chọn vị trí lưu trữ (Cloud Storage location): Nên chọn **`asia-southeast1` (Singapore)** hoặc **`asia-east1` (Taiwan)** để tốc độ tải file tại Việt Nam nhanh nhất.
5. Bấm **Done**.

---

### Bước 1.3: Cấu hình Firebase cho ứng dụng Flutter (2 cách)

#### Cách 1: Tự động bằng FlutterFire CLI (Khuyên dùng — Đã cài sẵn trên máy)
Mở terminal tại thư mục gốc dự án và chạy:
```powershell
# 1. Đăng nhập Firebase
firebase login

# 2. Tự động liên kết và tải file cấu hình cho cả Android & iOS
flutterfire configure
```
* Công cụ sẽ hiển thị danh sách các project Firebase của bạn $\rightarrow$ Chọn project vừa tạo.
* Chọn các nền tảng: `android`, `ios`, `web`.
* Công cụ sẽ **tự động tải `google-services.json`** vào `android/app/`, **`GoogleService-Info.plist`** vào `ios/Runner/`, và sinh file `lib/firebase_options.dart`.

#### Cách 2: Thủ công qua giao diện Web
Nếu làm thủ công:
1. **Thêm Android App:**
   - Tại trang chủ Project Overview, bấm biểu tượng **Android**.
   - Nhập Package Name: `com.example.lms_trung_tam_ngoai_ngu`
   - App nickname: `LMS Mobile Android`
   - Bấm **Register app** $\rightarrow$ Tải file `google-services.json`.
   - Di chuyển file vào thư mục: `android/app/google-services.json`.
2. **Thêm iOS App:**
   - Bấm biểu tượng **iOS**.
   - Nhập Apple bundle ID: `com.example.lmsTrungTamNgoaiNgu`
   - Bấm **Register app** $\rightarrow$ Tải file `GoogleService-Info.plist`.
   - Di chuyển file vào thư mục: `ios/Runner/GoogleService-Info.plist`.

---

### Bước 1.4: Lấy Service Account Key cho Backend (NestJS)
Để Backend có quyền gửi Push notification và quản lý file:
1. Vào **Project Settings** (biểu tượng bánh răng ⚙️ góc trên bên trái) $\rightarrow$ chọn tab **Service accounts**.
2. Chọn **Node.js**.
3. Bấm nút **Generate new private key** $\rightarrow$ xác nhận **Generate key**.
4. Trình duyệt sẽ tải về 1 file `.json` (ví dụ: `lms-ngoai-ngu-firebase-adminsdk-xxxxx.json`).
5. **Đổi tên file thành:** `firebase-service-account.json`.
6. **Lưu file vào đường dẫn:**
   ```
   backend/secrets/firebase-service-account.json
   ```
   *(Thư mục này đã được thêm vào `.gitignore`, an toàn không sợ lộ lên Git)*.
7. Mở file `.env` (ở cả thư mục gốc và thư mục `backend/.env`), cập nhật các giá trị tương ứng:
   ```env
   FIREBASE_PROJECT_ID=<project_id_cua_ban>
   FIREBASE_STORAGE_BUCKET=<project_id>.appspot.com
   ```

---

## 2. CỔNG THANH TOÁN VNPAY SANDBOX (QUAN TRỌNG 🟡)

Dùng để test tính năng thanh toán học phí trực tuyến mà không tốn tiền thật.

### Các bước lấy thông tin tài khoản VNPay Test:
1. Truy cập trang đăng ký thử nghiệm: [VNPay Sandbox Merchant Registration](https://sandbox.vnpayment.vn/devreg/).
2. Điền thông tin cá nhân/dự án để đăng ký tài khoản Merchant thử nghiệm.
3. Sau khi đăng ký thành công, VNPay sẽ gửi email chứa:
   - **Mã Website (TMN Code):** ví dụ `2QXUI4J4`
   - **Chuỗi bí mật tạo checksum (Hash Secret):** chuỗi ký tự bí mật
   - Link trang thanh toán test và danh sách thẻ ATM test (thẻ test không trừ tiền).
4. Cập nhật thông tin vào file `.env` và `backend/.env`:
   ```env
   VNPAY_TMN_CODE=<TMN_CODE_VNPAY_CAP>
   VNPAY_HASH_SECRET=<HASH_SECRET_VNPAY_CAP>
   VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
   VNPAY_RETURN_URL=http://localhost:3000/api/v1/finance/payments/vnpay-return
   ```

---

## 3. DỊCH VỤ GỬI EMAIL THÔNG BÁO (GMAIL APP PASSWORD) (🟢)

Hệ thống cần gửi email xác thực OTP, biên lai học phí và thông báo lịch học. Để tiện cho môi trường phát triển (Dev/Test), giải pháp nhanh nhất và miễn phí là dùng **Gmail App Password**.

### Các bước tạo Mật khẩu ứng dụng Gmail:
1. Truy cập [Google Account Security](https://myaccount.google.com/security).
2. Đảm bảo đã bật **Xác minh 2 bước (2-Step Verification)**.
3. Trong thanh tìm kiếm của Google Account, gõ tìm **"Mật khẩu ứng dụng"** (hoặc **App passwords**).
4. Đặt tên ứng dụng: `LMS Backend`.
5. Bấm **Tạo (Create)** $\rightarrow$ Google sẽ cấp một mật khẩu gồm 16 chữ cái (dạng `abcd efgh ijkl mnop`).
6. Cập nhật vào `.env` và `backend/.env`:
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=email_cua_ban@gmail.com
   SMTP_PASSWORD=abcdefghijklmnop
   ```

---

## 4. DỊCH VỤ SMS GATEWAY (TÙY CHỌN 🟢)

Dành cho giai đoạn nâng cao khi muốn gửi tin nhắn SMS trực tiếp đến phụ huynh:
- Có thể dùng **Twilio** (có $15 trial credit miễn phí) hoặc dịch vụ SMS trong nước như **eSMS.vn** / **SpeedSMS**.
- Ở giai đoạn Phase 1 đến Phase 3, hệ thống sẽ ưu tiên dùng **Push Notification FCM** và **Email** trước, SMS có thể cấu hình bổ sung sau.

---

## 5. TỔNG KẾT VỊ TRÍ CÁC FILE KHÓA SAU KHI TẢI

| File | Nơi lưu trong dự án | Trạng thái bảo mật Git |
|:---|:---|:---:|
| `google-services.json` | `android/app/google-services.json` | Đã ignore trong `.gitignore` ✅ |
| `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` | Đã ignore trong `.gitignore` ✅ |
| `firebase-service-account.json` | `backend/secrets/firebase-service-account.json` | Đã ignore trong `.gitignore` ✅ |
| Thông tin VNPay & Gmail | Điền trực tiếp vào file `.env` & `backend/.env` | `.env` đã được ignore ✅ |
