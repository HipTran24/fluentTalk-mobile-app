# Đo token và sử dụng theo ngày

Mở **Admin → Sử dụng**. Chọn 7/14/30 ngày, lọc Gemini/OpenAI/Groq, đổi chỉ số biểu đồ giữa tổng token, đầu vào, đầu ra và số yêu cầu. Chạm vào cột để xem chi tiết ngày; biểu đồ cuộn ngang trên điện thoại. Ngày được tính theo `Asia/Ho_Chi_Minh` (UTC+7), kể cả khi máy chủ chạy múi giờ khác.

## Dữ liệu ghi nhận

Mỗi lần backend thực sự gửi một yêu cầu chat đến provider tạo một bản ghi metadata riêng: provider/model, thời điểm, ngày Việt Nam, mục đích chat hoặc kiểm tra kết nối, kết quả, HTTP status, thời gian và các số token provider trả về. Không lưu API key, prompt, câu trả lời, email hoặc nội dung học vào bảng đo.

- Gemini: đọc `usageMetadata` (`promptTokenCount`, `candidatesTokenCount`, `totalTokenCount`, cache và thoughts nếu có). [API chính thức](https://ai.google.dev/api/generate-content#UsageMetadata).
- OpenAI/Groq Chat Completions: đọc `usage` (`prompt_tokens`, `completion_tokens`, `total_tokens`, cached/reasoning trong details nếu có). [OpenAI reference](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create), [Groq compatibility](https://console.groq.com/docs/openai).
- Tổng dùng đúng số provider báo, không tự cộng cache hoặc reasoning thêm lần nữa. Gemini có thể có các phần token khác ngoài đầu vào/đầu ra.
- Thiếu hoặc sai kiểu metadata được giữ là chưa biết, không ước lượng token từ ký tự. Số tổng trên giao diện là tổng phần đã biết; bộ đếm **Chưa có metadata token** chỉ rõ khoảng thiếu. Các thành phần cache/reasoning không có giá trị không đóng góp vào tổng thành phần.
- Lỗi 429/timeout vẫn ghi nhận số yêu cầu. Nếu provider trả token nhưng nội dung trả lời sai định dạng, token vẫn được ghi. Không mặc định yêu cầu lỗi là miễn phí.
- Kiểm tra kết nối trong trang cấu hình cũng có thể tiêu token, nên được tính và có bộ đếm riêng. Cấp token Live không phải chat token và không được cộng vào đây.

Giao dịch ghi usage độc lập với giao dịch lưu chat, vì provider có thể đã tính token ngay cả khi lưu chat rollback. Ghi metric thất bại được cảnh báo trong log máy chủ, không che mất kết quả chat và không retry yêu cầu upstream. Đây là dữ liệu vận hành của app, không thay thế hóa đơn/báo cáo billing nhà cung cấp.

## Phạm vi

Chỉ ghi từ lúc triển khai migration V12; không khôi phục số token cho hội thoại cũ hoặc yêu cầu trực tiếp ngoài backend. Hiện Gemini Live truyền trực tiếp giữa trình duyệt và provider, nên token Live chưa được xác minh từ máy chủ và không nằm trong chart này. Không nhận số token do client tự khai làm số đo đã xác nhận. Chưa có tính chi phí tiền tệ.

API `GET /api/v1/admin/usage?days=7&provider=gemini` chỉ dành cho admin, trả tổng, ngày liên tục (ngày không có yêu cầu có số 0) và tối đa 100 nhóm provider/model. Khoảng API tối đa 90 ngày. Bảng private `ai_usage_events` không cấp quyền cho Supabase anon/authenticated. Index ngày/provider phục vụ truy vấn; giao diện không tạo dữ liệu mẫu khi chưa có yêu cầu.
