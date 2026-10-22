import 'package:flutter/material.dart';

/// Stacks controls when enlarged text leaves too little horizontal space.
/// Unlike shrinking text, this keeps the user's accessibility setting intact.
class AdaptiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextBaseline? textBaseline;

  const AdaptiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textBaseline,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // OverflowBar measures actual child widths, including the bundled font.
      // It keeps short controls horizontal and stacks only when they do not fit.
      if (constraints.hasBoundedWidth &&
          !children.any((child) => child is Flexible || child is Spacer)) {
        return OverflowBar(
          alignment: mainAxisAlignment,
          overflowAlignment: OverflowBarAlignment.start,
          overflowSpacing: 4,
          children: children,
        );
      }
      final enlarged = MediaQuery.textScalerOf(context).scale(14) > 18;
      if (enlarged &&
          constraints.hasBoundedWidth &&
          constraints.maxWidth < 600) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.where((child) => child is! Spacer).map((child) {
            if (child is Flexible) return child.child;
            if (child is SizedBox &&
                child.child == null &&
                child.width != null) {
              return SizedBox(height: child.width);
            }
            return child;
          }).toList(),
        );
      }
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textBaseline: textBaseline,
        children: children,
      );
    });
  }
}
