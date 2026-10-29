# Gemini Live — hội thoại giọng nói trên web và mobile

## Dùng ngay
1. Mở http://localhost:3000 hoặc chạy app Android/iOS, rồi đăng nhập.
2. Trong Trang chủ / Luyện tập, chọn **Nói chuyện trực tiếp với AI**.
3. Chọn giọng (mặc định Aoede), bấm **Bắt đầu nói chuyện**, cho phép micro.
4. Nói tiếng Anh bình thường. AI nhận audio liên tục và trả audio trực tiếp, có phụ đề, phát theo hàng đợi và ngắt phát khi server báo người dùng ngắt lời.
5. Tắt/bật micro hoặc Kết thúc. Chuyển tab/ẩn app/rời màn hình/đổi tài khoản sẽ đóng micro và kết nối.

Trên Android/iOS, app mở micro native và truyền PCM trực tiếp qua WebSocket; Android dùng chế độ giao tiếp thoại, loa ngoài và echo cancellation khi thiết bị hỗ trợ; iOS ưu tiên loa ngoài và cho phép route Bluetooth. Tai nghe được khuyến nghị để giảm vọng. App dừng cuộc gọi khi chuyển nền. Chất lượng loa, micro Bluetooth và xử lý âm thanh trên từng thiết bị cần được kiểm tra thực tế trước khi phát hành rộng.
Android dùng AudioRecord thu mono PCM16 16 kHz và AudioTrack phát PCM16 24 kHz; quyền micro được yêu cầu trước khi cấp ticket. Khi có hỗ trợ, app bật echo cancellation/noise suppression, ưu tiên route giao tiếp thoại và giải phóng audio focus khi kết thúc. iOS dùng recorder và PCM player native qua plugin Flutter. Nên dùng tai nghe để giảm vọng. Chuyển app xuống nền sẽ dừng cuộc gọi.

## Cấu hình máy chủ
Trong `config/backend.private.env` (đã gitignore, mode 600):

```dotenv
GEMINI_API_KEY=DIEN_KEY_GOOGLE_AI_STUDIO_TAI_DAY
GEMINI_MODEL=gemini-2.5-flash
GEMINI_LIVE_MODEL=gemini-3.8-live
```

Key ở backend, không dán vào Flutter, mobile.public.json hoặc chat. Khởi động lại backend sau khi đổi key. Model cần có quyền truy cập trên Google project; API usage/quota/billing riêng với thuê bao Gemini chat. Backend không giả câu trả lời khi upstream lỗi.

## Luồng và hạn mức
- Supabase JWT bảo vệ `/api/v1/ai/status` và `POST /api/v1/ai/live-token`.
- Backend cấp ephemeral token một lần, khởi tạo trong 60 giây, hết hạn sau 5 phút. REST dùng `bidiGenerateContentSetup`, không phải tên SDK `liveConnectConstraints`; không có fieldMask nên khóa toàn bộ setup.
- Web nối WebSocket constrained v1beta; app mobile dùng cùng token ngắn hạn và WebSocket. Chỉ gửi audio sau `setupComplete`; không gửi API key lâu dài xuống client.
- Android dùng AudioRecord thu mono PCM16 16kHz, AudioTrack phát PCM 24kHz theo hàng đợi có giới hạn. Có xử lý quyền micro, echo cancellation/noise suppression theo thiết bị, ngắt phát khi người dùng ngắt lời và nhả micro/audio focus khi dừng. Mute chỉ tắt đầu vào micro, không tắt phản hồi của Tom.
- Trên web, AudioWorklet thu mono PCM16 little endian ở sample rate thực của AudioContext (provider resample); audio ra PCM 24kHz được phát qua WebAudio. Không dùng giọng đọc hệ điều hành trong cuộc gọi Live.
- iOS thu mono PCM16 16 kHz và phát PCM16 24 kHz bằng recorder/PCM player native qua plugin Flutter, với audio session `playAndRecord` và các tùy chọn route Bluetooth/loa ngoài.
- PostgreSQL advisory transaction lock và ledger `live_voice_access` giới hạn theo user/ngày UTC. Mỗi token cấp thành công đặt trước 300 giây, mặc định 15 phút gọi/ngày (3 phiên), cấu hình bằng `DAILY_VOICE_MINUTES` trong file backend local. Máy backend local đã được cấu hình 60 phút/ngày theo yêu cầu người dùng; môi trường khác giữ mặc định 15 phút. Dừng sớm/lỗi sau khi đã cấp token vẫn tính phiên; không tự hoàn hạn mức hoặc tự nối lại có thể làm phát sinh phí. Hạn mức thoại này riêng với lượt chat hiện tại.
- Không lưu audio/token vào database. Phụ đề chỉ lưu khi người dùng bật cá nhân hóa và đồng ý ghi nhớ trong tab Tom; xem CA_NHAN_HOA_TOM.md. Bản lưu tối đa 8000 ký tự/phiên và 30 ngày. Khi chưa đồng ý, phụ đề chỉ ở bộ nhớ màn hình. Audio được gửi trực tiếp đến Google; không có tuyên bố Google không lưu/xử lý dữ liệu theo chính sách của họ.
- Tự dừng khi chuyển nền, handshake timeout, socket đóng hoặc token hết hạn. Web transport còn chặn khi WebSocket send backlog lớn. Không tạo số độ trễ hay điểm phát âm giả.

