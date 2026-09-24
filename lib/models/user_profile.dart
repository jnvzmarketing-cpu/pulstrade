// ════════════════════════════════════════════════════════════════════
// USER PROFILE v2 — built from the onboarding quiz.
// Drives: signal filtering, FCM topic subscriptions, and the per-user
// trade plan (lot sizes per entry, partial-close ladder).
// ════════════════════════════════════════════════════════════════════

// ignore_for_file: unused_field

import 'package:shared_preferences/shared_preferences.dart';
import 'signal.dart';

enum TradeMode { sniper, executor }

enum RiskAppetite { conservative, moderate, aggressive }

enum TradingSession { tokyo, london, newYork, all }

class UserProfile {
  final TradeMode mode;
  final RiskAppetite riskAppetite;
  final TradingSession session;
  final double accountBalance;
  final double riskPercent; // % of account risked per trade
  final List<int> tpWeights; // % closed at each TP, sums to 100
  final bool breakEvenAfterTp1; // default false — original SL stays
  final String? broker;
  final String? experience;
  final String? painPoint;

  const UserProfile({
    this.mode = TradeMode.sniper,
    this.riskAppetite = RiskAppetite.moderate,
    this.session = TradingSession.all,
    this.accountBalance = 10000,
    this.riskPercent = 1.5,
    this.tpWeights = const [40, 20, 20, 10, 10],
    this.breakEvenAfterTp1 = false,
    this.broker,
    this.experience,
    this.painPoint,
  });

  UserProfile copyWith({
    TradeMode? mode,
    RiskAppetite? riskAppetite,
    TradingSession? session,
    double? accountBalance,
    double? riskPercent,
    List<int>? tpWeights,
    bool? breakEvenAfterTp1,
    String? broker,
    String? experience,
    String? painPoint,
  }) =>
      UserProfile(
        mode: mode ?? this.mode,
        riskAppetite: riskAppetite ?? this.riskAppetite,
        session: session ?? this.session,
        accountBalance: accountBalance ?? this.accountBalance,
        riskPercent: riskPercent ?? this.riskPercent,
        tpWeights: tpWeights ?? this.tpWeights,
        breakEvenAfterTp1: breakEvenAfterTp1 ?? this.breakEvenAfterTp1,
        broker: broker ?? this.broker,
        experience: experience ?? this.experience,
        painPoint: painPoint ?? this.painPoint,
      );

  // ── Derived ─────────────────────────────────────────────────────────
  double get riskAmount => accountBalance * riskPercent / 100;

  int get minConfidence {
    switch (riskAppetite) {
      case RiskAppetite.conservative:
        return 80;
      case RiskAppetite.moderate:
        return 72;
      case RiskAppetite.aggressive:
        return 65;
    }
  }

  /// FCM topics this profile should be subscribed to.
  /// Backend publishes each signal to the matching topic set.
  List<String> get fcmTopics {
    final kind = mode == TradeMode.sniper ? 'limit' : 'market';
    final risk = riskAppetite.name.substring(0, 4); // cons / mode / aggr
    final sess = switch (session) {
      TradingSession.tokyo => 'tokyo',
      TradingSession.london => 'london',
      TradingSession.newYork => 'ny',
      TradingSession.all => 'all',
    };
    return ['sig_${kind}_$risk', 'session_$sess'];
  }

  // ── Persistence ─────────────────────────────────────────────────────
  static Future<UserProfile> load() async {
    final p = await SharedPreferences.getInstance();
    return UserProfile(
      mode: p.getString('up_mode') == 'executor' ? TradeMode.executor : TradeMode.sniper,
      riskAppetite: RiskAppetite.values.firstWhere(
        (r) => r.name == p.getString('up_risk_appetite'),
        orElse: () => RiskAppetite.moderate,
      ),
      session: TradingSession.values.firstWhere(
        (s) => s.name == p.getString('up_session'),
        orElse: () => TradingSession.all,
      ),
      accountBalance: p.getDouble('profile_balance') ?? 10000,
      riskPercent: p.getDouble('profile_risk_percent') ?? 1.5,
      tpWeights: (p.getStringList('up_tp_weights') ?? ['40', '20', '20', '10', '10'])
          .map(int.parse)
          .toList(),
      breakEvenAfterTp1: p.getBool('up_be_after_tp1') ?? false,
      broker: p.getString('up_broker'),
      experience: p.getString('up_experience'),
      painPoint: p.getString('up_pain_point'),
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('up_mode', mode.name);
    await p.setString('up_risk_appetite', riskAppetite.name);
    await p.setString('up_session', session.name);
    await p.setDouble('profile_balance', accountBalance);
    await p.setDouble('profile_risk_percent', riskPercent);
    await p.setStringList('up_tp_weights', tpWeights.map((w) => '$w').toList());
    await p.setBool('up_be_after_tp1', breakEvenAfterTp1);
    if (broker != null) await p.setString('up_broker', broker!);
    if (experience != null) await p.setString('up_experience', experience!);
    if (painPoint != null) await p.setString('up_pain_point', painPoint!);
  }
}

// ════════════════════════════════════════════════════════════════════
// TRADE PLAN — the personalization engine.
// Turns (Signal, UserProfile) into a concrete, executable plan:
// lot size per entry, $-risk, partial-close lots per TP, R:R per TP.
//
// XAU/USD math: 1.00 lot = 100 oz → $100 P/L per $1.00 (100 pips)
// price move, i.e. $1 per pip per 1.00 lot.
// ════════════════════════════════════════════════════════════════════

class TpPlanLine {
  final TakeProfit tp;
  final int weightPct; // % of position closed here
  final double closeLots; // lots closed at this TP
  final double profitIfHit; // $ realized at this TP (cumulative basis: per-line)
  final double rr; // reward:risk of this TP vs SL distance
  const TpPlanLine({
    required this.tp,
    required this.weightPct,
    required this.closeLots,
    required this.profitIfHit,
    required this.rr,
  });
}

class EntryPlanLine {
  final SignalEntry entry;
  final double lots;
  final double riskUsd; // $ lost if this entry fills and SL is hit
  const EntryPlanLine({required this.entry, required this.lots, required this.riskUsd});
}

class TradePlan {
  final List<EntryPlanLine> entries;
  final List<TpPlanLine> tps;
  final double totalLots;
  final double maxRiskUsd; // all entries filled, SL hit
  final double maxProfitUsd; // all entries filled, every TP hit
  final double avgEntry;

