// ════════════════════════════════════════════════════════════════════
// SIGNALS SCREEN V3 (Obsidian) — Fokus-Trade-Update
// Sniper zeigt EINE klare Empfehlung (Fokus-Trade) statt einer Wand
// aus gleichwertigen Karten. Weitere Zonen: optional, kleiner Abschnitt.
// Vertrauens-Filter aus Einstellungen (min_confidence) wird angewendet —
// transparent: ausgeblendete Zonen werden gezählt, nie verschwiegen.
// ════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/signal.dart';
import '../widgets/compact_zone_card.dart';
import '../widgets/how_to_sheet.dart';

String _en(dynamic v) => v.toString().split('.').last;

class SignalsScreenV3 extends StatefulWidget {
  final Future<List<Signal>> Function() fetchSignals;
  final Future<double?> Function() fetchPrice;
  final List<int> tpWeights;
  final bool isPro;
  final double? accountSize;
  final double? riskPercent;
  final ({double lots, double riskUsd, double maxUsd})? Function(Signal)? planFor;

  const SignalsScreenV3({
    super.key,
    required this.fetchSignals,
    required this.fetchPrice,
    this.tpWeights = const [40, 20, 20, 10, 10],
    this.isPro = true,
    this.accountSize,
    this.riskPercent,
    this.planFor,
  });

  @override
  State<SignalsScreenV3> createState() => _SignalsScreenV3State();
}

class _SignalsScreenV3State extends State<SignalsScreenV3> {
  int _segment = 0; // 0 Sniper · 1 Executor · 2 Verlauf
  List<Signal> _signals = [];
  double? _price;
  bool _loading = true;
  int _minConf = 65;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await Future.wait([widget.fetchSignals(), widget.fetchPrice()]);
      if (!mounted) return;
      setState(() {
        _minConf = prefs.getInt('min_confidence') ?? 65;
        _signals = res[0] as List<Signal>;
        _price = res[1] as double? ?? _price;
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  bool _isOpen(Signal s) {
    final st = _en(s.status);
    return st == 'active' || st == 'filled' || st == 'pending';
  }

  /// Alle offenen Zonen, beste zuerst: im Trade > h\u00f6chstes Vertrauen.
  List<Signal> get _sniperAll {
    final l = _signals.where((s) => _en(s.kind) == 'zone' && _isOpen(s)).toList();
    int rank(Signal s) => _en(s.status) == 'filled' ? 0 : 1;
    l.sort((a, b) {
      if (rank(a) != rank(b)) return rank(a) - rank(b);
      final ca = a.confidence ?? 0;
      final cb = b.confidence ?? 0;
      if (ca != cb) return cb.compareTo(ca);
      return b.timestamp.compareTo(a.timestamp);
    });
    return l;
  }

  List<Signal> get _sniper =>
      _sniperAll.where((s) => (s.confidence ?? 0) >= _minConf).toList();
  int get _hiddenByFilter => _sniperAll.length - _sniper.length;

  List<Signal> get _executor {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));
    final l = _signals.where((s) =>
        _en(s.kind) != 'zone' && _isOpen(s) &&
        s.timestamp.isAfter(cutoff)).toList();
    l.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return l;
  }

