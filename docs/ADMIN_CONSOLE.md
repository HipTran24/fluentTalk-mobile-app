# Quản trị FluentTalk

Trang quản trị thật nằm tại `/#/admin`. Sau khi đăng nhập bằng tài khoản có quyền admin, app tự mở trang quản trị. Admin không được truy cập màn hình học viên; muốn dùng khu học tập cần đăng xuất và đăng nhập bằng tài khoản thường. Desktop có thanh điều hướng bên trái; màn hình nhỏ chuyển sang menu thu gọn.

## Chức năng

| Mục | Thao tác |
| --- | --- |
| Tổng quan | Hồ sơ học viên, tài khoản tạm khóa, nội dung xuất bản, phiên hoàn thành và số phiên được tạo trong 7 ngày UTC. |
| Học viên | Tìm tên/email, lọc trình độ, phân trang; chỉnh tên, trình độ tự chọn, mục tiêu phút/ngày và tạm khóa/mở khóa. |
| Tình huống | Tìm kiếm, lọc xuất bản/ẩn; tạo, chỉnh bối cảnh, vai trò Tom/người học, trình độ, chủ đề, thời lượng, mẫu câu và mục tiêu. |
| Chủ đề | Tạo và chỉnh tên, slug; slug duy nhất. |
| Sử dụng | Token chat từ metadata provider, chart theo ngày Việt Nam, bộ lọc khoảng ngày/provider và thống kê lỗi/thiếu metadata. |
| Nhật ký | Xem người thực hiện, loại thao tác, đối tượng và thời gian; phân trang. |
| Dịch vụ | Đổi provider chat (Gemini/OpenAI/Groq), model và API key; cấu hình Gemini Live riêng; kiểm tra kết nối và khôi phục môi trường máy chủ. |

Tình huống mới mặc định là bản nháp. Bật **Xuất bản trong danh mục** khi nội dung đã sẵn sàng. Tắt công tắc để ẩn; không xóa lịch sử học. Số phút chỉ tính phiên đã hoàn thành, chưa bao gồm cuộc gọi Live. Trạng thái dịch vụ cho biết cấu hình có mặt, không thay thế phép thử nhà cung cấp. Thống kê token chat nằm trong mục Sử dụng; chưa có token Live, chi phí hoặc số kết nối Live đang mở.

Học viên được đếm từ bảng hồ sơ của app, không phải tất cả tài khoản Supabase Auth chưa hoàn tất hồ sơ. Dữ liệu trống hiển thị trạng thái trống, không sinh dữ liệu minh họa.

## Cấp quyền

Tài khoản phải **đăng ký và xác thực email** trước. Từ thư mục dự án, người vận hành được ủy quyền chạy:

```sh
python3 scripts/grant_admin.py --email admin@example.com
```

Script đọc cấu hình database riêng trên máy, chỉ cập nhật `app_metadata.role` của đúng một tài khoản đã xác thực và giữ các metadata khác. Không tạo tài khoản, không đặt mật khẩu. Script rollback nếu không tìm thấy tài khoản hoặc có lỗi. Sau đó đăng xuất/đăng nhập lại để JWT mang quyền mới. Không sửa `user_metadata` hay hồ sơ để cấp quyền.

Không có nút tự nâng quyền trong app. Quyền admin được backend kiểm tra từ JWT đã xác minh chữ ký, bên cạnh chặn route ở frontend. API `/api/v1/admin/**` trả 401 khi chưa đăng nhập và 403 cho tài khoản thường. Token admin bị chặn ở các API học tập, kể cả khi đồng thời có role USER; GET `/api/v1/me` chỉ được dùng chung để khởi tạo danh tính đăng nhập. API quản trị dùng `Cache-Control: no-store`.

## Tính nhất quán và giới hạn

