import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Fängt rc-8b329af558:// Redemption-Links ab und löst den Web-Kauf ein.
/// WICHTIG: erst start() aufrufen, NACHDEM Purchases.configure(...) gelaufen ist.
class WebRedemptionService {
  final AppLinks _appLinks = AppLinks();
  final void Function(CustomerInfo info)? onSuccess;
  final void Function(String message)? onFailure;

  WebRedemptionService({this.onSuccess, this.onFailure});

  Future<void> start() async {
    final Uri? initial = await _appLinks.getInitialLink();
    if (initial != null) {
      await _handle(initial.toString());
    }
    _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri.toString()),
      onError: (e) => debugPrint('app_links error: $e'),
    );
  }

  Future<void> _handle(String url) async {
    try {
      final WebPurchaseRedemption? redemption =
          await Purchases.parseAsWebPurchaseRedemption(url);
      if (redemption == null) return; // kein RevenueCat-Redemption-Link

      // Einlösen. Rückgabetyp variiert je SDK-Version -> Erfolg ueber Entitlement pruefen.
      await Purchases.redeemWebPurchase(redemption);

      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active.containsKey('pulstrade_pro')) {
        debugPrint('Redeem OK - pro aktiv: true');
        onSuccess?.call(info);
      } else {
        debugPrint('Redeem: pulstrade_pro NICHT aktiv (Token ungueltig/abgelaufen?)');
        onFailure?.call('Aktivierung nicht abgeschlossen. Link evtl. ungueltig oder abgelaufen.');
      }
    } catch (e) {
      debugPrint('redeem exception: $e');
      onFailure?.call('Aktivierung fehlgeschlagen.');
    }
  }
}
