// Push: FCM-Token in push_tokens registrieren. Firebase bleibt nur dafür.
// Kein Topic-Abo mehr; das Backend filtert nach min_confidence pro Gerät.

import "dart:io";
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class PushRepo {
  final _sb = Supabase.instance.client;
  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  /// Wird mit der Signal-ID aufgerufen, wenn der Nutzer einen Push antippt.
  void Function(int signalId)? onOpenSignal;

  Future<void> init() async {
    await _local.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
      onDidReceiveNotificationResponse: (r) => _open(r.payload),
    );
    // Vordergrund: kurz anzeigen, ohne die App zu unterbrechen
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      _local.show(id: m.hashCode, title: n.title, body: n.body,
          notificationDetails: const NotificationDetails(iOS: DarwinNotificationDetails(presentSound: true), android: AndroidNotificationDetails("signals", "Signale", importance: Importance.high)),
          payload: m.data["signal_id"]);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data["signal_id"]));
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _open(initial.data["signal_id"]);
    _fcm.onTokenRefresh.listen((t) => _save(t));
  }

  /// Erst aufrufen, wenn der Nutzer eingeloggt ist und den Push-Schritt bejaht hat.
  Future<bool> requestAndRegister({int minConfidence = 0}) async {
    final p = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (p.authorizationStatus == AuthorizationStatus.denied) return false;
    if (Platform.isIOS) await _fcm.getAPNSToken();
    final t = await _fcm.getToken();
    if (t == null) return false;
    await _save(t, minConfidence: minConfidence);
    return true;
  }

  Future<void> _save(String token, {int? minConfidence}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    final row = {
      "token": token, "user_id": uid, "platform": Platform.isIOS ? "ios" : "android",
      "updated_at": DateTime.now().toUtc().toIso8601String(),
      if (minConfidence != null) "min_confidence": minConfidence,
    };
    try { await _sb.from("push_tokens").upsert(row); } catch (e) { debugPrint("push_tokens: $e"); }
  }

  Future<void> setMinConfidence(int v) async {
    final t = await _fcm.getToken();
    if (t != null) await _save(t, minConfidence: v);
  }

  Future<void> unregister() async {
    final t = await _fcm.getToken();
    if (t != null) await _sb.from("push_tokens").delete().eq("token", t);
  }

  void _open(String? id) {
    final n = int.tryParse(id ?? "");
    if (n != null) onOpenSignal?.call(n);
  }
}
