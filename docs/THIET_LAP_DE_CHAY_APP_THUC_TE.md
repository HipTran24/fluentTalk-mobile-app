# Thiết lập để chạy FluentTalk như một ứng dụng thực tế

Ngày đối chiếu mã nguồn: 22/10/2026. Tài liệu này phản ánh mã đang có trong workspace, không coi báo cáo kiểm thử ngày 21/10 là chứng nhận cho những thay đổi sau đó.

**Cần cả cấu hình dịch vụ và hoàn thiện mã nguồn. Chỉ thêm API key, chạy start_app.sh hoặc mở được giao diện chưa đủ để gọi đây là app hoàn chỉnh.**

## 1. Những gì hiện còn thiếu trong mã

| Phần | Bằng chứng hiện tại | Việc phải hoàn thiện |
|---|---|---|
| Chat Flutter | chat_controller.dart trả MockChatRepository | Repository HTTP thật, phiên lưu bền vững, retry dùng cùng idempotency key, xử lý token và lịch sử |
| AI backend | ConversationAiService sinh câu bằng if/else; khai báo AppProperties nhưng chưa gọi provider | Gemini adapter thật, schema ai_turn_v1, timeout, quota, usage/cost và xử lý đầu ra sai |
| Chấm điểm | ConversationAiService tính điểm từ số message, đặt tên scorer acoustic dù không có phân tích âm thanh | Loại bỏ điểm/bằng chứng mô phỏng khỏi chế độ thật; pronunciation N/A khi thiếu acoustic scorer; đánh giá phải có nguồn phiên, confidence và version |
| Guided/realtime | Controller còn dùng MockGuidedSpeakingRepository/MockRealtimeCallRepository và đường dẫn mock_audio | Thu/phát thật, STT/TTS, Live transport, permissions, reconnect, hủy tài nguyên |
| Coach/feedback/profile | Nhiều controller vẫn dùng Mock...Repository | API thật, dữ liệu theo tài khoản và lineage; thao tác xóa/cập nhật phải lưu thực tế |
| Chế độ chạy | main.dart hiện tự bật demo khi thiếu cấu hình Supabase; router vẫn chặn các màn học thật chưa tích hợp | Bỏ tự động giả lập ở chế độ thật; chỉ bật demo khi được chọn rõ; mở từng luồng sau khi có adapter và kiểm tra đạt |
| Khôi phục mật khẩu | Có resetPasswordForEmail nhưng chưa có mobile callback hoàn chỉnh trong manifest | Chọn callback URL, thêm deep link và màn đặt lại mật khẩu, cấu hình Supabase rồi test trên thiết bị |
| Android | Chưa thấy APK/AAB đầu ra ở lần đối chiếu này | Build lại, cài và kiểm tra trên Android; ký release riêng |

Đã có thêm mã session/controller/entity và migration V5; sự tồn tại của các file này chưa chứng minh AI, quota, idempotency đồng thời hay luồng mobile đã vận hành đúng.

## 2. Supabase: tài khoản và dữ liệu

Bạn thực hiện trên Dashboard:

1. Tạo một project **dev**; lưu database password trong trình quản lý bí mật/file local. Tách project production trước phát hành.
2. Bật đăng nhập Email/Password. Chốt có xác nhận email hay không; dùng SMTP và domain gửi thư phù hợp trước khi phục vụ người dùng thật.
3. Lấy **Project URL** và **publishable key** dành cho mobile. Mã hiện đặt tên biến là SUPABASE_ANON_KEY; tên cũ này không có nghĩa phải dùng service_role.
4. Lấy kết nối PostgreSQL từ mục Connect. Với backend chạy lâu dài, dùng direct connection khi mạng hỗ trợ hoặc session pooler khi cần IPv4. Dùng SSL cho kết nối cloud; copy host và username đúng từ Dashboard, không đoán tên pooler.
5. Chọn khóa ký JWT bất đối xứng mà backend hiện hỗ trợ (RSA/EC) và kiểm tra JWKS công khai trả được khóa. Backend hiện không có verifier HS256 cho legacy shared secret.
6. Cấu hình Site URL và danh sách redirect URL sau khi callback mobile/web được chốt trong mã. Dashboard và manifest/callback handler phải khớp nhau.
7. Chuẩn bị hai tài khoản dev để thử truy cập chéo dữ liệu.

Phía mã/hạ tầng cần làm tiếp: chạy và validate các migration trên database dev mới; kiểm tra grant/RLS/ownership với role thật. Không sửa V1–V5 đã được áp dụng; thêm migration mới cho thay đổi tiếp theo. Kiểm tra baseline-on-migrate trước khi áp dụng vào database Supabase có schema sẵn, tránh bỏ qua migration khởi tạo.

