abstract interface class LiveAudioTransport {
  bool get supported;

  Future<void> prepare();

  Future<void> connect(Map<String, dynamic> ticket);

  void sendUserText(String text);

  void mute(bool value);

  Future<void> close();
}
