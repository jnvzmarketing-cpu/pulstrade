// Tab "Signale": alle Signale, Filter Aktiv / Aufgelöst.
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../models/signal.dart";
import "../services/access_service.dart";
import "../services/market_repo.dart";
import "../widgets/paywall_sheet.dart";
import "../widgets/signal_tile.dart";
import "signal_detail_screen.dart";

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key});
  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  int _seg = 0;

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
    final list = repo.signals.where((s) => _seg == 0 ? (s.outcome == null || s.outcome == "open") : (s.outcome != null && s.outcome != "open")).toList();

    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(largeTitle: Text("Signale"), backgroundColor: PT.bg, border: null),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _seg,
              backgroundColor: PT.cardAlt,
              thumbColor: PT.card,
              children: const {0: Text("Aktiv", style: PT.footnote), 1: Text("Aufgelöst", style: PT.footnote)},
              onValueChanged: (v) { HapticFeedback.selectionClick(); setState(() => _seg = v ?? 0); },
            ),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(_seg == 0 ? "Gerade kein aktives Signal." : "Noch nichts aufgelöst.", style: PT.body.copyWith(color: PT.textSecondary))),
          )
        else
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (_, i) => SignalTile(s: list[i], locked: !acc.canSeeLevels, livePrice: repo.price, onTap: () => _open(list[i])),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }
}
