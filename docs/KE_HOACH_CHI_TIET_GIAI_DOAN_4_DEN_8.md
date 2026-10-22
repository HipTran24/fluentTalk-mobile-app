# Kế hoạch chi tiết năm giai đoạn còn lại: 4–8

Ngày xuất: 22/10/2026. Nguồn: ESP-PLAN-001 v1.1, ưu tiên phụ lục A–E trong PROJECT_MASTER_PLAN.md; thay đổi của người dùng: backend Java 27, mobile Flutter, giao diện chuyên nghiệp, điều phối Antigravity bằng GPT-6 Sol và QA độc lập bằng GPT-5.6 Sol.

Tài liệu này giữ đầy đủ phạm vi baseline. Phân bổ ban đầu cho giai đoạn 4–8 là 40/30/25/35/30 phút, tổng 160 phút; đó là phân bổ trong timebox đã quá hạn, **không phải ước lượng đủ để hoàn thiện và nghiệm thu toàn bộ phần còn lại**. Không đặt lại đồng hồ để tuyên bố đạt hạn bốn giờ. Lịch thực hiện tiếp cần được chốt theo kết quả tích hợp, dịch vụ và kiểm thử thiết bị.

## Điểm xuất phát và điều kiện vào

Hiện có nền tảng Java 27, auth/profile/catalog, Flutter UI và transport. Đã có thêm mã sessions/messages và V5 trong workspace, nhưng AI backend đang sinh câu/điểm bằng logic viết sẵn; nhiều repository Flutter vẫn là mock. Không tính các phần này là AI/audio/scoring thật.

Trước khi mở chức năng học production cần hoàn tất các việc còn nợ của giai đoạn 1–3:

- Chốt lại regression Flutter sau những thay đổi mới; lần chạy catalog tập trung gần nhất còn một lỗi overflow ở320 dp / 200%. Các kết quả85 Flutter / 25 backend trước đây là bằng chứng của snapshot cũ.
- Chạy verify backend mới; migrate/validate V1–V5 trên database mới và upgrade database cũ, kiểm tra nội dung A0–C2, phân trang và giữ nguyên bản ghi cũ.
- Supabase thật: restore/refresh/logout, xác nhận email và password-reset callback; hai tài khoản thật kiểm tra quyền.
- Bỏ tự bật demo khi thiếu Supabase. Production thiếu adapter/cấu hình phải trả unavailable rõ ràng; chỉ demo khi được chọn có chủ đích.
- Đối chiếu Java 27 với framework phát hành phù hợp. Spring Boot 4.2.0-M2 hiện là milestone; không lấy test local làm chứng nhận ổn định production.
- Chuẩn bị môi trường theo THIET_LAP_DE_CHAY_APP_THUC_TE.md. Những phần chưa cần cloud vẫn được lập trình và test bằng fixture, nhưng không thay thế nghiệm thu dịch vụ thật.

## Quy tắc chung và phân công

| Vai trò | Trách nhiệm | Bằng chứng phải giao |
|---|---|---|
| Agent chính | Hợp đồng, tích hợp Flutter/backend, quyết định kiến trúc, resource/quota và báo cáo | Diff, lệnh kiểm tra, kết quả và danh sách còn thiếu |
| GPT-6 Sol | Giao từng gói việc cho AI trong Antigravity, kiểm tra prompt thực sự được gửi, giới hạn file và tránh sửa trùng | Prompt/kịch bản, file đã đổi, trạng thái IDE và phần chưa chạy |
| GPT-5.6 Sol | Review độc lập, kiểm thử quyền/đồng thời/đầu ra AI và xác minh bằng chứng | Lỗi P0/P1/P2, cách tái hiện, kết quả chạy thật |
| Người dùng | Project/billing/secrets, thiết bị, hosting/signing khi tới giai đoạn phát hành | Cấu hình local hợp lệ và môi trường khả dụng; không gửi key trong chat |

Mỗi gói việc đi theo: hợp đồng/schema → implementation → tích hợp UI → kiểm thử độc lập → demo có bằng chứng → cập nhật trạng thái. Trạng thái dùng Ready/In progress/In review/Testing/Accepted/Blocked; có file hay test mock xanh chưa đủ Accepted. Không để IDE và agent chính cùng sửa một file. Với máy 8 GB, chạy tuần tự các build/test nặng, giữ giới hạn worker/heap; không tự xóa dữ liệu cá nhân để dọn ổ.

