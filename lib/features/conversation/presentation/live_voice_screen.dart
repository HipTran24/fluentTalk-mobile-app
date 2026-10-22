import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/live/live_audio_client.dart';
import '../../connected/presentation/academic_widgets.dart';

class LiveVoiceScreen extends ConsumerStatefulWidget {
  const LiveVoiceScreen({super.key});
  @override
  ConsumerState<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends ConsumerState<LiveVoiceScreen>
    with WidgetsBindingObserver {
  LiveAudioClient? _audio;
  Timer? _timer;
  ApiClient? _learningApi;
  String? _learningSessionId;
  bool _saveTranscriptAllowed = false;
  bool _voiceSelected = false;
  Future<void> _loadDefaults() async {
    try {
      final data = await ref.read(apiClientProvider)?.get('me/learning');
      if (!mounted || _active || _connecting || _voiceSelected) return;
      if (data is Map && data['settings'] is Map) {
        final settings = data['settings'] as Map;
        if (settings['enabled'] == true &&
            ['Aoede', 'Kore', 'Puck', 'Charon'].contains(settings['voice'])) {
          setState(() => _voice = settings['voice'] as String);
        }
      }
    } catch (_) {}
  }

  void _persistVoiceNote() {
    final id = _learningSessionId;
    final api = _learningApi;
    _learningSessionId = null;
    if (!_saveTranscriptAllowed || id == null || api == null) return;
    final lines = _captions
        .where((c) => c.role == 'user')
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    if (lines.isEmpty) return;
    final text =
        lines.length > 8000 ? lines.substring(lines.length - 8000) : lines;
    unawaited(api.post('me/learning/voice-notes', data: {
      'sessionId': id,
      'transcript': text
    }).then<void>((_) {}, onError: (Object error, StackTrace stack) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Cuộc gọi đã dừng nhưng chưa lưu được phụ đề cho Tom.')));
      }
    }));
  }

  final List<({String role, String text})> _captions = [];
  bool _connecting = false, _active = false, _muted = false, _speaking = false;
  String _voice = 'Aoede';
  String? _error;
  int _seconds = 0;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDefaults();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_active || _connecting) {
        _end('Cuộc gọi đã dừng khi ứng dụng chuyển nền.');
      }
    }
  }

  void _cleanup() {
    _generation++;
    _audio?.close();
    _audio = null;
    _timer?.cancel();
  }

  void _end([String? message, bool save = true]) {
    if (save) {
      _persistVoiceNote();
    } else {
      _learningSessionId = null;
    }
    _cleanup();
    if (mounted) {
      setState(() {
        _active = false;
        _connecting = false;
        _speaking = false;
        _error = message;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistVoiceNote();
    _cleanup();
    super.dispose();
  }

  void _event(int generation, String type, String text) {
    if (!mounted || generation != _generation) return;
    if (type == 'error') {
      _end(switch (text) {
        'permission' =>
          'Micro chưa được cho phép. Bật quyền micro cho trang này rồi gọi lại.',
        'unsupported' =>
          'Trình duyệt chưa hỗ trợ. Hãy dùng Chrome/Edge trên localhost hoặc HTTPS.',
        'microphone' =>
          'Không mở được micro. Kiểm tra thiết bị và đóng ứng dụng đang chiếm micro.',
        'access' ||
        'provider' =>
          'Gemini Live từ chối phiên. Kiểm tra API key, model và quyền truy cập trên máy chủ.',
        'expired' => 'Phiên đã kết thúc. Bạn có thể bắt đầu cuộc gọi mới.',
        'background' => 'Cuộc gọi đã dừng khi bạn chuyển sang tab khác.',
        'timeout' => 'Kết nối Tom quá lâu. Kiểm tra mạng rồi gọi lại.',
        _ => 'Kết nối âm thanh bị ngắt. Kiểm tra mạng rồi gọi lại.',
      });
      return;
    }
    setState(() {
      if (type == 'ready') {
        _active = true;
        _connecting = false;
      }
      if (type == 'speaking') _speaking = true;
      if (type == 'listening') _speaking = false;
      if ((type == 'user' || type == 'ai') && text.isNotEmpty) {
        if (_captions.isNotEmpty && _captions.last.role == type) {
          final last = _captions.removeLast();
          final combined = last.text + text;
          _captions.add((
            role: type,
            text: combined.length > 8000
                ? combined.substring(combined.length - 8000)
                : combined
          ));
        } else {
          _captions.add((role: type, text: text));
        }
        if (_captions.length > 100) _captions.removeAt(0);
      }
    });
  }

  Future<void> _start() async {
    if (_connecting || _active) return;
    final api = ref.read(apiClientProvider);
    if (api == null) {
      setState(() => _error = 'Chưa cấu hình kết nối máy chủ.');
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
      _captions.clear();
      _seconds = 0;
      _muted = false;
      _saveTranscriptAllowed = false;
      _learningSessionId = null;
      _learningApi = api;
    });
    final generation = ++_generation;
    try {
      final audio =
          LiveAudioClient((type, text) => _event(generation, type, text));
      _audio = audio;
      if (!audio.supported) {
        _end('Hội thoại giọng nói hiện hỗ trợ trên bản web.');
        return;
      }
      // Open AudioContext directly from the tap before network awaits (autoplay policy).
      await audio.prepare();
      if (!mounted || generation != _generation) return;
      final data = await api.post('ai/live-token', data: {
        'voice': _voice,
        'level':
            ref.read(authControllerProvider).user?.level.name.toUpperCase() ??
                'A1',
      });
      if (!mounted || generation != _generation) return;
      if (data is! Map<String, dynamic>) throw const FormatException();
      _saveTranscriptAllowed = data['saveTranscriptAllowed'] == true;
      _learningSessionId = data['learningSessionId'] as String?;
      await audio.connect(data);
      if (!mounted || generation != _generation) return;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || generation != _generation) {
          timer.cancel();
          return;
        }
        setState(() => _seconds++);
        if (_seconds >= 300) {
          _end('Đã hết 5 phút của phiên. Bạn có thể bắt đầu phiên mới.');
        }
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      _end(error is ApiFailure
          ? error.message
          : 'Chưa thể mở cuộc gọi. Kiểm tra micro, kết nối và cấu hình Gemini.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider.select((auth) => auth.user?.id),
        (previous, next) {
      if (previous != next) {
        _end('Tài khoản đã thay đổi. Cuộc gọi đã dừng.', false);
      }
    });
    final engaged = _active || _connecting;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Trò chuyện giọng nói')),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AcademicPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Text('FLUENTTALK · SPEAKING STUDIO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.textMuted)),
                const SizedBox(height: 32),
                CircleAvatar(
                    radius: 68,
                    backgroundColor: _active
                        ? AppColors.secondaryLight
                        : const Color(0xFF1E2C57),
                    child: Icon(
                        _speaking
                            ? Icons.graphic_eq
                            : Icons.headset_mic_outlined,
                        size: 48,
                        color: _active
                            ? AppColors.primary
                            : const Color(0xFFD1CFFB))),
                const SizedBox(height: 20),
                Text(
                    _connecting
                        ? 'Đang kết nối…'
                        : _active
                            ? (_speaking
                                ? 'Tom đang trả lời'
                                : _muted
                                    ? 'Micro đang tắt'
                                    : 'Tom đang lắng nghe bạn')
                            : 'Cùng nói tiếng Anh nhé',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(
                    _active
                        ? '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')} / 05:00'
                        : 'Nói tự nhiên, Tom sẽ nghe và trả lời bằng giọng nói. Bạn có thể ngắt lời Tom để hỏi tiếp.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                    initialValue: _voice,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Giọng Tom', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'Aoede', child: Text('Aoede · Nhẹ nhàng')),
                      DropdownMenuItem(
                          value: 'Kore', child: Text('Kore · Rõ ràng')),
                      DropdownMenuItem(
                          value: 'Puck', child: Text('Puck · Tươi vui')),
                      DropdownMenuItem(
                          value: 'Charon', child: Text('Charon · Điềm tĩnh'))
                    ],
                    onChanged: engaged
                        ? null
                        : (value) => setState(() {
                              _voiceSelected = true;
                              _voice = value ?? 'Aoede';
                            })),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Semantics(
                          liveRegion: true,
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.error)))),
                if (!engaged)
                  FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.call),
                      label: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Bắt đầu nói chuyện'))),
                if (engaged)
                  Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (_active)
                          OutlinedButton.icon(
                              onPressed: () {
                                setState(() => _muted = !_muted);
                                _audio?.mute(_muted);
                              },
                              icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                              label: Text(_muted ? 'Bật micro' : 'Tắt micro')),
                        FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error),
                            onPressed: () => _end(),
                            icon: const Icon(Icons.call_end),
                            label:
                                Text(_connecting ? 'Hủy kết nối' : 'Kết thúc')),
                      ]),
                const SizedBox(height: 20),
                const Text(
                    'Khi bắt đầu, âm thanh micro được gửi đến Google Gemini để Tom trả lời. App không lưu bản ghi âm. Phụ đề chỉ được lưu tối đa 30 ngày nếu bạn bật ghi nhớ trong mục Tom. Mỗi lần cấp phiên tính tối đa 5 phút vào hạn mức gọi trong ngày; dừng sớm vẫn tính một phiên.',
                    style:
                        TextStyle(color: AppColors.textSecondary, height: 1.5)),
                if (_captions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Phụ đề trực tiếp',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._captions.map((caption) => Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(caption.role == 'ai' ? 'Tom' : 'Bạn',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary)),
                                const SizedBox(height: 6),
                                SelectableText(caption.text),
                              ])))),
                ],
              ])),
        )),
      )),
    );
  }
}
