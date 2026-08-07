// ════════════════════════════════════════════════════════════════════
// SIGNAL MODEL v2 — Telegram-parity
// Multi-entry zones (limit/stop/market), TP ladders (up to 5) with
// per-TP status, full backward compatibility with the legacy backend
// payload (price / sl / tp1 / tp2).
// ════════════════════════════════════════════════════════════════════

enum SignalValidity { valid, warning, expired }

enum OrderKind { market, limit, stop }

enum EntryStatus { pending, filled, cancelled }

enum TpStatus { open, hit }

enum SignalKind { zone, setup } // zone = Sniper (limit), setup = Executor (market)

class MtfConfirmation {
  final bool h1, h4, d1;
  const MtfConfirmation({required this.h1, required this.h4, required this.d1});
  bool get isStrong => h1 && h4 && d1;
  int get confirmedCount => (h1 ? 1 : 0) + (h4 ? 1 : 0) + (d1 ? 1 : 0);
  factory MtfConfirmation.fromJson(Map<String, dynamic> j) =>
      MtfConfirmation(h1: j['h1'] == true, h4: j['h4'] == true, d1: j['d1'] == true);
}

class SignalEntry {
  final double price;
  final OrderKind kind;
  final EntryStatus status;
  final String? filledAt;

  const SignalEntry({
    required this.price,
    this.kind = OrderKind.market,
    this.status = EntryStatus.pending,
    this.filledAt,
  });

  bool get isFilled => status == EntryStatus.filled;

  factory SignalEntry.fromJson(Map<String, dynamic> j) => SignalEntry(
        price: (j['price'] as num).toDouble(),
        filledAt: j['filled_at']?.toString(),
        kind: OrderKind.values.firstWhere(
          (k) => k.name == (j['kind'] ?? 'market'),
          orElse: () => OrderKind.market,
        ),
        status: EntryStatus.values.firstWhere(
          (s) => s.name == (j['status'] ?? 'pending'),
          orElse: () => EntryStatus.pending,
        ),
      );

  Map<String, dynamic> toJson() => {
        'price': price,
        'kind': kind.name,
        'status': status.name,
        if (filledAt != null) 'filled_at': filledAt!,
      };
}

class TakeProfit {
  final int level; // 1..5
  final double price;
  final TpStatus status;
  final String? hitAt;

  const TakeProfit({
    required this.level,
    required this.price,
    this.status = TpStatus.open,
    this.hitAt,
  });

  bool get isHit => status == TpStatus.hit;

  factory TakeProfit.fromJson(Map<String, dynamic> j) => TakeProfit(
        level: j['level'] as int? ?? 1,
        price: (j['price'] as num).toDouble(),
        hitAt: j['hit_at']?.toString(),
        status: (j['status'] == 'hit') ? TpStatus.hit : TpStatus.open,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'price': price,
        'status': status.name,
        if (hitAt != null) 'hit_at': hitAt!,
      };
}

class Signal {
  final int? id;
  final String ticker, action; // BUY | SELL
  final SignalKind kind;
  final List<SignalEntry> entries;
  final List<TakeProfit> tps;
  final double sl;
  final String? timeframe, fibLevel, pattern, note, strategy, outcome, session;
  final int? confidence;
  final double? rsi, atr, currentPrice, entryValidFor;
  final MtfConfirmation? mtf;
  final DateTime timestamp;
  final String status; // active | filled | closed | cancelled

  const Signal({
    this.id,
    required this.ticker,
    required this.action,
    required this.kind,
    required this.entries,
    required this.tps,
    required this.sl,
    this.timeframe,
    this.fibLevel,
    this.pattern,
    this.note,
    this.strategy,
    this.outcome,
    this.session,
    this.confidence,
    this.rsi,
    this.atr,
    this.currentPrice,
    this.entryValidFor,
    this.mtf,
    this.status = 'active',
    required this.timestamp,
  });

  // ── Convenience ─────────────────────────────────────────────────────
  bool get isBuy => action == 'BUY';
  bool get isSell => action == 'SELL';
  bool get isZone => kind == SignalKind.zone;
  bool get isSetup => kind == SignalKind.setup;

  /// Primary entry price (first entry) — keeps legacy call sites working.
  double get price => entries.isNotEmpty ? entries.first.price : 0;
  String get formattedPrice => price.toStringAsFixed(2);

  /// Legacy accessors — derived from the TP ladder.
  double? get tp1 => tps.isNotEmpty ? tps.first.price : null;
  double? get tp2 => tps.length > 1 ? tps[1].price : null;

  /// Zone bounds. "Near" = the edge price reaches first.
  double get zoneNear => isSell
      ? entries.map((e) => e.price).reduce((a, b) => a < b ? a : b)
      : entries.map((e) => e.price).reduce((a, b) => a > b ? a : b);
  double get zoneFar => isSell
      ? entries.map((e) => e.price).reduce((a, b) => a > b ? a : b)
      : entries.map((e) => e.price).reduce((a, b) => a < b ? a : b);
  double get zoneMid => (zoneNear + zoneFar) / 2;

  bool get anyEntryFilled => entries.any((e) => e.isFilled);
  int get tpHitCount => tps.where((t) => t.isHit).length;
  bool get allTpsHit => tps.isNotEmpty && tps.every((t) => t.isHit);