Giữ năm tab Home/Practice/Progress/Coach/Profile và đủ 20 màn baseline. Dùng chung spacing, typography, màu, button/card; tất cả luồng có loading/empty/error/retry/unauthorized phù hợp, semantics, giảm chuyển động và hỗ trợ320 dp / 200%. Không hiển thị dữ liệu demo như thành tích thật.

## Giai đoạn 4 — Chat AI lưu bền vững và trả lời bằng giọng nói

**Kết quả người dùng:** chọn tình huống hoặc Quick Practice → gõ câu → nhận phản hồi đúng ngữ cảnh có text và audio khớp nhau → phát lại/chậm hơn → đóng app và mở lại vẫn đọc được phiên đúng tài khoản.

**Baseline:** MODE-01, CHAT-01..05, OPS-01..03; màn06–10 và luồng lịch sử15; roadmap v0.4.

| Mã việc | Đầu việc chi tiết | Đầu ra/điều kiện kiểm tra |
|---|---|---|
| S4-01 | Rà các DTO/session/message hiện có với OpenAPI; chốt schema ai_turn_v1 và lỗi typed; định nghĩa giới hạn text/context/pagination, trạng thái turn/session và idempotency | Hợp đồng được cập nhật trước client; ví dụ JSON thành công/lỗi; không thêm field userId có quyền quyết định chủ sở hữu |
| S4-02 | Hoàn thiện sessions/messages/usage/idempotency bằng migration mới sau migration cuối đang có; unique sequence trong phiên, key scope theo user+operation+resource và request hash; index history theo user/time | Database mới và upgrade đều chạy; duplicate key cùng payload trả lại kết quả, khác payload trả409; hai request đồng thời không tạo hai lượt |
| S4-03 | Thay ConversationAiService viết sẵn bằng AiConversationProvider/Gemini adapter; model qua environment; prompt version, level/scenario, giới hạn lịch sử và độ dài đầu ra | Có HTTP provider thật; schema validation; tối đa một lần sửa đầu ra sai trước lỗi typed; không giả response thành công khi provider hỏng |
| S4-04 | Thêm quota theo user, giới hạn phiên đồng thời, timeout, rate limit và usage/cost; lưu trạng thái khi kết quả upstream chưa rõ do timeout | Không retry mutation mù; đối soát usage/request upstream khi được hỗ trợ; ghi riêng chi phí chưa xác định, không tuyên bố exactly-once billing khi provider không bảo đảm |
| S4-05 | Flutter dùng RemoteChatRepository; giữ một idempotency key cho cùng lượt retry; composer multiline, thinking state, failed bubble và retry; paging transcript/history | Không gửi trùng khi double tap; lỗi không xóa nội dung đã gõ; response từ tài khoản/phiên cũ không cập nhật màn hiện tại |
| S4-06 | TTS/player thật: play/pause/replay/stop, tốc độ0.75x / 1x / 1.25x; voice/accent chỉ hiển thị khi adapter hỗ trợ; text vẫn dùng được khi TTS lỗi | Audio phát đúng replyText; không có mock_audio URL trong luồng thật; rời màn/logout dừng player |
| S4-07 | Hoàn tất phiên idempotent và phát sự kiện bền vững để giai đoạn 7 đánh giá; feedback có thể Pending/Processing/Failed | Kết thúc phiên không đợi chấm điểm; transcript hợp lệ vẫn tồn tại nếu scoring lỗi |

API trọng tâm: POST/GET /sessions; GET /sessions/{id}; POST /sessions/{id}/messages; POST /sessions/{id}/complete. TTS dùng thiết bị hoặc endpoint/asset được bổ sung vào hợp đồng trước khi làm client; không tự coi endpoint đang có đã cung cấp audio.

Kiểm thử bắt buộc:20 phiên text end-to-end; lưu/mở lại lịch sử; hai user không đọc/ghi phiên của nhau; cùng key đồng thời; key khác body; phiên đã đóng; JSON sai/empty/truncated; provider429/502/timeout; prompt injection không thay policy hoặc lộ secret; logout trong request; TTS thất bại nhưng text vẫn đọc được.

