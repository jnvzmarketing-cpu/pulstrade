// ════════════════════════════════════════════════════════════════════
// OBSIDIAN THEME v2 — PulsTrade Design System (Hell + Dunkel)
// Gleiche API wie v1 (Obsidian.bg, Obsidian.gold, ...), aber alle
// Farben sind jetzt Getter und schalten live zwischen zwei Paletten.
// Steuerung: Obsidian.setMode(...) — persistiert via SharedPreferences.
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ObsidianMode { system, light, dark }

class _P {
  final Color bg, card, cardAlt, stroke, strokeSub;
  final Color textHi, textMid, textLow;
  final Color gold, goldSoft, goldDeep, goldBg;
  final Color sell, sellBg, slLine;
  final Color buy, buyBg, buyInk, tpLine;
  final Color priceLine;
  const _P({
    required this.bg, required this.card, required this.cardAlt,
    required this.stroke, required this.strokeSub,
    required this.textHi, required this.textMid, required this.textLow,
    required this.gold, required this.goldSoft, required this.goldDeep,
    required this.goldBg,
    required this.sell, required this.sellBg, required this.slLine,
    required this.buy, required this.buyBg, required this.buyInk,
    required this.tpLine, required this.priceLine,
  });
}

const _dark = _P(
  bg: Color(0xFF0B0B0D), card: Color(0xFF121214), cardAlt: Color(0xFF16161A),
  stroke: Color(0xFF2A2A2E), strokeSub: Color(0xFF232327),
  textHi: Color(0xFFF4F4F0), textMid: Color(0xFF8A8A92),
  textLow: Color(0xFF6E6E76),
  gold: Color(0xFFEF9F27), goldSoft: Color(0xFFFAC775),
  goldDeep: Color(0xFFBA7517), goldBg: Color(0xFF1A1607),
  sell: Color(0xFFF09595), sellBg: Color(0xFF2B1212),
  slLine: Color(0xFFA32D2D),
  buy: Color(0xFF5DCAA5), buyBg: Color(0xFF0E1A14),
  buyInk: Color(0xFF04342C), tpLine: Color(0xFF1D9E75),
  priceLine: Color(0xFFD9D9DE),
);

// Tageslicht-Palette: warmes Papier, dunkle Tinte, satte Akzente.
const _light = _P(
  bg: Color(0xFFF5F4F1), card: Color(0xFFFFFFFF), cardAlt: Color(0xFFE9E6DF),
  stroke: Color(0xFFE0DED8), strokeSub: Color(0xFFE8E6E0),
  textHi: Color(0xFF17171A), textMid: Color(0xFF3E3E46),
  textLow: Color(0xFF6A6A72),
  gold: Color(0xFFB8771A), goldSoft: Color(0xFFD89A3C),
  goldDeep: Color(0xFF8F5A0F), goldBg: Color(0xFFF6ECD9),
  sell: Color(0xFFC03A3A), sellBg: Color(0xFFF9E7E7),
  slLine: Color(0xFFB02E2E),
  buy: Color(0xFF158562), buyBg: Color(0xFFE3F2EB),
  buyInk: Color(0xFFFFFFFF), tpLine: Color(0xFF128A66),
  priceLine: Color(0xFF2C2C30),
);

class Obsidian {
  Obsidian._();

  // ── Steuerung ─────────────────────────────────────────────────────
  static ObsidianMode mode = ObsidianMode.dark;
  /// Zaehlt bei jedem Wechsel hoch — main.dart hoert darauf und baut
  /// den kompletten Widget-Baum neu (KeyedSubtree-Trick).
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  /// 'system' | 'de' | 'en' — App-Sprache, persistiert.
  static String appLocaleCode = 'system';
  static Locale? get localeOverride => appLocaleCode == 'de'
      ? const Locale('de')
      : appLocaleCode == 'en' ? const Locale('en') : null;

  static bool get isDark {
    if (mode == ObsidianMode.dark) return true;
    if (mode == ObsidianMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static _P get _p => isDark ? _dark : _light;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final i = prefs.getInt('obsidian_mode') ?? ObsidianMode.dark.index;
    mode = ObsidianMode.values[i.clamp(0, 2)];
    appLocaleCode = prefs.getString('app_locale') ?? 'system';
    version.value++;
  }

  static Future<void> setMode(ObsidianMode m) async {
    mode = m;
    version.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('obsidian_mode', m.index);
  }

  static Future<void> setAppLocale(String code) async {
    appLocaleCode = code;
    version.value++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', code);
  }

  // ── Surfaces ──────────────────────────────────────────────────────
  static Color get bg        => _p.bg;
  static Color get card      => _p.card;
  static Color get cardAlt   => _p.cardAlt;
  static Color get stroke    => _p.stroke;
  static Color get strokeSub => _p.strokeSub;

  // ── Text ──────────────────────────────────────────────────────────
  static Color get textHi  => _p.textHi;
  static Color get textMid => _p.textMid;
  static Color get textLow => _p.textLow;

  // ── Gold ──────────────────────────────────────────────────────────
  static Color get gold     => _p.gold;
  static Color get goldSoft => _p.goldSoft;
  static Color get goldDeep => _p.goldDeep;
  static Color get goldBg   => _p.goldBg;

  // ── Sell / SL ─────────────────────────────────────────────────────
  static Color get sell   => _p.sell;
  static Color get sellBg => _p.sellBg;
  static Color get slLine => _p.slLine;

  // ── Buy / TP ──────────────────────────────────────────────────────
  static Color get buy    => _p.buy;
  static Color get buyBg  => _p.buyBg;
  static Color get buyInk => _p.buyInk;
  static Color get tpLine => _p.tpLine;

  // ── Chart ─────────────────────────────────────────────────────────
  static Color get priceLine => _p.priceLine;

  // ── Typografie ────────────────────────────────────────────────────
  static const monoFamily = 'Menlo';
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle get priceXL => TextStyle(
    fontFamily: monoFamily, fontSize: 34, fontWeight: FontWeight.w600,
    color: textHi, fontFeatures: _tabular, letterSpacing: -0.5,
  );
  static TextStyle get monoMd => TextStyle(
    fontFamily: monoFamily, fontSize: 13, color: textHi,
    fontFeatures: _tabular,
  );
  static TextStyle get monoSm => TextStyle(
    fontFamily: monoFamily, fontSize: 11, color: textMid,
    fontFeatures: _tabular,
  );
  static TextStyle get label => TextStyle(
    fontSize: 9, letterSpacing: 1.2, color: textLow,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get sectionTitle => TextStyle(
    fontSize: 12, letterSpacing: 2, color: textLow,
    fontWeight: FontWeight.w600,
  );
  static TextStyle get body =>
      TextStyle(fontSize: 13, color: textMid, height: 1.4);

  // ── Form ──────────────────────────────────────────────────────────
  static const rCard = 18.0;
  static const rTile = 9.0;
  static const rChip = 6.0;

  static BoxDecoration get cardBox => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(rCard),
    border: Border.all(color: stroke, width: 0.5),
  );
  static BoxDecoration tileBox({Color? color}) => BoxDecoration(
    color: color ?? cardAlt,
    borderRadius: BorderRadius.circular(rTile),
  );

  static ThemeData theme() => ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    cardColor: card,
    dividerColor: strokeSub,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: gold, onPrimary: bg,
      secondary: buy, onSecondary: bg,
      error: slLine, onError: Colors.white,
      surface: card, onSurface: textHi,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg, foregroundColor: textHi, elevation: 0),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: card,
      selectedItemColor: gold,
      unselectedItemColor: textLow,
    ),
    useMaterial3: false,
  );
}
