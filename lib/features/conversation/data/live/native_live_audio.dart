import 'dart:async';
import 'package:flutter/services.dart';

abstract class NativeLiveAudio {
  Stream<Map<Object?, Object?>> get events;
  Future<void> prepare();
  Future<void> start();
  Future<void> play(Uint8List bytes);
  Future<void> stopPlayback();
  Future<void> mute(bool value);
  Future<void> close();
}

/// Session IDs keep late permission/audio callbacks out of a replacement call.
class AndroidLiveAudio implements NativeLiveAudio {
  static const _methods = MethodChannel('fluenttalk/live_audio');
  static const _events = EventChannel('fluenttalk/live_audio/events');
  static final _stream = _events.receiveBroadcastStream().asBroadcastStream();
  static int _nextId = 0;
  final int _id = ++_nextId;

  @override
  Stream<Map<Object?, Object?>> get events => _stream
      .where((event) => event is Map && event['session'] == _id)
      .map((event) => Map<Object?, Object?>.from(event as Map));

  Future<void> _call(String method, [Map<String, Object?> args = const {}]) =>
      _methods.invokeMethod<void>(method, {'session': _id, ...args});

  @override
  Future<void> prepare() => _call('prepare');
  @override
  Future<void> start() => _call('start');
  @override
  Future<void> play(Uint8List bytes) => _call('play', {'pcm': bytes});
  @override
  Future<void> stopPlayback() => _call('stopPlayback');
  @override
  Future<void> mute(bool value) => _call('mute', {'muted': value});
  @override
  Future<void> close() => _call('close');
}
