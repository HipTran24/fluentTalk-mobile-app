import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Responsive wrapper that ensures the layout looks native and comfortable
/// on both Mobile screens and Desktop / Web browsers.
///
/// On web/desktop screens wider than [maxWidth], it centers the mobile layout
/// or scales nicely with a subtle background and frame.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? backgroundColor;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = 520.0,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > maxWidth) {
          return Container(
            color: backgroundColor ??
                (kIsWeb ? const Color(0xFFE2E8F0) : AppColors.background),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: constraints.maxHeight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
