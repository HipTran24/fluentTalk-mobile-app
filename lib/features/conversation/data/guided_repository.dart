import '../../../core/models/enums.dart';
import '../../../core/models/practice_session.dart';
import '../../../core/models/scenario.dart';
import '../domain/models/guided_models.dart';

abstract class GuidedSpeakingRepository {
  Future<List<GuidedTurn>> getTurnsForScenario(String scenarioId);
  Future<String> transcribeAudio(
      {required String scenarioId, required int turnIndex});
  Future<TurnFeedback> evaluateTurn({
    required String scenarioId,
    required int turnIndex,
    required String userTranscript,
  });
  Future<PracticeSession> saveCompletedSession({
    required String sessionId,
    required String scenarioId,
    required List<GuidedTurn> completedTurns,
  });
}

class MockGuidedSpeakingRepository implements GuidedSpeakingRepository {
  @override
  Future<List<GuidedTurn>> getTurnsForScenario(String scenarioId) async {
    // Simulate initial network fetch
    await Future.delayed(const Duration(milliseconds: 300));

    if (scenarioId == 'sc_intro_01') {
      return [
        const GuidedTurn(
          turnIndex: 1,
          aiRole: 'Thành viên câu lạc bộ',
          aiPromptEn:
              'Hi there! Welcome to our English speaking club! My name is Sarah. What is your name?',
          aiPromptVi:
              'Xin chào! Chào mừng bạn đến với CLB tiếng Anh! Mình tên là Sarah. Bạn tên là gì thế?',
          aiPromptIpa: '/haɪ ðeər! ˈwelkəm tuː ˈaʊər ˈɪŋɡlɪʃ ˈspiːkɪŋ klʌb!/',
          aiAudioUrl: 'mock_audio_intro_turn1.mp3',
          userRole: 'Người tham gia mới',
          userGoalVi: 'Nói lời chào lịch sự và giới thiệu tên đầy đủ của bạn.',
          suggestedStarters: [
            'Hello Sarah! Nice to meet you. My name is...',
            'Hi! I am thrilled to be here. You can call me...',
          ],
          keyVocabulary: [
            VocabularyPreviewItem(
                phrase: 'Nice to meet you',
                ipa: '/naɪs tu miːt juː/',
                meaningVi: 'Rất vui được gặp bạn'),
            VocabularyPreviewItem(
                phrase: 'Call me...',
                ipa: '/kɔːl miː/',
                meaningVi: 'Cứ gọi tôi là...'),
          ],
        ),
        const GuidedTurn(
          turnIndex: 2,
          aiRole: 'Thành viên câu lạc bộ',
          aiPromptEn:
              'It is so great to meet you! Are you from around here, or did you move here recently?',
          aiPromptVi:
              'Rất vui được làm quen với bạn! Bạn sinh ra ở đây hay mới chuyển đến đây gần đây?',
          aiPromptIpa: '/ɪt ɪz soʊ ɡreɪt tuː miːt juː!/',
          aiAudioUrl: 'mock_audio_intro_turn2.mp3',
          userRole: 'Người tham gia mới',
          userGoalVi:
              'Nêu quê hương/thành phố của bạn và bạn đã ở đây được bao lâu.',
          suggestedStarters: [
            'I am originally from Hanoi, and I moved here two years ago.',
            'Actually, I was born in Da Nang, but I currently live here.',
          ],
          keyVocabulary: [
            VocabularyPreviewItem(
                phrase: 'Originally from',
                ipa: '/əˈrɪdʒ.ən.əl.i frɒm/',
                meaningVi: 'Quê gốc ở...'),
            VocabularyPreviewItem(
                phrase: 'Move here',
                ipa: '/muːv hɪər/',
                meaningVi: 'Chuyển tới đây'),
          ],
        ),
        const GuidedTurn(
          turnIndex: 3,
          aiRole: 'Thành viên câu lạc bộ',
          aiPromptEn:
              'Awesome! That sounds like an exciting journey. What do you hope to improve most in our club?',
          aiPromptVi:
              'Tuyệt vời! Mục tiêu bạn mong muốn cải thiện nhất khi tham gia câu lạc bộ của chúng mình là gì?',
          aiPromptIpa: '/ˈɔː.səm! ðæt saʊndz laɪk ən ɪkˈsaɪ.tɪŋ ˈdʒɜː.ni./',
          aiAudioUrl: 'mock_audio_intro_turn3.mp3',
          userRole: 'Người tham gia mới',
          userGoalVi:
              'Chia sẻ mong muốn nâng cao phản xạ tự tin khi giao tiếp tiếng Anh.',
          suggestedStarters: [
            'I really want to improve my speaking fluency and sound more natural.',
            'My main goal is to expand my vocabulary and speak with confidence.',
          ],
          keyVocabulary: [
            VocabularyPreviewItem(
                phrase: 'Speaking fluency',
                ipa: '/ˈspiːkɪŋ ˈfluːənsi/',
                meaningVi: 'Độ lưu loát khi nói'),
            VocabularyPreviewItem(
                phrase: 'With confidence',
                ipa: '/wɪð ˈkɒnfɪdəns/',
                meaningVi: 'Một cách tự tin'),
          ],
        ),
      ];
    }

    // Default Restaurant / Bella Italia Scenario (sc_travel_01)
    return [
      const GuidedTurn(
        turnIndex: 1,
        aiRole: 'Bồi bàn (Waiter)',
        aiPromptEn:
            'Good evening! Welcome to Bella Italia. Do you have a table reservation with us tonight?',
        aiPromptVi:
            'Chào buổi tối! Chào mừng quý khách tới Bella Italia. Quý khách đã đặt bàn trước tối nay chưa ạ?',
        aiPromptIpa:
            '/ɡʊd ˈiːv.nɪŋ! ˈwelkəm tuː ˈbelə ɪˈtæljə. duː juː hæv ə ˈteɪbl ˌrezəˈveɪʃn wɪð ʌs təˈnaɪt?/',
        aiAudioUrl: 'mock_audio_restaurant_turn1.mp3',
        userRole: 'Khách hàng (Customer)',
        userGoalVi:
            'Nói lời chào, thông báo chưa đặt bàn trước và hỏi xem còn bàn trống cho 2 người không.',
        suggestedStarters: [
          'Good evening. No, we do not have a reservation, but do you have a table for two?',
          'Hello! We did not book in advance. Is there any table available for two people?',
        ],
        keyVocabulary: [
          VocabularyPreviewItem(
              phrase: 'Reservation',
              ipa: '/ˌrezəˈveɪʃn/',
              meaningVi: 'Sự đặt chỗ trước'),
          VocabularyPreviewItem(
              phrase: 'Table for two',
              ipa: '/ˈteɪbl fɔːr tuː/',
              meaningVi: 'Bàn dành cho 2 người'),
          VocabularyPreviewItem(
              phrase: 'Available',
              ipa: '/əˈveɪləbl/',
              meaningVi: 'Còn trống / có sẵn'),
        ],
      ),
      const GuidedTurn(
        turnIndex: 2,
        aiRole: 'Bồi bàn (Waiter)',
        aiPromptEn:
            'Certainly! We have a lovely table by the window. Here are your menus. Would you like to start with something to drink?',
        aiPromptVi:
            'Chắc chắn rồi ạ! Chúng tôi có một bàn rất đẹp cạnh cửa sổ. Đây là thực đơn. Quý khách có muốn bắt đầu với đồ uống gì không?',
        aiPromptIpa: '/ˈsɜːrtnli! wiː hæv ə ˈlʌvli ˈteɪbl baɪ ðə ˈwɪndoʊ./',
        aiAudioUrl: 'mock_audio_restaurant_turn2.mp3',
        userRole: 'Khách hàng (Customer)',
        userGoalVi:
            'Cảm ơn và gọi một chai nước khoáng có ga cùng một ly nước cam ép.',
        suggestedStarters: [
          'Thank you. Could we please have a bottle of sparkling water and fresh orange juice?',
          'That table sounds perfect! We would love some mineral water first, please.',
        ],
        keyVocabulary: [
          VocabularyPreviewItem(
              phrase: 'Sparkling water',
              ipa: '/ˈspɑːrklɪŋ ˈwɔːtər/',
              meaningVi: 'Nước khoáng có ga'),
          VocabularyPreviewItem(
              phrase: 'Could we please have...',
              ipa: '/kʊd wiː pliːz hæv/',
              meaningVi: 'Làm ơn cho chúng tôi...'),
        ],
      ),
      const GuidedTurn(
        turnIndex: 3,
        aiRole: 'Bồi bàn (Waiter)',
        aiPromptEn:
            'Right away! And what would you like for your main course? Today our chef recommends the creamy seafood pasta.',
        aiPromptVi:
            'Sẽ có ngay ạ! Còn món chính thì quý khách muốn dùng gì? Hôm nay bếp trưởng gợi ý món mì Ý hải sản sốt kem.',
        aiPromptIpa: '/raɪt əˈweɪ! ænd wʌt wʊd juː laɪk fɔːr jɔːr meɪn kɔːrs?/',
        aiAudioUrl: 'mock_audio_restaurant_turn3.mp3',
        userRole: 'Khách hàng (Customer)',
        userGoalVi:
            'Đồng ý thử món mì hải sản và hỏi thêm món đó có vị cay không.',
        suggestedStarters: [
          'The seafood pasta sounds delicious! Is it quite spicy, or mild?',
          'I will try the chef recommendation. Could you tell me if it contains chili?',
        ],
        keyVocabulary: [
          VocabularyPreviewItem(
              phrase: 'Main course',
              ipa: '/meɪn kɔːrs/',
              meaningVi: 'Món ăn chính'),
          VocabularyPreviewItem(
              phrase: 'Chef recommendation',
              ipa: '/ʃef ˌrekəmenˈdeɪʃn/',
              meaningVi: 'Món gợi ý của bếp trưởng'),
          VocabularyPreviewItem(
              phrase: 'Spicy', ipa: '/ˈspaɪsi/', meaningVi: 'Vị cay nồng'),
        ],
      ),
      const GuidedTurn(
        turnIndex: 4,
        aiRole: 'Bồi bàn (Waiter)',
        aiPromptEn:
            'It is very mild and creamy, not spicy at all! I will get that started for you. Is there anything else you need?',
        aiPromptVi:
            'Món này rất béo ngậy và dịu nhẹ, không cay chút nào đâu ạ! Tôi sẽ chuẩn bị ngay. Quý khách còn cần gì thêm không ạ?',
        aiPromptIpa: '/ɪt ɪz ˈveri maɪld ænd ˈkriːmi, nɒt ˈspaɪsi æt ɔːl!/',
        aiAudioUrl: 'mock_audio_restaurant_turn4.mp3',
        userRole: 'Khách hàng (Customer)',
        userGoalVi: 'Cảm ơn và nói rằng như vậy là đủ rồi.',
        suggestedStarters: [
          'That is all for now, thank you very much!',
          'No, that would be wonderful. Thanks a lot for your help.',
        ],
        keyVocabulary: [
          VocabularyPreviewItem(
              phrase: 'That is all for now',
              ipa: '/ðæt ɪz ɔːl fɔːr naʊ/',
              meaningVi: 'Tạm thời thế là đủ rồi'),
          VocabularyPreviewItem(
              phrase: 'Mild', ipa: '/maɪld/', meaningVi: 'Vị nhẹ / thanh mát'),
        ],
      ),
    ];
  }