  List<Signal> get _history {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));
    final l = _signals.where((s) =>
        !_isOpen(s) || (_en(s.kind) != 'zone' && !s.timestamp.isAfter(cutoff))
    ).toList();
    l.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return l;
  }

  @override
  Widget build(BuildContext context) {
    final lists = [_sniper, _executor, _history];
    final active = lists[_segment];

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
              Text(AppLocalizations.of(context).navSignals, style: TextStyle(fontSize: 18,
                  color: Obsidian.textHi, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              _segmentControl(lists),
              SizedBox(height: 14),
              if (_loading)
                Padding(padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(
                        color: Obsidian.gold, strokeWidth: 2)))
              else if (active.isEmpty && _segment == 0 && _hiddenByFilter > 0)
                ..._allFilteredState()
              else if (active.isEmpty)
                _emptyState()
              else if (_segment == 2)
                ...active.map((s) => _HistoryCard(
                    signal: s, tpWeights: widget.tpWeights))
              else if (_segment == 0)
                ..._sniperFocusLayout(active)
              else ...[
                for (var i = 0; i < active.length; i++) ...[
                  CompactZoneCard(
                    signal: active[i],
                    tpWeights: widget.tpWeights,
                    livePrice: _price,
                    blurred: !widget.isPro && i > 0,
                    onHowTo: () => HowToSheet.show(context,
                        isSell: active[i].action.toUpperCase() == 'SELL'),
                  ),
                  SizedBox(height: 8),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Sniper: EIN Fokus-Trade, Rest optional ─────────────────────────
  List<Widget> _sniperFocusLayout(List<Signal> zones) {
    final focus = zones.first;
    final rest = zones.skip(1).toList();
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
      CompactZoneCard(
        signal: focus,
        tpWeights: widget.tpWeights,
        livePrice: _price,
        accountSize: widget.accountSize,
        riskPercent: widget.riskPercent,
        planLots: widget.planFor?.call(focus)?.lots,
        planRiskUsd: widget.planFor?.call(focus)?.riskUsd,
        planMaxUsd: widget.planFor?.call(focus)?.maxUsd,
        focus: true,
        blurred: false,
        onHowTo: () => HowToSheet.show(context,
            isSell: focus.action.toUpperCase() == 'SELL'),
      ),
      SizedBox(height: 8),
      Center(child: Text(AppLocalizations.of(context).oneZoneEnough,
          style: TextStyle(fontSize: 11, color: Obsidian.textLow))),
      if (rest.isNotEmpty) ...[
        SizedBox(height: 18),
        Text(AppLocalizations.of(context).moreChances, style: TextStyle(fontSize: 11,
            letterSpacing: 1.5, color: Obsidian.textLow,
            fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        for (var i = 0; i < rest.length; i++) ...[
          CompactZoneCard(
            signal: rest[i],
            tpWeights: widget.tpWeights,
            livePrice: _price,
            blurred: !widget.isPro,
            onHowTo: () => HowToSheet.show(context,
                isSell: rest[i].action.toUpperCase() == 'SELL'),
          ),
          SizedBox(height: 8),
        ],
      ],
      if (_hiddenByFilter > 0) ...[
        SizedBox(height: 6),
        Center(child: Text(
          AppLocalizations.of(context).hiddenByFilter(_hiddenByFilter, _minConf),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Obsidian.textLow),
        )),
      ],
      SizedBox(height: 6),
      Center(child: Text(AppLocalizations.of(context).expiredInHistory,
          style: TextStyle(fontSize: 11, color: Obsidian.textLow))),
    ];
  }

  List<Widget> _allFilteredState() {
    return [
      Container(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: Obsidian.cardBox,
        child: Column(children: [
          Icon(Icons.filter_alt_outlined, size: 26, color: Obsidian.gold),
          SizedBox(height: 10),
          Text(AppLocalizations.of(context).allFilteredTitle(_minConf),
              style: TextStyle(fontSize: 14, color: Obsidian.textHi,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).allFilteredSub(_hiddenByFilter),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Obsidian.textMid, height: 1.5),
          ),
        ]),
      ),
    ];
  }

  Widget _segmentControl(List<List<Signal>> lists) {
    final labels = ['Sniper', 'Executor', AppLocalizations.of(context).segHistory];
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Obsidian.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Obsidian.stroke, width: 0.5),
      ),
      child: Row(children: [
        for (var i = 0; i < 3; i++)
          Expanded(child: GestureDetector(
            onTap: () => setState(() => _segment = i),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _segment == i ? Obsidian.goldBg : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(
                lists[i].isNotEmpty && i != 2
                    ? '${labels[i]} \u00b7 ${lists[i].length}'
                    : labels[i],
                style: TextStyle(fontSize: 12,
                    fontWeight: _segment == i ? FontWeight.w600 : FontWeight.w400,
                    color: _segment == i ? Obsidian.gold : Obsidian.textMid),
              )),
            ),
          )),
      ]),
    );
  }

  Widget _emptyState() {
    final t = AppLocalizations.of(context);
    final texts = [
      (t.emptySniperTitle, t.emptySniperSub),
      (t.emptyExecutorTitle, t.emptyExecutorSub),
      (t.emptyHistoryTitle, t.emptyHistorySub),
    ];
    final (title, sub) = texts[_segment];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: Obsidian.cardBox,
      child: Column(children: [
        Icon(_segment == 2 ? Icons.history : Icons.gps_fixed,
            size: 26, color: Obsidian.textLow),
        SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 14,
            color: Obsidian.textHi, fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text(sub, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Obsidian.textMid,
                height: 1.5)),
      ]),
    );
  }
}

