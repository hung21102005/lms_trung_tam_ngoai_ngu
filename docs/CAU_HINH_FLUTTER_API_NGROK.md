# Cấu hình Flutter Web gọi API qua ngrok

## Cấu hình đã triển khai

`lib/core/constants/api_endpoints.dart` là nguồn URL API duy nhất; `lib/core/network/api_client.dart` dùng Dio với URL này cho Auth, Public, Admin, bài tập, upload và download. Tên biến compile time: **`API_BASE_URL`**. Giá trị phải là URL đầy đủ **có `/api/v1` đúng một lần**, ví dụ `https://<ten-mien-ngrok>/api/v1`, không có dấu `/` cuối. Không truyền token, mật khẩu hoặc khóa JWT vào Flutter Web.

Không truyền biến khi chạy local: Web gọi `http://localhost:3000/api/v1`, Android emulator gọi `http://10.0.2.2:3000/api/v1`. Web ở host công khai thiếu biến sẽ báo lỗi cấu hình rõ ràng thay vì gọi localhost của người xem. Nếu trang HTTPS được cấp API HTTP, cấu hình bị từ chối để tránh mixed content. Đổi URL ngrok sau build phải build/deploy lại.

## Chạy local trên Windows

Tại root, chuẩn bị Docker và backend theo [hướng dẫn cài đặt](HUONG_DAN_CAI_DAT_VA_CHAY_DU_AN.md). Trong PowerShell khác:

```powershell
flutter pub get
flutter run -d chrome
```

Mở `http://localhost:3000/api/docs` để kiểm tra backend. Không chạy đồng thời backend container và `npm run start:dev` ở cùng cổng 3000.

## Tạo tunnel và build Web cho Vercel

Sau khi cài ngrok từ trang chính thức và cấu hình tài khoản trên máy cá nhân, khởi chạy tunnel tới cổng backend:

```powershell
ngrok http 3000
```

Lấy URL **HTTPS Forwarding** ngrok đang hiển thị. Không đưa URL vào source; đặt biến PowerShell cục bộ và build:

```powershell
$apiBase = 'https://<ten-mien-ngrok>/api/v1'
flutter pub get
flutter build web --release --dart-define="API_BASE_URL=$apiBase"
```

Đầu ra ở `build/web`. Upload thư mục này lên Vercel bằng quy trình triển khai tĩnh của nhóm. Backend và Docker trên laptop phải tiếp tục chạy trong lúc website được sử dụng. Chỉ tunnel cổng backend; không công khai cổng PostgreSQL. Khi tên miền ngrok đổi, thay `$apiBase`, build lại và triển khai lại `build/web`.

## Kiểm tra trước khi demo

1. Trên laptop, gọi endpoint công khai thực tế qua URL tunnel, chẳng hạn `https://<ten-mien-ngrok>/api/v1/public/programs`; xác nhận JSON thay vì HTML ngrok. Với tunnel được cung cấp ngày 30/10/2026, request không có header trả `ERR_NGROK_6024`; có `ngrok-skip-browser-warning: true` trả JSON 200. Dio hiện tự thêm header này cho ngrok Web, kể cả refresh token. Backend đã cho phép header này trong CORS.
2. Mở website Vercel → Chrome DevTools → Network → lọc `Fetch/XHR`. Request phải tới `https://<ten-mien-ngrok>/api/v1/...`, không tới `localhost`; kiểm tra status và Content-Type JSON.
3. Với lỗi CORS, xem Origin và OPTIONS preflight. Backend cho phép `localhost`/`127.0.0.1` với cổng phát triển bất kỳ, và các origin HTTPS/HTTP liệt kê trong `CORS_ORIGINS` (phân tách bằng dấu phẩy, không có đường dẫn). Đặt biến này trong `backend/.env` khi chạy `npm run start:dev`, hoặc trong `.env` ở root khi chạy backend bằng Docker Compose, ví dụ `CORS_ORIGINS=https://ten-du-an.vercel.app`. Khởi động lại backend sau khi đổi biến. Xác thực hiện dùng JWT trong header/body, không dùng cookie, nên CORS không bật `credentials`.
4. Nếu response là trang cảnh báo ngrok, kiểm tra tunnel và header `ngrok-skip-browser-warning` trong Network. Nếu API trả absolute file URL `localhost`, file sẽ không tải trên máy người khác. `resolveAttachmentUrl` xử lý đường dẫn tương đối `/uploads/`, nhưng absolute localhost từ Backend cần được kiểm tra với dữ liệu thực trước khi công bố.
5. WebSocket nếu được thêm sau cần URL `wss://` riêng. Source Flutter được rà trong bước này chưa thấy WebSocket client.

## Giới hạn kiểm chứng

Tunnel ngrok `https://scotch-refute-tarantula.ngrok-free.dev` đã trả JSON 200 với header cảnh báo bỏ qua. Bản Flutter Web release đã được build **trên máy local** với URL tunnel này; chưa deploy lên Vercel. Chưa có domain Vercel thật, nên chưa kiểm chứng đăng nhập từ Vercel, file upload/download và preflight từ domain triển khai. Lần thử `OPTIONS` có header ngrok trên backend đang chạy trước khi restart trả 404, trong khi preflight local không có header đó trả 204; cần restart backend với code mới rồi kiểm tra lại. URL API là giá trị công khai được nhúng vào build; đổi tunnel phải build lại.
