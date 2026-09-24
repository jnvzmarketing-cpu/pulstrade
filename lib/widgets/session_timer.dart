import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

class SessionTimer extends StatefulWidget {
  const SessionTimer({super.key});
  @override
  State<SessionTimer> createState() => _State();
}

class _State extends State<SessionTimer> {
  Timer? _timer;
  Duration _timeToNext = Duration.zero;
  String _sessionName = '';
  String _currentSession = '';
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _update() {
    final now = DateTime.now().toUtc();
    final weekday = now.weekday; // 1=Mon, 6=Sat, 7=Sun
    final totalSec = now.hour * 3600 + now.minute * 60 + now.second;

    // Gold market hours (UTC):
    // Opens: Sunday 22:00 UTC
    // Closes: Friday 21:00 UTC
    // Truly closed: Friday 21:00 → Sunday 22:00

    final isSaturday = weekday == DateTime.saturday;
    final isSundayBeforeOpen =
        weekday == DateTime.sunday && totalSec < 22 * 3600;
    final isFridayAfterClose =
        weekday == DateTime.friday && totalSec >= 21 * 3600;
    final isMarketClosed =
        isSaturday || isSundayBeforeOpen || isFridayAfterClose;

    if (isMarketClosed) {
      _isActive = false;
      _currentSession = 'CLOSED';
      _sessionName = 'Market opens';
      // Calculate time to Sunday 22:00 UTC
      if (isSaturday) {
        final secsToSunday22 = (7 - weekday) * 86400 - totalSec + 22 * 3600;
        _timeToNext = Duration(
            seconds: secsToSunday22 > 0
                ? secsToSunday22
                : secsToSunday22 + 7 * 86400);
      } else if (isSundayBeforeOpen) {
        _timeToNext = Duration(seconds: 22 * 3600 - totalSec);
      } else {
        // Friday after 21:00
        final secsTillSunday22 = (7 - weekday) * 86400 +
            (7 - weekday + 0) * 0 +
            (22 * 3600 - totalSec) +
            2 * 86400;
        _timeToNext = Duration(seconds: secsTillSunday22);
      }
    } else {
      // Determine which session is active
      // Sydney:  22:00 - 06:00 UTC
      // Tokyo:   00:00 - 08:00 UTC
      // London:  08:00 - 17:00 UTC
      // NY:      13:00 - 22:00 UTC
      // Overlap London+NY: 13:00 - 17:00 UTC

      if (totalSec >= 13 * 3600 && totalSec < 17 * 3600) {
        _isActive = true;
        _currentSession = 'LONDON + NY';
        _timeToNext = Duration(seconds: 17 * 3600 - totalSec);
        _sessionName = 'Overlap ends';
      } else if (totalSec >= 8 * 3600 && totalSec < 17 * 3600) {
        _isActive = true;
        _currentSession = 'LONDON';
        _timeToNext = Duration(seconds: 17 * 3600 - totalSec);
        _sessionName = 'Session ends';
      } else if (totalSec >= 13 * 3600 && totalSec < 22 * 3600) {
        _isActive = true;
        _currentSession = 'NEW YORK';
        _timeToNext = Duration(seconds: 22 * 3600 - totalSec);
        _sessionName = 'Session ends';
      } else if (totalSec >= 0 && totalSec < 8 * 3600) {
        _isActive = true;
        _currentSession = 'TOKYO';
        _timeToNext = Duration(seconds: 8 * 3600 - totalSec);
        _sessionName = 'London opens';
      } else {
        _isActive = true;
        _currentSession = 'SYDNEY';
        _timeToNext = Duration(seconds: 86400 - totalSec + 0);
        _sessionName = 'Tokyo opens';
      }
    }
    if (mounted) setState(() {});
  }

  String _fmt(Duration d) {
    final h = d.inHours.abs();
    final m = d.inMinutes.abs() % 60;
    final s = d.inSeconds.abs() % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final txt = isDark ? Colors.white : Colors.black;

    final sessionColor =
        _currentSession.contains('LONDON') && _currentSession.contains('NY')
            ? AppColors.gold
            : _currentSession == 'LONDON'
                ? const Color(0xFF3B82F6)
                : _currentSession == 'NEW YORK'
                    ? const Color(0xFF8B5CF6)
                    : _currentSession == 'TOKYO'
                        ? const Color(0xFFEC4899)
                        : _currentSession == 'SYDNEY'
                            ? const Color(0xFF06B6D4)
                            : Colors.grey;

    return Row(children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isActive ? sessionColor : Colors.grey,
            shape: BoxShape.circle,
          )),
      const SizedBox(width: 10),
      Text(_currentSession,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: sessionColor)),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(_sessionName, style: TextStyle(fontSize: 9, color: muted)),
        Text(_fmt(_timeToNext),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: txt,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    ]);
  }
}
