// ════════════════════════════════════════════════════════════════════
// SIGNAL DETAIL V3 (Obsidian) — Phase C
// "Was bisher passiert ist": Trade als Timeline (Zone erstellt → Order
// gefüllt → Ziele → Abschluss) + Kennzahlen-Strip + Bilanz teilen.
// Timeline wird client-seitig aus entries[].filled_at / tps[].hit_at
// abgeleitet — kein neuer Backend-Call nötig.
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/obsidian_theme.dart';
import '../models/signal.dart';
import '../l10n/gen/app_localizations.dart';

String _en(dynamic v) => v.toString().split('.').last;

class SignalDetailScreenV3 extends StatelessWidget {
  final Signal signal;
  final List<int> tpWeights;
  SignalDetailScreenV3({super.key, required this.signal,
      this.tpWeights = const [40, 20, 20, 10, 10]});

  bool get _sell => signal.action.toUpperCase() == 'SELL';
  bool get _isZone => _en(signal.kind) == 'zone';

  List<int> get _effWeights {
    final n = signal.tps.length;
    final out = <int>[]; var used = 0;
    for (var i = 0; i < n; i++) {
      if (i == n - 1) { out.add((100 - used).clamp(0, 100)); }
      else { final w = i < tpWeights.length ? tpWeights[i] : 0; out.add(w); used += w; }
    }
    return out;
  }

  // ── Timeline-Events aus dem Signal ableiten ────────────────────────
  List<_Event> _events(BuildContext context) {
    final ev = <_Event>[];
    ev.add(_Event(
      time: signal.timestamp,
      title: AppLocalizations.of(context).detailZoneCreated,
      sub: '${_sessionName()} \u00b7 ${signal.note ?? ''} \u00b7 ${signal.confidence}%',
      color: Obsidian.textLow,
    ));
    if (_isZone) {
      for (var i = 0; i < signal.entries.length; i++) {
        final e = signal.entries[i];
        if (_en(e.status) == 'filled') {
          ev.add(_Event(
            time: _parse(e.filledAt) ?? signal.timestamp,
            title: AppLocalizations.of(context).detailOrderFilled(i + 1, _fmt(e.price)),
            sub: AppLocalizations.of(context).detailInTradeStop(_fmt(signal.sl)),
            color: Obsidian.gold,
          ));
        }
      }
    }
    final w = _effWeights;
    for (var i = 0; i < signal.tps.length; i++) {
      final tp = signal.tps[i];
      if (_en(tp.status) == 'hit') {
        ev.add(_Event(
          time: _parse(tp.hitAt) ?? signal.timestamp,
          title: AppLocalizations.of(context).detailTargetHitAt(i + 1, _fmt(tp.price)),
          sub: AppLocalizations.of(context).detailPctClosed(w[i]),
          color: Obsidian.buy,
        ));
      }
    }
    final st = _en(signal.status);
    if (st == 'closed') {
      final hits = signal.tps.where((t) => _en(t.status) == 'hit').length;
      ev.add(_Event(
        time: ev.map((e) => e.time).reduce((a, b) => a.isAfter(b) ? a : b),
        title: hits > 0
            ? AppLocalizations.of(context).detailClosedTargets(hits, signal.tps.length)
            : AppLocalizations.of(context).detailStopClosed,
        sub: hits > 0 ? AppLocalizations.of(context).detailCleanPlan
            : AppLocalizations.of(context).detailLimitedPlan,
        color: hits > 0 ? Obsidian.buy : Obsidian.sell,
        isLast: true,
      ));
    } else if (st == 'cancelled') {
      ev.add(_Event(
        time: signal.timestamp.add(Duration(hours: 1)),
        title: AppLocalizations.of(context).detailExpiredTitle,
        sub: AppLocalizations.of(context).detailExpiredSub,
        color: Obsidian.textLow, isLast: true,
      ));
    }
    ev.sort((a, b) => b.time.compareTo(a.time)); // neuestes oben
    return ev;
  }

