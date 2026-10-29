import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';
import 'package:record/record.dart' hide IosAudioCategory;
import 'live_audio_transport.dart';

/// Native Android/iOS transport for Gemini Live.
///
/// The app sends microphone PCM16 at 16 kHz and plays Gemini's PCM16 response
/// at 24 kHz. The Gemini API key stays on the backend; this client only gets
/// the short-lived token returned by `POST /api/v1/ai/live-token`.
class PluginNativeLiveAudioClient implements LiveAudioTransport {
  PluginNativeLiveAudioClient(this._onEvent);

  static const _liveEndpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained';
  static const _inputRate = 16000;
  static const _outputRate = 24000;
  static Future<void> _nativeSessionTail = Future<void>.value();

  final void Function(String type, String text) _onEvent;
  final AudioRecorder _recorder = AudioRecorder();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  StreamSubscription<Uint8List>? _microphoneSubscription;
  Future<void> _messageTail = Future<void>.value();
  Future<void> _playerTail = Future<void>.value();
  Future<void>? _playerInitialization;
  Completer<void>? _sessionLease;
  Completer<void>? _connectCompleter;
  Future<void>? _closeFuture;
  Timer? _handshakeTimer;
  Timer? _expiryTimer;
  Timer? _playbackTimer;
  DateTime? _playbackEndsAt;
  bool _closed = false;
  bool _ready = false;
  bool _muted = false;
  bool _playerInitialized = false;
  bool _turnComplete = false;

  @override
  bool get supported => Platform.isIOS;

