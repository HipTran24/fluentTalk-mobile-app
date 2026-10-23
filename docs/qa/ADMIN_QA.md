# Admin console QA — 2026-10-23

## Kết quả

- Maven verify: 83 tests, 78 passed, 5 opt-in tests skipped; build thành công.
- PostgreSQL concurrency opt-in: 4/4 passed trong schema QA riêng, schema được xóa sau kiểm thử.
- Toàn bộ Flutter suite tại mốc triển khai: 190/190 passed. Sau khi bổ sung kiểm tra route desktop và mở/đóng form trên các kích thước, nhóm admin: 7/7 passed.
- Flutter analyze: không có vấn đề. Web release build thành công.
- Runtime local: web HTTP 200, backend health UP, admin API khi chưa đăng nhập trả 401.
- Supabase thật: 10 migration thành công, không có table grant cho anon/authenticated trong schema riêng.
- Secret scan: không tìm thấy credential khớp trong các file có thể push, staged changes và reachable Git history.

## Phạm vi kiểm tra

API: yêu cầu quyền admin trên mọi endpoint; không thể tự khóa tài khoản đang quản trị; khóa học viên chặn JWT đã cấp; stale revision trả 409; tạo nháp, xuất bản, ẩn tình huống; audit gắn đúng actor; pagination và dữ liệu nhập được kiểm tra; cấu hình trả về không chứa key; tài khoản thường không thể tự nâng quyền qua hồ sơ.

UI: desktop 1440 px, tablet 886 px, mobile 390 px, mobile 320 px với chữ 200%; mở các mục quản trị và form học viên; kiểm tra debounce tìm kiếm, giữ nội dung khi lưu thất bại, route admin dùng toàn bộ chiều rộng desktop. Sửa vòng đời TextEditingController để chỉ dispose sau khi dialog kết thúc animation.

Ảnh dưới đây dùng fixture trong kiểm thử để quan sát bố cục, không phải dữ liệu học viên thật:

- [Desktop](ui/admin-1440-fixture.png)
- [Mobile](ui/admin-390-fixture.png)

## Còn chờ

Email được người dùng chọn để cấp quyền chưa tồn tại trong Supabase Auth tại thời điểm kiểm tra. Script cấp quyền đã rollback, chưa nâng quyền cho tài khoản khác. Sau khi đăng ký và xác thực đúng email, chạy công cụ cấp quyền trong [hướng dẫn quản trị](../ADMIN_CONSOLE.md), rồi đăng nhập lại.

Chưa nghiệm thu thao tác quản trị end-to-end với tài khoản thật vì chưa có tài khoản đích. JWT, database và giao diện được kiểm tra qua bộ test riêng; không tạo học viên giả trong database thật để thay thế bước này.
