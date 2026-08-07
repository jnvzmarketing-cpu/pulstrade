import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_redemption.dart';

WebRedemptionService? _pulstradeRedemption;

class SubscriptionService extends ChangeNotifier {
  static final _revenueCatKey = Platform.isIOS
      ? 'appl_khbMUarlkrbqHiHpmsBoaCBhbpT'
      : 'goog_tJwKrhkkUCqZlRQbjFHchDIXDRy';

  static const int freeSignalLimit = 10;

  bool _isPro = false;
  bool _isTrial = false;
  int _signalsViewed = 0;
  bool _loading = false;

  Package? _monthly;
  Package? _annual;

  bool get isPro => _isPro || _isTrial;
  bool get isFree => !isPro;
  bool get isLoading => _loading;
  int get signalsViewed => _signalsViewed;
  int get freeSignalsLeft =>
      (freeSignalLimit - _signalsViewed).clamp(0, freeSignalLimit);
  bool get isLocked => isFree && _signalsViewed >= freeSignalLimit;

  // ── Dynamic pricing (never hardcode prices in UI) ──────────────────
  Package? get monthlyPackage => _monthly;
  Package? get annualPackage => _annual;

  String? get monthlyPriceString => _monthly?.storeProduct.priceString;
  String? get annualPriceString => _annual?.storeProduct.priceString;

  /// Per-day price of the annual plan, formatted with the store currency.
  String? get annualPerDayString {
    final p = _annual?.storeProduct;
    if (p == null) return null;
    final perDay = p.price / 365.0;
    final symbol = p.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${perDay.toStringAsFixed(2)}';
  }

  bool canViewSignal(int i) {
    if (isPro) return true;
    return _signalsViewed < freeSignalLimit;
  }

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _signalsViewed = p.getInt('signals_viewed') ?? 0;

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final config = PurchasesConfiguration(_revenueCatKey);
      await Purchases.configure(config);
      _pulstradeRedemption = WebRedemptionService(
        onSuccess: (info) async {
          await _checkSubscription(); // _isPro neu setzen
          notifyListeners(); // Pro greift sofort, ohne Neustart
        },
        onFailure: (msg) => debugPrint('Redemption: $msg'),
      );
      await _pulstradeRedemption!.start();
      await _checkSubscription();
      await _loadOfferings();
    } catch (_) {}

    notifyListeners();
  }

  /// Bind RevenueCat identity to the app's Firebase UID.
  Future<void> logIn(String uid) async {
    try {
      await Purchases.logIn(uid);
      await _checkSubscription();
      await _loadOfferings();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      await _checkSubscription();
    } catch (_) {}
    notifyListeners();
  }

  /// Bind RevenueCat identity to the app's Firebase UID.
  Future<void> _checkSubscription() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final ent = info.entitlements.active['pulstrade_pro'];
      _isPro = ent != null;
      _isTrial = ent?.periodType == PeriodType.trial;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return;
      _monthly = current.monthly ??
          current.availablePackages
              .where((p) => p.packageType == PackageType.monthly)
              .firstOrNull;
      _annual = current.annual ??
          current.availablePackages
              .where((p) => p.packageType == PackageType.annual)
              .firstOrNull;
      notifyListeners();
    } catch (e) {
      debugPrint('offerings load failed: $e');
    }
  }

  /// Purchase a specific package (annual or monthly).
  Future<String?> purchase(Package package) async {
    _loading = true;
    notifyListeners();
    try {
      final info = await Purchases.purchasePackage(package);
      final ent = info.customerInfo.entitlements.active['pulstrade_pro'];
      _isPro = ent != null;
      _isTrial = ent?.periodType == PeriodType.trial;
      _loading = false;
      notifyListeners();
      return null;
    } on PurchasesErrorCode catch (e) {
      _loading = false;
      notifyListeners();
      return _mapError(e);
    } on PlatformException catch (e) {
      _loading = false;
      notifyListeners();
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return 'cancelled';
      return 'Purchase error: ${e.message ?? 'unknown'}';
    } catch (e) {
      _loading = false;
      notifyListeners();
      final s = e.toString();
      return 'Purchase failed: ${s.substring(0, s.length > 80 ? 80 : s.length)}';
    }
  }

  /// Legacy entry point — purchases the monthly plan (kept for old call sites).
  Future<String?> startTrial() async {
    if (_monthly == null && _annual == null) {
      await _loadOfferings();
    }
    final pkg = _annual ?? _monthly;
    if (pkg == null) {
      return 'Subscriptions not configured yet. Please try again later or contact support.';
    }
    return purchase(pkg);
  }

  String _mapError(PurchasesErrorCode e) {
    switch (e) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'cancelled';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchase not allowed. Check your Apple ID restrictions.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment pending. Please wait for confirmation.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Subscription not yet available. Please try again later.';
      case PurchasesErrorCode.networkError:
        return 'No internet connection. Please check and try again.';
      case PurchasesErrorCode.storeProblemError:
        return 'App Store unavailable. Please try again later.';
      default:
        return 'Purchase failed (${e.toString().split('.').last}). Try again.';
    }
  }

  Future<void> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _isPro = info.entitlements.active.containsKey('pulstrade_pro');
      notifyListeners();
    } catch (_) {}
  }

  void recordSignalView() async {
    if (isFree) {
      _signalsViewed++;
      final p = await SharedPreferences.getInstance();
      await p.setInt('signals_viewed', _signalsViewed);
      notifyListeners();
    }
  }

  double get minConfidence => 65.0;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
