// ════════════════════════════════════════════════════════════════════
// TODAY SCREEN V3 (Obsidian) — Fokus-Update
// Preis-Header · Session-Strip · EIN Fokus-Trade oben · weitere offene
// Zonen · "Heute erledigt" gedimmt unten · Countdown wenn leer ·
// Gestern-Bilanz. Auto-Refresh: Preis 30s, Signale 60s, Countdown 1s.
// ════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/material.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/signal.dart';
import '../widgets/session_strip_v3.dart';
import '../widgets/compact_zone_card.dart';
import '../widgets/how_to_sheet.dart';

int _ms(dynamic t) {
  if (t == null) return 0;
  if (t is DateTime) return t.millisecondsSinceEpoch;
  if (t is num) return t.toInt();
  return 0;
}

class TodayScreenV3 extends StatefulWidget {
  final Future<List<Signal>> Function() fetchSignals;
  final Future<double?> Function() fetchPrice;
  final List<int> tpWeights;
  final double? accountSize;
  final double? riskPercent;
  final bool isPro;
  final ({double lots, double riskUsd, double maxUsd})? Function(Signal)? planFor;

  const TodayScreenV3({
    super.key,
    required this.fetchSignals,
    required this.fetchPrice,
    this.tpWeights = const [40, 20, 20, 10, 10],
    this.accountSize,
    this.riskPercent,
    this.isPro = true,
    this.planFor,
  });

  @override
  State<TodayScreenV3> createState() => _TodayScreenV3State();
}