- Hồ sơ và tình huống dùng revision để từ chối thay đổi trên dữ liệu cũ bằng lỗi 409. Tải lại dữ liệu trước khi chỉnh lại; form giữ nội dung khi lưu thất bại.
- Tạm khóa được backend kiểm tra trên mỗi request, kể cả JWT đã được cấp. Đây là khóa sử dụng API app, không phải xóa/cấm đăng nhập Supabase Auth. Kết nối Live đã mở có thể tiếp tục trong thời hạn token ngắn đã cấp, tối đa 5 phút.
- Nhật ký chỉ lưu ID, loại thao tác và thời gian, không lưu mật khẩu, key hay nội dung hội thoại. Backend không cho sửa/xóa nhật ký qua API.
- Không có thao tác xóa vĩnh viễn học viên trong giao diện. Quản lý danh tính, thu hồi phiên Auth và vòng đời tài khoản vẫn thực hiện trong Supabase bởi người vận hành được cấp quyền.
- Key mới được nhập bằng ô mật khẩu, gửi đến backend và mã hóa AES-256-GCM trong database. API chỉ trả trạng thái có key, không trả key hay ciphertext. Không nhập key qua URL hoặc chat. Dùng HTTPS khi triển khai ngoài localhost.

Migration V10 thêm revision, trạng thái tạm khóa, bảng audit và index hoạt động. Các kiểm thử API bao gồm phân quyền, tự khóa, khóa JWT hiện có, xung đột revision, vòng đời nháp/xuất bản/ẩn và audit. Kiểm thử Flutter kiểm tra desktop, tablet, điện thoại, chữ lớn, lỗi lưu và debounce tìm kiếm.


## Đổi provider và model

Mở **Dịch vụ → Provider chat / Provider giọng nói → Thay đổi cấu hình**. Chọn provider, nhập model ID được tài khoản nhà cung cấp cho phép và API key mới. Để trống key khi chỉ đổi model để giữ key cùng provider; đổi provider phải nhập key mới. **Kiểm tra kết nối** thử cấu hình đang nhập mà chưa lưu: chat gửi một câu chào và kiểm tra JSON, Live thử cấp phiên ngắn hạn. Phép thử có thể phát sinh phí, không gửi lịch sử học viên. Chỉ **Lưu thay đổi** mới áp dụng cho yêu cầu tiếp theo. Cuộc gọi đang mở giữ cấu hình cũ.

Chat hỗ trợ Gemini và Chat Completions của OpenAI/Groq với model hỗ trợ JSON. API upstream dùng endpoint cố định của từng nhà cung cấp, không cho nhập URL tùy ý. Adapter dùng [OpenAI Chat Completions](https://developers.openai.com/api/reference/resources/chat) và [Groq OpenAI compatibility](https://console.groq.com/docs/openai). Không tự động chuyển provider khi lỗi để tránh gửi dữ liệu học viên tới nhà cung cấp khác ngoài lựa chọn quản trị.

Live hiện chỉ hỗ trợ giao thức Gemini Live; có key và model riêng, không bị thay khi đổi provider chat. Nút kiểm tra Live không thay thế nghiệm thu âm thanh/micro trong trình duyệt.

**Khôi phục cấu hình máy chủ** bỏ cấu hình database của đúng kênh, dùng lại Gemini theo biến môi trường. Các thay đổi được ghi audit theo ID admin và kênh, không chứa key. Revision chặn ghi đè cấu hình cũ.

Máy chủ cần `AI_CONFIG_ENCRYPTION_KEY`, base64 của 32 byte ngẫu nhiên. Tạo một lần bằng `python3 -c 'import secrets,base64; print(base64.b64encode(secrets.token_bytes(32)).decode())'` và lưu trong secret storage của máy chủ, tuyệt đối không commit. Giữ cùng khóa khi khởi động lại hoặc chuyển máy chủ; sao lưu cùng chính sách phục hồi database. Đổi/mất khóa mà chưa mã hóa lại sẽ khiến các key đã lưu không đọc được. Biến môi trường Gemini ban đầu vẫn là cấu hình dự phòng. Nếu chưa có khóa mã hóa, giao diện không cho lưu key.

Chi tiết phạm vi đo và cách đọc biểu đồ: [Usage Analytics](USAGE_ANALYTICS.md).
