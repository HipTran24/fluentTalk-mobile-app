-- V4__seed_scenarios_a0_c1_c2.sql
-- Curriculum catalog: Additive and idempotent seed for levels A0, C1, and C2
-- Compliant with ESP-PLAN-001 Stage 3 & API_CONTRACT.yaml

INSERT INTO scenarios (
    id, topic_id, level, title, description, role_ai, role_user,
    learning_objectives, estimated_minutes, sample_phrases, vocabulary_preview, active
) VALUES
-- 1. Introduction - A0 (Absolute Beginner: Alphabet & Spelling)
(
    '22222222-2222-2222-2222-222222222013',
    '11111111-1111-1111-1111-111111111001',
    'A0',
    'Bảng chữ cái và đánh vần tên riêng',
    'Làm quen với ngữ âm cơ bản, cách đánh vần tên và các con số điện thoại đơn giản cho người mới bắt đầu.',
    'Nhân viên tiếp tân (Receptionist Emily)',
    'Học viên mới',
    '["Đánh vần từng chữ cái trong tên riêng", "Nhận biết các con số từ 0 đến 9", "Hỏi lại khi chưa nghe rõ bằng câu đơn giản"]',
    5,
    '["Could you spell your name, please?", "My name is Nam, N-A-M.", "Can you repeat that?"]',
    '[{"phrase":"spell","meaningVi":"đánh vần","ipa":"/spɛl/"},{"phrase":"repeat","meaningVi":"lặp lại","ipa":"/rɪˈpiːt/"}]',
    true
),
-- 2. Daily Life - A0 (Absolute Beginner: Numbers & Prices)
(
    '22222222-2222-2222-2222-222222222014',
    '11111111-1111-1111-1111-111111111002',
    'A0',
    'Đếm số và hỏi giá tiền đơn giản',
    'Nhận biết số đếm từ 1 đến 20 và thực hành hỏi giá tiền món đồ đơn giản tại cửa hàng tiện lợi.',
    'Thu ngân cửa hàng (Cashier John)',
    'Khách mua hàng',
    '["Đọc chính xác số đếm từ 1 đến 20", "Hỏi giá tiền cơ bản bằng How much", "Nói lời cảm ơn khi nhận hóa đơn"]',
    5,
    '["How much is this?", "It is five dollars.", "Thank you very much."]',
    '[{"phrase":"how much","meaningVi":"bao nhiêu tiền","ipa":"/haʊ mʌtʃ/"},{"phrase":"dollar","meaningVi":"đồng đô la","ipa":"/ˈdɒl.ər/"}]',
    true
),
-- 3. Travel - C1 (Effective Operational Proficiency: Baggage Policy & Document Inquiries)
(
    '22222222-2222-2222-2222-222222222015',
    '11111111-1111-1111-1111-111111111003',
    'C1',
    'Xử lý bồi thường hành lý thất lạc cao cấp',
    'Thương lượng với đại diện hãng hàng không quốc tế về việc bồi hoàn thiệt hại và chi phí phát sinh do hành lý thất lạc.',
    'Trưởng đại diện hãng hàng không (Baggage Resolution Manager Claire)',
    'Hành khách hạng thương gia',
    '["Trình bày khiếu nại về hành lý thất lạc bằng dẫn chứng rõ ràng", "Yêu cầu đại diện hãng hàng không làm rõ chính sách bồi hoàn và các chứng từ cần thiết", "Thương lượng giải pháp hỗ trợ chi phí phát sinh hợp lý trong thời gian chờ đợi"]',
    18,
    '["Could you please clarify the airline policy regarding reimbursement for essential items during baggage delay?", "Which supporting receipts and documentation do I need to submit with my claim form?"]',
    '[{"phrase":"reimbursement policy","meaningVi":"chính sách bồi hoàn chi phí","ipa":"/ˌriː.ɪmˈbɜːs.mənt ˈpɒl.ə.si/"},{"phrase":"supporting receipts","meaningVi":"hóa đơn chứng từ kèm theo","ipa":"/səˈpɔː.tɪŋ rɪˈsiːts/"}]',
    true
),
-- 4. Work - C1 (Advanced Negotiation & SLA Agreements)
(
    '22222222-2222-2222-2222-222222222016',
    '11111111-1111-1111-1111-111111111004',
    'C1',
    'Đàm phán điều khoản hợp đồng đối tác',
    'Thảo luận và thương lượng các điều khoản cam kết mức dịch vụ (SLA) và điều khoản bảo mật thông tin với đại diện pháp lý đối tác.',
    'Giám đốc pháp lý đối tác (Legal Counsel Marcus)',
    'Trưởng đoàn đàm phán doanh nghiệp',
    '["Diễn đạt điều kiện ràng buộc pháp lý chặt chẽ", "Bảo vệ lợi ích doanh nghiệp mềm mỏng nhưng kiên quyết", "Đề xuất phương án hòa giải thay thế"]',
    18,
    '["We are amenable to this clause subject to reciprocity.", "Given the liability cap, we would propose a staged warranty period."]',
    '[{"phrase":"liability cap","meaningVi":"giới hạn trách nhiệm pháp lý","ipa":"/ˌlaɪ.əˈbɪl.ə.ti kæp/"},{"phrase":"reciprocity","meaningVi":"tính hỗ tương, có qua có lại","ipa":"/ˌrɛs.ɪˈprɒs.ə.ti/"}]',
    true
),
-- 5. Work - C2 (Mastery: International Media Crisis Briefing)
(
    '22222222-2222-2222-2222-222222222017',
    '11111111-1111-1111-1111-111111111004',
    'C2',
    'Họp báo xử lý khủng hoảng truyền thông quốc tế',
    'Đại diện hội đồng quản trị trả lời các câu hỏi hóc búa từ báo chí quốc tế về sự cố gián đoạn hệ thống quy mô toàn cầu.',
    'Phóng viên điều tra trưởng (Senior Journalist Victoria)',
    'Người phát ngôn tập đoàn',
    '["Ứng biến nhanh trước các câu hỏi công kích đa chiều", "Kiểm soát ngôn từ mang sắc thái trung lập và minh bạch tuyệt đối", "Truyền tải cam kết khắc phục mà không tạo thêm rủi ro pháp lý"]',
    20,
    '["We unequivocally acknowledge the gravity of this incident.", "Our cybersecurity task force is conducting a comprehensive technical investigation without delay."]',
    '[{"phrase":"unequivocally","meaningVi":"một cách dứt khoát, minh bạch","ipa":"/ˌʌn.ɪˈkwɪv.ə.kli/"},{"phrase":"without delay","meaningVi":"ngay lập tức, không chậm trễ","ipa":"/wɪðˈaʊt dɪˈleɪ/"}]',
    true
)
ON CONFLICT (id) DO NOTHING;
