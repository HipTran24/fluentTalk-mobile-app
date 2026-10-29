import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'native_live_audio.dart';
import 'live_audio_native.dart' as plugin_native;
import 'live_audio_transport.dart';

typedef LiveSocketConnector = Future<WebSocket> Function(Uri uri);

/// Full-duplex PCM audio. Long-lived provider keys never enter the app.
class _AndroidLiveAudioClient implements LiveAudioTransport {
  final void Function(String type, String text) onEvent;
  final NativeLiveAudio _audio;
  final LiveSocketConnector _connector;
  final Duration handshakeTimeout;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _messages;
  StreamSubscription<Map<Object?, Object?>>? _audioEvents;
  Completer<void>? _handshake;
  Timer? _timeout, _expiry;
  bool _closed = false, _ready = false, _muted = false;
  bool _playing = false;
  final bool _supported;

  _AndroidLiveAudioClient(this.onEvent,
      {NativeLiveAudio? audio,
      LiveSocketConnector? connector,
      this.handshakeTimeout = const Duration(seconds: 20)})
      : _audio = audio ?? AndroidLiveAudio(),
        _supported = audio != null || Platform.isAndroid,
        _connector = connector ?? ((uri) => WebSocket.connect(uri.toString()));

  @override
  bool get supported => _supported;

  @override
  Future<void> prepare() async {
    try {
      if (!supported) throw PlatformException(code: 'unsupported');
      _audioEvents = _audio.events.listen((event) {
        if (_closed) return;
        switch (event['type']) {
          case 'pcm':
            final pcm = event['pcm'];
            if (_ready && !_muted && pcm is Uint8List) {
              _send({
                'realtimeInput': {
                  'audio': {
                    'mimeType': 'audio/pcm;rate=16000',
                    'data': base64Encode(pcm)
                  }
                }
              });
            }
          case 'drained':
            _playing = false;
            _emit('listening');
          case 'error':
            _fail(event['reason'] as String? ?? 'microphone');
        }
      }, onError: (Object _) => _fail('microphone'));
      await _audio.prepare();
      if (_closed) throw StateError('Call cancelled');
    } on PlatformException catch (error) {
      _fail(error.code == 'permission'
          ? 'permission'
          : error.code == 'unsupported'
              ? 'unsupported'
              : 'microphone');
      rethrow;
    }
  }