  const TradePlan({
    required this.entries,
    required this.tps,
    required this.totalLots,
    required this.maxRiskUsd,
    required this.maxProfitUsd,
    required this.avgEntry,
  });

  static const double _usdPerPipPerLot = 1.0; // XAU/USD: $1 per 0.01-pip? No: $1/pip/lot? see note
  // Note: for XAU/USD, 1.00 lot = 100 oz. A $1.00 move = $100 per lot.
  // We treat "pip" = $0.01? Gold convention in this app: prices like 4530.00,
  // pips counted as whole dollars in the Telegram channel (4530 → 4520 = "10 pips").
  // P/L per lot per point ($1.00 move) = $100.
  static const double _usdPerPointPerLot = 100.0;

  static TradePlan build(Signal signal, UserProfile profile) {
    if (signal.entries.isEmpty || signal.sl <= 0) {
      return const TradePlan(
          entries: [], tps: [], totalLots: 0, maxRiskUsd: 0, maxProfitUsd: 0, avgEntry: 0);
    }

    final n = signal.entries.length;
    final riskBudget = profile.riskAmount;
    final perEntryBudget = riskBudget / n;

    // Lots per entry so that (its own SL distance × lots × $100) = its budget.
    final entryLines = <EntryPlanLine>[];
    for (final e in signal.entries) {
      final slDist = (e.price - signal.sl).abs();
      if (slDist <= 0) continue;
      var lots = perEntryBudget / (slDist * _usdPerPointPerLot);
      lots = (lots * 100).floorToDouble() / 100; // round DOWN to 0.01 — never over-risk
      if (lots < 0.01) lots = 0.01;
      entryLines.add(EntryPlanLine(
        entry: e,
        lots: lots,
        riskUsd: double.parse((lots * slDist * _usdPerPointPerLot).toStringAsFixed(2)),
      ));
    }

    final totalLots = entryLines.fold<double>(0, (s, l) => s + l.lots);
    final maxRisk = entryLines.fold<double>(0, (s, l) => s + l.riskUsd);
    final avgEntry = entryLines.isEmpty
        ? 0.0
        : entryLines.fold<double>(0, (s, l) => s + l.entry.price * l.lots) / totalLots;

    // TP ladder: distribute weights across however many TPs the signal has.
    final tpCount = signal.tps.length;
    final weights = _normalizedWeights(profile.tpWeights, tpCount);

    final tpLines = <TpPlanLine>[];
    var maxProfit = 0.0;
    for (var i = 0; i < tpCount; i++) {
      final tp = signal.tps[i];
      final w = weights[i];
      var closeLots = totalLots * w / 100;
      closeLots = (closeLots * 100).roundToDouble() / 100;
      final dist = (tp.price - avgEntry).abs();
      final profit = closeLots * dist * _usdPerPointPerLot;
      final slDist = (avgEntry - signal.sl).abs();
      final rr = slDist > 0 ? dist / slDist : 0.0;
      maxProfit += profit;
      tpLines.add(TpPlanLine(
        tp: tp,
        weightPct: w,
        closeLots: closeLots,
        profitIfHit: double.parse(profit.toStringAsFixed(2)),
        rr: double.parse(rr.toStringAsFixed(2)),
      ));
    }

    return TradePlan(
      entries: entryLines,
      tps: tpLines,
      totalLots: double.parse(totalLots.toStringAsFixed(2)),
      maxRiskUsd: double.parse(maxRisk.toStringAsFixed(2)),
      maxProfitUsd: double.parse(maxProfit.toStringAsFixed(2)),
      avgEntry: double.parse(avgEntry.toStringAsFixed(2)),
    );
  }

  /// Adapt the 5-slot weight preset to signals with fewer TPs:
  /// fold leftover weight into the last available TP, keep sum = 100.
  static List<int> _normalizedWeights(List<int> preset, int tpCount) {
    if (tpCount <= 0) return [];
    final w = List<int>.filled(tpCount, 0);
    for (var i = 0; i < preset.length; i++) {
      final idx = i < tpCount ? i : tpCount - 1;
      w[idx] += preset[i];
    }
    final sum = w.fold<int>(0, (s, v) => s + v);
    if (sum != 100 && sum > 0) {
      w[tpCount - 1] += 100 - sum;
    }
    return w;
  }
}
