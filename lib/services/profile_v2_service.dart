import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import 'topic_service.dart';

/// App-wide holder for the v2 user profile (built by the onboarding quiz).
/// Saving a new profile automatically re-syncs FCM topics.
class ProfileV2Service extends ChangeNotifier {
  UserProfile _profile = const UserProfile();
  bool _loaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _loaded;

  Future<void> init() async {
    _profile = await UserProfile.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(UserProfile next, {bool syncTopics = true}) async {
    _profile = next;
    notifyListeners();
    await next.save();
    if (syncTopics) {
      await TopicService.sync(next);
    }
  }
}
