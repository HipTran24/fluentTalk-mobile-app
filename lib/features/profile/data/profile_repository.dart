import '../../../core/models/vocabulary_item.dart';

abstract class ProfileRepository {
  Future<List<VocabularyItem>> getSavedVocabulary();
  Future<bool> toggleMastered(String wordId);
  Future<void> saveSettings({
    required bool notifications,
    required bool audioConsent,
    required double defaultSpeed,
    required String voiceName,
  });
  Future<void> deleteAudioRecords();
}

class MockProfileRepository implements ProfileRepository {
  final List<VocabularyItem> _vocabList = [
    VocabularyItem(
      id: 'voc_01',
      phrase: 'Could I have the bill, please?',
      ipa: '/kʊd aɪ hæv ðə bɪl pliːz/',
      meaningVi: 'Làm ơn cho tôi xin hóa đơn thanh toán?',
      exampleSentence:
          'Excuse me, could I have the bill, please? We are in a hurry.',
      sourceScenarioTitle: 'Gọi món tại nhà hàng Ý',
      isMastered: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    VocabularyItem(
      id: 'voc_02',
      phrase: 'I would be delighted to',
      ipa: '/aɪ wʊd bi dɪˈlaɪtɪd tuː/',
      meaningVi: 'Tôi rất sẵn lòng / rất vinh hạnh được làm việc này.',
      exampleSentence:
          'I would be delighted to assist you with your flight reservation.',
      sourceScenarioTitle: 'Hỏi đáp với Tom Coach',
      isMastered: false,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    VocabularyItem(
      id: 'voc_03',
      phrase: 'Specialty of the house',
      ipa: '/ˈspeʃəlti əv ðə haʊs/',
      meaningVi: 'Món ăn đặc sản trứ danh của nhà hàng.',
      exampleSentence: 'What is the specialty of the house tonight?',
      sourceScenarioTitle: 'Gọi món tại nhà hàng Ý',
      isMastered: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    VocabularyItem(
      id: 'voc_04',
      phrase: 'Have a reservation',
      ipa: '/hæv ə ˌrezəˈveɪʃn/',
      meaningVi: 'Đã đặt chỗ / đặt bàn trước.',
      exampleSentence:
          'Good evening, I have a reservation under the name of Nam.',
      sourceScenarioTitle: 'Gọi món tại nhà hàng Ý',
      isMastered: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    VocabularyItem(
      id: 'voc_05',
      phrase: 'Sparkling water',
      ipa: '/ˈspɑːrklɪŋ ˈwɔːtər/',
      meaningVi: 'Nước khoáng có ga.',
      exampleSentence:
          'Could we get a bottle of chilled sparkling water, please?',
      sourceScenarioTitle: 'Gọi món tại nhà hàng Ý',
      isMastered: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<VocabularyItem>> getSavedVocabulary() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_vocabList);
  }

  @override
  Future<bool> toggleMastered(String wordId) async {
    final idx = _vocabList.indexWhere((w) => w.id == wordId);
    if (idx != -1) {
      final old = _vocabList[idx];
      _vocabList[idx] = VocabularyItem(
        id: old.id,
        phrase: old.phrase,
        ipa: old.ipa,
        meaningVi: old.meaningVi,
        exampleSentence: old.exampleSentence,
        sourceScenarioTitle: old.sourceScenarioTitle,
        isMastered: !old.isMastered,
        createdAt: old.createdAt,
      );
      return _vocabList[idx].isMastered;
    }
    return false;
  }

  @override
  Future<void> saveSettings({
    required bool notifications,
    required bool audioConsent,
    required double defaultSpeed,
    required String voiceName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> deleteAudioRecords() async {
    await Future.delayed(const Duration(milliseconds: 250));
  }
}
