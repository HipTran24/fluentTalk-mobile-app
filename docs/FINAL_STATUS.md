# Báo cáo bàn giao ngày 21/10/2026

**Chưa hoàn thành đủ tám giai đoạn trong bốn giờ. Dự án chưa sẵn sàng production.** Khung kế hoạch là 16:13–20:13, Asia/Ho_Chi_Minh. Máy bị khóa trong lúc cần giao bản sửa cho Antigravity; khi nhận xác nhận mở khóa, đồng hồ đã qua 20:13. Sau đó chỉ xử lý lỗi xác thực quan trọng, khóa phạm vi và kiểm tra bản bàn giao. Việc chờ mở khóa không được tính là triển khai thành công.

Kế hoạch chi tiết: [KE_HOACH_8_GIAI_DOAN.md](KE_HOACH_8_GIAI_DOAN.md). Nguồn đã đọc và lưu: [PROJECT_MASTER_PLAN.md](PROJECT_MASTER_PLAN.md), ESP-PLAN-001 v1.1, ưu tiên phụ lục A–E. Hợp đồng API: [API_CONTRACT.yaml](API_CONTRACT.yaml). Hợp đồng chứa cả endpoint dự kiến; không đồng nghĩa tất cả đã được triển khai.

## Trạng thái tám giai đoạn

| Giai đoạn | Kết quả thực tế | Phần còn thiếu để nghiệm thu |
|---|---|---|
| 1. Nền tảng | Backend Java 27, Maven, health/error/requestId, OpenAPI, Flyway, PostgreSQL local, cấu hình và network mobile đã chạy kiểm tra local | Hạ tầng production, CI từ xa, vận hành/rollback và framework ổn định |
| 2. Auth và giao diện | Có Supabase repository, JWT/JWKS backend, hồ sơ/settings theo subject; sửa router, logout, stale requests, quyền admin, theme và nhiều lỗi widget | Supabase thật, full account/media cleanup, xác minh toàn bộ giao diện và accessibility trên thiết bị |
| 3. Danh mục | Backend chủ đề/tình huống, lọc/phân trang; migration mới có 4 chủ đề, 12 tình huống | Flutter vẫn dùng dữ liệu minh họa; seed thiếu A0/C1/C2; validation đầu vào chưa hoàn toàn khớp hợp đồng |
| 4. Chat AI/TTS | Lớp HTTP, lỗi định kiểu, hủy request và hợp đồng đã có | Chưa có session/message persistence, Gemini/TTS thật, quota và idempotency database |
| 5. Guided audio | Có màn hình minh họa và đặc tả | Chưa có luồng thu âm/STT/TTS thật, consent/storage/deletion đã kiểm chứng |
| 6. Realtime | Có màn hình minh họa và hợp đồng | Chưa có transport/provider thật, token phiên ngắn hạn, reconnect và ma trận 30 cuộc gọi |
| 7. Feedback/coach | Điểm thiếu bằng chứng bị ẩn; phát âm N/A khi thiếu acoustic evidence; overall cần đủ bốn trục hợp lệ | Chưa có đánh giá/coach/progress từ phiên thật, memory lifecycle và hiệu chuẩn |
| 8. QA/bàn giao | Đã chạy các kiểm tra local dưới đây, ghi lỗi và hướng dẫn | UAT-01..09, kiểm thử cloud/thiết bị, profile hiệu năng và release acceptance chưa đạt |

## Ranh giới demo và chế độ thật

Build mặc định không bật demo. Khi thiếu cấu hình, ứng dụng thông báo cấu hình chưa sẵn sàng. Với tài khoản thật, các màn học chưa tích hợp bị chuyển sang `/unavailable`; tránh hiển thị thành công giả. Chỉ build bật rõ `DEMO_MODE=true` mới mở dữ liệu mô phỏng, có nhãn **DEMO** toàn ứng dụng. Nhãn demo không biến các chức năng này thành chức năng đã nghiệm thu.

## Bằng chứng đã chạy

- Flutter: **85/85 bài kiểm thử đạt** ở bản chốt, gồm các kiểm tra network, router, auth lifecycle và tính hợp lệ của điểm.
- `flutter analyze --no-pub --no-fatal-infos`: exit 0, **0 lỗi, 0 cảnh báo, 158 thông tin**. Đây không phải kết quả sạch của chế độ analyze nghiêm ngặt; các góp ý/deprecation vẫn cần dọn.
- Backend: QA độc lập chạy `./mvnw verify` trên JDK 27: **25 bài, 0 thất bại, 0 lỗi, 0 bỏ qua**. Class ứng dụng có major version 71.
- PostgreSQL 17 mới `esp_final`: Flyway V1–V3 migrate/validate đạt, SQL đọc lại đúng 4 chủ đề và 12 tình huống.
- JAR đóng gói + PostgreSQL thật + RSA/JWKS fixture local: **14/14 kiểm tra đạt**, gồm JWT không hợp lệ bị từ chối, hồ sơ hai chủ sở hữu tách biệt, metadata do người dùng điều khiển không cấp admin và catalog phân trang đúng. Đây chưa phải kiểm thử Supabase cloud hay toàn bộ IDOR.
- Health benchmark local: 100 request, concurrency 4, p50 13.85 ms, p95 45.79 ms. Chỉ đo health; chưa chứng minh mục tiêu latency API nghiệp vụ hoặc độ mượt mobile.
- APK Android: **build thất bại, exit 1; chưa tạo APK**. Lần cuối chạy 778.2 giây và kết thúc với `java.io.IOException: No space left on device` khi Gradle ghi transform metadata. Đã qua bước kiểm tra phiên bản và cài các SDK thiếu, nhưng chưa có bằng chứng build hoàn tất. Tóm tắt: [qa/android-build-result.json](qa/android-build-result.json).

