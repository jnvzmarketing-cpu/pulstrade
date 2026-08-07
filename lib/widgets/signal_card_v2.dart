// ════════════════════════════════════════════════════════════════════
// SIGNAL CARD v2
// Sniper mode: entry zone bar with live-price marker, TP ladder with
// hit status, personal plan strip (lots per entry, max risk).
// Executor mode: classic market signal with validity state.
// ════════════════════════════════════════════════════════════════════

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/signal.dart';
import '../models/user_profile.dart';
import '../theme.dart';

class SignalCardV2 extends StatelessWidget {
  final Signal signal;
  final UserProfile profile;
  final double? livePrice;
  final VoidCallback? onTap;
  final bool locked; // free-tier blur

  const SignalCardV2({
    super.key,
    required this.signal,
    required this.profile,
    this.livePrice,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;

    final body = signal.isZone
        ? _zoneBody(context, txt, muted, bord, isDark)
        : _setupBody(context, txt, muted, bord, isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bord, width: isDark ? 1 : 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: locked
              ? Stack(children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: body,
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.lock_rounded, color: AppColors.gold, size: 14),
                          const SizedBox(width: 6),
                          Text('Pro signal',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.gold)),
                        ]),
                      ),
                    ),
                  ),
                ])
              : body,
        ),
      ),
    );
  }

  // ── SNIPER: zone card ───────────────────────────────────────────────
  Widget _zoneBody(BuildContext context, Color txt, Color muted, Color bord, bool isDark) {
    final plan = TradePlan.build(signal, profile);
    final sellish = signal.isSell;
    final actionColor = sellish ? AppColors.red : AppColors.green;
    final inTrade = signal.anyEntryFilled;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sellish ? 'SELL LIMIT' : 'BUY LIMIT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: actionColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(signal.ticker, style: TextStyle(fontSize: 12, color: muted)),
          const Spacer(),
          Icon(
            inTrade ? Icons.gps_fixed_rounded : Icons.my_location_rounded,
            size: 13,
            color: inTrade ? AppColors.gold : AppColors.green,
          ),
          const SizedBox(width: 4),
          Text(
            signal.zoneStatusLabel(livePrice ?? signal.currentPrice),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: inTrade ? AppColors.gold : AppColors.green),
          ),
        ]),
      ),

      // Zone prices + SL
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(signal.zoneNear.toStringAsFixed(0),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: txt,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('–', style: TextStyle(fontSize: 18, color: muted)),
          ),
          Text(signal.zoneFar.toStringAsFixed(0),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: txt,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const Spacer(),
          Text('SL ${signal.sl.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
        ]),
      ),
      const SizedBox(height: 10),

      // Zone bar with live price marker
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: _ZoneBar(signal: signal, livePrice: livePrice ?? signal.currentPrice),
      ),
      const SizedBox(height: 12),

      // TP ladder (compact)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            for (final line in plan.tps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Row(children: [
                  Icon(
                    line.tp.isHit ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 14,
                    color: line.tp.isHit ? AppColors.green : muted,
                  ),
                  const SizedBox(width: 8),
                  Text('TP${line.tp.level}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: line.tp.isHit ? AppColors.green : txt)),
                  const SizedBox(width: 10),
                  Text(line.tp.price.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 12,
                          color: txt,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                  const Spacer(),
                  Text('${line.weightPct}%', style: TextStyle(fontSize: 11, color: muted)),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 64,
                    child: Text(
                      line.tp.isHit
                          ? '+\$${line.profitIfHit.toStringAsFixed(0)}'
                          : '${line.rr.toStringAsFixed(1)}R',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: line.tp.isHit ? AppColors.green : muted),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Personal plan strip
      Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard2 : AppColors.lightCard2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          for (var i = 0; i < plan.entries.length && i < 2; i++) ...[
            _planStat('Entry ${i + 1}', '${plan.entries[i].lots.toStringAsFixed(2)} lot',
                txt, muted),
            const SizedBox(width: 16),
          ],
          _planStat('Max risk', '\$${plan.maxRiskUsd.toStringAsFixed(0)}', txt, muted),
          const Spacer(),
          Text(timeago.format(signal.timestamp),
              style: TextStyle(fontSize: 10, color: muted)),
        ]),
      ),
    ]);
  }

  // ── EXECUTOR: market signal card ────────────────────────────────────
  Widget _setupBody(BuildContext context, Color txt, Color muted, Color bord, bool isDark) {
    final plan = TradePlan.build(signal, profile);
    final actionColor = signal.isSell ? AppColors.red : AppColors.green;
    final v = signal.validity;
    final vColor = switch (v) {
      SignalValidity.valid => AppColors.green,
      SignalValidity.warning => AppColors.gold,
      SignalValidity.expired => muted,
    };

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(signal.action,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: actionColor)),
          ),
          const SizedBox(width: 8),
          Text(signal.ticker, style: TextStyle(fontSize: 12, color: muted)),
          if (signal.timeframe != null) ...[
            const SizedBox(width: 6),
            Text('· ${signal.timeframe}', style: TextStyle(fontSize: 12, color: muted)),
          ],
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: vColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(signal.validityLabel,
              style:
                  TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: vColor)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(signal.formattedPrice,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: txt,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 10),
          if (signal.confidence != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('${signal.confidence}% confidence',
                  style: TextStyle(fontSize: 11, color: muted)),
            ),
          const Spacer(),
          Text('SL ${signal.sl.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final line in plan.tps.take(3)) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard2 : AppColors.lightCard2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text('TP${line.tp.level}', style: TextStyle(fontSize: 10, color: muted)),
                  const SizedBox(height: 2),
                  Text(line.tp.price.toStringAsFixed(0),
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: txt)),
                ]),
              ),
            ),
            if (line != plan.tps.take(3).last) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _planStat('Lot', plan.totalLots.toStringAsFixed(2), txt, muted),
          const SizedBox(width: 16),
          _planStat('Max risk', '\$${plan.maxRiskUsd.toStringAsFixed(0)}', txt, muted),
          const Spacer(),
          Text(timeago.format(signal.timestamp),
              style: TextStyle(fontSize: 10, color: muted)),
        ]),
      ]),
    );
  }

  Widget _planStat(String label, String value, Color txt, Color muted) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: muted)),
        const SizedBox(height: 1),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: txt)),
      ]);
}

