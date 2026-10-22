# English Speaking AI Project Master Plan

Source: https://docs.google.com/document/d/1tG6tqacN4W6dQW1SLTJeqjvMS7ql4ydMUpehVJl0WmU
Retrieved: 2026-10-21
Source revision: AHj4eMS58MG0-Vgb2qdqXeR9F3r4X6SyxvWSzYjDBkpW7yZfC9tGbZjhfKKw5oiUX_UZ4M9REVXAwhVRYjNb36tHshKXiqhvhGF1lOIt9zM
This is a text mirror. Appendices A–E supersede conflicting scope in chapters 1–12. User-requested Java 27 and four-hour execution amendments are recorded separately in ADR and execution plan; the source text below is preserved.

ENGLISH SPEAKING AI — PROJECT MASTER PLAN
Xây dựng ứng dụng di động luyện giao tiếp và phản xạ tiếng Anh thông minh tích hợp Generative AI trên nền tảng Flutter
Mã tài liệu: ESP-PLAN-001 | Phiên bản tài liệu: 1.0.0 | Ngày khởi tạo: 14/10/2026
Trạng thái: Baseline đề xuất — cần nhóm phê duyệt
Vai trò tài liệu:
Project Charter
Product Requirements
Architecture Decision Record
Version Roadmap
AI Agent Coding Contract
Đây là nguồn tham chiếu chuẩn duy nhất (single source of truth) cho lập kế hoạch và triển khai; mọi thay đổi phải ghi CHANGELOG.
1. TỔNG QUAN VÀ ĐỊNH HƯỚNG SẢN PHẨM
1.1. Vấn đề và giá trị
Người học tiếng Anh thiếu môi trường thực hành nói thường xuyên, ngại sai, khó nhận phản hồi cá nhân hóa và khó duy trì phản xạ. Sản phẩm xây dựng không gian luyện nói với gia sư AI theo tình huống, đánh giá sau phiên và lộ trình tiến bộ có thể theo dõi.
1.2. Mục tiêu SMART (giả định dùng để nghiệm thu)
G1: Người mới có thể đăng nhập, chọn trình độ và hoàn thành 01 phiên hội thoại trong tối đa 5 thao tác chính sau onboarding.
G2: v0.5 có tối thiểu 12 kịch bản thuộc 4 chủ đề (giới thiệu, đời sống, du lịch, công việc).
G3: 95% yêu cầu API thông thường đạt p95 < 800 ms tại môi trường thử nghiệm, không tính độ trễ bên thứ ba.
G4: phản hồi AI có cấu trúc hợp lệ ≥ 98% trên tập 100 ca kiểm thử.
G5: phiên hội thoại và lịch sử không lộ dữ liệu chéo tài khoản trong các ca kiểm thử phân quyền.
G6: demo hoàn chỉnh Android; iOS là mục tiêu bổ sung nếu có môi trường ký build.
1.3. Đối tượng và phạm vi
Đối tượng: sinh viên, người đi làm, người mất gốc hoặc trình độ A1–B2.
Vai trò sản phẩm MVP: learner và system admin (admin quản trị qua backend, chưa cần app quản trị riêng).
Ngôn ngữ giao diện: tiếng Việt; hội thoại bằng tiếng Anh; lời giải thích có thể bằng tiếng Việt.
Không cam kết chấm điểm CEFR/IELTS chính thức hoặc thay giáo viên.
1.4. In-scope / Out-of-scope
In-scope v1: tài khoản, onboarding, hồ sơ trình độ, chủ đề và tình huống, trò chuyện text, voice turn-by-turn, transcript, giải thích lỗi, từ vựng, lịch sử, theo dõi tiến độ, nhắc luyện, cấu hình AI và giới hạn sử dụng.
Out-of-scope v1: lớp học trực tiếp, video call, mạng xã hội, thanh toán, AI avatar 3D, xếp hạng ngôn ngữ có chứng nhận, hội thoại giọng nói song công quy mô lớn.
2. QUYẾT ĐỊNH KIẾN TRÚC CHUẨN (ADR)
ADR-001 [ACCEPTED AS BASELINE]: Flutter/Dart cho mobile Android-first; iOS tương thích.
ADR-002: Java 21 LTS + Spring Boot 3.x Modular Monolith triển khai thành 01 dịch vụ.
ADR-003: Supabase PostgreSQL là database chính; Supabase Auth chịu trách nhiệm định danh; Supabase Storage chứa tệp có kiểm soát.
ADR-004: REST JSON /api/v1 cho nghiệp vụ; WebSocket hoặc Live gateway chỉ dùng khi thật sự triển khai realtime.
ADR-005: Gemini API thông qua AI Provider Adapter; không đặt provider keys trên mobile.
ADR-006: mã nguồn là monorepo gồm mobile/, backend/, docs/, infra/.
ADR-007: mọi bảng dữ liệu người dùng có owner_id và phân quyền rõ ràng.
2.1. Ranh giới trách nhiệm
Flutter: hiển thị, state, thu/phát audio, xác thực UI, hiển thị transcript/feedback và offline cache nhẹ.
Spring Boot: xác thực Supabase JWT, authorization, kịch bản, phiên trò chuyện, prompt building, Gemini adapter, rubric scoring, quota, audit, lưu lịch sử.
Supabase Auth: đăng ký/đăng nhập và phát JWT.
PostgreSQL: lưu dữ liệu sản phẩm.
Storage: lưu recording tùy chọn, private mặc định.
Gemini: sinh câu trả lời và phản hồi có cấu trúc; không nắm logic quyền hạn hoặc truy cập DB trực tiếp.
2.2. Quy tắc xác thực và RLS
Luồng:
Flutter đăng nhập qua Supabase Auth
Lấy access token
Gọi Spring Boot kèm Authorization: Bearer
Backend verify chữ ký JWT với JWKS, issuer/audience/expiry phù hợp
Lấy subject làm user id
Kiểm tra quyền sở hữu tài nguyên
Nếu backend dùng DB role có đặc quyền bỏ qua RLS, bắt buộc enforce ownership ở service/repository và kiểm thử IDOR. Tuyệt đối không chuyển service_role key cho Flutter; không tin user_id do client gửi.
2.3. Đánh giá Gemini và phương án thay thế
MVP ưu tiên Gemini text model có giá/độ trễ phù hợp, model name qua biến môi trường thay vì hardcode; dùng structured JSON output cho coach feedback.
Phương án voice MVP: STT → transcript → Gemini text → TTS hoặc audio chuẩn của thiết bị, giúp kiểm soát quy trình và kiểm thử.
Sau v1 mới thí nghiệm Gemini Live API native-audio cho phản xạ thời gian thực.
Nếu Gemini không đạt chi phí/chất lượng: chuyển provider qua interface AiConversationProvider / SpeechToTextProvider / TextToSpeechProvider; có thể thử OpenAI hoặc Google Cloud Speech/TTS và so sánh theo benchmark.
Không dựa vào mô hình miễn phí để cam kết SLA.
Quy tắc chọn provider:
So sánh 100 mẫu (50 hội thoại A1–A2, 50 hội thoại B1–B2)
Đo chất lượng, tỷ lệ JSON hợp lệ, độ trễ p50/p95, giá trên một phiên 5 phút, độ ổn định tiếng Anh và mức độ hữu ích của correction
Chọn theo kết quả thực nghiệm, không theo quảng cáo
Giá/ID model có thể đổi nên xác minh lại trên trang chính thức trước sprint AI.
3. CHỨC NĂNG VÀ MÃ YÊU CẦU (BACKLOG CHUẨN)
AUTH: AUTH-01 đăng ký email; AUTH-02 đăng nhập/đăng xuất; AUTH-03 quên mật khẩu; AUTH-04 quản lý phiên.
PROFILE: PROFILE-01 tên hiển thị/avatar; PROFILE-02 trình độ/goal/time-per-day.
CATALOG: TOPIC-01 danh mục chủ đề; SCENARIO-01 danh sách tình huống, vai trò, độ khó, mục tiêu.
CHAT & VOICE: CHAT-01 tạo phiên; CHAT-02 gửi câu tiếng Anh; CHAT-03 trả lời AI; CHAT-04 kết thúc phiên; CHAT-05 xem lịch sử; VOICE-01 quyền microphone; VOICE-02 ghi âm turn; VOICE-03 nhận transcript; VOICE-04 đọc câu AI.
FEEDBACK & PROGRESS: FEEDBACK-01 chỉ ra lỗi; FEEDBACK-02 gợi ý diễn đạt tự nhiên; FEEDBACK-03 lưu từ vựng; FEEDBACK-04 điểm theo rubric; PROGRESS-01 thống kê thời lượng/số phiên; PROGRESS-02 xu hướng theo tuần; NOTIFY-01 nhắc học nội bộ.
OPS: OPS-01 quota; OPS-02 logging; OPS-03 audit/security.
3.1. User journeys và quy tắc sản phẩm
Journey A: Welcome → Sign up/Login → chọn level và goal → Home → chọn scenario → Conversation → End Session → Feedback → Save Vocabulary → Progress.
Journey B: Home → Quick Practice → AI hỏi mở đầu → người dùng trả lời bằng text hoặc voice → AI phản hồi ngắn, tự nhiên → kết thúc → đánh giá.
Journey C: History → chọn phiên → xem transcript và corrections → luyện lại câu sai.
Khi mất mạng: hiển thị lỗi có thể retry; không tạo nhiều message trùng khi bấm lại.
3.2. Quy tắc hội thoại và sư phạm
AI đóng vai nhân vật của scenario; ưu tiên hỏi tiếp để kích thích phản xạ thay vì giải thích dài.
Mỗi turn duy trì level, ngữ cảnh, câu hỏi liên quan, tối đa độ dài câu AI theo cấp độ.
Chế độ Conversation không ngắt lời sửa mọi câu; correction chi tiết hiển thị sau turn hoặc sau session.
Feedback nêu bằng chứng từ transcript, không bịa lỗi.
Gán rubric mức 0–5 cho relevance, grammar, vocabulary, fluency proxy; pronunciation chỉ hiển thị khi thực sự có tín hiệu audio và bộ đánh giá đáng tin, không suy từ transcript text.
4. THIẾT KẾ KIẾN TRÚC VÀ HỢP ĐỒNG API
4.1. Mobile folders / backend packages
Mobile Directory Structure (mobile/lib/):
app/: bootstrap, router, theme
core/: network, errors, config, widgets
features/: auth/, onboarding/, home/, scenarios/, conversation/, feedback/, progress/, profile/
Trong từng feature: data/ (DTO, datasource, repository impl), domain/ (entities, repository contracts, use cases), presentation/ (screens, widgets, providers). State: Riverpod; navigation: GoRouter; networking: Dio; model serialization: json_serializable/freezed nếu nhóm thống nhất.
backend/src/main/java/.../: config/, security/, common/, auth/, profile/, scenario/, conversation/, ai/, feedback/, progress/, quota/. Trong mỗi module: controller/, application/, domain/, infrastructure/. Backend dùng Spring Web, Validation, Security, Data JPA/JDBC theo module, Flyway migration, Actuator, OpenAPI. Module không gọi trực tiếp entity nội bộ của nhau; giao tiếp qua service interface.
4.2. API v1 khởi tạo
GET /api/v1/me; PATCH /api/v1/me; GET /api/v1/scenarios?level=&topic=; GET /api/v1/scenarios/{id}; POST /api/v1/sessions; GET /api/v1/sessions; GET /api/v1/sessions/{id}; POST /api/v1/sessions/{id}/messages; POST /api/v1/sessions/{id}/audio-turns; POST /api/v1/sessions/{id}/complete; GET /api/v1/sessions/{id}/feedback; GET /api/v1/progress/summary; GET /api/v1/vocabulary; POST /api/v1/vocabulary; GET /api/v1/health (public, không lộ secrets). Các endpoint thay đổi phải cập nhật OpenAPI trước khi code client.
4.3. API conventions / error schema
JSON camelCase, database snake_case, timestamps UTC ISO-8601, ID UUID, enum ổn định, version /api/v1. Lỗi chuẩn: {"code":"QUOTA_EXCEEDED","message":"...","details":{},"requestId":"...","timestamp":"..."}; status 400 validation, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 429 rate limit, 502/503 upstream AI. Gửi Idempotency-Key khi tạo session/message; hỗ trợ pagination bằng cursor hoặc page-size thống nhất.
4.4. AI structured contract
AiTurnRequest: sessionId, scenarioId, learnerLevel, history[], latestUserText, feedbackMode, locale, constraints.
AiTurnResponse: replyText, followUpQuestion, usefulPhrases[], corrections[{original, suggested, explanationVi, type}], safetyFlag, modelId, usage.
Json schema version ai_turn_v1; validate server-side, retry có giới hạn nếu JSON invalid, fallback phản hồi an toàn; không lưu prompt có dữ liệu nhận dạng không cần thiết.
5. DATABASE DESIGN — POSTGRESQL / SUPABASE
Tất cả schema do Flyway migration quản lý; không chỉnh cấu trúc production thủ công trên Dashboard. Bảng lõi: profiles(id PK=auth.users.id, display_name, level, goal, daily_minutes, created_at, updated_at); topics(id, slug unique, title, active); scenarios(id, topic_id FK, level, title, description, role_ai, learning_objectives jsonb, initial_prompt_template, active); practice_sessions(id, user_id FK, scenario_id FK nullable, status, mode, started_at, ended_at, duration_seconds); conversation_messages(id, session_id FK, role, text, audio_path nullable, sequence_no, provider_model nullable, created_at); feedback_reports(id, session_id unique FK, rubric_version, summary_vi, scores jsonb, corrections jsonb, generated_at); vocabulary_items(id, user_id FK, source_session_id FK nullable, phrase, meaning_vi, example, mastered, created_at); daily_progress(id, user_id, day, sessions_count, seconds_spoken, unique(user_id,day)); ai_usage_logs(id, user_id, session_id, provider, model, input_tokens, output_tokens, estimated_cost, created_at); user_settings(user_id PK, notifications_enabled, audio_retention_days).
Index bắt buộc: practice_sessions(user_id,started_at desc), conversation_messages(session_id,sequence_no unique), vocabulary_items(user_id,created_at desc), daily_progress(user_id,day). CHECK constraint các enum, duration >= 0; FK on delete có chủ đích. Storage audio private; thiết lập hạn lưu mặc định (ví dụ 30 ngày) cần được người dùng chấp thuận, có cơ chế xóa. RLS bật cho mọi bảng user-facing, policy user_id = auth.uid() trong trường hợp truy cập bằng user JWT; các bảng public content chỉ SELECT active. Backend role được giới hạn quyền và kiểm soát ownership riêng.
6. ROADMAP PHÁT TRIỂN THEO VERSION
Cách version: Semantic Versioning MAJOR.MINOR.PATCH cho ứng dụng và API. Mỗi version là một release có demo, migration, test, changelog và release tag. Ước lượng nhóm 3–4 người, sprint 2 tuần, tổng kế hoạch khoảng 16–20 tuần (điều chỉnh theo năng lực thực tế). Không trộn tính năng version tương lai vào sprint hiện tại.
v0.1.0 — Foundation / Sprint 1–2 / Tuần 1–4
Mục tiêu: chạy xuyên suốt project skeleton. Mobile: app theme, routing, splash, màn hình Auth placeholder. Backend: Spring Boot bootstrap, health, OpenAPI, exception handler, CORS, environment config. Supabase: project dev, auth, migration đầu tiên. DevOps: monorepo, branch protection, CI format/lint/test, Docker Compose local cho backend phụ trợ, README setup. DoD: cả mobile và backend chạy từ README trên máy mới; CI xanh; secrets không commit; ADR được duyệt.
v0.2.0 — Identity & Profile / Sprint 3 / Tuần 5–6
Mobile: register/login/reset password, onboarding level/goal, profile. Backend: JWT verification, /me, authorization tests. DB: profiles, user_settings, policies. DoD: đăng nhập/đăng xuất/refresh hợp lệ, chặn truy cập tài khoản khác, xử lý expired token, 10+ test auth/security.
v0.3.0 — Learning Catalog / Sprint 4 / Tuần 7–8
Mobile: Home, topics, scenario list/detail, filters theo level. Backend: scenario catalog và seed versioned. DB: topics/scenarios. Nội dung: ít nhất 12 scenario / 4 chủ đề, mục tiêu học cụ thể, prompt role metadata. DoD: người dùng chọn scenario và xem intro; UI loading/empty/error được xử lý.
v0.4.0 — AI Text Conversation / Sprint 5 / Tuần 9–10
Mobile: text chat, typing state, kết thúc phiên, recover network. Backend: session/message APIs, Gemini adapter, response validation, quota, context window management. DB: sessions/messages/usage_logs. DoD: 20 phiên end-to-end không mất hoặc trùng message, prompt injection không làm lộ secrets, mock-provider integration tests xanh.
v0.5.0 — Voice Turn-Based / Sprint 6 / Tuần 11–12
Mobile: microphone permission, record/stop, waveform đơn giản, phát audio đáp lời, fallback text. Backend: upload kiểm tra MIME/size/duration, speech adapter, STT→AI→TTS orchestration, timeout/retry. Storage: private bucket, signed access có TTL, cleanup. DoD: ghi âm → transcript → AI reply → phát tiếng thành công trên thiết bị thật; nếu microphone bị từ chối vẫn dùng text; test file sai định dạng.
v0.6.0 — Personalized Feedback / Sprint 7 / Tuần 13–14
Mobile: trang tổng kết, highlights correction, lưu câu/từ vựng, làm lại. Backend: JSON rubric scoring, guardrails, versioned prompt templates, feedback persistence. DB: feedback_reports, vocabulary_items. DoD: dữ liệu feedback parse hợp lệ ≥98%/100 fixtures; hiển thị rõ điểm tham khảo, không quảng bá điểm thi chuẩn hóa; feedback gắn đúng câu thực tế.
v0.7.0 — Progress & Habit / Sprint 8 / Tuần 15–16
Mobile: lịch sử, biểu đồ luyện tập, streak, mục tiêu hàng ngày, notification local. Backend: summary aggregation, daily progress, tối ưu queries. DoD: số liệu nhất quán với phiên đã hoàn tất; timezone Asia/Ho_Chi_Minh trong hiển thị ngày, lưu UTC; streak tính đúng ở ranh giới ngày.
v0.8.0 — Hardening & Quality / Sprint 9 / Tuần 17–18
Security: rà IDOR, OWASP MASVS cơ bản, rate limits, quota, audit; Reliability: exponential backoff có giới hạn, circuit breaker cho AI, logging không chứa raw token/audio; Performance: p95 API, profiling Flutter; Accessibility: font scaling, contrast, permission disclosures; Quality: E2E, regression, crash recovery. DoD: zero blocker/critical còn mở, release candidate build thành công.
v0.9.0 — Beta & Acceptance / Sprint 10 / Tuần 19
Pilot 10–20 người học, thu feedback có consent, theo dõi lỗi và usage cost, sửa lỗi ưu tiên P0/P1, chốt demo scripts, user manual, sơ đồ ERD/sequence/deployment, chuẩn bị checklist phát hành. DoD: ≥90% task completion trên kịch bản UAT đã thống nhất, không lỗi P0/P1, có báo cáo thử nghiệm.
v1.0.0 — Final Release / Tuần 20
Đóng băng feature; phát hành Android APK/AAB thử nghiệm, tài liệu API/architecture/test/installation, video demo, release notes, bản báo cáo đồ án và tài liệu bảo trì. Chỉ tag v1.0.0 khi Product Owner/giảng viên xác nhận acceptance checklist và dữ liệu demo hoạt động.
Post-v1 candidate (KHÔNG thuộc cam kết v1)
v1.1: Live conversational streaming / barge-in sau spike Gemini Live API; v1.2: adaptive curriculum dựa trên mastery; v1.3: spaced repetition + pronunciation acoustic scoring bằng engine chuyên dụng; v2: đa nền tảng/monetization. Chỉ khởi động sau ADR, benchmark và dự toán chi phí.
7. KẾ HOẠCH TRIỂN KHAI VÀ QUẢN TRỊ SPRINT
Vai trò RACI tối thiểu: PO/BA sở hữu scope, user stories, acceptance; Mobile Lead sở hữu Flutter UX và test; Backend Lead sở hữu API/security/database; AI/QA owner sở hữu prompts/evaluation/tests; một người có thể kiêm vai trong nhóm nhỏ. Mỗi sprint: Sprint Planning → thiết kế API/schema → implement vertical slice → code review → test → demo → retro. Board: Backlog / Ready / In Progress / In Review / Testing / Done / Blocked; WIP tối đa 2 task/dev.
Mỗi issue chuẩn: ID, version, feature, mục tiêu, dependencies, requirements, implementation notes, acceptance criteria dạng Given–When–Then, test evidence, PR link. Definition of Ready: rõ API/UX/DB tác động, phụ thuộc đã giải quyết, ước lượng ≤ 3 ngày/dev. Definition of Done: code review, lint pass, tests pass, migration forward-tested, docs updated, không secret, build chạy, bằng chứng ảnh/video khi UI.
7.1. Dependencies / critical path
Auth → Profiles → Catalog → Sessions → Gemini AI text → Audio → Feedback → Progress → UAT → Release. Không xây dựng scoring trước khi chốt transcript/AI schema; không triển khai Live streaming trước khi đo turn-based latency và chi phí. Phân công song song: Flutter wireframe và Backend contract trong sprint đầu; seed scenarios và UI catalog có thể song song.
7.2. Chỉ số quản trị
Theo dõi sprint burndown, velocity theo issue hoàn thành, escape defects, build success, test coverage phần business logic (mục tiêu 70%+ làm guideline, không thay cho chất lượng), AI JSON validity, cost/session, API p95, crash-free sessions. Ghi rõ baseline, cách đo, môi trường và ngày đo; không báo cáo số giả định như dữ liệu thực.
8. KIỂM THỬ, CHẤT LƯỢNG VÀ BẢO MẬT
Pyramid: unit tests Flutter providers/domain và backend services; integration tests database/auth/API/AI mocks; contract tests OpenAPI/schema; E2E smoke on Android device. Test matrix: happy path, network loss/timeout, mic denied, malformed audio, JWT expired, concurrent requests, double tap, session ownership, AI invalid JSON, quota reached, user deletes account. Mọi lỗi phân loại P0 (data/security outage), P1 (core flow broken), P2 (minor flow), P3 (cosmetic).
Bảo mật: secrets chỉ ở backend secret manager/env; TLS bắt buộc; JWT verification dùng issuer/JWKS; server xác minh ownership; input validation, file limits, malware-safe handling; rate limit user/IP; data minimization; consent ghi âm; quyền xóa transcript/audio; backup + restore drill; structured log có requestId và masking. Prompt injection: scenario/user content là dữ liệu không tin cậy, không thể thay đổi system policies, backend không thực thi tool ngoài whitelist.
9. CHI PHÍ, RỦI RO VÀ ĐIỂM QUYẾT ĐỊNH
Tách chi phí: Supabase compute/database/storage/egress, hosting Java, Gemini input/output, STT, TTS, CI/CD và monitoring. Công thức ngân sách: monthly_cost ≈ DAU × sessions_per_day × days × (AI cost per session + audio cost per session) + fixed infrastructure; đo token/audio thực tế từ pilot, thêm buffer 20–30%. Không chốt USD cụ thể khi chưa có telemetry hoặc pricing snapshot.
Risk R1 Gemini trả JSON sai (M/H): schema validation + retry bounded + fallback. R2 speech latency/mất kết nối (H/H): turn-based trước, compress/audio formats, provider timeout. R3 phát sinh phí (H/H): per-user quota, project budget alerts, cost logs. R4 dữ liệu audio nhạy cảm (H/H): consent, encryption, private bucket, retention/delete. R5 scope creep (H/H): version freeze, change request. R6 RLS/JWT sai (H/H): security tests và kiểm tra privilege. R7 model deprecation (M/H): configurable model + adapter + compatibility checks.
10. AI CODING AGENT — CONTRACT KHÔNG ĐƯỢC VI PHẠM
AGENT-01: Luôn đọc PROJECT_MASTER_PLAN và docs/adr/ trước khi sửa.
AGENT-02: Không tự ý thay đổi stack, package layout, DB schema, API conventions, provider, naming hoặc phạm vi release; nếu cần đề xuất ADR mới.
AGENT-03: Mỗi nhiệm vụ phải bám issue ID và target version; chỉ thay file trong scope.
AGENT-04: Contract-first: OpenAPI/DTO → backend → Flutter client → tests.
AGENT-05: DB thay đổi luôn bằng migration có version, kiểm soát rollback; không sửa DB bằng tay.
AGENT-06: AI output phải schema-validated, provider key không xuất hiện trong app/log.
AGENT-07: Không dùng placeholder giả thay feature hoàn chỉnh nếu không đánh dấu TODO rõ.
AGENT-08: Không coi task Done nếu test/build chưa chạy; nêu rõ test nào không chạy được.
AGENT-09: Mọi PR cập nhật changelog/task log.
AGENT-10: Mã nguồn/README/comments dùng tiếng Anh; UX và báo cáo chủ yếu tiếng Việt.
10.1. Prompt giao việc chuẩn cho agent
Task ID: ESP-[version]-[number]. Goal: ... Scope: ... Files allowed: ... Inputs: ... API/DB contracts: ... Acceptance criteria: ... Constraints: ... Test commands: ... Expected output: changed files + reasoning summary + migrations + tests + risks. Trước code agent phải tóm tắt kế hoạch ngắn; sau code phải liệt kê files changed, câu lệnh test và kết quả thực tế. Nếu requirements mâu thuẫn, agent phải báo conflict thay vì tự suy đoán.
10.2. Branching / commit / CI rules
Main được bảo vệ; develop tùy nhóm; branch feature/ESP-123-short-name, fix/ESP-124-name. Conventional Commits: feat:, fix:, refactor:, test:, docs:, chore:. PR bắt buộc issue link + checklist + screenshot UI + API compatibility + test evidence; tối thiểu 1 reviewer. CI chạy Flutter analyze/test, Java test, secret scanning, migration validation, build artifact. Deploy dev → staging → production, cấu hình độc lập; không dùng production key trên máy dev.
11. TÀI LIỆU SỐNG, PHÊ DUYỆT VÀ CHANGE LOG
Cấu trúc docs khuyến nghị: docs/PROJECT_MASTER_PLAN.md (bản mirror từ Google Docs), docs/PRODUCT_REQUIREMENTS.md, docs/API_CONTRACT.yaml, docs/DATABASE_SCHEMA.md, docs/adr/ADR-001-architecture.md, docs/AI_PROMPTS.md (prompt versions + evaluation), docs/TEST_PLAN.md, docs/SPRINT_LOG.md, docs/CHANGELOG.md, docs/AGENT_RULES.md. Source of truth: Google Docs này cho product roadmap; OpenAPI/migrations trong Git là nguồn chuẩn cho contract thực thi. Đồng bộ nội dung trước merge và khi thay version.
11.1. Decision log
2026-10-14 | DEC-001 | Đề xuất Flutter + Spring Boot + Supabase | Proposed; 2026-10-14 | DEC-002 | Gemini adapter cho hội thoại và feedback | Proposed; 2026-10-14 | DEC-003 | Turn-based voice MVP, Live API post-v1 | Proposed; 2026-10-14 | DEC-004 | 10 milestones v0.1–v1.0 | Proposed. Người phê duyệt: Product Owner/nhóm — chưa ghi nhận.
11.2. Change log của kế hoạch
v1.0.0 / 2026-10-14 — Khởi tạo master plan: vision, architecture, AI strategy, feature IDs, DB baseline, endpoints, milestones, QA/security, cost/risk, agent contract. Author: AI-assisted draft. Trạng thái: Đề xuất để rà soát; chưa được xem là bản thiết kế đã triển khai.
11.3. Các điểm cần xác nhận khi kick-off
D-01 Quy mô nhóm và deadline thật; D-02 Android-only hay cả iOS; D-03 người dùng beta và ngân sách; D-04 chọn nhà cung cấp STT/TTS sau PoC; D-05 quyền lưu/xóa audio; D-06 cách đặt tên app/repo chính thức; D-07 hosting Spring Boot; D-08 metric chất lượng speaking; D-09 tính năng ngoài scope có được đổi vào MVP không.
12. NGUỒN KỸ THUẬT VÀ NGUYÊN TẮC CẬP NHẬT
Nguồn tham khảo chính thức: https://docs.flutter.dev/ ; https://docs.spring.io/spring-boot/ ; https://supabase.com/docs ; https://ai.google.dev/gemini-api/docs ; https://ai.google.dev/gemini-api/docs/live-api/capabilities ; https://ai.google.dev/gemini-api/docs/pricing ; https://owasp.org/www-project-mobile-application-security/ . Tên model, API, pricing, SDK và policy cần kiểm tra lại trước khi khởi tạo từng sprint. Ngày đối chiếu nguồn: 14/10/2026.
KẾT THÚC BASELINE — Mọi phát triển mới phải chỉ rõ feature ID, release target, API/DB impact và acceptance test.
PHỤ LỤC A — PRODUCT SPECIFICATION V1.1.0 (THAY THẾ PHẠM VI V1 TRƯỚC ĐÓ)
Cập nhật 14/10/2026. Trạng thái: revised product baseline, chưa phê duyệt. Ưu tiên: nếu có mâu thuẫn về phạm vi/tính năng/release giữa chương 1–12 và Phụ lục A–E, áp dụng Phụ lục A–E; các quy tắc bảo mật, cấu trúc Git và nguyên tắc contract-first trước đó vẫn giữ hiệu lực. Bản kế hoạch này làm rõ thêm, không tuyên bố rằng chức năng đã hoàn thành.
A1. Tuyên ngôn sản phẩm và ưu tiên
Tên làm việc: English Speaking AI Coach. Giá trị cốt lõi: một AI speaking tutor có giọng nói tự nhiên, tương tác hội thoại gần thời gian thực, ghi nhớ mục tiêu/khuyết điểm và thiết kế bài luyện phù hợp từng cá nhân. P0 bắt buộc v1: session persistence, text→AI spoken reply, speaking turn-based, realtime voice conversation, multi-level placement, scoring tham khảo IELTS, progress dashboard, individual learning plan, corrective exercises và đầy đủ UX/error states. P1: reminders, saved vocabulary, review insights, voice preference. P2 post-v1: thi thử IELTS đầy đủ chuẩn examiner workflow, collaborative classroom, payment, avatar 3D.
A2. Đối tượng, trình độ và learning pathway
Level A0 (Starter, nội bộ, không phải CEFR chính thức): alphabet, câu giới thiệu rất ngắn, từ vựng sinh hoạt. A1 Beginner: câu đơn, hỏi/đáp bản thân và nhu cầu thường ngày. A2 Elementary: hội thoại mua sắm, chỉ đường, đặt dịch vụ, kể chuyện ngắn. B1 Intermediate: thảo luận kinh nghiệm, diễn đạt lý do/quan điểm, duy trì mạch nói. B2 Upper Intermediate: hội thoại công việc, bảo vệ ý kiến, giải thích ưu/nhược. C1 Advanced: lập luận phức tạp, nuance, nói theo ngữ cảnh học thuật/nghề nghiệp. C2 Proficient: diễn đạt linh hoạt, độ chính xác cao, discourse nâng cao. Level placement là ước lượng ứng dụng dựa trên multiple tasks; không chứng nhận năng lực CEFR.
Mỗi level định nghĩa: 1) proficiency objectives; 2) vocabulary themes; 3) grammar targets; 4) speaking tasks; 5) rubric thresholds do nhóm hiệu chuẩn; 6) remedial exercises; 7) unlock rules. Không nâng/hạ level chỉ từ 01 cuộc hội thoại. Đề xuất: placement 3 phần (self-rating + reading/response + audio sample), theo dõi ít nhất 5 phiên có chất lượng và xác nhận khi đề xuất tăng level. Người dùng có quyền luyện vượt level mà không bị khóa.
A3. Persistent login và điều hướng auth
AUTH-05 Remember me mặc định: Supabase Flutter persist session trong storage; ưu tiên AuthAsyncStorage với secure storage nơi thích hợp. App launch: Splash → initialize Supabase → await auth initialized → restore session → refresh khi cần → verify profile → Home nếu hợp lệ, Login nếu signed out/revoked. Nếu offline và phiên đã có: chỉ hiện nội dung cache cho phép, không thực hiện network request chưa xác thực. Xử lý initialSession, tokenRefreshed, signedOut, userDeleted và stream onError; tránh vòng lặp refresh. Logout xóa session local, dừng audio stream và reset providers. Không lưu password hoặc JWT ở plain logs. Cung cấp 'Sign out all devices' chỉ nếu API/flow được hỗ trợ và kiểm thử.
A4. Ba chế độ nói cốt lõi
MODE-01 Ask by Text → Hear AI: người dùng gõ câu hỏi tiếng Anh hoặc Việt, Java gọi AI hội thoại → nhận replyText + audio response → Flutter phát giọng nói có nhấn nhá và subtitle đồng bộ ở mức khả thi; nút replay, tốc độ 0.75x/1x/1.25x, hiển thị transcript. MODE-02 Guided Speaking Turn: AI đưa ra câu hỏi bằng tiếng Anh, phát audio; người dùng nhấn giữ/nhấn bắt đầu nói; audio → transcript và dữ liệu timing → AI trả lời; lưu phát âm/fluency signals nếu có. MODE-03 Realtime Free Conversation: cuộc gọi âm thanh 2 chiều, session context, VAD, interruption/barge-in, mute, subtitles, elapsed time, reconnect và graceful end; hệ thống không chấm mọi giây gây gián đoạn; sau cuộc gọi tạo báo cáo.
Real-time success criteria (mục tiêu cần benchmark, chưa phải cam kết provider): voice start success ≥ 95% trong môi trường Wi-Fi thử nghiệm; first audible response p95 < 2.5s nếu API/thiết bị hỗ trợ; reconnect trong 10s sau đứt ngắn nếu provider có cơ chế resume; nếu không thể resume thì tạo segment mới giữ context text tóm tắt. Đo riêng thời gian từ kết thúc phát âm đến bắt đầu audio AI, first audio latency, turn end detection, dropped frames, crashes; công bố giới hạn mạng và thiết bị.
A5. IELTS-inspired scorecard và sự minh bạch
SCORE-01 Fluency & Coherence: tốc độ, độ ngập ngừng, lặp, cách phát triển ý và liên kết câu (cần audio timing + transcript). SCORE-02 Lexical Resource: phạm vi/độ chính xác từ, collocations, diễn đạt lại ý. SCORE-03 Grammatical Range & Accuracy: đa dạng cấu trúc và mức độ lỗi. SCORE-04 Pronunciation: intelligibility, stress, rhythm, intonation, phonemic features, dựa trên audio/engine phù hợp, không suy điểm từ văn bản thuần. Mỗi trục cho estimated score 0–9 (có thể dùng nửa band nếu đã hiệu chuẩn), evidence snippets, confidence, feedback tiếng Việt, micro-exercise liên kết lỗi. Overall chỉ tính nếu cả 4 trục có đánh giá hợp lệ; hiển thị 'N/A' thay vì bịa pronunciation khi thiếu audio. Điểm ứng dụng không phải kết quả thi IELTS được công nhận.
Assessment reliability protocol: 1) phiên đủ thời lượng và số lượt nói tối thiểu được nhóm định nghĩa; 2) tách ASR confidence và chất lượng audio; 3) đánh giá từ transcript + acoustic features; 4) version rubric; 5) hiệu chuẩn trên sample được giảng viên/assessor chấm độc lập, đo MAE, agreement và bias theo accent; 6) lưu confidence/limitations. Score không được dùng để khẳng định chứng chỉ. IELTS public descriptors là tham chiếu giáo dục, không sao chép bảng đầy đủ vào app.
A6. Personal Coach memory và adaptive correction
COACH-01 learner profile: level estimate, goals (IELTS/travel/work/daily speaking), available daily minutes, preferred feedback language, preferred coach personality/voice; COACH-02 durable learning memory: top error categories, recurring grammar patterns, frequently mispronounced words khi acoustic evidence đủ, vocabulary gaps, pace/hesitation trends, scenario strengths, study consistency. COACH-03 after session: 3 ưu tiên cải thiện, 1 micro-drill 3–5 phút, model answer và exercise queue. COACH-04 weekly review: điểm tốt lên/xuống cùng kích thước mẫu, recommendation và next-week plan. COACH-05 spaced revisit: lặp lại lỗi cũ sau 1/3/7 ngày (lịch đề xuất), kiểm tra mastery bằng nhiệm vụ nói mới. COACH-06 memory controls: người dùng xem, chỉnh mục tiêu, tắt memory personalization, xóa lịch sử/audio theo chính sách.
Decision engine: weighted weakness priority = recurrence × learning impact × recency × confidence; score giảm do sample thiếu dữ liệu không được coi là người học yếu đi. Một người chỉ có 1–3 trọng tâm/tuần để tránh overload. Rules engine deterministic chọn drill và goals; LLM chỉ giải thích và soạn ví dụ, không tự thay đổi level/ownership/điểm lịch sử. Coach summary được cập nhật sau successful session completion, lưu revision, source session IDs và timestamp.
PHỤ LỤC B — UI/UX DESIGN SYSTEM VÀ CHI TIẾT TỪNG PAGE
B1. Design direction / visual identity
Phong cách: modern, warm, trustworthy, mobile-first, coaching-oriented; không nhồi nhiều hiệu ứng game. Brand colors đề xuất: Primary Indigo #4F46E5; Accent Teal #0D9488; Secondary Light #EEF2FF; Background #F8FAFC; Surface #FFFFFF; Text #0F172A; Muted #64748B; Success #16A34A; Warning #D97706; Error #DC2626. Dark mode token riêng, không chỉ đảo màu. Typography UI: Inter hoặc SF Pro/Roboto theo OS, headline 24–28sp semibold, section 18–20sp, body 14–16sp, supporting 12–13sp; scale theo textScaleFactor. Times New Roman 13/14–16 chỉ áp dụng tài liệu planning, không áp đặt cho UI app.
Layout tokens: 8pt grid, page horizontal padding 20–24dp, card radius 16–20, input radius 12–14, button height min 48–52dp, touch target ≥44–48dp, subtle shadows, consistent icon family (Lucide/Material Symbols), bottom nav 4–5 tabs, max content width 480dp trên điện thoại, responsive cho tablet. Hiển thị progress bằng chart dễ đọc, hạn chế gradient quá nhiều. Motion 150–250ms transitions, 200–350ms microinteraction, support reduce motion. Accessibility: WCAG AA contrast mục tiêu, label cho control, haptic optional, semantics, focus order, text scaling.
B2. Sitemap / điều hướng chính
Khởi động: Splash/Auth Gate → Welcome → Sign In/Sign Up/Forgot Password → Onboarding Goal → Level Placement → Permission Explainer → Home. Bottom Nav: Home | Practice | Progress | Coach | Profile. Nested routes: /practice/scenarios, /practice/scenario/:id, /practice/voice, /practice/text, /practice/session/:id/summary, /progress/history, /progress/report/:id, /coach/plan, /coach/drill/:id, /profile/settings. Deep link phải qua AuthGuard.
B3. Screen 01 — Splash / Session Restoration
Mục tiêu: nhận diện thương hiệu, khôi phục session an toàn. Thành phần: logo, app name, tagline 'Speak with confidence', loading indicator nhỏ. Logic: không nháy màn hình login khi còn session; timeout xử lý retry, offline banner, routing đúng theo trạng thái onboarding. States: loading, signed-in, signed-out, network-error, migration-needed.
B4. Screen 02 — Welcome / Introduction
Hero illustration đơn giản (voice waveform + coach abstract), 3 lợi ích (Practice real conversations, Get personalized feedback, Track your growth), primary CTA 'Bắt đầu', secondary 'Tôi đã có tài khoản', note quyền riêng tư. Carousel tối đa 3 trang, Skip rõ ràng, CTA sticky bottom.
B5. Screen 03 — Sign In / Sign Up / Password Recovery
Header chào mừng, email/password fields, show/hide password, password requirement helper, validation inline, primary sign in button, forgot password, sign-up link; OAuth optional nếu thiết lập. Loading disabled double-submit; show human-readable errors; keyboard-safe layout; terms/privacy checkbox đúng policy. Đăng nhập thành công đi thẳng Home nếu đã onboarding. Người dùng không phải đăng nhập lại mỗi lần mở app.
B6. Screen 04 — Goal & Personalization Onboarding
Progress stepper 1/3, multi-select mục tiêu (Daily, Work, Travel, IELTS, Interview), chọn thời gian 5/10/15/20 phút mỗi ngày, topic interests, preferred feedback language, coach voice preference và permission explanation. Cho phép 'Để sau'; defaults rõ ràng, lưu vào profile, có Edit sau này.
B7. Screen 05 — Level Placement
Stepper 2/3: self-assessment A0–C2 với giải thích dễ hiểu → 2–3 câu hỏi speaking theo level tăng dần → playback + transcript check → estimated level và confidence, mục tiêu đề xuất. Cho phép skip để bắt đầu ở A1 rồi placement lại. Không gán band IELTS chắc chắn từ vài câu. Thiết kế card level + ví dụ task + progress bar, nút 'Làm lại bài kiểm tra' có giới hạn hợp lý.
B8. Screen 06 — Home Dashboard
Top greeting theo thời điểm, avatar và notifications; hero 'Continue your speaking journey' + CTA 'Start Speaking'; streak, today goal minutes, weekly speaking time; card 'Your next best lesson' dựa trên weakness; quick actions Ask AI, Roleplay, Realtime Call; micro insight 'Bạn đã cải thiện...' có bằng chứng; recommended scenario horizontal list; recent session và resume nếu session còn hợp lệ. Loading skeleton, empty new user state, pull to refresh; bottom nav persistent.
B9. Screen 07 — Practice Hub / Mode Selection
3 hero cards: Ask & Listen (text question → AI voice reply), Guided Speaking (từng lượt, phù hợp người mới), Realtime Conversation (gọi trực tiếp tự nhiên); filter level, topic, time (3/5/10/15 phút), intent (free talk, interview, IELTS-style); show microphone/headphone requirements and network indicator. Mỗi card: icon, duration, benefit, primary CTA, tag recommendation.
B10. Screen 08 — Topic & Scenario Catalog
Search/filter chips theo level A0–C2, goal, difficulty, estimated duration; scenario cards có title, practical goal, role, sample phrase, lock status (nếu có); tabs Popular/Recommended/All; bookmarks. Empty and no-match states với clear filters. Nội dung phải cập nhật metadata qua backend, không hardcode cả catalogue trong Flutter.
B11. Screen 09 — Scenario Detail / Session Setup
Hero topic illustration, scenario description, roles (AI = receptionist, user = guest), learning outcomes (3 bullets), vocabulary preview, expected duration, current level, voice choice/speaking speed, captions toggle, session mode, audio consent và mic test. CTA 'Start Conversation'; nếu realtime chưa hỗ trợ trên thiết bị, giải thích và fallback Guided Mode.
B12. Screen 10 — Ask AI by Text, Hear AI Reply
Modern messaging page với message bubbles, composer multiline và Send, option language, AI reply text bubble + embedded player waveform, Play/Pause/Replay, speed button, transcript toggle, share/copy phrase, optional 'Try saying this'. Header coach avatar, level, back, menu. AI có thể hỏi tiếp bằng giọng nói, người dùng bấm micro để chuyển sang speaking. Loading trạng thái 'AI is thinking/speaking', prevent duplicate submits; connection loss cho retry message idempotent.
B13. Screen 11 — Guided Speaking Session
Header session topic/time/progress; AI question card lớn + animated coach avatar nhẹ + subtitle; mic button lớn 'Tap to speak' / 'Stop'; listening waveform; pause/playback own recording (tuỳ consent); transcript editable only as correction annotation, original recognized transcript preserved; hint/translate/repeat question; feedback quick chip (Great / Try again) không gây ngắt mạch. State machine: idle → aiSpeaking → waitingForUser → recording → transcribing → generating → aiSpeaking / recoverableError → ended.
B14. Screen 12 — Realtime Voice Conversation
Call-style immersive dark/indigo surface, dynamic waveform AI và user riêng, live captions toggle, status Listening/AI speaking/Reconnecting, timer, active level/topic badge, bottom actions Mute, Captions, Switch mode (nếu safe), End call prominent red. Hoạt ảnh theo amplitude không gây chóng mặt, safe area cho notch. Người học có thể ngắt lời AI theo khả năng session; Bluetooth/headset route handling, echo cancellation, interruption từ điện thoại, permission revocation, poor network, reconnect. Không hiển thị IELTS band realtime gây phân tâm. Trước vào call có preflight network/mic; khi end tạo session report async có trạng thái Processing; nếu scoring thất bại vẫn giữ transcript hợp lệ.
B15. Screen 13 — Session Summary / Speaking Score
Hero 'You completed X minutes', number of turns, total learner talk time; estimated speaking overview card (không dùng 'Official IELTS'), 4-axis rubric chart fluency, lexical, grammar, pronunciation với confidence/n/a; 3 strengths và 3 improvements tối đa; timeline transcript evidence click to play timestamp (nếu audio retained); expandable corrections Before → After → Why in Vietnamese; CTA 'Practice my weakness', 'Save phrases', 'Next lesson', 'Retake'; show assessment limitations and rubric version. Error state partial report và regenerate nếu được.
B16. Screen 14 — Progress Analytics
Segmented Weekly/Monthly/All Time, line chart speaking practice minutes, cards active days/total sessions/goal completion; rubric trend theo cùng version hoặc version alignment, level timeline, topic competency heatmap, top errors trend; filter level/assessment type. Empty first-week state kèm CTA; biểu đồ có alt summary, trục và chú thích, không dùng điểm thiếu dữ liệu để vẽ thành 0.
B17. Screen 15 — Session History / Detail
Danh sách phiên theo ngày, mode, scenario, duration, completion, estimated score có confidence; sort/filter, click mở bản transcript theo lượt, AI audio nếu được lưu, corrections, pinned phrases; search transcripts có giới hạn privacy, pagination. Action delete/export khi được hỗ trợ; xác nhận xóa và cảnh báo không khôi phục.
B18. Screen 16 — Personal AI Coach Dashboard
Coach avatar/name, greeting cá nhân, 'Your 3 focus areas this week', mức ưu tiên, evidence ('lặp thì quá khứ 4/6 phiên'), kế hoạch tuần dưới dạng checklist, recommended drills, progress since last review, encouragement không phán xét. Card 'Why this recommendation?' giải thích quyết định từ lỗi và thành tích, 'Change goal', 'Review memory'. Không hiển thị thông tin phỏng đoán như sự thật.
B19. Screen 17 — Corrective Drill Player
Micro exercise types: listen-repeat, shadowing, reorder sentence, targeted roleplay, answer with target structure, minimal-pair pronunciation chỉ khi có acoustic scorer. Layout: one objective, sample audio, learner recording, immediate evidence-based feedback, attempts, mastery indicator, retry. Drills 3–5 phút; adaptive difficulty nhưng user skip được; results sync vào mastery record.
B20. Screen 18 — Weekly Learning Plan
7-day timeline with day cards (goal, estimated minutes, scenario/drill), status Planned/Done/Skipped, 'Adjust schedule', progress rings, weak points goal and target. Weekly review summary: top gains, still struggling, next best action. Notifications opt-in; time windows follow user's timezone; no shame messaging after missed days.
B21. Screen 19 — Vocabulary & Saved Expressions
Saved phrases grouped by scenario/error/topic, search, word definition Vietnamese, IPA optional and audio pronunciation, example sentence, bookmark; actions Speak this phrase / Mark mastered / Remove; spaced repetition queue. Empty state actionable. Avoid treating a repeated word alone as speaking improvement.
B22. Screen 20 — Profile / Settings / Privacy
Profile: avatar, display name, current estimated level, goals, achievements without deceptive certificates. Settings sections: account, voice/accent/speed, native language/subtitle, daily reminders, mic/accessibility, data & privacy (recording consent, audio retention, export/delete requests, personalization memory), notification, theme, app version, help, logout. Account delete flow with reauthentication/confirmation when applicable; clear account deletion and data retention notice.
B23. Shared widgets, UI state và quality bar
Reusable components: PrimaryButton, SecondaryButton, LoadingButton, AppTextField, VoiceWaveform, AudioPlayerBar, LevelChip, RecommendationCard, ScoreAxisCard, ChartLegend, EmptyState, ErrorState, ShimmerLoading, PermissionRationale, ConfirmSheet, Toast. Tất cả screens có loading/empty/offline/permission-denied/unauthorized/error/success state phù hợp. Thiết kế Figma: design tokens → components → wireframe low-fi → high-fi → clickable prototype → handoff specs → Flutter golden tests. Tiêu chí nghiệm thu UI: Pixel-consistent theo tokens, không overflow 320dp width hoặc text scale 200%, an toàn keyboard/bottom insets, interactive state & semantics đủ, animation tắt theo reduce-motion.
PHỤ LỤC C — THIẾT KẾ REALTIME, LEARNING MEMORY VÀ DATA
C1. Realtime audio architecture (production-minded)
Control plane: Flutter → Spring Boot REST (create session, authorize, load scenario/level, set quota, issue short-lived session bootstrap credential) → DB. Media plane lựa chọn sau PoC: Flutter → Gemini Live qua ephemeral token giới hạn nếu Gemini client transport đáp ứng yêu cầu mobile, HOẶC Flutter → Java media gateway → provider khi cần enforce controls/transform audio. Không gửi long-lived Gemini API key tới app. Backend nhận session events/usage/transcript summaries và thực hiện server-side post-session score. Nếu voice path trực tiếp provider, phải có cơ chế giới hạn session/chi phí và server reconciliation, tránh tin client gửi score. REST fallback turn-based khi Live lỗi, provider unavailable, hoặc mạng kém.
Realtime pipeline: preflight auth/mic → create voice session → select scenario context and coach policy → start streaming input PCM chunks (codec/rate per API current spec) → provider VAD/turn detection → receive audio reply chunks + optional transcriptions → play using jitter buffer/audio focus → user barge-in/interrupt as supported → periodic checkpoint text/events → end session → scoring job → coach memory update. Do not stream raw audio into logs; audio storage only with consent. Flutter states: connecting, connected-listening, speaking-user, thinking, speaking-ai, reconnecting, ending, ended, failed. QA: network drop, app background, phone calls, headphones, denied permission, zero audio, unsupported device.
C2. Database schema additions (Flyway)
learner_assessments(id, user_id, assessment_type, source_session_id nullable, rubric_version, language_level_estimate, overall_estimated_band nullable, confidence, limitations jsonb, created_at). assessment_dimensions(id, assessment_id, dimension enum, estimated_band nullable, evidence jsonb, confidence, scorer_provider, scorer_version). learning_goals(id,user_id,goal_type,target_level,minutes_daily,deadline nullable,active). learner_skill_profiles(id,user_id,skill_key,ability_estimate,confidence,sample_count,updated_at). learner_weaknesses(id,user_id,category,description,evidence_session_ids jsonb,recurrence,impact,confidence,status,last_observed_at). coach_memories(id,user_id,memory_type,summary,source_session_ids jsonb,confidence,version,active,updated_at). learning_plans(id,user_id,week_start,goals jsonb,status,created_at). learning_plan_items(id,plan_id,day,activity_type,reference_id,status,minutes_estimate). remedial_drills(id,weakness_category,level,task_type,content jsonb,rubric_version,active). drill_attempts(id,user_id,drill_id,session_id nullable,outcome,score,feedback jsonb,created_at). voice_sessions(id,session_id unique,provider,provider_session_ref,connection_state,started_at,ended_at,network_metrics jsonb). audio_assets(id,user_id,session_id,object_path,consent_version,delete_after,created_at). user_privacy_preferences(user_id,save_audio,personalization_enabled,retention_days,updated_at).
DB rules: user_id indexed, ownership enforced and RLS where supported; immutable score assessment revisions; use migration with safe default and backfill; avoid storing raw customer prompt/audio by default. Summary AI memory phải có lineage tới phiên thật và soft-hide/delete cùng dữ liệu nguồn theo policy. Realtime chunks không ghi từng packet DB; save only meaningful events/aggregate metrics. Không biến JSONB thành nơi chứa toàn bộ data có quan hệ ổn định.
C3. API contracts / backend modules bổ sung
POST /api/v1/placement/start; POST /api/v1/placement/{id}/submit; GET /api/v1/placement/latest; POST /api/v1/voice-sessions; POST /api/v1/voice-sessions/{id}/complete; GET /api/v1/voice-sessions/{id}/status; POST /api/v1/coach/ask; GET /api/v1/coach/dashboard; GET /api/v1/coach/memory; PATCH /api/v1/coach/preferences; GET /api/v1/learning-plans/current; PATCH /api/v1/learning-plans/items/{id}; GET /api/v1/drills/recommended; POST /api/v1/drills/{id}/attempts; GET /api/v1/assessments/{id}; GET /api/v1/progress/skills; PATCH /api/v1/privacy/preferences. Realtime session credentials returned only via authorized endpoint with short TTL and scoped privileges.
Backend modules new: realtime/, assessment/, learning/, personalization/, exercises/, privacy/. Async pipeline: sessionCompleted event → scoring job → persist assessment (idempotent) → update weakness profile → regenerate weekly plan if needed → notification ready. Use transaction/outbox pattern when reliability demands; do not block voice hangup waiting for AI full evaluation. Every scoring artifact carries rubricVersion, modelId, input completeness and confidence.
C4. Personalization safety and transparency
Learning memory is scoped per user; learner can view summary and clear coach personalization. Never claim persistent 'memory' is an unrestricted store of all chats; stored preferences, recurring weaknesses and summaries are explicitly modeled. Encourage consistent learning but avoid guilt-based dark patterns. Disable user audio retention by default until explicit consent; explain AI provider handling separately. Provide account data access/deletion plan and retention audit, especially for voice.
PHỤ LỤC D — ROADMAP THAY THẾ: PHÁT HÀNH CÓ REALTIME NGAY V1
Giả định revised timeline: 24–28 tuần với 3–5 người, sprint 2 tuần; realtime audio + acoustic scoring có rủi ro kỹ thuật cao. Nếu deadline cứng 16 tuần, phải giảm scope hoặc tách beta, không hứa đủ mọi tính năng ở mức production. Mỗi phiên bản có release gate, test evidence, UI implementation, backend/API, migration và demo recording.
v0.1.0 Foundation + Design System (Weeks 1–3)
Deliver: Flutter app skeleton, theme/token library, component catalog, Riverpod/router, Java modules scaffold, Supabase dev/staging, architecture/ERD, Figma wireframes for 20 screens, CI, secret policy. Acceptance: design tokens implemented, app navigation shell works, API health and DB migrations run, build pipeline green.
v0.2.0 Persistent Authentication + Onboarding (Weeks 4–5)
Deliver: Supabase Auth, secure persisted session, refresh/auth guard, signup/login/forgot password, goals and daily minutes, level selection, profile API. Acceptance: close/reopen app remains signed in while session valid; expired/revoked sign-in correctly redirects; auth stream network errors handled; IDOR test passes.
v0.3.0 Placement + Level Curriculum (Weeks 6–8)
Deliver: A0–C2 learning taxonomy, placement wizard, 4+ topic groups, scenario catalog, metadata and seed files, baseline skill profile; placement excludes unsupported official certification claims. Acceptance: representative tasks cover all levels; user can choose suggested or manual level; recommendations explain why.
v0.4.0 Text-to-Voice AI Tutor (Weeks 9–10)
Deliver: ask-by-text UI, AI response text/audio with intonation from TTS or voice-capable provider, subtitles, playback speed, reply follow-up, event logging; Java AI provider adapter and quota. Acceptance: user typed question → AI spoken response → user can replay, network retry does not double-charge or double-message.
v0.5.0 Guided Speaking + Audio Pipeline (Weeks 11–13)
Deliver: turn-based voice UI, recording, STT, TTS, transcript verification, player and mic states; audio consent, timeout and permission fallback. Acceptance: device test speak → transcript → AI voice reply; no audio saved when consent denied; error states use clear recovery actions.
v0.6.0 Realtime Voice Beta (Weeks 14–17)
Deliver: provider spike/benchmark → ADR transport choice → short-lived token gateway → live two-way audio, VAD, user interruption where supported, reconnect, captions, audio focus, quota enforcement. Acceptance: scripted 30-call test across wifi/mobile network with result table for latency, failures, cost, provider constraints; realtime graceful fallback to guided speaking.
v0.7.0 IELTS-inspired Scoring & Evidence (Weeks 18–20)
Deliver: 4-axis scorecard, correction explainers, pronunciation engine evaluation, sample-based calibration, confidence and 'N/A', assessment history, rubric version tracking. Acceptance: test scores never presented as official; text-only sample has no invented pronunciation score; human review set and agreement metrics documented.
v0.8.0 Personal Coach + Remediation (Weeks 21–23)
Deliver: weakness detection, durable scoped coach memories, drill generation/templates, weekly plan and revision, progress/skill chart, trend chart and vocabulary review. Acceptance: recurring mistakes map to specific exercise; learner can explain why recommendation was generated, update goal, remove memory and audit source sessions.
v0.9.0 Pilot + Security + Polish (Weeks 24–26)
Deliver: UI accessibility/golden tests, signed audio consent and retention, GDPR/local-law review as appropriate, load/cost tests, end-to-end pilot, cleanup of P0/P1 issues, store assets and documentation. Acceptance: ≥ 90% UAT scenario pass target, zero open blocker, usable offline/error states, cost per typical learner session measured.
v1.0.0 Academic Release (Weeks 27–28)
Deliver: version-tagged Android package, optional iOS build, deployment and monitoring, user manual, ERD/API/architecture diagrams, 3 video demonstrations (text-to-voice, realtime, personal coach), test evidence and release notes. Gate: checklist signed off; do not call beta realtime feature production-ready if tested requirements fail.
PHỤ LỤC E — ACCEPTANCE, AI AGENT IMPLEMENTATION RULES, UPDATE LOG
E1. End-to-end acceptance scenarios
UAT-01 registered user closes and reopens app 3 times over multiple launches → arrives Home without password re-entry if session valid. UAT-02 input 'How should I introduce myself?' → AI replies audibly with matching readable text → replay and slow playback work. UAT-03 beginner practice → AI questions pitched to selected level; errors explained in Vietnamese at end. UAT-04 realtime two-way call → audio captured and returned continuously with clear microphone status; disconnect handled; session ends cleanly. UAT-05 speaking sample → 4 scoring axes with provenance/confidence; missing acoustic data → pronunciation N/A. UAT-06 repeat grammar mistakes across ≥3 sessions → coach identifies recurring weakness and assigns drill; after drill shows evidence of improvement or persistent weakness. UAT-07 cross-account requests cannot access history/memory/audio. UAT-08 consent denied → no retained user audio. UAT-09 low end Android 320dp and 200% font scale → no blocked critical actions.
E2. Mandatory agent rules for new features
AGENT-11 Use revised roadmap v0.1–v1.0 in Appendix D; original section 6 is superseded. AGENT-12 Design all 20 screens listed in Appendix B, do not invent extra top-level tabs without an ADR. AGENT-13 Every UI PR references screen ID, states, token system, accessibility and screenshot/golden test. AGENT-14 Persistent auth must await restoration; never implement 'remember me' as plaintext credentials. AGENT-15 Realtime voice requires measurable transport/design spike before selection and short-lived credentials only. AGENT-16 Scoring claims require acoustic evidence for pronunciation and proper limitations; never display official IELTS claim. AGENT-17 Coach suggestions must trace back to session evidence and user controls. AGENT-18 API schema/migrations and prompt contracts updated ahead of client implementation. AGENT-19 Every model/provider must be configurable and benchmarked against quality/latency/cost. AGENT-20 If requirements conflict, cite this appendix and file a decision record, do not silently alter scope.
E3. Revised change log / source links
Plan v1.1.0 | 14/10/2026 | Added detailed 20-page UX specifications, auth session persistence, typed question to spoken reply, real-time voice beta in committed release path, CEFR-aligned tiers with A0 informal, IELTS-inspired multi-axis feedback, adaptive memory and corrective drills, extended database/API and updated 28-week release plan. Status: proposal awaiting PO approval.
Technical validation: Supabase Flutter session persistence https://github.com/supabase/supabase-flutter/blob/main/packages/supabase_flutter/README.md ; auth events https://supabase.com/docs/reference/dart/auth-onauthstatechange ; Gemini Live ephemeral auth https://ai.google.dev/api/live ; IELTS Speaking assessment criteria https://takeielts.britishcouncil.org/sites/default/files/ielts_speaking_band_descriptors.pdf . Provider model/prices and platform SDK API must be revalidated at relevant sprint. END REVISED PRODUCT BASELINE.