  DateTime? _parse(dynamic raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

  @override
  Widget build(BuildContext context) {
    final openTps = <int>[];
    final w = _effWeights;
    for (var i = 0; i < signal.tps.length; i++) {
      if (_en(signal.tps[i].status) != 'hit') openTps.add(i);
    }

    return Scaffold(
      backgroundColor: Obsidian.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(padding: EdgeInsets.all(6),
                    child: Icon(Icons.chevron_left, size: 22,
                        color: Obsidian.textMid)),
              ),
              SizedBox(width: 4),
              Text(AppLocalizations.of(context).detailZoneTitle(_sell ? 'Sell' : 'Buy', _sessionName()),
                  style: TextStyle(fontSize: 15,
                      color: Obsidian.textHi, fontWeight: FontWeight.w600)),
              Spacer(),
              GestureDetector(
                onTap: () => _share(context),
                child: Padding(padding: EdgeInsets.all(6),
                    child: Icon(Icons.ios_share, size: 18,
                        color: Obsidian.gold)),
              ),
            ]),
            SizedBox(height: 12),
            _statStrip(context),
            SizedBox(height: 18),
            Text(AppLocalizations.of(context).whatHappened, style: TextStyle(
                fontSize: 11, letterSpacing: 1.5, color: Obsidian.textLow,
                fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            _timeline(context),
            if (openTps.isNotEmpty) ...[
              SizedBox(height: 14),
              Text(AppLocalizations.of(context).openTargets, style: TextStyle(
                  fontSize: 11, letterSpacing: 1.5, color: Obsidian.textLow,
                  fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(children: [
                for (var k = 0; k < openTps.length; k++) ...[
                  if (k > 0) SizedBox(width: 4),
                  Expanded(child: Container(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Obsidian.cardAlt,
                      borderRadius: BorderRadius.circular(6),
                      border: k == 0 ? Border.all(
                          color: Obsidian.tpLine, width: 0.5) : null,
                    ),
                    child: Center(child: Text(
                      '${_fmt(signal.tps[openTps[k]].price)} \u00b7 ${w[openTps[k]]}%',
                      style: TextStyle(fontFamily: Obsidian.monoFamily,
                          fontSize: 10,
                          color: k == 0 ? Obsidian.buy : Obsidian.textMid),
                    )),
                  )),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statStrip(BuildContext context) {
    final hits = signal.tps.where((t) => _en(t.status) == 'hit').length;
    return Row(children: [
      Expanded(child: _statBox(AppLocalizations.of(context).statOrders,
          _isZone && signal.entries.length >= 2
              ? '${_fmt(signal.entries[0].price)}+${_fmt(signal.entries[1].price)}'
              : _fmt(signal.price),
          Obsidian.textHi, Obsidian.cardAlt)),
      SizedBox(width: 6),
      Expanded(child: _statBox(AppLocalizations.of(context).statStopFixed, _fmt(signal.sl),
          Obsidian.sell, Obsidian.sellBg)),
      SizedBox(width: 6),
      Expanded(child: _statBox(AppLocalizations.of(context).statTargets, '$hits/${signal.tps.length}',
          hits > 0 ? Obsidian.buy : Obsidian.textMid,
          hits > 0 ? Obsidian.buyBg : Obsidian.cardAlt)),
    ]);
  }

  Widget _statBox(String label, String value, Color color, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, letterSpacing: 1,
            color: color.withValues(alpha: 0.7))),
        SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: Obsidian.monoFamily,
                fontSize: 12, color: color)),
      ]),
    );
  }

  Widget _timeline(BuildContext context) {
    final events = _events(context);
    return Container(
      margin: EdgeInsets.only(left: 4),
      padding: EdgeInsets.only(left: 16),
      decoration: BoxDecoration(border: Border(
          left: BorderSide(color: Obsidian.stroke, width: 1))),
      child: Column(children: [
        for (final e in events) Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: -21, top: 3, child: Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                    color: e.color, shape: BoxShape.circle))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: TextStyle(fontSize: 12.5,
                  color: e.color == Obsidian.textLow
                      ? Color(0xFFB8B8BE) : e.color,
                  fontWeight: FontWeight.w500)),
              SizedBox(height: 2),
              Text('${_clock(e.time)} \u00b7 ${e.sub}',
                  style: TextStyle(fontSize: 11,
                      color: Obsidian.textLow)),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _share(BuildContext context) {
    final hits = signal.tps.where((t) => _en(t.status) == 'hit').length;
    final b = StringBuffer();
    b.writeln('\ud83c\udfaf PulsTrade ${signal.action.toUpperCase()} XAU/USD');
    if (_isZone && signal.entries.length >= 2) {
      b.writeln('Zone: ${_fmt(signal.entries[0].price)} + ${_fmt(signal.entries[1].price)}');
    }
    b.writeln(AppLocalizations.of(context).shareStopFixed(_fmt(signal.sl)));
    b.writeln(AppLocalizations.of(context).shareTargetsLine(hits, signal.tps.length));
    for (var i = 0; i < signal.tps.length; i++) {
      final hit = _en(signal.tps[i].status) == 'hit';
      b.writeln('${hit ? '\u2705' : '\u25cb'} ' + AppLocalizations.of(context).shareTargetLine(i + 1, _fmt(signal.tps[i].price)));
    }
    b.writeln('\u2014 pulstrade.app');
    Clipboard.setData(ClipboardData(text: b.toString()));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).copiedShare),
        duration: Duration(seconds: 2)));
  }

  String _sessionName() {
    switch (signal.session) {
      case 'tokyo': return 'Tokyo';
      case 'london': return 'London';
      case 'ny': return 'New York';
      default: return 'XAU/USD';
    }
  }

  String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

class _Event {
  final DateTime time;
  final String title, sub;
  final Color color;
  final bool isLast;
  _Event({required this.time, required this.title, required this.sub,
      required this.color, this.isLast = false});
}
