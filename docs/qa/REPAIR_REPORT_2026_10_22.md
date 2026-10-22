# Sửa lỗi và tích hợp tiếp — 22/10/2026

**Kết luận:** đã sửa và kiểm tra các lỗi dưới đây; chưa hoàn thành/nghiệm thu toàn bộ baseline ESP-PLAN-001. Không cam kết app không còn mọi lỗi giao diện hoặc đã sẵn sàng production.

## Những lỗi đã xử lý

- Bố cục có lỗi ở 17/20 màn khi thử 320 dp / 200%: bổ sung `AdaptiveRow`, giữ cỡ chữ người dùng, cho controls tự xuống hàng, tăng không gian carousel/chart, sửa trailing của ListTile, dropdown, filter và trang drill cuộn được.
- Kiểm tra lại với font thật đóng gói (không dựa vào font Ahem mặc định của widget test), ba viewport 320×800/200%, 390×844/100%, 768×1024/130%. Bổ sung kiểm tra 5-tab navigation và các màn tài khoản thật.
- Loại bỏ tải Google Fonts lúc runtime: đóng gói Plus Jakarta Sans normal/italic và giấy phép OFL. Dọn deprecation/style để `flutter analyze` không còn issues.
- Chat mặc định dùng `RemoteChatRepository`; mock chỉ được chọn rõ trong demo. Mã phiên lưu theo account; khôi phục transcript, gửi lại bằng cùng idempotency key, không thêm bubble user trùng, chặn double tap và bỏ kết quả sau dispose/logout.
- TTS thực qua `flutter_tts`, dùng đúng reply text; đổi tốc độ, dừng/replay và cleanup khi rời trang/background. Chưa chứng minh âm thanh trên thiết bị thật.
- Trang chủ, luyện tập, tiến độ, lịch sử và hồ sơ cho tài khoản thật đọc API. Sửa lưu tên/level/mục tiêu vào backend và trạng thái onboarding theo backend. Không dùng streak/band/tên demo làm dữ liệu thật.
- Danh mục/chi tiết có thể xem công khai; bắt đầu tình huống yêu cầu đăng nhập và tạo chat với scenario/level tương ứng. Guided/realtime chưa được mở ở chế độ thật.
- Đăng ký có user nhưng chưa có session (chờ xác nhận email) không được coi là đã đăng nhập. Giữ nguyên mật khẩu khi nhập, không trim làm thay đổi credential. Lỗi auth stream hiển thị thông báo an toàn.
- `ConversationAiService` gọi Gemini REST thật với JSON schema, giới hạn context/output/timeout, typed errors và không thay provider lỗi bằng câu trả lời giả. Key/model hiện chưa có nên chưa chạy provider thật.
- Bỏ điểm hardcoded, acoustic scorer giả và số liệu progress tối thiểu giả. Không có bằng chứng thì band/confidence/provenance là null/empty và feedback unavailable. V7 vô hiệu điểm giả cũ, giữ các bản ghi.
- Idempotency scope theo user + operation + resource, khóa transaction PostgreSQL để bảo vệ retry/quota/sequence, unique sequence index. Không nuốt lỗi lưu cache và không tạo mutation mới khi cache không đọc được.
- Yêu cầu Idempotency-Key rõ ràng; thiếu header, JSON/UUID/query sai trả 400 an toàn. Kiểm tra độ dài message và goal.
- Sửa thiếu `spring-boot-starter-flyway`: khai báo Flyway core trước đây không làm Spring Boot 4 tự chạy migration khi khởi động. Đã khởi tạo schema private `english_app`, migration V1–V7, giới hạn pool dev và thu hồi grant Data API trên bảng backend.
- Trình chạy mới tách public config của Flutter khỏi secret Java, build source mới, chờ health thực, bind web local và không tự coi tiến trình cũ là bản mới. Biến runtime không bị đưa vào Maven test profile.
- Android HTTP dev chỉ cho loopback/emulator trong debug manifest; thêm khai báo truy vấn TTS engine.

## Bằng chứng kiểm thử

