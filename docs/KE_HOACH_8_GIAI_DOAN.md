# Kế hoạch phát triển English Speaking AI trong 8 giai đoạn

Nguồn yêu cầu là ESP-PLAN-001, bản bổ sung v1.1 trong Google Docs đã được sao chép vào PROJECT_MASTER_PLAN.md. Phụ lục A–E được ưu tiên khi khác chương 1–12. Kế hoạch kỹ thuật giao cho agent nằm trong EXECUTION_PLAN_8_STAGES.md; tài liệu này trình bày kế hoạch bằng tiếng Việt để theo dõi và nghiệm thu.

Khung dự kiến ngày 21/10/2026 là 16:13–20:13, tổng 240 phút. Đây là thời lượng phân bổ công việc. Thực tế chưa hoàn thành đủ tám giai đoạn trong thời gian này. Không được chuyển các mục chưa kiểm chứng thành trạng thái hoàn thành.

## Quyết định kỹ thuật

- Mobile giữ Flutter/Dart, Riverpod, GoRouter và năm tab Home, Practice, Progress, Coach, Profile; không viết lại mobile bằng Java.
- Backend chuyển sang Java 27 theo yêu cầu. Đã cài riêng OpenJDK27.0.1 và kiểm tra SHA256. Spring Boot3.4.2 không đọc được class Java27; đã chuyển sang4.2.0-M2, build/test trên Java27 thành công. Đây là bản milestone; mức sẵn sàng production vẫn cần đánh giá riêng.
- Giữ Supabase Auth, PostgreSQL/Flyway, private Storage và Gemini qua backend adapter. Model và khóa provider đặt ở môi trường backend; mobile chỉ dùng khóa publishable/anon hợp lệ.
- Tạm giữ thư mục Flutter hiện có để không phá đường dẫn IDE, thêm backend/, docs/, infra/. Thay đổi này và thay đổi Java/framework có ADR riêng.
- Chế độ demo phải được bật rõ bằng DEMO_MODE và hiển thị nhãn. Khi thiếu cấu hình, chế độ thật phải thông báo chưa sẵn sàng; dữ liệu giả không được dùng để nghiệm thu chức năng thật.

## Phân công

Agent chính đọc plan, quản lý hợp đồng và quyết định kiến trúc, xây lớp kết nối, sửa lỗi tích hợp, kiểm tra runtime và tổng hợp bằng chứng. Agent GPT-6 Sol điều phối AI trong Antigravity IDE, giao phạm vi file và yêu cầu test. Agent GPT-5.6 Sol kiểm thử độc lập, ghi lỗi và kiểm chứng kết quả.

Các agent làm trong cùng workspace, tránh sửa trùng file. Không reset thay đổi có sẵn trong pubspec.lock; không commit khóa, không tự deploy hay phát hành. Khi Mac bị khóa, điều khiển IDE bằng giao diện bị chặn và cần người dùng mở khóa.

## Giai đoạn 1 Nền tảng và khả năng chạy lại

**20 phút, dự kiến 16:13–16:33.** Mã việc ESP-S1-01..05, tương ứng roadmap v0.1.

Đọc và lưu đầy đủ plan, xác định phần phụ lục thay thế, ghi baseline Git/toolchain/test. Dựng backend Java27, health API, mã lỗi chuẩn và requestId. Viết hợp đồng OpenAPI trước client; quản lý schema bằng Flyway. Chuẩn bị cấu hình mẫu, PostgreSQL local, Maven wrapper, CI và hướng dẫn chạy lại. Đối chiếu phiên bản framework bằng build và kiểm thử context thực tế.

Nghiệm thu khi health trả đúng schema, migration chạy được trên database mới, mã nguồn biên dịch đúng class Java27 và có kết quả test cụ thể. Ghi rõ phần chưa có môi trường cloud; không coi biên dịch thành công là bằng chứng runtime hoạt động.

## Giai đoạn 2 Đăng nhập bền vững và hệ thống giao diện

**35 phút, dự kiến 16:33–17:08.** ESP-S2-01..06, AUTH-01..05, PROFILE-01..02, các màn 01–05 và20.