**Gate 4:** UAT-02 thực tế đạt; dữ liệu persisted đúng một lượt khi retry trong phạm vi app kiểm soát; có log requestId/usage đã redacted và báo cáo20 phiên. Fixture provider chỉ chứng minh logic phục hồi, không chứng minh Gemini/TTS thật.

## Giai đoạn 5 — Guided Speaking, STT/TTS và quyền riêng tư audio

**Kết quả người dùng:** nghe câu hỏi → cấp quyền mic khi cần → ghi âm/dừng → xem transcript → nhận AI audio trả lời; từ chối mic vẫn có đường dùng text.

**Baseline:** MODE-02, VOICE-01..04; màn09,11,20; UAT-03/08; roadmap v0.5.

| Mã việc | Đầu việc chi tiết | Đầu ra/điều kiện kiểm tra |
|---|---|---|
| S5-01 | Chốt STT/TTS provider/khả năng thiết bị; đo một chuỗi thu âm→STT→AI→TTS trước khi tối ưu | ADR lựa chọn, format/codec/duration/size cấu hình, latency từng chặng và cost/phiên5 phút |
| S5-02 | Implement recorder/player thật, permission rationale, start/stop, audio focus; hủy khi background, bị gọi điện, logout hoặc quyền bị thu hồi | Không recording trước thao tác/cấp quyền; giải phóng resource; không waveform giả trạng thái đang thu |
| S5-03 | Guided state machine: idle→aiSpeaking→waitingForUser→recording→transcribing→generating→aiSpeaking/recoverableError→ended | Chuyển trạng thái hợp lệ; chặn double tap; lỗi cho retry hoặc chuyển text; end không treo |
| S5-04 | POST /sessions/{id}/audio-turns theo ownership/idempotency; kiểm MIME, magic header, file rỗng, kích thước/thời lượng và hủy request | File sai bị từ chối trước provider; không dùng tên file/path người dùng như đường dẫn lưu trữ |
| S5-05 | Giữ original ASR riêng với annotation sửa của người dùng; lưu timing/confidence nếu provider cung cấp; AI nhận nguồn text rõ ràng | Không ghi đè bằng chứng nhận dạng gốc; transcript thấp confidence được thông báo, không bịa timing |
| S5-06 | Privacy preferences, consent version và storage private; retention mặc định false; signed reads TTL, delete_after, cleanup và xóa source | Từ chối lưu không tạo retained asset; temporary upload được dọn; xóa/cancel có hiệu lực theo chính sách; xử lý provider data riêng |
| S5-07 | Giao diện mic lớn, hint/translate/repeat, captions, phát lại và tốc độ; bàn phím/safe area, font lớn, trạng thái offline | Critical action không bị che; tốc độ/voice thực sự tác động player; permission denial có text fallback |

Dữ liệu cần có: audio_assets, user_privacy_preferences, transcript source/timing và metadata turn; bổ sung migration mới, không sửa lịch sử migration. Không lưu raw audio trong log. Lưu recording tùy chọn khác với xử lý audio tạm để STT; phải giải thích rõ hai hành vi.

Kiểm thử bắt buộc: mic denied/revoked; recording rỗng; file giả MIME; oversize/overduration; ngắt mạng ở upload/STT/AI/TTS; retry không trùng turn; logout trong lúc thu; đổi audio route; app background; hai account truy cập audio; consent false kiểm cảDB/storage/tempcleanup.

**Gate 5:** thiết bị Android thật/emulator hỗ trợ mic hoàn thành speak→transcript→AI spoken reply, có video và log theo chặng; UAT-03/08 đạt. Test controller mô phỏng không thay thế kiểm thử microphone/âm thanh.

## Giai đoạn 6 — Realtime voice beta và phục hồi kết nối

**Kết quả người dùng:** cuộc gọi hai chiều có audio thật, captions và trạng thái mic rõ; mute/end hoạt động; mất mạng được phục hồi hoặc chuyển guided có giải thích.

**Baseline:** MODE-03, phụ lục C1/C3; màn12; UAT-04; roadmap v0.6.

