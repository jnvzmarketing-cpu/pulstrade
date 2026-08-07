import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/apple_button.dart';
import '../widgets/google_button.dart';
import '../l10n/gen/app_localizations.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _State();
}

class _State extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  bool _isLogin = true;
  final _nameCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).loginFillAll);
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).loginEnterName);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final err = _isLogin
        ? await auth.login(email, password)
        : await auth.register(email, password, name);
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
      if (err == null) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).loginEmailFirst);
      return;
    }
    final auth = context.read<AuthService>();
    final err = await auth.resetPassword(email);
    if (mounted) setState(() => _error = err ?? AppLocalizations.of(context).loginResetSent);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const SizedBox(height: 40),

                // LOGO
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD700), Color(0xFFC9A84C)]),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withValues(alpha: .4),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]),
                    child: const Icon(Icons.show_chart,
                        color: Colors.black, size: 40)),
                const SizedBox(height: 16),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: 'Puls',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: txt)),
                  const TextSpan(
                      text: 'trade',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: AppColors.gold)),
                ])),
                const SizedBox(height: 6),
                Text('Gold Signals · XAU/USD',
                    style: TextStyle(fontSize: 13, color: muted)),
                const SizedBox(height: 40),

                // TOGGLE
                Container(
                  decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bord, width: .5)),
                  child: Row(children: [
                    Expanded(
                        child: GestureDetector(
                      onTap: () => setState(() {
                        _isLogin = true;
                        _error = null;
                      }),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: _isLogin
                                  ? AppColors.gold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14)),
                          child: Center(
                              child: Text(AppLocalizations.of(context).signIn,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _isLogin ? Colors.black : muted)))),
                    )),
                    Expanded(
                        child: GestureDetector(
                      onTap: () => setState(() {
                        _isLogin = false;
                        _error = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color:
                                !_isLogin ? AppColors.gold : Colors.transparent,
                            borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: Text(AppLocalizations.of(context).createAccount,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: !_isLogin ? Colors.black : muted)),
                        ),
                      ),
                    )),
                  ]),
                ),
                const SizedBox(height: 24),

                // FORM
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: bord, width: .5)),
                  child: Column(children: [
                    if (!_isLogin) ...[
                      _field(AppLocalizations.of(context).fullName, _nameCtrl, txt, muted,
                          icon: Icons.person_outline),
                      Divider(color: bord, height: 16),
                    ],
                    _field(AppLocalizations.of(context).email, _emailCtrl, txt, muted,
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress),
                    Divider(color: bord, height: 16),
                    _passField(txt, muted),
                  ]),
                ),

                // ERROR
                if (_error != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _error!.startsWith('✓')
                                  ? AppColors.green
                                  : AppColors.red),
                          textAlign: TextAlign.center)),

                const SizedBox(height: 24),

                // SUBMIT BUTTON
                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: _loading
                                ? [
                                    AppColors.gold.withValues(alpha: .6),
                                    AppColors.gold.withValues(alpha: .4)
                                  ]
                                : [
                                    const Color(0xFFFFD700),
                                    const Color(0xFFC9A84C)
                                  ]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.gold.withValues(alpha: .3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2.5))
                          : Text(
                              _isLogin ? AppLocalizations.of(context).signIn : AppLocalizations.of(context).createAccount,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black),
                            ),
                    ),
                  ),
                ),

                // FORGOT PASSWORD
                if (_isLogin) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _resetPassword,
                    child: Text(AppLocalizations.of(context).forgotPassword,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600)),
                  ),
                ],

                const SizedBox(height: 32),
                AppleSignInButton(callback: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }),

                const SizedBox(height: 20),
                GoogleSignInButton(callback: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }),

                const SizedBox(height: 32),
                Text(AppLocalizations.of(context).legalNotice,
                    style: TextStyle(fontSize: 10, color: muted),
                    textAlign: TextAlign.center),
              ]))),
    );
  }

  Widget _field(
          String label, TextEditingController ctrl, Color txt, Color muted,
          {IconData? icon, TextInputType? type}) =>
      Row(children: [
        if (icon != null) Icon(icon, color: muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: muted)),
          const SizedBox(height: 2),
          TextField(
              controller: ctrl,
              style: TextStyle(fontSize: 14, color: txt),
              keyboardType: type,
              autocorrect: false,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero)),
        ])),
      ]);

  Widget _passField(Color txt, Color muted) => Row(children: [
        Icon(Icons.lock_outline, color: muted, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(AppLocalizations.of(context).password, style: TextStyle(fontSize: 10, color: muted)),
          const SizedBox(height: 2),
          TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              style: TextStyle(fontSize: 14, color: txt),
              autocorrect: false,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: GestureDetector(
                      onTap: () => setState(() => _showPass = !_showPass),
                      child: Icon(
                          _showPass ? Icons.visibility_off : Icons.visibility,
                          color: muted,
                          size: 18)))),
        ])),
      ]);
}