class _TodayScreenV3State extends State<TodayScreenV3>
    with SingleTickerProviderStateMixin {
  List<Signal> _signals = [];
  double? _price;
  bool _loading = true;
  Timer? _signalTimer, _priceTimer, _tickTimer;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
    _signalTimer = Timer.periodic(Duration(seconds: 60), (_) => _load());
    _priceTimer = Timer.periodic(Duration(seconds: 30), (_) => _loadPrice());
    _tickTimer = Timer.periodic(
        Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _signalTimer?.cancel(); _priceTimer?.cancel(); _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.fetchSignals(),
        widget.fetchPrice(),
      ]);
      if (!mounted) return;
      setState(() {
        _signals = results[0] as List<Signal>;
        _price = results[1] as double? ?? _price;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPrice() async {
    try {
      final p = await widget.fetchPrice();
      if (mounted && p != null) setState(() => _price = p);
    } catch (_) {}
  }

  // ── Zonen des Tages, getrennt in offen / erledigt ──────────────────
  String _en(dynamic v) => v.toString().split('.').last;

  List<Signal> get _todayAll {
    final cutoff = DateTime.now()
        .subtract(Duration(hours: 24)).millisecondsSinceEpoch;
    return _signals.where((s) =>
        _en(s.kind) == 'zone' &&
        _ms(s.timestamp) > cutoff &&
        _en(s.status) != 'cancelled').toList();
  }

  /// Offen: im Trade zuerst, dann h\u00f6chstes Vertrauen.
  List<Signal> get _openZones {
    final l = _todayAll
        .where((s) => _en(s.status) == 'filled' || _en(s.status) == 'active')
        .toList();
    int rank(Signal s) => _en(s.status) == 'filled' ? 0 : 1;
    l.sort((a, b) {
      if (rank(a) != rank(b)) return rank(a) - rank(b);
      final ca = a.confidence ?? 0;
      final cb = b.confidence ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return _ms(b.timestamp) - _ms(a.timestamp);
    });
    return l;
  }

  List<Signal> get _doneZones {
    final l = _todayAll.where((s) => _en(s.status) == 'closed').toList();
    l.sort((a, b) => _ms(b.timestamp) - _ms(a.timestamp));
    return l;
  }

  int _closedMs(Signal s) {
    String? raw;
    for (final t in s.tps) {
      if (_en(t.status) == 'hit' && t.hitAt != null) raw = t.hitAt;
    }
    if (raw == null && s.entries.isNotEmpty) raw = s.entries.last.filledAt;
    final d = raw != null ? DateTime.tryParse(raw) : null;
    return d?.toLocal().millisecondsSinceEpoch ?? _ms(s.timestamp);
  }

  double _estR(Signal s) {
    if (s.tps.isEmpty) return 0;
    final e1 = s.entries.isNotEmpty ? s.entries[0].price : s.price;
    final e2 = s.entries.length > 1 ? s.entries[1].price : e1;
    final avg = (e1 + e2) / 2;
    final risk = (avg - s.sl).abs();
    if (risk <= 0) return 0;
    double pnl = 0;
    var remaining = 100;
    final n = s.tps.length;
    for (var i = 0; i < n; i++) {
      final w = i == n - 1
          ? remaining
          : (i < widget.tpWeights.length ? widget.tpWeights[i] : 0);
      if (_en(s.tps[i].status) == 'hit') {
        pnl += ((s.tps[i].price - avg).abs() / risk) * (w / 100);
        remaining -= w;
      }
    }
    final hits = s.tps.where((t) => _en(t.status) == 'hit').length;
    if (hits == 0) return -1.0;
    if (hits < n) pnl -= remaining / 100;
    return pnl;
  }

  ({int count, double pnlUsd})? get _yesterday {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: 1)).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final closed = _signals.where((s) {
      if (_en(s.kind) != 'zone' || _en(s.status) != 'closed') return false;
      final cm = _closedMs(s);
      return cm >= start && cm < end;
    }).toList();
    if (closed.isEmpty) return null;
    double pnl = 0;
    for (final s in closed) {
      final plan = widget.planFor?.call(s);
      pnl += _estR(s) * (plan?.riskUsd ?? 100);
    }
    return (count: closed.length, pnlUsd: pnl);
  }

  @override
  Widget build(BuildContext context) {
    final open = _openZones;
    final done = _doneZones;

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
              _priceHeader(),
              SizedBox(height: 14),
              SessionStripV3(),
              SizedBox(height: 20),
              if (_loading)
                Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(
                      color: Obsidian.gold, strokeWidth: 2)),
                )
              else ...[
                if (open.isEmpty) _emptyState(hasDone: done.isNotEmpty)
                else ..._openSection(open),
                if (done.isNotEmpty) ...[
                  SizedBox(height: 20),
                  Text(AppLocalizations.of(context).doneToday(done.length),
                      style: TextStyle(fontSize: 11, letterSpacing: 1.5,
                          color: Obsidian.textLow,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  for (final z in done) ...[
                    _card(z, focus: false),
                    SizedBox(height: 8),
                  ],
                ],
                if (_yesterday != null) ...[
                  SizedBox(height: 6),
                  _yesterdayStrip(_yesterday!),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _openSection(List<Signal> open) {
    final focus = open.first;
    final rest = open.skip(1).toList();
    final inTrade = _en(focus.status) == 'filled';
    return [
      Row(children: [
        Icon(Icons.gps_fixed, size: 12, color: Obsidian.gold),
        SizedBox(width: 5),
        Text(AppLocalizations.of(context).focusTrade, style: TextStyle(fontSize: 11,
            letterSpacing: 1.5, color: Obsidian.gold,
            fontWeight: FontWeight.w600)),
        Spacer(),
        Text(inTrade ? AppLocalizations.of(context).focusInTrade
                : AppLocalizations.of(context).focusHighestConf(focus.confidence ?? 0),
            style: TextStyle(fontSize: 10, color: Obsidian.textLow)),
      ]),
      SizedBox(height: 8),
      _card(focus, focus: true),
      SizedBox(height: 8),
      Center(child: Text(AppLocalizations.of(context).oneZoneEnough,
          style: TextStyle(fontSize: 11, color: Obsidian.textLow))),
      if (rest.isNotEmpty) ...[
        SizedBox(height: 18),
        Text(AppLocalizations.of(context).moreZones(rest.length),
            style: TextStyle(fontSize: 11, letterSpacing: 1.5,
                color: Obsidian.textLow, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        for (var i = 0; i < rest.length; i++) ...[
          _card(rest[i], focus: false, blurIndex: i + 1),
          SizedBox(height: 8),
        ],
      ],
    ];
  }

  Widget _card(Signal z, {required bool focus, int blurIndex = 0}) {
    return CompactZoneCard(
      signal: z,
      tpWeights: widget.tpWeights,
      livePrice: _price,
      accountSize: widget.accountSize,
      riskPercent: widget.riskPercent,
      planLots: widget.planFor?.call(z)?.lots,
      planRiskUsd: widget.planFor?.call(z)?.riskUsd,
      planMaxUsd: widget.planFor?.call(z)?.maxUsd,
      focus: focus,
      blurred: !widget.isPro && blurIndex > 0,
      onHowTo: () => HowToSheet.show(context,
          isSell: z.action.toUpperCase() == 'SELL'),
    );
  }

  // ── Pro/Free Status-Badge ──────────────────────────────────────────
  Widget _proBadge() {
    final pro = widget.isPro;
    final color = pro ? Obsidian.gold : Obsidian.textMid;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(pro ? 'PRO' : 'FREE',
          style: TextStyle(fontSize: 10, color: color,
              fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }

  // ── Preis-Header mit pulsierendem Live-Punkt ───────────────────────
  Widget _priceHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('XAU/USD', style: TextStyle(fontSize: 12,
            letterSpacing: 2, color: Obsidian.textMid)),
        SizedBox(width: 8),
        _proBadge(),
        Spacer(),
        FadeTransition(
          opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
          child: Row(children: [
            Icon(Icons.circle, size: 7, color: Obsidian.gold),
            SizedBox(width: 4),
            Text('LIVE', style: TextStyle(fontSize: 11,
                color: Obsidian.gold, letterSpacing: 1)),
          ]),
        ),
      ]),
      SizedBox(height: 2),
      Text(
        _price != null ? _price!.toStringAsFixed(2) : '\u2014',
        style: Obsidian.priceXL,
      ),
    ]);
  }

  // ── Leer-Zustand: Countdown bis zum n\u00e4chsten Zonen-Drop ───────────
  Widget _emptyState({bool hasDone = false}) {
    final drop = nextZoneDrop(DateTime.now().toUtc());
    final left = drop.at.difference(DateTime.now().toUtc());
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final sec = left.inSeconds % 60;
    final countdown =
        '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: Obsidian.cardBox,
      child: Column(children: [
        Container(width: 54, height: 54,
            decoration: BoxDecoration(
                color: Obsidian.goldBg, shape: BoxShape.circle),
            child: Icon(Icons.my_location,
                size: 24, color: Obsidian.gold)),
        SizedBox(height: 14),
        Text(hasDone ? AppLocalizations.of(context).allZonesDone : AppLocalizations.of(context).nextZonesIn,
            style: TextStyle(fontSize: 15, color: Obsidian.textHi,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text(countdown, style: TextStyle(
            fontFamily: Obsidian.monoFamily, fontSize: 32,
            color: Obsidian.gold, fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()])),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).preSessionAnalysis(drop.session.name),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Obsidian.textMid,
              height: 1.5),
        ),
        SizedBox(height: 14),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Obsidian.cardAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Obsidian.stroke, width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, size: 13, color: Obsidian.textMid),
            SizedBox(width: 5),
            Text(AppLocalizations.of(context).pushOn,
                style: TextStyle(fontSize: 12, color: Obsidian.textMid)),
          ]),
        ),
      ]),
    );
  }

  // ── Gestern-Bilanz ─────────────────────────────────────────────────
  Widget _yesterdayStrip(({int count, double pnlUsd}) y) {
    final positive = y.pnlUsd >= 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Obsidian.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Obsidian.stroke, width: 0.5),
      ),
      child: Row(children: [
        Text(
          AppLocalizations.of(context).yesterdaySummary(y.count,
              positive ? AppLocalizations.of(context).inPlus : AppLocalizations.of(context).inMinus),
          style: TextStyle(fontSize: 12, color: Obsidian.textMid),
        ),
        Spacer(),
        Text(
          '${positive ? "+" : "\u2212"}\$${y.pnlUsd.abs().toStringAsFixed(0)}',
          style: TextStyle(fontFamily: Obsidian.monoFamily, fontSize: 12,
              color: positive ? Obsidian.buy : Obsidian.sell),
        ),
      ]),
    );
  }
}