| Mã việc | Đầu việc chi tiết | Đầu ra/điều kiện kiểm tra |
|---|---|---|
| S6-01 | Spike provider trước: kiểm model/protocol hiện hành, codec/sample rate, VAD, interruption, TTL, resume và quyền truy cập | ADR chọn direct mobile+ephemeral token hoặc Java media gateway; benchmark thực tế và giới hạn đã biết |
| S6-02 | POST /voice-sessions: JWT, ownership, scenario/level, quota/concurrency, giới hạn TTL/duration; /status và /complete | Chỉ trả credential ngắn hạn có phạm vi; không trả key dài hạn; usage phải được server đối soát |
| S6-03 | Flutter media input/output thật, buffering/audio focus, captions, VAD/interruption khi được hỗ trợ | Không phát AI cũ chồng sau barge-in; mute dừng input thực; không hiển thị band score trong cuộc gọi |
| S6-04 | States connecting/listening/speaking/thinking/reconnecting/ending/ended/failed; timeout và reconnect có giới hạn | Nếu không resume được, tạo segment mới có context tóm tắt; không nhân đôi call hoặc mở mic âm thầm |
| S6-05 | Checkpoint transcript/sự kiện quan trọng và network metrics; không ghi từng packet vào DB; hangup phát scoring job sau | Hangup tức thời hợp lý, cleanup kể cả lỗi; báo cáo có thể Processing; lịch sử vẫn đọc được |
| S6-06 | Ma trận30 cuộc gọi gồm Wi-Fi/mobile và điều kiện bất lợi; đo first audible, end-of-utterance→audio, reconnect, drops, crash, cost | Bảng từng cuộc gọi và tổng p50/p95/tỷ lệ thành công, tên thiết bị/mạng/model, không chỉ video thành công |

Ma trận đề xuất30 ca:12Wi-Fi bình thường,8mobile bình thường,4mất mạng ngắn/reconnect,2background/đổi audio route,2mic denied/revoked,2zero-audio/unsupported. Báo cáo đúng loại ca và mẫu số; ca chủ ý từ chối phải tính là xử lý đúng, không trộn vào tỷ lệ call start bình thường. Nếu số mẫu Wi-Fi chưa đủ đánh giá mục tiêu, bổ sung mẫu và ghi rõ.

**Gate 6:** UAT-04 đạt; có30 ca đã chạy; mục tiêu call start≥ 95% trong điều kiện Wi-Fi thử nghiệm, first audible p95< 2.5 giây khi API/thiết bị đáp ứng; reconnect trong10 giây chỉ khi provider hỗ trợ resume. Đây là mục tiêu đo, không cam kết đạt trước thử nghiệm. Không đạt thì tiếp tục giữ nhãn beta/giới hạn và chưa gọi toàn bộ v1 hoàn chỉnh.

## Giai đoạn 7 — Feedback có bằng chứng, coach, progress và privacy

**Kết quả người dùng:** phiên thật tạo feedback có nguồn; biết nên sửa gì và vì sao; lỗi lặp ít nhất3 phiên dẫn tới drill phù hợp; lịch sử, tiến độ, kế hoạch tuần và quyền xóa có tác dụng thật.

**Baseline:** SCORE/FEEDBACK/COACH/PROGRESS/NOTIFY; phụ lục A5/A6,C2/C4; màn05,13–20; UAT-05/06/07; roadmap v0.7–v0.8.

