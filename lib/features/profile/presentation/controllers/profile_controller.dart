import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/vocabulary_item.dart';
import '../../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

final vocabularyFilterProvider = StateProvider<String>((ref) => 'all'); // 'all', 'learning', 'mastered'

final vocabularyListProvider =
    StateNotifierProvider<VocabularyNotifier, AsyncValue<List<VocabularyItem>>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return VocabularyNotifier(repo);
});

class VocabularyNotifier extends StateNotifier<AsyncValue<List<VocabularyItem>>> {
  final ProfileRepository _repo;

  VocabularyNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadWords();
  }

  Future<void> loadWords() async {
    state = const AsyncValue.loading();
    try {
      final words = await _repo.getSavedVocabulary();
      state = AsyncValue.data(words);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleMastered(String wordId) async {
    final current = state.value;
    if (current == null) return;

    await _repo.toggleMastered(wordId);
    state = AsyncValue.data(
      current.map((w) {
        if (w.id == wordId) {
          return VocabularyItem(
            id: w.id,
            phrase: w.phrase,
            ipa: w.ipa,
            meaningVi: w.meaningVi,
            exampleSentence: w.exampleSentence,
            sourceScenarioTitle: w.sourceScenarioTitle,
            isMastered: !w.isMastered,
            createdAt: w.createdAt,
          );
        }
        return w;
      }).toList(),
    );
  }
}

class ProfileSettingsState {
  final bool notifications;
  final bool audioConsent;
  final double defaultSpeed;
  final String voiceName;
  final bool isSaved;

  const ProfileSettingsState({
    this.notifications = true,
    this.audioConsent = false,
    this.defaultSpeed = 1.0,
    this.voiceName = 'Giọng Nữ chuẩn Anh - Mỹ (Journey-F)',
    this.isSaved = false,
  });

  ProfileSettingsState copyWith({
    bool? notifications,
    bool? audioConsent,
    double? defaultSpeed,
    String? voiceName,
    bool? isSaved,
  }) {
    return ProfileSettingsState(
      notifications: notifications ?? this.notifications,
      audioConsent: audioConsent ?? this.audioConsent,
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      voiceName: voiceName ?? this.voiceName,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

final profileSettingsControllerProvider =
    StateNotifierProvider<ProfileSettingsController, ProfileSettingsState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileSettingsController(repo);
});

class ProfileSettingsController extends StateNotifier<ProfileSettingsState> {
  final ProfileRepository _repo;

  ProfileSettingsController(this._repo) : super(const ProfileSettingsState());

  void setNotifications(bool value) {
    state = state.copyWith(notifications: value);
    _save();
  }

  void setAudioConsent(bool value) {
    state = state.copyWith(audioConsent: value);
    _save();
  }

  void setDefaultSpeed(double speed) {
    state = state.copyWith(defaultSpeed: speed);
    _save();
  }

  void setVoice(String voice) {
    state = state.copyWith(voiceName: voice);
    _save();
  }

  Future<void> _save() async {
    await _repo.saveSettings(
      notifications: state.notifications,
      audioConsent: state.audioConsent,
      defaultSpeed: state.defaultSpeed,
      voiceName: state.voiceName,
    );
  }

  Future<void> deleteAllRecordings() async {
    await _repo.deleteAudioRecords();
  }
}
