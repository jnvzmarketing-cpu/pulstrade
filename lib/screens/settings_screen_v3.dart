// ════════════════════════════════════════════════════════════════════
// SETTINGS SCREEN V3 (Obsidian) — Phase F
// Deutsch, Klartext. Gruppen: Erscheinungsbild / Mitteilungen /
// Dein Plan / Erweitert. Hell-Dunkel-Schalter wirkt sofort app-weit.
// ════════════════════════════════════════════════════════════════════
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/subscription_service.dart';
import '../services/auth_service.dart';
import 'onboarding_quiz_screen.dart';

class SettingsScreenV3 extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenAutoTrading;
  const SettingsScreenV3({super.key, this.onOpenProfile,
      this.onOpenAutoTrading});

  @override
  State<SettingsScreenV3> createState() => _SettingsScreenV3State();
}

class _SettingsScreenV3State extends State<SettingsScreenV3> {
  bool _allSignals = true;
  double _minConf = 65;
  bool _beProtect = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _allSignals = p.getBool('notif_all') ?? true;
      _minConf = (p.getInt('min_confidence') ?? 65).toDouble();
      _beProtect = p.getBool('be_protect') ?? false;
    });
  }

  Future<void> _toggleSignals(bool v) async {
    setState(() => _allSignals = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif_all', v);
    try {
      final fm = FirebaseMessaging.instance;
      if (v) {
        await fm.subscribeToTopic('signals');
      } else {
        await fm.unsubscribeFromTopic('signals');
      }
    } catch (_) {}
  }

  Future<void> _saveConf(double v) async {
    setState(() => _minConf = v);
    final p = await SharedPreferences.getInstance();
    await p.setInt('min_confidence', v.round());
  }

  Future<void> _toggleBe(bool v) async {
    setState(() => _beProtect = v);
    final p = await SharedPreferences.getInstance();
    await p.setBool('be_protect', v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Obsidian.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(t.settingsTitle, style: TextStyle(fontSize: 22,
                color: Obsidian.textHi, fontWeight: FontWeight.w700)),
            SizedBox(height: 18),

            _accountCard(context),
            SizedBox(height: 22),

            _section(t.sectionAppearance),
            Container(
              decoration: Obsidian.cardBox,
              child: Column(children: [
                _modeTile(ObsidianMode.system, Icons.brightness_auto_outlined,
                    t.modeSystem, t.modeSystemSub),
                _div(),
                _modeTile(ObsidianMode.light, Icons.wb_sunny_outlined,
                    t.modeLight, t.modeLightSub),
                _div(),
                _modeTile(ObsidianMode.dark, Icons.nightlight_outlined,
                    t.modeDark, t.modeDarkSub),
              ]),
            ),
            SizedBox(height: 22),

            _section(t.language),
            Container(
              decoration: Obsidian.cardBox,
              child: Column(children: [
                _langTile('system', Icons.public, t.langSystem, t.langSystemSub),
                _div(),
                _langTile('de', Icons.flag_outlined, t.langGerman, 'Deutsch'),
                _div(),
                _langTile('en', Icons.flag_outlined, t.langEnglish, 'English'),
              ]),
            ),
            SizedBox(height: 22),

            _section(t.sectionNotifications),
            Container(
              decoration: Obsidian.cardBox,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Material(
                color: Colors.transparent,
                child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.notifAll, style: TextStyle(fontSize: 15,
                      color: Obsidian.textHi, fontWeight: FontWeight.w500)),
                  subtitle: Text(t.notifAllSub,
                      style: TextStyle(fontSize: 12, color: Obsidian.textMid)),
                  value: _allSignals,
                  activeColor: Obsidian.gold,
                  onChanged: _toggleSignals,
                ),
                Divider(height: 1, color: Obsidian.strokeSub),
                SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.minConfidence, style: TextStyle(fontSize: 15,
                          color: Obsidian.textHi,
                          fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text(t.minConfidenceSub,
                          style: TextStyle(fontSize: 12,
                              color: Obsidian.textMid)),
                    ],
                  )),
                  Text('${_minConf.round()}%', style: TextStyle(
                      fontFamily: Obsidian.monoFamily, fontSize: 16,
                      color: Obsidian.gold, fontWeight: FontWeight.w600)),
                ]),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Obsidian.gold,
                    inactiveTrackColor: Obsidian.cardAlt,
                    thumbColor: Obsidian.gold,
                    overlayColor: Obsidian.gold.withOpacity(0.12),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _minConf, min: 50, max: 90, divisions: 8,
                    onChanged: _saveConf,
                  ),
                ),
              ]),
              ),
            ),
            SizedBox(height: 22),

            if (widget.onOpenProfile != null ||
                widget.onOpenAutoTrading != null) ...[
            _section(t.sectionPlan),
            Container(
              decoration: Obsidian.cardBox,
              child: Column(children: [
                if (widget.onOpenProfile != null)
                  _navTile(Icons.tune, Obsidian.gold,
                      t.tradingProfile,
                      t.tradingProfileSub,
                      widget.onOpenProfile!),
                if (widget.onOpenProfile != null &&
                    widget.onOpenAutoTrading != null) _div(),
                if (widget.onOpenAutoTrading != null)
                  _navTile(Icons.bolt, Obsidian.buy,
                      t.autoTrading,
                      t.autoTradingSub,
                      widget.onOpenAutoTrading!),
              ]),
            ),
            ],
            SizedBox(height: 22),

            _section(t.sectionAdvanced),
            Container(
              decoration: Obsidian.cardBox,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Material(
                color: Colors.transparent,
                child: Column(children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.beProtect, style: TextStyle(
                      fontSize: 15, color: Obsidian.textHi,
                      fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      t.beProtectSub,

                      style: TextStyle(fontSize: 12, color: Obsidian.textMid,
                          height: 1.4)),
                  isThreeLine: true,
                  value: _beProtect,
                  activeColor: Obsidian.gold,
                  onChanged: _toggleBe,
                ),
              ]),
              ),
            ),
            SizedBox(height: 26),

            Center(child: Text(t.footerVersion,
                style: TextStyle(fontSize: 11, color: Obsidian.textLow))),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(BuildContext context) {
    final sub = context.watch<SubscriptionService>();
    final auth = context.watch<AuthService>();
    final isPro = sub.isPro;
    final email = auth.userEmail ?? auth.userName ?? 'Kein Konto verbunden';

    final statusLabel = isPro ? 'PulsTrade Pro' : 'Kostenlos';
    final statusColor = isPro ? Obsidian.gold : Obsidian.textMid;

    return Container(
      decoration: Obsidian.cardBox,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(isPro ? Icons.workspace_premium : Icons.person,
                    color: statusColor, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusLabel, style: TextStyle(fontSize: 16,
                        color: statusColor, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 12,
                        color: Obsidian.textMid),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (!isPro) ...[
            SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OnboardingQuizScreen(onDone: () =>
                      Navigator.of(context).maybePop()))),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Obsidian.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('Auf Pro upgraden',
                    style: TextStyle(fontSize: 15, color: Colors.black,
                        fontWeight: FontWeight.w700))),
              ),
            ),
          ],
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: _accountAction('Käufe wiederherstellen',
                () async {
              await sub.restore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(sub.isPro
                        ? 'Pro wiederhergestellt.'
                        : 'Keine Käufe gefunden.')));
              }
            })),
            SizedBox(width: 10),
            Expanded(child: _accountAction('Abmelden', () async {
              await auth.signOut();
              await sub.logOut();
            })),
          ]),
        ],
      ),
    );
  }

  Widget _accountAction(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border.all(color: Obsidian.stroke),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Obsidian.textHi,
                fontWeight: FontWeight.w600))),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t, style: Obsidian.sectionTitle),
  );

  Widget _div() => Divider(height: 1, indent: 56,
      color: Obsidian.strokeSub);


  Widget _langTile(String code, IconData icon, String title, String sub) {
    final sel = Obsidian.appLocaleCode == code;
    return InkWell(
      onTap: () => Obsidian.setAppLocale(code),
      borderRadius: BorderRadius.circular(Obsidian.rCard),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: sel ? Obsidian.goldBg : Obsidian.cardAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18,
                color: sel ? Obsidian.gold : Obsidian.textMid),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15,
                  color: Obsidian.textHi, fontWeight: FontWeight.w500)),
              Text(sub, style: TextStyle(fontSize: 12,
                  color: Obsidian.textMid)),
            ],
          )),
          if (sel)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: Obsidian.gold, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 14, color: Obsidian.bg),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Obsidian.stroke, width: 1.5),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _modeTile(ObsidianMode m, IconData icon, String title, String sub) {
    final sel = Obsidian.mode == m;
    return InkWell(
      onTap: () => Obsidian.setMode(m),
      borderRadius: BorderRadius.circular(Obsidian.rCard),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: sel ? Obsidian.goldBg : Obsidian.cardAlt,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18,
                color: sel ? Obsidian.gold : Obsidian.textMid),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15,
                  color: Obsidian.textHi, fontWeight: FontWeight.w500)),
              Text(sub, style: TextStyle(fontSize: 12,
                  color: Obsidian.textMid)),
            ],
          )),
          if (sel)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                  color: Obsidian.gold, shape: BoxShape.circle),
              child: Icon(Icons.check, size: 14, color: Obsidian.bg),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Obsidian.stroke, width: 1.5),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _navTile(IconData icon, Color tint, String title, String sub,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Obsidian.rCard),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15,
                  color: Obsidian.textHi, fontWeight: FontWeight.w500)),
              Text(sub, style: TextStyle(fontSize: 12,
                  color: Obsidian.textMid)),
            ],
          )),
          Icon(Icons.chevron_right, size: 20, color: Obsidian.textLow),
        ]),
      ),
    );
  }
}