## Bằng chứng kiểm tra và giới hạn
- Test Java mô phỏng HTTP kiểm tra token, khóa setup, thời hạn, không lộ key, upstream 403/429, payload lỗi; kiểm tra hết quota và không ghi quota khi provider thất bại.
- Test Node mô phỏng AudioContext/WebSocket kiểm tra PCM little endian, handshake, phụ đề, ngắt playback, mute, từ chối micro, timeout và backpressure.
- Các test Flutter đã ghi nhận kiểm tra route cần đăng nhập, nút gọi không tự thu micro, trạng thái thiếu backend và layout 320dp/chữ 200%; không bao gồm nghiệm thu micro/loa native trên thiết bị thật.
- Đã chạy opt-in `LiveProviderSmokeTest` bằng key thật: nhận phản hồi chat và PCM audio cùng phụ đề từ Live bằng đầu vào văn bản tổng hợp. Đây là kiểm thử provider, không thay cho cuộc gọi người dùng qua micro/loa trình duyệt.
- Cần kiểm tra micro, chất lượng giọng/độ trễ nghe thực tế, ngắt lời, route loa/tai nghe Bluetooth, nhiều mẫu Android/iPhone, Safari và mạng yếu. Kết quả build web cũ không xác nhận build hoặc chất lượng mobile.
- Không có lưu tiến độ/chấm điểm từ cuộc gọi Live trong phiên bản này. Guided/coach/đánh giá không nằm trong luồng Live.

Tài liệu chính thức:
- https://ai.google.dev/gemini-api/docs/live-api/ephemeral-tokens
- https://ai.google.dev/api/live
- https://ai.google.dev/gemini-api/docs/models/gemini-3.8-live
- Schema REST dùng để đối chiếu: https://generativelanguage.googleapis.com/$discovery/rest?version=v1beta

## Kết quả chạy ngày 23/10/2026
- Flutter: 178 kiểm thử đạt, analyze không có vấn đề.
- Backend verify: 70 kiểm thử được phát hiện, 65 đạt, 5 opt-in bỏ qua.
- Provider smoke chạy riêng: 1/1 đạt bằng key thật; phản hồi chat, 115200 byte PCM Live và phụ đề 36 ký tự. Không thu micro.
- Node transport: 6/6 đạt. Web release build thành công.
- Supabase: 8 migration, 1 tài khoản; health UP. Endpoint Live không có đăng nhập trả 401; hai asset JS/AudioWorklet trả 200.
- Kết quả trên không kiểm tra transport mobile hoặc chất lượng nghe qua micro/loa thiết bị thật.

## Android — kiểm thử ngày 29/10/2026
- Android chấp nhận `setupComplete: {}` của Gemini; không so sánh riêng với boolean `true`.
- Native nhận PCM và phụ đề từ provider, phát âm thanh gốc; không đọc phụ đề qua TTS.
- Máy ảo cần bật host microphone input (Extended Controls → Microphone). Có thể kiểm tra bằng `adb emu avd hostmicon`; điện thoại thật dùng micro của thiết bị.
- Chạy kiểm thử transport: `flutter test test/native_live_audio_test.dart test/live_voice_screen_test.dart`.
- Kết quả nghiệm thu cụ thể và giới hạn: [Android Live QA](qa/ANDROID_LIVE_2026_10_29.md).
- Báo cáo Android ghi nhận kết quả trên máy ảo Pixel 7; chưa chứng minh chất lượng trên mọi điện thoại, tai nghe Bluetooth, iOS hay mạng yếu.
