// Design-Tokens. Hell, ruhig, viel Luft. Farbe nur mit Bedeutung.
// Genau eine dunkle Insel pro Screen (Zugangs-Karte, Paywall, aktiver Tab).
import "dart:ui" show FontFeature;
import "package:flutter/cupertino.dart";

class PT {
  // Flächen
  static const bg = Color(0xFFF7F7F8);          // Seite
  static const sheet = Color(0xFFFFFFFF);       // Sheets
  static const card = Color(0xFFFFFFFF);        // Karten
  static const cardAlt = Color(0xFFF1F1F3);     // gedämpfte Karten, Chips
  static const hairline = Color(0xFFE6E6EA);
  static const ink = Color(0xFF0B0B0D);         // die dunkle Insel
  static const inkText = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF0B0B0D);
  static const textSecondary = Color(0xFF6B6B75);
  static const textTertiary = Color(0xFFA0A0A8);

  // Bedeutung
  static const gold = Color(0xFFC9962B);
  static const buy = Color(0xFF16A34A);
  static const sell = Color(0xFFDC2626);
  static const buySoft = Color(0xFFE8F7EE);
  static const sellSoft = Color(0xFFFCE9E9);

  static const shadow = [BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 6))];

  // Typografie
  static const _f = ".SF Pro Text";
  static const largeTitle = TextStyle(fontFamily: _f, fontSize: 34, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.6);
  static const title1 = TextStyle(fontFamily: _f, fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.4);
  static const headline = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.2);
  static const body = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w400, color: textPrimary);
  static const footnote = TextStyle(fontFamily: _f, fontSize: 13, color: textPrimary);
  static const caption = TextStyle(fontFamily: _f, fontSize: 13, fontWeight: FontWeight.w500, color: textTertiary);
  static const button = TextStyle(fontFamily: _f, fontSize: 17, fontWeight: FontWeight.w600, color: inkText);

  static const mono = TextStyle(fontFamily: _f, fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary, fontFeatures: [FontFeature.tabularFigures()]);
  static const price = TextStyle(fontFamily: ".SF Pro Display", fontSize: 44, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1.2, fontFeatures: [FontFeature.tabularFigures()]);

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;

  /// Standard-Karte: weiß, 20 px, hauchdünner Rand, weicher Schatten.
  static BoxDecoration cardDeco({Color? color, double radius = 20}) => BoxDecoration(
        color: color ?? card, borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hairline, width: 1), boxShadow: shadow);
}
