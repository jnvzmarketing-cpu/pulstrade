// ════════════════════════════════════════════════════════════════════
// STATS SCREEN V3 (Obsidian) — Phase D
// Klartext-Ergebnisse: animierter Win-Ring ("7 von 10 Trades gewinnen"),
// Kennzahlen-Kacheln, Ziel-Leiter aus /stats.zoneStats.tpLadder.
// Erste Motion-Komponente: Ring + Zahl zählen beim Öffnen hoch.
// ════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';

class StatsScreenV3 extends StatefulWidget {
  final String serverUrl;
  StatsScreenV3({super.key, required this.serverUrl});

  @override
  State<StatsScreenV3> createState() => _StatsScreenV3State();
}

class _StatsScreenV3State extends State<StatsScreenV3>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1100));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final res = await http
          .get(Uri.parse('${widget.serverUrl}/stats'))
          .timeout(Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _stats = json.decode(res.body) as Map<String, dynamic>;
          _loading = false;
        });
        _anim.forward(from: 0);
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  double? get _winRate => (_stats?['winRate'] as num?)?.toDouble();
  int get _closed => (_stats?['closedSignals'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Obsidian.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: Obsidian.gold,
          backgroundColor: Obsidian.card,
          onRefresh: _load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Row(children: [
                Text(t.statsTitle, style: TextStyle(fontSize: 18,
                    color: Obsidian.textHi, fontWeight: FontWeight.w600)),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Obsidian.buyBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(t.statsLiveBadge,
                      style: TextStyle(fontSize: 10, color: Obsidian.buy)),
                ),
              ]),
              SizedBox(height: 14),
              if (_loading)
                Padding(padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(
                        color: Obsidian.gold, strokeWidth: 2)))
              else if (_winRate == null)
                _gathering()
              else ...[
                _winCard(),
                SizedBox(height: 10),
                _tileRow(),
                SizedBox(height: 16),
                Text(t.ladderHeader, style: TextStyle(
                    fontSize: 11, letterSpacing: 1.5, color: Obsidian.textLow,
                    fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                _ladder(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state: Daten sammeln ─────────────────────────────────────
  Widget _gathering() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: Obsidian.cardBox,
      child: Column(children: [
        Icon(Icons.hourglass_empty, size: 26, color: Obsidian.gold),
        SizedBox(height: 10),
        Text(AppLocalizations.of(context).statsGatheringTitle, style: TextStyle(fontSize: 14,
            color: Obsidian.textHi, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
Text(AppLocalizations.of(context).statsGatheringSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Obsidian.textMid,
                height: 1.5)),
      ]),
    );
  }

  // ── Win-Ring mit Count-Up ──────────────────────────────────────────
  Widget _winCard() {
    final target = _winRate!.clamp(0, 100).toDouble();
    final outOf10 = (target / 10).round();
    return Container(
      padding: EdgeInsets.all(16),
      decoration: Obsidian.cardBox,
      child: Row(children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            final t = Curves.easeOutCubic.transform(_anim.value);
            final v = target * t;
            return SizedBox(width: 86, height: 86, child: CustomPaint(
              painter: _RingPainter(fraction: v / 100),
              child: Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${v.round()}%', style: TextStyle(
                      fontFamily: Obsidian.monoFamily, fontSize: 17,
                      color: Obsidian.textHi, fontWeight: FontWeight.w600)),
                  Text(AppLocalizations.of(context).winRateLabel, style: TextStyle(
                      fontSize: 8, color: Obsidian.textMid)),
                ],
              )),
            ));
          },
        ),
        SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).winOutOf10(outOf10),
                style: TextStyle(fontSize: 14, color: Obsidian.textHi,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 3),
            Text(AppLocalizations.of(context).closedSince(_closed),
                style: TextStyle(fontSize: 11, color: Obsidian.textMid,
                    height: 1.5)),
          ],
        )),
      ]),
    );
  }

  Widget _tileRow() {
    final avg = (_stats?['avgRR'] as num?)?.toDouble();
    final best = (_stats?['bestTrade'] as num?)?.toDouble();
    final worst = (_stats?['worstTrade'] as num?)?.toDouble();
    Widget tile(String label, double? v, {bool forceRed = false}) {
      final pos = (v ?? 0) >= 0 && !forceRed;
      return Expanded(child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: Obsidian.cardBox,
        child: Column(children: [
          Text(label, style: TextStyle(
              fontSize: 10, color: Obsidian.textLow)),
          SizedBox(height: 3),
          Text(v == null ? '\u2014'
              : '${v >= 0 ? '+' : '\u2212'}${v.abs().toStringAsFixed(1)}R',
              style: TextStyle(fontFamily: Obsidian.monoFamily, fontSize: 14,
                  color: pos ? Obsidian.buy : Obsidian.sell)),
        ]),
      ));
    }
    return Row(children: [
      tile(AppLocalizations.of(context).tileAvg, avg),
      SizedBox(width: 8),
      tile(AppLocalizations.of(context).tileBest, best),
      SizedBox(width: 8),
      tile(AppLocalizations.of(context).tileWorst, worst, forceRed: true),
    ]);
  }

  // ── Ziel-Leiter aus zoneStats.tpLadder ─────────────────────────────
  Widget _ladder() {
    final zs = _stats?['zoneStats'] as Map<String, dynamic>?;
    final ladder = zs?['tpLadder'] as Map<String, dynamic>?;
    final total = (zs?['total'] as num?)?.toInt() ?? 0;

    if (ladder == null || total == 0) {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: Obsidian.cardBox,
        child: Text(
          AppLocalizations.of(context).ladderEmpty,
          style: TextStyle(fontSize: 12, color: Obsidian.textMid),
        ),
      );
    }

    final counts = [for (var i = 1; i <= 5; i++)
        (ladder['tp$i'] as num?)?.toInt() ?? 0];

    return Container(
      padding: EdgeInsets.all(12),
      decoration: Obsidian.cardBox,
      child: Column(children: [
        for (var i = 0; i < 5; i++) ...[
          if (counts[i] > 0 || i < 3) Padding(
            padding: EdgeInsets.only(bottom: i == 4 ? 0 : 7),
            child: Row(children: [
              SizedBox(width: 40, child: Text(AppLocalizations.of(context).ladderTarget(i + 1),
                  style: TextStyle(fontSize: 11,
                      color: Obsidian.textMid))),
              Expanded(child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) {
                  final pct = (counts[i] / total).clamp(0.0, 1.0);
                  final t = Curves.easeOutCubic.transform(_anim.value);
                  return Stack(children: [
                    Container(height: 7, decoration: BoxDecoration(
                        color: Obsidian.cardAlt,
                        borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: pct * t,
                      child: Container(height: 7, decoration: BoxDecoration(
                          color: i < 2 ? Obsidian.buy
                              : Color(0xFF3E8A70),
                          borderRadius: BorderRadius.circular(4))),
                    ),
                  ]);
                },
              )),
              SizedBox(width: 38, child: Text(
                  '${((counts[i] / total) * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontFamily: Obsidian.monoFamily,
                      fontSize: 11,
                      color: i < 2 ? Obsidian.buy : Obsidian.textMid))),
            ]),
          ),
        ],
        SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Text(
            AppLocalizations.of(context).ladderFootnote,
            style: TextStyle(fontSize: 11, color: Obsidian.textLow))),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  _RingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    final bg = Paint()
      ..color = Color(0xFF1C1C20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final fg = Paint()
      ..color = Obsidian.buy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -math.pi / 2, 2 * math.pi * fraction.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