  @override
  Future<void> connect(Map<String, dynamic> ticket) async {
    if (_closed) throw StateError('Call cancelled');
    final token = ticket['token'];
    final setup = ticket['setup'];
    final expires = DateTime.tryParse(ticket['expiresAt'] as String? ?? '');
    if (token is! String ||
        !token.startsWith('auth_tokens/') ||
        setup is! Map ||
        expires == null) {
      throw const FormatException('Invalid live ticket');
    }
    final remaining = expires.difference(DateTime.now());
    if (remaining <= Duration.zero) throw StateError('Expired live ticket');
    _expiry = Timer(
        remaining < const Duration(minutes: 5)
            ? remaining
            : const Duration(minutes: 5),
        () => _fail('expired'));
    final handshake = _handshake = Completer<void>();
    // Attach a listener before any connection failure can complete the future.
    final ready = handshake.future;
    unawaited(ready.then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    _timeout = Timer(handshakeTimeout, () => _fail('timeout'));
    try {
      final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained',
          {'access_token': token}).replace(scheme: 'wss');
      final opening = _connector(uri);
      unawaited(opening.then<void>((socket) {
        if (_closed) unawaited(socket.close());
      }, onError: (Object _, StackTrace __) {}));
      // Closing a call must settle connect even while DNS/TLS is pending.
      final socket = await Future.any<WebSocket>([
        opening,
        ready.then<WebSocket>((_) => throw StateError('Call closed')),
      ]).timeout(handshakeTimeout);
      if (_closed) {
        unawaited(socket.close());
        return await ready;
      }
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 10);
      // asyncMap preserves PCM/interruption order; async listen callbacks do not.
      _messages =
          socket.asyncMap(_message).listen((_) {}, onError: (Object error) {
        debugPrint('LiveAudio: socket error type=${error.runtimeType}');
        _fail('network');
      }, onDone: () {
        debugPrint('LiveAudio: socket closed code=${socket.closeCode}');
        // Gemini may close with 1011 a few seconds before the credential's
        // exact deadline. This is an ended session, not a broken connection.
        final expired = _ready &&
            (socket.closeCode == 1011 || socket.closeCode == 1000) &&
            expires.difference(DateTime.now()) <= const Duration(seconds: 10);
        _fail(expired
            ? 'expired'
            : socket.closeCode == 1008
                ? 'access'
                : 'disconnected');
      });
      _send({'setup': setup});
    } catch (error) {
      debugPrint('LiveAudio: connection failed type=${error.runtimeType}');
      _fail('network');
    }
    await ready;
  }

  Future<void> _message(dynamic frame) async {
    if (_closed) return;
    try {
      final value =
          jsonDecode(frame is String ? frame : utf8.decode(frame as List<int>))
              as Map<String, dynamic>;
      if (value['error'] != null) {
        _fail('provider');
        return;
      }
      if (value['goAway'] != null) {
        _fail('expired');
        return;
      }
      // Protobuf's empty message is {}, not the boolean true.
      if (!_ready &&
          (value['setupComplete'] is Map || value['setupComplete'] == true)) {
        await _audio.start();
        if (_closed) return;
        _ready = true;
        _timeout?.cancel();
        _handshake?.complete();
        _emit('ready');
        _send({
          'realtimeInput': {
            'text':
                'Please greet me briefly and ask one easy question to start our English practice.'
          }
        });
      }
      final content = value['serverContent'];
      if (content is! Map || _closed) return;
      if (content['interrupted'] == true) {
        await _audio.stopPlayback();
        _playing = false;
        _emit('listening');
      }
      final input = content['inputTranscription'];
      final output = content['outputTranscription'];
      if (input is Map && input['text'] is String) {
        _emit('user', input['text'] as String);
      }
      if (output is Map && output['text'] is String) {
        _emit('ai', output['text'] as String);
      }
      final turn = content['modelTurn'];
      if (turn is Map && turn['parts'] is List) {
        for (final part in turn['parts'] as List) {
          if (_closed) return;
          final data = part is Map ? part['inlineData'] : null;
          if (data is! Map || data['data'] is! String) continue;
          final mime = data['mimeType'] as String? ?? '';
          if (!mime.startsWith('audio/pcm')) continue;
          final rate = RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1);
          final pcm = base64Decode(data['data'] as String);
          if ((rate != null && rate != '24000') ||
              pcm.length.isOdd ||
              pcm.length > 384000) {
            throw const FormatException('Invalid PCM audio');
          }
          if (pcm.isNotEmpty) {
            await _audio.play(pcm);
            if (!_playing) {
              _playing = true;
              _emit('speaking');
            }
          }
        }
      }
      if (content['turnComplete'] == true && !_playing) _emit('listening');
    } on PlatformException catch (_) {
      _fail('microphone');
    } catch (_) {
      _fail('provider');
    }
  }

  @override
  void sendUserText(String text) {
    if (!_ready || _closed || text.trim().isEmpty) return;
    _safe(_audio.stopPlayback());
    _playing = false;
    _emit('user', text.trim());
    _send({
      'realtimeInput': {'text': text.trim()}
    });
  }

  @override
  void mute(bool value) {
    if (_closed) return;
    _muted = value;
    _safe(_audio.mute(value));
    if (value && _ready) {
      _send({
        'realtimeInput': {'audioStreamEnd': true}
      });
    }
  }

  void _send(Map<String, dynamic> value) {
    if (_closed || _socket?.readyState != WebSocket.open) return;
    try {
      _socket!.add(jsonEncode(value));
    } catch (_) {
      _fail('network');
    }
  }

  void _emit(String type, [String text = '']) {
    if (!_closed) onEvent(type, text);
  }

  void _safe(Future<void> future) {
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace __) {
      if (!_closed) _fail('microphone');
    }));
  }

  void _fail(String reason) {
    if (_closed) return;
    debugPrint('LiveAudio: failure=$reason');
    _emit('error', reason);
    close();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _ready = false;
    _timeout?.cancel();
    _expiry?.cancel();
    final handshake = _handshake;
    if (handshake != null && !handshake.isCompleted) {
      handshake.completeError(StateError('Call closed'));
    }
    try {
      await _messages?.cancel();
      await _audioEvents?.cancel();
      await _socket?.close();
      await _audio.close();
    } catch (_) {
      // Closing a call is best-effort; all handles above are already detached.
    }
  }
}

/// Runtime dispatcher: Android uses the low-latency platform audio bridge;
/// iOS keeps the existing recorder/PCM-player transport.
class LiveAudioClient implements LiveAudioTransport {
  late final LiveAudioTransport _transport;

  LiveAudioClient(
    void Function(String type, String text) onEvent, {
    NativeLiveAudio? audio,
    LiveSocketConnector? connector,
    Duration handshakeTimeout = const Duration(seconds: 20),
  }) {
    if (audio != null || Platform.isAndroid) {
      _transport = _AndroidLiveAudioClient(
        onEvent,
        audio: audio,
        connector: connector,
        handshakeTimeout: handshakeTimeout,
      );
    } else if (Platform.isIOS) {
      _transport = plugin_native.PluginNativeLiveAudioClient(onEvent);
    } else {
      _transport = _UnsupportedLiveAudioTransport();
    }
  }

  @override
  bool get supported => _transport.supported;

  @override
  Future<void> prepare() => _transport.prepare();

  @override
  Future<void> connect(Map<String, dynamic> ticket) =>
      _transport.connect(ticket);

  @override
  void sendUserText(String text) => _transport.sendUserText(text);

  @override
  void mute(bool value) => _transport.mute(value);

  @override
  Future<void> close() => _transport.close();
}

class _UnsupportedLiveAudioTransport implements LiveAudioTransport {
  @override
  bool get supported => false;

  @override
  Future<void> prepare() => Future<void>.error(
        UnsupportedError('Realtime chưa được hỗ trợ trên nền tảng này.'),
      );

  @override
  Future<void> connect(Map<String, dynamic> ticket) => Future<void>.error(
        UnsupportedError('Realtime chưa được hỗ trợ trên nền tảng này.'),
      );

  @override
  void sendUserText(String text) {}

  @override
  void mute(bool value) {}

  @override
  Future<void> close() async {}
}
