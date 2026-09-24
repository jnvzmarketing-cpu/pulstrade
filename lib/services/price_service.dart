import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PriceService extends ChangeNotifier {
  static const _serverUrl =
      'https://pulstrade-backend-production.up.railway.app';
  static const _pollInterval = Duration(seconds: 15);
  double _price = 0.0, _change = 0.0, _high24h = 0.0, _low24h = 0.0;
  bool _marketClosed = false;
  Timer? _timer;

  double get price => _price;
  double get change => _change;
  double get high24h => _high24h;
  double get low24h => _low24h;
  bool get marketClosed => _marketClosed;
  bool get isPositive => _change >= 0;
  // Shows "Loading…" while first fetch is in progress — never empty dash
  String get formattedPrice =>
      _price > 0 ? '\$${_price.toStringAsFixed(2)}' : 'Loading…';
  String get formattedChange =>
      '${isPositive ? '+' : ''}${_change.toStringAsFixed(2)}%';

  static bool isWeekend() {
    final now = DateTime.now().toUtc();
    final wd = now.weekday;
    if (wd == 6 || wd == 7) return true;
    if (wd == 5 && now.hour >= 22) return true;
    if (wd == 1 && now.hour < 1) return true;
    return false;
  }

  PriceService() {
    _init();
  }

  Future<void> _init() async {
    _marketClosed = isWeekend();
    // Always try initial fetch — even on weekend we want last known price
    await _fetchWithRetry();
    if (!_marketClosed) {
      _timer = Timer.periodic(_pollInterval, (_) {
        _marketClosed = isWeekend();
        if (_marketClosed) {
          _timer?.cancel();
          notifyListeners();
        } else {
          fetchPrice();
        }
      });
    }
    notifyListeners();
  }

  // Retry up to 3 times on initial load so we never show "Loading…" forever
  Future<void> _fetchWithRetry() async {
    for (int i = 0; i < 3; i++) {
      await fetchPrice();
      if (_price > 0) return;
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> fetchPrice() async {
    try {
      final res = await http
          .get(Uri.parse('$_serverUrl/price'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final newPrice = (data['price'] as num).toDouble();
        if (newPrice > 0) {
          if (_price > 0) _change = (newPrice - _price) / _price * 100;
          if (_high24h == 0 || newPrice > _high24h) _high24h = newPrice;
          if (_low24h == 0 || newPrice < _low24h) _low24h = newPrice;
          _price = newPrice;
          _marketClosed = isWeekend();
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep last known price on error — never reset to 0
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