Khởi tạo Supabase trước luồng xác thực, chờ restore/refresh, xử lý signedOut, tokenRefreshed, userDeleted và lỗi stream. Đăng ký, đăng nhập, quên mật khẩu phải gọi dịch vụ thật khi cấu hình đủ. Router được giữ ổn định, chặn deep link khi chưa xác minh danh tính; quyền quản trị chỉ lấy từ nguồn server kiểm soát và vẫn được backend xác minh. Đăng xuất hủy request, dừng media, dọn dữ liệu theo tài khoản và ngăn kết quả cũ ghi đè phiên mới.

Backend xác minh chữ ký JWKS, issuer, audience, hạn token và subject; /me chỉ thao tác hồ sơ của chủ token. Bổ sung hồ sơ, thiết lập và RLS qua migration. Đồng bộ DTO camelCase của API với model mobile thay vì dùng nhầm định dạng lưu local.

Giao diện dùng màu indigo/teal, nền nhẹ, lưới8pt, card16–20dp, chữ dễ đọc, nút ít nhất48dp và giảm hiệu ứng thừa. Sửa các lỗi Material/ListTile, safe area, bàn phím, semantics và giảm chuyển động. Nghiệm thu bằng test giữ phiên, test quyền, kiểm tra router và ảnh thực tế; phải ghi riêng các ca Supabase thật chưa chạy.

## Giai đoạn 3 Trình độ và danh mục học

**25 phút, dự kiến 17:08–17:33.** ESP-S3-01..05, TOPIC-01, SCENARIO-01, placement, màn05–09.

Định nghĩa mục tiêu A0–C2, có lựa chọn thủ công và bỏ qua placement; A0 là nhãn nội bộ, kết quả không phải chứng nhận CEFR. Seed tối thiểu12 tình huống thuộc bốn nhóm giới thiệu, đời sống, du lịch, công việc. Metadata có UUID, vai trò, mục tiêu, trình độ và thời lượng.

Triển khai API chủ đề, danh sách và chi tiết với lọc/phân trang có giới hạn. Flutter đọc metadata từ API, xử lý loading/empty/error/retry và dùng ID backend. Tách nội dung công khai đang hoạt động khỏi dữ liệu cá nhân cần JWT. Nghiệm thu bằng kiểm đếm seed từ migration mới, test lọc/phân trang, nội dung đại diện các mức và hành trình Home đến bắt đầu luyện.

## Giai đoạn 4 Chat AI lưu bền vững và phát giọng nói

**40 phút, dự kiến 17:33–18:13.** ESP-S4-01..07, MODE-01, CHAT-01..05, OPS-01..03, màn10.

Thiết kế trước schema/API cho session, message và usage. Backend tạo, đọc, gửi lượt và kết thúc phiên theo subject đã xác minh; lưu thứ tự và khóa idempotency bằng ràng buộc database. Không tạo trùng hay tính phí hai lần khi gửi lại hoặc gửi đồng thời. Có quota, giới hạn context, độ dài đầu vào và timeout.

Gemini adapter dùng model từ môi trường, xác thực ai_turn_v1, retry giới hạn khi JSON sai và trả lỗi có thể phục hồi khi provider hỏng. Flutter sử dụng lớp kết nối có lỗi định kiểu, thinking state, retry giữ nguyên khóa và lịch sử sau khởi động lại. TTS/player thật hỗ trợ phát lại, dừng và0.75x/1x/1.25x. Nghiệm thu bằng câu gõ thành phản hồi nghe được, lưu đúng một lần và test IDOR, lỗi provider, quota, phiên đã đóng.

## Giai đoạn 5 Nói theo lượt và quyền riêng tư audio

**30 phút, dự kiến 18:13–18:43.** ESP-S5-01..06, MODE-02, VOICE-01..04, màn11.

Thu âm thật có giải thích quyền, start/stop và dọn tài nguyên khi rời màn hình, logout hoặc ứng dụng bị gián đoạn. Thực hiện state machine guided speaking, STT thành transcript/timing rồi AI/TTS; giữ bản nhận dạng gốc riêng với chú thích sửa của người dùng. Khi bị từ chối mic vẫn có đường dùng text.

Backend kiểm MIME, magic header, kích thước, thời lượng và file rỗng. Mặc định không giữ audio; nếu lưu cần consent đã xác nhận, private bucket, signed URL có TTL và cơ chế xóa. Nghiệm thu bằng thiết bị thật, kiểm chứng không lưu khi không consent, test file hỏng/oversize, provider lỗi và gửi lại không trùng.

## Giai đoạn 6 Hội thoại realtime và phục hồi

