import '../../core/widgets/adaptive_row.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Audio Player Bar with Replay & Speed Controller (0.75x, 1x, 1.25x)
/// Compliant with MODE-01 and Appendix B10, B12
class AudioPlayerBar extends StatefulWidget {
  final String? audioUrl;
  final Duration totalDuration;
  final ValueChanged<double>? onSpeedChanged;

  const AudioPlayerBar({
    super.key,
    this.audioUrl,
    this.totalDuration = const Duration(seconds: 15),
    this.onSpeedChanged,
  });

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  bool _isPlaying = false;
  double _currentProgress = 0.0;
  double _speed = 1.0;

  final List<double> _speeds = [0.75, 1.0, 1.25];

  void _toggleSpeed() {
    final currentIndex = _speeds.indexOf(_speed);
    final nextIndex = (currentIndex + 1) % _speeds.length;
    setState(() {
      _speed = _speeds[nextIndex];
    });
    widget.onSpeedChanged?.call(_speed);
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _replay() {
    setState(() {
      _currentProgress = 0.0;
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: AdaptiveRow(
        children: [
          // Play / Pause Button
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: AppColors.primary,
              size: 32,
            ),
            onPressed: _togglePlay,
            tooltip: _isPlaying ? 'Tạm dừng' : 'Nghe phát âm',
          ),

          // Replay Button
          IconButton(
            icon: const Icon(Icons.replay,
                color: AppColors.textSecondary, size: 20),
            onPressed: _replay,
            tooltip: 'Phát lại',
          ),

          // Progress Bar
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: _currentProgress,
                onChanged: (val) {
                  setState(() {
                    _currentProgress = val;
                  });
                },
              ),
            ),
          ),

          // Speed Pill Button
          InkWell(
            onTap: _toggleSpeed,
            borderRadius: BorderRadius.circular(AppRadius.round),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.round),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${_speed}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
