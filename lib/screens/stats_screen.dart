// Tab "Bilanz": Track Record 30/90 Tage, Verpasst (wenn gesperrt),
// Konto-Einstellungen (Kontogröße, Risiko, Push, Abo, Logout, Löschen).
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../models/user_profile.dart";
import "../services/access_service.dart";
import "../services/auth_repo.dart";
import "../services/market_repo.dart";
import "../services/push_repo.dart";
import "../widgets/paywall_sheet.dart";
import "../widgets/equity_chart.dart";
import "../core/format.dart";
import "missed_screen.dart";

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TrackRecord? _t30, _t90;
  UserProfile? _profile;
  bool _pushOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<MarketRepo>();
    final r = await Future.wait([repo.trackRecord(days: 30), repo.trackRecord(days: 90), UserProfile.load()]);
    if (!mounted) return;
    setState(() { _t30 = r[0] as TrackRecord?; _t90 = r[1] as TrackRecord?; _profile = r[2] as UserProfile; });
  }

  @override
  Widget build(BuildContext context) {
    final acc = context.watch<AccessService>();
    final auth = context.read<AuthRepo>();
    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      child: CustomScrollView(slivers: [
        const CupertinoSliverNavigationBar(largeTitle: Text("Bilanz"), backgroundColor: PT.bg, border: null),
        SliverList(delegate: SliverChildListDelegate([
          _section("Track Record"),
          _recordCard(),
          if (acc.access == Access.locked) ...[
            const SizedBox(height: 12),
            _group([_tile("Was du verpasst hast", trailing: CupertinoIcons.chevron_right,
                onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const MissedScreen())))]),
          ],
          _section("Zugang"),
          _group([
            _tile(acc.isPro ? "Pulstrade Pro aktiv" : acc.inFullAccess ? "Voller Zugriff, noch ${acc.fullAccessLeft.inHours} Std." : "Free",
                trailing: acc.isPro ? null : CupertinoIcons.chevron_right,
                onTap: acc.isPro ? null : () => showPaywall(context, reason: PaywallReason.signal)),
          ]),
          _section("Dein Konto"),
          _group([
            _tile("Kontogröße", value: _profile == null ? "" : "${_profile!.accountBalance.toStringAsFixed(0)} \$", onTap: () => _editNumber("Kontogröße in \$", _profile?.accountBalance ?? 10000, (v) => _profile!.copyWith(accountBalance: v))),
            _tile("Risiko pro Trade", value: _profile == null ? "" : "${_profile!.riskPercent.toStringAsFixed(1)} %", onTap: () => _editNumber("Risiko in %", _profile?.riskPercent ?? 1.5, (v) => _profile!.copyWith(riskPercent: v))),
          ]),
          _section("Push"),
          _group([
            _switchTile("Signale als Push", _pushOn, (v) async {
              final push = context.read<PushRepo>();
              bool ok = true;
              if (v) { ok = await push.requestAndRegister(); } else { await push.unregister(); }
              if (mounted) setState(() => _pushOn = v && ok);
            }),
          ]),
          _section(""),
          _group([
            _tile("Kauf wiederherstellen", onTap: () async { final ok = await acc.restore(); if (mounted) _toast(ok ? "Pro wiederhergestellt." : "Kein Kauf gefunden."); }),
            _tile("Abmelden", onTap: auth.signOut),
            _tile("Konto löschen", color: PT.sell, onTap: () => _confirmDelete(auth)),
          ]),
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }

  Widget _recordCard() {
    final repo = context.read<MarketRepo>();
    final closed = repo.signals.where((s) => s.outcome != null && s.outcome != "open" && s.outcome != "expired").toList();
    final t = _t30;
    final showT90 = _t90 != null && t != null && _t90!.total != t.total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        decoration: PT.cardDeco(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Letzte 30 Tage", style: PT.caption),
          const SizedBox(height: 6),
          if (t == null) Text("Noch zu wenig abgeschlossene Trades.", style: PT.body.copyWith(color: PT.textSecondary))
          else ...[
            Text(rr(t.sumR), style: PT.price.copyWith(fontSize: 34, color: t.sumR >= 0 ? PT.buy : PT.sell)),
            const SizedBox(height: 2),
            Text("${t.total} Trades · ${t.winRate.toStringAsFixed(0)} % Treffer · Ø ${t.avgR.toStringAsFixed(2)} R${showT90 ? "   ·   90 Tage ${rr(_t90!.sumR)}" : ""}", style: PT.footnote.copyWith(color: PT.textSecondary)),
          ],
          const SizedBox(height: 14),
          EquityChart(closed: closed, height: 170),
          const SizedBox(height: 10),
          Text("Kumuliertes R bei 1 % Risiko pro Trade. Jeder Punkt ist ein Trade, nachprüfbar unter Signale.", style: PT.footnote.copyWith(color: PT.textTertiary)),
        ]),
      ),
    );
  }

  Widget _section(String t) => t.isEmpty ? const SizedBox(height: 24) : Padding(padding: const EdgeInsets.fromLTRB(16, 26, 16, 10), child: Text(t, style: PT.headline.copyWith(fontSize: 20, letterSpacing: -0.4)));
  Widget _group(List<Widget> c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(
        decoration: PT.cardDeco(radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [for (var i = 0; i < c.length; i++) ...[if (i > 0) Container(height: 1, margin: const EdgeInsets.only(left: 16), color: PT.hairline), c[i]]])));

  Widget _tile(String label, {String? value, IconData? trailing, Color? color, VoidCallback? onTap}) => CupertinoButton(
        padding: EdgeInsets.zero, onPressed: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: PT.cardDeco(radius: 16),
          child: Row(children: [
            Text(label, style: PT.body.copyWith(color: color)),
            const Spacer(),
            if (value != null) Text(value, style: PT.mono.copyWith(color: PT.textSecondary)),
            if (trailing != null || onTap != null && value == null) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(CupertinoIcons.chevron_right, size: 14, color: PT.textTertiary)),
          ]),
        ),
      );

  Widget _switchTile(String label, bool v, ValueChanged<bool> on) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(children: [Text(label, style: PT.body), const Spacer(), CupertinoSwitch(value: v, activeTrackColor: PT.gold, onChanged: (x) { HapticFeedback.selectionClick(); on(x); })]),
      );

  Future<void> _editNumber(String title, double current, UserProfile Function(double) apply) async {
    final c = TextEditingController(text: current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1));
    final v = await showCupertinoDialog<double>(context: context, builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(padding: const EdgeInsets.only(top: 12), child: CupertinoTextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true)),
      actions: [
        CupertinoDialogAction(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(ctx)),
        CupertinoDialogAction(isDefaultAction: true, child: const Text("Speichern"), onPressed: () => Navigator.pop(ctx, double.tryParse(c.text.replaceAll(",", ".")))),
      ],
    ));
    if (v == null || _profile == null) return;
    final p = apply(v);
    await p.save();
    if (mounted) setState(() => _profile = p);
  }

  void _confirmDelete(AuthRepo auth) => showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Konto löschen?"),
        content: const Text("Dein Zugang und deine Einstellungen werden dauerhaft entfernt."),
        actions: [
          CupertinoDialogAction(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(ctx)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text("Löschen"), onPressed: () async { Navigator.pop(ctx); await auth.deleteAccount(); }),
        ],
      ));

  void _toast(String msg) => showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(content: Text(msg), actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(ctx))]));
}