| Mã việc | Đầu việc chi tiết | Đầu ra/điều kiện kiểm tra |
|---|---|---|
| S7-01 | Scoring job theo sessionCompleted; outbox/worker/retry có giới hạn, idempotent; tách phiên Completed khỏi report Processing/Failed | Retry không tạo hai assessment cùng revision; phiên không mất nếu AI đánh giá lỗi |
| S7-02 | Bốn trục 0–9: fluency/coherence, lexical, grammar, pronunciation; lưu rubric/model/prompt/scorer version, confidence, completeness và evidence | Xóa điểm hardcoded/tên acoustic giả; pronunciation N/A khi thiếu engine/audio hợp lệ; overall chỉ có khi đủ4 trục hợp lệ; text-only không suy ngữ điệu/nhịp nói |
| S7-03 | Schema assessment/dimensions, weaknesses, skill profiles, coach memories có source session IDs; assessment revisions bất biến | Không ghi đè lịch sử để làm biểu đồ đẹp; correction trỏ đúng câu thực, evidence không nằm ngoài transcript |
| S7-04 | Ưu tiên coach = recurrence×impact×recency×confidence, với quy tắc/weight có version; tối đa3 focus và micro-drill3–5 phút | Recommendation giải thích được, có sample_count, không bịa cải thiện khi ít dữ liệu |
| S7-05 | Drill templates, attempts và mastery; lịch revisit1/3/7 ngày; kế hoạch7 ngày Planned/Done/Skipped, chỉnh goal/schedule | Lỗi lặp≥3 phiên dẫn tới bài phù hợp; kết quả mới chứng minh cải thiện hoặc còn lỗi, không cộng mastery từ click hoàn tất |
| S7-06 | Vocabulary save/search/master/remove theo owner, nguồn phiên và ví dụ; progress chỉ từ phiên hoàn tất | Không dùng số liệu demo; UTC persistence/Asia_Ho_Chi_Minh khi hiển thị; missing scores là khoảng trống, trend kèm sample/version |
| S7-07 | Profile/privacy thật: đổi goal/voice, bật/tắt memory, xem/xóa nguồn và dữ liệu dẫn xuất, export/delete/account workflow | Xóa source kéo theo hide/delete memory theo policy; có xác thực lại/xác nhận ở thao tác nhạy cảm; không chỉ toast thành công |
| S7-08 | Hoàn tất placement/level estimate còn nợ giai đoạn 3: manual/skip, confidence/limitations và lưu baseline profile | A0 là nhãn nội bộ; không nói CEFR/IELTS chính thức; thiếu acoustic thì không đưa pronunciation vào kết quả |
| S7-09 | Notifications opt-in theo timezone và giờ người dùng; polish summary/history/coach/drill/plan/vocabulary/profile | Chart có bản tóm tắt đọc được, critical actions ở320 dp / 200%, không dùng shame messaging |

API trọng tâm: feedback/assessments; coach/dashboard/ask/memory/preferences; learning-plans/current/items; drills/recommended/attempts; progress/summary/skills; vocabulary CRUD; privacy/preferences; placement start/submit/latest. Hợp đồng hiện chưa đủ delete/export/account/memory-clear: phải bổ sung endpoint, quyền và trạng thái job trước UI, không gọi nút mock là đã hỗ trợ.

Kiểm thử bắt buộc: ít nhất100 fixtures cấu trúc, validity≥ 98% cho đầu ra AI theo baseline; parser từ chối payload sai và không biến thiếu dữ liệu thành điểm0; text-only pronunciationN/A; provenance/confidence đúng; hai account IDOR;3 phiên có cùng lỗi→đúngdrill; policy xóa nguồn/memory/audio; tắt personalization; UTC/day-boundary; human review/calibration có dataset và phương pháp riêng.

**Gate 7:** UAT-05/06/07 đạt; một phiên thực tạo feedback nguồn rõ, drill có lý do, progress khớp DB; báo cáo calibration và giới hạn. Chưa có acoustic scorer thì vẫn hiển thị N/A đúng quy tắc, không tuyên bố đã có chấm phát âm thật.

## Giai đoạn 8 — Kiểm thử toàn hệ thống, tối ưu và phát hành

**Kết quả người dùng:** có Android package cài được, ba hành trình vận hành thật, quyền riêng tư có hiệu lực, lỗi phổ biến có phục hồi và có bằng chứng nghiệm thu.

**Baseline:** UAT-01..09,G1..G6,phụ lục B23/D/E; đủ 20 màn; roadmap v0.9–v1.0.

