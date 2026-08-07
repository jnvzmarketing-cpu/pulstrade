// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navToday => 'Today';

  @override
  String get navSignals => 'Signals';

  @override
  String get navStats => 'Stats';

  @override
  String get navNews => 'News';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'APPEARANCE';

  @override
  String get modeSystem => 'Automatic';

  @override
  String get modeSystemSub => 'Follows your device';

  @override
  String get modeLight => 'Light';

  @override
  String get modeLightSub => 'For daylight · paper instead of black';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeDarkSub => 'Obsidian · built for the night session';

  @override
  String get sectionNotifications => 'NOTIFICATIONS';

  @override
  String get notifAll => 'All signals';

  @override
  String get notifAllSub => 'Push the moment a new zone goes live';

  @override
  String get minConfidence => 'Minimum confidence';

  @override
  String get minConfidenceSub => 'Zones below this are ignored';

  @override
  String get sectionPlan => 'YOUR PLAN';

  @override
  String get tradingProfile => 'Trading profile';

  @override
  String get tradingProfileSub => 'Account size, risk, target weights';

  @override
  String get autoTrading => 'Auto trading';

  @override
  String get autoTradingSub => 'Connect MT5 · trades execute automatically';

  @override
  String get sectionAdvanced => 'ADVANCED';

  @override
  String get beProtect => 'Break-even protection';

  @override
  String get beProtectSub =>
      'After target 1, move the stop to entry.\nDefault: OFF — our plan is built without it.';

  @override
  String get footerVersion => 'PulsTrade · XAU/USD · v1.1';

  @override
  String get statsTitle => 'Results';

  @override
  String get statsLiveBadge => 'real data · live';

  @override
  String get statsGatheringTitle => 'We\'re collecting results';

  @override
  String get statsGatheringSub =>
      'Once the first zones complete,\nyou\'ll see the honest record here — nothing polished.';

  @override
  String get winRateLabel => 'Win rate';

  @override
  String winOutOf10(int n) {
    return '$n out of 10 trades win';
  }

  @override
  String closedSince(int n) {
    return '$n closed trades since launch\nnothing polished · stops count in full';
  }

  @override
  String get tileAvg => 'Avg per trade';

  @override
  String get tileBest => 'Best';

  @override
  String get tileWorst => 'Worst';

  @override
  String get ladderHeader => 'HOW FAR DO OUR ZONES GO?';

  @override
  String get ladderEmpty =>
      'The target ladder fills up once the first sniper zones have run their course.';

  @override
  String ladderTarget(int n) {
    return 'Target $n';
  }

  @override
  String get ladderFootnote =>
      'That\'s why we bank 40% at the very first target.';

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
    return '$p% confidence';
  }

  @override
  String get openChevron => 'open ›';

  @override
  String get collapseCard => 'collapse ▴';

  @override
  String statusFilledHit(int n) {
    return '● Target $n hit — you\'re in the trade';
  }

  @override
  String get statusFilled => '● Order filled — you\'re in the trade';

  @override
  String statusClosedHits(String when, int hits, int total) {
    return '✓ closed $when · $hits of $total targets';
  }

  @override
  String statusClosedStop(String when) {
    return '✓ closed $when · stop hit';
  }

  @override
  String get statusCancelled => '○ expired — no loss taken';

  @override
  String statusWaitingDist(String d) {
    return '○ waiting · price is $d points away';
  }

  @override
  String get statusWaiting => '○ waiting for price';

  @override
  String get whenToday => 'today';

  @override
  String whenAtTime(String time) {
    return 'at $time';
  }

  @override
  String whenYesterday(String time) {
    return 'yesterday $time';
  }

  @override
  String whenOnDate(String date, String time) {
    return 'on $date at $time';
  }

  @override
  String get focusTrade => 'YOUR FOCUS TRADE';

  @override
  String get focusInTrade => 'you\'re in the trade';

  @override
  String focusHighestConf(int p) {
    return 'highest confidence · $p%';
  }

  @override
  String get oneZoneEnough =>
      'One zone is enough. More trades isn\'t more profit.';

  @override
  String get moreChances => 'MORE OPPORTUNITIES · OPTIONAL';

  @override
  String moreZones(int n) {
    return 'MORE ZONES · OPTIONAL · $n';
  }

  @override
  String doneToday(int n) {
    return 'DONE TODAY · $n';
  }

  @override
  String hiddenByFilter(int n, int min) {
    return '$n zone(s) below your confidence filter (min $min%) · Settings';
  }

  @override
  String allFilteredTitle(int min) {
    return 'Nothing above $min% today';
  }

  @override
  String allFilteredSub(int n) {
    return '$n zone(s) sit below your confidence filter.\nNo trade is a decision too — or lower the filter in Settings.';
  }

  @override
  String get segHistory => 'History';

  @override
  String get expiredInHistory => 'Expired zones live in History';

  @override
  String get emptySniperTitle => 'No active zones';

  @override
  String get emptySniperSub =>
      'The next zones drop before the next session — see the countdown on the Today tab.';

  @override
  String get emptyExecutorTitle => 'No market signal active';

  @override
  String get emptyExecutorSub =>
      'The Executor speaks up the moment one of our setups triggers. Push is on.';

  @override
  String get emptyHistoryTitle => 'No history yet';

  @override
  String get emptyHistorySub =>
      'Completed and expired signals land here — with an honest record.';

  @override
  String get historySniperZone => 'Sniper zone';

  @override
  String get historyExpired =>
      '○ expired — price never reached the zone, no loss';

  @override
  String historyTargets(int hits, int total) {
    return '✓ $hits of $total targets';
  }

  @override
  String get historyStop => '✗ stop hit · −1.00R';

  @override
  String agoM(int n) {
    return '${n}m ago';
  }

  @override
  String agoH(int n) {
    return '${n}h ago';
  }

  @override
  String agoD(int n) {
    return '${n}d ago';
  }

  @override
  String get nextZonesIn => 'Next zones in';

  @override
  String get allZonesDone => 'All zones done — next in';

  @override
  String preSessionAnalysis(String session) {
    return 'Before the $session session we analyze\nthe market and set your zones.';
  }

  @override
  String get pushOn => 'Push is on — we\'ll wake you';

  @override
  String yesterdaySummary(int n, String result) {
    return 'Yesterday: $n zones · $result';
  }

  @override
  String get inPlus => 'in profit';

  @override
  String get inMinus => 'in the red';

  @override
  String cardYourOrdersSell(int n) {
    return 'YOUR $n SELL ORDERS (LIMIT)';
  }

  @override
  String cardYourOrdersBuy(int n) {
    return 'YOUR $n BUY ORDERS (LIMIT)';
  }

  @override
  String get entrySection => 'ENTRY';

  @override
  String sessionMarketSignal(String session) {
    return '$session · market signal — execute right away';
  }

  @override
  String sessionWaitSell(String session) {
    return '$session · price needs to run up first, then we sell';
  }

  @override
  String sessionWaitBuy(String session) {
    return '$session · price needs to come down first, then we buy';
  }

  @override
  String orderFilledAt(String order) {
    return '$order filled';
  }

  @override
  String orderAtPrice(String order) {
    return '$order at';
  }

  @override
  String get stopYourProtection => 'Stop loss · your protection';

  @override
  String get stopNeverMoves => 'ALWAYS stays fixed — never moved';

  @override
  String targetHitN(int n) {
    return 'Target $n hit';
  }

  @override
  String targetN(int n) {
    return 'Target $n';
  }

  @override
  String pctClosed(int w) {
    return ' · $w% closed';
  }

  @override
  String pctThenClose(int w) {
    return ' · then close $w%';
  }

  @override
  String yourStake(String lots) {
    return 'Your size: $lots lots';
  }

  @override
  String atAccountRisk(String acc, String r) {
    return 'on a \\\$$acc account · $r% risk';
  }

  @override
  String worstCase(String x) {
    return 'Worst case: −\\\$$x';
  }

  @override
  String allTargetsUsd(String x) {
    return 'All targets: +\\\$$x';
  }

  @override
  String get copiedMt5 => 'Values copied — paste into MT5';

  @override
  String get copyValues => 'Copy values';

  @override
  String get howApply => 'How do I execute this?';

  @override
  String get unlockPro => 'Unlock with Pro';

  @override
  String get statusInTradeLive => 'You\'re in the trade — targets tracked live';

  @override
  String statusClosedDone(int hits, int total) {
    return '$hits of $total targets hit — closed';
  }

  @override
  String get statusStopDone => 'Stop hit — closed';

  @override
  String get statusExpiredCard =>
      'Price never reached the zone — expired, no loss';

  @override
  String get howToTitle => 'How to execute this trade';

  @override
  String get howToSub => 'Takes 2 minutes in MT5 or MT4.';

  @override
  String howToS1Title(String order) {
    return 'Set $order orders';
  }

  @override
  String howToS1Body(String order) {
    return 'In MT5 tap \"New Order\" → choose \"$order\". Place 2 orders — one per entry price from the card. Split your size: half lots per order.';
  }

  @override
  String get howToS2Title => 'Add the stop loss to BOTH orders';

  @override
  String get howToS2Body =>
      'Enter the stop price from the card into both orders. Important: the stop stays fixed. Never move it — even when it hurts. That\'s the rule.';

  @override
  String get howToS3Title => 'Close a portion at every target';

  @override
  String get howToS3Body =>
      'We push you when a target is hit. Then close the stated percentage (e.g. 40% at target 1) — the rest keeps running.';

  @override
  String get detailZoneCreated => 'Zone created';

  @override
  String detailOrderFilled(int n, String p) {
    return 'Order $n filled @ $p';
  }

  @override
  String detailInTradeStop(String p) {
    return 'you\'re in the trade · stop stays $p';
  }

  @override
  String detailTargetHitAt(int n, String p) {
    return 'Target $n hit @ $p';
  }

  @override
  String detailPctClosed(int w) {
    return '$w% closed · profit banked';
  }

  @override
  String detailClosedTargets(int hits, int total) {
    return 'Closed · $hits of $total targets';
  }

  @override
  String get detailStopClosed => 'Stop hit · closed';

  @override
  String get detailCleanPlan => 'executed cleanly to plan';

  @override
  String get detailLimitedPlan => '−1R · limited exactly as planned';

  @override
  String get detailExpiredTitle => 'Expired — no loss';

  @override
  String get detailExpiredSub =>
      'Price never reached the zone · discipline > action';

  @override
  String detailZoneTitle(String dir, String session) {
    return '$dir zone · $session';
  }

  @override
  String get whatHappened => 'WHAT HAPPENED SO FAR';

  @override
  String get openTargets => 'OPEN TARGETS';

  @override
  String get statOrders => 'ORDERS';

  @override
  String get statStopFixed => 'STOP · FIXED';

  @override
  String get statTargets => 'TARGETS';

  @override
  String get copiedShare => 'Recap copied — share it anywhere';

  @override
  String shareTargetsLine(int h, int t) {
    return 'Targets: $h/$t hit';
  }

  @override
  String shareStopFixed(String p) {
    return 'Stop (fixed): $p';
  }

  @override
  String shareTargetLine(int n, String p) {
    return 'Target $n: $p';
  }

  @override
  String get loginFillAll => 'Please fill in all fields';

  @override
  String get loginEnterName => 'Please enter your name';

  @override
  String get loginEmailFirst => 'Enter your email first';

  @override
  String get loginResetSent => '✓ Reset email sent';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get fullName => 'Full name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get legalNotice =>
      'By continuing you agree to our Terms & Privacy Policy';

  @override
  String get language => 'LANGUAGE';

  @override
  String get langSystem => 'System';

  @override
  String get langSystemSub => 'Follows your device';

  @override
  String get langGerman => 'Deutsch';

  @override
  String get langEnglish => 'English';

  @override
  String get hookTitle => 'Stop chasing gold.\nLet it come to you.';

  @override
  String get hookSub =>
      'Zone signals with a full target ladder — sized to your account, before price even gets there.';

  @override
  String get statTracked => 'trades tracked';

  @override
  String get statHistWin => 'historical win rate';

  @override
  String get hookCta => 'Build my profile';

  @override
  String get hookDuration => 'Takes about 60 seconds';

  @override
  String get secAboutYou => 'ABOUT YOU';

  @override
  String get qExperience => 'How long have you been trading?';

  @override
  String get expNew => 'Brand new';

  @override
  String get exp1to3 => '1–3 years';

  @override
  String get exp3plus => '3+ years';

  @override
  String get secOneDecision => 'THE ONE DECISION';

  @override
  String get qHowTrade => 'How do you want to trade?';

  @override
  String get decisionNote =>
      'This shapes your signals, your pushes — everything.';

  @override
  String get sniperDesc =>
      'I place limit orders at key zones before price arrives. No rushing, no FOMO.';

  @override
  String get executorDesc =>
      'Tell me when to enter right now — live market signals.';

  @override
  String get recommended => 'RECOMMENDED';

  @override
  String get modeZoneLabel => 'Limit zone signals';

  @override
  String get modeLiveLabel => 'Live market signals';

  @override
  String get secLeak => 'YOUR BIGGEST LEAK';

  @override
  String get qCost => 'What costs you the most money?';

  @override
  String get leakFomo => 'FOMO entries';

  @override
  String get leakEarlyExit => 'Exiting too early';

  @override
  String get leakLots => 'Wrong lot sizes';

  @override
  String get leakNoPlan => 'No plan after entry';

  @override
  String get leakMissed => 'Missed entries';

  @override
  String get secNumbers => 'YOUR NUMBERS';

  @override
  String get accountSizeLabel => 'Account size';

  @override
  String get riskPerTrade => 'Risk per trade';

  @override
  String riskNever(String r) {
    return 'You risk \\\$$r per trade — never more.';
  }

  @override
  String get numbersNote =>
      'Every signal comes with exact lot sizes for these numbers.';

  @override
  String get secRiskProfile => 'RISK PROFILE';

  @override
  String get qPicky => 'How picky should your signals be?';

  @override
  String get conservative => 'Conservative';

  @override
  String get balanced => 'Balanced';

  @override
  String get aggressive => 'Aggressive';

  @override
  String get conservativeSub =>
      'Only the strongest setups (80%+ confidence). Fewer, but cleaner.';

  @override
  String get balancedSub => 'Strong setups (72%+). The sweet spot for most.';

  @override
  String get aggressiveSub =>
      'Every qualified setup (65%+). Maximum opportunities.';

  @override
  String get secTimes => 'YOUR HOURS';

  @override
  String get qWhenCharts => 'When are you at the charts?';

  @override
  String get tokyoTime => '00:00–08:00 UTC · quiet, technical';

  @override
  String get londonTime => '07:00–16:00 UTC · highest gold volume';

  @override
  String get nyTime => '12:00–21:00 UTC · news-driven';

  @override
  String get allSessions => 'All sessions';

  @override
  String get allSessionsSub => 'Send me everything, around the clock';

  @override
  String get timesNote => 'No 3 a.m. pushes for sessions you never trade.';

  @override
  String get qBroker => 'Which broker do you use?';

  @override
  String get brokerNone => 'None yet';

  @override
  String get brokerOther => 'Other';

  @override
  String get optionalTag => 'OPTIONAL';

  @override
  String get notifNever => 'Never miss your entry';

  @override
  String get notifTitle => 'Your zones arrive\nbefore the session opens';

  @override
  String get notifBody =>
      'Zone ready → order filled → every target hit. You only get pushes that match your profile.';

  @override
  String get notifBodyLive =>
      'Live entries plus every target update — only for signals that match your profile.';

  @override
  String get notifNote => 'Controls which signals reach your phone.';

  @override
  String get enableNotifs => 'Enable notifications';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get calcBuilding => 'Building your trading profile…';

  @override
  String get calcSessions => 'Setting up your sessions…';

  @override
  String get calcLots => 'Calibrating lot sizes…';

  @override
  String get calcFilter => 'Tuning your signal filter…';

  @override
  String get resultReady => 'YOUR PROFILE IS SET';

  @override
  String get youAreSniper => 'You\'re a Sniper.';

  @override
  String get youAreExecutor => 'You\'re an Executor.';

  @override
  String get resultZones =>
      'Zones arrive before your session — orders set, no stress';

  @override
  String get resultInstant => 'Instant entries with a validity window';

  @override
  String resultLadder(String weights) {
    return 'Target ladder $weights';
  }

  @override
  String resultTp1(int w) {
    return 'Bank $w% at the very first target — locked in';
  }

  @override
  String resultMaxRisk(String x) {
    return 'Max \\\$$x risk per trade';
  }

  @override
  String get resultAccount => 'Trades sized to your account';

  @override
  String get showMyPlan => 'Show me my plan';

  @override
  String get paywallTitle => 'Try Pro free for 7 days';

  @override
  String paywallUnlockMode(String mode) {
    return 'Unlock your full $mode setup. \\\$0 today.';
  }

  @override
  String get tlToday => 'Today';

  @override
  String get tlDay5 => 'Day 5';

  @override
  String get tlDay7 => 'Day 7';

  @override
  String get tlTodaySub => 'Full access — unlocked instantly';

  @override
  String get tlDay5Sub => 'We remind you before the trial ends';

  @override
  String get tlDay7Sub => 'Subscription starts — cancel anytime before';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get bestDealCaps => 'BEST DEAL';

  @override
  String get bestDeal => 'Best deal';

  @override
  String perDay(String x) {
    return '$x / day';
  }

  @override
  String get perMonth => 'per month';

  @override
  String get featZoneLadder => 'Limit zone signals with a full target ladder';

  @override
  String get featLiveLadder => 'Live signals with a full target ladder';

  @override
  String get featPushes => 'Pushes on order fills & every target';

  @override
  String get featLots => 'Lot sizes calculated for your account';

  @override
  String get featMt5 => 'Market news with gold relevance & economic calendar';

  @override
  String trackRecord(String wr, int n, String rr) {
    return 'Track record: $wr% win rate across $n tracked trades$rr. Past results don\'t guarantee future ones.';
  }

  @override
  String get startTrial => 'Start 7 days free';

  @override
  String get zeroToday => '\\\$0 today · cancel anytime in Settings';

  @override
  String trialTermsMonthly(Object price) {
    return '7-day free trial, then $price/month. Auto-renews until canceled. Cancel anytime in Google Play.';
  }

  @override
  String trialTermsYearly(Object price) {
    return '7-day free trial, then $price/year. Auto-renews until canceled. Cancel anytime in Google Play.';
  }

  @override
  String get restorePurchase => 'Restore purchase';

  @override
  String get continueFree => 'Continue with the free plan';

  @override
  String get plansLoading => 'Plans are still loading — try again in a moment.';

  @override
  String get reminderToggle => 'Remind me before the trial ends';

  @override
  String get continueBtn => 'Continue';

  @override
  String get histWinRate => 'historical win rate';

  @override
  String get newsTitle => 'Market News';

  @override
  String get liveBadge => 'Live';

  @override
  String get tabNews => 'News';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String newsUpdated(String ago) {
    return 'Updated $ago · pull to refresh';
  }

  @override
  String get justNow => 'just now';

  @override
  String minAgo(int n) {
    return '${n}m ago';
  }

  @override
  String hourAgo(int n) {
    return '${n}h ago';
  }

  @override
  String get pausedTip =>
      'Signals pause 30 min before high-impact events — to protect your trades.';

  @override
  String get impactHighNews => 'High impact — can move gold hard';

  @override
  String get impactMediumNews => 'Medium impact — watch gold\'s reaction';

  @override
  String get impactLowNews => 'Low impact — little effect on gold';

  @override
  String get eventHighTip =>
      'High impact — signals pause 30 min before this event. Expect gold volatility.';

  @override
  String get eventMediumTip =>
      'Medium impact — watch gold\'s reaction. Actual vs. forecast decides.';

  @override
  String get readFull => 'Read full article';

  @override
  String get tapMore => 'Tap for more';

  @override
  String get tapDetails => 'Tap for details';

  @override
  String get chipActual => 'Actual';

  @override
  String get chipForecast => 'Forecast';

  @override
  String get chipPrevious => 'Previous';

  @override
  String get pushOnlyTrading => 'Pushes only when you actually trade';
}
