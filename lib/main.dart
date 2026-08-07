// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/signal_service.dart';
import 'services/subscription_service.dart';
import 'services/price_service.dart';
import 'services/auth_service.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen_v3.dart';
import 'screens/onboarding_quiz_screen.dart';
import 'screens/signal_detail_screen_v3.dart';
import 'services/profile_v2_service.dart';
import 'services/topic_service.dart';
import 'models/signal.dart';
import 'screens/today_screen_v3.dart';
import 'models/user_profile.dart';
import 'screens/signals_screen_v3.dart';
import 'screens/stats_screen_v3.dart';
import 'config/obsidian_theme.dart';
import 'l10n/gen/app_localizations.dart';

// ═══ DEMO-DATEN NUR FUER STORE-SCREENSHOTS — vor Release auf false! ═══
const kDemoShots = false;

List<Map<String, dynamic>> _demoMaps() {
  final now = DateTime.now().toUtc();
  String iso(int minAgo) =>
      now.subtract(Duration(minutes: minAgo)).toIso8601String();
  int ms(int minAgo) =>
      now.subtract(Duration(minutes: minAgo)).millisecondsSinceEpoch;
  return [
    {
      'id': 9001, 'ticker': 'XAU/USD', 'action': 'SELL',
      'price': 4338.0, 'sl': 4347.0, 'tp1': 4332.0, 'tp2': 4326.0,
      'timeframe': '15m', 'confidence': 86,
      'pattern': 'Limit Zone',
      'note': '18 touches | MTF confluence | 4 sources',
      'strategy': 'Zone', 'atr': 6.2, 'current_price': 4330.1,
      'mtf': '{"h1":true,"h4":true,"d1":false}',
      'timestamp': ms(95), 'created_at': ms(95),
      'kind': 'zone', 'status': 'filled', 'session': 'london',
      'entries': [
        {'price': 4338.0, 'kind': 'limit', 'status': 'filled',
         'filled_at': iso(34)},
        {'price': 4341.0, 'kind': 'limit', 'status': 'filled',
         'filled_at': iso(31)},
      ],
      'tps': [
        {'level': 1, 'price': 4332.0, 'status': 'hit', 'hit_at': iso(12)},
        {'level': 2, 'price': 4326.0, 'status': 'open', 'hit_at': null},
        {'level': 3, 'price': 4318.0, 'status': 'open', 'hit_at': null},
        {'level': 4, 'price': 4305.0, 'status': 'open', 'hit_at': null},
      ],
    },
    {
      'id': 9002, 'ticker': 'XAU/USD', 'action': 'BUY',
      'price': 4312.0, 'sl': 4303.0, 'tp1': 4318.0, 'tp2': 4324.0,
      'timeframe': '15m', 'confidence': 78,
      'pattern': 'Limit Zone',
      'note': '11 touches | round level | 3 sources',
      'strategy': 'Zone', 'atr': 6.2, 'current_price': 4330.1,
      'mtf': '{"h1":true,"h4":false,"d1":false}',
      'timestamp': ms(80), 'created_at': ms(80),
      'kind': 'zone', 'status': 'active', 'session': 'london',
      'entries': [
        {'price': 4312.0, 'kind': 'limit', 'status': 'pending',
         'filled_at': null},
        {'price': 4309.0, 'kind': 'limit', 'status': 'pending',
         'filled_at': null},
      ],
      'tps': [
        {'level': 1, 'price': 4318.0, 'status': 'open', 'hit_at': null},
        {'level': 2, 'price': 4324.0, 'status': 'open', 'hit_at': null},
        {'level': 3, 'price': 4332.0, 'status': 'open', 'hit_at': null},
      ],
    },
    {
      'id': 9003, 'ticker': 'XAU/USD', 'action': 'BUY',
      'price': 4296.0, 'sl': 4288.0, 'tp1': 4301.0, 'tp2': 4307.0,
      'timeframe': '15m', 'confidence': 83,
      'pattern': 'Limit Zone',
      'note': '22 touches | MTF confluence | 4 sources',
      'strategy': 'Zone', 'atr': 5.8, 'current_price': 4330.1,
      'mtf': '{"h1":true,"h4":true,"d1":true}',
      'timestamp': ms(60 * 26), 'created_at': ms(60 * 26),
      'kind': 'zone', 'status': 'closed', 'session': 'tokyo',
      'outcome': 'tp2_hit', 'exit_price': 4307.0,
      'closed_at': ms(60 * 22), 'pnl_r': 1.05,
      'entries': [
        {'price': 4296.0, 'kind': 'limit', 'status': 'filled',
         'filled_at': iso(60 * 25)},
        {'price': 4293.0, 'kind': 'limit', 'status': 'filled',
         'filled_at': iso(60 * 25)},
      ],
      'tps': [
        {'level': 1, 'price': 4301.0, 'status': 'hit',
         'hit_at': iso(60 * 24)},
        {'level': 2, 'price': 4307.0, 'status': 'hit',
         'hit_at': iso(60 * 22)},
        {'level': 3, 'price': 4316.0, 'status': 'open', 'hit_at': null},
      ],
    },
  ];
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Already initialized — safe to ignore
    debugPrint('Firebase already initialized in background isolate: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Obsidian.init();
  // Initialize Firebase — catch duplicate-app error (iOS auto-init via plist)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Already initialized — safe to ignore
    debugPrint('Firebase already initialized: $e');
  }

  // ── Push Notifications ────────────────────────────────────────────────────
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 2. Get APNs token (iOS only)
  await FirebaseMessaging.instance.getAPNSToken();
  // Topic subscriptions are profile-driven — synced via TopicService below.

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  timeago.setLocaleMessages('de', timeago.DeMessages());
  timeago.setDefaultLocale('de');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ── STATUS BAR HANDLING (fix Android status bar overlap from QA) ──────────
  // Make status bar transparent so app content shows beneath, but flutter's
  // SafeArea ensures content doesn't actually overlap the system UI.
  // Auto-adapts brightness based on theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // for dark theme
    statusBarBrightness: Brightness.dark,       // iOS
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Edge-to-edge mode: content extends behind system bars but SafeArea protects it
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(const PulstradeApp());
}