// ── Zone bar: SL → zone → TPs scale with live price marker ────────────
class _ZoneBar extends StatelessWidget {
  final Signal signal;
  final double? livePrice;
  const _ZoneBar({required this.signal, this.livePrice});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final track = isDark ? AppColors.darkCard2 : AppColors.lightCard2;

    // Price scale: from deepest TP to SL.
    final tpExtreme = signal.tps.isEmpty
        ? signal.zoneFar
        : signal.tps.map((t) => t.price).reduce(
            signal.isSell ? (a, b) => a < b ? a : b : (a, b) => a > b ? a : b);
    final lo = [tpExtreme, signal.sl, signal.zoneNear, signal.zoneFar]
        .reduce((a, b) => a < b ? a : b);
    final hi = [tpExtreme, signal.sl, signal.zoneNear, signal.zoneFar]
        .reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs();
    double pos(double price) => span <= 0 ? 0 : ((price - lo) / span).clamp(0.0, 1.0);

    final zoneL = pos(signal.zoneNear < signal.zoneFar ? signal.zoneNear : signal.zoneFar);
    final zoneR = pos(signal.zoneNear < signal.zoneFar ? signal.zoneFar : signal.zoneNear);
    final actionColor = signal.isSell ? AppColors.red : AppColors.green;

    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      return Column(children: [
        SizedBox(
          height: 14,
          child: Stack(children: [
            Positioned(
              top: 3,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration:
                    BoxDecoration(color: track, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Positioned(
              top: 3,
              left: w * zoneL,
              child: Container(
                width: (w * (zoneR - zoneL)).clamp(6.0, w),
                height: 8,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (livePrice != null && livePrice! > 0)
              Positioned(
                left: (w * pos(livePrice!)) - 1,
                child: Container(
                  width: 2.5,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            signal.tps.isEmpty ? '' : 'TP${signal.tps.length} ${tpExtreme.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 10, color: muted),
          ),
          if (livePrice != null)
            Text('Price ${livePrice!.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 10, color: muted)),
          Text('SL ${signal.sl.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 10, color: muted)),
        ]),
      ]);
    });
  }
}
