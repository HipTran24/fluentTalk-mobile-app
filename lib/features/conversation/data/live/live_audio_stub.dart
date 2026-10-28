class LiveAudioClient {
  LiveAudioClient(void Function(String type, String text) onEvent);
  bool get supported => false;
  Future<void> prepare() async =>
      throw UnsupportedError('Realtime hiện hỗ trợ trên web, Android và iOS.');
  Future<void> connect(Map<String, dynamic> ticket) async =>
      throw UnsupportedError('Realtime hiện hỗ trợ trên web, Android và iOS.');
  void mute(bool value) {}
  Future<void> close() async {}
}