class PulstradeApp extends StatefulWidget {
  const PulstradeApp({super.key});
  @override
  State<PulstradeApp> createState() => _AppState();
}

class _AppState extends State<PulstradeApp> {
  final _sig = SignalService();
  final _sub = SubscriptionService();
  final _price = PriceService();
  final _profileV2 = ProfileV2Service();
  final _auth = AuthService();
  bool _showOnboarding = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _sub.init();
    _profileV2.init().then((_) => TopicService.sync(_profileV2.profile));
    _checkOnboarding();
    _sig.addListener(_onNewSignal);
    _sig.updateLivePrice(_price.price);
    _price.addListener(() => _sig.updateLivePrice(_price.price));

    // Foreground push — System banner shows automatically, no extra haptic
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // No haptic — OS handles notification UI
    });
  }

  Future<void> _checkOnboarding() async {
    final show = await OnboardingQuizScreen.shouldShow();
    setState(() {
      _showOnboarding = show;
      _ready = true;
    });
  }

  void _onQuizDone() => setState(() => _showOnboarding = false);

  int? _lastNotifiedSignalId;

  void _onNewSignal() async {
    // Only vibrate when there's actually a NEW signal (not just refresh)
    final signals = _sig.signals;
    if (signals.isEmpty) return;
    final newestId = signals.first.id;

    // First call after start — set baseline, don't vibrate
    if (_lastNotifiedSignalId == null) {
      _lastNotifiedSignalId = newestId;
      return;
    }

    // Same signal — skip vibration
    if (newestId == _lastNotifiedSignalId) return;

    // Genuinely new signal!
    _lastNotifiedSignalId = newestId;
    final p = await SharedPreferences.getInstance();
    if (p.getBool('vibration') ?? true) HapticFeedback.heavyImpact();
  }

  void _toggle() {} // Theme laeuft jetzt ueber Obsidian

  @override
  void dispose() {
    _sig.removeListener(_onNewSignal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _auth),
          ChangeNotifierProvider.value(value: _sig),
          ChangeNotifierProvider.value(value: _sub),
          ChangeNotifierProvider.value(value: _price),
          ChangeNotifierProvider.value(value: _profileV2),
        ],
        child: ValueListenableBuilder<int>(
          valueListenable: Obsidian.version,
          builder: (ctx, themeVersion, _) => KeyedSubtree(
            key: ValueKey('obsidian-themeVersion-$themeVersion'),
            child: MaterialApp(
            title: 'Pulstrade',
            theme: Obsidian.theme(),
            darkTheme: Obsidian.theme(),
            themeMode: Obsidian.isDark ? ThemeMode.dark : ThemeMode.light,
            locale: Obsidian.localeOverride,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            debugShowCheckedModeBanner: false,
            // Wrap whole app in MediaQuery + SafeArea to fix Android status bar overlap
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child ?? const SizedBox.shrink(),
            ),
            home: !_ready
                ? const Scaffold(
                    body: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFD700))))
                : _showOnboarding
                    ? OnboardingQuizScreen(onDone: _onQuizDone)
                    : _Shell(onToggle: _toggle),
          ),
          ),
        ),
      );
}