**25 phút, dự kiến 18:43–19:08.** ESP-S6-01..05, MODE-03, phụ lụcC, màn12.

Đo thử transport trước khi chọn kiến trúc. Backend cấp quyền phiên ngắn hạn, giới hạn phạm vi và chi phí; không đưa khóa Gemini dài hạn vào mobile. Thực hiện luồng thu/phát thật, VAD, captions, ngắt lời khi hỗ trợ, mute/end, reconnect và chuyển sang guided khi cần.

Không chờ chấm điểm xong mới kết thúc cuộc gọi. Lưu checkpoint và sự kiện có ý nghĩa thay vì mọi packet. Nghiệm thu cần kết quả30 cuộc gọi theo ma trận Wi-Fi/mobile, đo first audio latency, phục hồi, lỗi và chi phí. Mục tiêu95% khởi động thành công và p95 dưới2.5giây phải được đo, không tự coi là đạt khi chưa có provider/thiết bị.

## Giai đoạn 7 Phản hồi có bằng chứng và coach cá nhân

**35 phút, dự kiến 19:08–19:43.** ESP-S7-01..07, SCORE, FEEDBACK, COACH, PROGRESS, NOTIFY, màn13–20.

Hoàn tất phiên kích hoạt đánh giá idempotent; lưu rubric/model/prompt version, độ tin cậy, mức đầy đủ đầu vào và nguồn transcript. Bốn trục điểm0–9 cần bằng chứng. Phát âm là N/A khi thiếu acoustic scorer; điểm tổng chỉ xuất hiện khi cả bốn trục hợp lệ. Không quảng bá là điểm IELTS chính thức.

Coach ưu tiên lỗi bằng recurrence × impact × recency × confidence, gắn drill và kế hoạch tuần với các phiên thật. Theo dõi lỗi lặp qua ít nhất ba phiên, lịch nhắc lại1/3/7ngày, từ vựng và quyền tắt/xóa memory. Thống kê lấy từ phiên hoàn tất, lưu UTC và hiển thị ngày theo Asia/Ho_Chi_Minh; điểm thiếu dữ liệu không vẽ thành0. Nghiệm thu bằng dữ liệu có nguồn, kiểm tra xóa/quyền riêng tư và đo JSON hợp lệ trên100fixtures; hiệu chuẩn với người đánh giá vẫn cần riêng.

## Giai đoạn 8 Kiểm thử tối ưu và bàn giao

**30 phút, dự kiến 19:43–20:13.** ESP-S8-01..07, UAT-01..09, roadmap v0.9–v1.0.

Đóng tính năng, kiểm tra độc lập và sửa P0/P1. Chạy analyze/test Flutter, verify Java27, migration từ database trống, build Android và kiểm UI320dp/cỡ chữ200%. Test token hết hạn, IDOR, gửi đồng thời, mất mạng, AI trả sai, quota, mic bị từ chối và cleanup.

Đo p50/p95 API thường, mục tiêu p95 dưới800ms; tách thời gian provider. Profile/release Flutter mới đủ cơ sở đánh giá độ mượt, không suy từ test debug hay animation. Bàn giao mã nguồn, cấu hình mẫu, API/schema, lệnh chạy, test evidence, lỗi còn mở và hướng dẫn vận hành. Chỉ gọi release candidate khi các gate thực sự đạt; không tag v1.0 khi còn blocker.

## Trạng thái bàn giao

Báo cáo cuối FINAL_STATUS.md ghi rõ trạng thái thực tế và kết quả đã chạy. Hiện có nền tảng backend Java27, auth/profile/catalog local, sửa giao diện và lớp kết nối; chưa có đủ các luồng AI/voice/realtime/coach thực tế. Các kết quả mock/unit không thay thế nghiệm thu cloud và thiết bị.

Chưa có Supabase/Gemini dev project. Android chưa được adb nhận diện ở lần kiểm tra cuối. Người dùng cần tự cấu hình dịch vụ/billing/budget, đặt secrets cục bộ và chuẩn bị thiết bị cho vòng tích hợp tiếp theo; không gửi key trong chat. Quota Codex được theo dõi: đã tăng từ2% lên80% trước khi cửa sổ đặt lại; sau đặt lại đã còn khả năng cho kiểm tra cuối. Không thể coi thời gian chờ mở khóa hay IDE đứng chờ là thời gian đã triển khai đủ tính năng.
