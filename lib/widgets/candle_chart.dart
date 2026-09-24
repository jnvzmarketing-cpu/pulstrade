// Candlestick-Chart, eigener Painter.
//  - Kerzen, Zeitachse unten, Preisskala rechts, dezentes Raster
//  - Zone als Band (Entry 1 bis Entry 2), Stop als roter Bereich, Ziele als Linien
//  - Live-Kurs als gestrichelte Linie mit Label, pulsiert
//  - Wischen (Pan), Pinch (Zoom), Long-Press (Crosshair mit OHLC und Zeit)
//  - zeichnet sich beim ersten Aufbau von links nach rechts ein
import "dart:math" as math;
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "../core/format.dart";
import "../core/pt_theme.dart";
import "../services/market_repo.dart";

class ChartLevel {
  final String label;
  final double price;
  final Color color;
  const ChartLevel(this.label, this.price, this.color);
}

/// Zone: Bereich zwischen zwei Entries (oder entry +/- 0 bei einem Entry).
class ChartZone {
  final double top, bottom;
  final double? sl;
  final bool buy;
  const ChartZone({required this.top, required this.bottom, this.sl, required this.buy});
}

class CandleChart extends StatefulWidget {
  final List<Candle> candles; // chronologisch
  final List<ChartLevel> levels;
  final ChartZone? zone;
  final double? livePrice;
  final double height;
  final int initialVisible;
  const CandleChart({super.key, required this.candles, this.levels = const [], this.zone, this.livePrice, this.height = 260, this.initialVisible = 60});

  @override
  State<CandleChart> createState() => _CandleChartState();
}

