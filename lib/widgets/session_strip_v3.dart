// ════════════════════════════════════════════════════════════════════
// SESSION STRIP V3 — Tokyo / London / NY chips (Obsidian)
// UTC windows: Tokyo 0–8, London 7–16, NY 12–21.
// Active session = gold chip. Others show countdown or "vorbei".
// Also exposes nextZoneDrop(): the next 23:45/06:45/11:45 UTC moment.
// ════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../config/obsidian_theme.dart';

class TradingSession {
  final String key, name;
  final int openH, closeH;       // UTC
  final int dropH, dropM;        // zone drop time UTC
  TradingSession(this.key, this.name, this.openH, this.closeH,
      this.dropH, this.dropM);
}

final kSessions = [
  TradingSession('tokyo', 'Tokyo', 0, 8, 23, 45),
  TradingSession('london', 'London', 7, 16, 6, 45),
  TradingSession('ny', 'New York', 12, 21, 11, 45),
];

class SessionInfo {
  final TradingSession session;
  final bool isLive;
  final Duration untilOpen;   // zero if live/over today
  final Duration untilClose;  // zero if not live
  final bool overToday;
  SessionInfo(this.session, this.isLive, this.untilOpen, this.untilClose,
      this.overToday);
}

bool _isTradingDay(DateTime d) =>
    d.weekday >= DateTime.monday && d.weekday <= DateTime.friday;

SessionInfo sessionInfo(TradingSession s, DateTime nowUtc) {
  final todayOpen = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, s.openH);
  final todayClose = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, s.closeH);
  final tradingToday = _isTradingDay(nowUtc);
  if (tradingToday && nowUtc.isAfter(todayOpen) && nowUtc.isBefore(todayClose)) {
    return SessionInfo(s, true, Duration.zero, todayClose.difference(nowUtc), false);
  }
  if (tradingToday && nowUtc.isBefore(todayOpen)) {
    return SessionInfo(s, false, todayOpen.difference(nowUtc), Duration.zero, false);
  }
  // vorbei oder Wochenende: naechsten Handelstag suchen
  final overToday = tradingToday && nowUtc.isAfter(todayClose);
  var openAt = todayOpen.add(Duration(days: 1));
  while (!_isTradingDay(openAt)) {
    openAt = openAt.add(Duration(days: 1));
  }
  return SessionInfo(s, false, openAt.difference(nowUtc), Duration.zero, overToday);
}

/// Next zone-drop moment (23:45 / 06:45 / 11:45 UTC) and its session.
({DateTime at, TradingSession session}) nextZoneDrop(DateTime nowUtc) {
  ({DateTime at, TradingSession session})? best;
  for (final s in kSessions) {
    var t = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, s.dropH, s.dropM);
    // Drop nur gueltig, wenn die SESSION auf einen Handelstag faellt.
    // Tokyo-Drop 23:45 gehoert zur Session des Folgetags.
    DateTime sessionDay(DateTime drop) =>
        s.key == 'tokyo' ? drop.add(Duration(days: 1)) : drop;
    while (!t.isAfter(nowUtc) || !_isTradingDay(sessionDay(t))) {
      t = t.add(Duration(days: 1));
    }
    if (best == null || t.isBefore(best.at)) best = (at: t, session: s);
  }
  return best!;
}

String _short(Duration d) {
  if (d.inHours >= 24) return 'in ${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours >= 1) return 'in ${d.inHours}h';
  return 'in ${d.inMinutes}m';
}

class SessionStripV3 extends StatelessWidget {
  final DateTime? nowUtc; // injectable for tests
  SessionStripV3({super.key, this.nowUtc});

  @override
  Widget build(BuildContext context) {
    final now = nowUtc ?? DateTime.now().toUtc();
    return Row(
      children: [
        for (var i = 0; i < kSessions.length; i++) ...[
          if (i > 0) SizedBox(width: 6),
          Expanded(child: _chip(sessionInfo(kSessions[i], now))),
        ],
      ],
    );
  }

  Widget _chip(SessionInfo info) {
    final live = info.isLive;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: live ? Obsidian.goldBg : Obsidian.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: live
            ? Border.all(color: Obsidian.goldDeep, width: 0.5) : null,
      ),
      child: Column(children: [
        Text(info.session.name, style: TextStyle(
          fontSize: 11,
          fontWeight: live ? FontWeight.w600 : FontWeight.w400,
          color: live ? Obsidian.gold : Obsidian.textLow,
        )),
        SizedBox(height: 1),
        Text(
          live
              ? (info.untilClose.inHours >= 1
                  ? 'live \u00b7 ${info.untilClose.inHours}h'
                  : 'live \u00b7 ${info.untilClose.inMinutes}m')
              : (info.overToday ? _short(info.untilOpen) : _short(info.untilOpen)),
          style: TextStyle(
            fontFamily: Obsidian.monoFamily, fontSize: 11,
            color: live ? Obsidian.goldSoft : Obsidian.textMid,
          ),
        ),
      ]),
    );
  }
}
