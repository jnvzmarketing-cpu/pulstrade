// ════════════════════════════════════════════════════════════════════
// HOW-TO SHEET — "Wie setze ich das um?"
// 3 steps in plain language. Opened from the trade ticket.
// Usage: HowToSheet.show(context, isSell: true);
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../config/obsidian_theme.dart';
import '../l10n/gen/app_localizations.dart';

class HowToSheet {
  static void show(BuildContext context, {required bool isSell}) {
    final order = isSell ? 'Sell Limit' : 'Buy Limit';
    showModalBottomSheet(
      context: context,
      backgroundColor: Obsidian.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Obsidian.stroke,
                    borderRadius: BorderRadius.circular(2)))),
            SizedBox(height: 18),
            Text(AppLocalizations.of(context).howToTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: Obsidian.textHi)),
            SizedBox(height: 4),
            Text(AppLocalizations.of(context).howToSub,
                style: TextStyle(fontSize: 13, color: Obsidian.textMid)),
            SizedBox(height: 18),
            _step(1, AppLocalizations.of(context).howToS1Title(order),
                AppLocalizations.of(context).howToS1Body(order)),
            _step(2, AppLocalizations.of(context).howToS2Title,
                AppLocalizations.of(context).howToS2Body),
            _step(3, AppLocalizations.of(context).howToS3Title,
                AppLocalizations.of(context).howToS3Body),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Obsidian.goldBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Obsidian.gold),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Tipp: "Werte kopieren" \u2014 dann hast du alle Preise '
                  'im Zwischenspeicher und musst nichts abtippen.',
                  style: TextStyle(fontSize: 12, color: Obsidian.goldSoft),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _step(int n, String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 24, height: 24,
            decoration: BoxDecoration(
                color: Obsidian.goldBg, shape: BoxShape.circle),
            child: Center(child: Text('$n', style: TextStyle(
                fontSize: 12, color: Obsidian.gold,
                fontWeight: FontWeight.w600)))),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: Obsidian.textHi)),
              SizedBox(height: 2),
              Text(body, style: TextStyle(fontSize: 12.5,
                  color: Obsidian.textMid, height: 1.45)),
            ])),
      ]),
    );
  }
}