  /// Distance from live price to the near zone edge, in points.
  double? distanceToZone(double? livePrice) {
    if (livePrice == null || livePrice <= 0 || entries.isEmpty) return null;
    return (livePrice - zoneNear).abs();
  }

  bool priceInZone(double? livePrice) {
    if (livePrice == null || entries.length < 2) return false;
    final lo = zoneNear < zoneFar ? zoneNear : zoneFar;
    final hi = zoneNear < zoneFar ? zoneFar : zoneNear;
    return livePrice >= lo && livePrice <= hi;
  }

  /// Zone status label for the Sniper card.
  String zoneStatusLabel(double? livePrice) {
    if (status == 'closed') return 'Closed';
    if (status == 'cancelled') return 'Cancelled';
    if (allTpsHit) return 'All TPs hit';
    if (anyEntryFilled) return 'In trade · TP $tpHitCount/${tps.length}';
    if (priceInZone(livePrice)) return 'Price in zone';
    final d = distanceToZone(livePrice);
    if (d == null) return 'Zone active';
    return '${d.toStringAsFixed(0)} pips away';
  }

  // ── Validity ────────────────────────────────────────────────────────
  SignalValidity get validity {
    if (isZone) {
      if (status == 'cancelled' || status == 'closed') return SignalValidity.expired;
      final age = DateTime.now().difference(timestamp).inHours;
      return age > 24 ? SignalValidity.expired : SignalValidity.valid;
    }
    final validFor = entryValidFor ?? 2.0;
    final age = DateTime.now().difference(timestamp).inMinutes;
    if (age < validFor * 60 * 0.5) return SignalValidity.valid;
    if (age < validFor * 60) return SignalValidity.warning;
    return SignalValidity.expired;
  }

  String get validityLabel {
    if (isZone) return zoneStatusLabel(currentPrice);
    switch (validity) {
      case SignalValidity.valid:
        return 'Enter now';
      case SignalValidity.warning:
        return 'Check price';
      case SignalValidity.expired:
        return 'Expired';
    }
  }

  String get rsiLabel {
    if (rsi == null) return '';
    if (rsi! >= 70) return 'Overbought';
    if (rsi! <= 30) return 'Oversold';
    return 'Neutral';
  }

  // ── Parsing ─────────────────────────────────────────────────────────
  factory Signal.fromJson(Map<String, dynamic> j) {
    MtfConfirmation? mtf;
    if (j['mtf'] != null && j['mtf'] is Map) {
      mtf = MtfConfirmation.fromJson(Map<String, dynamic>.from(j['mtf']));
    }

    final ts = j['timestamp'];
    DateTime dt;
    if (ts is int) {
      dt = ts > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    } else {
      dt = DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();
    }

    // ── v2 payload: entries[] present ──
    if (j['entries'] is List && (j['entries'] as List).isNotEmpty) {
      final entries = (j['entries'] as List)
          .map((e) => SignalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final tps = (j['tps'] as List? ?? [])
          .map((t) => TakeProfit.fromJson(Map<String, dynamic>.from(t)))
          .toList()
        ..sort((a, b) => a.level.compareTo(b.level));
      return Signal(
        id: j['id'] as int?,
        ticker: j['ticker']?.toString() ?? 'XAU/USD',
        action: j['action']?.toString() ?? 'BUY',
        kind: (j['kind'] == 'zone' || entries.any((e) => e.kind != OrderKind.market))
            ? SignalKind.zone
            : SignalKind.setup,
        entries: entries,
        tps: tps,
        sl: _d(j['sl']) ?? 0,
        timeframe: j['timeframe']?.toString(),
        fibLevel: j['fib_level']?.toString(),
        pattern: j['pattern']?.toString(),
        note: j['note']?.toString(),
        strategy: j['strategy']?.toString(),
        outcome: j['outcome']?.toString(),
        session: j['session']?.toString(),
        confidence: j['confidence'] as int?,
        rsi: _d(j['rsi']),
        atr: _d(j['atr']),
        currentPrice: _d(j['current_price']),
        entryValidFor: _d(j['entry_valid_for']),
        mtf: mtf,
        status: j['status']?.toString() ?? 'active',
        timestamp: dt,
      );
    }

    // ── Legacy payload: price / sl / tp1 / tp2 ──
    final price = _d(j['price']) ?? 0;
    final tps = <TakeProfit>[
      if (_d(j['tp1']) != null) TakeProfit(level: 1, price: _d(j['tp1'])!),
      if (_d(j['tp2']) != null) TakeProfit(level: 2, price: _d(j['tp2'])!),
    ];
    return Signal(
      id: j['id'] as int?,
      ticker: j['ticker']?.toString() ?? 'XAU/USD',
      action: j['action']?.toString() ?? 'BUY',
      kind: SignalKind.setup,
      entries: [SignalEntry(price: price)],
      tps: tps,
      sl: _d(j['sl']) ?? 0,
      timeframe: j['timeframe']?.toString(),
      fibLevel: j['fib_level']?.toString(),
      pattern: j['pattern']?.toString(),
      note: j['note']?.toString(),
      strategy: j['strategy']?.toString(),
      outcome: j['outcome']?.toString(),
      confidence: j['confidence'] as int?,
      rsi: _d(j['rsi']),
      atr: _d(j['atr']),
      currentPrice: _d(j['current_price']),
      entryValidFor: _d(j['entry_valid_for']),
      mtf: mtf,
      timestamp: dt,
    );
  }

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
}
