import '../../../core/models/enums.dart';
import '../../../core/models/scenario.dart';

abstract class ScenarioRepository {
  Future<List<Topic>> getTopics();
  Future<List<Scenario>> getScenarios({
    String? topicId,
    UserLevel? level,
    String? searchQuery,
    String? filterTab, // 'all', 'popular', 'recommended', 'bookmarked'
  });
  Future<Scenario?> getScenarioById(String id);
  Future<bool> toggleBookmark(String scenarioId);
}

class LocalScenarioRepository implements ScenarioRepository {
  final Set<String> _bookmarkedIds = {'sc_travel_01', 'sc_career_01'};

  final List<Topic> _topics = const [
    Topic(id: 'tp_intro', slug: 'intro', title: 'Giới thiệu & Bản thân', icon: '👋'),
    Topic(id: 'tp_daily', slug: 'daily', title: 'Đời sống hàng ngày', icon: '☕'),
    Topic(id: 'tp_travel', slug: 'travel', title: 'Du lịch & Dịch vụ', icon: '✈️'),
    Topic(id: 'tp_career', slug: 'career', title: 'Công việc & Phỏng vấn', icon: '💼'),
  ];

  late final List<Scenario> _allScenarios = [
    // --- CHỦ ĐỀ 1: GIỚI THIỆU & BẢN THÂN ---
    const Scenario(
      id: 'sc_intro_01',
      topicId: 'tp_intro',
      level: UserLevel.a0,
      title: 'Làm quen & Chào hỏi cơ bản',
      description: 'Gặp gỡ một người bạn mới tại buổi giao lưu câu lạc bộ tiếng Anh. Hãy nói lời chào, giới thiệu tên và quốc tịch của bạn.',
      roleAi: 'Thành viên câu lạc bộ',
      roleUser: 'Người tham gia mới',
      estimatedMinutes: 3,
      learningObjectives: [
        'Nói lời chào hỏi phù hợp vào các thời điểm trong ngày.',
        'Sử dụng cấu trúc "My name is..." hoặc "I am from...".',
        'Hỏi tên và quốc tịch của người đối diện bằng câu hỏi ngắn.',
      ],
      samplePhrases: [
        'Nice to meet you!',
        'I am from Vietnam.',
        'What is your name?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Nice to meet you', ipa: '/naɪs tu miːt juː/', meaningVi: 'Rất vui được gặp bạn'),
        VocabularyPreviewItem(phrase: 'Where are you from?', ipa: '/weər ɑːr ju frɒm/', meaningVi: 'Bạn đến từ đâu?'),
        VocabularyPreviewItem(phrase: 'Pleased to meet you', ipa: '/pliːzd tu miːt juː/', meaningVi: 'Hân hạnh được làm quen'),
      ],
    ),
    const Scenario(
      id: 'sc_intro_02',
      topicId: 'tp_intro',
      level: UserLevel.a1,
      title: 'Chia sẻ về sở thích lúc rảnh rỗi',
      description: 'Trò chuyện thân mật về những hoạt động bạn thích làm vào cuối tuần như nghe nhạc, đọc sách hoặc chơi thể thao.',
      roleAi: 'Bạn học cùng lớp',
      roleUser: 'Bạn thân',
      estimatedMinutes: 4,
      learningObjectives: [
        'Sử dụng động từ chỉ sở thích: "like", "love", "enjoy + V-ing".',
        'Nêu 2-3 hoạt động giải trí thường làm trong thời gian rảnh.',
        'Hỏi người bạn về sở thích âm nhạc hoặc thể thao của họ.',
      ],
      samplePhrases: [
        'In my free time, I love listening to pop music.',
        'I usually go swimming on Sundays.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Free time', ipa: '/friː taɪm/', meaningVi: 'Thời gian rảnh rỗi'),
        VocabularyPreviewItem(phrase: 'Be fond of', ipa: '/bi fɒnd əv/', meaningVi: 'Rất thích cái gì đó'),
        VocabularyPreviewItem(phrase: 'Outdoor activities', ipa: '/ˈaʊt.dɔːr ækˈtɪv.ə.tiz/', meaningVi: 'Hoạt động ngoài trời'),
      ],
    ),
    const Scenario(
      id: 'sc_intro_03',
      topicId: 'tp_intro',
      level: UserLevel.a2,
      title: 'Giới thiệu về quê hương & nơi ở',
      description: 'Mô tả ngắn gọn về thành phố nơi bạn sinh ra và sinh sống: thời tiết, con người, giao thông và món ăn đặc sản.',
      roleAi: 'Người bạn quốc tế',
      roleUser: 'Người bản xứ',
      estimatedMinutes: 5,
      learningObjectives: [
        'Sử dụng tính từ miêu tả: "peaceful", "crowded", "bustling", "famous for".',
        'Diễn đạt lý do bạn yêu thích hoặc chưa thích điều gì ở nơi bạn sống.',
        'Gợi ý một địa điểm nên ghé thăm nếu bạn bè đến chơi.',
      ],
      samplePhrases: [
        'My hometown is famous for its delicious street food.',
        'It is a bustling city with friendly people.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Hometown', ipa: '/ˈhəʊm.taʊn/', meaningVi: 'Quê hương, nơi chôn rau cắt rốn'),
        VocabularyPreviewItem(phrase: 'Famous for', ipa: '/ˈfeɪ.məs fɔːr/', meaningVi: 'Nổi tiếng về cái gì'),
        VocabularyPreviewItem(phrase: 'Bustling', ipa: '/ˈbʌs.lɪŋ/', meaningVi: 'Nhộn nhịp, hối hả, sôi động'),
      ],
    ),

    // --- CHỦ ĐỀ 2: ĐỜI SỐNG HÀNG NGÀY ---
    const Scenario(
      id: 'sc_daily_01',
      topicId: 'tp_daily',
      level: UserLevel.a1,
      title: 'Mua sắm & hỏi giá tại siêu thị',
      description: 'Bạn đang tìm một số nhu yếu phẩm tại cửa hàng tiện lợi. Hãy hỏi nhân viên vị trí quầy hàng và giá tiền sản phẩm.',
      roleAi: 'Nhân viên bán hàng',
      roleUser: 'Khách mua sắm',
      estimatedMinutes: 4,
      learningObjectives: [
        'Hỏi vị trí món đồ: "Excuse me, where can I find...?"',
        'Hỏi giá tiền: "How much is this?" hoặc "How much are these?"',
        'Nói về phương thức thanh toán tiền mặt hay chuyển khoản thẻ.',
      ],
      samplePhrases: [
        'Excuse me, where can I find the fresh milk?',
        'How much does this bottle cost?',
        'Can I pay with credit card?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Aisle', ipa: '/aɪl/', meaningVi: 'Lối đi giữa các dãy kệ hàng'),
        VocabularyPreviewItem(phrase: 'Receipt', ipa: '/rɪˈsiːt/', meaningVi: 'Biên lai, hóa đơn tính tiền'),
        VocabularyPreviewItem(phrase: 'Pay in cash', ipa: '/peɪ ɪn kæʃ/', meaningVi: 'Thanh toán bằng tiền mặt'),
      ],
    ),
    const Scenario(
      id: 'sc_daily_02',
      topicId: 'tp_daily',
      level: UserLevel.a2,
      title: 'Hẹn gặp bạn bè tại quán cà phê',
      description: 'Gọi điện cho một người bạn để thống nhất thời gian, địa điểm gặp mặt uống cà phê và thảo luận kế hoạch đi xem phim.',
      roleAi: 'Người bạn thân',
      roleUser: 'Người lên lịch hẹn',
      estimatedMinutes: 5,
      learningObjectives: [
        'Đưa ra lời mời hẹn: "Are you free this Saturday?"',
        'Đề xuất địa điểm và giờ: "How about meeting at 3 PM?"',
        'Chấp nhận hoặc điều chỉnh lại giờ hẹn cho thuận tiện đôi bên.',
      ],
      samplePhrases: [
        'Would you like to grab a cup of coffee tomorrow?',
        'That sounds great! Where should we meet?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Grab a coffee', ipa: '/ɡræb ə ˈkɒf.i/', meaningVi: 'Đi uống một cốc cà phê nhanh'),
        VocabularyPreviewItem(phrase: 'How about...', ipa: '/haʊ əˈbaʊt/', meaningVi: 'Hay là thế này... (lời gợi ý)'),
        VocabularyPreviewItem(phrase: 'Make it', ipa: '/meɪk ɪt/', meaningVi: 'Đến kịp giờ hẹn'),
      ],
    ),
    const Scenario(
      id: 'sc_daily_03',
      topicId: 'tp_daily',
      level: UserLevel.b1,
      title: 'Thói quen tập luyện & Sống khỏe',
      description: 'Thảo luận với huấn luyện viên về chế độ ăn uống, thói quen tập gym hàng tuần và cách cải thiện chất lượng giấc ngủ.',
      roleAi: 'Huấn luyện viên sức khỏe',
      roleUser: 'Hội viên phòng gym',
      estimatedMinutes: 6,
      learningObjectives: [
        'Sử dụng các trạng từ chỉ tần suất: "consistently", "rarely", "on a regular basis".',
        'Trình bày mục tiêu cá nhân: giảm mỡ, tăng cơ hoặc giải tỏa căng thẳng.',
        'Lắng nghe và phản hồi lại lời khuyên về chế độ dinh dưỡng lành mạnh.',
      ],
      samplePhrases: [
        'I try to work out three times a week to stay fit.',
        'I find it difficult to maintain a balanced diet during busy workdays.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Work out', ipa: '/wɜːk aʊt/', meaningVi: 'Tập luyện thể thao, rèn luyện thể chất'),
        VocabularyPreviewItem(phrase: 'Stay in shape', ipa: '/steɪ ɪn ʃeɪp/', meaningVi: 'Giữ vóc dáng cân đối, khỏe mạnh'),
        VocabularyPreviewItem(phrase: 'Sedentary lifestyle', ipa: '/ˈsed.ən.tər.i ˈlaɪf.staɪl/', meaningVi: 'Lối sống ít vận động, ngồi nhiều'),
      ],
    ),

    // --- CHỦ ĐỀ 3: DU LỊCH & DỊCH VỤ ---
    const Scenario(
      id: 'sc_travel_01',
      topicId: 'tp_travel',
      level: UserLevel.a2,
      title: 'Gọi món tại nhà hàng Ý',
      description: 'Bạn bước vào một nhà hàng tại Rome. Hãy hỏi nhân viên về các món đặc sản của quán và gọi một phần pasta kèm thức uống.',
      roleAi: 'Bồi bàn thân thiện',
      roleUser: 'Thực khách gọi món',
      estimatedMinutes: 5,
      learningObjectives: [
        'Hỏi bàn trống và thực đơn: "Could we have a table for two?"',
        'Sử dụng cấu trúc gọi món lịch sự: "Could I have..." hoặc "I\'d like...".',
        'Yêu cầu tính tiền hóa đơn: "Could I get the bill, please?"',
      ],
      samplePhrases: [
        'Good evening, do you have a table for two by the window?',
        'What is the specialty of the house tonight?',
        'Could I have the seafood pasta, please?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Specialty of the house', ipa: '/ˈspeʃ.əl.ti əv ðə haʊs/', meaningVi: 'Món đặc sản đặc trưng của quán'),
        VocabularyPreviewItem(phrase: 'Appetizer', ipa: '/ˈæp.ə.taɪ.zər/', meaningVi: 'Món khai vị'),
        VocabularyPreviewItem(phrase: 'Could I have the bill?', ipa: '/kʊd aɪ hæv ðə bɪl/', meaningVi: 'Làm ơn cho tôi xin hóa đơn'),
      ],
    ),
    const Scenario(
      id: 'sc_travel_02',
      topicId: 'tp_travel',
      level: UserLevel.a2,
      title: 'Thủ tục Check-in tại sân bay',
      description: 'Bạn đang làm thủ tục cho chuyến bay đi Tokyo. Hãy xuất trình hộ chiếu, gửi hành lý ký gửi và xin ghế ngồi cạnh cửa sổ.',
      roleAi: 'Nhân viên hãng hàng không',
      roleUser: 'Hành khách bay',
      estimatedMinutes: 5,
      learningObjectives: [
        'Xác nhận thông tin chuyến bay và xuất trình giấy tờ tùy thân.',
        'Trả lời các câu hỏi về số kiện hành lý ký gửi và xách tay.',
        'Yêu cầu vị trí ghế ngồi: "window seat" hoặc "aisle seat".',
      ],
      samplePhrases: [
        'Here is my passport and booking confirmation.',
        'I have one suitcase to check in and one carry-on bag.',
        'Is it possible to get a window seat?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Boarding pass', ipa: '/ˈbɔː.dɪŋ pɑːs/', meaningVi: 'Thẻ lên máy bay'),
        VocabularyPreviewItem(phrase: 'Baggage allowance', ipa: '/ˈbæɡ.ɪdʒ əˈlaʊ.əns/', meaningVi: 'Tiêu chuẩn hành lý cho phép'),
        VocabularyPreviewItem(phrase: 'Window seat', ipa: '/ˈwɪn.dəʊ siːt/', meaningVi: 'Ghế ngồi sát cửa sổ'),
      ],
    ),
    const Scenario(
      id: 'sc_travel_03',
      topicId: 'tp_travel',
      level: UserLevel.b1,
      title: 'Phàn nàn về dịch vụ khách sạn',
      description: 'Phòng khách sạn của bạn bị hỏng điều hòa và không có nước nóng. Hãy liên hệ lễ tân để phản ánh một cách lịch thiệp nhưng kiên quyết.',
      roleAi: 'Lễ tân khách sạn',
      roleUser: 'Khách lưu trú',
      estimatedMinutes: 6,
      learningObjectives: [
        'Trình bày sự cố một cách rõ ràng: "There seems to be an issue with...".',
        'Giải thích tác động của sự cố đối với kỳ nghỉ của bạn.',
        'Đề xuất giải pháp: cử thợ kỹ thuật sửa ngay hoặc đổi sang phòng khác.',
      ],
      samplePhrases: [
        'I am calling from room 402. The air conditioner is not working properly.',
        'Could you please send someone to take a look or change my room?',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Malfunction', ipa: '/ˌmælˈfʌŋk.ʃən/', meaningVi: 'Bị lỗi, trục trặc chức năng hoạt động'),
        VocabularyPreviewItem(phrase: 'Inconvenience', ipa: '/ˌɪn.kənˈviː.ni.əns/', meaningVi: 'Sự phiền toái, bất tiện'),
        VocabularyPreviewItem(phrase: 'Compensate', ipa: '/ˈkɒm.pən.seɪt/', meaningVi: 'Đền bù, bồi thường thiệt hại'),
      ],
    ),

    // --- CHỦ ĐỀ 4: CÔNG VIỆC & PHỎNG VẤN ---
    const Scenario(
      id: 'sc_career_01',
      topicId: 'tp_career',
      level: UserLevel.b1,
      title: 'Phỏng vấn: Giới thiệu bản thân',
      description: 'Nhà tuyển dụng yêu cầu bạn tóm tắt học vấn, kỹ năng cốt lõi và những thành tích nổi bật nhất trong công việc vừa qua.',
      roleAi: 'Nhà tuyển dụng (HR Manager)',
      roleUser: 'Ứng viên phỏng vấn',
      estimatedMinutes: 7,
      learningObjectives: [
        'Mở đầu ấn tượng: tóm tắt 3 điểm mạnh nhất của bản thân.',
        'Sử dụng các thì quá khứ đơn và hiện tại hoàn thành linh hoạt khi kể kinh nghiệm.',
        'Nêu lý do vì sao bạn hứng thú với vị trí công việc này.',
      ],
      samplePhrases: [
        'I have over three years of experience in mobile development.',
        'My biggest strength is solving complex problems under tight deadlines.',
        'I am eager to contribute to your team with my technical expertise.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Proven track record', ipa: '/ˈpruː.vən træk ˈrek.ɔːd/', meaningVi: 'Bề dày thành tích đã được chứng minh'),
        VocabularyPreviewItem(phrase: 'Collaborate', ipa: '/kəˈlæb.ə.reɪt/', meaningVi: 'Phối hợp, hợp tác nhóm chặt chẽ'),
        VocabularyPreviewItem(phrase: 'Core strength', ipa: '/kɔːr streŋθ/', meaningVi: 'Thế mạnh cốt lõi'),
      ],
    ),
    const Scenario(
      id: 'sc_career_02',
      topicId: 'tp_career',
      level: UserLevel.b1,
      title: 'Báo cáo tiến độ trong họp nhóm',
      description: 'Cập nhật nhanh với quản lý về các tính năng đã hoàn thành trong sprint, các trở ngại (blockers) đang gặp và kế hoạch tuần tới.',
      roleAi: 'Quản lý dự án (Project Lead)',
      roleUser: 'Lập trình viên / Thành viên nhóm',
      estimatedMinutes: 6,
      learningObjectives: [
        'Báo cáo rõ ràng: "What I have completed...", "What I am working on...".',
        'Chỉ ra trở ngại kỹ thuật và xin trợ giúp: "Currently, I am blocked by...".',
        'Cam kết thời hạn hoàn tất công việc (Definition of Done).',
      ],
      samplePhrases: [
        'Yesterday, I finished the authentication module integration.',
        'Currently, I am facing an issue with the third-party API response time.',
        'I expect to wrap up the unit tests by this afternoon.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Blocker', ipa: '/ˈblɒk.ər/', meaningVi: 'Rào cản, trở ngại khiến task bị tắc nghẽn'),
        VocabularyPreviewItem(phrase: 'Milestone', ipa: '/ˈmaɪl.stəʊn/', meaningVi: 'Cột mốc tiến độ quan trọng'),
        VocabularyPreviewItem(phrase: 'Wrap up', ipa: '/ræp ʌp/', meaningVi: 'Gói gọn, hoàn tất nốt giai đoạn cuối'),
      ],
    ),
    const Scenario(
      id: 'sc_career_03',
      topicId: 'tp_career',
      level: UserLevel.b2,
      title: 'Đàm phán thời hạn giao dự án',
      description: 'Do khách hàng yêu cầu bổ sung tính năng mới, bạn cần đàm phán kéo dài deadline thêm 2 tuần để đảm bảo chất lượng kiểm thử an toàn.',
      roleAi: 'Đại diện đối tác nước ngoài',
      roleUser: 'Trưởng nhóm kỹ thuật',
      estimatedMinutes: 8,
      learningObjectives: [
        'Sử dụng các cấu trúc ngoại giao: "We understand your priority, however...".',
        'Phân tích rủi ro giữa việc vội vàng bàn giao vs việc kiểm thử toàn diện.',
        'Đưa ra đề xuất đôi bên cùng có lợi (Win-win trade-off).',
      ],
      samplePhrases: [
        'To ensure the highest quality and stability, we recommend extending the release date by two weeks.',
        'Rushing the deployment could introduce critical security bugs in production.',
      ],
      vocabularyPreview: [
        VocabularyPreviewItem(phrase: 'Trade-off', ipa: '/ˈtreɪd.ɒf/', meaningVi: 'Sự đánh đổi giữa hai yếu tố (chất lượng vs thời gian)'),
        VocabularyPreviewItem(phrase: 'Compromise', ipa: '/ˈkɒm.prə.maɪz/', meaningVi: 'Sự thỏa hiệp mang tính xây dựng'),
        VocabularyPreviewItem(phrase: 'Quality assurance', ipa: '/ˈkwɒl.ə.ti əˈʃɔː.rəns/', meaningVi: 'Đảm bảo chất lượng kiểm thử'),
      ],
    ),
  ];

  @override
  Future<List<Topic>> getTopics() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _topics;
  }

  @override
  Future<List<Scenario>> getScenarios({
    String? topicId,
    UserLevel? level,
    String? searchQuery,
    String? filterTab,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    return _allScenarios.map((s) {
      return s.copyWith(isBookmarked: _bookmarkedIds.contains(s.id));
    }).where((s) {
      // Topic filter
      if (topicId != null && topicId != 'all' && s.topicId != topicId) {
        return false;
      }
      // Level filter
      if (level != null && s.level != level) {
        return false;
      }
      // Search query
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase().trim();
        final matchTitle = s.title.toLowerCase().contains(query);
        final matchDesc = s.description.toLowerCase().contains(query);
        final matchRole = s.roleAi.toLowerCase().contains(query) || s.roleUser.toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchRole) return false;
      }
      // Tab filter
      if (filterTab == 'bookmarked' && !_bookmarkedIds.contains(s.id)) {
        return false;
      }
      if (filterTab == 'popular' && (s.level == UserLevel.c1 || s.level == UserLevel.a0)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Scenario?> getScenarioById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final s = _allScenarios.firstWhere((element) => element.id == id);
      return s.copyWith(isBookmarked: _bookmarkedIds.contains(s.id));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> toggleBookmark(String scenarioId) async {
    if (_bookmarkedIds.contains(scenarioId)) {
      _bookmarkedIds.remove(scenarioId);
      return false;
    } else {
      _bookmarkedIds.add(scenarioId);
      return true;
    }
  }
}
