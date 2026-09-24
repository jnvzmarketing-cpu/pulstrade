// Onboarding: drei Fragen, dann rein. Kontogröße und Risiko füttern den
// persönlichen Plan, Push-Frage registriert das Gerät. Keine Paywall hier.
import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../models/user_profile.dart";
import "../services/push_repo.dart";

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  double _balance = 5000, _risk = 1.0;

  static const _balances = [1000.0, 2500.0, 5000.0, 10000.0, 25000.0, 50000.0];
  static const _risks = [0.5, 1.0, 1.5, 2.0];

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (_step < 2) { setState(() => _step++); return; }
    final p = (await UserProfile.load()).copyWith(accountBalance: _balance, riskPercent: _risk);
    await p.save();
    widget.onDone();
  }

  Future<void> _push(bool yes) async {
    if (yes) await context.read<PushRepo>().requestAndRegister();
    await _next();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 16 + bottom),
          child: AnimatedSwitcher(
            duration: PT.normal,
            switchInCurve: PT.curve,
            child: KeyedSubtree(key: ValueKey(_step), child: _body()),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return _frame("Wie groß ist dein Konto?", "Daraus rechnen wir die Lot-Größe für jedes Signal.",
            _grid(_balances, (v) => "${v.toStringAsFixed(0)} \$", _balance, (v) => setState(() => _balance = v)), _cta("Weiter"));
      case 1:
        return _frame("Wie viel riskierst du pro Trade?", "1 % ist der Standard für Gold. Später jederzeit änderbar.",
            _grid(_risks, (v) => "${v.toStringAsFixed(1)} %", _risk, (v) => setState(() => _risk = v)), _cta("Weiter"));
      default:
        return _frame("Signale als Push?", "Ein Signal ist oft nur 30 Minuten gültig. Ohne Push verpasst du die meisten.",
            const SizedBox.shrink(),
            Column(children: [
              SizedBox(width: double.infinity, child: CupertinoButton.filled(borderRadius: BorderRadius.circular(14), onPressed: () => _push(true), child: Text("Push einschalten", style: PT.button))),
              CupertinoButton(onPressed: () => _push(false), child: Text("Später", style: PT.footnote.copyWith(color: PT.textSecondary))),
            ]));
    }
  }

  Widget _frame(String title, String sub, Widget body, Widget cta) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${_step + 1} von 3", style: PT.caption),
        const SizedBox(height: 12),
        Text(title, style: PT.title1),
        const SizedBox(height: 6),
        Text(sub, style: PT.body.copyWith(color: PT.textSecondary)),
        const SizedBox(height: 28),
        body,
        const Spacer(),
        cta,
      ]);

  Widget _grid(List<double> opts, String Function(double) label, double sel, ValueChanged<double> on) => Wrap(
        spacing: 10, runSpacing: 10,
        children: [for (final o in opts) GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); on(o); },
          child: AnimatedContainer(
            duration: PT.fast,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: o == sel ? PT.ink : PT.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: o == sel ? PT.ink : PT.hairline, width: 1)),
            child: Text(label(o), style: PT.mono.copyWith(fontSize: 17, color: o == sel ? PT.inkText : PT.textPrimary)),
          ),
        )],
      );

  Widget _cta(String t) => SizedBox(width: double.infinity, child: CupertinoButton.filled(borderRadius: BorderRadius.circular(14), onPressed: _next, child: Text(t, style: PT.button)));
}
