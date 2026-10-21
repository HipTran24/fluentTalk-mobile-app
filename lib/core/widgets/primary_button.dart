import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Primary Brand Button
/// Compliant with ESP-PLAN-001 Appendix B1 (min height 48-52dp, touch target >= 48dp)
///
/// Renders the brand gradient by default; pass [backgroundColor] for a solid fill.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
  });

  /// Directional arrows read better after the label.
  bool get _isTrailingIcon =>
      icon == Icons.arrow_forward ||
      icon == Icons.arrow_forward_rounded ||
      icon == Icons.arrow_forward_ios_rounded ||
      icon == Icons.chevron_right_rounded;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    final fg = foregroundColor ?? Colors.white;
    final glowColor = backgroundColor ?? AppColors.brandViolet;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled || isLoading ? 1 : 0.5,
      child: Container(
        width: width ?? double.infinity,
        height: AppSpacing.buttonHeightStandard,
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: backgroundColor == null ? AppColors.brandGradient : null,
          borderRadius: AppRadius.buttonRadius,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: glowColor.withOpacity(0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: AppRadius.buttonRadius,
            splashColor: Colors.white.withOpacity(0.18),
            highlightColor: Colors.white.withOpacity(0.08),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null && !_isTrailingIcon) ...[
                            Icon(icon, size: 20, color: fg),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Flexible(
                            child: Text(
                              text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: fg,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          if (icon != null && _isTrailingIcon) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(icon, size: 20, color: fg),
                          ],
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined Secondary Button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: AppSpacing.buttonHeightStandard,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: borderColor ?? AppColors.border,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