class _CandleChartState extends State<CandleChart> with TickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  double _visible = 60;      // sichtbare Kerzen
  double _offset = 0;        // Kerzen vom rechten Rand weg
  double _scaleStart = 60;
  Offset? _cross;

  @override
  void initState() { super.initState(); _visible = widget.initialVisible.toDouble(); }
  @override
  void dispose() { _draw.dispose(); _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = widget.candles;
    if (c.length < 5) {
      return SizedBox(height: widget.height, child: const Center(child: CupertinoActivityIndicator()));
    }
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GestureDetector(
        onScaleStart: (_) { _scaleStart = _visible; },
        onScaleUpdate: (d) {
          setState(() {
            if (d.pointerCount > 1) {
              _visible = (_scaleStart / d.scale).clamp(20, c.length.toDouble());
            } else {
              final perCandle = (context.size!.width - 58) / _visible;
              _offset = (_offset - d.focalPointDelta.dx / perCandle).clamp(0, math.max(0, c.length - _visible));
            }
          });
        },
        onLongPressStart: (d) { HapticFeedback.selectionClick(); setState(() => _cross = d.localPosition); },
        onLongPressMoveUpdate: (d) => setState(() => _cross = d.localPosition),
        onLongPressEnd: (_) => setState(() => _cross = null),
        child: AnimatedBuilder(
          animation: Listenable.merge([_draw, _pulse]),
          builder: (_, __) => CustomPaint(
            painter: _Painter(
              candles: c, levels: widget.levels, zone: widget.zone, live: widget.livePrice,
              visible: _visible, offset: _offset, draw: Curves.easeOutCubic.transform(_draw.value),
              pulse: _pulse.value, cross: _cross,
            ),
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<Candle> candles;
  final List<ChartLevel> levels;
  final ChartZone? zone;
  final double? live;
  final double visible, offset, draw, pulse;
  final Offset? cross;
  _Painter({required this.candles, required this.levels, required this.zone, required this.live, required this.visible, required this.offset, required this.draw, required this.pulse, required this.cross});

  static const scaleW = 58.0, axisH = 22.0, padT = 10.0;

  TextPainter _tp(String s, Color c, {double size = 10, FontWeight w = FontWeight.w500}) => TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontFamily: ".SF Pro Text", fontSize: size, fontWeight: w, color: c, fontFeatures: tabular)),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - scaleW, h = size.height - axisH - padT;
    final n = candles.length;
    final end = (n - offset).round().clamp(1, n);
    final start = (end - visible).round().clamp(0, end - 1);
    final vis = candles.sublist(start, end);
    if (vis.isEmpty) return;

    // Preisbereich inkl. Level, Zone, Live
    var lo = vis.map((c) => c.low).reduce(math.min), hi = vis.map((c) => c.high).reduce(math.max);
    for (final l in levels) { lo = math.min(lo, l.price); hi = math.max(hi, l.price); }
    if (zone != null) { lo = math.min(lo, zone!.sl ?? zone!.bottom); hi = math.max(hi, zone!.top); lo = math.min(lo, zone!.bottom); }
    if (live != null) { lo = math.min(lo, live!); hi = math.max(hi, live!); }
    final pad = (hi - lo) * 0.06;
    lo -= pad; hi += pad;
    final span = math.max(hi - lo, 0.5);
    double y(double p) => padT + h - (p - lo) / span * h;
    final cw = w / vis.length;
    double xc(int i) => i * cw + cw / 2;

    // Raster + Preisskala
    final step = _niceStep(span / 4);
    final pillYs = [for (final l in levels) y(l.price), if (live != null) y(live!)];
    for (var p = (lo / step).ceil() * step; p < hi; p += step) {
      final yy = y(p);
      canvas.drawLine(Offset(0, yy), Offset(w, yy), Paint()..color = PT.hairline..strokeWidth = 1);
      if (pillYs.any((py) => (py - yy).abs() < 12)) continue; // Label weicht Pillen aus
      final t = _tp(step >= 1 ? p.toStringAsFixed(0) : px(p), PT.textTertiary);
      t.paint(canvas, Offset(w + 8, yy - t.height / 2));
    }

    // Zone + Stop-Bereich
    if (zone != null) {
      final z = zone!;
      final zc = z.buy ? PT.buy : PT.sell;
      canvas.drawRect(Rect.fromLTRB(0, y(z.top), w, y(z.bottom)), Paint()..color = zc.withValues(alpha: .14));
      canvas.drawLine(Offset(0, y(z.top)), Offset(w, y(z.top)), Paint()..color = zc.withValues(alpha: .6)..strokeWidth = 1);
      canvas.drawLine(Offset(0, y(z.bottom)), Offset(w, y(z.bottom)), Paint()..color = zc.withValues(alpha: .6)..strokeWidth = 1);
      if (z.sl != null) {
        final a = z.buy ? y(z.bottom) : y(z.sl!), b = z.buy ? y(z.sl!) : y(z.top);
        canvas.drawRect(Rect.fromLTRB(0, math.min(a, b), w, math.max(a, b)), Paint()..color = PT.sell.withValues(alpha: .08));
      }
    }

    // Kerzen (mit Einzeichnen-Animation)
    final shown = (vis.length * draw).ceil();
    final bodyW = math.max(1.5, cw * 0.55);
    for (var i = 0; i < shown; i++) {
      final c = vis[i];
      final up = c.close >= c.open;
      final col = up ? PT.buy : PT.sell;
      final x = xc(i);
      canvas.drawLine(Offset(x, y(c.high)), Offset(x, y(c.low)), Paint()..color = col.withValues(alpha: .55)..strokeWidth = 1);
      final top = y(math.max(c.open, c.close)), bot = y(math.min(c.open, c.close));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - bodyW / 2, top, x + bodyW / 2, math.max(bot, top + 1)), const Radius.circular(1.5)), Paint()..color = col.withValues(alpha: .85));
    }

    // Level-Linien mit Label-Pill
    for (final l in levels) {
      final yy = y(l.price);
      _dashed(canvas, Offset(0, yy), Offset(w, yy), l.color.withValues(alpha: .8));
      _pill(canvas, "${l.label} ${px(l.price)}", Offset(w + 4, yy), l.color, PT.inkText);
    }

    // Live-Kurs
    if (live != null) {
      final yy = y(live!);
      final a = .55 + .45 * pulse;
      _dashed(canvas, Offset(0, yy), Offset(w, yy), PT.ink.withValues(alpha: a * .6), dash: 3, gap: 3);
      _pill(canvas, px(live!), Offset(w + 4, yy), PT.ink, PT.inkText);
    }

    // Zeitachse
    final every = math.max(1, (vis.length / 4).round());
    final stepMin = vis.length > 1 ? vis[1].ts.difference(vis[0].ts).inMinutes.abs() : 1;
    for (var i = every ~/ 2; i < vis.length; i += every) {
      final t = _tp(stepMin >= 60 ? ddmm(vis[i].ts) : hhmm(vis[i].ts), PT.textTertiary);
      final tx = (xc(i) - t.width / 2).clamp(0.0, w - t.width);
      t.paint(canvas, Offset(tx, size.height - axisH + 6));
    }

    // Crosshair
    if (cross != null && cross!.dx < w) {
      final i = (cross!.dx / cw).floor().clamp(0, vis.length - 1);
      final c = vis[i];
      final x = xc(i);
      final p = lo + (padT + h - cross!.dy) / h * span;
      final cp = Paint()..color = PT.textSecondary.withValues(alpha: .7)..strokeWidth = .8;
      canvas.drawLine(Offset(x, padT), Offset(x, padT + h), cp);
      canvas.drawLine(Offset(0, cross!.dy), Offset(w, cross!.dy), cp);
      _pill(canvas, px(p), Offset(w + 4, cross!.dy), PT.textSecondary, PT.inkText);
      final info = _tp("${ddmm(c.ts)} ${hhmm(c.ts)}   O ${px(c.open)}  H ${px(c.high)}  L ${px(c.low)}  C ${px(c.close)}", PT.inkText, size: 11);
      final bx = (x - info.width / 2).clamp(0.0, w - info.width - 8);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx - 6, 0, info.width + 12, info.height + 8), const Radius.circular(6)), Paint()..color = PT.ink);
      info.paint(canvas, Offset(bx, 4));
    }
  }

  void _dashed(Canvas c, Offset a, Offset b, Color col, {double dash = 5, double gap = 4}) {
    final p = Paint()..color = col..strokeWidth = 1;
    for (double x = a.dx; x < b.dx; x += dash + gap) c.drawLine(Offset(x, a.dy), Offset(math.min(x + dash, b.dx), a.dy), p);
  }

  void _pill(Canvas c, String s, Offset at, Color bg, Color fg) {
    final t = _tp(s, fg, w: FontWeight.w600);
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy - t.height / 2 - 3, t.width + 10, t.height + 6), const Radius.circular(4));
    c.drawRRect(r, Paint()..color = bg);
    t.paint(c, Offset(at.dx + 5, at.dy - t.height / 2));
  }

  double _niceStep(double raw) {
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final r = raw / mag;
    return (r < 1.5 ? 1 : r < 3 ? 2 : r < 7 ? 5 : 10) * mag;
  }

  @override
  bool shouldRepaint(_Painter o) => true;
}
