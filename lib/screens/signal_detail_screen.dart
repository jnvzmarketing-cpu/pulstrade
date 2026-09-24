// Signal-Detail: Level, Zonen-Leiter, persönlicher Plan (Lots aus dem
// bestehenden TradePlan), Status. Gesperrt = Paywall beim Öffnen, der Screen
// selbst zeigt dann nur Struktur.
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../models/signal.dart";
import "../models/user_profile.dart";
import "../services/access_service.dart";
import "../services/market_repo.dart";
import "../widgets/paywall_sheet.dart";
import "../widgets/candle_chart.dart";
import "../core/format.dart";

class SignalDetailScreen extends StatefulWidget {
  final Signal signal;
  const SignalDetailScreen({super.key, required this.signal});
  @override
  State<SignalDetailScreen> createState() => _SignalDetailScreenState();
}

class _SignalDetailScreenState extends State<SignalDetailScreen> {
  UserProfile? _profile;
  List<Candle> _chart = const [];

  @override
  void initState() {
    super.initState();
    UserProfile.load().then((p) { if (mounted) setState(() => _profile = p); });
    context.read<MarketRepo>().candles(_tfOf(widget.signal.timeframe), limit: 120).then((c) { if (mounted) setState(() => _chart = c); });
  }

  static String _tfOf(String? tf) => switch (tf) { "5m" => "5min", "30m" => "30min", "1H" => "1h", "4H" => "4h", _ => "15min" };

