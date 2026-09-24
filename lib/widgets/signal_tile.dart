// Signal-Karten, hell. Richtung als Chip, Zahlen ruhig, Trade-Balken dünn.
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "../core/format.dart";
import "../core/pt_theme.dart";
import "../models/signal.dart";

class SignalTile extends StatelessWidget {
  final Signal s;
  final bool locked;
  final double? livePrice;
  final VoidCallback onTap;
  const SignalTile({super.key, required this.s, required this.locked, required this.onTap, this.livePrice});
  bool get _active => s.outcome == null || s.outcome == "open";
  @override
  Widget build(BuildContext context) => _active ? _ActiveCard(s: s, locked: locked, live: livePrice, onTap: onTap) : _ResolvedRow(s: s, locked: locked, onTap: onTap);
}

Widget dirChip(bool buy, {String? extra}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: buy ? PT.buySoft : PT.sellSoft, borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(buy ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right, size: 12, color: buy ? PT.buy : PT.sell),
        const SizedBox(width: 4),
        Text("${buy ? "Kauf" : "Verkauf"}${extra != null ? " · $extra" : ""}", style: PT.footnote.copyWith(fontWeight: FontWeight.w600, color: buy ? PT.buy : PT.sell)),
      ]),
    );

class _ActiveCard extends StatelessWidget {
  final Signal s; final bool locked; final double? live; final VoidCallback onTap;
  const _ActiveCard({required this.s, required this.locked, required this.live, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final buy = s.action == "BUY";
    final entry = s.entries.isNotEmpty ? s.entries.first.price : (s.currentPrice ?? 0);
    final tp1 = s.tps.isNotEmpty ? s.tps.first.price : null;
    final zone = s.kind == SignalKind.zone;
    double? left;
    if (s.entryValidFor != null && s.entryValidFor! > 0) {
      left = (1 - DateTime.now().difference(s.timestamp).inSeconds / (s.entryValidFor! * 3600)).clamp(0, 1).toDouble();
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: PT.cardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            dirChip(buy, extra: zone ? "Zone" : s.timeframe),
            const Spacer(),
            Text(ago(s.timestamp), style: PT.caption),
            if (locked) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.lock_fill, size: 13, color: PT.textTertiary)),
          ]),
          const SizedBox(height: 16),
          if (locked)
            Row(children: [_ph("Entry"), const SizedBox(width: 22), _ph("Stop"), const SizedBox(width: 22), _ph("Ziel 1")])
          else ...[
            Row(children: [
              _kv("Entry", entry, PT.textPrimary), const SizedBox(width: 22),
              _kv("Stop", s.sl, PT.sell), const SizedBox(width: 22),
              if (tp1 != null) _kv("Ziel 1", tp1, PT.buy),
            ]),
            if (tp1 != null && s.sl > 0) ...[const SizedBox(height: 16), _TradeBar(buy: buy, sl: s.sl, entry: entry, tp: tp1, live: live)],
          ],
          if (left != null && left > 0) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _Thin(value: left, color: PT.textPrimary)),
              const SizedBox(width: 10),
              Text("noch ${((s.entryValidFor! * 60) * left).ceil()} min", style: PT.caption),
            ]),
          ] else if (left != null) ...[
            const SizedBox(height: 12),
            Text(s.kind == SignalKind.zone ? "Zone aktiv, wartet auf Füllung" : "Im Markt, wartet auf Ziel oder Stop", style: PT.caption),
          ],
        ]),
      ),
    );
  }

  Widget _kv(String k, double v, Color c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: PT.caption),
        const SizedBox(height: 3),
        Text(px(v), style: PT.mono.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: c, letterSpacing: -0.3)),
      ]);
  Widget _ph(String k) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: PT.caption), const SizedBox(height: 8),
        Container(width: 60, height: 14, decoration: BoxDecoration(color: PT.cardAlt, borderRadius: BorderRadius.circular(4))),
      ]);
}

