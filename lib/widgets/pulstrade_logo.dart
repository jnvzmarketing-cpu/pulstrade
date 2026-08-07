import 'package:flutter/material.dart';
import '../theme.dart';

class PulstradeLogo extends StatelessWidget {
  final double size;
  final bool showWordmark, darkIcon;
  const PulstradeLogo(
      {super.key,
      this.size = 36,
      this.showWordmark = true,
      this.darkIcon = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _P(dark: darkIcon || isDark)));
    if (!showWordmark) return icon;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      icon,
      SizedBox(width: size * 0.25),
      RichText(
          text: TextSpan(children: [
        TextSpan(
            text: 'Puls',
            style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black)),
        TextSpan(
            text: 'trade',
            style: TextStyle(
                fontSize: size * 0.38,
                fontWeight: FontWeight.w300,
                color: AppColors.gold)),
      ])),
    ]);
  }
}

class _P extends CustomPainter {
  final bool dark;
  const _P({this.dark = false});
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height),
            Radius.circular(s.width * 0.22)),
        Paint()..color = dark ? AppColors.darkCard : AppColors.gold);
    final pts = [
      Offset(s.width * .13, s.height * .67),
      Offset(s.width * .27, s.height * .45),
      Offset(s.width * .38, s.height * .54),
      Offset(s.width * .52, s.height * .27),
      Offset(s.width * .65, s.height * .37),
      Offset(s.width * .80, s.height * .15)
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fg = dark ? AppColors.gold : Colors.black;
    canvas.drawPath(
        path,
        Paint()
          ..color = fg
          ..strokeWidth = s.width * .065
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke);
    canvas.drawCircle(pts.last, s.width * .075, Paint()..color = fg);
  }

  @override
  bool shouldRepaint(_) => false;
}
