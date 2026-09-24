// Equity-Kurve: kumuliertes R über die Zeit, jeder Trade ein Punkt.
// Die Grafik, die einem Free-Nutzer zeigt, was das Konto gemacht hätte.
import "dart:math" as math;
import "package:flutter/cupertino.dart";
import "../core/format.dart";
import "../core/pt_theme.dart";
import "../models/signal.dart";

class EquityChart extends StatelessWidget {
  final List<Signal> closed; // beliebige Reihenfolge
  final double height;
  const EquityChart({super.key, required this.closed, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final pts = closed.where((s) => s.pnlR != null).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pts.length < 2) return SizedBox(height: height, child: Center(child: Text("Ab zwei abgeschlossenen Trades erscheint hier die Kurve.", style: PT.footnote.copyWith(color: PT.textSecondary))));
    return SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _P(pts)));
  }
}

class _P extends CustomPainter {
  final List<Signal> pts;
  _P(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    const padR = 44.0, padT = 12.0, padB = 18.0;
    final w = size.width - padR, h = size.height - padT - padB;
    final cum = <double>[0];
    for (final s in pts) cum.add(cum.last + s.pnlR!);
    final lo = math.min(0.0, cum.reduce(math.min)), hi = math.max(0.0, cum.reduce(math.max));
    final span = math.max(hi - lo, 1.0);
    double y(double v) => padT + h - (v - lo) / span * h;
    double x(int i) => i / (cum.length - 1) * w;

    // Null-Linie
    canvas.drawLine(Offset(0, y(0)), Offset(w, y(0)), Paint()..color = PT.hairline..strokeWidth = 1);
    final t0 = _t("0 R", PT.textTertiary); t0.paint(canvas, Offset(w + 6, y(0) - t0.height / 2));

    final positive = cum.last >= 0;
    final col = positive ? PT.buy : PT.sell;
    final path = Path()..moveTo(x(0), y(cum[0]));
    for (var i = 1; i < cum.length; i++) path.lineTo(x(i), y(cum[i]));
    final fill = Path.from(path)..lineTo(x(cum.length - 1), y(0))..lineTo(0, y(0))..close();
    canvas.drawPath(fill, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withValues(alpha: .25), col.withValues(alpha: 0)]).createShader(Rect.fromLTWH(0, padT, w, h)));
    canvas.drawPath(path, Paint()..color = col..strokeWidth = 2..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);
    for (var i = 1; i < cum.length; i++) {
      final win = pts[i - 1].pnlR! >= 0;
      canvas.drawCircle(Offset(x(i), y(cum[i])), 3, Paint()..color = win ? PT.buy : PT.sell);
      canvas.drawCircle(Offset(x(i), y(cum[i])), 3, Paint()..color = PT.card..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
    final last = _t(rr(cum.last), col, bold: true);
    last.paint(canvas, Offset(w + 6, y(cum.last) - last.height / 2));

    final sameDay = ddmm(pts.first.timestamp) == ddmm(pts.last.timestamp);
    final a = _t(sameDay ? hhmm(pts.first.timestamp) : ddmm(pts.first.timestamp), PT.textTertiary);
    final b = _t(sameDay ? hhmm(pts.last.timestamp) : ddmm(pts.last.timestamp), PT.textTertiary);
    a.paint(canvas, Offset(0, size.height - padB + 4));
    b.paint(canvas, Offset(w - b.width, size.height - padB + 4));
  }

  TextPainter _t(String s, Color c, {bool bold = false}) => TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontFamily: ".SF Pro Text", fontSize: 10, fontWeight: bold ? FontWeight.w600 : FontWeight.w500, color: c, fontFeatures: tabular)),
        textDirection: TextDirection.ltr)..layout();

  @override
  bool shouldRepaint(_P o) => o.pts != pts;
}