| Mã việc | Đầu việc chi tiết | Đầu ra/điều kiện kiểm tra |
|---|---|---|
| S8-01 | Đóng tính năng, QA độc lập review diff/API/migration/JWT/IDOR/idempotency/quota/secrets; phân loại P0/P1/P2 | Zero blocker/critical và không còn P0/P1 mở ở bản bàn giao; ghi reproduction và bằng chứng fix |
| S8-02 | Flutter analyze/test, Java 27 verify, contract tests, Postgres fresh+upgrade migrations, config prod và CI từ xa | Ghi đúng phiên bản, command/exit/date; không dùng kết quả snapshot cũ cho mã mới; dọn lỗi/cảnh báo và công khai informational debt |
| S8-03 | E2E9 UAT; app kill/reopen, offline, expired/revoked token, AI429/invalidJSON/timeout, concurrency, crash recovery, audio cleanup | Video/log/DB/storage evidence; business state không mất hay hiện thành công giả khi request lỗi |
| S8-04 | UI audit cả 20 màn:320 dp / 200%, keyboard/insets, loading/empty/offline/denied, semantics/contrast/reduce-motion; render ảnh đại diện | Không chặn thao tác quan trọng; ảnh/golden phản ánh widget hiện tại, không thay bằng mockup chưa triển khai |
| S8-05 | Đo API nghiệp vụ p50/p95 không tính provider; profile/release Flutter đo jank, bộ nhớ, tài nguyên audio; tải/chi phí theo phiên | Mục tiêu API p95< 800 ms trong môi trường/tải công bố; báo cáo provider latency riêng; health benchmark không thay nghiệp vụ |
| S8-06 | Android debug/profile/release cài được; applicationId/version/keystore đúng; HTTPS backend và secret env; DBbackup/restore, monitoring và rollback | APK/AAB có hash/build metadata, không ký debug cho release; không còn localhost trong cấu hình phát hành; thử restore/rollback |
| S8-07 | Pilot10–20 người có consent; đo task completion và feedback; sửa lỗi ưu tiên, chạy regression sau sửa | Mục tiêu≥ 90% task completion theo UAT đã thống nhất; không loại ca thất bại để làm đẹp tỷ lệ |
| S8-08 | Bàn giao source, API/schema, env mẫu, hướng dẫn cài/chạy/vận hành, ERD/sequence/deployment, release notes, known issues;3 video text→voice/realtime/coach | Chỉ tagv1.0 và phát hành sau acceptance đúng baseline; iOS bổ sung nếu có signing |

### Ma trận nghiệm thu bắt buộc

| UAT | Phải chứng minh | Giai đoạn sở hữu |
|---|---|---|
| 01 | Đăng ký/đăng nhập, đóng mở3 lần, phiên hợp lệ vàoHome không nhập lại mật khẩu | Nợgiai đoạn 2; kiểm lại8 |
| 02 | Câu “How should I introduce myself?”→text/audio khớp, replay và slow playback thật | 4, kiểm lại8 |
| 03 | Beginner nhận câu hỏi đúng level, giải thích lỗi bằng tiếng Việt ở cuối | 5+7 |
| 04 | Call audio hai chiều, mic rõ, mất mạng/end sạch | 6 |
| 05 |4 trục có confidence/provenance; thiếu acoustic thì pronunciationN/A | 7 |
| 06 | Lỗi lặp≥3 phiên→drill phù hợp→kết quả có bằng chứng | 7 |
| 07 | User A không đọc/ghi history/memory/audio của B bằng request trực tiếp | 4–8 |
| 08 | Không đồng ý lưu→không retained user audio, kiểm storage/DB/temp cleanup | 5–8 |
| 09 | Android320 dp / 200% không chặn thao tác quan trọng | Mỗi giai đoạn và8 |

**Gate 8/final:** toàn bộ yêu cầu trên có bằng chứng phù hợp, Android cài/chạy thành công, môi trường thật và dữ liệu test hợp lệ, không dùng mock làm thành công thật. Nếu Live/human calibration/thiết bị/provider/hosting chưa kiểm chứng, giữ trạng thái chưa nghiệm thu phần tương ứng; không đổi tên bản còn thiếu thành sản phẩm hoàn chỉnh.

## Phụ thuộc và điều phối tiếp

Đường chính: đóng nợcatalog/auth → sessions/persistence → Gemini text → TTS → guided/STT/privacy → Live spike/transport → evidence scoring → coach/progress → security/performance/device/pilot → release.

Có thể làm song song sau khi hợp đồng chốt: UI với backend adapter; schema/tests với provider fixture; nội dung drill với scoring schema. Không chạy nhiều build nặng đồng thời trên máy 8 GB. Kiểm tra quota ở ranh giới gói việc; khi gần giới hạn ưu tiên tích hợp, sửa lỗi và lưu bằng chứng. Không coi agent/IDE đang đứng chờ là tiến độ đã hoàn thành.

Từng báo cáo phải tách: đã code, đã test local, đã test provider thật, đã test thiết bị và đãAccepted. Những điều cần người dùng chuẩn bị nằm trong THIET_LAP_DE_CHAY_APP_THUC_TE.md; khóa và mật khẩu chỉ để ở cấu hình local/backend.
