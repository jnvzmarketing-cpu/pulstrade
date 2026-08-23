// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navToday => 'Heute';

  @override
  String get navSignals => 'Signale';

  @override
  String get navStats => 'Statistik';

  @override
  String get navNews => 'News';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get sectionAppearance => 'ERSCHEINUNGSBILD';

  @override
  String get modeSystem => 'Automatisch';

  @override
  String get modeSystemSub => 'Folgt deinem Gerät';

  @override
  String get modeLight => 'Hell';

  @override
  String get modeLightSub => 'Für Tageslicht · Papier statt Schwarz';

  @override
  String get modeDark => 'Dunkel';

  @override
  String get modeDarkSub => 'Obsidian · für die Session bei Nacht';

  @override
  String get sectionNotifications => 'MITTEILUNGEN';

  @override
  String get notifAll => 'Alle Signale';

  @override
  String get notifAllSub => 'Push, sobald eine neue Zone live geht';

  @override
  String get minConfidence => 'Mindest-Vertrauen';

  @override
  String get minConfidenceSub => 'Zonen darunter werden ignoriert';

  @override
  String get sectionPlan => 'DEIN PLAN';

  @override
  String get tradingProfile => 'Trading-Profil';

  @override
  String get tradingProfileSub => 'Kontogröße, Risiko, Ziel-Gewichte';

  @override
  String get autoTrading => 'Auto-Trading';

  @override
  String get autoTradingSub => 'MT5 verbinden · Trades laufen automatisch';

  @override
  String get sectionAdvanced => 'ERWEITERT';

  @override
  String get beProtect => 'Break-Even-Schutz';

  @override
  String get beProtectSub =>
      'Nach Ziel 1 den Stop auf Einstand ziehen.\nStandard: AUS — unser Plan rechnet ohne.';

  @override
  String get footerVersion => 'PulsTrade · XAU/USD · v1.1';

  @override
  String get statsTitle => 'Ergebnisse';

  @override
  String get statsLiveBadge => 'echte Daten · live';

  @override
  String get statsGatheringTitle => 'Wir sammeln Ergebnisse';

  @override
  String get statsGatheringSub =>
      'Sobald die ersten Zonen abgeschlossen sind,\nsiehst du hier die ehrliche Bilanz — nichts geschönt.';

  @override
  String get winRateLabel => 'Win-Rate';

  @override
  String winOutOf10(int n) {
    return '$n von 10 Trades gewinnen';
  }

  @override
  String closedSince(int n) {
    return '$n abgeschlossene Trades seit Start\nnichts geschönt · Stop zählt voll';
  }

  @override
  String get tileAvg => 'Ø pro Trade';

  @override
  String get tileBest => 'Bester';

  @override
  String get tileWorst => 'Schlechtester';

  @override
  String get ladderHeader => 'WIE WEIT KOMMEN UNSERE ZONEN?';

  @override
  String get ladderEmpty =>
      'Die Ziel-Leiter füllt sich, sobald die ersten Sniper-Zonen durchgelaufen sind.';

  @override
  String ladderTarget(int n) {
    return 'Ziel $n';
  }

  @override
  String get ladderFootnote => 'Darum sichern wir 40% schon am ersten Ziel.';

  @override
  String cardOrders(String a, String b) {
    return 'Orders $a + $b';
  }

  @override
  String cardEntry(String p) {
    return 'Entry $p';
  }

  @override
  String cardStop(String p) {
    return 'Stop $p';
  }

  @override
  String confidencePct(int p) {
    return '$p% sicher';
  }

  @override
  String get openChevron => 'öffnen ›';

  @override
  String get collapseCard => 'einklappen ▴';

  @override
  String statusFilledHit(int n) {
    return '● Ziel $n erreicht — du bist im Trade';
  }

  @override
  String get statusFilled => '● Order gefüllt — du bist im Trade';

  @override
  String statusClosedHits(String when, int hits, int total) {
    return '✓ $when abgeschlossen · $hits von $total Zielen';
  }

  @override
  String statusClosedStop(String when) {
    return '✓ $when abgeschlossen · Stop erreicht';
  }

  @override
  String get statusCancelled => '○ abgelaufen — kein Verlust';

  @override
  String statusWaitingDist(String d) {
    return '○ wartet · Preis ist $d Punkte entfernt';
  }

  @override
  String get statusWaiting => '○ wartet auf den Preis';

  @override
  String get whenToday => 'heute';

  @override
  String whenAtTime(String time) {
    return 'um $time Uhr';
  }

  @override
  String whenYesterday(String time) {
    return 'gestern $time';
  }

  @override
  String whenOnDate(String date, String time) {
    return 'am $date um $time';
  }

  @override
  String get focusTrade => 'DEIN FOKUS-TRADE';

  @override
  String get focusInTrade => 'du bist im Trade';

  @override
  String focusHighestConf(int p) {
    return 'höchstes Vertrauen · $p%';
  }

  @override
  String get oneZoneEnough =>
      'Eine Zone reicht. Mehr Trades sind nicht mehr Gewinn.';

  @override
  String get moreChances => 'WEITERE CHANCEN · OPTIONAL';

  @override
  String moreZones(int n) {
    return 'WEITERE ZONEN · OPTIONAL · $n';
  }

  @override
  String doneToday(int n) {
    return 'HEUTE ERLEDIGT · $n';
  }

  @override
  String hiddenByFilter(int n, int min) {
    return '$n Zone(n) unter deinem Vertrauens-Filter (ab $min%) · Einstellungen';
  }

  @override
  String allFilteredTitle(int min) {
    return 'Heute nichts über $min%';
  }

  @override
  String allFilteredSub(int n) {
    return '$n Zone(n) liegen unter deinem Vertrauens-Filter.\nKein Trade ist auch eine Entscheidung — oder senke den Filter in den Einstellungen.';
  }

  @override
  String get segHistory => 'Verlauf';

  @override
  String get expiredInHistory => 'Abgelaufene Zonen findest du im Verlauf';

  @override
  String get emptySniperTitle => 'Keine aktiven Zonen';

  @override
  String get emptySniperSub =>
      'Die nächsten Zonen kommen vor der nächsten Session — siehe Countdown im Heute-Tab.';

  @override
  String get emptyExecutorTitle => 'Kein Markt-Signal aktiv';

  @override
  String get emptyExecutorSub =>
      'Der Executor meldet sich, sobald eines unserer Setups auslöst. Push ist an.';

  @override
  String get emptyHistoryTitle => 'Noch kein Verlauf';

  @override
  String get emptyHistorySub =>
      'Hier landen abgeschlossene und abgelaufene Signale — mit ehrlicher Bilanz.';

  @override
  String get historySniperZone => 'Sniper-Zone';

  @override
  String get historyExpired =>
      '○ abgelaufen — Preis kam nicht in die Zone, kein Verlust';

  @override
  String historyTargets(int hits, int total) {
    return '✓ $hits von $total Zielen';
  }

  @override
  String get historyStop => '✗ Stop erreicht · −1.00R';

  @override
  String agoM(int n) {
    return 'vor ${n}m';
  }

  @override
  String agoH(int n) {
    return 'vor ${n}h';
  }

  @override
  String agoD(int n) {
    return 'vor ${n}d';
  }

  @override
  String get nextZonesIn => 'Nächste Zonen in';

  @override
  String get allZonesDone => 'Alle Zonen durch — nächste in';

  @override
  String preSessionAnalysis(String session) {
    return 'Vor der $session-Session analysieren wir\nden Markt und legen die Zonen für dich fest.';
  }

  @override
  String get pushOn => 'Push ist an — wir wecken dich';

  @override
  String yesterdaySummary(int n, String result) {
    return 'Gestern: $n Zonen · $result';
  }

  @override
  String get inPlus => 'im Plus';

  @override
  String get inMinus => 'im Minus';

  @override
  String cardYourOrdersSell(int n) {
    return 'DEINE $n VERKAUFS-ORDERS (LIMIT)';
  }

  @override
  String cardYourOrdersBuy(int n) {
    return 'DEINE $n KAUF-ORDERS (LIMIT)';
  }

  @override
  String get entrySection => 'EINSTIEG';

  @override
  String sessionMarketSignal(String session) {
    return '$session · Markt-Signal — direkt ausführbar';
  }

  @override
  String sessionWaitSell(String session) {
    return '$session · Preis muss erst hochlaufen, dann verkaufen wir';
  }

  @override
  String sessionWaitBuy(String session) {
    return '$session · Preis muss erst runterkommen, dann kaufen wir';
  }

  @override
  String orderFilledAt(String order) {
    return '$order gefüllt';
  }

  @override
  String orderAtPrice(String order) {
    return '$order bei';
  }

  @override
  String get stopYourProtection => 'Stop Loss · dein Schutz';

  @override
  String get stopNeverMoves => 'bleibt IMMER fest — wird nie verschoben';

  @override
  String targetHitN(int n) {
    return 'Ziel $n erreicht';
  }

  @override
  String targetN(int n) {
    return 'Ziel $n';
  }

  @override
  String pctClosed(int w) {
    return ' · $w% geschlossen';
  }

  @override
  String pctThenClose(int w) {
    return ' · dann $w% schließen';
  }

  @override
  String yourStake(String lots) {
    return 'Dein Einsatz: $lots Lots';
  }

  @override
  String atAccountRisk(String acc, String r) {
    return 'bei \\\$$acc Konto · $r% Risiko';
  }

  @override
  String worstCase(String x) {
    return 'Schlimmster Fall: −\\\$$x';
  }

  @override
  String allTargetsUsd(String x) {
    return 'Alle Ziele: +\\\$$x';
  }

  @override
  String get copiedMt5 => 'Werte kopiert — in MT5 einfügen';

  @override
  String get copyValues => 'Werte kopieren';

  @override
  String get howApply => 'Wie setze ich das um?';

  @override
  String get unlockPro => 'Mit Pro freischalten';

  @override
  String get statusInTradeLive =>
      'Du bist im Trade — Ziele werden live getrackt';

  @override
  String statusClosedDone(int hits, int total) {
    return '$hits von $total Zielen erreicht — abgeschlossen';
  }

  @override
  String get statusStopDone => 'Stop erreicht — abgeschlossen';

  @override
  String get statusExpiredCard =>
      'Preis kam nicht in die Zone — abgelaufen, kein Verlust';

  @override
  String get howToTitle => 'So setzt du den Trade um';

  @override
  String get howToSub => 'Dauert 2 Minuten in MT5 oder MT4.';

  @override
  String howToS1Title(String order) {
    return '$order-Orders setzen';
  }

  @override
  String howToS1Body(String order) {
    return 'Tippe in MT5 auf \"Neue Order\" → wähle \"$order\". Setze 2 Orders — eine pro Entry-Preis aus der Karte. Teile deinen Einsatz: halbe Lots pro Order.';
  }

  @override
  String get howToS2Title => 'Stop Loss bei BEIDEN Orders eintragen';

  @override
  String get howToS2Body =>
      'Trage den Stop-Preis aus der Karte in beide Orders ein. Wichtig: Der Stop bleibt fest. Niemals verschieben — auch wenn es weh tut. Das ist die Regel.';

  @override
  String get howToS3Title => 'Bei jedem Ziel einen Teil schließen';

  @override
  String get howToS3Body =>
      'Wir schicken dir eine Push, wenn ein Ziel erreicht ist. Dann schließt du den angegebenen Prozent-Anteil (z.B. 40% bei Ziel 1) — der Rest läuft weiter.';

  @override
  String get detailZoneCreated => 'Zone erstellt';

  @override
  String detailOrderFilled(int n, String p) {
    return 'Order $n gefüllt @ $p';
  }

  @override
  String detailInTradeStop(String p) {
    return 'du bist im Trade · Stop bleibt $p';
  }

  @override
  String detailTargetHitAt(int n, String p) {
    return 'Ziel $n erreicht @ $p';
  }

  @override
  String detailPctClosed(int w) {
    return '$w% geschlossen · Gewinn gesichert';
  }

  @override
  String detailClosedTargets(int hits, int total) {
    return 'Abgeschlossen · $hits von $total Zielen';
  }

  @override
  String get detailStopClosed => 'Stop erreicht · abgeschlossen';

  @override
  String get detailCleanPlan => 'sauber nach Plan gehandelt';

  @override
  String get detailLimitedPlan => '−1R · genau wie geplant begrenzt';

  @override
  String get detailExpiredTitle => 'Abgelaufen — kein Verlust';

  @override
  String get detailExpiredSub =>
      'Preis kam nicht in die Zone · Disziplin > Aktion';

  @override
  String detailZoneTitle(String dir, String session) {
    return '$dir Zone · $session';
  }

  @override
  String get whatHappened => 'WAS BISHER PASSIERT IST';

  @override
  String get openTargets => 'OFFENE ZIELE';

  @override
  String get statOrders => 'ORDERS';

  @override
  String get statStopFixed => 'STOP · FEST';

  @override
  String get statTargets => 'ZIELE';

  @override
  String get copiedShare => 'Bilanz kopiert — teile sie wo du willst';

  @override
  String shareTargetsLine(int h, int t) {
    return 'Ziele: $h/$t erreicht';
  }

  @override
  String shareStopFixed(String p) {
    return 'Stop (fest): $p';
  }

  @override
  String shareTargetLine(int n, String p) {
    return 'Ziel $n: $p';
  }

  @override
  String get loginFillAll => 'Bitte alle Felder ausfüllen';

  @override
  String get loginEnterName => 'Bitte gib deinen Namen ein';

  @override
  String get loginEmailFirst => 'Gib zuerst deine E-Mail ein';

  @override
  String get loginResetSent => '✓ Reset-Mail verschickt';

  @override
  String get signIn => 'Anmelden';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get fullName => 'Voller Name';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get legalNotice =>
      'Mit dem Fortfahren stimmst du unseren AGB & Datenschutzbestimmungen zu';

  @override
  String get language => 'SPRACHE';

  @override
  String get langSystem => 'System';

  @override
  String get langSystemSub => 'Folgt deinem Gerät';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langEnglish => 'English';

  @override
  String get hookTitle => 'Hör auf, Gold zu jagen.\nLass es zu dir kommen.';

  @override
  String get hookSub =>
      'Zonen-Signale mit kompletter Ziel-Leiter — passend zu deinem Konto, bevor der Preis überhaupt da ist.';

  @override
  String get statTracked => 'Trades getrackt';

  @override
  String get statHistWin => 'historische Win-Rate';

  @override
  String get hookCta => 'Mein Profil erstellen';

  @override
  String get hookDuration => 'Dauert etwa 60 Sekunden';

  @override
  String get secAboutYou => 'ÜBER DICH';

  @override
  String get qExperience => 'Wie lange tradest du schon?';

  @override
  String get expNew => 'Ganz neu';

  @override
  String get exp1to3 => '1–3 Jahre';

  @override
  String get exp3plus => '3+ Jahre';

  @override
  String get secOneDecision => 'DIE EINE ENTSCHEIDUNG';

  @override
  String get qHowTrade => 'Wie willst du traden?';

  @override
  String get decisionNote => 'Das prägt deine Signale, deine Pushes — alles.';

  @override
  String get sniperDesc =>
      'Ich setze Limit-Orders an Schlüssel-Zonen, bevor der Preis ankommt. Kein Hetzen, kein FOMO.';

  @override
  String get executorDesc =>
      'Sag mir, wann ich sofort einsteige — Live-Markt-Signale.';

  @override
  String get recommended => 'EMPFOHLEN';

  @override
  String get modeZoneLabel => 'Limit-Zonen-Signale';

  @override
  String get modeLiveLabel => 'Live-Markt-Signale';

  @override
  String get secLeak => 'DEIN GRÖSSTES LECK';

  @override
  String get qCost => 'Was kostet dich am meisten Geld?';

  @override
  String get leakFomo => 'FOMO-Einstiege';

  @override
  String get leakEarlyExit => 'Zu früher Ausstieg';

  @override
  String get leakLots => 'Falsche Lot-Größen';

  @override
  String get leakNoPlan => 'Kein Plan nach dem Einstieg';

  @override
  String get leakMissed => 'Verpasste Einstiege';

  @override
  String get secNumbers => 'DEINE ZAHLEN';

  @override
  String get accountSizeLabel => 'Kontogröße';

  @override
  String get riskPerTrade => 'Risiko pro Trade';

  @override
  String riskNever(String r) {
    return 'Du riskierst \\\$$r pro Trade — nie mehr.';
  }

  @override
  String get numbersNote =>
      'Jedes Signal kommt mit exakten Lot-Größen für diese Zahlen.';

  @override
  String get secRiskProfile => 'RISIKO-PROFIL';

  @override
  String get qPicky => 'Wie wählerisch sollen deine Signale sein?';

  @override
  String get conservative => 'Konservativ';

  @override
  String get balanced => 'Ausgewogen';

  @override
  String get aggressive => 'Aggressiv';

  @override
  String get conservativeSub =>
      'Nur die stärksten Setups (80%+ Vertrauen). Weniger, dafür sauberer.';

  @override
  String get balancedSub =>
      'Starke Setups (72%+). Der Sweet Spot für die meisten.';

  @override
  String get aggressiveSub =>
      'Jedes qualifizierte Setup (65%+). Maximale Chancen.';

  @override
  String get secTimes => 'DEINE ZEITEN';

  @override
  String get qWhenCharts => 'Wann sitzt du an den Charts?';

  @override
  String get tokyoTime => '00:00–08:00 UTC · ruhig, technisch';

  @override
  String get londonTime => '07:00–16:00 UTC · höchstes Gold-Volumen';

  @override
  String get nyTime => '12:00–21:00 UTC · News-getrieben';

  @override
  String get allSessions => 'Alle Sessions';

  @override
  String get allSessionsSub => 'Schick mir alles, rund um die Uhr';

  @override
  String get timesNote =>
      'Keine 3-Uhr-Pushes für Sessions, die du nie tradest.';

  @override
  String get qBroker => 'Welchen Broker nutzt du?';

  @override
  String get brokerNone => 'Noch keinen';

  @override
  String get brokerOther => 'Anderer';

  @override
  String get optionalTag => 'OPTIONAL';

  @override
  String get notifNever => 'Verpasse nie deinen Einstieg';

  @override
  String get notifTitle => 'Deine Zonen kommen an,\nbevor die Session öffnet';

  @override
  String get notifBody =>
      'Zone bereit → Order gefüllt → jedes Ziel erreicht. Du bekommst nur Pushes, die zu deinem Profil passen.';

  @override
  String get notifBodyLive =>
      'Live-Einstiege plus jedes Ziel-Update — nur für Signale, die zu deinem Profil passen.';

  @override
  String get notifNote => 'Steuert, welche Signale dein Handy erreichen.';

  @override
  String get enableNotifs => 'Mitteilungen aktivieren';

  @override
  String get maybeLater => 'Vielleicht später';

  @override
  String get calcBuilding => 'Wir bauen dein Trading-Profil…';

  @override
  String get calcSessions => 'Deine Sessions werden eingerichtet…';

  @override
  String get calcLots => 'Lot-Größen werden kalibriert…';

  @override
  String get calcFilter => 'Dein Signal-Filter wird justiert…';

  @override
  String get resultReady => 'DEIN PROFIL STEHT';

  @override
  String get youAreSniper => 'Du bist ein Sniper.';

  @override
  String get youAreExecutor => 'Du bist ein Executor.';

  @override
  String get resultZones =>
      'Zonen kommen vor deiner Session — Orders gesetzt, kein Stress';

  @override
  String get resultInstant => 'Sofort-Einstiege mit Gültigkeitsfenster';

  @override
  String resultLadder(String weights) {
    return 'Ziel-Leiter $weights';
  }

  @override
  String resultTp1(int w) {
    return '$w% schon am ersten Ziel sichern — fest verbucht';
  }

  @override
  String resultMaxRisk(String x) {
    return 'Max. \\\$$x Risiko pro Trade';
  }

  @override
  String get resultAccount => 'Trades passend zu deinem Konto';

  @override
  String get showMyPlan => 'Zeig mir meinen Plan';

  @override
  String get paywallTitle => 'Teste Pro 7 Tage kostenlos';

  @override
  String paywallUnlockMode(String mode) {
    return 'Schalte dein komplettes $mode-Setup frei. Heute 0 \\\$.';
  }

  @override
  String get tlToday => 'Heute';

  @override
  String get tlDay5 => 'Tag 5';

  @override
  String get tlDay7 => 'Tag 7';

  @override
  String get tlTodaySub => 'Voller Zugriff — sofort freigeschaltet';

  @override
  String get tlDay5Sub => 'Wir erinnern dich, bevor der Test endet';

  @override
  String get tlDay7Sub => 'Abo startet — vorher jederzeit kündbar';

  @override
  String get yearly => 'Jährlich';

  @override
  String get monthly => 'Monatlich';

  @override
  String get bestDealCaps => 'BESTER DEAL';

  @override
  String get bestDeal => 'Bester Deal';

  @override
  String perDay(String x) {
    return '$x / Tag';
  }

  @override
  String get perMonth => 'pro Monat';

  @override
  String get featZoneLadder => 'Limit-Zonen-Signale mit kompletter Ziel-Leiter';

  @override
  String get featLiveLadder => 'Live-Signale mit kompletter Ziel-Leiter';

  @override
  String get featPushes => 'Pushes bei Order-Füllung & jedem Ziel';

  @override
  String get featLots => 'Lot-Größen für dein Konto berechnet';

  @override
  String get featMt5 => 'Markt-News mit Gold-Relevanz & Wirtschaftskalender';

  @override
  String trackRecord(String wr, int n, String rr) {
    return 'Bilanz: $wr% Win-Rate über $n getrackte Trades$rr. Vergangene Ergebnisse garantieren keine zukünftigen.';
  }

  @override
  String startTrialMonthly(Object price) {
    return 'Abo starten für $price/Monat';
  }

  @override
  String startTrialYearly(Object price) {
    return 'Abo starten für $price/Jahr';
  }

  @override
  String get zeroToday =>
      'Heute 0 \\\$ · jederzeit in den Einstellungen kündbar';

  @override
  String trialTermsMonthly(Object price) {
    return '7 Tage kostenlos, danach $price/Monat. Verlängert sich automatisch, bis du kündigst. Jederzeit in Google Play kündbar.';
  }

  @override
  String trialTermsYearly(Object price) {
    return '7 Tage kostenlos, danach $price/Jahr. Verlängert sich automatisch, bis du kündigst. Jederzeit in Google Play kündbar.';
  }

  @override
  String get restorePurchase => 'Kauf wiederherstellen';

  @override
  String get continueFree => 'Mit Free-Plan weitermachen';

  @override
  String get plansLoading => 'Pläne laden noch — versuch es gleich nochmal.';

  @override
  String get reminderToggle => 'Erinnere mich vor Ende des Tests';

  @override
  String get continueBtn => 'Weiter';

  @override
  String get histWinRate => 'historische Win-Rate';

  @override
  String get newsTitle => 'Markt-News';

  @override
  String get liveBadge => 'Live';

  @override
  String get tabNews => 'News';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String newsUpdated(String ago) {
    return 'Aktualisiert $ago · zum Aktualisieren ziehen';
  }

  @override
  String get justNow => 'gerade eben';

  @override
  String minAgo(int n) {
    return 'vor $n Min';
  }

  @override
  String hourAgo(int n) {
    return 'vor $n Std';
  }

  @override
  String get pausedTip =>
      'Signale pausieren 30 Min vor High-Impact-Terminen — zum Schutz deiner Trades.';

  @override
  String get impactHighNews => 'High Impact — kann Gold stark bewegen';

  @override
  String get impactMediumNews => 'Medium Impact — Gold-Reaktion beobachten';

  @override
  String get impactLowNews => 'Low Impact — kaum Wirkung auf Gold';

  @override
  String get eventHighTip =>
      'High Impact — Signale pausieren 30 Min vor diesem Termin. Volatilität bei Gold erwartet.';

  @override
  String get eventMediumTip =>
      'Medium Impact — Gold-Reaktion beobachten. Ist vs. Prognose entscheidet.';

  @override
  String get readFull => 'Ganzen Artikel lesen';

  @override
  String get tapMore => 'Tippen für mehr';

  @override
  String get tapDetails => 'Tippen für Details';

  @override
  String get chipActual => 'Ist';

  @override
  String get chipForecast => 'Prognose';

  @override
  String get chipPrevious => 'Zuvor';

  @override
  String get pushOnlyTrading => 'Pushes nur, wenn du wirklich tradest';
}
