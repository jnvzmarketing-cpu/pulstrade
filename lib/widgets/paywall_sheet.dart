// Paywall-Sheet. Wird nie beim App-Start gezeigt, sondern:
//   1. wenn ein gesperrter Nutzer ein Signal antippt (reason: signal)
//   2. wenn er einen Push zu einem gesperrten Signal öffnet (reason: push)
//   3. einmalig am Tag 3+ über den "Verpasst"-Screen (reason: missed)
//
// Aufbau: Kontext (das Signal, das er gerade wollte) → letzte 3 aufgelöste
// Trades → zwei Pläne → ein Button → Bedingungen → Wiederherstellen.
// Keine Feature-Liste, keine Timeline, kein Timer.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/pt_theme.dart';
import '../core/format.dart';
import '../models/signal.dart';
import '../services/access_service.dart';
import '../services/market_repo.dart';

enum PaywallReason { signal, push, missed }

Future<bool> showPaywall(BuildContext context,
    {required PaywallReason reason, Signal? signal}) async {
  HapticFeedback.mediumImpact();
  final ok = await showCupertinoModalPopup<bool>(
    context: context,
    barrierColor: CupertinoColors.black.withValues(alpha: .35),
    builder: (_) => _PaywallSheet(reason: reason, signal: signal),
  );
  return ok ?? false;
}

class _PaywallSheet extends StatefulWidget {
  final PaywallReason reason;
  final Signal? signal;
  const _PaywallSheet({required this.reason, this.signal});
  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  bool _yearly = true;
  String? _error;
  TrackRecord? _tr;

  @override
  void initState() {
    super.initState();
    context.read<MarketRepo>().trackRecord().then((t) {
      if (mounted) setState(() => _tr = t);
    });
  }

  String get _title {
    final s = widget.signal;
    if (s != null) {
      final dir = s.action == 'BUY' ? 'Kauf' : 'Verkauf';
      return '$dir-Zone ${s.timeframe ?? ''} ist aktiv.';
    }
    switch (widget.reason) {
      case PaywallReason.push:
        return 'Neues Signal ist da.';
      case PaywallReason.missed:
        return 'Du warst bei keinem dabei.';
      case PaywallReason.signal:
        return 'Die Level sind Pro.';
    }
  }

  String get _sub {
    switch (widget.reason) {
      case PaywallReason.signal:
      case PaywallReason.push:
        return 'Entry, Stop und Ziele siehst du mit Pro. Alles andere bleibt, wie du es kennst.';
      case PaywallReason.missed:
        return 'Die Signale laufen weiter. Die Frage ist nur, ob du dabei bist.';
    }
  }

  Future<void> _buy() async {
    final acc = context.read<AccessService>();
    final pkg = _yearly ? acc.annual : acc.monthly;
    if (pkg == null) return;
    HapticFeedback.lightImpact();
    final err = await acc.purchase(pkg);
    if (!mounted) return;
    if (err == null && acc.isPro) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessService>();
    final repo = context.watch<MarketRepo>();
    final closed = repo.signals.where((s) => s.outcome != null && s.outcome != 'open').take(3).toList();
    final pkg = _yearly ? acc.annual : acc.monthly;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: PT.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 5, decoration: BoxDecoration(color: PT.hairline, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Text(_title, style: PT.title1),
        const SizedBox(height: 6),
        Text(_sub, style: PT.body.copyWith(color: PT.textSecondary)),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Zuletzt aufgelöst', style: PT.caption),
          const SizedBox(height: 8),
          for (final s in closed) _ResolvedRow(s),
        ],
        if (_tr != null) ...[
          const SizedBox(height: 10),
          Text(
            '${_tr!.total} Trades in 30 Tagen · ${_tr!.winRate.toStringAsFixed(0)} % Treffer · ${_tr!.sumR >= 0 ? '+' : ''}${_tr!.sumR.toStringAsFixed(1)} R',
            style: PT.footnote.copyWith(color: PT.textSecondary),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _Plan(
            selected: _yearly,
            title: 'Jahr',
            price: acc.annual?.storeProduct.priceString ?? '–',
            note: acc.annualSavings != null ? '${acc.annualSavings} gespart' : null,
            onTap: () { HapticFeedback.selectionClick(); setState(() => _yearly = true); },
          )),
          const SizedBox(width: 10),
          Expanded(child: _Plan(
            selected: !_yearly,
            title: 'Monat',
            price: acc.monthly?.storeProduct.priceString ?? '–',
            onTap: () { HapticFeedback.selectionClick(); setState(() => _yearly = false); },
          )),
        ]),
        const SizedBox(height: 14),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: PT.footnote.copyWith(color: PT.sell))),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: acc.purchasing || pkg == null ? null : _buy,
            borderRadius: BorderRadius.circular(14),
            child: acc.purchasing
                ? const CupertinoActivityIndicator(color: PT.inkText)
                : Text(_yearly ? 'Pro freischalten' : 'Pro für einen Monat', style: PT.button),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _yearly
              ? 'Wird jährlich abgerechnet und verlängert sich automatisch. Jederzeit im App Store kündbar.'
              : 'Wird monatlich abgerechnet und verlängert sich automatisch. Jederzeit im App Store kündbar.',
          textAlign: TextAlign.center,
          style: PT.footnote.copyWith(color: PT.textTertiary),
        ),
        const SizedBox(height: 4),
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: () async {
              final ok = await acc.restore();
              if (ok && context.mounted) Navigator.of(context).pop(true);
            },
            child: Text('Kauf wiederherstellen', style: PT.footnote.copyWith(color: PT.textSecondary)),
          ),
        ),
      ]),
    );
  }
}

class _ResolvedRow extends StatelessWidget {
  final Signal s;
  const _ResolvedRow(this.s);
  @override
  Widget build(BuildContext context) {
    final win = s.outcome != 'sl';
    final r = s.pnlR;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: win ? PT.buy : PT.sell, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Text(s.action == 'BUY' ? 'Kauf' : 'Verkauf', style: PT.body),
        const SizedBox(width: 6),
        Text(s.timeframe ?? '', style: PT.body.copyWith(color: PT.textSecondary)),
        const Spacer(),
        Text(
          r == null ? (win ? 'Ziel erreicht' : 'Stop') : rr(r),
          style: PT.mono.copyWith(color: win ? PT.buy : PT.sell),
        ),
      ]),
    );
  }
}

class _Plan extends StatelessWidget {
  final bool selected;
  final String title, price;
  final String? note;
  final VoidCallback onTap;
  const _Plan({required this.selected, required this.title, required this.price, this.note, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PT.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? PT.ink : PT.hairline, width: selected ? 1.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: PT.footnote.copyWith(color: PT.textSecondary)),
          const SizedBox(height: 4),
          Text(price, style: PT.mono.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: PT.footnote.copyWith(color: PT.gold)),
          ],
        ]),
      ),
    );
  }
}
