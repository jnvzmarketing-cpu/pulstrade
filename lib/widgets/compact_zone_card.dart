// ════════════════════════════════════════════════════════════════════
// COMPACT ZONE CARD v2 — Fokus-Frame · Session-Tag · Auto-Dim
// Tap = expand zum vollen SignalCardV3-Ticket.
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/signal.dart';
import 'signal_card_v3.dart';

class CompactZoneCard extends StatefulWidget {
  final Signal signal;
  final List<int> tpWeights;
  final double? planLots, planRiskUsd, planMaxUsd, accountSize, riskPercent;
  final double? livePrice;
  final bool blurred;
  /// Fokus-Trade: goldener Rahmen, hebt DIE eine Zone hervor.
  final bool focus;
  final VoidCallback? onHowTo;

  const CompactZoneCard({
    super.key,
    required this.signal,
    this.tpWeights = const [40, 20, 20, 10, 10],
    this.planLots, this.planRiskUsd, this.planMaxUsd,
    this.accountSize, this.riskPercent,
    this.livePrice,
    this.blurred = false,
    this.focus = false,
    this.onHowTo,
  });

  @override
  State<CompactZoneCard> createState() => _CompactZoneCardState();
}

class _CompactZoneCardState extends State<CompactZoneCard> {
  bool _expanded = false;

  Signal get s => widget.signal;
  bool get _isSell => s.action.toUpperCase() == 'SELL';
  bool get _isZone => s.kind == 'zone' && s.entries.length >= 2;
  bool get _isRunning => s.status == 'filled';
  bool get _isDone => s.status == 'closed' || s.status == 'cancelled';

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return Column(children: [
        SignalCardV3(
          signal: s,
          tpWeights: widget.tpWeights,
          planLots: widget.planLots,
          planRiskUsd: widget.planRiskUsd,
          planMaxUsd: widget.planMaxUsd,
          accountSize: widget.accountSize,
          riskPercent: widget.riskPercent,
          blurred: widget.blurred,
          onHowTo: widget.onHowTo,
          onTap: () => setState(() => _expanded = false),
        ),
        SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = false),
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Text(AppLocalizations.of(context).collapseCard,
                style: TextStyle(fontSize: 11, color: Obsidian.textLow)),
          ),
        ),
      ]);
    }

    final card = GestureDetector(
      onTap: () => setState(() => _expanded = true),
      child: Container(
        decoration: BoxDecoration(
          color: Obsidian.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.focus
                ? Obsidian.gold
                : (_isRunning ? Obsidian.goldDeep : Obsidian.stroke),
            width: widget.focus ? 1.0 : 0.5,
          ),
        ),
        padding: EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: _isSell ? Obsidian.sellBg : Obsidian.buyBg,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(s.action.toUpperCase(), style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _isSell ? Obsidian.sell : Obsidian.buy,
              )),
            ),
            if (_sessionTag() != null) ...[
              SizedBox(width: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Obsidian.cardAlt,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(_sessionTag()!, style: TextStyle(
                    fontSize: 9, letterSpacing: 1,
                    color: Obsidian.textLow, fontWeight: FontWeight.w600)),
              ),
            ],
            Spacer(),
            Text(AppLocalizations.of(context).confidencePct(s.confidence ?? 0),
                style: Obsidian.monoSm.copyWith(
                    fontSize: 10, color: Obsidian.gold)),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(
              _isZone
                  ? AppLocalizations.of(context).cardOrders(_fmt(s.entries[0].price), _fmt(s.entries[1].price))
                  : AppLocalizations.of(context).cardEntry(_fmt(s.price)),
              style: Obsidian.monoSm.copyWith(
                  fontSize: 12, color: Obsidian.textHi),
            )),
            Text(AppLocalizations.of(context).cardStop(_fmt(s.sl)),
                style: Obsidian.monoSm.copyWith(
                    fontSize: 12, color: Obsidian.sell)),
          ]),
          if (s.tps.isNotEmpty) ...[
            SizedBox(height: 8),
            _miniTpRow(),
          ],
          SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(_statusText(AppLocalizations.of(context)), style: TextStyle(
                fontSize: 11, color: _statusColor()))),
            Text(AppLocalizations.of(context).openChevron,
                style: TextStyle(fontSize: 11, color: Obsidian.textLow)),
          ]),
        ]),
      ),
    );

    return _isDone ? Opacity(opacity: 0.72, child: card) : card;
  }

  String? _sessionTag() {
    switch (s.session) {
      case 'tokyo': return 'TOKYO';
      case 'london': return 'LONDON';
      case 'ny': return 'NEW YORK';
      default: return null;
    }
  }

  Widget _miniTpRow() {
    final chips = <Widget>[];
    final n = s.tps.length.clamp(0, 5);
    for (var i = 0; i < n; i++) {
      final hit = s.tps[i].status == 'hit';
      chips.add(Expanded(child: Container(
        margin: EdgeInsets.only(right: i < n - 1 ? 4 : 0),
        padding: EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: hit ? Obsidian.buy : Obsidian.cardAlt,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: Text(_fmt(s.tps[i].price), style: TextStyle(
          fontFamily: Obsidian.monoFamily, fontSize: 10,
          color: hit ? Obsidian.buyInk : Obsidian.textMid,
        ))),
      )));
    }
    return Row(children: chips);
  }

  String _statusText(AppLocalizations t) {
    switch (s.status) {
      case 'filled':
        final hits = s.tps.where((t) => t.status == 'hit').length;
        return hits > 0 ? t.statusFilledHit(hits) : t.statusFilled;
      case 'closed':
        final hits = s.tps.where((t) => t.status == 'hit').length;
        final when = _whenClosed(t);
        return hits > 0
            ? t.statusClosedHits(when, hits, s.tps.length)
            : t.statusClosedStop(when);
      case 'cancelled':
        return t.statusCancelled;
      default:
        if (widget.livePrice != null && _isZone) {
          final dist = (widget.livePrice! - s.entries[0].price).abs();
          return t.statusWaitingDist(dist.toStringAsFixed(0));
        }
        return t.statusWaiting;
    }
  }

  String _whenClosed(AppLocalizations t) {
    String? raw;
    for (final t in s.tps) {
      if (t.status == 'hit' && t.hitAt != null) raw = t.hitAt;
    }
    if (raw == null) {
      for (final e in s.entries) {
        if (e.filledAt != null) raw = e.filledAt;
      }
    }
    if (raw == null) return t.whenToday;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return t.whenToday;
    final l = parsed.toLocal();
    final now = DateTime.now();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    if (l.year == now.year && l.month == now.month && l.day == now.day) {
      return t.whenAtTime('$hh:$mm');
    }
    if (now.difference(l).inHours < 48) return t.whenYesterday('$hh:$mm');
    return t.whenOnDate('${l.day}.${l.month}.', '$hh:$mm');
  }

  Color _statusColor() {
    switch (s.status) {
      case 'filled': return Obsidian.gold;
      case 'closed':
        return s.tps.any((t) => t.status == 'hit')
            ? Obsidian.buy : Obsidian.sell;
      default: return Obsidian.textMid;
    }
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
