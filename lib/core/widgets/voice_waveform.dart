import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Animated Waveform Visualizer for Speaking & AI Audio Playback
/// Compliant with Appendix B11, B12, B14
class VoiceWaveform extends StatefulWidget {
  final bool isActive;
  final Color? color;
  final int barCount;
  final double height;
  final double barWidth;

  const VoiceWaveform({
    super.key,
    this.isActive = true,
    this.color,
    this.barCount = 24,
    this.height = 48.0,
    this.barWidth = 3.5,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.color ?? AppColors.primary;

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              double multiplier = 0.2;
              if (widget.isActive) {
                final phase = (index / widget.barCount) * 2 * math.pi;
                final animVal = _controller.value * 2 * math.pi;
                multiplier = (math.sin(phase + animVal).abs() * 0.75) + 0.25;
              }

              final barHeight = (widget.height * multiplier).clamp(4.0, widget.height);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: widget.barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: waveColor.withOpacity(widget.isActive ? 0.9 : 0.3),
                  borderRadius: BorderRadius.circular(widget.barWidth / 2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