  @override
  Widget build(BuildContext context) {
    // Live-Version des Signals aus dem Repo (Status kann sich ändern)
    final repo = context.watch<MarketRepo>();
    final s = repo.signals.firstWhere((x) => x.id == widget.signal.id, orElse: () => widget.signal);
    final acc = context.watch<AccessService>();
    final locked = !acc.canSeeLevels;
    final buy = s.action == "BUY";
    final color = buy ? PT.buy : PT.sell;
    final resolved = s.outcome != null && s.outcome != "open";
    final plan = (_profile != null && !locked) ? TradePlan.build(s, _profile!) : null;
    final price = repo.price;

    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: PT.bg, border: null,
        middle: Text("${buy ? "Kauf" : "Verkauf"} · ${s.timeframe ?? ""}", style: PT.headline),
      ),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          // Kopf
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(s.kind == SignalKind.zone ? "Limit-Zone" : (s.strategy ?? "Setup"), style: PT.body),
            const Spacer(),
            Text(ago(s.timestamp), style: PT.footnote.copyWith(color: PT.textTertiary)),
          ]),
          const SizedBox(height: 6),
          Text(_statusLine(s, resolved), style: PT.footnote.copyWith(color: resolved ? (s.outcome == "sl" ? PT.sell : PT.buy) : PT.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 4, 6),
            decoration: PT.cardDeco(),
            child: CandleChart(
              candles: _chart,
              height: 240,
              initialVisible: 48,
              livePrice: price,
              // Zone nur bei Limit-Zonen (zwei Entries); Setups zeigen Entry als Linie
              zone: locked || s.kind != SignalKind.zone || s.entries.length < 2 ? null : ChartZone(
                top: s.entries.map((e) => e.price).reduce((a, b) => a > b ? a : b),
                bottom: s.entries.map((e) => e.price).reduce((a, b) => a < b ? a : b),
                sl: s.sl > 0 ? s.sl : null, buy: buy),
              levels: locked ? const [] : [
                if (s.kind != SignalKind.zone && s.entries.isNotEmpty) ChartLevel("Entry", s.entries.first.price, PT.textPrimary),
                ChartLevel("SL", s.sl, PT.sell),
                for (final tp in s.tps.take(2)) ChartLevel("TP${tp.level}", tp.price, PT.buy),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Level
          Text("Level", style: PT.headline),
          const SizedBox(height: 8),
          _card(children: [
            for (var i = 0; i < s.entries.length; i++)
              _row("Entry${s.entries.length > 1 ? " ${i + 1}" : ""}", s.entries[i].price, locked, dim: s.entries[i].status == EntryStatus.cancelled),
            _row("Stop", s.sl, locked, color: PT.sell),
            for (final tp in s.tps)
              _row("Ziel ${tp.level}", tp.price, locked, color: PT.buy, hit: tp.status == TpStatus.hit),
          ]),
          if (price != null && !locked) ...[
            const SizedBox(height: 8),
            Text("Kurs jetzt ${px(price)} · ${_distance(s, price)}", style: PT.footnote.copyWith(color: PT.textTertiary)),
          ],

          // Persönlicher Plan
          if (plan != null && plan.totalLots > 0) ...[
            const SizedBox(height: 24),
            Text("Dein Plan", style: PT.headline),
            const SizedBox(height: 8),
            _card(children: [
              _kv("Lot gesamt", plan.totalLots.toStringAsFixed(2)),
              if (plan.entries.length > 1)
                for (var i = 0; i < plan.entries.length; i++) _kv("Lot Entry ${i + 1}", plan.entries[i].lots.toStringAsFixed(2)),
              _kv("Max. Risiko", "${plan.maxRiskUsd.toStringAsFixed(0)} \$", color: PT.sell),
              _kv("Max. Gewinn", "${plan.maxProfitUsd.toStringAsFixed(0)} \$", color: PT.buy),
            ]),
            const SizedBox(height: 6),
            Text("Bei ${_profile!.accountBalance.toStringAsFixed(0)} \$ Konto und ${_profile!.riskPercent.toStringAsFixed(1)} % Risiko. Anpassen unter Bilanz.", style: PT.footnote.copyWith(color: PT.textTertiary)),
          ],

          if (locked) ...[
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(14),
              onPressed: () async { if (await showPaywall(context, reason: PaywallReason.signal, signal: s) && mounted) setState(() {}); },
              child: Text("Level freischalten", style: PT.button),
            )),
          ],

          if ((s.note ?? "").isNotEmpty) ...[
            const SizedBox(height: 24),
            Text("Kontext", style: PT.headline),
            const SizedBox(height: 8),
            Text(s.note!, style: PT.body.copyWith(color: PT.textSecondary)),
          ],
          const SizedBox(height: 24),
          Row(children: [
            if (s.confidence != null) _chip("${s.confidence} %"),
            if (s.rsi != null) _chip("RSI ${s.rsi!.toStringAsFixed(0)}"),
            if (s.atr != null) _chip("ATR ${s.atr!.toStringAsFixed(1)}"),
            if (s.session != null) _chip(s.session!),
          ]),
        ]),
      ),
    );
  }

  String _statusLine(Signal s, bool resolved) {
    if (resolved) {
      final r = s.pnlR;
      final what = s.outcome == "sl" ? "Stop erreicht" : s.outcome == "expired" ? "Abgelaufen" : "Ziel erreicht";
      return r == null ? what : "$what · ${rr(r)}";
    }
    if (s.kind == SignalKind.zone) return "Zone aktiv, wartet auf Füllung";
    final h = s.entryValidFor ?? 0;
    return h > 0 ? "Aktiv · gültig ca. ${h < 1 ? "${(h * 60).round()} min" : "${h.toStringAsFixed(0)} Std"}" : "Aktiv";
  }

  String _distance(Signal s, double price) {
    if (s.entries.isEmpty) return "";
    final d = price - s.entries.first.price;
    return "${d >= 0 ? "+" : ""}${px(d)} \$ zum Entry";
  }

  Widget _card({required List<Widget> children}) => Container(
        decoration: PT.cardDeco(radius: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(children: children),
      );

  Widget _row(String label, double v, bool locked, {Color? color, bool hit = false, bool dim = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Text(label, style: PT.body.copyWith(color: dim ? PT.textTertiary : PT.textSecondary)),
          const Spacer(),
          if (hit) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(CupertinoIcons.checkmark_circle_fill, size: 16, color: PT.buy)),
          locked
              ? Container(width: 64, height: 14, decoration: BoxDecoration(color: PT.hairline, borderRadius: BorderRadius.circular(4)))
              : GestureDetector(
                  onLongPress: () { HapticFeedback.mediumImpact(); Clipboard.setData(ClipboardData(text: px(v))); },
                  child: Text(px(v), style: PT.mono.copyWith(fontSize: 17, color: dim ? PT.textTertiary : (color ?? PT.textPrimary))),
                ),
        ]),
      );

  Widget _kv(String k, String v, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [Text(k, style: PT.body.copyWith(color: PT.textSecondary)), const Spacer(), Text(v, style: PT.mono.copyWith(fontSize: 17, color: color))]),
      );

  Widget _chip(String t) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: PT.card, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: PT.footnote.copyWith(color: PT.textSecondary)),
      );
}
