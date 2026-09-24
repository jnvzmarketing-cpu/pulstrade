// Tab "Markt": zählender Kurs, Candlestick-Chart mit Timeframe-Wahl,
// aktive Signale als Hero-Karten, zuletzt aufgelöst kompakt.
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/format.dart";
import "../core/pt_theme.dart";
import "../models/signal.dart";
import "../services/access_service.dart";
import "../services/market_repo.dart";
import "../widgets/animated_number.dart";
import "../widgets/candle_chart.dart";
import "../widgets/paywall_sheet.dart";
import "../widgets/signal_tile.dart";
import "signal_detail_screen.dart";

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _tfs = ["5min", "15min", "1h", "4h"];
  static const _tfLabels = {"5min": "5m", "15min": "15m", "1h": "1H", "4h": "4H"};
  String _tf = "15min";
  List<Candle> _candles = const [];
  DateTime? _loadedFor;

  Future<void> _load(MarketRepo repo) async {
    final c = await repo.candles(_tf, limit: 160);
    if (mounted) setState(() => _candles = c);
  }

  Future<void> _open(Signal s) async {
    final acc = context.read<AccessService>();
    if (!acc.canSeeLevels) {
      final ok = await showPaywall(context, reason: PaywallReason.signal, signal: s);
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SignalDetailScreen(signal: s)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MarketRepo>();
    final acc = context.watch<AccessService>();
    if (repo.priceTs != null && _loadedFor != repo.priceTs) { _loadedFor = repo.priceTs; _load(repo); }
    final active = repo.signals.where((s) => s.outcome == null || s.outcome == "open").toList();
    final recent = repo.signals.where((s) => s.outcome != null && s.outcome != "open").take(6).toList();
    final chg = repo.dayChangePct;

    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(largeTitle: Text("Gold"), backgroundColor: PT.bg, border: null),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AnimatedPrice(value: repo.price, style: PT.price),
              const SizedBox(width: 10),
              if (chg != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: chg >= 0 ? PT.buySoft : PT.sellSoft, borderRadius: BorderRadius.circular(6)),
                child: Text("${chg >= 0 ? "+" : ""}${chg.toStringAsFixed(2)} %", style: PT.mono.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: chg >= 0 ? PT.buy : PT.sell)),
              )),
            ]),
            const SizedBox(height: 2),
            Text(repo.priceAge == null ? "Verbinde …" : repo.priceStale ? "Keine aktuellen Daten" : "COMEX Gold · Stand vor ${repo.priceAge!.inMinutes} min",
                style: PT.footnote.copyWith(color: repo.priceStale ? PT.sell : PT.textTertiary)),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            for (final tf in _tfs) Padding(padding: const EdgeInsets.only(right: 6), child: _TfChip(label: _tfLabels[tf]!, selected: _tf == tf, onTap: () { HapticFeedback.selectionClick(); setState(() { _tf = tf; _candles = const []; }); _load(repo); })),
          ]),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 4, 6),
            decoration: PT.cardDeco(),
            child: CandleChart(key: ValueKey(_tf), candles: _candles, livePrice: repo.price, height: 240, initialVisible: 48),
          ),
        )),
        if (acc.access == Access.full) SliverToBoxAdapter(child: _FullAccessNote(acc)),
        _section("Aktive Signale", active.isEmpty ? "Gerade kein aktives Signal. Der Scanner läuft, Push kommt sofort." : null),
        SliverList.builder(itemCount: active.length, itemBuilder: (_, i) => SignalTile(s: active[i], locked: !acc.canSeeLevels, livePrice: repo.price, onTap: () => _open(active[i]))),
        _section("Zuletzt aufgelöst", recent.isEmpty ? "Noch keine abgeschlossenen Trades." : null),
        SliverList.builder(itemCount: recent.length, itemBuilder: (_, i) => SignalTile(s: recent[i], locked: !acc.canSeeLevels, onTap: () => _open(recent[i]))),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }

  Widget _section(String title, String? empty) => SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: PT.headline.copyWith(fontSize: 20, letterSpacing: -0.4)),
          if (empty != null) Padding(padding: const EdgeInsets.only(top: 10), child: Container(
            width: double.infinity, padding: const EdgeInsets.all(18), decoration: PT.cardDeco(),
            child: Text(empty, style: PT.body.copyWith(color: PT.textSecondary)))),
        ]),
      ));
}

class _TfChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _TfChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: AnimatedContainer(
        duration: PT.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: selected ? PT.ink : PT.cardAlt, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: PT.footnote.copyWith(fontWeight: FontWeight.w600, color: selected ? PT.inkText : PT.textSecondary)),
      ));
}

class _FullAccessNote extends StatelessWidget {
  final AccessService acc;
  const _FullAccessNote(this.acc);
  @override
  Widget build(BuildContext context) {
    final left = acc.fullAccessLeft;
    final txt = left.inHours >= 24 ? "Noch ${left.inDays + 1} Tage voller Zugriff" : "Noch ${left.inHours} Std. voller Zugriff";
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: PT.ink, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(CupertinoIcons.clock, size: 16, color: PT.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(txt, style: PT.footnote.copyWith(color: PT.inkText, fontWeight: FontWeight.w500))),
          CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: () { HapticFeedback.selectionClick(); showPaywall(context, reason: PaywallReason.signal); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: PT.gold, borderRadius: BorderRadius.circular(8)),
                  child: Text("Pro", style: PT.footnote.copyWith(color: PT.ink, fontWeight: FontWeight.w700)))),
        ]),
      ),
    );
  }
}
