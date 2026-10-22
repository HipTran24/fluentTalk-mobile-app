# Tom — cá nhân hóa từ dữ liệu tài khoản

## Bật tính năng
1. Tải lại web, đăng nhập và mở tab **Tom**.
2. Bật **Cá nhân hóa cùng Tom**. Điền mục tiêu, chủ đề quan tâm và giọng mặc định, sau đó bấm **Lưu cá nhân hóa**.
3. Trình độ tự chọn và mục tiêu phút/ngày lấy từ **Cá nhân**; không tự nâng trình độ dựa trên số phiên.
4. Nếu muốn ghi nhớ cuộc gọi, bật riêng **Cho Tom ghi nhớ phụ đề cuộc gọi** rồi lưu. Phiên gọi tiếp theo sẽ được cấp quyền ghi nhớ. Không lưu bản ghi âm.

## Dữ liệu và cách quyết định
- Đề xuất lấy từ danh mục tình huống thật đang active, xếp theo độ gần trình độ tự chọn, chủ đề ưu tiên và việc đã có phiên luyện hay chưa.
- Mục tiêu cá nhân được đưa vào kế hoạch ngày và ngữ cảnh gia sư. Đây là gợi ý dựa trên sở thích và hoạt động, không phải chẩn đoán lỗi ngôn ngữ.
- Đọc tối đa 100 phiên gần nhất, 30 tin nhắn người học, 20 phụ đề của 30 ngày gần nhất. Nguồn hiển thị tối đa 3 trích đoạn chat và 2 trích đoạn thoại.
- Tom chat và Live nhận ngữ cảnh ngắn từ chính user đang đăng nhập: mục tiêu, trình độ tự chọn, thời gian, chủ đề, tối đa 3 tin nhắn gần nhất và 2 đoạn phụ đề đã đồng ý lưu. Nội dung này được gửi tới Gemini để thích ứng ví dụ và nối tiếp hội thoại.
- Phụ đề Live là văn bản trình duyệt nhận được từ provider, có thể nhận dạng sai và có nguồn `browser_live_transcript`. Không coi đây là audio đã được xác minh hoặc bằng chứng chấm phát âm.
- Khi chưa có lịch sử, Tom hiển thị rõ rằng đề xuất chỉ dựa trên lựa chọn cá nhân và danh mục. Không tạo điểm, lỗi hoặc lịch sử giả.
- Phút trong kế hoạch hôm nay chỉ tính các phiên hoàn thành đã lưu trong cửa sổ 100 phiên; hiện chỉ có chat. Cuộc gọi ghi nhớ phụ đề chưa cộng phút. Ngày tính theo Asia/Ho_Chi_Minh, được nêu trong UI.

## Quyền riêng tư
- Cá nhân hóa và lưu phụ đề mặc định tắt, lưu tại server theo Supabase JWT subject; không nhận userId từ client.
- Chỉ nhận phụ đề khi user đã bật cả hai tùy chọn và có phiên Live do server cấp cho chính tài khoản đó trong 15 phút gần nhất.
- Lưu tối đa 8000 ký tự phần người học nói mỗi phiên, không lưu lời Tom thành dữ liệu người học. ID duy nhất bằng ID cấp phiên chống ghi lặp. Payload khác cho cùng ID trả conflict.
- Rời màn hình/kết thúc gọi sẽ cố lưu phụ đề đã nhận. Nếu mạng/browser ngắt khi đóng trang, dữ liệu có thể chưa lưu; không báo giả là đã ghi nhớ. Đổi tài khoản sẽ bỏ phần chưa gửi của phiên cũ.
- Phụ đề quá 30 ngày bị loại khỏi ngữ cảnh ngay; job xóa vật lý chạy mỗi giờ (khởi động sau 60 giây).
- Tắt lưu phụ đề hoặc tắt cá nhân hóa xóa toàn bộ phụ đề đã lưu. Nút **Xóa phụ đề đã ghi nhớ** chỉ xóa phụ đề, giữ lịch sử chat. Tắt cá nhân hóa ngừng dùng lịch sử giữa các phiên ở những yêu cầu mới; yêu cầu Gemini đã bắt đầu không thể thu hồi.
- Có thể đọc lại nguồn chat. Cá nhân hóa không thay đổi consent lưu audio; app không thu lưu audio.

## API và vận hành
- GET/PATCH `/api/v1/me/learning`
- POST/DELETE `/api/v1/me/learning/voice-notes`
- Flyway V9: learning_preferences, voice_learning_notes trong schema private; thu hồi quyền Data API anon/authenticated.
- Kiểm thử tích hợp kiểm tra phân tách tài khoản, consent, idempotency, thu hồi/xóa, thời hạn lưu và ngân sách thời gian. Fixture trong test không ghi vào dữ liệu người dùng production.
- Phần phát hiện lỗi ngữ pháp lặp lại, chấm điểm kỹ năng, lịch ôn từ vựng chưa được triển khai; giao diện không tuyên bố có những kết quả đó.