// ── Verlauf-Karte: kompakt, ehrliche Bilanz, est. PnL in R ───────────
class _HistoryCard extends StatelessWidget {
  final Signal signal;
  final List<int> tpWeights;
  const _HistoryCard({required this.signal, required this.tpWeights});

  bool get _sell => signal.action.toUpperCase() == 'SELL';
  bool get _isZone => _en(signal.kind) == 'zone';

  double? get _pnlR {
    if (_en(signal.status) == 'cancelled') return null;
    if (signal.tps.isEmpty) return null;
    final e1 = _isZone && signal.entries.isNotEmpty
        ? signal.entries[0].price : signal.price;
    final e2 = _isZone && signal.entries.length > 1
        ? signal.entries[1].price : e1;
    final avg = (e1 + e2) / 2;
    final risk = (avg - signal.sl).abs();
    if (risk <= 0) return null;
    final n = signal.tps.length;
    double pnl = 0; var remaining = 100;
    for (var i = 0; i < n; i++) {
      final w = i == n - 1
          ? remaining
          : (i < tpWeights.length ? tpWeights[i] : 0);
      if (_en(signal.tps[i].status) == 'hit') {
        pnl += ((signal.tps[i].price - avg).abs() / risk) * (w / 100);
        remaining -= w;
      }
    }
    final hits = signal.tps.where((t) => _en(t.status) == 'hit').length;
    if (hits == 0) return -1.0;
    if (hits < n) pnl -= remaining / 100;
    return (pnl * 100).round() / 100;
  }

  @override
  Widget build(BuildContext context) {
    final st = _en(signal.status);
    final hits = signal.tps.where((t) => _en(t.status) == 'hit').length;
    final cancelled = st == 'cancelled';
    final pnl = _pnlR;
    final won = (pnl ?? 0) > 0;

    String result;
    Color resultColor;
    if (cancelled) {
      result = AppLocalizations.of(context).historyExpired;
      resultColor = Obsidian.textLow;
    } else if (hits > 0) {
      result = AppLocalizations.of(context).historyTargets(hits, signal.tps.length) +
          (pnl != null ? ' \u00b7 ${pnl >= 0 ? '+' : '\u2212'}${pnl.abs().toStringAsFixed(2)}R' : '');
      resultColor = won ? Obsidian.buy : Obsidian.sell;
    } else {
      result = AppLocalizations.of(context).historyStop;
      resultColor = Obsidian.sell;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Obsidian.card.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Obsidian.stroke, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _sell ? Obsidian.sellBg : Obsidian.buyBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(signal.action.toUpperCase(), style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _sell ? Obsidian.sell : Obsidian.buy)),
          ),
          SizedBox(width: 8),
          Text(_isZone ? AppLocalizations.of(context).historySniperZone : 'Executor',
              style: TextStyle(fontSize: 11, color: Obsidian.textLow)),
          Spacer(),
          Text(_ago(context, signal.timestamp),
              style: TextStyle(fontSize: 10, color: Obsidian.textLow)),
        ]),
        SizedBox(height: 7),
        Text(
          _isZone && signal.entries.isNotEmpty
              ? '${signal.entries.map((e) => _fmt(e.price)).join(' + ')} \u00b7 Stop ${_fmt(signal.sl)}'
              : 'Entry ${_fmt(signal.price)} \u00b7 Stop ${_fmt(signal.sl)}',
          style: TextStyle(fontFamily: Obsidian.monoFamily,
              fontSize: 12, color: Obsidian.textHi),
        ),
        SizedBox(height: 5),
        Text(result, style: TextStyle(fontSize: 11, color: resultColor)),
      ]),
    );
  }

  String _ago(BuildContext context, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inHours < 1) return AppLocalizations.of(context).agoM(d.inMinutes);
    if (d.inHours < 24) return AppLocalizations.of(context).agoH(d.inHours);
    return AppLocalizations.of(context).agoD(d.inDays);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
