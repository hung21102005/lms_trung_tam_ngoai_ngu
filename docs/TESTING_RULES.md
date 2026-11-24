# 🛡️ QUY TẮC KIỂM THỬ BẮT BUỘC CHO EDULMS

Áp dụng từ: **29/10/2026**
Phạm vi: Mọi thay đổi liên quan đến **Flutter UI, Routing, Authentication, Adaptive UI hoặc State Management**.

---

## 1. Quy Trình Xác Minh 2 Mức

### Mức 1 – Static & Build Verification
1. **Static Analysis:**
   - Chạy `flutter analyze` (hoặc kiểm tra qua Dart Analysis Server).
   - Đảm bảo **0 errors** trên toàn bộ các file thay đổi và dự án.
2. **Unit / Widget Test:**
   - Chạy `flutter test` cho module hoặc widget bị ảnh hưởng trước khi chuyển bước.
3. **Build Check:**
   - Xác minh khả năng biên dịch thực tế của ứng dụng (`flutter build web --debug` hoặc tương đương).

---

### Mức 2 – Runtime Verification
1. **Khởi chạy thực tế:**
   - Khởi chạy ứng dụng Flutter Web (`flutter run -d chrome`).
2. **Xác nhận Render:**
   - Xác nhận ứng dụng thực sự render được trên màn hình, không bị kẹt ở màn hình trắng, splash hoặc spinner vô tận.
3. **Route Navigation:**
   - Điều hướng trực tiếp tới các route chịu tác động từ thay đổi để kiểm tra luồng màn hình.
4. **Console Audit:**
   - Kiểm tra log Chrome Console và Flutter runtime log; đảm bảo không phát sinh Unhandled Exception, assertion failure hoặc RenderFlex overflow.
5. **Kiểm tra nghiệp vụ cụ thể:**
   - **Authentication:** Kiểm tra luồng đăng nhập, chuyển đổi quyền hạn (RBAC), duy trì session và đăng xuất.
   - **Adaptive UI:** Kiểm tra đồng thời cả 2 chế độ hiển thị:
     - **Desktop** ($\ge 1024$px / Web mode)
     - **Mobile** ($< 600$px / Phone mode)

---

## 2. Nguyên Tắc Trung Thực & Minh Bạch Kỹ Thuật

* **Minh bạch trạng thái:** Nếu môi trường chưa hỗ trợ mở trình duyệt hoặc Backend API chưa sẵn sàng, bắt buộc phải ghi rõ:
  > **"Chưa kiểm chứng runtime"**  
  Tuyệt đối không báo "toàn bộ chức năng hoạt động thành công" nếu chưa thực hiện Mức 2.
* **Quy tắc Checkpoint Git:** Tuyệt đối không tạo Git checkpoint được đánh dấu ổn định nếu vẫn còn lỗi runtime nghiêm trọng trong phạm vi thay đổi.
* **Thứ tự ưu tiên:** Luôn ưu tiên sửa dứt điểm các lỗi làm ứng dụng không khởi động được, crash, hoặc hỏng điều hướng trước khi phát triển tính năng mới.