| Kiểm tra | Kết quả |
|---|---|
| Flutter analyze strict | `flutter analyze --no-pub`: No issues found |
| Flutter regression | 173 bài đạt ở lượt cuối, bao gồm demo fixtures; không đồng nghĩa mọi luồng dịch vụ thật đã đạt |
| UI matrix | 60 ca cho 20 màn × 3 viewport/text scales, thêm màn tài khoản thật và thanh điều hướng |
| Backend Java 27 | 61 bài được phát hiện: 57 đạt, 4 ca PostgreSQL opt-in được bỏ qua trong verify thường |
| PostgreSQL thật, chạy riêng | 4/4 đạt trên schema QA tạm; đã dọn schema: retry đồng thời, scope giữa phiên, quota đồng thời, tạo phiên đồng thời |
| Supabase dev | 7 migration có version; 4 topics, 17 scenarios; 0 grant bảng cho anon/authenticated trong schema backend |
| API runtime | health 200, topics 200/4, scenarios 200/17, C2 200/1, /me không token 401 |
| Web | build JS thành công; khởi động qua script thật, xem catalog/filter C2/detail và chuyển sang đăng nhập bằng trình duyệt |
| Android debug | build APK thành công, cài/mở trên Pixel 7 Pro emulator; tải catalog từ API, kiểm tra 320 dp/200% sau khi khởi động lại activity và cuộn tới các nút chính. Không có fatal/overflow/unhandled exception trong log của app ở ca smoke; chưa kiểm tra mic/audio. Xem repair-build-metadata.json cho hash |

Lần đọc Supabase gần nhất có **0 Auth users**; chưa có bằng chứng hai tài khoản thật đăng nhập và truy cập chéo trên cloud. Các test JWT/IDOR tự động dùng fixture ký, không phải mật khẩu/JWT của người dùng thật. GEMINI_API_KEY/GEMINI_MODEL vẫn trống ở lần kiểm tra này.

Ảnh trong `ui/` có hai loại: `*-320-200.png`, `*-390-100.png` là widget fixtures/demo có font thật; `web-real-scenario-detail.png` là ảnh runtime catalog thật. Không dùng ảnh minh họa làm bằng chứng AI/audio hoạt động.

## Trạng thái so với baseline

| Phần | Đã làm | Còn thiếu để nghiệm thu |
|---|---|---|
| Nền tảng/Auth/Catalog | Supabase schema, API runtime, auth adapters, sửa UI và catalog thật | Hai tài khoản cloud, reset callback/email, role tối thiểu và vận hành production |
| Chat | Client/server persistence, provider HTTP, retry/quota/concurrency, TTS adapter | Provider thật, usage/cost accounting và timeout reconciliation, transcript pagination, ma trận 20 phiên/TTS thiết bị |
| Guided/STT/privacy audio | Giữ UI demo và chặn thật khi chưa tích hợp | Recorder/STT/API audio, permissions/lifecycle, consent/storage/cleanup và UAT-03/08 |
| Realtime | Giữ UI demo và chặn thật khi chưa tích hợp | Provider/token/audio transport, reconnect/resume, 30 cuộc gọi và UAT-04 |
| Feedback/Coach/Progress | Không bịa band/acoustic evidence; thống kê completed-session và lịch sử thật | Scoring pipeline/calibration, nguồn evidence, coach/memory/drill/plan/vocabulary/privacy, breakdown/period và history pagination đầy đủ |
| QA/Release | Unit/integration/concurrency/UI checks, web build và debug APK | Full thiết bị/audio E2E, perf nghiệp vụ, stable framework, HTTPS hosting, backup/restore/CI, release signing và pilot |

Không đánh dấu Gate 4–8 Accepted, không tag/release v1.0 và không gọi debug APK là bản production.

## Chạy tiếp

- Web/backend: `./start_app.sh`; dùng config public/private đã điền. Nếu preview đang chạy, dừng tiến trình launcher trước khi chạy lại.
- Android emulator: backend trên Mac cần chạy; debug config dùng `10.0.2.2`.
- Điền Gemini key/model vào file private trên máy, khởi động lại backend; không nhúng key vào Flutter/APK và không gửi key vào chat.
- Tạo/xác nhận hai Auth users trong đúng Supabase project hoặc đăng ký trong app rồi kiểm tra email theo cấu hình Auth.
- Làm tiếp đúng kế hoạch giai đoạn 4–8; không mở các luồng mock như tính năng thật để vượt gate.

## Giới hạn phép thử emulator

Emulator chạy read-only, headless và tắt audio; đã khôi phục cỡ chữ/độ phân giải và tắt instance do lượt QA tạo. Thay đổi độ phân giải bằng `wm size` khi activity đang chạy tạo một frame bị crop; phép thử 320 dp/200% chính thức được chụp sau khi khởi động lại activity. Không coi đây là bằng chứng mọi thay đổi cấu hình động/rotation đều đã đạt. `android-welcome-actions-320-200.png` cho thấy các nút chính truy cập được bằng cuộn; `android-catalog-320-200.png` là catalog từ API thật.

Build web JS thành công. `flutter_tts` còn cảnh báo compatibility trong bước Wasm dry-run của toolchain; chưa nghiệm thu bản WebAssembly. Gradle/AGP/Kotlin hiện build được nhưng Flutter đã cảnh báo cần nâng trong các bản tương lai.
