import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme.dart';

/// MarketOverviewWidget v2 — Backend-driven (no direct API calls)
/// Fetches from Pulstrade Backend /market-overview which caches Twelve Data calls
class MarketOverviewWidget extends StatefulWidget {
  const MarketOverviewWidget({super.key});
  @override
  State<MarketOverviewWidget> createState() => _State();
}

class _State extends State<MarketOverviewWidget> {
  Timer? _timer;
  bool _loading = true;
  bool _error = false;

  static const _backend = 'https://pulstrade-backend-production.up.railway.app';

  // Market data
  double? _dxy, _dxyChg;
  double? _oil, _oilChg;
  double? _btc, _btcChg;
  double? _spx, _spxChg;

  // Macro events
  List<_MacroEvent> _events = [];
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Refresh every 60 seconds (backend caches)
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    await Future.wait([_fetchMarkets(), _fetchEvents()]);
    if (mounted) {
      setState(() {
      _loading = false;
      _lastUpdate = DateTime.now();
    });
    }
  }

  Future<void> _fetchMarkets() async {
    try {
      final res = await http
          .get(Uri.parse('$_backend/market-overview'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (data['dxy'] != null) {
          _dxy = (data['dxy']['price'] as num?)?.toDouble();
          _dxyChg = (data['dxy']['change'] as num?)?.toDouble();
        }
        if (data['oil'] != null) {
          _oil = (data['oil']['price'] as num?)?.toDouble();
          _oilChg = (data['oil']['change'] as num?)?.toDouble();
        }
        if (data['btc'] != null) {
          _btc = (data['btc']['price'] as num?)?.toDouble();
          _btcChg = (data['btc']['change'] as num?)?.toDouble();
        }
        if (data['spx'] != null) {
          _spx = (data['spx']['price'] as num?)?.toDouble();
          _spxChg = (data['spx']['change'] as num?)?.toDouble();
        }
        _error = false;
      } else {
        _error = true;
      }
    } catch (_) {
      _error = true;
    }
  }

  Future<void> _fetchEvents() async {
    try {
      final res = await http
          .get(Uri.parse('$_backend/calendar'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        _events = data.take(4).map((e) {
          final m = e as Map<String, dynamic>;
          return _MacroEvent(
            m['title']?.toString() ?? 'Event',
            m['currency']?.toString() ?? 'USD',
            m['timeLabel']?.toString() ?? '',
            m['impact']?.toString() ?? 'medium',
            (m['isSoon'] as bool?) ?? false,
          );
        }).toList();
      }
    } catch (_) {
      // keep stale events if any
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final bord = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final muted = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final txt = isDark ? Colors.white : Colors.black;

    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bord, width: .5),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppColors.gold,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bord, width: .5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.public, color: AppColors.gold, size: 14),
            ),
            const SizedBox(width: 10),
            Text('Market Overview',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: txt,
                    letterSpacing: -0.2)),
            const Spacer(),
            if (_error)
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppColors.red.withOpacity(.8)),
            if (!_error && _lastUpdate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                          letterSpacing: 0.5)),
                ]),
              ),
          ]),
        ),

        // 2x2 Grid of markets
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: _marketTile(
                      'DXY', 'Dollar Index', _dxy, _dxyChg, muted, txt)),
              const SizedBox(width: 8),
              Expanded(
                  child: _marketTile(
                      'WTI', 'Oil', _oil, _oilChg, muted, txt,
                      decimals: 2)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _marketTile(
                      'BTC', 'Bitcoin', _btc, _btcChg, muted, txt,
                      decimals: 0)),
              const SizedBox(width: 8),
              Expanded(
                  child: _marketTile(
                      'SPX', 'S&P 500', _spx, _spxChg, muted, txt,
                      decimals: 2)),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // Events Section
        if (_events.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Row(children: [
              const Icon(Icons.event_note,
                  size: 12, color: AppColors.gold),
              const SizedBox(width: 6),
              Text('Upcoming Events',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: muted,
                      letterSpacing: 0.5)),
            ]),
          ),
          ..._events.map((e) => _eventRow(e, muted, txt, bord)),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 6),
      ]),
    );
  }

  Widget _marketTile(String symbol, String name, double? price, double? chg,
      Color muted, Color txt,
      {int decimals = 2}) {
    final hasData = price != null;
    final isUp = (chg ?? 0) >= 0;
    final chgColor = isUp ? AppColors.green : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.gold.withOpacity(.08), width: .5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(symbol,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: muted,
                  letterSpacing: 0.5)),
          const Spacer(),
          if (chg != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: chgColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(
                  '${isUp ? '+' : ''}${chg.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: chgColor)),
            ),
        ]),
        const SizedBox(height: 4),
        Text(
          hasData
              ? (decimals == 0
                  ? '\$${price.toStringAsFixed(0)}'
                  : price.toStringAsFixed(decimals))
              : '—',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: txt,
              letterSpacing: -0.3),
        ),
        const SizedBox(height: 1),
        Text(name,
            style: TextStyle(fontSize: 9, color: muted, letterSpacing: 0.3)),
      ]),
    );
  }

  Widget _eventRow(
      _MacroEvent e, Color muted, Color txt, Color bord) {
    final impactColor = e.impact == 'high'
        ? AppColors.red
        : e.impact == 'medium'
            ? AppColors.gold
            : AppColors.green;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 2, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: e.isSoon ? AppColors.goldDim.withOpacity(.5) : null,
      ),
      child: Row(children: [
        Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
                color: impactColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(e.title,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: txt)),
              Text(e.currency,
                  style: TextStyle(fontSize: 9, color: muted)),
            ])),
        Text(e.timeLabel,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: e.isSoon ? AppColors.gold : muted)),
      ]),
    );
  }
}

class _MacroEvent {
  final String title;
  final String currency;
  final String timeLabel;
  final String impact;
  final bool isSoon;
  _MacroEvent(
      this.title, this.currency, this.timeLabel, this.impact, this.isSoon);
}
