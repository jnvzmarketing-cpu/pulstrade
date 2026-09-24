import 'package:flutter/material.dart';
import '../models/signal.dart';
import '../theme.dart';

/// "Why this signal?" Expandable Section
/// Explains in plain language what triggered the signal
class WhySignalSection extends StatefulWidget {
  final Signal signal;
  const WhySignalSection({super.key, required this.signal});

  @override
  State<WhySignalSection> createState() => _State();
}

class _State extends State<WhySignalSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final reasons = _parseReasons();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bord, width: .5),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: AppColors.gold, size: 14),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Why this signal?',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: txt,
                            letterSpacing: -0.2)),
                    Text(
                        '${reasons.length} setup ${reasons.length == 1 ? 'reason' : 'reasons'} confirmed',
                        style: TextStyle(fontSize: 10, color: muted)),
                  ])),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down,
                    color: muted, size: 20),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: bord, height: 1),
                        const SizedBox(height: 14),
                        // Strategy Header
                        if (widget.signal.strategy != null) ...[
                          Row(children: [
                            const Icon(Icons.architecture,
                                size: 12, color: AppColors.gold),
                            const SizedBox(width: 6),
                            Text(
                                widget.signal.strategy!.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.gold,
                                    letterSpacing: 0.8)),
                          ]),
                          const SizedBox(height: 6),
                          Text(_strategyExplanation(widget.signal.strategy!),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: txt.withOpacity(.85),
                                  height: 1.5)),
                          const SizedBox(height: 14),
                        ],
                        // Reasons
                        Text('CONFIRMATIONS',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: muted,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        ...reasons.map((r) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                          color: AppColors.green,
                                          shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(r,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: txt.withOpacity(.85),
                                              height: 1.4)),
                                    ),
                                  ]),
                            )),
                      ]),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  // Parse the note field into individual reasons
  List<String> _parseReasons() {
    final note = widget.signal.note ?? '';
    final reasons = <String>[];

    // Split by | separator (used in backend)
    final parts = note.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);

    for (final part in parts) {
      // Skip the meta part like "A+ setup (4/5)" or "CONFIRMED after 2-bar sweep"
      if (part.startsWith('A+ setup') ||
          part.startsWith('A setup') ||
          part.startsWith('CONFIRMED') ||
          part.startsWith('Range:') ||
          part.startsWith('Tops:') ||
          part.startsWith('Bottoms:')) {
        continue;
      }
      // Convert to friendly format
      reasons.add(_humanize(part));
    }

    // If we got nothing meaningful from parsing, derive from signal fields
    if (reasons.isEmpty) {
      if (widget.signal.fibLevel != null) {
        reasons.add(
            'Price reached the ${widget.signal.fibLevel} Fibonacci retracement level — a key technical zone where reversals often occur.');
      }
      if (widget.signal.pattern != null &&
          widget.signal.pattern != 'No pattern') {
        reasons.add(
            'Detected ${widget.signal.pattern!.replaceAll(' (Liquidity Sweep Confirmed)', '')} candlestick pattern — a recognized reversal signal.');
      }
      if ((widget.signal.rsi ?? 50) < 35 && widget.signal.isBuy) {
        reasons.add(
            'RSI is oversold at ${widget.signal.rsi!.toStringAsFixed(1)} — momentum exhausted, reversal likely.');
      }
      if ((widget.signal.rsi ?? 50) > 65 && !widget.signal.isBuy) {
        reasons.add(
            'RSI is overbought at ${widget.signal.rsi!.toStringAsFixed(1)} — upside exhausted, reversal likely.');
      }
    }

    if (reasons.isEmpty) {
      reasons.add(
          'Multiple technical indicators aligned to suggest this entry point.');
    }

    return reasons;
  }

  // Make raw note like "FIB 61.8%: +25pts" more human readable
  String _humanize(String raw) {
    // Strip the points notation
    final cleaned = raw.replaceAll(RegExp(r':\s*\+\d+pts'), '');
    
    // Map technical terms to plain language
    if (cleaned.contains('FIB 61.8%')) {
      return 'Price at the Golden Pocket (61.8% Fibonacci) — the most respected reversal level.';
    }
    if (cleaned.contains('FIB 50.0%')) {
      return 'Price at the 50% Fibonacci retracement — strong mid-level support.';
    }
    if (cleaned.contains('FIB 38.2%')) {
      return 'Price at the 38.2% Fibonacci retracement — early reversal zone.';
    }
    if (cleaned.contains('FIB 78.6%')) {
      return 'Price at the 78.6% Fibonacci — deep retracement before reversal.';
    }
    if (cleaned.contains('extreme oversold')) {
      return 'RSI shows extreme oversold conditions — strong reversal probability.';
    }
    if (cleaned.contains('oversold')) {
      return 'RSI in oversold territory — momentum favors a bounce.';
    }
    if (cleaned.contains('overbought')) {
      return 'RSI in overbought territory — momentum favors a pullback.';
    }
    if (cleaned.contains('Above EMA50')) {
      return 'Price holding above the 50-period EMA — bullish trend confirmed.';
    }
    if (cleaned.contains('Below EMA50')) {
      return 'Price below the 50-period EMA — bearish trend confirmed.';
    }
    if (cleaned.contains('Pin Bar')) {
      return 'Pin Bar candlestick formed — strong rejection at this level.';
    }
    if (cleaned.contains('Engulfing')) {
      return 'Engulfing candlestick pattern — strong reversal indication.';
    }
    if (cleaned.contains('At BB Lower')) {
      return 'Price at the lower Bollinger Band — extreme stretch suggests bounce.';
    }
    if (cleaned.contains('At BB Upper')) {
      return 'Price at the upper Bollinger Band — overextended, pullback likely.';
    }
    if (cleaned.contains('Strong momentum candle')) {
      return 'Strong momentum candle confirms the directional bias.';
    }
    
    return cleaned;
  }

  String _strategyExplanation(String strategy) {
    if (strategy.contains('FIB')) {
      return 'Fibonacci Pullback strategy — entries are taken when price retraces to key Fibonacci levels in the direction of the larger trend. The Golden Pocket (61.8-65%) is the most reliable.';
    }
    if (strategy.contains('Setup 2') || strategy.contains('Breakout')) {
      return 'Aggressive Breakout & Retest strategy — after a tight consolidation range, an aggressive candle breaks through key moving averages. We wait for a retest of the breakout zone before entering.';
    }
    if (strategy.contains('Double Top') || strategy.contains('Double Bottom')) {
      return 'Double Top/Bottom Reversal strategy — when the market tests the same zone twice and fails to break through, an EMA20 break in the opposite direction confirms the reversal.';
    }
    if (strategy.contains('Liquidity Sweep')) {
      return 'After the initial signal trigger, we waited for a stop-hunt move (liquidity sweep) followed by a strong close back in our trade direction. This dramatically improves entry quality.';
    }
    return 'Multi-factor confirmation across price action, momentum, and volatility indicators.';
  }
}
