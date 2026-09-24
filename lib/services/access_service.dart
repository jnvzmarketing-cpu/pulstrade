// Zugangsmodell Pulstrade
//   Tag 0 bis 3 nach Registrierung: voller Zugriff, keine Karte.
//   Danach: Free sieht jedes Signal als Struktur (Richtung, Timeframe, Zeit,
//   Ergebnis), Entry/SL/TP sind verdeckt. Pro (RevenueCat "pulstrade_pro")
//   sieht alles.
//
// Der Startzeitpunkt liegt in Supabase (auth.users.created_at), nicht in
// SharedPreferences, damit Neuinstallation den Zugang nicht zurücksetzt.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum Access { full, pro, locked }

class AccessService extends ChangeNotifier {
  static const _entitlement = 'pulstrade_pro';
  static const fullAccessDays = 3;
  static final _rcKey = Platform.isIOS
      ? 'appl_khbMUarlkrbqHiHpmsBoaCBhbpT'
      : 'goog_tJwKrhkkUCqZlRQbjFHchDIXDRy';

  bool _pro = false;
  DateTime? _signupAt;
  Package? monthly, annual;
  bool purchasing = false;

  bool get isPro => _pro;
  DateTime? get fullAccessEnds =>
      _signupAt?.add(const Duration(days: fullAccessDays));
  bool get inFullAccess =>
      fullAccessEnds != null && DateTime.now().isBefore(fullAccessEnds!);
  Duration get fullAccessLeft =>
      inFullAccess ? fullAccessEnds!.difference(DateTime.now()) : Duration.zero;

  Access get access => _pro
      ? Access.pro
      : inFullAccess
          ? Access.full
          : Access.locked;

  /// Level (Entry/SL/TP) sichtbar?
  bool get canSeeLevels => access != Access.locked;

  Future<void> init() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) _signupAt = DateTime.tryParse(user.createdAt);

    try {
      await Purchases.configure(PurchasesConfiguration(_rcKey));
      if (user != null) await Purchases.logIn(user.id);
      await _refresh();
      final off = await Purchases.getOfferings();
      monthly = off.current?.monthly;
      annual = off.current?.annual;
    } catch (e) {
      debugPrint('RevenueCat: $e');
    }
    Purchases.addCustomerInfoUpdateListener((info) {
      _pro = info.entitlements.active.containsKey(_entitlement);
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _refresh() async {
    final info = await Purchases.getCustomerInfo();
    _pro = info.entitlements.active.containsKey(_entitlement);
  }

  /// Ersparnis Jahr gegenüber 12 Monaten, in Store-Währung formatiert.
  String? get annualSavings {
    final m = monthly?.storeProduct, a = annual?.storeProduct;
    if (m == null || a == null) return null;
    final diff = m.price * 12 - a.price;
    if (diff <= 0) return null;
    final symbol = a.priceString.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${diff.round()}';
  }

  /// Gibt null bei Erfolg, sonst eine kurze Fehlermeldung. Abbruch = null.
  Future<String?> purchase(Package pkg) async {
    purchasing = true;
    notifyListeners();
    try {
      final info = (await Purchases.purchase(PurchaseParams.package(pkg))).customerInfo;
      _pro = info.entitlements.active.containsKey(_entitlement);
      return _pro ? null : 'Kauf nicht bestätigt. Bitte nochmal versuchen.';
    } on PurchasesErrorCode catch (_) {
      return 'Kauf fehlgeschlagen.';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PURCHASE_CANCELLED')) return null;
      return 'Kauf fehlgeschlagen. Bitte nochmal versuchen.';
    } finally {
      purchasing = false;
      notifyListeners();
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      _pro = info.entitlements.active.containsKey(_entitlement);
      notifyListeners();
      return _pro;
    } catch (_) {
      return false;
    }
  }
}
