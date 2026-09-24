// ════════════════════════════════════════════════════════════════════
// SIGNAL CARD V3 — "Trade Ticket" (final design, simplified)
// Mirrors the Telegram signal format users already know:
//   SELL badge → 2 limit orders → fixed stop → 5 profit targets → plan
// Plain language, dollar amounts, zero jargon, NO chart.
// Works with Signal v2 model (entries[], tps[], kind, status).
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/obsidian_theme.dart';
import '../models/signal.dart';
import '../l10n/gen/app_localizations.dart';

class SignalCardV3 extends StatelessWidget {
  final Signal signal;
  final List<int> tpWeights;     // default 40/20/20/10/10, user-adjustable
  final double? planLots;        // from TradePlan calculator
  final double? planRiskUsd;     // worst case in $
  final double? planMaxUsd;      // all targets hit in $
  final double? accountSize;     // for the "bei $5.000 Konto" hint
  final double? riskPercent;
  final bool blurred;            // free tier
  final VoidCallback? onHowTo;   // opens the 3-step how-to sheet
  final VoidCallback? onTap;

  SignalCardV3({
    super.key,
    required this.signal,
    this.tpWeights = const [40, 20, 20, 10, 10],
    this.planLots,
    this.planRiskUsd,
    this.planMaxUsd,
    this.accountSize,
    this.riskPercent,
    this.blurred = false,
    this.onHowTo,
    this.onTap,
  });

  bool get _isSell => signal.action.toUpperCase() == 'SELL';
  bool get _isZone => _enumName(signal.kind) == 'zone' && signal.entries.length >= 2;
  String get _orderWord => _isSell ? 'Sell Limit' : 'Buy Limit';

  List<double> get _entryPrices => _isZone
      ? signal.entries.map((e) => e.price).toList()
      : [signal.price];

  List<int> get _effWeights {
    final n = signal.tps.length;
    final out = <int>[];
    var used = 0;
    for (var i = 0; i < n; i++) {
      if (i == n - 1) {
        out.add((100 - used).clamp(0, 100));
      } else {
        final wi = i < tpWeights.length ? tpWeights[i] : 0;
        out.add(wi); used += wi;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: Obsidian.cardBox,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          SizedBox(height: 14),
          _sectionLabel(_isZone
              ? (_isSell
                  ? AppLocalizations.of(context).cardYourOrdersSell(_entryPrices.length)
                  : AppLocalizations.of(context).cardYourOrdersBuy(_entryPrices.length))
              : AppLocalizations.of(context).entrySection),
          SizedBox(height: 6),
          ..._entryRows(context),
          SizedBox(height: 6),
          _stopRow(context),
          SizedBox(height: 14),
          _sectionLabel('GEWINN MITNEHMEN \u2014 ${signal.tps.length} ZIELE'),
          SizedBox(height: 6),
          ..._targetRows(context),
          if (planLots != null) ...[
            SizedBox(height: 10),
            _planBox(context),
          ],
          SizedBox(height: 12),
          _actions(context),
          if (_statusLine(context) != null) ...[
            SizedBox(height: 10),
            _statusLine(context)!,
          ],
        ],
      ),
    );

