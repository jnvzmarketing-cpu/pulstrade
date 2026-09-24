import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

enum Sentiment { bullish, bearish, neutral }

/// MarketSentimentWidget v2 — Real MTF Trend Consensus
/// Uses /trend-consensus endpoint which checks EMAs across 5 timeframes
class MarketSentimentWidget extends StatefulWidget {
  const MarketSentimentWidget({super.key});
  @override
  State<MarketSentimentWidget> createState() => _State();
}

class _State extends State<MarketSentimentWidget> {
  Sentiment _sentiment = Sentiment.neutral;
  String _reason = 'Analyzing market conditions...';
  double _strength = 0.5;
  bool _loading = true;
  Timer? _timer;
  Map<String, String> _tfTrends = {};

  static const _backend = 'https://pulstrade-backend-production.up.railway.app';

  @override
  void initState() {
    super.initState();
    _fetch();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await http
          .get(Uri.parse('$_backend/trend-consensus'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final votes = data['votes'] as Map<String, dynamic>?;
        final consensus = data['consensus']?.toString() ?? 'NO_CONSENSUS';
        final timeframes = data['timeframes'] as Map<String, dynamic>?;

        if (timeframes != null) {
          _tfTrends = timeframes.map(
              (k, v) => MapEntry(k, (v['trend'] ?? 'N/A').toString()));
        }

        final upCount = (votes?['UP'] ?? 0) as int;
        final downCount = (votes?['DOWN'] ?? 0) as int;
        final total = upCount + downCount;

        if (mounted) {
          setState(() {
            if (consensus == 'BUY') {
              _sentiment = Sentiment.bullish;
              _reason =
                  '$upCount of 5 timeframes bullish · MTF aligned UP';
              _strength = total > 0 ? upCount / 5.0 : 0.5;
            } else if (consensus == 'SELL') {
              _sentiment = Sentiment.bearish;
              _reason =
                  '$downCount of 5 timeframes bearish · MTF aligned DOWN';
              _strength = total > 0 ? downCount / 5.0 : 0.5;
            } else {
              _sentiment = Sentiment.neutral;
              _reason =
                  'Mixed timeframes ($upCount UP / $downCount DOWN) · No clear bias';
              _strength = 0.4;
            }
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback if backend unavailable — say neutral honestly
    if (mounted) {
      setState(() {
        _sentiment = Sentiment.neutral;
        _reason = 'Unable to load market data · Try again later';
        _strength = 0.5;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.gold, strokeWidth: 2),
        ),
      );
    }

    final isBullish = _sentiment == Sentiment.bullish;
    final isBearish = _sentiment == Sentiment.bearish;
    final primaryColor = isBullish
        ? AppColors.green
        : isBearish
            ? AppColors.red
            : AppColors.gold;
    final label = isBullish ? 'BULLISH' : isBearish ? 'BEARISH' : 'NEUTRAL';
    final icon = isBullish ? '📈' : isBearish ? '📉' : '➡️';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withOpacity(isDark ? 0.15 : 0.08),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: primaryColor.withOpacity(.3), width: .5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Market Sentiment',
                style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight,
                    letterSpacing: .5)),
            Text(label,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: .5)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(_strength * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryColor)),
            Text('strength',
                style: TextStyle(
                    fontSize: 9,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight)),
          ]),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strength,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              color: primaryColor,
            )),
        const SizedBox(height: 10),
        Text(_reason,
            style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.textMuted
                    : AppColors.textMutedLight,
                height: 1.4)),
        if (_tfTrends.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tfTrends.entries.map((e) {
              final isUp = e.value == 'UP';
              final isDown = e.value == 'DOWN';
              final c = isUp
                  ? AppColors.green
                  : isDown
                      ? AppColors.red
                      : (isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: c.withOpacity(.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.key,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: c)),
                  const SizedBox(width: 4),
                  Text(
                      isUp
                          ? '↑'
                          : isDown
                              ? '↓'
                              : '→',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: c)),
                ]),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }
}
