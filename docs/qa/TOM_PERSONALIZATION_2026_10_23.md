# Tom và cá nhân hóa — kết quả kiểm tra

- Đổi tên giao diện/nhãn/thông báo từ AI/Emma sang Tom; giữ nguyên role `ai`, mã lỗi và giao thức để tương thích dữ liệu cũ. Đổi tên trong system instruction của chat và Live.
- Tab Tom mới đọc API learning; có mục tiêu, chủ đề, giọng mặc định, consent, kế hoạch ngày, đề xuất kèm lý do và nguồn hội thoại. Xem ../CA_NHAN_HOA_TOM.md để biết phạm vi và quyền riêng tư.
- Flutter: 184 test đạt; analyze không có vấn đề. Hai test Tom kiểm tra lưu lựa chọn qua API, không tự bật lưu phụ đề, không tạo nguồn giả và layout 320dp/chữ 200%.
- Backend verify: 78 test được phát hiện, 73 đạt, 5 opt-in bỏ qua. Bao gồm 7 ca learning kiểm tra JWT/account isolation, mặc định tắt, provenance, consent/ownership/idempotency/revoke, thời hạn 30 ngày, ranking và ngân sách thời gian.
- PostgreSQL thật: 4/4 concurrency test đạt trong schema QA tạm, schema đã được xóa. Production đã chạy 9 migration. Quyền Data API với hai bảng learning: 0 grant cho anon/authenticated.
- Snapshot đọc thật lúc kiểm tra: 1 profile, 0 tin nhắn người học đã lưu, 0 lựa chọn learning và 0 phụ đề đã đồng ý lưu. Không tạo lịch sử giả hay bật consent thay người dùng. Khi user bắt đầu lưu, dashboard/context dùng dữ liệu của họ.
- Provider smoke chạy riêng: 1/1 đạt, kiểm tra tên Tom trong câu trả lời chat, nhận 125762 byte PCM Live và phụ đề 36 ký tự. Dùng đầu vào tổng hợp, không thu micro hay gửi lịch sử người dùng cho phép thử này.
- Model text 3.8/3.5 trả 503 high demand trong thử nghiệm. Cấu hình máy chuyển sang gemini-2.5-flash, tắt thinking cho text; đã kiểm tra structured response và smoke thực tế. Live giữ gemini-3.8-live. Không tự retry POST khi timeout/kết quả chưa xác định.
- Build web release thành công. Kiểm thử nghe/nói micro và ghi phụ đề trên trình duyệt thật cần người dùng bật consent và gọi thử. Rời/đóng trình duyệt có thể làm yêu cầu lưu không hoàn tất; chỉ dữ liệu đã được server nhận mới xuất hiện trong memory.
