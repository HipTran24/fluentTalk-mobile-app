# Provider configuration QA — 2026-10-23

- Backend verify: 88 tests, 83 passed, 5 opt-in skipped; build thành công.
- Flutter: 192/192 passed; analyze không có vấn đề; web release build thành công.
- Gemini thật: text response nhận được; Gemini Live nhận được PCM và phụ đề qua WebSocket. Không ghi âm micro hoặc dùng lịch sử người học trong phép thử.
- OpenAI/Groq: kiểm thử adapter bằng HTTP client giả lập, kiểm tra endpoint cố định, Bearer auth, parse JSON và lỗi quota. Chưa gọi provider thật vì chưa có key tương ứng.
- Cấu hình: kiểm tra lưu ciphertext, giải mã lại, giữ key khi đổi model, bắt buộc key mới khi đổi provider, chống stale revision, khôi phục môi trường, audit và không trả secret qua API.
- Bảo vệ: anonymous 401, user 403 trên các thao tác cấu hình và kiểm tra provider. Live từ chối provider khác Gemini.
- UI: mở form cấu hình ở desktop, tablet và mobile 320 px chữ 200%; key được che; kiểm tra kết nối không lưu; lỗi lưu giữ form.
- Runtime: health UP, web HTTP 200; Flyway V11 thành công; schema riêng không có grant bảng cho anon/authenticated.

Hướng dẫn sử dụng và quản lý khóa mã hóa tại [ADMIN_CONSOLE.md](../ADMIN_CONSOLE.md). Không lưu key thật hoặc khóa mã hóa vào tài liệu, log hay Git.