class _Shell extends StatefulWidget {
  final VoidCallback onToggle;
  const _Shell({required this.onToggle});
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _idx = 0;

  void _openSignal(BuildContext context, Signal s) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SignalDetailScreenV3(signal: s),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(index: _idx, children: [
        TodayScreenV3(
          fetchSignals: () async {
            if (kDemoShots) {
              try {
                return _demoMaps().map((m) => Signal.fromJson(m)).toList();
              } catch (e, st) {
                print('DEMO-FEHLER: $e');
                print(st.toString().split('\n').take(3).join('\n'));
                rethrow;
              }
            }
            final svc = context.read<SignalService>();
            await svc.fetchSignals();
            return svc.signals;
          },
          fetchPrice: () async {
            final p = context.read<PriceService>().price;
            return p > 0 ? p : null;
          },
          tpWeights: context.read<ProfileV2Service>().profile.tpWeights,
          accountSize: context.read<ProfileV2Service>().profile.accountBalance,
          riskPercent: context.read<ProfileV2Service>().profile.riskPercent,
          planFor: (signal) {
            try {
              final plan = TradePlan.build(
                  signal, context.read<ProfileV2Service>().profile);
              if (plan.totalLots <= 0) return null;
              return (lots: plan.totalLots,
                      riskUsd: plan.maxRiskUsd,
                      maxUsd: plan.maxProfitUsd);
            } catch (_) { return null; }
          },
          isPro: true,
        ),
        SignalsScreenV3(
          fetchSignals: () async {
            if (kDemoShots) {
              try {
                return _demoMaps().map((m) => Signal.fromJson(m)).toList();
              } catch (e, st) {
                print('DEMO-FEHLER: $e');
                print(st.toString().split('\n').take(3).join('\n'));
                rethrow;
              }
            }
            final svc = context.read<SignalService>();
            await svc.fetchSignals();
            return svc.signals;
          },
          fetchPrice: () async {
            final p = context.read<PriceService>().price;
            return p > 0 ? p : null;
          },
          tpWeights: context.read<ProfileV2Service>().profile.tpWeights,
          accountSize: context.read<ProfileV2Service>().profile.accountBalance,
          riskPercent: context.read<ProfileV2Service>().profile.riskPercent,
          planFor: (signal) {
            try {
              final plan = TradePlan.build(
                  signal, context.read<ProfileV2Service>().profile);
              if (plan.totalLots <= 0) return null;
              return (lots: plan.totalLots,
                      riskUsd: plan.maxRiskUsd,
                      maxUsd: plan.maxProfitUsd);
            } catch (_) { return null; }
          },
          isPro: true,
        ),
        StatsScreenV3(
          serverUrl: 'https://pulstrade-backend-production.up.railway.app',
        ),
        NewsScreen(),
        SettingsScreenV3(),
      ]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
          border: Border(
              top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFE5E5E5),
                  width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) {
            setState(() => _idx = i);
            HapticFeedback.selectionClick();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor:
              isDark ? const Color(0xFF666666) : const Color(0xFF999999),
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.today_outlined),
                activeIcon: Icon(Icons.today),
                label: AppLocalizations.of(context).navToday),
            BottomNavigationBarItem(
                icon: Icon(Icons.bolt_outlined),
                activeIcon: Icon(Icons.bolt),
                label: AppLocalizations.of(context).navSignals),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: AppLocalizations.of(context).navStats),
            BottomNavigationBarItem(
                icon: Icon(Icons.newspaper_outlined),
                activeIcon: Icon(Icons.newspaper),
                label: AppLocalizations.of(context).navNews),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: AppLocalizations.of(context).navSettings),
          ],
        ),
      ),
    );
  }
}
