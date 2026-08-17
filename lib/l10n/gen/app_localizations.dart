import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @navToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get navToday;

  /// No description provided for @navSignals.
  ///
  /// In de, this message translates to:
  /// **'Signale'**
  String get navSignals;

  /// No description provided for @navStats.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get navStats;

  /// No description provided for @navNews.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get navNews;

  /// No description provided for @navSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In de, this message translates to:
  /// **'ERSCHEINUNGSBILD'**
  String get sectionAppearance;

  /// No description provided for @modeSystem.
  ///
  /// In de, this message translates to:
  /// **'Automatisch'**
  String get modeSystem;

  /// No description provided for @modeSystemSub.
  ///
  /// In de, this message translates to:
  /// **'Folgt deinem Gerät'**
  String get modeSystemSub;

  /// No description provided for @modeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get modeLight;

  /// No description provided for @modeLightSub.
  ///
  /// In de, this message translates to:
  /// **'Für Tageslicht · Papier statt Schwarz'**
  String get modeLightSub;

  /// No description provided for @modeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get modeDark;

  /// No description provided for @modeDarkSub.
  ///
  /// In de, this message translates to:
  /// **'Obsidian · für die Session bei Nacht'**
  String get modeDarkSub;

  /// No description provided for @sectionNotifications.
  ///
  /// In de, this message translates to:
  /// **'MITTEILUNGEN'**
  String get sectionNotifications;

  /// No description provided for @notifAll.
  ///
  /// In de, this message translates to:
  /// **'Alle Signale'**
  String get notifAll;

  /// No description provided for @notifAllSub.
  ///
  /// In de, this message translates to:
  /// **'Push, sobald eine neue Zone live geht'**
  String get notifAllSub;

  /// No description provided for @minConfidence.
  ///
  /// In de, this message translates to:
  /// **'Mindest-Vertrauen'**
  String get minConfidence;

  /// No description provided for @minConfidenceSub.
  ///
  /// In de, this message translates to:
  /// **'Zonen darunter werden ignoriert'**
  String get minConfidenceSub;

  /// No description provided for @sectionPlan.
  ///
  /// In de, this message translates to:
  /// **'DEIN PLAN'**
  String get sectionPlan;

  /// No description provided for @tradingProfile.
  ///
  /// In de, this message translates to:
  /// **'Trading-Profil'**
  String get tradingProfile;

  /// No description provided for @tradingProfileSub.
  ///
  /// In de, this message translates to:
  /// **'Kontogröße, Risiko, Ziel-Gewichte'**
  String get tradingProfileSub;

  /// No description provided for @autoTrading.
  ///
  /// In de, this message translates to:
  /// **'Auto-Trading'**
  String get autoTrading;

  /// No description provided for @autoTradingSub.
  ///
  /// In de, this message translates to:
  /// **'MT5 verbinden · Trades laufen automatisch'**
  String get autoTradingSub;

  /// No description provided for @sectionAdvanced.
  ///
  /// In de, this message translates to:
  /// **'ERWEITERT'**
  String get sectionAdvanced;

  /// No description provided for @beProtect.
  ///
  /// In de, this message translates to:
  /// **'Break-Even-Schutz'**
  String get beProtect;

  /// No description provided for @beProtectSub.
  ///
  /// In de, this message translates to:
  /// **'Nach Ziel 1 den Stop auf Einstand ziehen.\nStandard: AUS — unser Plan rechnet ohne.'**
  String get beProtectSub;

  /// No description provided for @footerVersion.
  ///
  /// In de, this message translates to:
  /// **'PulsTrade · XAU/USD · v1.1'**
  String get footerVersion;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Ergebnisse'**
  String get statsTitle;

  /// No description provided for @statsLiveBadge.
  ///
  /// In de, this message translates to:
  /// **'echte Daten · live'**
  String get statsLiveBadge;

  /// No description provided for @statsGatheringTitle.
  ///
  /// In de, this message translates to:
  /// **'Wir sammeln Ergebnisse'**
  String get statsGatheringTitle;

  /// No description provided for @statsGatheringSub.
  ///
  /// In de, this message translates to:
  /// **'Sobald die ersten Zonen abgeschlossen sind,\nsiehst du hier die ehrliche Bilanz — nichts geschönt.'**
  String get statsGatheringSub;

  /// No description provided for @winRateLabel.
  ///
  /// In de, this message translates to:
  /// **'Win-Rate'**
  String get winRateLabel;

  /// No description provided for @winOutOf10.
  ///
  /// In de, this message translates to:
  /// **'{n} von 10 Trades gewinnen'**
  String winOutOf10(int n);

  /// No description provided for @closedSince.
  ///
  /// In de, this message translates to:
  /// **'{n} abgeschlossene Trades seit Start\nnichts geschönt · Stop zählt voll'**
  String closedSince(int n);

  /// No description provided for @tileAvg.
  ///
  /// In de, this message translates to:
  /// **'Ø pro Trade'**
  String get tileAvg;

  /// No description provided for @tileBest.
  ///
  /// In de, this message translates to:
  /// **'Bester'**
  String get tileBest;

  /// No description provided for @tileWorst.
  ///
  /// In de, this message translates to:
  /// **'Schlechtester'**
  String get tileWorst;

  /// No description provided for @ladderHeader.
  ///
  /// In de, this message translates to:
  /// **'WIE WEIT KOMMEN UNSERE ZONEN?'**
  String get ladderHeader;

  /// No description provided for @ladderEmpty.
  ///
  /// In de, this message translates to:
  /// **'Die Ziel-Leiter füllt sich, sobald die ersten Sniper-Zonen durchgelaufen sind.'**
  String get ladderEmpty;

  /// No description provided for @ladderTarget.
  ///
  /// In de, this message translates to:
  /// **'Ziel {n}'**
  String ladderTarget(int n);

  /// No description provided for @ladderFootnote.
  ///
  /// In de, this message translates to:
  /// **'Darum sichern wir 40% schon am ersten Ziel.'**
  String get ladderFootnote;

  /// No description provided for @cardOrders.
  ///
  /// In de, this message translates to:
  /// **'Orders {a} + {b}'**
  String cardOrders(String a, String b);

  /// No description provided for @cardEntry.
  ///
  /// In de, this message translates to:
  /// **'Entry {p}'**
  String cardEntry(String p);

  /// No description provided for @cardStop.
  ///
  /// In de, this message translates to:
  /// **'Stop {p}'**
  String cardStop(String p);

  /// No description provided for @confidencePct.
  ///
  /// In de, this message translates to:
  /// **'{p}% sicher'**
  String confidencePct(int p);

  /// No description provided for @openChevron.
  ///
  /// In de, this message translates to:
  /// **'öffnen ›'**
  String get openChevron;

  /// No description provided for @collapseCard.
  ///
  /// In de, this message translates to:
  /// **'einklappen ▴'**
  String get collapseCard;

  /// No description provided for @statusFilledHit.
  ///
  /// In de, this message translates to:
  /// **'● Ziel {n} erreicht — du bist im Trade'**
  String statusFilledHit(int n);

  /// No description provided for @statusFilled.
  ///
  /// In de, this message translates to:
  /// **'● Order gefüllt — du bist im Trade'**
  String get statusFilled;

  /// No description provided for @statusClosedHits.
  ///
  /// In de, this message translates to:
  /// **'✓ {when} abgeschlossen · {hits} von {total} Zielen'**
  String statusClosedHits(String when, int hits, int total);

  /// No description provided for @statusClosedStop.
  ///
  /// In de, this message translates to:
  /// **'✓ {when} abgeschlossen · Stop erreicht'**
  String statusClosedStop(String when);

  /// No description provided for @statusCancelled.
  ///
  /// In de, this message translates to:
  /// **'○ abgelaufen — kein Verlust'**
  String get statusCancelled;

  /// No description provided for @statusWaitingDist.
  ///
  /// In de, this message translates to:
  /// **'○ wartet · Preis ist {d} Punkte entfernt'**
  String statusWaitingDist(String d);

  /// No description provided for @statusWaiting.
  ///
  /// In de, this message translates to:
  /// **'○ wartet auf den Preis'**
  String get statusWaiting;

  /// No description provided for @whenToday.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get whenToday;

  /// No description provided for @whenAtTime.
  ///
  /// In de, this message translates to:
  /// **'um {time} Uhr'**
  String whenAtTime(String time);

  /// No description provided for @whenYesterday.
  ///
  /// In de, this message translates to:
  /// **'gestern {time}'**
  String whenYesterday(String time);

  /// No description provided for @whenOnDate.
  ///
  /// In de, this message translates to:
  /// **'am {date} um {time}'**
  String whenOnDate(String date, String time);

  /// No description provided for @focusTrade.
  ///
  /// In de, this message translates to:
  /// **'DEIN FOKUS-TRADE'**
  String get focusTrade;

  /// No description provided for @focusInTrade.
  ///
  /// In de, this message translates to:
  /// **'du bist im Trade'**
  String get focusInTrade;

  /// No description provided for @focusHighestConf.
  ///
  /// In de, this message translates to:
  /// **'höchstes Vertrauen · {p}%'**
  String focusHighestConf(int p);

  /// No description provided for @oneZoneEnough.
  ///
  /// In de, this message translates to:
  /// **'Eine Zone reicht. Mehr Trades sind nicht mehr Gewinn.'**
  String get oneZoneEnough;

  /// No description provided for @moreChances.
  ///
  /// In de, this message translates to:
  /// **'WEITERE CHANCEN · OPTIONAL'**
  String get moreChances;

  /// No description provided for @moreZones.
  ///
  /// In de, this message translates to:
  /// **'WEITERE ZONEN · OPTIONAL · {n}'**
  String moreZones(int n);

  /// No description provided for @doneToday.
  ///
  /// In de, this message translates to:
  /// **'HEUTE ERLEDIGT · {n}'**
  String doneToday(int n);

  /// No description provided for @hiddenByFilter.
  ///
  /// In de, this message translates to:
  /// **'{n} Zone(n) unter deinem Vertrauens-Filter (ab {min}%) · Einstellungen'**
  String hiddenByFilter(int n, int min);

  /// No description provided for @allFilteredTitle.
  ///
  /// In de, this message translates to:
  /// **'Heute nichts über {min}%'**
  String allFilteredTitle(int min);

  /// No description provided for @allFilteredSub.
  ///
  /// In de, this message translates to:
  /// **'{n} Zone(n) liegen unter deinem Vertrauens-Filter.\nKein Trade ist auch eine Entscheidung — oder senke den Filter in den Einstellungen.'**
  String allFilteredSub(int n);

  /// No description provided for @segHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get segHistory;

  /// No description provided for @expiredInHistory.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufene Zonen findest du im Verlauf'**
  String get expiredInHistory;

  /// No description provided for @emptySniperTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine aktiven Zonen'**
  String get emptySniperTitle;

  /// No description provided for @emptySniperSub.
  ///
  /// In de, this message translates to:
  /// **'Die nächsten Zonen kommen vor der nächsten Session — siehe Countdown im Heute-Tab.'**
  String get emptySniperSub;

  /// No description provided for @emptyExecutorTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Markt-Signal aktiv'**
  String get emptyExecutorTitle;

  /// No description provided for @emptyExecutorSub.
  ///
  /// In de, this message translates to:
  /// **'Der Executor meldet sich, sobald eines unserer Setups auslöst. Push ist an.'**
  String get emptyExecutorSub;

  /// No description provided for @emptyHistoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Verlauf'**
  String get emptyHistoryTitle;

  /// No description provided for @emptyHistorySub.
  ///
  /// In de, this message translates to:
  /// **'Hier landen abgeschlossene und abgelaufene Signale — mit ehrlicher Bilanz.'**
  String get emptyHistorySub;

  /// No description provided for @historySniperZone.
  ///
  /// In de, this message translates to:
  /// **'Sniper-Zone'**
  String get historySniperZone;

  /// No description provided for @historyExpired.
  ///
  /// In de, this message translates to:
  /// **'○ abgelaufen — Preis kam nicht in die Zone, kein Verlust'**
  String get historyExpired;

  /// No description provided for @historyTargets.
  ///
  /// In de, this message translates to:
  /// **'✓ {hits} von {total} Zielen'**
  String historyTargets(int hits, int total);

  /// No description provided for @historyStop.
  ///
  /// In de, this message translates to:
  /// **'✗ Stop erreicht · −1.00R'**
  String get historyStop;

  /// No description provided for @agoM.
  ///
  /// In de, this message translates to:
  /// **'vor {n}m'**
  String agoM(int n);

  /// No description provided for @agoH.
  ///
  /// In de, this message translates to:
  /// **'vor {n}h'**
  String agoH(int n);

  /// No description provided for @agoD.
  ///
  /// In de, this message translates to:
  /// **'vor {n}d'**
  String agoD(int n);

  /// No description provided for @nextZonesIn.
  ///
  /// In de, this message translates to:
  /// **'Nächste Zonen in'**
  String get nextZonesIn;

  /// No description provided for @allZonesDone.
  ///
  /// In de, this message translates to:
  /// **'Alle Zonen durch — nächste in'**
  String get allZonesDone;

  /// No description provided for @preSessionAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Vor der {session}-Session analysieren wir\nden Markt und legen die Zonen für dich fest.'**
  String preSessionAnalysis(String session);

  /// No description provided for @pushOn.
  ///
  /// In de, this message translates to:
  /// **'Push ist an — wir wecken dich'**
  String get pushOn;

  /// No description provided for @yesterdaySummary.
  ///
  /// In de, this message translates to:
  /// **'Gestern: {n} Zonen · {result}'**
  String yesterdaySummary(int n, String result);

  /// No description provided for @inPlus.
  ///
  /// In de, this message translates to:
  /// **'im Plus'**
  String get inPlus;

  /// No description provided for @inMinus.
  ///
  /// In de, this message translates to:
  /// **'im Minus'**
  String get inMinus;

  /// No description provided for @cardYourOrdersSell.
  ///
  /// In de, this message translates to:
  /// **'DEINE {n} VERKAUFS-ORDERS (LIMIT)'**
  String cardYourOrdersSell(int n);

  /// No description provided for @cardYourOrdersBuy.
  ///
  /// In de, this message translates to:
  /// **'DEINE {n} KAUF-ORDERS (LIMIT)'**
  String cardYourOrdersBuy(int n);

  /// No description provided for @entrySection.
  ///
  /// In de, this message translates to:
  /// **'EINSTIEG'**
  String get entrySection;

  /// No description provided for @sessionMarketSignal.
  ///
  /// In de, this message translates to:
  /// **'{session} · Markt-Signal — direkt ausführbar'**
  String sessionMarketSignal(String session);

  /// No description provided for @sessionWaitSell.
  ///
  /// In de, this message translates to:
  /// **'{session} · Preis muss erst hochlaufen, dann verkaufen wir'**
  String sessionWaitSell(String session);

  /// No description provided for @sessionWaitBuy.
  ///
  /// In de, this message translates to:
  /// **'{session} · Preis muss erst runterkommen, dann kaufen wir'**
  String sessionWaitBuy(String session);

  /// No description provided for @orderFilledAt.
  ///
  /// In de, this message translates to:
  /// **'{order} gefüllt'**
  String orderFilledAt(String order);

  /// No description provided for @orderAtPrice.
  ///
  /// In de, this message translates to:
  /// **'{order} bei'**
  String orderAtPrice(String order);

  /// No description provided for @stopYourProtection.
  ///
  /// In de, this message translates to:
  /// **'Stop Loss · dein Schutz'**
  String get stopYourProtection;

  /// No description provided for @stopNeverMoves.
  ///
  /// In de, this message translates to:
  /// **'bleibt IMMER fest — wird nie verschoben'**
  String get stopNeverMoves;

  /// No description provided for @targetHitN.
  ///
  /// In de, this message translates to:
  /// **'Ziel {n} erreicht'**
  String targetHitN(int n);

  /// No description provided for @targetN.
  ///
  /// In de, this message translates to:
  /// **'Ziel {n}'**
  String targetN(int n);

  /// No description provided for @pctClosed.
  ///
  /// In de, this message translates to:
  /// **' · {w}% geschlossen'**
  String pctClosed(int w);

  /// No description provided for @pctThenClose.
  ///
  /// In de, this message translates to:
  /// **' · dann {w}% schließen'**
  String pctThenClose(int w);

  /// No description provided for @yourStake.
  ///
  /// In de, this message translates to:
  /// **'Dein Einsatz: {lots} Lots'**
  String yourStake(String lots);

  /// No description provided for @atAccountRisk.
  ///
  /// In de, this message translates to:
  /// **'bei \\\${acc} Konto · {r}% Risiko'**
  String atAccountRisk(String acc, String r);

  /// No description provided for @worstCase.
  ///
  /// In de, this message translates to:
  /// **'Schlimmster Fall: −\\\${x}'**
  String worstCase(String x);

  /// No description provided for @allTargetsUsd.
  ///
  /// In de, this message translates to:
  /// **'Alle Ziele: +\\\${x}'**
  String allTargetsUsd(String x);

  /// No description provided for @copiedMt5.
  ///
  /// In de, this message translates to:
  /// **'Werte kopiert — in MT5 einfügen'**
  String get copiedMt5;

  /// No description provided for @copyValues.
  ///
  /// In de, this message translates to:
  /// **'Werte kopieren'**
  String get copyValues;

  /// No description provided for @howApply.
  ///
  /// In de, this message translates to:
  /// **'Wie setze ich das um?'**
  String get howApply;

  /// No description provided for @unlockPro.
  ///
  /// In de, this message translates to:
  /// **'Mit Pro freischalten'**
  String get unlockPro;

  /// No description provided for @statusInTradeLive.
  ///
  /// In de, this message translates to:
  /// **'Du bist im Trade — Ziele werden live getrackt'**
  String get statusInTradeLive;

  /// No description provided for @statusClosedDone.
  ///
  /// In de, this message translates to:
  /// **'{hits} von {total} Zielen erreicht — abgeschlossen'**
  String statusClosedDone(int hits, int total);

  /// No description provided for @statusStopDone.
  ///
  /// In de, this message translates to:
  /// **'Stop erreicht — abgeschlossen'**
  String get statusStopDone;

  /// No description provided for @statusExpiredCard.
  ///
  /// In de, this message translates to:
  /// **'Preis kam nicht in die Zone — abgelaufen, kein Verlust'**
  String get statusExpiredCard;

  /// No description provided for @howToTitle.
  ///
  /// In de, this message translates to:
  /// **'So setzt du den Trade um'**
  String get howToTitle;

  /// No description provided for @howToSub.
  ///
  /// In de, this message translates to:
  /// **'Dauert 2 Minuten in MT5 oder MT4.'**
  String get howToSub;

  /// No description provided for @howToS1Title.
  ///
  /// In de, this message translates to:
  /// **'{order}-Orders setzen'**
  String howToS1Title(String order);

  /// No description provided for @howToS1Body.
  ///
  /// In de, this message translates to:
  /// **'Tippe in MT5 auf \"Neue Order\" → wähle \"{order}\". Setze 2 Orders — eine pro Entry-Preis aus der Karte. Teile deinen Einsatz: halbe Lots pro Order.'**
  String howToS1Body(String order);

  /// No description provided for @howToS2Title.
  ///
  /// In de, this message translates to:
  /// **'Stop Loss bei BEIDEN Orders eintragen'**
  String get howToS2Title;

  /// No description provided for @howToS2Body.
  ///
  /// In de, this message translates to:
  /// **'Trage den Stop-Preis aus der Karte in beide Orders ein. Wichtig: Der Stop bleibt fest. Niemals verschieben — auch wenn es weh tut. Das ist die Regel.'**
  String get howToS2Body;

  /// No description provided for @howToS3Title.
  ///
  /// In de, this message translates to:
  /// **'Bei jedem Ziel einen Teil schließen'**
  String get howToS3Title;

  /// No description provided for @howToS3Body.
  ///
  /// In de, this message translates to:
  /// **'Wir schicken dir eine Push, wenn ein Ziel erreicht ist. Dann schließt du den angegebenen Prozent-Anteil (z.B. 40% bei Ziel 1) — der Rest läuft weiter.'**
  String get howToS3Body;

  /// No description provided for @detailZoneCreated.
  ///
  /// In de, this message translates to:
  /// **'Zone erstellt'**
  String get detailZoneCreated;

  /// No description provided for @detailOrderFilled.
  ///
  /// In de, this message translates to:
  /// **'Order {n} gefüllt @ {p}'**
  String detailOrderFilled(int n, String p);

  /// No description provided for @detailInTradeStop.
  ///
  /// In de, this message translates to:
  /// **'du bist im Trade · Stop bleibt {p}'**
  String detailInTradeStop(String p);

  /// No description provided for @detailTargetHitAt.
  ///
  /// In de, this message translates to:
  /// **'Ziel {n} erreicht @ {p}'**
  String detailTargetHitAt(int n, String p);

  /// No description provided for @detailPctClosed.
  ///
  /// In de, this message translates to:
  /// **'{w}% geschlossen · Gewinn gesichert'**
  String detailPctClosed(int w);

  /// No description provided for @detailClosedTargets.
  ///
  /// In de, this message translates to:
  /// **'Abgeschlossen · {hits} von {total} Zielen'**
  String detailClosedTargets(int hits, int total);

  /// No description provided for @detailStopClosed.
  ///
  /// In de, this message translates to:
  /// **'Stop erreicht · abgeschlossen'**
  String get detailStopClosed;

  /// No description provided for @detailCleanPlan.
  ///
  /// In de, this message translates to:
  /// **'sauber nach Plan gehandelt'**
  String get detailCleanPlan;

  /// No description provided for @detailLimitedPlan.
  ///
  /// In de, this message translates to:
  /// **'−1R · genau wie geplant begrenzt'**
  String get detailLimitedPlan;

  /// No description provided for @detailExpiredTitle.
  ///
  /// In de, this message translates to:
  /// **'Abgelaufen — kein Verlust'**
  String get detailExpiredTitle;

  /// No description provided for @detailExpiredSub.
  ///
  /// In de, this message translates to:
  /// **'Preis kam nicht in die Zone · Disziplin > Aktion'**
  String get detailExpiredSub;

  /// No description provided for @detailZoneTitle.
  ///
  /// In de, this message translates to:
  /// **'{dir} Zone · {session}'**
  String detailZoneTitle(String dir, String session);

  /// No description provided for @whatHappened.
  ///
  /// In de, this message translates to:
  /// **'WAS BISHER PASSIERT IST'**
  String get whatHappened;

  /// No description provided for @openTargets.
  ///
  /// In de, this message translates to:
  /// **'OFFENE ZIELE'**
  String get openTargets;

  /// No description provided for @statOrders.
  ///
  /// In de, this message translates to:
  /// **'ORDERS'**
  String get statOrders;

  /// No description provided for @statStopFixed.
  ///
  /// In de, this message translates to:
  /// **'STOP · FEST'**
  String get statStopFixed;

  /// No description provided for @statTargets.
  ///
  /// In de, this message translates to:
  /// **'ZIELE'**
  String get statTargets;

  /// No description provided for @copiedShare.
  ///
  /// In de, this message translates to:
  /// **'Bilanz kopiert — teile sie wo du willst'**
  String get copiedShare;

  /// No description provided for @shareTargetsLine.
  ///
  /// In de, this message translates to:
  /// **'Ziele: {h}/{t} erreicht'**
  String shareTargetsLine(int h, int t);

  /// No description provided for @shareStopFixed.
  ///
  /// In de, this message translates to:
  /// **'Stop (fest): {p}'**
  String shareStopFixed(String p);

  /// No description provided for @shareTargetLine.
  ///
  /// In de, this message translates to:
  /// **'Ziel {n}: {p}'**
  String shareTargetLine(int n, String p);

  /// No description provided for @loginFillAll.
  ///
  /// In de, this message translates to:
  /// **'Bitte alle Felder ausfüllen'**
  String get loginFillAll;

  /// No description provided for @loginEnterName.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Namen ein'**
  String get loginEnterName;

  /// No description provided for @loginEmailFirst.
  ///
  /// In de, this message translates to:
  /// **'Gib zuerst deine E-Mail ein'**
  String get loginEmailFirst;

  /// No description provided for @loginResetSent.
  ///
  /// In de, this message translates to:
  /// **'✓ Reset-Mail verschickt'**
  String get loginResetSent;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In de, this message translates to:
  /// **'Voller Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get forgotPassword;

  /// No description provided for @legalNotice.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Fortfahren stimmst du unseren AGB & Datenschutzbestimmungen zu'**
  String get legalNotice;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'SPRACHE'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langSystemSub.
  ///
  /// In de, this message translates to:
  /// **'Folgt deinem Gerät'**
  String get langSystemSub;

  /// No description provided for @langGerman.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get langGerman;

  /// No description provided for @langEnglish.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @hookTitle.
  ///
  /// In de, this message translates to:
  /// **'Hör auf, Gold zu jagen.\nLass es zu dir kommen.'**
  String get hookTitle;

  /// No description provided for @hookSub.
  ///
  /// In de, this message translates to:
  /// **'Zonen-Signale mit kompletter Ziel-Leiter — passend zu deinem Konto, bevor der Preis überhaupt da ist.'**
  String get hookSub;

  /// No description provided for @statTracked.
  ///
  /// In de, this message translates to:
  /// **'Trades getrackt'**
  String get statTracked;

  /// No description provided for @statHistWin.
  ///
  /// In de, this message translates to:
  /// **'historische Win-Rate'**
  String get statHistWin;

  /// No description provided for @hookCta.
  ///
  /// In de, this message translates to:
  /// **'Mein Profil erstellen'**
  String get hookCta;

  /// No description provided for @hookDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauert etwa 60 Sekunden'**
  String get hookDuration;

  /// No description provided for @secAboutYou.
  ///
  /// In de, this message translates to:
  /// **'ÜBER DICH'**
  String get secAboutYou;

  /// No description provided for @qExperience.
  ///
  /// In de, this message translates to:
  /// **'Wie lange tradest du schon?'**
  String get qExperience;

  /// No description provided for @expNew.
  ///
  /// In de, this message translates to:
  /// **'Ganz neu'**
  String get expNew;

  /// No description provided for @exp1to3.
  ///
  /// In de, this message translates to:
  /// **'1–3 Jahre'**
  String get exp1to3;

  /// No description provided for @exp3plus.
  ///
  /// In de, this message translates to:
  /// **'3+ Jahre'**
  String get exp3plus;

  /// No description provided for @secOneDecision.
  ///
  /// In de, this message translates to:
  /// **'DIE EINE ENTSCHEIDUNG'**
  String get secOneDecision;

  /// No description provided for @qHowTrade.
  ///
  /// In de, this message translates to:
  /// **'Wie willst du traden?'**
  String get qHowTrade;

  /// No description provided for @decisionNote.
  ///
  /// In de, this message translates to:
  /// **'Das prägt deine Signale, deine Pushes — alles.'**
  String get decisionNote;

  /// No description provided for @sniperDesc.
  ///
  /// In de, this message translates to:
  /// **'Ich setze Limit-Orders an Schlüssel-Zonen, bevor der Preis ankommt. Kein Hetzen, kein FOMO.'**
  String get sniperDesc;

  /// No description provided for @executorDesc.
  ///
  /// In de, this message translates to:
  /// **'Sag mir, wann ich sofort einsteige — Live-Markt-Signale.'**
  String get executorDesc;

  /// No description provided for @recommended.
  ///
  /// In de, this message translates to:
  /// **'EMPFOHLEN'**
  String get recommended;

  /// No description provided for @modeZoneLabel.
  ///
  /// In de, this message translates to:
  /// **'Limit-Zonen-Signale'**
  String get modeZoneLabel;

  /// No description provided for @modeLiveLabel.
  ///
  /// In de, this message translates to:
  /// **'Live-Markt-Signale'**
  String get modeLiveLabel;

  /// No description provided for @secLeak.
  ///
  /// In de, this message translates to:
  /// **'DEIN GRÖSSTES LECK'**
  String get secLeak;

  /// No description provided for @qCost.
  ///
  /// In de, this message translates to:
  /// **'Was kostet dich am meisten Geld?'**
  String get qCost;

  /// No description provided for @leakFomo.
  ///
  /// In de, this message translates to:
  /// **'FOMO-Einstiege'**
  String get leakFomo;

  /// No description provided for @leakEarlyExit.
  ///
  /// In de, this message translates to:
  /// **'Zu früher Ausstieg'**
  String get leakEarlyExit;

  /// No description provided for @leakLots.
  ///
  /// In de, this message translates to:
  /// **'Falsche Lot-Größen'**
  String get leakLots;

  /// No description provided for @leakNoPlan.
  ///
  /// In de, this message translates to:
  /// **'Kein Plan nach dem Einstieg'**
  String get leakNoPlan;

  /// No description provided for @leakMissed.
  ///
  /// In de, this message translates to:
  /// **'Verpasste Einstiege'**
  String get leakMissed;

  /// No description provided for @secNumbers.
  ///
  /// In de, this message translates to:
  /// **'DEINE ZAHLEN'**
  String get secNumbers;

  /// No description provided for @accountSizeLabel.
  ///
  /// In de, this message translates to:
  /// **'Kontogröße'**
  String get accountSizeLabel;

  /// No description provided for @riskPerTrade.
  ///
  /// In de, this message translates to:
  /// **'Risiko pro Trade'**
  String get riskPerTrade;

  /// No description provided for @riskNever.
  ///
  /// In de, this message translates to:
  /// **'Du riskierst \\\${r} pro Trade — nie mehr.'**
  String riskNever(String r);

  /// No description provided for @numbersNote.
  ///
  /// In de, this message translates to:
  /// **'Jedes Signal kommt mit exakten Lot-Größen für diese Zahlen.'**
  String get numbersNote;

  /// No description provided for @secRiskProfile.
  ///
  /// In de, this message translates to:
  /// **'RISIKO-PROFIL'**
  String get secRiskProfile;

  /// No description provided for @qPicky.
  ///
  /// In de, this message translates to:
  /// **'Wie wählerisch sollen deine Signale sein?'**
  String get qPicky;

  /// No description provided for @conservative.
  ///
  /// In de, this message translates to:
  /// **'Konservativ'**
  String get conservative;

  /// No description provided for @balanced.
  ///
  /// In de, this message translates to:
  /// **'Ausgewogen'**
  String get balanced;

  /// No description provided for @aggressive.
  ///
  /// In de, this message translates to:
  /// **'Aggressiv'**
  String get aggressive;

  /// No description provided for @conservativeSub.
  ///
  /// In de, this message translates to:
  /// **'Nur die stärksten Setups (80%+ Vertrauen). Weniger, dafür sauberer.'**
  String get conservativeSub;

  /// No description provided for @balancedSub.
  ///
  /// In de, this message translates to:
  /// **'Starke Setups (72%+). Der Sweet Spot für die meisten.'**
  String get balancedSub;

  /// No description provided for @aggressiveSub.
  ///
  /// In de, this message translates to:
  /// **'Jedes qualifizierte Setup (65%+). Maximale Chancen.'**
  String get aggressiveSub;

  /// No description provided for @secTimes.
  ///
  /// In de, this message translates to:
  /// **'DEINE ZEITEN'**
  String get secTimes;

  /// No description provided for @qWhenCharts.
  ///
  /// In de, this message translates to:
  /// **'Wann sitzt du an den Charts?'**
  String get qWhenCharts;

  /// No description provided for @tokyoTime.
  ///
  /// In de, this message translates to:
  /// **'00:00–08:00 UTC · ruhig, technisch'**
  String get tokyoTime;

  /// No description provided for @londonTime.
  ///
  /// In de, this message translates to:
  /// **'07:00–16:00 UTC · höchstes Gold-Volumen'**
  String get londonTime;

  /// No description provided for @nyTime.
  ///
  /// In de, this message translates to:
  /// **'12:00–21:00 UTC · News-getrieben'**
  String get nyTime;

  /// No description provided for @allSessions.
  ///
  /// In de, this message translates to:
  /// **'Alle Sessions'**
  String get allSessions;

  /// No description provided for @allSessionsSub.
  ///
  /// In de, this message translates to:
  /// **'Schick mir alles, rund um die Uhr'**
  String get allSessionsSub;

  /// No description provided for @timesNote.
  ///
  /// In de, this message translates to:
  /// **'Keine 3-Uhr-Pushes für Sessions, die du nie tradest.'**
  String get timesNote;

  /// No description provided for @qBroker.
  ///
  /// In de, this message translates to:
  /// **'Welchen Broker nutzt du?'**
  String get qBroker;

  /// No description provided for @brokerNone.
  ///
  /// In de, this message translates to:
  /// **'Noch keinen'**
  String get brokerNone;

  /// No description provided for @brokerOther.
  ///
  /// In de, this message translates to:
  /// **'Anderer'**
  String get brokerOther;

  /// No description provided for @optionalTag.
  ///
  /// In de, this message translates to:
  /// **'OPTIONAL'**
  String get optionalTag;

  /// No description provided for @notifNever.
  ///
  /// In de, this message translates to:
  /// **'Verpasse nie deinen Einstieg'**
  String get notifNever;

  /// No description provided for @notifTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Zonen kommen an,\nbevor die Session öffnet'**
  String get notifTitle;

  /// No description provided for @notifBody.
  ///
  /// In de, this message translates to:
  /// **'Zone bereit → Order gefüllt → jedes Ziel erreicht. Du bekommst nur Pushes, die zu deinem Profil passen.'**
  String get notifBody;

  /// No description provided for @notifBodyLive.
  ///
  /// In de, this message translates to:
  /// **'Live-Einstiege plus jedes Ziel-Update — nur für Signale, die zu deinem Profil passen.'**
  String get notifBodyLive;

  /// No description provided for @notifNote.
  ///
  /// In de, this message translates to:
  /// **'Steuert, welche Signale dein Handy erreichen.'**
  String get notifNote;

  /// No description provided for @enableNotifs.
  ///
  /// In de, this message translates to:
  /// **'Mitteilungen aktivieren'**
  String get enableNotifs;

  /// No description provided for @maybeLater.
  ///
  /// In de, this message translates to:
  /// **'Vielleicht später'**
  String get maybeLater;

  /// No description provided for @calcBuilding.
  ///
  /// In de, this message translates to:
  /// **'Wir bauen dein Trading-Profil…'**
  String get calcBuilding;

  /// No description provided for @calcSessions.
  ///
  /// In de, this message translates to:
  /// **'Deine Sessions werden eingerichtet…'**
  String get calcSessions;

  /// No description provided for @calcLots.
  ///
  /// In de, this message translates to:
  /// **'Lot-Größen werden kalibriert…'**
  String get calcLots;

  /// No description provided for @calcFilter.
  ///
  /// In de, this message translates to:
  /// **'Dein Signal-Filter wird justiert…'**
  String get calcFilter;

  /// No description provided for @resultReady.
  ///
  /// In de, this message translates to:
  /// **'DEIN PROFIL STEHT'**
  String get resultReady;

  /// No description provided for @youAreSniper.
  ///
  /// In de, this message translates to:
  /// **'Du bist ein Sniper.'**
  String get youAreSniper;

  /// No description provided for @youAreExecutor.
  ///
  /// In de, this message translates to:
  /// **'Du bist ein Executor.'**
  String get youAreExecutor;

  /// No description provided for @resultZones.
  ///
  /// In de, this message translates to:
  /// **'Zonen kommen vor deiner Session — Orders gesetzt, kein Stress'**
  String get resultZones;

  /// No description provided for @resultInstant.
  ///
  /// In de, this message translates to:
  /// **'Sofort-Einstiege mit Gültigkeitsfenster'**
  String get resultInstant;

  /// No description provided for @resultLadder.
  ///
  /// In de, this message translates to:
  /// **'Ziel-Leiter {weights}'**
  String resultLadder(String weights);

  /// No description provided for @resultTp1.
  ///
  /// In de, this message translates to:
  /// **'{w}% schon am ersten Ziel sichern — fest verbucht'**
  String resultTp1(int w);

  /// No description provided for @resultMaxRisk.
  ///
  /// In de, this message translates to:
  /// **'Max. \\\${x} Risiko pro Trade'**
  String resultMaxRisk(String x);

  /// No description provided for @resultAccount.
  ///
  /// In de, this message translates to:
  /// **'Trades passend zu deinem Konto'**
  String get resultAccount;

  /// No description provided for @showMyPlan.
  ///
  /// In de, this message translates to:
  /// **'Zeig mir meinen Plan'**
  String get showMyPlan;

  /// No description provided for @paywallTitle.
  ///
  /// In de, this message translates to:
  /// **'Teste Pro 7 Tage kostenlos'**
  String get paywallTitle;

  /// No description provided for @paywallUnlockMode.
  ///
  /// In de, this message translates to:
  /// **'Schalte dein komplettes {mode}-Setup frei. Heute 0 \\\$.'**
  String paywallUnlockMode(String mode);

  /// No description provided for @tlToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get tlToday;

  /// No description provided for @tlDay5.
  ///
  /// In de, this message translates to:
  /// **'Tag 5'**
  String get tlDay5;

  /// No description provided for @tlDay7.
  ///
  /// In de, this message translates to:
  /// **'Tag 7'**
  String get tlDay7;

  /// No description provided for @tlTodaySub.
  ///
  /// In de, this message translates to:
  /// **'Voller Zugriff — sofort freigeschaltet'**
  String get tlTodaySub;

  /// No description provided for @tlDay5Sub.
  ///
  /// In de, this message translates to:
  /// **'Wir erinnern dich, bevor der Test endet'**
  String get tlDay5Sub;

  /// No description provided for @tlDay7Sub.
  ///
  /// In de, this message translates to:
  /// **'Abo startet — vorher jederzeit kündbar'**
  String get tlDay7Sub;

  /// No description provided for @yearly.
  ///
  /// In de, this message translates to:
  /// **'Jährlich'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In de, this message translates to:
  /// **'Monatlich'**
  String get monthly;

  /// No description provided for @bestDealCaps.
  ///
  /// In de, this message translates to:
  /// **'BESTER DEAL'**
  String get bestDealCaps;

  /// No description provided for @bestDeal.
  ///
  /// In de, this message translates to:
  /// **'Bester Deal'**
  String get bestDeal;

  /// No description provided for @perDay.
  ///
  /// In de, this message translates to:
  /// **'{x} / Tag'**
  String perDay(String x);

  /// No description provided for @perMonth.
  ///
  /// In de, this message translates to:
  /// **'pro Monat'**
  String get perMonth;

  /// No description provided for @featZoneLadder.
  ///
  /// In de, this message translates to:
  /// **'Limit-Zonen-Signale mit kompletter Ziel-Leiter'**
  String get featZoneLadder;

  /// No description provided for @featLiveLadder.
  ///
  /// In de, this message translates to:
  /// **'Live-Signale mit kompletter Ziel-Leiter'**
  String get featLiveLadder;

  /// No description provided for @featPushes.
  ///
  /// In de, this message translates to:
  /// **'Pushes bei Order-Füllung & jedem Ziel'**
  String get featPushes;

  /// No description provided for @featLots.
  ///
  /// In de, this message translates to:
  /// **'Lot-Größen für dein Konto berechnet'**
  String get featLots;

  /// No description provided for @featMt5.
  ///
  /// In de, this message translates to:
  /// **'Markt-News mit Gold-Relevanz & Wirtschaftskalender'**
  String get featMt5;

  /// No description provided for @trackRecord.
  ///
  /// In de, this message translates to:
  /// **'Bilanz: {wr}% Win-Rate über {n} getrackte Trades{rr}. Vergangene Ergebnisse garantieren keine zukünftigen.'**
  String trackRecord(String wr, int n, String rr);

  /// No description provided for @startTrial.
  ///
  /// In de, this message translates to:
  /// **'7 Tage kostenlos starten'**
  String get startTrial;

  /// No description provided for @zeroToday.
  ///
  /// In de, this message translates to:
  /// **'Heute 0 \\\$ · jederzeit in den Einstellungen kündbar'**
  String get zeroToday;

  /// No description provided for @trialTermsMonthly.
  ///
  /// In de, this message translates to:
  /// **'7 Tage kostenlos, danach {price}/Monat. Verlängert sich automatisch, bis du kündigst. Jederzeit in Google Play kündbar.'**
  String trialTermsMonthly(Object price);

  /// No description provided for @trialTermsYearly.
  ///
  /// In de, this message translates to:
  /// **'7 Tage kostenlos, danach {price}/Jahr. Verlängert sich automatisch, bis du kündigst. Jederzeit in Google Play kündbar.'**
  String trialTermsYearly(Object price);

  /// No description provided for @restorePurchase.
  ///
  /// In de, this message translates to:
  /// **'Kauf wiederherstellen'**
  String get restorePurchase;

  /// No description provided for @continueFree.
  ///
  /// In de, this message translates to:
  /// **'Mit Free-Plan weitermachen'**
  String get continueFree;

  /// No description provided for @plansLoading.
  ///
  /// In de, this message translates to:
  /// **'Pläne laden noch — versuch es gleich nochmal.'**
  String get plansLoading;

  /// No description provided for @reminderToggle.
  ///
  /// In de, this message translates to:
  /// **'Erinnere mich vor Ende des Tests'**
  String get reminderToggle;

  /// No description provided for @continueBtn.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueBtn;

  /// No description provided for @histWinRate.
  ///
  /// In de, this message translates to:
  /// **'historische Win-Rate'**
  String get histWinRate;

  /// No description provided for @newsTitle.
  ///
  /// In de, this message translates to:
  /// **'Markt-News'**
  String get newsTitle;

  /// No description provided for @liveBadge.
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get liveBadge;

  /// No description provided for @tabNews.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get tabNews;

  /// No description provided for @tabCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get tabCalendar;

  /// No description provided for @newsUpdated.
  ///
  /// In de, this message translates to:
  /// **'Aktualisiert {ago} · zum Aktualisieren ziehen'**
  String newsUpdated(String ago);

  /// No description provided for @justNow.
  ///
  /// In de, this message translates to:
  /// **'gerade eben'**
  String get justNow;

  /// No description provided for @minAgo.
  ///
  /// In de, this message translates to:
  /// **'vor {n} Min'**
  String minAgo(int n);

  /// No description provided for @hourAgo.
  ///
  /// In de, this message translates to:
  /// **'vor {n} Std'**
  String hourAgo(int n);

  /// No description provided for @pausedTip.
  ///
  /// In de, this message translates to:
  /// **'Signale pausieren 30 Min vor High-Impact-Terminen — zum Schutz deiner Trades.'**
  String get pausedTip;

  /// No description provided for @impactHighNews.
  ///
  /// In de, this message translates to:
  /// **'High Impact — kann Gold stark bewegen'**
  String get impactHighNews;

  /// No description provided for @impactMediumNews.
  ///
  /// In de, this message translates to:
  /// **'Medium Impact — Gold-Reaktion beobachten'**
  String get impactMediumNews;

  /// No description provided for @impactLowNews.
  ///
  /// In de, this message translates to:
  /// **'Low Impact — kaum Wirkung auf Gold'**
  String get impactLowNews;

  /// No description provided for @eventHighTip.
  ///
  /// In de, this message translates to:
  /// **'High Impact — Signale pausieren 30 Min vor diesem Termin. Volatilität bei Gold erwartet.'**
  String get eventHighTip;

  /// No description provided for @eventMediumTip.
  ///
  /// In de, this message translates to:
  /// **'Medium Impact — Gold-Reaktion beobachten. Ist vs. Prognose entscheidet.'**
  String get eventMediumTip;

  /// No description provided for @readFull.
  ///
  /// In de, this message translates to:
  /// **'Ganzen Artikel lesen'**
  String get readFull;

  /// No description provided for @tapMore.
  ///
  /// In de, this message translates to:
  /// **'Tippen für mehr'**
  String get tapMore;

  /// No description provided for @tapDetails.
  ///
  /// In de, this message translates to:
  /// **'Tippen für Details'**
  String get tapDetails;

  /// No description provided for @chipActual.
  ///
  /// In de, this message translates to:
  /// **'Ist'**
  String get chipActual;

  /// No description provided for @chipForecast.
  ///
  /// In de, this message translates to:
  /// **'Prognose'**
  String get chipForecast;

  /// No description provided for @chipPrevious.
  ///
  /// In de, this message translates to:
  /// **'Zuvor'**
  String get chipPrevious;

  /// No description provided for @pushOnlyTrading.
  ///
  /// In de, this message translates to:
  /// **'Pushes nur, wenn du wirklich tradest'**
  String get pushOnlyTrading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