    final wrapped = blurred ? _paywallOverlay(context, card) : card;
    return GestureDetector(onTap: onTap, child: wrapped);
  }

  // ── Header: SELL badge · plain-language explainer · confidence ────
  Widget _header(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _isSell ? Obsidian.sellBg : Obsidian.buyBg,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_isSell ? Icons.arrow_downward : Icons.arrow_upward,
                size: 13, color: _isSell ? Obsidian.sell : Obsidian.buy),
            SizedBox(width: 4),
            Text(signal.action.toUpperCase(), style: TextStyle(
              color: _isSell ? Obsidian.sell : Obsidian.buy,
              fontSize: 13, fontWeight: FontWeight.w600,
            )),
          ]),
        ),
        Spacer(),
        Text(AppLocalizations.of(context).confidencePct(signal.confidence ?? 0),
            style: Obsidian.monoSm.copyWith(color: Obsidian.gold)),
      ]),
      SizedBox(height: 6),
      Text(_explainer(context), style: Obsidian.body.copyWith(fontSize: 12)),
    ]);
  }

  String _explainer(BuildContext context) {
    final session = _sessionName();
    if (!_isZone) return AppLocalizations.of(context).sessionMarketSignal(session);
    return _isSell
        ? AppLocalizations.of(context).sessionWaitSell(session)
        : AppLocalizations.of(context).sessionWaitBuy(session);
  }

  String _sessionName() {
    switch (signal.session) {
      case 'tokyo': return 'Tokyo Session';
      case 'london': return 'London Session';
      case 'ny': return 'New York Session';
      default: return 'XAU/USD';
    }
  }

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(fontSize: 11, letterSpacing: 1.5,
          color: Obsidian.textLow, fontWeight: FontWeight.w600));

  // ── Entry rows: numbered, "Sell Limit bei 4505" ───────────────────
  List<Widget> _entryRows(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < _entryPrices.length; i++) {
      final filled = _isZone && signal.entries[i].status == 'filled';
      rows.add(Container(
        margin: EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: Obsidian.tileBox(),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
                color: Obsidian.goldBg, shape: BoxShape.circle),
            child: Center(child: filled
                ? Icon(Icons.check, size: 13, color: Obsidian.gold)
                : Text('${i + 1}', style: TextStyle(
                    fontSize: 11, color: Obsidian.gold,
                    fontWeight: FontWeight.w600))),
          ),
          SizedBox(width: 10),
          Text(filled ? AppLocalizations.of(context).orderFilledAt(_orderWord) : AppLocalizations.of(context).orderAtPrice(_orderWord),
              style: TextStyle(fontSize: 13,
                  color: filled ? Obsidian.gold : Obsidian.textHi)),
          Spacer(),
          Text(_fmt(_entryPrices[i]),
              style: Obsidian.monoMd.copyWith(fontSize: 16)),
        ]),
      ));
    }
    return rows;
  }

  // ── Stop row: the brand promise in plain words ────────────────────
  Widget _stopRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: Obsidian.tileBox(color: Obsidian.sellBg),
      child: Row(children: [
        Icon(Icons.shield_outlined, size: 17, color: Obsidian.sell),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).stopYourProtection, style: TextStyle(
              fontSize: 13, color: Obsidian.sell, fontWeight: FontWeight.w600)),
          Text(AppLocalizations.of(context).stopNeverMoves,
              maxLines: 2,
              style: TextStyle(fontSize: 11, color: Obsidian.sell)),
        ])),
        SizedBox(width: 8),
        Text(_fmt(signal.sl),
            style: Obsidian.monoMd.copyWith(fontSize: 16, color: Obsidian.sell)),
      ]),
    );
  }

  // ── Target rows: checklist with percent instructions ──────────────
  List<Widget> _targetRows(BuildContext context) {
    final rows = <Widget>[];
    final firstOpen = signal.tps.indexWhere((t) => _enumName(t.status) != 'hit');
    for (var i = 0; i < signal.tps.length; i++) {
      final tp = signal.tps[i];
      final hit = _enumName(tp.status) == 'hit';
      final isNext = i == firstOpen;
      final w = _effWeights[i];

      rows.add(Container(
        margin: EdgeInsets.only(bottom: 5),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hit ? Obsidian.buyBg : Obsidian.cardAlt,
          borderRadius: BorderRadius.circular(10),
          border: isNext && !hit
              ? Border.all(color: Obsidian.tpLine, width: 0.5) : null,
        ),
        child: Row(children: [
          if (hit)
            Icon(Icons.check_circle_outline, size: 16, color: Obsidian.buy)
          else if (isNext)
            Icon(Icons.gps_fixed, size: 16, color: Obsidian.buy)
          else
            SizedBox(width: 16, child: Center(child: Text('${i + 1}',
                style: TextStyle(fontSize: 12, color: Obsidian.textLow)))),
          SizedBox(width: 10),
          Expanded(child: RichText(text: TextSpan(
            style: TextStyle(fontSize: 13,
                color: hit ? Obsidian.buy
                    : (isNext ? Obsidian.textHi : Obsidian.textMid)),
            children: [
              TextSpan(text: hit ? AppLocalizations.of(context).targetHitN(i + 1) : AppLocalizations.of(context).targetN(i + 1)),
              TextSpan(
                text: hit
                    ? AppLocalizations.of(context).pctClosed(w)
                    : (isNext ? AppLocalizations.of(context).pctThenClose(w) : ' \u00b7 $w%'),
                style: TextStyle(fontSize: hit || isNext ? 13 : 12,
                    color: hit ? Color(0xFF3E8A70) : Obsidian.textLow),
              ),
            ],
          ))),
          SizedBox(width: 8),
          Text(_fmt(tp.price), style: Obsidian.monoMd.copyWith(
              fontSize: 14,
              color: hit ? Obsidian.buy
                  : (isNext ? Obsidian.textHi : Obsidian.textMid))),
        ]),
      ));
    }
    return rows;
  }

  // ── Plan box: everything in dollars, no R-multiples ───────────────
  Widget _planBox(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Obsidian.goldBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Row(children: [
          Text(AppLocalizations.of(context).yourStake(planLots!.toStringAsFixed(2)),
              style: TextStyle(fontSize: 13, color: Obsidian.goldSoft,
                  fontWeight: FontWeight.w600)),
          Spacer(),
          if (accountSize != null && riskPercent != null)
            Text(AppLocalizations.of(context).atAccountRisk(accountSize!.toStringAsFixed(0), riskPercent!.toStringAsFixed(0)),
                style: TextStyle(fontSize: 11, color: Obsidian.goldDeep)),
        ]),
        SizedBox(height: 4),
        Row(children: [
          if (planRiskUsd != null)
            Text(AppLocalizations.of(context).worstCase(planRiskUsd!.toStringAsFixed(0)),
                style: TextStyle(fontSize: 13, color: Obsidian.sell)),
          Spacer(),
          if (planMaxUsd != null)
            Text(AppLocalizations.of(context).allTargetsUsd(planMaxUsd!.toStringAsFixed(0)),
                style: TextStyle(fontSize: 13, color: Obsidian.buy)),
        ]),
      ]),
    );
  }

  // ── Actions: copy values + how-to ─────────────────────────────────
  Widget _actions(BuildContext context) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: _clipboardText()));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).copiedMt5),
            duration: Duration(seconds: 2),
          ));
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Obsidian.gold,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.copy, size: 14, color: Color(0xFF1A1607)),
            SizedBox(width: 6),
            Text(AppLocalizations.of(context).copyValues, style: TextStyle(fontSize: 13,
                color: Color(0xFF1A1607), fontWeight: FontWeight.w600)),
          ]),
        ),
      )),
      SizedBox(width: 8),
      Expanded(child: GestureDetector(
        onTap: onHowTo,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Obsidian.cardAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Obsidian.stroke, width: 0.5),
          ),
          child: Center(child: Text(AppLocalizations.of(context).howApply,
              style: TextStyle(fontSize: 13, color: Obsidian.textMid))),
        ),
      )),
    ]);
  }

  String _clipboardText() {
    final b = StringBuffer();
    b.writeln('${signal.action.toUpperCase()} XAU/USD');
    for (var i = 0; i < _entryPrices.length; i++) {
      b.writeln('$_orderWord ${i + 1}: ${_fmt(_entryPrices[i])}');
    }
    b.writeln('Stop Loss: ${_fmt(signal.sl)}');
    for (var i = 0; i < signal.tps.length; i++) {
      final w = _effWeights[i];
      b.writeln('Ziel ${i + 1} ($w%): ${_fmt(signal.tps[i].price)}');
    }
    return b.toString();
  }

  // ── Status line + paywall ─────────────────────────────────────────
  Widget? _statusLine(BuildContext context) {
    String? text;
    Color color = Obsidian.textLow;
    switch (_enumName(signal.status)) {
      case 'filled':
        text = AppLocalizations.of(context).statusInTradeLive;
        color = Obsidian.gold; break;
      case 'closed':
        final hits = signal.tps.where((t) => _enumName(t.status) == 'hit').length;
        text = hits > 0
            ? AppLocalizations.of(context).statusClosedDone(hits, signal.tps.length)
            : AppLocalizations.of(context).statusStopDone;
        color = hits > 0 ? Obsidian.buy : Obsidian.sell; break;
      case 'cancelled':
        text = AppLocalizations.of(context).statusExpiredCard; break;
      default:
        return null;
    }
    return Row(children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: 6),
      Expanded(child: Text(text,
          style: Obsidian.body.copyWith(color: color, fontSize: 12))),
    ]);
  }

  Widget _paywallOverlay(BuildContext context, Widget card) {
    return Stack(children: [
      Opacity(opacity: 0.22, child: IgnorePointer(child: card)),
      Positioned.fill(child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Obsidian.goldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Obsidian.goldDeep, width: 0.5),
          ),
          child: Text(AppLocalizations.of(context).unlockPro, style: TextStyle(
              color: Obsidian.gold, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      )),
    ]);
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

String _enumName(dynamic v) => v.toString().split('.').last;
