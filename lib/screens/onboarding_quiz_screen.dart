// ════════════════════════════════════════════════════════════════════
// ONBOARDING QUIZ — replaces both onboarding_screen.dart and
// paywall_funnel_screen.dart. One flow:
//
//   Hook → Mode (Sniper default) → Experience → Pain point →
//   Account size → Risk appetite → Session → Broker →
//   Notifications → Calculating → Your profile → Paywall
//
// Every answer feeds the real UserProfile (lot math, signal filtering,
// FCM topics). Pricing is loaded from RevenueCat — never hardcoded.
// No invented social proof; stats come live from the backend.
// ════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_v2_service.dart';
import '../services/subscription_service.dart';
import '../services/trial_reminder_service.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';

class OnboardingQuizScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingQuizScreen({super.key, required this.onDone});

  static Future<bool> shouldShow() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool('onboarding_quiz_done') ?? false);
  }

  static Future<void> markDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_quiz_done', true);
    await p.setBool('onboarding_done', true); // legacy flag
  }

  @override
  State<OnboardingQuizScreen> createState() => _State();
}

enum _Step {
  hook,
  mode,
  experience,
  pain,
  account,
  risk,
  session,
  broker,
  notifications,
  calculating,
  result,
  paywall,
}

class _State extends State<OnboardingQuizScreen> with TickerProviderStateMixin {
  _Step _step = _Step.hook;
  UserProfile _profile = UserProfile();

  // Live stats (real numbers only — shown only if the backend answers).
  double? _winRate;
  double? _avgRR;
  int? _totalSignals;
  static final _backendUrl =
      'https://pulstrade-backend-production.up.railway.app';

  // Paywall state
  bool _yearlySelected = true;
  bool _remindMe = true;
  bool _purchasing = false;
  String? _error;

  late final AnimationController _calcCtrl =
      AnimationController(vsync: this, duration: Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  @override
  void dispose() {
    _calcCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final res = await http
          .get(Uri.parse('$_backendUrl/stats'))
          .timeout(Duration(seconds: 6));
      if (res.statusCode == 200 && mounted) {
        final d = json.decode(res.body) as Map<String, dynamic>;
        setState(() {
          _winRate = (d['winRate'] as num?)?.toDouble();
          _avgRR = (d['avgRR'] as num?)?.toDouble();
          _totalSignals = d['totalSignals'] as int?;
        });
      }
    } catch (_) {}
  }

  int get _stepIndex => _Step.values.indexOf(_step);
  int get _quizLength => _Step.values.indexOf(_Step.notifications) + 1;

  void _next() {
    HapticFeedback.lightImpact();
    final i = _stepIndex;
    if (_step == _Step.notifications) {
      setState(() => _step = _Step.calculating);
      _calcCtrl.forward(from: 0);
      Future.delayed(Duration(milliseconds: 2900), () {
        if (mounted) setState(() => _step = _Step.result);
      });
      return;
    }
    if (i < _Step.values.length - 1) {
      setState(() => _step = _Step.values[i + 1]);
    }
  }

  void _back() {
    HapticFeedback.lightImpact();
    final i = _stepIndex;
    if (i > 0 && _step != _Step.calculating) {
      setState(() => _step = _Step.values[i - 1]);
    }
  }