Khi triển khai lưu recording, tạo bucket **private** theo tên được chốt trong adapter. Không cần mua hoặc mở bucket public để thử demo; audio retention phải mặc định tắt. Cần policy theo chủ sở hữu, signed URL có TTL và tác vụ xóa trước khi bật lưu audio.

Tài liệu chính thức: [API keys](https://supabase.com/docs/guides/getting-started/api-keys), [kết nối PostgreSQL](https://supabase.com/docs/guides/database/connecting-to-postgres), [JWT/JWKS](https://supabase.com/docs/guides/auth/jwts), [redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls).

## 3. Gemini và dịch vụ âm thanh

Bạn cần một Google project/AI Studio project có Gemini API key, model được tài khoản hỗ trợ và quota đủ cho các bài thử dự kiến. Cấu hình billing khi tính năng/quota đã chọn yêu cầu; đặt budget alerts và theo dõi usage. Budget alert không thay thế giới hạn chi phí trong app.

Backend cần GEMINI_API_KEY và GEMINI_MODEL. **Key chỉ đặt ở backend**, không truyền bằng Dart define hay nhúng vào APK/web. Adapter hiện chưa gọi Gemini, nên điền hai biến này chưa làm chat thông minh hoạt động.

Giai đoạn âm thanh cần chốt thêm STT và TTS: có thể dùng khả năng thiết bị hoặc provider qua adapter, nhưng phải đo độ chính xác/độ trễ và kiểm tra giấy phép/chi phí trước lựa chọn. Không mặc định rằng một key text đã đủ cho toàn bộ speech và Live.

Với realtime, xác minh model, protocol, audio format và quyền truy cập tại thời điểm làm spike. Nếu kết nối trực tiếp từ mobile, backend cấp token ngắn hạn có giới hạn; không đưa key Gemini dài hạn ra app. Nếu chưa đạt điều kiện, giữ realtime unavailable/beta và cung cấp guided fallback.

Tài liệu: [Gemini API keys](https://ai.google.dev/gemini-api/docs/api-key), [billing](https://ai.google.dev/gemini-api/docs/billing), [Live ephemeral tokens](https://ai.google.dev/gemini-api/docs/live-api/ephemeral-tokens).

## 4. Biến cấu hình phải đặt ở đâu

| Biến | Nơi dùng | Ghi chú |
|---|---|---|
| API_BASE_URL | Flutter, public | URL kết thúc bằng /api/v1; HTTPS khi chạy ngoài máy dev |
| SUPABASE_URL | Flutter và backend | Project URL cùng một môi trường |
| SUPABASE_ANON_KEY | Flutter, public | Publishable/anon key của project; không phải secret/service_role |
| DEMO_MODE | Flutter | false cho luồng thật; hiện cần sửa auto-demo trong main.dart để thiếu cấu hình không bị che |
| ALLOW_INSECURE_LOCALHOST | Flutter dev | Chỉ cho loopback/emulator; không bật như cách thay TLS production |
| SPRING_DATASOURCE_URL | Backend, private | JDBC PostgreSQL URL đúng host/database và SSL |
| SPRING_DATASOURCE_USERNAME | Backend, private | Theo Connect dialog; runtime role cần quyền tối thiểu |
| SPRING_DATASOURCE_PASSWORD | Backend, secret | Không dùng mật khẩu mặc định khi triển khai |
| SUPABASE_JWT_ISSUER | Backend | https://PROJECT_REF.supabase.co/auth/v1 |
| SUPABASE_JWKS_URL | Backend | https://PROJECT_REF.supabase.co/auth/v1/.well-known/jwks.json |
| SUPABASE_JWT_AUDIENCE | Backend | authenticated nếu đúng cấu hình project |
| GEMINI_API_KEY | Backend, secret | Không gửi vào mobile |
| GEMINI_MODEL | Backend | Model thực tế được chọn và benchmark |
| SPRING_PROFILES_ACTIVE | Backend | dev cho tích hợp; prod/production chỉ sau khi kiểm tra cấu hình |
| CORS_ALLOWED_ORIGINS | Backend | Danh sách origin web cụ thể; native app không dùng CORS như trình duyệt |

File .env.example hiện chưa liệt kê đủ biến JWKS/audience/CORS/mobile; có cả tên legacy chưa được verifier sử dụng. Backend Spring và Flutter **không tự đọc file .env chỉ vì file tồn tại**. Cần truyền biến qua IDE/hosting/process environment; Flutter đọc --dart-define hoặc --dart-define-from-file. Không đưa cả file chứa secret backend vào --dart-define-from-file.

Đã thêm hai mẫu tách biệt:

- config/mobile.public.example.json: chỉ cấu hình public cho Flutter.
- config/backend.private.env.example: mẫu tên biến backend, chưa chứa secret thật.

Sao chép thành mobile.public.json và backend.private.env rồi điền local. File private là dữ liệu cấu hình, không phải shell script để chạy. Cấu hình IDE/hosting nạp các biến này vào tiến trình backend; hiện start_app.sh chưa thực hiện việc đó.

Ví dụ chạy Flutter sau khi chuẩn bị cấu hình public:

```bash
flutter run --dart-define-from-file=config/mobile.public.json
```

Nếu chạy backend trên Mac và app trên Android emulator, loopback dành cho máy host là 10.0.2.2; API dev có thể là http://10.0.2.2:8080/api/v1 với ngoại lệ localhost được bật có chủ đích. Android network security cũng phải cho phép HTTP dev ở đúng build. Với điện thoại thật, localhost là chính điện thoại: cần HTTPS backend có thể truy cập hoặc phương án adb reverse được cấu hình; mã AppConfig hiện không chấp nhận tùy ý IP LAN qua HTTP.

## 5. Chạy ngoài máy phát triển

Để app trên điện thoại hoạt động khi Mac tắt, cần deploy backend lên máy chủ/container hỗ trợ runtime Java 27, có HTTPS và truy cập được database/provider. Supabase không tự host mã Java trong repository này.

Cần chuẩn bị thêm health/readiness, biến môi trường riêng dev/staging/prod, log có requestId và masking, giám sát lỗi, rate limit/quota, backup và thử restore, migration release và phương án rollback. Hiện Spring Boot là 4.2.0-M2: test local không thay thế quyết định dùng framework ổn định tương thích Java 27 trước production.

start_app.sh hiện khởi động PostgreSQL/backend và phục vụ thư mục build/web có sẵn. Script không build frontend mới, không nạp toàn bộ secret, không chứng minh Live/AI hoạt động và không tạo Android APK. Không dùng dòng thông báo “sẵn sàng” của script làm tiêu chí nghiệm thu.

## 6. Android và phát hành

- JDK backend: Java 27. Android dùng JDK phù hợp với Gradle/AGP riêng, bản kiểm tra trước dùng JDK 21.
- Mở emulator hoặc bật USB debugging trên điện thoại; adb devices phải nhận thiết bị trước test microphone, audio focus và background.
- Thêm và kiểm tra permission microphone, xin quyền khi cần, dừng recording/player khi rời màn hình hoặc logout. INTERNET hiện có trong main manifest, nhưng microphone/callback vẫn cần triển khai.
- Build debug và cài thử trước; sau đó dùng applicationId riêng, version, keystore release và cấu hình ký để tạo APK/AAB phát hành. Không coi signing bằng debug key là release hợp lệ.
- Tại lần đọc ngày 22/10, ổ đĩa còn khoảng 14 GiB trống; chưa có APK/AAB. Lỗi build đầy đĩa trước đây chưa được xác nhận khắc phục bằng một lần build thành công.
- iOS là phần bổ sung: cần signing, provisioning và cấu hình microphone/deep link tương ứng; không cản Android-first.

## 7. Thứ tự nên chuẩn bị

1. Supabase dev + hai tài khoản test + PostgreSQL connection + public key/JWKS.
2. Gemini project/key/model/quota; đặt secret local và chỉ báo đường dẫn cấu hình, không gửi key vào chat.
3. Backend dev nhận đúng environment; Flyway/JWT/profile/catalog kiểm tra đạt.
4. Hoàn thiện chat thật và TTS, rồi guided audio, realtime, feedback/coach theo kế hoạch giai đoạn 4–8.
5. Android emulator/điện thoại, build/cài thành công, chạy UAT-01..09; sau đó mới deploy và ký release.

Điều kiện gọi là app hoàn chỉnh: ba luồng luyện tập thực sự sử dụng provider/audio, dữ liệu lưu đúng tài khoản qua lần mở app, scoring có bằng chứng, thao tác privacy có hiệu lực, không còn mock được dùng như dữ liệu thật, các gate chất lượng và Android UAT đã được kiểm chứng. Không có thiết lập đơn lẻ nào thay thế các phần lập trình này.
