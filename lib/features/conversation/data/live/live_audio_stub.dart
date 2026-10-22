class LiveAudioClient {
  LiveAudioClient(void Function(String type, String text) onEvent);
  bool get supported => false;
  Future<void> prepare() async =>
      throw UnsupportedError('Realtime hiện hỗ trợ trên web.');
  Future<void> connect(Map<String, dynamic> ticket) async =>
      throw UnsupportedError('Realtime hiện hỗ trợ trên web.');
  void mute(bool value) {}
  void close() {}
}
