-- V3__seed_topics_and_scenarios.sql
-- Curriculum catalog: Topics and Scenarios tables with initial seed data
-- Compliant with ESP-PLAN-001 Stage 3 & API_CONTRACT.yaml

CREATE TABLE IF NOT EXISTS topics (
    id UUID PRIMARY KEY,
    slug VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS scenarios (
    id UUID PRIMARY KEY,
    topic_id UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    role_ai VARCHAR(100) NOT NULL,
    role_user VARCHAR(100) NOT NULL,
    learning_objectives TEXT NOT NULL DEFAULT '[]',
    estimated_minutes INT NOT NULL DEFAULT 10,
    sample_phrases TEXT NOT NULL DEFAULT '[]',
    vocabulary_preview TEXT NOT NULL DEFAULT '[]',
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_scenarios_level CHECK (level IN ('A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    CONSTRAINT chk_scenarios_minutes CHECK (estimated_minutes > 0)
);

CREATE INDEX IF NOT EXISTS idx_scenarios_topic_id ON scenarios(topic_id);
CREATE INDEX IF NOT EXISTS idx_scenarios_level ON scenarios(level);
CREATE INDEX IF NOT EXISTS idx_scenarios_active ON scenarios(active);

-- Seed 4 required Topic groups
INSERT INTO topics (id, slug, title) VALUES
('11111111-1111-1111-1111-111111111001', 'introduction', 'Làm quen & Giới thiệu'),
('11111111-1111-1111-1111-111111111002', 'daily_life', 'Đời sống thường nhật'),
('11111111-1111-1111-1111-111111111003', 'travel', 'Du lịch & Khách sạn'),
('11111111-1111-1111-1111-111111111004', 'work', 'Công việc & Phỏng vấn')
ON CONFLICT (id) DO NOTHING;

-- Seed at least 12 Scenarios across all 4 topics
INSERT INTO scenarios (
    id, topic_id, level, title, description, role_ai, role_user,
    learning_objectives, estimated_minutes, sample_phrases, vocabulary_preview, active
) VALUES
-- 1. Introduction - A0/A1
(
    '22222222-2222-2222-2222-222222222001',
    '11111111-1111-1111-1111-111111111001',
    'A1',
    'Lần đầu gặp gỡ bạn mới',
    'Luyện tập các câu chào hỏi căn bản, hỏi tên, quốc tịch và nghề nghiệp trong lần đầu gặp gỡ.',
    'Bạn cùng lớp mới (Alex)',
    'Học viên mới',
    '["Biết chào hỏi lịch sự", "Giới thiệu tên và quê quán", "Hỏi lại đối phương"]',
    10,
    '["Hi, nice to meet you!", "Where are you from?", "I come from Vietnam."]',
    '[{"phrase":"nice to meet you","meaningVi":"rất vui được gặp bạn","ipa":"/naɪs tuː miːt juː/"},{"phrase":"hometown","meaningVi":"quê hương","ipa":"/ˈhəʊm.taʊn/"}]',
    true
),
-- 2. Introduction - A2
(
    '22222222-2222-2222-2222-222222222002',
    '11111111-1111-1111-1111-111111111001',
    'A2',
    'Giới thiệu bản thân và sở thích',
    'Trò chuyện về sở thích cá nhân, các hoạt động cuối tuần và thời gian rảnh rỗi.',
    'Người dẫn chương trình CLB (Sarah)',
    'Thành viên câu lạc bộ',
    '["Mô tả hoạt động giải trí", "Bày tỏ mức độ yêu thích", "Sử dụng thì hiện tại đơn"]',
    12,
    '["In my free time, I enjoy reading.", "I usually play badminton on weekends."]',
    '[{"phrase":"free time","meaningVi":"thời gian rảnh","ipa":"/friː taɪm/"},{"phrase":"keen on","meaningVi":"say mê","ipa":"/kiːn ɒn/"}]',
    true
),
-- 3. Introduction - B1
(
    '22222222-2222-2222-2222-222222222003',
    '11111111-1111-1111-1111-111111111001',
    'B1',
    'Networking tại sự kiện công nghệ',
    'Giao lưu chuyên môn với các kỹ sư quốc tế tại hội thảo công nghệ thông tin.',
    'Kỹ sư phần mềm đối tác (David)',
    'Kỹ sư tham dự hội thảo',
    '["Giới thiệu dự án hiện tại", "Trao đổi công nghệ sử dụng", "Mời kết nối LinkedIn"]',
    15,
    '["What tech stack is your team using?", "Let us stay in touch on LinkedIn."]',
    '[{"phrase":"tech stack","meaningVi":"hệ thống công nghệ","ipa":"/tɛk stæk/"},{"phrase":"scalable","meaningVi":"có khả năng mở rộng","ipa":"/ˈskeɪ.lə.bəl/"}]',
    true
),
-- 4. Daily Life - A1
(
    '22222222-2222-2222-2222-222222222004',
    '11111111-1111-1111-1111-111111111002',
    'A1',
    'Gọi món tại quán cà phê',
    'Thực hành gọi đồ uống, chọn kích cỡ và thanh toán tại quầy gọi món.',
    'Nhân viên pha chế (Barista Tom)',
    'Khách mua cà phê',
    '["Gọi đồ uống theo size", "Yêu cầu lượng đường/đá", "Hỏi giá và thanh toán"]',
    8,
    '["Can I have an iced latte, please?", "Less sugar and regular ice, please."]',
    '[{"phrase":"take away","meaningVi":"mang đi","ipa":"/ˈteɪk.ə.weɪ/"},{"phrase":"receipt","meaningVi":"hóa đơn","ipa":"/rɪˈsiːt/"}]',
    true
),
-- 5. Daily Life - A2
(
    '22222222-2222-2222-2222-222222222005',
    '11111111-1111-1111-1111-111111111002',
    'A2',
    'Mua sắm tại siêu thị địa phương',
    'Tìm kiếm sản phẩm, hỏi vị trí các gian hàng và hỏi về chính sách giảm giá.',
    'Thu ngân siêu thị (Emma)',
    'Người mua sắm',
    '["Hỏi đường đến gian hàng thực phẩm", "Hỏi hạn sử dụng", "Sử dụng thẻ thành viên"]',
    10,
    '["Where can I find organic milk?", "Do you accept card payment?"]',
    '[{"phrase":"aisle","meaningVi":"lối đi giữa các quầy","ipa":"/aɪl/"},{"phrase":"discount","meaningVi":"chiết khấu, giảm giá","ipa":"/ˈdɪs.kaʊnt/"}]',
    true
),
-- 6. Daily Life - B1
(
    '22222222-2222-2222-2222-222222222006',
    '11111111-1111-1111-1111-111111111002',
    'B1',
    'Thương lượng sửa chữa đồ gia dụng',
    'Mô tả sự cố rò rỉ nước trong căn hộ và hẹn giờ thợ kỹ thuật đến kiểm tra.',
    'Thợ bảo trì chung cư (Robert)',
    'Chủ căn hộ',
    '["Mô tả chính xác vấn đề hỏng hóc", "Thương lượng chi phí và thời gian", "Xác nhận lịch hẹn"]',
    12,
    '["There is a leak under the kitchen sink.", "Can you send someone this afternoon?"]',
    '[{"phrase":"leakage","meaningVi":"sự rò rỉ","ipa":"/ˈliː.kɪdʒ/"},{"phrase":"estimate","meaningVi":"bản dự toán","ipa":"/ˈes.tɪ.meɪt/"}]',
    true
),
-- 7. Travel - A1
(
    '22222222-2222-2222-2222-222222222007',
    '11111111-1111-1111-1111-111111111003',
    'A1',
    'Hỏi đường đến nhà ga trung tâm',
    'Hỏi hướng đi, khoảng cách và phương tiện công cộng phù hợp để đến ga.',
    'Cảnh sát khu vực (Officer John)',
    'Khách du lịch đi bộ',
    '["Sử dụng từ chỉ phương hướng", "Hỏi khoảng cách và thời gian đi bộ", "Cảm ơn lịch sự"]',
    8,
    '["Excuse me, how do I get to the central station?", "Is it within walking distance?"]',
    '[{"phrase":"turn left","meaningVi":"rẽ trái","ipa":"/tɜːn lɛft/"},{"phrase":"crossroad","meaningVi":"ngã tư","ipa":"/ˈkrɒs.rəʊd/"}]',
    true
),
-- 8. Travel - A2
(
    '22222222-2222-2222-2222-222222222008',
    '11111111-1111-1111-1111-111111111003',
    'A2',
    'Làm thủ tục nhận phòng khách sạn',
    'Xác nhận thông tin đặt phòng, yêu cầu tầng cao và hỏi về mật khẩu Wi-Fi.',
    'Lễ tân khách sạn (Anna)',
    'Khách lưu trú',
    '["Cung cấp mã đặt phòng", "Yêu cầu phòng không hút thuốc", "Hỏi giờ phục vụ bữa sáng"]',
    10,
    '["I have a reservation under the name Le.", "Could I have a quiet room on a high floor?"]',
    '[{"phrase":"check-in","meaningVi":"nhận phòng","ipa":"/ˈtʃɛk.ɪn/"},{"phrase":"complimentary breakfast","meaningVi":"bữa sáng miễn phí","ipa":"/ˌkɒm.plɪˈmɛn.tər.i ˈbrɛk.fəst/"}]',
    true
),
-- 9. Travel - B2
(
    '22222222-2222-2222-2222-222222222009',
    '11111111-1111-1111-1111-111111111003',
    'B2',
    'Báo thất lạc hành lý tại sân bay',
    'Trình bày chi tiết về kiện hành lý bị thất lạc, mô tả đặc điểm và yêu cầu giao hàng tận nơi.',
    'Nhân viên hành lý thất lạc (Agent Miller)',
    'Hành khách bay quốc tế',
    '["Mô tả kích thước, màu sắc, nhãn hiệu hành lý", "Điền thông tin Property Irregularity Report", "Yêu cầu bồi thường khẩn cấp"]',
    15,
    '["My baggage did not appear on carousel number 4.", "It is a navy hard-shell Samsonite suitcase."]',
    '[{"phrase":"carousel","meaningVi":"băng chuyền hành lý","ipa":"/ˌkær.əˈsɛl/"},{"phrase":"hard-shell suitcase","meaningVi":"vali vỏ cứng","ipa":"/hɑːd ʃɛl ˈsuːt.keɪs/"}]',
    true
),
-- 10. Work - A2
(
    '22222222-2222-2222-2222-222222222010',
    '11111111-1111-1111-1111-111111111004',
    'A2',
    'Chào hỏi đồng nghiệp ngày đầu đi làm',
    'Giới thiệu bản thân ngắn gọn với các thành viên trong nhóm và làm quen môi trường làm việc.',
    'Trưởng nhóm hướng dẫn (Leader Michael)',
    'Nhân viên mới gia nhập',
    '["Giới thiệu tên và vị trí công tác", "Bày tỏ sự hào hứng", "Hỏi vị trí các khu vực tiện ích"]',
    10,
    '["Today is my first day on the engineering team.", "I am looking forward to working with everyone."]',
    '[{"phrase":"onboarding","meaningVi":"quy trình hội nhập nhân viên mới","ipa":"/ˈɒnˌbɔː.dɪŋ/"},{"phrase":"colleague","meaningVi":"đồng nghiệp","ipa":"/ˈkɒl.iːɡ/"}]',
    true
),
-- 11. Work - B1
(
    '22222222-2222-2222-2222-222222222011',
    '11111111-1111-1111-1111-111111111004',
    'B1',
    'Báo cáo tiến độ công việc hàng tuần',
    'Trình bày các hạng mục đã hoàn thành, các rào cản kỹ thuật và kế hoạch tuần kế tiếp trong họp Sprint.',
    'Quản lý dự án (Project Manager Lisa)',
    'Kỹ sư phụ trách tính năng',
    '["Tóm tắt đầu việc hoàn thành", "Giải thích nguyên nhân chậm trễ", "Đề xuất giải pháp khắc phục"]',
    15,
    '["We completed the authentication migration yesterday.", "There is a slight blocker with the upstream API."]',
    '[{"phrase":"standup meeting","meaningVi":"cuộc họp nhanh hàng ngày","ipa":"/ˈstænd.ʌp ˈmiː.tɪŋ/"},{"phrase":"bottleneck","meaningVi":"điểm nghẽn tiến độ","ipa":"/ˈbɒt.əl.nɛk/"}]',
    true
),
-- 12. Work - B2
(
    '22222222-2222-2222-2222-222222222012',
    '11111111-1111-1111-1111-111111111004',
    'B2',
    'Phỏng vấn xin việc vòng văn hóa doanh nghiệp',
    'Trả lời các câu hỏi hành vi (STAR method) về giải quyết xung đột ý kiến và làm việc dưới áp lực.',
    'Giám đốc nhân sự (HR Director Karen)',
    'Ứng viên tiềm năng',
    '["Áp dụng cấu trúc STAR", "Mô tả bài học kinh nghiệm", "Đặt câu hỏi ngược cho nhà tuyển dụng"]',
    20,
    '["When faced with tight deadlines, I prioritize high-impact tasks.", "Could you share more about the team culture?"]',
    '[{"phrase":"conflict resolution","meaningVi":"giải quyết xung đột","ipa":"/ˈkɒn.flɪkt ˌrɛz.əˈluː.ʃən/"},{"phrase":"leadership principle","meaningVi":"nguyên tắc lãnh đạo","ipa":"/ˈliː.də.ʃɪp ˈprɪn.sɪ.pəl/"}]',
    true
)
ON CONFLICT (id) DO NOTHING;