  Future<void> _requestNotifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
    _next();
  }

  Future<void> _saveProfile() async {
    await context.read<ProfileV2Service>().update(_profile);
  }

  Future<void> _purchase() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _purchasing = true;
      _error = null;
    });

    // Profile is saved regardless of purchase outcome.
    await _saveProfile();

    // Sign in (Apple on iOS, Google elsewhere) if needed.
    if (mounted) {
      final auth = context.read<AuthService>();
      if (auth.currentUser == null) {
        final err = Platform.isIOS
            ? await auth.signInWithApple()
            : await auth.signInWithGoogle();
        if (!mounted) return;
        if (err == 'cancelled') {
          setState(() => _purchasing = false);
          return;
        }
        if (err != null) {
          setState(() {
            _error = err;
            _purchasing = false;
          });
          return;
        }
      }
    }

    if (!mounted) return;
    final sub = context.read<SubscriptionService>();
    // Bind RevenueCat to the Firebase UID so web (Stripe) purchases match this user.
    final uid = context.read<AuthService>().userId;
    if (uid != null) await sub.logIn(uid);
    if (!mounted) return;
    final Package? pkg = _yearlySelected
        ? (sub.annualPackage ?? sub.monthlyPackage)
        : (sub.monthlyPackage ?? sub.annualPackage);
    if (pkg == null) {
      setState(() {
        _error = AppLocalizations.of(context).plansLoading;
        _purchasing = false;
      });
      return;
    }

    final err = await sub.purchase(pkg);
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      _error = err == 'cancelled' ? null : err;
    });
    if (err == null) {
      if (_remindMe) {
        await TrialReminderService.scheduleTrialEndingReminder();
      }
      await OnboardingQuizScreen.markDone();
      widget.onDone();
    }
  }

  Future<void> _skipPaywall() async {
    await _saveProfile();
    await OnboardingQuizScreen.markDone();
    widget.onDone();
  }

  // ════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Obsidian.bg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          if (_step != _Step.calculating) _topBar(isDark),
          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 280),
              switchInCurve: Curves.easeOut,
              child: _buildStep(isDark),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _topBar(bool isDark) {
    final muted = Obsidian.textMid;
    final showProgress = _stepIndex >= 1 && _stepIndex < _quizLength;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        if (_stepIndex > 0 && _step != _Step.paywall && _step != _Step.result)
          GestureDetector(
            onTap: _back,
            child: Icon(Icons.arrow_back_rounded, size: 22, color: muted),
          )
        else
          SizedBox(width: 22),
        SizedBox(width: 12),
        if (showProgress)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _stepIndex / (_quizLength - 1),
                minHeight: 5,
                backgroundColor: muted.withValues(alpha: .15),
                valueColor: AlwaysStoppedAnimation(Obsidian.gold),
              ),
            ),
          )
        else
          Spacer(),
        SizedBox(width: 34),
      ]),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_step) {
      case _Step.hook:
        return _hookStep(isDark);
      case _Step.mode:
        return _choiceStep(
          key: ValueKey('mode'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).secOneDecision,
          title: AppLocalizations.of(context).qHowTrade,
          subtitle: AppLocalizations.of(context).decisionNote,
          options: [
            _Opt(
              icon: Icons.my_location_rounded,
              title: 'Sniper',
              subtitle: AppLocalizations.of(context).sniperDesc,
              badge: AppLocalizations.of(context).recommended,
              selected: _profile.mode == TradeMode.sniper,
              onTap: () => setState(
                  () => _profile = _profile.copyWith(mode: TradeMode.sniper)),
            ),
            _Opt(
              icon: Icons.bolt_rounded,
              title: 'Executor',
              subtitle: AppLocalizations.of(context).executorDesc,
              selected: _profile.mode == TradeMode.executor,
              onTap: () => setState(
                  () => _profile = _profile.copyWith(mode: TradeMode.executor)),
            ),
          ],
        );
      case _Step.experience:
        return _chipStep(
          key: ValueKey('exp'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).secAboutYou,
          title: AppLocalizations.of(context).qExperience,
          values: [
            AppLocalizations.of(context).expNew,
            'Unter 1 Jahr',
            AppLocalizations.of(context).exp1to3,
            AppLocalizations.of(context).exp3plus
          ],
          selected: _profile.experience,
          onSelect: (v) =>
              setState(() => _profile = _profile.copyWith(experience: v)),
        );
      case _Step.pain:
        return _chipStep(
          key: ValueKey('pain'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).secLeak,
          title: AppLocalizations.of(context).qCost,
          values: [
            AppLocalizations.of(context).leakMissed,
            AppLocalizations.of(context).leakLots,
            AppLocalizations.of(context).leakFomo,
            AppLocalizations.of(context).leakNoPlan,
            AppLocalizations.of(context).leakEarlyExit,
          ],
          selected: _profile.painPoint,
          onSelect: (v) =>
              setState(() => _profile = _profile.copyWith(painPoint: v)),
        );
      case _Step.account:
        return _accountStep(isDark);
      case _Step.risk:
        return _choiceStep(
          key: ValueKey('risk'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).secRiskProfile,
          title: AppLocalizations.of(context).qPicky,
          subtitle: AppLocalizations.of(context).notifNote,
          options: [
            _Opt(
              icon: Icons.shield_rounded,
              title: AppLocalizations.of(context).conservative,
              subtitle: AppLocalizations.of(context).conservativeSub,
              selected: _profile.riskAppetite == RiskAppetite.conservative,
              onTap: () => setState(() => _profile =
                  _profile.copyWith(riskAppetite: RiskAppetite.conservative)),
            ),
            _Opt(
              icon: Icons.balance_rounded,
              title: AppLocalizations.of(context).balanced,
              subtitle: AppLocalizations.of(context).balancedSub,
              selected: _profile.riskAppetite == RiskAppetite.moderate,
              onTap: () => setState(() => _profile =
                  _profile.copyWith(riskAppetite: RiskAppetite.moderate)),
            ),
            _Opt(
              icon: Icons.local_fire_department_rounded,
              title: AppLocalizations.of(context).aggressive,
              subtitle: AppLocalizations.of(context).aggressiveSub,
              selected: _profile.riskAppetite == RiskAppetite.aggressive,
              onTap: () => setState(() => _profile =
                  _profile.copyWith(riskAppetite: RiskAppetite.aggressive)),
            ),
          ],
        );
      case _Step.session:
        return _choiceStep(
          key: ValueKey('session'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).secTimes,
          title: AppLocalizations.of(context).qWhenCharts,
          subtitle: AppLocalizations.of(context).timesNote,
          options: [
            _Opt(
              icon: Icons.wb_twilight_rounded,
              title: 'Tokyo',
              subtitle: AppLocalizations.of(context).tokyoTime,
              selected: _profile.session == TradingSession.tokyo,
              onTap: () => setState(() =>
                  _profile = _profile.copyWith(session: TradingSession.tokyo)),
            ),
            _Opt(
              icon: Icons.account_balance_rounded,
              title: 'London',
              subtitle: AppLocalizations.of(context).londonTime,
              selected: _profile.session == TradingSession.london,
              onTap: () => setState(() =>
                  _profile = _profile.copyWith(session: TradingSession.london)),
            ),
            _Opt(
              icon: Icons.location_city_rounded,
              title: 'New York',
              subtitle: AppLocalizations.of(context).nyTime,
              selected: _profile.session == TradingSession.newYork,
              onTap: () => setState(() => _profile =
                  _profile.copyWith(session: TradingSession.newYork)),
            ),
            _Opt(
              icon: Icons.public_rounded,
              title: AppLocalizations.of(context).allSessions,
              subtitle: AppLocalizations.of(context).allSessionsSub,
              selected: _profile.session == TradingSession.all,
              onTap: () => setState(() =>
                  _profile = _profile.copyWith(session: TradingSession.all)),
            ),
          ],
        );
      case _Step.broker:
        return _chipStep(
          key: ValueKey('broker'),
          isDark: isDark,
          kicker: AppLocalizations.of(context).optionalTag,
          title: AppLocalizations.of(context).qBroker,
          values: [
            'VT Markets',
            'IC Markets',
            'FTMO',
            'Vantage',
            AppLocalizations.of(context).brokerOther,
            AppLocalizations.of(context).brokerNone
          ],
          selected: _profile.broker,
          onSelect: (v) =>
              setState(() => _profile = _profile.copyWith(broker: v)),
        );
      case _Step.notifications:
        return _notificationsStep(isDark);
      case _Step.calculating:
        return _calculatingStep(isDark);
      case _Step.result:
        return _resultStep(isDark);
      case _Step.paywall:
        return _paywallStep(isDark);
    }
  }

  // ── Step 0: Hook ────────────────────────────────────────────────────
  Widget _hookStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    return Padding(
      key: ValueKey('hook'),
      padding: EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(children: [
        Spacer(),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Obsidian.gold.withValues(alpha: .12),
            shape: BoxShape.circle,
            border: Border.all(
                color: Obsidian.gold.withValues(alpha: .3), width: 2),
          ),
          child:
              Icon(Icons.my_location_rounded, color: Obsidian.gold, size: 38),
        ),
        SizedBox(height: 28),
        Text(AppLocalizations.of(context).hookTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: txt,
                height: 1.2)),
        SizedBox(height: 14),
        Text(
          AppLocalizations.of(context).hookSub,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: muted, height: 1.5),
        ),
        SizedBox(height: 22),
        if (_winRate != null || _totalSignals != null)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_totalSignals != null)
              _stat('$_totalSignals', AppLocalizations.of(context).statTracked,
                  muted, txt),
            if (_totalSignals != null && _winRate != null) SizedBox(width: 28),
            if (_winRate != null)
              _stat('${_winRate!.toStringAsFixed(0)}%',
                  AppLocalizations.of(context).histWinRate, muted, txt),
          ]),
        Spacer(),
        _primaryButton(AppLocalizations.of(context).hookCta, _next),
        SizedBox(height: 10),
        Text(AppLocalizations.of(context).hookDuration,
            style: TextStyle(fontSize: 12, color: muted)),
      ]),
    );
  }

  Widget _stat(String value, String label, Color muted, Color txt) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: txt)),
        Text(label, style: TextStyle(fontSize: 11, color: muted)),
      ]);

  // ── Choice step (card options) ──────────────────────────────────────
  Widget _choiceStep({
    required Key key,
    required bool isDark,
    required String kicker,
    required String title,
    String? subtitle,
    required List<_Opt> options,
  }) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final hasSelection = options.any((o) => o.selected);
    return Padding(
      key: key,
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 8),
        Text(kicker,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Obsidian.gold,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: txt)),
        if (subtitle != null) ...[
          SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: muted)),
        ],
        SizedBox(height: 20),
        Expanded(
          child: ListView(children: [
            for (final o in options) _OptionCard(opt: o, isDark: isDark),
          ]),
        ),
        _primaryButton(AppLocalizations.of(context).continueBtn,
            hasSelection ? _next : null),
      ]),
    );
  }

  // ── Chip step (compact choices) ─────────────────────────────────────
  Widget _chipStep({
    required Key key,
    required bool isDark,
    required String kicker,
    required String title,
    required List<String> values,
    required String? selected,
    required void Function(String) onSelect,
  }) {
    final txt = Obsidian.textHi;
    return Padding(
      key: key,
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 8),
        Text(kicker,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Obsidian.gold,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text(title,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: txt)),
        SizedBox(height: 24),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final v in values)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(v);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected == v
                      ? Obsidian.gold.withValues(alpha: .16)
                      : (Obsidian.card),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected == v ? Obsidian.gold : (Obsidian.stroke),
                    width: selected == v ? 1.5 : 1,
                  ),
                ),
                child: Text(v,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected == v ? FontWeight.w800 : FontWeight.w600,
                        color: selected == v ? Obsidian.gold : txt)),
              ),
            ),
        ]),
        Spacer(),
        _primaryButton(AppLocalizations.of(context).continueBtn,
            selected != null ? _next : null),
      ]),
    );
  }

  // ── Account size step ───────────────────────────────────────────────
  Widget _accountStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final risk = _profile.riskAmount;
    return Padding(
      key: ValueKey('account'),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 8),
        Text(AppLocalizations.of(context).secNumbers,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Obsidian.gold,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text(AppLocalizations.of(context).resultAccount,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, color: txt)),
        SizedBox(height: 6),
        Text(AppLocalizations.of(context).numbersNote,
            style: TextStyle(fontSize: 13, color: muted)),
        SizedBox(height: 32),
        Text(AppLocalizations.of(context).accountSizeLabel,
            style: TextStyle(fontSize: 13, color: muted)),
        Text('\$${_profile.accountBalance.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w900, color: txt)),
        Slider(
          value: _profile.accountBalance.clamp(500, 100000),
          min: 500,
          max: 100000,
          divisions: 199,
          activeColor: Obsidian.gold,
          onChanged: (v) => setState(() => _profile =
              _profile.copyWith(accountBalance: (v / 500).round() * 500)),
        ),
        SizedBox(height: 18),
        Text(AppLocalizations.of(context).riskPerTrade,
            style: TextStyle(fontSize: 13, color: muted)),
        Text('${_profile.riskPercent.toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w900, color: txt)),
        Slider(
          value: _profile.riskPercent.clamp(0.5, 5),
          min: 0.5,
          max: 5,
          divisions: 18,
          activeColor: Obsidian.gold,
          onChanged: (v) => setState(() => _profile = _profile.copyWith(
              riskPercent: double.parse(v.toStringAsFixed(2)))),
        ),
        SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Obsidian.gold.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppLocalizations.of(context).riskNever(risk.toStringAsFixed(0)),
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Obsidian.gold),
          ),
        ),
        Spacer(),
        _primaryButton(AppLocalizations.of(context).continueBtn, _next),
      ]),
    );
  }

  // ── Notifications step ──────────────────────────────────────────────
  Widget _notificationsStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final isSniper = _profile.mode == TradeMode.sniper;
    return Padding(
      key: ValueKey('notif'),
      padding: EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(children: [
        Spacer(),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Obsidian.gold.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_active_rounded,
              color: Obsidian.gold, size: 38),
        ),
        SizedBox(height: 28),
        Text(
          isSniper
              ? AppLocalizations.of(context).notifTitle
              : AppLocalizations.of(context).notifNever,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: txt,
              height: 1.25),
        ),
        SizedBox(height: 12),
        Text(
          isSniper
              ? AppLocalizations.of(context).notifBody
              : AppLocalizations.of(context).notifBodyLive,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: muted, height: 1.5),
        ),
        Spacer(),
        _primaryButton(
            AppLocalizations.of(context).enableNotifs, _requestNotifications),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _next,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Text(AppLocalizations.of(context).maybeLater,
                style: TextStyle(fontSize: 13, color: muted)),
          ),
        ),
      ]),
    );
  }

  // ── Calculating step ────────────────────────────────────────────────
  Widget _calculatingStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final lines = [
      AppLocalizations.of(context).calcBuilding,
      AppLocalizations.of(context).calcLots,
      AppLocalizations.of(context).calcFilter,
      AppLocalizations.of(context).calcSessions,
    ];
    return Center(
      key: ValueKey('calc'),
      child: AnimatedBuilder(
        animation: _calcCtrl,
        builder: (ctx, _) {
          final idx = (_calcCtrl.value * lines.length)
              .floor()
              .clamp(0, lines.length - 1);
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: _calcCtrl.value,
                strokeWidth: 5,
                color: Obsidian.gold,
                backgroundColor: muted.withValues(alpha: .15),
              ),
            ),
            SizedBox(height: 28),
            Text(lines[idx],
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: txt)),
          ]);
        },
      ),
    );
  }

  // ── Result step ─────────────────────────────────────────────────────
  Widget _resultStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final card = Obsidian.card;
    final bord = Obsidian.stroke;
    final isSniper = _profile.mode == TradeMode.sniper;
    final sessionName = switch (_profile.session) {
      TradingSession.tokyo => 'Tokyo Session',
      TradingSession.london => 'London Session',
      TradingSession.newYork => 'New York Session',
      TradingSession.all => AppLocalizations.of(context).allSessions,
    };

    return Padding(
      key: ValueKey('result'),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: 8),
        Text(AppLocalizations.of(context).resultReady,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Obsidian.gold,
                letterSpacing: 1.5)),
        SizedBox(height: 8),
        Text(
            isSniper
                ? AppLocalizations.of(context).youAreSniper
                : AppLocalizations.of(context).youAreExecutor,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: txt)),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bord, width: 0.5),
          ),
          child: Column(children: [
            _resultRow(
                Icons.my_location_rounded,
                isSniper
                    ? AppLocalizations.of(context).modeZoneLabel
                    : AppLocalizations.of(context).modeLiveLabel,
                isSniper
                    ? AppLocalizations.of(context).resultZones
                    : AppLocalizations.of(context).resultInstant,
                txt,
                muted),
            _div(bord),
            _resultRow(
                Icons.pie_chart_rounded,
                AppLocalizations.of(context)
                    .resultLadder(_profile.tpWeights.join('/')),
                AppLocalizations.of(context)
                    .resultTp1(_profile.tpWeights.first),
                txt,
                muted),
            _div(bord),
            _resultRow(
                Icons.shield_rounded,
                AppLocalizations.of(context)
                    .resultMaxRisk(_profile.riskAmount.toStringAsFixed(0)),
                '${_profile.riskPercent.toStringAsFixed(1)}% von \$${_profile.accountBalance.toStringAsFixed(0)} — Lot-Größen rechnen wir für dich',
                txt,
                muted),
            _div(bord),
            _resultRow(Icons.schedule_rounded, sessionName,
                AppLocalizations.of(context).pushOnlyTrading, txt, muted),
          ]),
        ),
        Spacer(),
        _primaryButton(AppLocalizations.of(context).showMyPlan, _next),
      ]),
    );
  }

  Widget _div(Color bord) => Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: bord, height: 1),
      );

  Widget _resultRow(
          IconData icon, String title, String sub, Color txt, Color muted) =>
      Row(children: [
        Icon(icon, color: Obsidian.gold, size: 20),
        SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: txt)),
            SizedBox(height: 2),
            Text(sub,
                style: TextStyle(fontSize: 12, color: muted, height: 1.3)),
          ]),
        ),
      ]);

  // ── Paywall step ────────────────────────────────────────────────────
  Widget _paywallStep(bool isDark) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    final card = Obsidian.card;
    final bord = Obsidian.stroke;
    final sub = context.watch<SubscriptionService>();

    final annualPrice = sub.annualPriceString;
    final monthlyPrice = sub.monthlyPriceString;
    final perDay = sub.annualPerDayString;

    return SingleChildScrollView(
      key: ValueKey('paywall'),
      padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context).paywallTitle,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w900, color: txt)),
        SizedBox(height: 6),
        Text(
            AppLocalizations.of(context).paywallUnlockMode(
                _profile.mode == TradeMode.sniper ? 'Sniper' : 'Executor'),
            style: TextStyle(fontSize: 14, color: muted)),
        SizedBox(height: 18),
        // Trial timeline
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: bord, width: 0.5),
          ),
          child: Column(children: [
            _timelineRow(
                Icons.lock_open_rounded,
                AppLocalizations.of(context).tlToday,
                AppLocalizations.of(context).tlTodaySub,
                Obsidian.gold,
                txt,
                muted,
                first: true),
            _timelineRow(
                Icons.notifications_rounded,
                AppLocalizations.of(context).tlDay5,
                AppLocalizations.of(context).tlDay5Sub,
                Obsidian.gold,
                txt,
                muted),
            _timelineRow(
                Icons.star_rounded,
                AppLocalizations.of(context).tlDay7,
                AppLocalizations.of(context).tlDay7Sub,
                Obsidian.gold,
                txt,
                muted,
                last: true),
          ]),
        ),
        SizedBox(height: 10),

        // Reminder toggle
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: bord, width: 0.5),
          ),
          child: Row(children: [
            Expanded(
              child: Text(AppLocalizations.of(context).reminderToggle,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: txt)),
            ),
            Switch(
              value: _remindMe,
              activeThumbColor: Obsidian.gold,
              onChanged: (v) => setState(() => _remindMe = v),
            ),
          ]),
        ),
        SizedBox(height: 16),

        // Plan selector — yearly default
        Row(children: [
          Expanded(
            child: _planCard(
              selected: _yearlySelected,
              title: AppLocalizations.of(context).yearly,
              price: annualPrice == null ? '—' : '$annualPrice / ${AppLocalizations.of(context).year}',
              sub: '',
              badge: AppLocalizations.of(context).bestDealCaps,
              isDark: isDark,
              onTap: () => setState(() => _yearlySelected = true),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _planCard(
              selected: !_yearlySelected,
              title: AppLocalizations.of(context).monthly,
              price: monthlyPrice == null ? '—' : '$monthlyPrice / ${AppLocalizations.of(context).month}',
              sub: '',
              isDark: isDark,
              onTap: () => setState(() => _yearlySelected = false),
            ),
          ),
        ]),
        SizedBox(height: 16),

        // Features (short)
        for (final f in [
          (_profile.mode == TradeMode.sniper
              ? AppLocalizations.of(context).featZoneLadder
              : AppLocalizations.of(context).featLiveLadder),
          AppLocalizations.of(context).featLots,
          AppLocalizations.of(context).featPushes,
          AppLocalizations.of(context).featMt5,
        ])
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(Icons.check_rounded, color: Obsidian.buy, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(f, style: TextStyle(fontSize: 13, color: txt))),
            ]),
          ),

        // Real stats only — nothing invented.
        if (_winRate != null && _totalSignals != null) ...[
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: card.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: bord, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context).trackRecord(
                  _winRate!.toStringAsFixed(0),
                  _totalSignals ?? 0,
                  _avgRR != null ? ' · Ø ${_avgRR!.toStringAsFixed(2)}R' : ''),
              style: TextStyle(fontSize: 11, color: muted, height: 1.4),
            ),
          ),
        ],
        SizedBox(height: 16),

        if (_error != null)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(_error!,
                style: TextStyle(
                    fontSize: 12,
                    color: Obsidian.sell,
                    fontWeight: FontWeight.w600)),
          ),

        _primaryButton(
          _purchasing
              ? null
              : _yearlySelected
                  ? AppLocalizations.of(context)
                      .startTrialYearly(annualPrice ?? '—')
                  : AppLocalizations.of(context)
                      .startTrialMonthly(monthlyPrice ?? '—'),
          _purchasing ? null : _purchase,
          loading: _purchasing,
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
              _yearlySelected
                  ? AppLocalizations.of(context)
                      .trialTermsYearly(annualPrice ?? '—')
                  : AppLocalizations.of(context)
                      .trialTermsMonthly(monthlyPrice ?? '—'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ),
        SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => context.read<SubscriptionService>().restore(),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(AppLocalizations.of(context).restorePurchase,
                  style: TextStyle(fontSize: 11, color: muted)),
            ),
          ),
          GestureDetector(
            onTap: _skipPaywall,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Text(AppLocalizations.of(context).continueFree,
                  style: TextStyle(fontSize: 11, color: muted)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _timelineRow(IconData icon, String day, String text, Color accent,
          Color txt, Color muted,
          {bool first = false, bool last = false}) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: accent),
          ),
          if (!last)
            Container(
                width: 2, height: 22, color: accent.withValues(alpha: .2)),
        ]),
        SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 12, top: 4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(day,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: txt)),
              Text(text, style: TextStyle(fontSize: 12, color: muted)),
            ]),
          ),
        ),
      ]);

  Widget _planCard({
    required bool selected,
    required String title,
    required String price,
    required String sub,
    String? badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? Obsidian.gold.withValues(alpha: .12) : (Obsidian.card),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Obsidian.gold : (Obsidian.stroke),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: txt)),
            Spacer(),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Obsidian.gold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.black)),
              ),
          ]),
          SizedBox(height: 8),
          Text(price,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: txt)),
          Text(sub, style: TextStyle(fontSize: 11, color: muted)),
        ]),
      ),
    );
  }

  Widget _primaryButton(String? label, VoidCallback? onTap,
          {bool loading = false}) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 150),
          opacity: onTap == null && !loading ? 0.4 : 1,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Obsidian.gold,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Obsidian.gold.withValues(alpha: .35),
                    blurRadius: 16,
                    offset: Offset(0, 5)),
              ],
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2.5),
                    )
                  : Text(label ?? '',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black)),
            ),
          ),
        ),
      );
}

// ── Option card ───────────────────────────────────────────────────────
class _Opt {
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;
  _Opt({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.selected,
    required this.onTap,
  });
}

class _OptionCard extends StatelessWidget {
  final _Opt opt;
  final bool isDark;
  _OptionCard({required this.opt, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txt = Obsidian.textHi;
    final muted = Obsidian.textMid;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        opt.onTap();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: opt.selected
              ? Obsidian.gold.withValues(alpha: .12)
              : (Obsidian.card),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: opt.selected ? Obsidian.gold : (Obsidian.stroke),
            width: opt.selected ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Obsidian.gold.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(opt.icon, color: Obsidian.gold, size: 20),
          ),
          SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(opt.title,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: txt)),
                if (opt.badge != null) ...[
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Obsidian.gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(opt.badge!,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.black)),
                  ),
                ],
              ]),
              SizedBox(height: 3),
              Text(opt.subtitle,
                  style: TextStyle(fontSize: 12, color: muted, height: 1.35)),
            ]),
          ),
          SizedBox(width: 8),
          Icon(
            opt.selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: opt.selected ? Obsidian.gold : muted.withValues(alpha: .4),
            size: 22,
          ),
        ]),
      ),
    );
  }
}