  @override
  Future<void> prepare() async {
    if (!supported) {
      throw UnsupportedError('Native realtime requires Android or iOS.');
    }
    try {
      if (!await _recorder.hasPermission()) {
        _emitError('permission');
        throw StateError('Microphone permission denied');
      }
      await _acquireAudioSession();
      if (_closed) throw StateError('Audio session was cancelled');

      // Configure output before recording so iOS uses a full-duplex audio
      // session, which is required to listen and speak at the same time.
      await _initializePlayer();
      if (_closed) throw StateError('Audio session was cancelled');

      final microphone = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _inputRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
        audioInterruption: AudioInterruptionMode.pauseResume,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceCommunication,
          speakerphone: true,
          audioManagerMode: AudioManagerMode.modeInCommunication,
        ),
        // Keep speech routed to the loudspeaker by default while preserving
        // Bluetooth headset input/output when one is connected.
        iosConfig: IosRecordConfig(categoryOptions: [
          IosAudioCategoryOption.defaultToSpeaker,
          IosAudioCategoryOption.allowBluetooth,
          IosAudioCategoryOption.allowBluetoothA2DP,
        ]),
      ));
      if (_closed) {
        await _recorder.stop();
        throw StateError('Audio session was cancelled');
      }
      _microphoneSubscription = microphone.listen(
        _sendMicrophoneAudio,
        onError: (Object _) {
          if (!_closed) _fail('microphone');
        },
        onDone: () {
          if (!_closed) _fail('microphone');
        },
      );
    } catch (error) {
      if (!_closed && error is! StateError) _emitError('microphone');
      rethrow;
    }
  }

  @override
  Future<void> connect(Map<String, dynamic> ticket) async {
    if (_closed || _microphoneSubscription == null) {
      throw StateError('Prepare microphone before connecting');
    }
    final token = ticket['token'];
    final setup = ticket['setup'];
    final expiresAt = DateTime.tryParse(ticket['expiresAt']?.toString() ?? '');
    if (token is! String ||
        !token.startsWith('auth_tokens/') ||
        setup is! Map<String, dynamic>) {
      throw const FormatException('Invalid Gemini Live ticket');
    }
    final ttl = expiresAt?.difference(DateTime.now());
    if (ttl == null || ttl <= Duration.zero) {
      _emitError('expired');
      throw StateError('Gemini Live ticket expired');
    }

    _connectCompleter = Completer<void>();
    _handshakeTimer =
        Timer(const Duration(seconds: 20), () => _fail('timeout'));
    _expiryTimer = Timer(
      ttl > const Duration(minutes: 5) ? const Duration(minutes: 5) : ttl,
      () => _fail('expired'),
    );

    try {
      final uri = Uri.parse(_liveEndpoint).replace(queryParameters: {
        'access_token': token,
      });
      _socket = await WebSocket.connect(uri.toString()).timeout(
        const Duration(seconds: 20),
      );
      if (_closed) {
        await _socket?.close();
        throw StateError('Connection cancelled');
      }
      _socketSubscription = _socket!.listen(
        _onSocketData,
        onError: (Object _) => _fail('network'),
        onDone: () {
          if (!_closed) _fail('disconnected');
        },
        cancelOnError: true,
      );
      _socket!.add(jsonEncode({'setup': setup}));
      await _connectCompleter!.future;
    } on TimeoutException {
      _fail('timeout');
      rethrow;
    } catch (_) {
      if (!_closed) _fail('network');
      rethrow;
    }
  }

  void _sendMicrophoneAudio(Uint8List bytes) {
    if (_closed || !_ready || _muted || _socket?.readyState != WebSocket.open) {
      return;
    }
    if (bytes.isEmpty || bytes.length.isOdd) return;
    _send({
      'realtimeInput': {
        'audio': {
          'mimeType': 'audio/pcm;rate=$_inputRate',
          'data': base64Encode(bytes),
        },
      },
    });
  }

  void _onSocketData(dynamic data) {
    _messageTail = _messageTail.then((_) async {
      if (_closed) return;
      final text = data is String ? data : utf8.decode(data as List<int>);
      final message = jsonDecode(text) as Map<String, dynamic>;
      if (message['error'] != null) {
        _fail('provider');
        return;
      }
      if (message['goAway'] != null) {
        _fail('expired');
        return;
      }
      if (message['setupComplete'] != null) {
        _handshakeTimer?.cancel();
        _ready = true;
        _connectCompleter?.complete();
        _connectCompleter = null;
        _emit('ready');
        _send({
          'realtimeInput': {
            'text':
                'Please greet me briefly and ask one easy question to start our English practice.',
          },
        });
      }

      final content = message['serverContent'];
      if (content is! Map<String, dynamic>) return;
      if (content['interrupted'] == true) {
        await _stopPlayback();
        _turnComplete = false;
        _emit('listening');
      }
      final inputText = content['inputTranscription'];
      if (inputText is Map && inputText['text'] is String) {
        _emit('user', inputText['text'] as String);
      }
      final outputText = content['outputTranscription'];
      if (outputText is Map && outputText['text'] is String) {
        _emit('ai', outputText['text'] as String);
      }

      final modelTurn = content['modelTurn'];
      final parts = modelTurn is Map ? modelTurn['parts'] : null;
      if (parts is List) {
        for (final part in parts) {
          if (part is Map &&
              part['inlineData'] is Map &&
              (part['inlineData'] as Map)['data'] is String &&
              ((part['inlineData'] as Map)['mimeType'] as String? ?? '')
                  .startsWith('audio/pcm')) {
            final audio = part['inlineData'] as Map;
            await _queueAudio(audio['data'] as String,
                audio['mimeType'] as String? ?? 'audio/pcm;rate=$_outputRate');
          }
        }
      }
      if (content['turnComplete'] == true) {
        _turnComplete = true;
        _emitListeningWhenPlaybackEnds();
      }
    }).catchError((Object _) {
      if (!_closed) _fail('provider');
    });
  }

  Future<void> _queueAudio(String encoded, String mimeType) async {
    final bytes = base64Decode(encoded);
    if (bytes.length.isOdd) throw const FormatException('Invalid PCM audio');
    final rate = int.tryParse(
            RegExp(r'rate=(\d+)').firstMatch(mimeType)?.group(1) ?? '') ??
        _outputRate;
    if (rate < 8000 || rate > 96000) {
      throw const FormatException('Unsupported PCM sample rate');
    }
    final sampleCount = bytes.length ~/ 2;
    _playbackTimer?.cancel();
    _playbackEndsAt ??= DateTime.now();
    final startAt = _playbackEndsAt!.isAfter(DateTime.now())
        ? _playbackEndsAt!
        : DateTime.now();
    _playbackEndsAt = startAt.add(Duration(
      microseconds:
          (sampleCount * Duration.microsecondsPerSecond / rate).round(),
    ));
    _emit('speaking');
    _playerTail = _playerTail.then((_) async {
      if (_closed) return;
      await _initializePlayer();
      // Gemini already sends little-endian PCM16, so feed its byte view
      // directly and avoid a per-frame Int16List copy on the UI isolate.
      await FlutterPcmSound.feed(
          PcmArrayInt16(bytes: ByteData.sublistView(bytes)));
    });
    await _playerTail;
  }

  Future<void> _initializePlayer() {
    if (_playerInitialized) return Future<void>.value();
    final currentInitialization = _playerInitialization;
    if (currentInitialization != null) return currentInitialization;

    final initialization = _setupPlayer();
    _playerInitialization = initialization;
    return initialization;
  }

  Future<void> _acquireAudioSession() async {
    final previousSession = _nativeSessionTail;
    final lease = Completer<void>();
    _sessionLease = lease;
    _nativeSessionTail = previousSession.then((_) => lease.future);
    await previousSession;
    if (_closed) _releaseAudioSession();
  }

  void _releaseAudioSession() {
    final lease = _sessionLease;
    _sessionLease = null;
    if (lease != null && !lease.isCompleted) lease.complete();
  }

  Future<void> _setupPlayer() async {
    try {
      await FlutterPcmSound.setup(
        sampleRate: _outputRate,
        channelCount: 1,
        iosAudioCategory: IosAudioCategory.playAndRecord,
      );
      _playerInitialized = true;
    } catch (_) {
      _playerInitialization = null;
      rethrow;
    }
  }

  void _emitListeningWhenPlaybackEnds() {
    _playbackTimer?.cancel();
    final end = _playbackEndsAt;
    final delay = end == null ? Duration.zero : end.difference(DateTime.now());
    _playbackTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!_closed && _turnComplete) {
        _playbackEndsAt = null;
        _turnComplete = false;
        _emit('listening');
      }
    });
  }

  Future<void> _stopPlayback() async {
    _playbackTimer?.cancel();
    _playbackEndsAt = null;
    _playerTail = _playerTail.then((_) async {
      if (!_playerInitialized) return;
      await FlutterPcmSound.release();
      _playerInitialized = false;
      _playerInitialization = null;
    });
    await _playerTail;
  }

  @override
  void sendUserText(String text) {
    final normalized = text.trim();
    if (_closed || !_ready || normalized.isEmpty) return;
    _turnComplete = false;
    _emit('user', normalized);
    unawaited(_stopPlayback().then((_) {
      if (!_closed) {
        _send({
          'realtimeInput': {'text': normalized}
        });
      }
    }).catchError((Object _) {
      if (!_closed) _fail('microphone');
    }));
  }

  @override
  void mute(bool value) {
    _muted = value;
    if (value) {
      _send({
        'realtimeInput': {'audioStreamEnd': true}
      });
    }
  }

  void _send(Map<String, Object?> message) {
    if (!_closed && _socket?.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(message));
    }
  }

  void _emit(String type, [String text = '']) => _onEvent(type, text);

  void _emitError(String reason) => _emit('error', reason);

  void _fail(String reason) {
    if (_closed) return;
    _emitError(reason);
    unawaited(close());
  }

  @override
  Future<void> close() {
    if (_closeFuture != null) return _closeFuture!;
    if (_closed) return Future<void>.value();
    _closed = true;
    _ready = false;
    _handshakeTimer?.cancel();
    _expiryTimer?.cancel();
    _playbackTimer?.cancel();
    final completer = _connectCompleter;
    _connectCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(StateError('Connection closed'));
    }
    final socketSubscription = _socketSubscription;
    _socketSubscription = null;
    final microphoneSubscription = _microphoneSubscription;
    _microphoneSubscription = null;
    final socket = _socket;
    _socket = null;
    _closeFuture = _finishClose(
      socketSubscription,
      microphoneSubscription,
      socket,
    );
    return _closeFuture!;
  }

  Future<void> _finishClose(
    StreamSubscription<dynamic>? socketSubscription,
    StreamSubscription<Uint8List>? microphoneSubscription,
    WebSocket? socket,
  ) async {
    Future<void> ignoreFailure(Future<void> Function() operation) async {
      try {
        await operation();
      } catch (_) {}
    }

    try {
      await Future.wait<void>([
        if (socketSubscription != null)
          ignoreFailure(socketSubscription.cancel),
        if (microphoneSubscription != null)
          ignoreFailure(microphoneSubscription.cancel),
        if (socket != null)
          ignoreFailure(
              () => socket.close().timeout(const Duration(seconds: 1))),
        ignoreFailure(_recorder.dispose),
      ]);
      try {
        await _messageTail;
      } catch (_) {}
      try {
        await _playerInitialization;
      } catch (_) {}
      try {
        await _playerTail;
      } catch (_) {}
      if (_playerInitialized) {
        await ignoreFailure(FlutterPcmSound.release);
        _playerInitialized = false;
        _playerInitialization = null;
      }
    } finally {
      _releaseAudioSession();
    }
  }
}
