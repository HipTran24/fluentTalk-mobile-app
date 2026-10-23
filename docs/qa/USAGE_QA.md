# Usage analytics QA — 2026-10-23

- Backend verify: 92 tests, 87 passed, 5 opt-in skipped; build thành công.
- Flutter: 193/193 passed; analyze không có vấn đề; release web build thành công.
- Provider smoke opt-in: nhận metadata token thật của Gemini, ghi qua hook metering được kiểm tra bằng repository capture; Live PCM vẫn hoạt động. Không chèn dữ liệu thử vào bảng usage production.
- Kiểm thử parser Gemini/OpenAI/Groq, không ước lượng metadata thiếu hoặc không hợp lệ; HTTP 200 với nội dung sai định dạng vẫn ghi số token provider trả; lỗi metric không làm hỏng câu trả lời chat.
- Integration test: tổng ngày/provider, ngày trống, lọc phạm vi, lỗi/unknown/check, chống truy vấn ngoài phạm vi và giữ metric sau rollback transaction ngoài.
- API usage: anonymous 401, user thường 403.
- UI: các kích thước 320/390/886/1440 px, chữ 200%, đổi khoảng ngày/provider, tương tác cột và chi tiết ngày. [Ảnh fixture](ui/admin-usage-fixture.png) dùng dữ liệu test để đánh giá bố cục.
- Runtime local: backend health UP; Supabase migration V12 thành công; private schema không có grant bảng cho anon/authenticated; secret scan sạch.

Phạm vi: đo token chat qua backend, gồm probe cấu hình; chưa có đo token Live trực tiếp hoặc chi phí. Không hồi tố dữ liệu cũ. [Hướng dẫn](../USAGE_ANALYTICS.md).
