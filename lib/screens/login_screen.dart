// Login: Apple zuerst (iOS-Pflicht, wenn Google angeboten wird), Google,
// E-Mail als Fallback. Ein Screen, keine Slides, kein Marketing davor.

import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";
import "../core/pt_theme.dart";
import "../services/auth_repo.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false, _emailMode = false, _signUp = false;
  String? _error;
  final _email = TextEditingController(), _pw = TextEditingController();

  Future<void> _run(Future<String?> Function() f) async {
    HapticFeedback.lightImpact();
    setState(() { _busy = true; _error = null; });
    final err = await f();
    if (!mounted) return;
    setState(() { _busy = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepo>();
    final bottom = MediaQuery.of(context).padding.bottom;
    return CupertinoPageScaffold(
      backgroundColor: PT.bg,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Spacer(flex: 3),
            Text("Pulstrade", style: PT.largeTitle),
            const SizedBox(height: 6),
            Text("Gold-Signale mit Entry, Stop und Ziel.\nErgebnisse nachprüfbar, Tag für Tag.", style: PT.body.copyWith(color: PT.textSecondary)),
            const Spacer(flex: 4),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: PT.footnote.copyWith(color: PT.sell))),
            if (!_emailMode) ...[
              _btn("Mit Apple fortfahren", CupertinoIcons.chevron_right, filled: true, onTap: () => _run(auth.signInWithApple)),
              const SizedBox(height: 10),
              _btn("Mit Google fortfahren", CupertinoIcons.chevron_right, onTap: () => _run(auth.signInWithGoogle)),
              const SizedBox(height: 10),
              CupertinoButton(
                onPressed: _busy ? null : () => setState(() => _emailMode = true),
                child: Text("Mit E-Mail", style: PT.footnote.copyWith(color: PT.textSecondary)),
              ),
            ] else ...[
              _field(_email, "E-Mail", keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(_pw, "Passwort", obscure: true),
              const SizedBox(height: 14),
              _btn(_signUp ? "Konto anlegen" : "Anmelden", null, filled: true, onTap: () => _run(() => _signUp
                  ? auth.signUpWithEmail(_email.text, _pw.text)
                  : auth.signInWithEmail(_email.text, _pw.text))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                CupertinoButton(onPressed: () => setState(() => _signUp = !_signUp),
                    child: Text(_signUp ? "Ich habe schon ein Konto" : "Neu hier? Konto anlegen", style: PT.footnote.copyWith(color: PT.textSecondary))),
                CupertinoButton(onPressed: () => setState(() => _emailMode = false),
                    child: Text("Zurück", style: PT.footnote.copyWith(color: PT.textSecondary))),
              ]),
            ],
            const SizedBox(height: 8),
            Text("3 Tage voller Zugriff nach der Anmeldung. Keine Karte nötig.", textAlign: TextAlign.center, style: PT.footnote.copyWith(color: PT.textTertiary)),
          ]),
        ),
      ),
    );
  }

  Widget _btn(String label, IconData? icon, {bool filled = false, required VoidCallback onTap}) => SizedBox(
        width: double.infinity,
        child: filled
            ? CupertinoButton.filled(borderRadius: BorderRadius.circular(14), onPressed: _busy ? null : onTap,
                child: _busy ? const CupertinoActivityIndicator(color: CupertinoColors.white) : Text(label, style: PT.button))
            : CupertinoButton(color: PT.card, borderRadius: BorderRadius.circular(14), onPressed: _busy ? null : onTap,
                child: Text(label, style: PT.button)),
      );

  Widget _field(TextEditingController c, String hint, {bool obscure = false, TextInputType? keyboard}) => CupertinoTextField(
        controller: c, placeholder: hint, obscureText: obscure, keyboardType: keyboard,
        autocorrect: false, style: PT.body,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: PT.card, borderRadius: BorderRadius.circular(12)),
      );
}