QA chi tiết: [qa/FINAL_QA_REPORT.md](qa/FINAL_QA_REPORT.md); mẫu runtime: [qa/local-api-smoke.json](qa/local-api-smoke.json).

## Java 27 và Android

Backend dùng OpenJDK 27.0.1 đã xác minh SHA256. Spring Boot 3.4.2 không đọc được class Java 27 trong kiểm tra thực tế; bản hiện tại chuyển sang **Spring Boot 4.2.0-M2** và chạy được bộ test. Milestone chưa đủ cơ sở để gọi là nền tảng production ổn định; cần đánh giá phiên bản được hỗ trợ trước phát hành.

Android có toolchain riêng. Đã bỏ đường dẫn JDK Windows cố định khỏi `android/gradle.properties`; lần build local dùng JDK 21 qua cấu hình Flutter/XDG tách riêng, không thay đổi cấu hình Flutter toàn máy. Đồng bộ Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20 theo mức tối thiểu Flutter đang cài, dùng NDK do Flutter chọn. Giảm heap Gradle từ 8 GB xuống 2 GB, Kotlin daemon 768 MB và giới hạn hai worker vì máy local có 8 GB RAM. Đây là điều chỉnh tài nguyên build, chưa phải bằng chứng tối ưu hiệu năng runtime. Yêu cầu Java 27 áp dụng cho backend, không ép Android Gradle chạy bằng JDK 27.

Sau lỗi đầy ổ đĩa, đã dừng các daemon do lượt build này tạo và xóa hai archive tải tạm JDK/Gradle (khoảng 423 MiB); giữ bản toolchain đã giải nén, mã nguồn và kết quả test. Dung lượng trống đọc lại khoảng 2.7 GiB, vẫn hạn chế cho Android build. Không xóa dữ liệu cá nhân hay cache không thuộc lượt công việc này. Flutter còn cảnh báo các phiên bản Android hiện tại sẽ cần nâng tiếp trong tương lai; chưa kiểm chứng release signing hay INTERNET permission trong manifest release.

## Điều phối và quota

Đã tạo đúng hai subagent theo yêu cầu: **GPT-6 Sol** giao việc trực tiếp cho AI trong Antigravity IDE; **GPT-5.6 Sol** rà soát và kiểm tra độc lập. IDE đã nhận lệnh đóng phạm vi và được xác nhận ở trạng thái idle. Agent chính sửa tích hợp, kiểm chứng runtime và đóng gói báo cáo. Không commit, push hay deploy.

Quota Codex được kiểm tra theo cửa sổ tài khoản dùng chung: có lúc đạt 80% trước reset; lần kiểm tra bàn giao cuối là 68% của cửa sổ 5 giờ và 26% tuần. Đây là mức dùng của tài khoản, không phải số token riêng dự án. Không có credit bổ sung; chưa chạm rate limit tại lần đọc này.

## Việc cần người dùng chuẩn bị cho vòng tiếp theo

1. Tạo Supabase dev project và Gemini API, bật billing/budget phù hợp; đặt secrets trong file môi trường local, không gửi key trong chat.
2. Giải phóng thêm dung lượng ổ đĩa trước khi build lại Android; sau đó chạy `flutter build apk --debug --dart-define=DEMO_MODE=true` với JDK Android tương thích. Không dùng cờ bỏ qua kiểm tra tương thích để che lỗi.
3. Mở emulator hoặc kết nối Android có bật USB debugging và xác nhận `adb devices` nhận thiết bị. Lần kiểm tra trước chưa có thiết bị khả dụng.
4. Sau khi có môi trường, hoàn thiện lần lượt giai đoạn 3–7 rồi thực hiện UAT-01..09; kiểm tra phiên thật, âm thanh, lưu/xóa dữ liệu, độ trễ và chi phí trước khi bật luồng học production.

Không có bằng chứng ứng dụng chịu được mọi lỗi hay đã mượt trên thiết bị. Bản bàn giao là nền tảng local đã kiểm tra cùng phần UI demo, chưa phải sản phẩm mobile hoàn chỉnh theo master plan.
