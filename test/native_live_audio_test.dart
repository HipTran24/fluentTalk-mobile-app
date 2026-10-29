import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_mobile_app/features/conversation/data/live/live_audio_io.dart';
import 'package:english_mobile_app/features/conversation/data/live/native_live_audio.dart';

class FakeAudio implements NativeLiveAudio {
  final controller = StreamController<Map<Object?, Object?>>.broadcast();
  final played = <List<int>>[];
  int starts = 0, stops = 0, closes = 0;
  bool muted = false, denyPermission = false;
  @override
  Stream<Map<Object?, Object?>> get events => controller.stream;
  @override
  Future<void> prepare() async {
    if (denyPermission) throw PlatformException(code: 'permission');
  }

  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> play(Uint8List bytes) async {
    played.add(bytes.toList());
  }

  @override
  Future<void> stopPlayback() async {
    stops++;
  }

  @override
  Future<void> mute(bool value) async {
    muted = value;
  }

  @override
  Future<void> close() async {
    closes++;
  }
}

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 300 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue, reason: 'Asynchronous operation did not finish');
}

void main() {
  late HttpServer server;
  late FakeAudio audio;
  late LiveAudioClient client;
  late WebSocket peer;
  late List<Map<String, dynamic>> sent;
  late List<(String, String)> events;
  late Map<String, dynamic> ticket;
  var acknowledge = true;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    audio = FakeAudio();
    sent = [];
    events = [];
    acknowledge = true;
    ticket = {
      'token': 'auth_tokens/test-only',
      'setup': {'model': 'models/test'},
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String()
    };
    server.listen((request) async {
      peer = await WebSocketTransformer.upgrade(request);
      peer.listen((data) {
        final value = jsonDecode(data as String) as Map<String, dynamic>;
        sent.add(value);
        if (value.containsKey('setup') && acknowledge) {
          peer.add(jsonEncode({'setupComplete': <String, dynamic>{}}));
        }
      });
    });
    client = LiveAudioClient((type, text) => events.add((type, text)),
        audio: audio, connector: (uri) {
      expect(uri.scheme, 'wss');
      expect(uri.host, 'generativelanguage.googleapis.com');
      expect(uri.queryParameters['access_token'], 'auth_tokens/test-only');
      return WebSocket.connect('ws://127.0.0.1:${server.port}');
    }, handshakeTimeout: const Duration(seconds: 3));
  });
  tearDown(() async {
    client.close();
    await audio.controller.close();
    await server.close(force: true);
  });

  test('empty-object setup acknowledgement starts PCM microphone and greeting',
      () async {
    await client.prepare();
    await client.connect(ticket);
    expect(audio.starts, 1);
    expect(events.where((e) => e.$1 == 'ready'), hasLength(1));
    audio.controller.add({
      'type': 'pcm',
      'pcm': Uint8List.fromList([0, 1, 2, 3])
    });
    await until(
        () => sent.any((m) => (m['realtimeInput'] as Map?)?['audio'] != null));
    final input = (sent.last['realtimeInput'] as Map)['audio'] as Map;
    expect(input['mimeType'], 'audio/pcm;rate=16000');
    expect(base64Decode(input['data'] as String), [0, 1, 2, 3]);
  });
  test('plays actual AI PCM in order and forwards both transcripts', () async {
    await client.prepare();
    await client.connect(ticket);
    peer.add(jsonEncode({
      'serverContent': {
        'inputTranscription': {'text': 'Hello Tom'},
        'outputTranscription': {'text': 'Hello there'},
        'modelTurn': {
          'parts': [
            {
              'inlineData': {
                'mimeType': 'audio/pcm;rate=24000',
                'data': base64Encode([1, 0, 2, 0])
              }
            },
            {
              'inlineData': {
                'mimeType': 'audio/pcm;rate=24000',
                'data': base64Encode([3, 0])
              }
            }
          ]
        },
        'turnComplete': true
      }
    }));
    await until(() => audio.played.length == 2);
    expect(audio.played, [
      [1, 0, 2, 0],
      [3, 0]
    ]);
    expect(events, contains(('user', 'Hello Tom')));
    expect(events, contains(('ai', 'Hello there')));
    expect(events.last.$1, 'speaking');
    audio.controller.add({'type': 'drained'});
    await until(() => events.last.$1 == 'listening');
    peer.add(jsonEncode({
      'serverContent': {'interrupted': true}
    }));
    await until(() => audio.stops == 1);
  });
  test('mute stops uplink only, AI output continues, unmute resumes mic',
      () async {
    await client.prepare();
    await client.connect(ticket);
    client.mute(true);
    audio.controller.add({
      'type': 'pcm',
      'pcm': Uint8List.fromList([1, 0])
    });
    await until(() => sent
        .any((m) => (m['realtimeInput'] as Map?)?['audioStreamEnd'] == true));
    expect(audio.muted, isTrue);
    expect(sent.where((m) => (m['realtimeInput'] as Map?)?['audio'] != null),
        isEmpty);
    peer.add(jsonEncode({
      'serverContent': {
        'modelTurn': {
          'parts': [
            {
              'inlineData': {'mimeType': 'audio/pcm;rate=24000', 'data': 'AQA='}
            }
          ]
        }
      }
    }));
    await until(() => audio.played.isNotEmpty);
    client.mute(false);
    audio.controller.add({
      'type': 'pcm',
      'pcm': Uint8List.fromList([2, 0])
    });
    await until(
        () => sent.any((m) => (m['realtimeInput'] as Map?)?['audio'] != null));
  });
  test('cancel during handshake settles immediately and ignores late frames',
      () async {
    acknowledge = false;
    await client.prepare();
    final connection = client.connect(ticket);
    final check = expectLater(connection, throwsStateError);
    await until(() => sent.isNotEmpty);
    client.close();
    client.close();
    await check;
    expect(audio.closes, 1);
    expect(audio.starts, 0);
    expect(events, isEmpty);
  });
  test('handshake timeout settles and releases microphone', () async {
    acknowledge = false;
    await client.prepare();
    await expectLater(client.connect(ticket), throwsStateError);
    expect(events, contains(('error', 'timeout')));
    expect(audio.closes, 1);
  });
  test('object goAway expires session and closes all resources', () async {
    await client.prepare();
    await client.connect(ticket);
    peer.add(jsonEncode({
      'goAway': {'timeLeft': '0s'}
    }));
    await until(() => audio.closes == 1);
    expect(events, contains(('error', 'expired')));
  });
  test('permission failure is actionable and never connects to Gemini',
      () async {
    audio.denyPermission = true;
    await expectLater(client.prepare(), throwsA(isA<PlatformException>()));
    expect(events, [('error', 'permission')]);
    expect(sent, isEmpty);
    expect(audio.closes, 1);
  });
  test('invalid output audio fails safely rather than playing corrupt PCM',
      () async {
    await client.prepare();
    await client.connect(ticket);
    peer.add(jsonEncode({
      'serverContent': {
        'modelTurn': {
          'parts': [
            {
              'inlineData': {'mimeType': 'audio/pcm;rate=24000', 'data': 'AQ=='}
            }
          ]
        }
      }
    }));
    await until(() => audio.closes == 1);
    expect(audio.played, isEmpty);
    expect(events, contains(('error', 'provider')));
  });
  test('provider close settles pending handshake without waiting for timeout',
      () async {
    acknowledge = false;
    await client.prepare();
    final pending = client.connect(ticket);
    final check = expectLater(pending, throwsStateError);
    await until(() => sent.isNotEmpty);
    await peer.close(1008, 'denied');
    await check;
    expect(events, contains(('error', 'access')));
  });
  test('cancel while socket is opening settles without waiting for DNS or TLS',
      () async {
    client.close();
    final opening = Completer<WebSocket>();
    client = LiveAudioClient((type, text) => events.add((type, text)),
        audio: audio, connector: (_) => opening.future);
    await client.prepare();
    final connection = client.connect(ticket);
    final check = expectLater(connection, throwsStateError);
    client.close();
    await check.timeout(const Duration(seconds: 1));
    final lateSocket = await WebSocket.connect('ws://127.0.0.1:${server.port}');
    opening.complete(lateSocket);
    await until(() => lateSocket.readyState == WebSocket.closed);
    expect(events, isEmpty);
  });

  test('provider 1011 near credential expiry is a normal ended session',
      () async {
    ticket['expiresAt'] = DateTime.now()
        .add(const Duration(seconds: 8))
        .toUtc()
        .toIso8601String();
    await client.prepare();
    await client.connect(ticket);
    await peer.close(1011, 'deadline expired');
    await until(() => audio.closes == 1);
    expect(events, contains(('error', 'expired')));
    expect(events, isNot(contains(('error', 'disconnected'))));
  });
  test('early provider 1011 still reports a disconnection', () async {
    await client.prepare();
    await client.connect(ticket);
    await peer.close(1011, 'unavailable');
    await until(() => audio.closes == 1);
    expect(events, contains(('error', 'disconnected')));
    expect(events, isNot(contains(('error', 'expired'))));
  });
}