class _Thin extends StatelessWidget {
  final double value; final Color color;
  const _Thin({required this.value, required this.color});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) => ClipRRect(borderRadius: BorderRadius.circular(2), child: Stack(children: [
        Container(height: 3, width: c.maxWidth, color: PT.cardAlt),
        AnimatedContainer(duration: PT.normal, height: 3, width: c.maxWidth * value.clamp(0, 1), color: color),
      ])));
}

class _TradeBar extends StatelessWidget {
  final bool buy; final double sl, entry, tp; final double? live;
  const _TradeBar({required this.buy, required this.sl, required this.entry, required this.tp, this.live});
  @override
  Widget build(BuildContext context) {
    final lo = buy ? sl : tp, hi = buy ? tp : sl;
    double pos(double p) => ((p - lo) / (hi - lo)).clamp(0, 1).toDouble();
    final e = pos(entry), l = live == null ? null : pos(live!);
    final inProfit = live != null && (buy ? live! > entry : live! < entry);
    final diff = live == null ? null : (buy ? live! - entry : entry - live!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        return SizedBox(height: 16, child: Stack(children: [
          Positioned(top: 6, left: 0, right: 0, child: Container(height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: buy ? [PT.sellSoft, PT.cardAlt, PT.buySoft] : [PT.buySoft, PT.cardAlt, PT.sellSoft])))),
          Positioned(top: 6, left: 0, width: w * (buy ? e : 1 - e), child: Container(height: 4, color: buy ? PT.sell.withValues(alpha: .35) : PT.buy.withValues(alpha: .35))),
          Positioned(top: 1, left: w * e - 1.5, child: Container(width: 3, height: 14, decoration: BoxDecoration(color: PT.textPrimary, borderRadius: BorderRadius.circular(1.5), border: Border.all(color: PT.card, width: .5)))),
          if (l != null) Positioned(top: 0, left: w * l - 8, child: Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: inProfit ? PT.buy : PT.sell, border: Border.all(color: PT.card, width: 3), boxShadow: PT.shadow))),
        ]));
      }),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(buy ? "Stop" : "Ziel 1", style: PT.caption.copyWith(fontSize: 11)),
        if (diff != null) Text("${diff >= 0 ? "+" : ""}${px(diff)} \$", style: PT.footnote.copyWith(color: inProfit ? PT.buy : PT.sell, fontWeight: FontWeight.w600)),
        Text(buy ? "Ziel 1" : "Stop", style: PT.caption.copyWith(fontSize: 11)),
      ]),
    ]);
  }
}

class _ResolvedRow extends StatelessWidget {
  final Signal s; final bool locked; final VoidCallback onTap;
  const _ResolvedRow({required this.s, required this.locked, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final buy = s.action == "BUY";
    final expired = s.outcome == "expired";
    final win = !expired && s.outcome != "sl";
    final col = expired ? PT.textTertiary : win ? PT.buy : PT.sell;
    final entry = s.entries.isNotEmpty ? s.entries.first.price : (s.currentPrice ?? 0);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: PT.cardDeco(radius: 16),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: expired ? PT.cardAlt : win ? PT.buySoft : PT.sellSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(expired ? CupertinoIcons.clock : win ? CupertinoIcons.checkmark : CupertinoIcons.xmark, size: 16, color: col)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(buy ? "Kauf" : "Verkauf", style: PT.headline.copyWith(fontSize: 15)),
              const SizedBox(width: 6),
              Text("${s.timeframe ?? ""} · ${ago(s.timestamp)}", style: PT.caption),
            ]),
            const SizedBox(height: 3),
            Text(locked ? "Level in Pro" : "Entry ${px(entry)} · Stop ${px(s.sl)}${s.tps.isNotEmpty ? " · Ziel ${px(s.tps.first.price)}" : ""}", style: PT.caption.copyWith(fontFeatures: tabular), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 10),
          SizedBox(width: 62, child: Text(s.pnlR == null ? (expired ? "offen" : win ? "Ziel" : "Stop") : rr(s.pnlR!), textAlign: TextAlign.right, style: PT.mono.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: col))),
        ]),
      ),
    );
  }
}
