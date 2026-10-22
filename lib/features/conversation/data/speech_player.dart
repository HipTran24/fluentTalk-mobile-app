import 'package:flutter_tts/flutter_tts.dart';

class SpeechPlayer {
  FlutterTts? _engine;
  int _epoch = 0;

  Future<void> speak(String text, double speed) async {
    final epoch = ++_epoch;
    final engine = _engine ??= FlutterTts();
    await engine.stop();
    if (epoch != _epoch) return;
    await engine.setLanguage('en-US');
    if (epoch != _epoch) return;
    await engine.setSpeechRate((0.5 * speed).clamp(0.1, 1.0));
    if (epoch != _epoch) return;
    await engine.awaitSpeakCompletion(true);
    if (epoch != _epoch) return;
    final result = await engine.speak(text);
    if (result != 1) throw StateError('Speech engine unavailable');
  }

  Future<void> stop() async {
    _epoch++;
    await _engine?.stop();
  }
}
