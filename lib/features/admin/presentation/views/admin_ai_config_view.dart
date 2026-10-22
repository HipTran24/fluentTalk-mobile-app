import 'package:flutter/material.dart';
import 'package:english_mobile_app/core/theme/app_colors.dart';
import 'package:english_mobile_app/core/theme/app_radius.dart';
import 'package:english_mobile_app/core/theme/app_spacing.dart';
import 'package:english_mobile_app/features/admin/domain/models/admin_models.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_controller.dart';
import 'package:english_mobile_app/features/admin/presentation/controllers/admin_state.dart';

class AdminAiConfigView extends StatefulWidget {
  final AdminState state;
  final AdminController controller;

  const AdminAiConfigView({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  State<AdminAiConfigView> createState() => _AdminAiConfigViewState();
}

class _AdminAiConfigViewState extends State<AdminAiConfigView> {
  late TextEditingController _promptController;
  late double _temperature;
  late double _bargeInSensitivity;
  late int _maxTurnDuration;
  late String _selectedModel;
  late String _ttsVoice;

  @override
  void initState() {
    super.initState();
    _initValues(widget.state.aiConfig);
  }

  void _initValues(AdminAiConfig? config) {
    _promptController = TextEditingController(text: config?.systemPrompt ?? '');
    _temperature = config?.temperature ?? 0.7;
    _bargeInSensitivity = config?.bargeInSensitivity ?? 0.85;
    _maxTurnDuration = config?.maxTurnDurationSec ?? 90;
    _selectedModel = config?.modelName ?? 'gemini-1.5-flash-live';
    _ttsVoice = config?.preferredTtsVoice ?? 'en-US-Journey-F';
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _save() {
    final current = widget.state.aiConfig;
    if (current != null) {
      final updated = current.copyWith(
        modelName: _selectedModel,
        temperature: _temperature,
        bargeInSensitivity: _bargeInSensitivity,
        maxTurnDurationSec: _maxTurnDuration,
        systemPrompt: _promptController.text,
        preferredTtsVoice: _ttsVoice,
      );
      widget.controller.updateAiConfig(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã cập nhật cấu hình Tom Gateway thành công!',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.state.aiConfig;
    if (config == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final isDesktop = MediaQuery.of(context).size.width >= 1100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMobile
                          ? 'Cấu hình Mô hình Tom'
                          : 'Cấu hình Mô hình Tom & Telemetry Gateway',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? 'Gemini 1.5 Live, Deepgram STT & Full-Duplex'
                          : 'Điều phối Gemini 1.5 Live, Deepgram STT và Tham số Đàm thoại Full-Duplex',
                      style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 12,
                          color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.cloud_done_rounded, size: 18),
                label: Text(
                  isMobile ? 'Lưu' : 'Lưu cấu hình',
                  style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Telemetry Status Card (WebSockets, Token Budget, P95 Latency)
          _buildTelemetryCard(config, isMobile),
          const SizedBox(height: AppSpacing.lg),

          // Main Configuration Form: Desktop (2 columns) vs Mobile (stacked)
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildParametersCard()),
                const SizedBox(width: AppSpacing.lg),
                Expanded(flex: 4, child: _buildSystemPromptCard()),
              ],
            )
          else ...[
            _buildParametersCard(),
            const SizedBox(height: AppSpacing.lg),
            _buildSystemPromptCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(AdminAiConfig config, bool isMobile) {
    final tokenPct =
        (config.monthlyTokensUsed / config.monthlyTokenQuota) * 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Giám sát Hạ tầng Trực tiếp (Live Telemetry)',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildMetricItem(
                label: 'Kênh WebSocket Đang Kết nối',
                value: '${config.activeWebSocketConnections} sessions',
                icon: Icons.wifi_tethering_rounded,
                color: AppColors.accent,
              ),
              _buildMetricItem(
                label: 'Độ trễ Đàm thoại (P95 Latency)',
                value: '420 ms',
                icon: Icons.speed_rounded,
                color: AppColors.primaryLight,
              ),
              _buildMetricItem(
                label: 'Ngân sách Token Gemini Tháng',
                value:
                    '${(config.monthlyTokensUsed / 1000000).toStringAsFixed(2)}M / ${(config.monthlyTokenQuota / 1000000).toStringAsFixed(0)}M (${tokenPct.toStringAsFixed(1)}%)',
                icon: Icons.pie_chart_outline_rounded,
                color: const Color(0xFFA855F7),
              ),
              _buildMetricItem(
                label: 'Tỷ lệ Ngắt lời (Barge-In Success)',
                value: '98.4%',
                icon: Icons.record_voice_over_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white)),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 12,
                    color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildParametersCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tham số Mô hình (Model Parameters)',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),

          // Chọn Model Tom
          const Text('Mô hình Hội thoại Realtime:',
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFCBD5E1))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedModel,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.white,
                fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'gemini-1.5-flash-live',
                  child: Text('Gemini 1.5 Flash Live (Siêu tốc, Khuyên dùng)',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
              DropdownMenuItem(
                  value: 'gemini-1.5-pro',
                  child: Text('Gemini 1.5 Pro (Suy luận sâu, Đánh giá Rubric)',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
              DropdownMenuItem(
                  value: 'deepgram-elevenlabs',
                  child: Text('Deepgram Nova-2 + ElevenLabs TTS',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedModel = val);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Temperature Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nhiệt độ sáng tạo (Temperature):',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFCBD5E1))),
              Text(_temperature.toStringAsFixed(2),
                  style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight)),
            ],
          ),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: AppColors.primaryLight,
            onChanged: (val) => setState(() => _temperature = val),
          ),
          const Text(
            'Giá trị thấp (0.2–0.5) giúp Tom kiên định theo kịch bản; giá trị cao (0.7–0.9) giúp phản xạ đa dạng, tự nhiên.',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),

          // Barge-in Sensitivity Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Độ nhạy ngắt lời (Barge-In Sensitivity):',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFFCBD5E1))),
              Text('${(_bargeInSensitivity * 100).toInt()}%',
                  style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
            ],
          ),
          Slider(
            value: _bargeInSensitivity,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            activeColor: AppColors.accent,
            onChanged: (val) => setState(() => _bargeInSensitivity = val),
          ),
          const Text(
            'Khi học viên phát âm trong lúc Tom đang nói, Tom lập tức dừng phát âm thanh nếu độ tin cậy vượt ngưỡng này.',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),

          // Preferred Voice
          const Text('Giọng đọc Tom (TTS Voice Persona):',
              style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFFCBD5E1))),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _ttsVoice,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.white,
                fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
            items: const [
              DropdownMenuItem(
                  value: 'en-US-Journey-F',
                  child: Text('Journey Female (Mỹ - Ấm áp, Tự nhiên)',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
              DropdownMenuItem(
                  value: 'en-US-Journey-M',
                  child: Text('Journey Male (Mỹ - Trầm ấm, Rõ ràng)',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
              DropdownMenuItem(
                  value: 'en-GB-Studio-B',
                  child: Text('British Studio (Anh-Anh - Chuẩn RP chuẩn mực)',
                      style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _ttsVoice = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPromptCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Text(
                'Mẫu Chỉ lệnh Hệ thống (System Prompt)',
                style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_promptController.text.length} ký tự (~${_promptController.text.length ~/ 4} tokens)',
                  style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Chỉ lệnh cốt lõi định hình phong cách giao tiếp, sự kiên nhẫn và chiến thuật đàm thoại của Tom đối với mọi lượt nói.',
            style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 12,
                color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _promptController,
            maxLines: 12,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFE2E8F0)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155))),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _promptController.text =
                        '''You are an empathetic, professional English conversation partner.
Guidelines:
1. Stay in character based on the scenario role.
2. Keep spoken responses concise (1 to 2 sentences) to encourage learner speaking time.
3. If learner makes grammar mistakes, maintain conversational flow, then provide subtle recasting.
4. If learner pauses for >3 seconds, offer gentle encouraging cues.''';
                  });
                },
                icon: const Icon(Icons.restore_rounded, size: 16),
                label: const Text('Đặt lại mặc định',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Lưu Thay Đổi',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
