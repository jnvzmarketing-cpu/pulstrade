// ════════════════════════════════════════════════════════════════════
// TODAY SCREEN — the cockpit. First tab.
// Session status → zones of the day (Sniper) → active trades with
// TP progress → latest setup signals (Executor).
// ════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/signal.dart';
import '../models/user_profile.dart';
import '../services/signal_service.dart';
import '../services/price_service.dart';
import '../services/profile_v2_service.dart';
import '../widgets/signal_card_v2.dart';
import '../widgets/live_price_header.dart';
import '../theme.dart';

class TodayScreen extends StatelessWidget {
  final void Function(Signal)? onOpenSignal;
  const TodayScreen({super.key, this.onOpenSignal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txt = isDark ? Colors.white : Colors.black;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;

    final sig = context.watch<SignalService>();
    final price = context.watch<PriceService>();
    final profile = context.watch<ProfileV2Service>().profile;

    final zones = sig.signals
        .where((s) => s.isZone && s.validity != SignalValidity.expired && !s.anyEntryFilled)
        .toList();
    final activeTrades = sig.signals
        .where((s) => s.anyEntryFilled && s.status != 'closed' && s.status != 'cancelled')
        .toList();
    final setups = sig.signals
        .where((s) => s.isSetup && s.validity != SignalValidity.expired)
        .take(3)
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => sig.fetchSignals(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const LivePriceHeader(),
            const SizedBox(height: 4),

            // ── Session status ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: _SessionStrip(profile: profile),
            ),

            // ── Active trades ──
            if (activeTrades.isNotEmpty) ...[
              _sectionTitle('Active trades', txt,
                  trailing: '${activeTrades.length}', muted: muted),
              for (final s in activeTrades)
                SignalCardV2(
                  signal: s,
                  profile: profile,
                  livePrice: price.price,
                  onTap: () => onOpenSignal?.call(s),
                ),
            ],

            // ── Zones of the day ──
            _sectionTitle("Today's zones", txt,
                trailing: zones.isEmpty ? null : '${zones.length}', muted: muted),
            if (zones.isEmpty)
              _emptyState(
                context,
                icon: Icons.my_location_rounded,
                title: 'No zones yet',
                subtitle: profile.session == TradingSession.all
                    ? 'New zones drop before each session opens.'
                    : 'Your ${_sessionName(profile.session)} zones drop ~15 min before the open.',
                muted: muted,
              )
            else
              for (final s in zones)
                SignalCardV2(
                  signal: s,
                  profile: profile,
                  livePrice: price.price,
                  onTap: () => onOpenSignal?.call(s),
                ),

            // ── Latest setups ──
            if (setups.isNotEmpty) ...[
              _sectionTitle('Live setups', txt, muted: muted),
              for (final s in setups)
                SignalCardV2(
                  signal: s,
                  profile: profile,
                  livePrice: price.price,
                  onTap: () => onOpenSignal?.call(s),
                ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _sessionName(TradingSession s) => switch (s) {
        TradingSession.tokyo => 'Tokyo',
        TradingSession.london => 'London',
        TradingSession.newYork => 'New York',
        TradingSession.all => 'next',
      };

  Widget _sectionTitle(String title, Color txt, {String? trailing, required Color muted}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Row(children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: txt)),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(trailing,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold)),
            ),
          ],
        ]),
      );

  Widget _emptyState(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color muted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: isDark ? 1 : 0.5),
      ),
      child: Column(children: [
        Icon(icon, color: muted, size: 28),
        const SizedBox(height: 10),
        Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: muted)),
      ]),
    );
  }
}

// ── Session strip: which session is live now (UTC-based) ──────────────
class _SessionStrip extends StatelessWidget {
  final UserProfile profile;
  const _SessionStrip({required this.profile});

  // Approx XAU sessions in UTC: Tokyo 00–08, London 07–16, NY 12–21.
  static const _sessions = [
    ('Tokyo', 0, 8, TradingSession.tokyo),
    ('London', 7, 16, TradingSession.london),
    ('New York', 12, 21, TradingSession.newYork),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final nowUtc = DateTime.now().toUtc();
    final h = nowUtc.hour + nowUtc.minute / 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: isDark ? 1 : 0.5),
      ),
      child: Row(
        children: [
          for (final (name, start, end, sess) in _sessions) ...[
            Expanded(child: _chip(name, start, end, sess, h, isDark, muted)),
            if (name != 'New York') const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(String name, int start, int end, TradingSession sess, double h,
      bool isDark, Color muted) {
    final live = h >= start && h < end;
    final isMine = profile.session == sess || profile.session == TradingSession.all;
    final color = live
        ? AppColors.green
        : (isMine ? AppColors.gold : muted);
    String sub;
    if (live) {
      sub = 'Live · ${(end - h).floor()}h left';
    } else {
      final until = h < start ? start - h : 24 - h + start;
      sub = 'in ${until.ceil()}h';
    }
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: live ? AppColors.green : muted.withValues(alpha: .4),
                shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 2),
      Text(sub, style: TextStyle(fontSize: 10, color: muted)),
    ]);
  }
}
