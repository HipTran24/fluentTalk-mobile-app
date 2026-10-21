import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Level Badge / Chip (A0 - C2)
class LevelChip extends StatelessWidget {
  final UserLevel level;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showDescription;

  const LevelChip({
    super.key,
    required this.level,
    this.isSelected = false,
    this.onTap,
    this.showDescription = false,
  });

  Color _getLevelColor(UserLevel lvl) {
    switch (lvl) {
      case UserLevel.a0:
        return const Color(0xFF64748B); // Slate
      case UserLevel.a1:
        return const Color(0xFF0284C7); // Sky blue
      case UserLevel.a2:
        return const Color(0xFF0D9488); // Teal
      case UserLevel.b1:
        return const Color(0xFF16A34A); // Green
      case UserLevel.b2:
        return const Color(0xFFD97706); // Amber
      case UserLevel.c1:
        return const Color(0xFF4F46E5); // Indigo
      case UserLevel.c2:
        return const Color(0xFF9333EA); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(level);

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.round),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.round),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level.code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  level.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.round),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '${level.code} • ${level.label}',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
