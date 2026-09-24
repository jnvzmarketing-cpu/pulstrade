// Pulstrade v2. Supabase für Auth und Daten, Firebase nur für Push, Cupertino.
// Ablauf: Bootstrap (sichtbar) -> Login -> Onboarding (einmalig) -> App.
import "package:firebase_core/firebase_core.dart";
import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:timeago/timeago.dart" as timeago;
import "core/pt_theme.dart";
import "firebase_options.dart";
import "screens/market_screen.dart";
import "screens/onboarding_screen.dart";
import "screens/signal_detail_screen.dart";
import "screens/signals_screen.dart";
import "screens/stats_screen.dart";
import "services/access_service.dart";
import "services/auth_repo.dart";
import "services/market_repo.dart";
import "services/push_repo.dart";

const supabaseUrl = "https://cofdlxftbmauvjlstrkl.supabase.co";
const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZmRseGZ0Ym1hdXZqbHN0cmtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxOTI0MTUsImV4cCI6MjEwNTc2ODQxNX0.Nh6xk8-wFuRQ-lwhoABh4w8oLb1FAjl_YImDZfeaCMA";

final navKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages("de", timeago.DeMessages());
  runApp(const _Bootstrap());
}

/// Zeichnet sofort, initialisiert dann. Fehler landen auf dem Screen statt im Nichts.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  String? _error;
  bool _ready = false;
  late final AuthRepo auth;
  late final AccessService access;
  late final MarketRepo repo;
  late final PushRepo push;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      auth = AuthRepo();
      access = AccessService();
      repo = MarketRepo();
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      push = PushRepo();
      try { await push.init(); } catch (e) { debugPrint("Push: $e"); }
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      debugPrint("Bootstrap: $e\n$st");
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return CupertinoApp(home: CupertinoPageScaffold(backgroundColor: PT.bg, child: Center(child: Padding(
        padding: const EdgeInsets.all(24), child: Text("Start fehlgeschlagen:\n$_error", style: PT.footnote.copyWith(color: PT.sell))))));
    }
    if (!_ready) {
      return const CupertinoApp(home: CupertinoPageScaffold(backgroundColor: PT.bg, child: Center(child: CupertinoActivityIndicator())));
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: access),
        ChangeNotifierProvider.value(value: repo),
        Provider.value(value: push),
      ],
      child: const PulstradeApp(),
    );
  }
}

class PulstradeApp extends StatelessWidget {
  const PulstradeApp({super.key});
  @override
  Widget build(BuildContext context) => CupertinoApp(
        title: "Pulstrade",
        navigatorKey: navKey,
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(brightness: Brightness.light, primaryColor: PT.ink, scaffoldBackgroundColor: PT.bg, barBackgroundColor: PT.bg),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.3)),
          child: child!,
        ),
        home: const _Root(),
      );
}

class _Root extends StatefulWidget {
  const _Root();
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool? _onboarded;
  String? _startedFor;
  bool _signingIn = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) { if (mounted) setState(() => _onboarded = p.getBool("onboarded_v2") ?? false); });
    context.read<PushRepo>().onOpenSignal = _openSignal;
  }

  void _openSignal(int id) {
    final s = context.read<MarketRepo>().signals.where((x) => x.id == id).firstOrNull;
    if (s != null) navKey.currentState?.push(CupertinoPageRoute(builder: (_) => SignalDetailScreen(signal: s)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepo>();
    if (!auth.signedIn) {
      if (!_signingIn) { _signingIn = true; auth.ensureSession().catchError((e) { debugPrint("anon: $e"); if (mounted) setState(() => _authError = e.toString()); }); }
      return CupertinoPageScaffold(backgroundColor: PT.bg, child: Center(child: _authError == null
          ? const CupertinoActivityIndicator()
          : Padding(padding: const EdgeInsets.all(24), child: Text("Verbindung fehlgeschlagen:\n$_authError", style: PT.footnote.copyWith(color: PT.sell)))));
    }
    // Nach Login einmalig: Daten laden (RLS braucht den Nutzer), RevenueCat anmelden
    if (_startedFor != auth.user!.id) {
      _startedFor = auth.user!.id;
      final repo = context.read<MarketRepo>();
      final access = context.read<AccessService>();
      Future.microtask(() async { await repo.start(); await access.init(); });
    }
    if (_onboarded == null) return const CupertinoPageScaffold(backgroundColor: PT.bg, child: SizedBox.shrink());
    if (_onboarded == false) {
      return OnboardingScreen(onDone: () async {
        (await SharedPreferences.getInstance()).setBool("onboarded_v2", true);
        if (mounted) setState(() => _onboarded = true);
      });
    }
    return const _Tabs();
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();
  @override
  Widget build(BuildContext context) => CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: PT.card,
          activeColor: PT.ink,
          inactiveColor: PT.textTertiary,
          border: const Border(top: BorderSide(color: PT.hairline, width: 1)),
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_bar_alt_fill), label: "Markt"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.bolt_fill), label: "Signale"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.chart_pie_fill), label: "Bilanz"),
          ],
        ),
        tabBuilder: (_, i) => CupertinoTabView(builder: (_) => switch (i) { 0 => const MarketScreen(), 1 => const SignalsScreen(), _ => const StatsScreen() }),
      );
}