  @override
  Future<String> transcribeAudio(
      {required String scenarioId, required int turnIndex}) async {
    // Simulate Whisper speech-to-text latency
    await Future.delayed(const Duration(milliseconds: 750));

    if (scenarioId == 'sc_intro_01') {
      switch (turnIndex) {
        case 1:
          return 'Hello Sarah! Nice to meet you. My name is Nam and I am very happy to join today.';
        case 2:
          return 'I am originally from Da Nang, and I have moved to Ho Chi Minh City for work.';
        case 3:
          return 'I want to improve my speaking fluency and talk more naturally with international colleagues.';
        default:
          return 'Thank you so much for the warm welcome!';
      }
    }

    switch (turnIndex) {
      case 1:
        return 'Good evening. We do not have a reservation, but do you have a table for two available please?';
      case 2:
        return 'Thank you. Could we please have a bottle of sparkling water and some fresh orange juice?';
      case 3:
        return 'The seafood pasta sounds wonderful! Could you tell me if the dish is spicy?';
      case 4:
        return 'That is all for now, thank you very much for your great assistance.';
      default:
        return 'Thank you for your kind help.';
    }
  }

  @override
  Future<TurnFeedback> evaluateTurn({
    required String scenarioId,
    required int turnIndex,
    required String userTranscript,
  }) async {
    // Simulate rubric Tom analysis
    await Future.delayed(const Duration(milliseconds: 800));

    final textLower = userTranscript.toLowerCase();

    if (textLower.contains('table for two') ||
        textLower.contains('reservation')) {
      return const TurnFeedback(
        score: 92.0,
        praise:
            'Xuất sắc! Cấu trúc câu chuẩn mực, sử dụng chính xác từ vựng đặt chỗ "reservation".',
        nativeAlternative:
            'Người bản xứ có thể nói tự nhiên hơn: "Hi, two of us without a booking, do you have any room?"',
        usedKeywords: ['table for two', 'reservation', 'available'],
        pronunciationNotes:
            'Ngữ điệu câu hỏi lên giọng ở cuối rất chuẩn. Chú ý bật âm đuôi /z/ ở "is" và /t/ ở "right".',
      );
    } else if (textLower.contains('water') ||
        textLower.contains('juice') ||
        textLower.contains('sparkling')) {
      return const TurnFeedback(
        score: 88.0,
        praise:
            'Rất tốt! Cách dùng "Could we please have..." tạo cảm giác cực kỳ lịch sự và tự nhiên.',
        nativeAlternative:
            'Bạn có thể nói nhanh: "Could we start with some sparkling water and orange juice, please?"',
        usedKeywords: ['sparkling water', 'could we have'],
        pronunciationNotes: 'Âm /p/ trong "please" và "sparkling" bật hơi tốt.',
      );
    } else {
      return const TurnFeedback(
        score: 85.0,
        praise: 'Phản xạ câu trả lời nhanh chóng, diễn đạt ý rõ ràng.',
        nativeAlternative:
            'Tham khảo cách nói tự nhiên: "Sounds great! That will be all for us, thank you."',
        usedKeywords: ['sounds good', 'thank you'],
        pronunciationNotes:
            'Nhịp điệu đều đặn. Giữ hơi thở ổn định giữa các vế câu.',
      );
    }
  }

  @override
  Future<PracticeSession> saveCompletedSession({
    required String sessionId,
    required String scenarioId,
    required List<GuidedTurn> completedTurns,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return PracticeSession(
      id: sessionId,
      userId: 'usr_current',
      scenarioId: scenarioId,
      scenarioTitle: 'Phản xạ: Gọi món tại nhà hàng Ý',
      mode: SessionMode.guided,
      status: SessionStatus.completed,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      endedAt: DateTime.now(),
      durationSeconds: 285,
      turnsCount: completedTurns.length,
      estimatedScore: 89.5,
    );
  }
}
