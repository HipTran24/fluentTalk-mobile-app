import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AcademicPanel extends StatelessWidget {
  const AcademicPanel({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF131B2E) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE7EAF2)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x040F172A), blurRadius: 24, offset: Offset(0, 8))
          ]),
      child: Material(color: Colors.transparent, child: child));
}

class AcademicHeading extends StatelessWidget {
  const AcademicHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFF8FAFC) : AppColors.textPrimary, letterSpacing: -.5)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : AppColors.textSecondary, height: 1.5)),
        if (action != null) action!,
      ]));
}

class AcademicGrid extends StatelessWidget {
  const AcademicGrid({super.key, required this.children, this.minWidth = 260});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final count =
            (constraints.maxWidth / minWidth).floor().clamp(1, children.length);
        final width = (constraints.maxWidth - (count - 1) * 16) / count;
        return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList());
      });
}

class AcademicAction extends StatelessWidget {
  const AcademicAction(
      {super.key,
      required this.title,
      required this.description,
      required this.icon,
      required this.tag,
      required this.onTap,
      this.color = AppColors.primary});
  final String title, description, tag;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7EAF2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(16)),
                              child: Icon(icon, color: color, size: 26)),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: .07),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(tag,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                        ]),
                    const SizedBox(height: 24),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4)),
                    const SizedBox(height: 10),
                    Text(description,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.65)),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: Text('Khám phá',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13))),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, size: 19, color: color)
                    ]),
                  ]))));
}

class AcademicHero extends StatelessWidget {
  const AcademicHero(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.onStart,
      this.name = 'SPEAKING STUDIO'});
  final String title, subtitle, name;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) => Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF17234A),
                Color(0xFF34327B),
                Color(0xFF5251A5)
              ])),
      child: LayoutBuilder(
          builder: (context, c) => Stack(children: [
                Positioned(
                    right: -65,
                    top: -85,
                    child: ExcludeSemantics(
                        child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: .08),
                                    width: 42))))),
                Padding(
                    padding: EdgeInsets.all(c.maxWidth < 500 ? 24 : 36),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      size: 15, color: Color(0xFFBDBBF8)),
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.6,
                                          color: Color(0xFFD1CFFB)))
                                ]),
                            const SizedBox(height: 20),
                            Text(title,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: c.maxWidth < 500 ? 27 : 34,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    letterSpacing: -.9)),
                            const SizedBox(height: 14),
                            Text(subtitle,
                                style: const TextStyle(
                                    color: Color(0xFFD3D7ED),
                                    height: 1.7,
                                    fontSize: 14)),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                                onPressed: onStart,
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF263362),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18)),
                                icon: const Icon(Icons.headset_mic_outlined,
                                    size: 19),
                                label:
                                    const Text('Nói chuyện trực tiếp với Tom')),
                          ])),
                      if (c.maxWidth > 760) ...[
                        const SizedBox(width: 40),
                        ExcludeSemantics(
                            child: Container(
                                width: 165,
                                height: 165,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: .07),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: .15))),
                                child: Center(
                                    child: Container(
                                        width: 112,
                                        height: 112,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white
                                                .withValues(alpha: .1)),
                                        child: const Icon(
                                            Icons.graphic_eq_rounded,
                                            size: 64,
                                            color: Color(0xFFE7E5FF))))))
                      ],
                    ])),
              ])));
}
