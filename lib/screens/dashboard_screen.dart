import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../services/signal_service.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _State();
}

class _State extends State<DashboardScreen> {
  static const _serverUrl =
      'https://pulstrade-backend-production.up.railway.app';

  bool _loading = true;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _closedHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _loading = true);
    try {
      // Fetch real stats
      final statsRes = await http
          .get(Uri.parse('$_serverUrl/stats'))
          .timeout(const Duration(seconds: 10));
      if (statsRes.statusCode == 200) {
        _stats = Map<String, dynamic>.from(json.decode(statsRes.body));
      }
      // Fetch recent closed signals
      final histRes = await http
          .get(Uri.parse('$_serverUrl/signals?limit=50'))
          .timeout(const Duration(seconds: 10));
      if (histRes.statusCode == 200) {
        final all = List<Map<String, dynamic>>.from(json.decode(histRes.body));
        _closedHistory = all
            .where((s) => s['outcome'] != null && s['outcome'] != 'open')
            .take(10)
            .toList();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _winRateColor(double? rate) {
    if (rate == null) return AppColors.gold;
    if (rate >= 65) return AppColors.green;
    if (rate >= 50) return AppColors.gold;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final stat = isDark ? AppColors.darkCard2 : AppColors.lightCard2;

    //final svc = context.watch<SignalService>();

    final closed = _stats?['closedSignals'] as int? ?? 0;
    final open = _stats?['openSignals'] as int? ?? 0;
    final totalSig = _stats?['totalSignals'] as int? ?? 0;
    final winRate = (_stats?['winRate'] as num?)?.toDouble();
    final avgRR = (_stats?['avgRR'] as num?)?.toDouble();
    final profitFact = (_stats?['profitFactor'] as num?)?.toDouble();
    final bestTrade = (_stats?['bestTrade'] as num?)?.toDouble();
    final worstTrade = (_stats?['worstTrade'] as num?)?.toDouble();
    final wins = _stats?['wins'] as int? ?? 0;
    final lossesCnt = _stats?['losses'] as int? ?? 0;
    final expiredCnt = _stats?['expired'] as int? ?? 0;
    final hasEnoughData = closed >= 5;

    return Scaffold(
        body: RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _fetchStats,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(children: [
                      Text('Statistics',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      const Spacer(),
                      if (!_loading)
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppColors.greenDim,
                                borderRadius: BorderRadius.circular(20)),
                            child: Row(children: [
                              Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              const Text('Real Data',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.green)),
                            ])),
                    ])))),

        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('Based on actual TP/SL hits',
                    style: TextStyle(fontSize: 11, color: muted)))),

        // ── LIVE STATUS ──────────────────────────────────────────
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: bord, width: .5)),
                  child: Row(children: [
                    _quickStat('$totalSig', 'Total', AppColors.gold, muted),
                    Container(
                        width: 1,
                        height: 40,
                        color: bord,
                        margin: const EdgeInsets.symmetric(horizontal: 12)),
                    _quickStat('$open', 'Open', AppColors.gold, muted),
                    Container(
                        width: 1,
                        height: 40,
                        color: bord,
                        margin: const EdgeInsets.symmetric(horizontal: 12)),
                    _quickStat('$closed', 'Closed', AppColors.green, muted),
                  ]),
                ))),

        // ── NO DATA YET STATE ────────────────────────────────────
        if (!_loading && !hasEnoughData)
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: bord, width: .5)),
                    child: Column(children: [
                      const Icon(Icons.hourglass_empty,
                          color: AppColors.gold, size: 40),
                      const SizedBox(height: 12),
                      Text('Gathering Performance Data',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: txt)),
                      const SizedBox(height: 6),
                      Text(
                        closed == 0
                            ? 'No signals have closed yet.\nStats appear after the first trade resolves.'
                            : 'Only $closed closed signal${closed == 1 ? '' : 's'} so far.\nStats become reliable after 5+ closed trades.',
                        style:
                            TextStyle(fontSize: 12, color: muted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ))),

        // ── WIN RATE HERO — only if enough data ─────────────────
        if (!_loading && hasEnoughData) ...[
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1A1A0A),
                                  const Color(0xFF0D0D0D)
                                ]
                              : [
                                  const Color(0xFFFFF8E7),
                                  const Color(0xFFF5F5F0)
                                ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: Column(children: [
                      Row(children: [
                        SizedBox(
                            width: 110,
                            height: 110,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircularProgressIndicator(
                                    value: (winRate ?? 0) / 100,
                                    strokeWidth: 10,
                                    backgroundColor: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                    valueColor: AlwaysStoppedAnimation(
                                        _winRateColor(winRate)),
                                  )),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                Text('${winRate?.toStringAsFixed(1) ?? '—'}%',
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: _winRateColor(winRate))),
                                Text('Win Rate',
                                    style:
                                        TextStyle(fontSize: 9, color: muted)),
                              ]),
                            ])),
                        const SizedBox(width: 20),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              _statRow('Closed', '$closed', txt, muted),
                              const SizedBox(height: 8),
                              _statRow(
                                  '✓ TP Hit', '$wins', AppColors.green, muted),
                              const SizedBox(height: 8),
                              _statRow('✗ SL Hit', '$lossesCnt', AppColors.red,
                                  muted),
                              const SizedBox(height: 8),
                              _statRow('~ Expired', '$expiredCnt',
                                  AppColors.gold, muted),
                            ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        _metricCard(
                            'Avg R:R',
                            avgRR != null
                                ? '${avgRR >= 0 ? '+' : ''}${avgRR.toStringAsFixed(2)}R'
                                : '—',
                            avgRR != null && avgRR >= 0
                                ? AppColors.green
                                : AppColors.red,
                            stat),
                        const SizedBox(width: 8),
                        _metricCard(
                            'Profit Factor',
                            profitFact?.toStringAsFixed(2) ?? '—',
                            (profitFact ?? 0) >= 1.5
                                ? AppColors.green
                                : AppColors.gold,
                            stat),
                        const SizedBox(width: 8),
                        _metricCard(
                            'Best Trade',
                            bestTrade != null
                                ? '+${bestTrade.toStringAsFixed(1)}R'
                                : '—',
                            AppColors.green,
                            stat),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        _metricCard(
                            'Worst Trade',
                            worstTrade != null
                                ? '${worstTrade.toStringAsFixed(1)}R'
                                : '—',
                            AppColors.red,
                            stat),
                      ]),
                    ]),
                  ))),

          // ── FIB PERFORMANCE — real ──────────────────────────
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('FIB Level Performance',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: txt)))),
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildFibPerf(card, bord, txt, muted)),
          ),
        ],

        // ── SIGNAL BREAKDOWN — always show, from live list ──────
        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('Signal Breakdown',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: txt)))),

        SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Consumer<SignalService>(builder: (_, svc, __) {
                  final buys = svc.signals.where((s) => s.isBuy).length;
                  final sells = svc.signals.where((s) => s.isSell).length;
                  final total = svc.signals.length;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: bord, width: 0.5)),
                    child: Row(children: [
                      Expanded(
                          child: Column(children: [
                        Text('$buys',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.green
                                    : AppColors.greenDark)),
                        Text('BUY Signals',
                            style: TextStyle(fontSize: 11, color: muted)),
                        const SizedBox(height: 6),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? buys / total : 0,
                              backgroundColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              color: isDark
                                  ? AppColors.green
                                  : AppColors.greenDark,
                              minHeight: 5,
                            )),
                      ])),
                      Container(
                          width: 1,
                          height: 60,
                          color: bord,
                          margin: const EdgeInsets.symmetric(horizontal: 16)),
                      Expanded(
                          child: Column(children: [
                        Text('$sells',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.red
                                    : AppColors.redDark)),
                        Text('SELL Signals',
                            style: TextStyle(fontSize: 11, color: muted)),
                        const SizedBox(height: 6),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? sells / total : 0,
                              backgroundColor:
                                  isDark ? Colors.white12 : Colors.black12,
                              color: isDark ? AppColors.red : AppColors.redDark,
                              minHeight: 5,
                            )),
                      ])),
                    ]),
                  );
                }))),

        // ── RECENT CLOSED HISTORY — only real closed trades ─────
        if (_closedHistory.isNotEmpty) ...[
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text('Recent Closed Trades',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: txt)))),
          SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
            if (i >= _closedHistory.length) return null;
            final s = _closedHistory[i];
            final isBuy = s['action'] == 'BUY';
            final outcome = s['outcome']?.toString() ?? '';
            final pnlR = (s['pnl_r'] as num?)?.toDouble();
            final fib = s['fib_level']?.toString() ?? '—';
            final tf = s['timeframe']?.toString() ?? '—';

            String outLabel;
            Color outColor;
            switch (outcome) {
              case 'tp2_hit':
                outLabel = 'TP2 Hit';
                outColor = AppColors.green;
                break;
              case 'tp1_hit':
                outLabel = 'TP1 Hit';
                outColor = AppColors.green;
                break;
              case 'sl_hit':
                outLabel = 'SL Hit';
                outColor = AppColors.red;
                break;
              case 'expired':
                outLabel = 'Expired';
                outColor = AppColors.gold;
                break;
              default:
                outLabel = outcome;
                outColor = muted;
            }

            return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: bord, width: 0.5)),
                  child: Row(children: [
                    Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color:
                                isBuy ? AppColors.greenDim : AppColors.redDim,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Text(isBuy ? '▲' : '▼',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isBuy
                                        ? AppColors.green
                                        : AppColors.red)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('${s['action']} · $fib · $tf',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: txt)),
                          Text(
                              '\$${(s['price'] as num?)?.toStringAsFixed(2) ?? '—'} → \$${(s['exit_price'] as num?)?.toStringAsFixed(2) ?? '—'}',
                              style: TextStyle(fontSize: 11, color: muted)),
                        ])),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: outColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(outLabel,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: outColor))),
                          const SizedBox(height: 4),
                          if (pnlR != null)
                            Text(
                                '${pnlR >= 0 ? '+' : ''}${pnlR.toStringAsFixed(2)}R',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: pnlR >= 0
                                        ? AppColors.green
                                        : AppColors.red)),
                        ]),
                  ]),
                ));
          }, childCount: _closedHistory.length)),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    ));
  }

  Widget _buildFibPerf(Color card, Color bord, Color txt, Color muted) {
    final fibPerf = _stats?['fibPerformance'] as Map<String, dynamic>? ?? {};
    final levels = ['61.8%', '50.0%', '38.2%', '78.6%', '23.6%'];
    final labels = {
      '61.8%': '★ Golden Ratio',
      '50.0%': 'Midpoint',
      '38.2%': 'Key Level',
      '78.6%': 'Deep Pullback',
      '23.6%': 'Shallow'
    };
    final colors = {
      '61.8%': AppColors.gold,
      '50.0%': Colors.yellow,
      '38.2%': Colors.purple,
      '78.6%': Colors.orange,
      '23.6%': Colors.blue
    };

    return Container(
      decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bord, width: 0.5)),
      child: Column(children: [
        for (int i = 0; i < levels.length; i++) ...[
          _fibRow(
            levels[i],
            (fibPerf[levels[i]]?['winRate'] as num?)?.toDouble(),
            (fibPerf[levels[i]]?['total'] as int?) ?? 0,
            labels[levels[i]]!,
            colors[levels[i]]!,
            bord,
            txt,
            muted,
            last: i == levels.length - 1,
          ),
        ],
      ]),
    );
  }

  Widget _fibRow(String level, double? winRate, int count, String label,
          Color color, Color bord, Color txt, Color muted,
          {bool last = false}) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: bord, width: 0.5))),
        child: Row(children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(level,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: txt)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 10, color: muted)),
          const Spacer(),
          if (winRate != null) ...[
            Text('${winRate.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: winRate >= 65
                        ? AppColors.green
                        : winRate >= 50
                            ? AppColors.gold
                            : AppColors.red)),
            const SizedBox(width: 6),
            Text('($count)', style: TextStyle(fontSize: 9, color: muted)),
            const SizedBox(width: 10),
            SizedBox(
                width: 60,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: winRate / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(winRate >= 65
                          ? AppColors.green
                          : winRate >= 50
                              ? AppColors.gold
                              : AppColors.red),
                    ))),
          ] else
            Text('No data',
                style: TextStyle(
                    fontSize: 11, color: muted, fontStyle: FontStyle.italic)),
        ]),
      );

  Widget _quickStat(String value, String label, Color color, Color muted) =>
      Expanded(
          child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: muted)),
      ]));

  Widget _statRow(String label, String value, Color valueColor, Color muted) =>
      Row(children: [
        Text(label, style: TextStyle(fontSize: 12, color: muted)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ]);

  Widget _metricCard(String label, String value, Color color, Color bg) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(label,
              style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ]),
      ));
}
