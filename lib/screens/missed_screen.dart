// "Verpasst": ehrliche Urgency. Zeigt dem gesperrten Nutzer, was seit seiner
// Registrierung passiert ist. Nur echte Zahlen aus signals. Einmalig ab Tag 3
// als Sheet, danach jederzeit im Bilanz-Tab erreichbar.

import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../services/access_service.dart";
import "../services/market_repo.dart";
import "../widgets/paywall_sheet.dart";

class MissedScreen extends StatelessWidget {
  const MissedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final acc = context.read<AccessService>();
    final repo = context.read<MarketRepo>();
    final since = acc.fullAccessEnds ?? DateTime.now();

    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      navigationBar: const CupertinoNavigationBar(middle: Text("Seit deinem Zugang"), backgroundColor: PT.bg, border: null),
      child: FutureBuilder<MissedSummary?>(
        future: repo.missedSince(since),
        builder: (context, snap) {
          final m = snap.data;
          if (m == null) return const Center(child: CupertinoActivityIndicator());
          final r = m.pnlR;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 60),
              Text("${m.total} Signale.", style: PT.largeTitle),
              Text("${m.wins} haben das Ziel erreicht.", style: PT.title1.copyWith(color: PT.buy)),
              if (m.losses > 0) Text("${m.losses} den Stop.", style: PT.title1.copyWith(color: PT.textSecondary)),
              const SizedBox(height: 24),
              Text("Ergebnis mit 1 % Risiko pro Trade", style: PT.caption),
              const SizedBox(height: 6),
              Text("${r >= 0 ? "+" : ""}${r.toStringAsFixed(1)} R", style: PT.price.copyWith(color: r >= 0 ? PT.buy : PT.sell)),
              const SizedBox(height: 8),
              Text("Bei 10.000 € Konto wären das ${(r * 100).round() >= 0 ? "+" : ""}${(r * 100).round()} €. Du warst bei keinem dabei.", style: PT.body.copyWith(color: PT.textSecondary)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () => showPaywall(context, reason: PaywallReason.missed),
                  child: Text("Beim nächsten dabei sein", style: PT.button),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text("Vergangene Ergebnisse garantieren keine zukünftigen.", style: PT.footnote.copyWith(color: PT.textTertiary))),
            ]),
          );
        },
      ),
    );
  }
}
