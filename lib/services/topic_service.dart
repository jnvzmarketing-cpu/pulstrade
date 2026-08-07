// ════════════════════════════════════════════════════════════════════
// TOPIC SERVICE — keeps FCM topic subscriptions in sync with the
// user's profile. The backend publishes each signal only to the
// matching topics, so users receive exactly the pushes their
// onboarding answers asked for.
//
// Topic scheme (must match backend, see BACKEND_SPEC.md):
//   sig_limit_cons | sig_limit_mode | sig_limit_aggr   (Sniper)
//   sig_market_cons | sig_market_mode | sig_market_aggr (Executor)
//   session_tokyo | session_london | session_ny | session_all
//   signals  ← legacy catch-all, kept until backend v2 is live
// ════════════════════════════════════════════════════════════════════

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class TopicService {
  static const _kStoredTopics = 'fcm_subscribed_topics';

  /// Keep the legacy topic alive until the backend publishes per-topic.
  /// Flip to false in the release that ships together with backend v2.
  static const bool keepLegacyTopic = true;

  /// Re-sync subscriptions: unsubscribe everything we subscribed before,
  /// then subscribe to the profile's current topic set.
  static Future<void> sync(UserProfile profile) async {
    final fcm = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getStringList(_kStoredTopics) ?? [];
    final target = <String>{
      ...profile.fcmTopics,
      if (keepLegacyTopic) 'signals',
    };

    for (final t in previous) {
      if (!target.contains(t)) {
        try {
          await fcm.unsubscribeFromTopic(t);
          debugPrint('🔕 unsubscribed: $t');
        } catch (e) {
          debugPrint('topic unsubscribe failed ($t): $e');
        }
      }
    }

    for (final t in target) {
      try {
        await fcm.subscribeToTopic(t);
        debugPrint('🔔 subscribed: $t');
      } catch (e) {
        debugPrint('topic subscribe failed ($t): $e');
      }
    }

    await prefs.setStringList(_kStoredTopics, target.toList());
  }
}
