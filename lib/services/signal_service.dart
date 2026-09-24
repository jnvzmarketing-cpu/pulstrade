import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/signal.dart';

class SignalService extends ChangeNotifier {
  static const _serverUrl =
      'https://pulstrade-backend-production.up.railway.app';
  static const _pollInterval = Duration(seconds: 15);
  static const _maxPriceDeviation = 0.02; // 2% max deviation from live price
  static const _maxSignalAgeHours = 24;

  List<Signal> _signals = [];
  bool _isLoading = false;
  bool _demoMode = false;
  DateTime? _lastUpdated;
  Timer? _timer;
  double? _livePrice; // set externally from PriceService

  List<Signal> get signals => _signals;
  bool get isLoading => _isLoading;
  bool get demoMode => _demoMode;
  DateTime? get lastUpdated => _lastUpdated;

  SignalService() {
    _init();
  }

  /// Call this from main.dart whenever PriceService updates to enable filtering
  void updateLivePrice(double price) {
    _livePrice = price;
  }

  Future<void> _init() async {
    await fetchSignals();
    _timer = Timer.periodic(_pollInterval, (_) => fetchSignals());
  }

  Future<void> fetchSignals() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('$_serverUrl/signals?limit=20'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        final parsed = data
            .map((j) => Signal.fromJson(Map<String, dynamic>.from(j)))
            .toList();
        _signals = _filterValid(parsed);
        _demoMode = false;
        _lastUpdated = DateTime.now();
      }
    } catch (_) {
      // No fake fallback data — UI shows its empty/offline state instead.
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── FILTER: drop stale or wrong-price signals ────────────────
  List<Signal> _filterValid(List<Signal> raw) {
    final now = DateTime.now();
    return raw.where((s) {
      // Drop if older than 24h
      final age = now.difference(s.timestamp).inHours;
      if (age > _maxSignalAgeHours) {
        debugPrint('⚠️ Dropped old signal #${s.id} age=${age}h');
        return false;
      }

      // Drop if price deviates > 2% from live price (stale/wrong data)
      if (_livePrice != null && _livePrice! > 0) {
        final deviation = (s.price - _livePrice!).abs() / _livePrice!;
        if (deviation > _maxPriceDeviation) {
          debugPrint(
              '⚠️ Dropped stale signal #${s.id} price=${s.price} live=$_livePrice deviation=${(deviation * 100).toStringAsFixed(1)}%');
          return false;
        }
      }

      return true;
    }).toList();
  }

  void setServerUrl(String url) => fetchSignals();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

extension SignalServiceExt on SignalService {
  List<Signal> get buySignals => signals.where((s) => s.isBuy).toList();
  List<Signal> get sellSignals => signals.where((s) => s.isSell).toList();
}
