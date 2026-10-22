# Thiết lập email OTP cho FluentTalk

App đã có luồng: email + mật khẩu → Supabase signup → nhập mã email → verifyOTP(type: email) → khôi phục phiên và đồng bộ hồ sơ. Gửi lại sử dụng resend(type: signup), không tạo lại tài khoản. Chưa hỗ trợ đăng nhập không mật khẩu hoặc OTP khôi phục mật khẩu trong thay đổi này.

## 1. Bật xác nhận email
Trong Supabase Dashboard, mở Authentication → Sign In / Providers → Email (tên mục có thể thay đổi theo giao diện). Bật Email provider và Confirm email. Nếu tắt Confirm email, Supabase có thể đăng nhập ngay sau đăng ký và app không yêu cầu OTP.

## 2. Dán mẫu email
Authentication → Email Templates → Confirm signup:
- Subject: `Mã xác thực FluentTalk của bạn`
- Nội dung: sao chép toàn bộ `supabase/templates/confirm-signup.html`.
- Giữ nguyên `{{ .Token }}`; Supabase thay biến này bằng mã thật. Không tự nhập mã cố định.
- Lưu thay đổi. Luồng nhập mã không cần mở liên kết callback từ email.

## 3. Điền tài khoản gửi email (SMTP)
Trong Authentication → Email → SMTP Settings / Custom SMTP, bật custom SMTP và điền:

| Trường | Điền gì |
|---|---|
| Sender email | Địa chỉ gửi được nhà cung cấp SMTP cho phép |
| Sender name | FluentTalk |
| Host | SMTP host do nhà cung cấp cung cấp |
| Port | Cổng TLS theo tài liệu nhà cung cấp |
| Username | SMTP username |
| Password | SMTP password/API credential hoặc App Password theo nhà cung cấp |

Không gửi password qua chat, không dán vào Flutter hoặc mobile.public.json. Đây là cấu hình trên Supabase, không phải mật khẩu đăng nhập app. Chỉ email + mật khẩu hộp thư thông thường có thể chưa đủ: cần host, port và credential SMTP đúng. Nếu dùng Gmail yêu cầu App Password thì dùng App Password, không dùng mật khẩu tài khoản chính.

Nếu dùng tên miền gửi riêng, hoàn thành xác minh tên miền/DNS theo nhà cung cấp. SMTP mặc định Supabase bị giới hạn người nhận và tần suất, không dùng cho gửi đại trà. Thiết lập hạn mức email phù hợp, thời hạn OTP và độ dài mã trong cấu hình Auth. App chấp nhận mã số 6–10 ký tự để theo cấu hình Supabase. UI chờ 60 giây gửi lại; giới hạn thật và thời hạn do Supabase quyết định.

## 4. Kiểm thử bằng hộp thư thật
1. Mở app → Đăng ký, điền tên, email nhận được thư và mật khẩu từ 8 ký tự.
2. Nhận email, nhập mã → vào app. Mật khẩu đăng ký được xóa khỏi ô nhập sau khi có kết quả.
3. Thử mã sai, mã hết hạn, gửi lại sau 60 giây, mã đã dùng và mất mạng.
4. Đăng xuất rồi đăng nhập lại bằng email/mật khẩu.
5. Nếu rời màn hình OTP, mở Đăng nhập, điền email rồi chọn “Đã đăng ký nhưng chưa xác thực email?”. Có thể yêu cầu gửi lại tại màn OTP.
6. Kiểm tra Authentication → Logs nếu không nhận thư; kiểm tra Spam và danh sách người nhận được phép nếu chưa có custom SMTP.

Kiểm thử tự động dùng gateway giả và HTTP giả, không chứng minh email đã đến hộp thư. Chỉ xác nhận gửi thật sau bước 4 trên dự án đã cấu hình.

Tài liệu chính thức:
- https://supabase.com/docs/reference/dart/auth-verifyotp
- https://supabase.com/docs/reference/dart/auth-resend
- https://supabase.com/docs/guides/auth/auth-email-templates
- https://supabase.com/docs/guides/auth/auth-smtp
