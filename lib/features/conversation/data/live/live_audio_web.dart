import 'dart:convert';
import 'dart:js_interop';

@JS('fluentLiveCreate')
external _LiveHandle _create(JSFunction callback);
extension type _LiveHandle(JSObject _) implements JSObject {
  external JSPromise<JSAny?> prepare();
  external JSPromise<JSAny?> connect(JSString ticket);
  external void mute(JSBoolean value);
  external void close();
}

class LiveAudioClient {
  late final _LiveHandle _handle;
  LiveAudioClient(void Function(String type, String text) onEvent) {
    _handle = _create(((JSString event) {
      final value = jsonDecode(event.toDart) as Map<String, dynamic>;
      onEvent(value['type'] as String, value['text'] as String? ?? '');
    }).toJS);
  }
  bool get supported => true;
  Future<void> prepare() async {
    await _handle.prepare().toDart;
  }

  Future<void> connect(Map<String, dynamic> ticket) async {
    await _handle.connect(jsonEncode(ticket).toJS).toDart;
  }

  void mute(bool value) => _handle.mute(value.toJS);
  void close() => _handle.close();
}
