// Ersetzt price_service.dart + signal_service.dart (Railway-Polling alle 15 s).
// Preis und Signale kommen per Realtime, Kerzen per RPC candles(tf, limit).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/signal.dart';

class Candle {
  final DateTime ts;
  final double open, high, low, close;
  const Candle(this.ts, this.open, this.high, this.low, this.close);
  factory Candle.fromRow(Map<String, dynamic> r) => Candle(
        DateTime.parse(r['ts']).toUtc(),
        (r['open'] as num).toDouble(),
        (r['high'] as num).toDouble(),
        (r['low'] as num).toDouble(),
        (r['close'] as num).toDouble(),
      );
}

class TrackRecord {
  final int total;
  final double winRate, avgR, sumR;
  const TrackRecord(this.total, this.winRate, this.avgR, this.sumR);
}

class MissedSummary {
  final int total, wins, losses, open;
  final double pnlR;
  const MissedSummary(this.total, this.wins, this.losses, this.open, this.pnlR);
}

class MarketRepo extends ChangeNotifier {
  final _sb = Supabase.instance.client;

  double? price;
  DateTime? priceTs;
  double? prevClose; // für Tagesveränderung
  List<Signal> signals = const [];
  RealtimeChannel? _ch;

  /// Alter des letzten Kurses. Yahoo liefert Futures ~10 min verzögert,
  /// deshalb zeigt die UI "vor 10 min", nicht "live".
  Duration? get priceAge =>
      priceTs == null ? null : DateTime.now().toUtc().difference(priceTs!);
  bool get priceStale => priceAge == null || priceAge! > const Duration(minutes: 25);
  double? get dayChangePct =>
      (price != null && prevClose != null && prevClose! > 0)
          ? (price! - prevClose!) / prevClose! * 100
          : null;

  Future<void> start() async {
    await Future.wait([_loadPrice(), _loadSignals(), _loadPrevClose()]);
    _ch = _sb
        .channel('market')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'candles_1m',
          callback: (p) {
            final r = p.newRecord;
            price = (r['close'] as num).toDouble();
            priceTs = DateTime.parse(r['ts']).toUtc();
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'signals',
          callback: (_) => _loadSignals(),
        )
        .subscribe();
  }

  Future<void> _loadPrice() async {
    final r = await _sb.rpc('latest_price').select().maybeSingle();
    if (r != null) {
      price = (r['price'] as num).toDouble();
      priceTs = DateTime.parse(r['ts']).toUtc();
      notifyListeners();
    }
  }

  Future<void> _loadPrevClose() async {
    final rows = await _sb.rpc('candles', params: {'p_tf': '1day', 'p_limit': 2});
    if (rows is List && rows.length >= 2) {
      prevClose = (rows[1]['close'] as num).toDouble();
      notifyListeners();
    }
  }

  Future<void> _loadSignals() async {
    final rows = await _sb
        .from('signals')
        .select()
        .order('created_at', ascending: false)
        .limit(150);
    signals = rows.map(Signal.fromRow).toList();
    notifyListeners();
  }

  Future<List<Candle>> candles(String tf, {int limit = 220}) async {
    final rows = await _sb.rpc('candles', params: {'p_tf': tf, 'p_limit': limit});
    return (rows as List).map((r) => Candle.fromRow(r)).toList().reversed.toList();
  }

  Future<TrackRecord?> trackRecord({int days = 30}) async {
    final r = await _sb.rpc('track_record', params: {'p_days': days}).select().maybeSingle();
    if (r == null || r['total'] == null || r['total'] == 0) return null;
    return TrackRecord(r['total'], _d(r['win_rate']), _d(r['avg_r']), _d(r['sum_r']));
  }

  Future<MissedSummary?> missedSince(DateTime since) async {
    final r = await _sb
        .rpc('missed_summary', params: {'p_since': since.toUtc().toIso8601String()})
        .select()
        .maybeSingle();
    if (r == null) return null;
    return MissedSummary(r['total'], r['wins'], r['losses'], r['open'], _d(r['pnl_r']));
  }

  static double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

  @override
  void dispose() {
    _ch?.unsubscribe();
    super.dispose();
  }
}
