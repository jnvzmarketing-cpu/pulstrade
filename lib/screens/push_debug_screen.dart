// PUSH NOTIFICATION DEBUG SCREEN
//
// Drop this file into lib/screens/ and add to main.dart routes or
// link from settings screen via:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => PushDebugScreen()));
//
// This screen runs full diagnostic on Firebase Push setup and shows
// detailed status. Send a screenshot to your developer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

class PushDebugScreen extends StatefulWidget {
  const PushDebugScreen({super.key});
  @override
  State<PushDebugScreen> createState() => _PushDebugScreenState();
}

class _PushDebugScreenState extends State<PushDebugScreen> {
  final List<_DebugLine> _lines = [];
  bool _running = false;

  void _log(String msg,
      {bool ok = false, bool error = false, bool warn = false}) {
    setState(() {
      _lines.add(_DebugLine(
        message: msg,
        ok: ok,
        error: error,
        warn: warn,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _running = true;
      _lines.clear();
    });

    _log('═══ Starting Push Debug ═══');
    _log('Platform: ${Platform.operatingSystem}');
    _log('Bundle ID needed: com.pulstrade');

    // 1. Firebase initialized?
    try {
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        _log('❌ Firebase NOT initialized', error: true);
        _running = false;
        setState(() {});
        return;
      }
      _log('Firebase initialized: ${apps.length} app(s)', ok: true);
      _log('   Default app: ${Firebase.app().name}');
      _log('   Project ID: ${Firebase.app().options.projectId}');
      _log('   iOS Bundle: ${Firebase.app().options.iosBundleId ?? 'N/A'}');
    } catch (e) {
      _log('❌ Firebase check failed: $e', error: true);
      _running = false;
      setState(() {});
      return;
    }

    // 2. Permission status
    try {
      _log('───── Permission Check ─────');
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final status = settings.authorizationStatus;
      if (status == AuthorizationStatus.authorized) {
        _log('Permission: AUTHORIZED', ok: true);
      } else if (status == AuthorizationStatus.provisional) {
        _log('Permission: PROVISIONAL', ok: true);
      } else if (status == AuthorizationStatus.denied) {
        _log('❌ Permission: DENIED — User must enable in Settings',
            error: true);
      } else {
        _log('⚠️  Permission: NOT DETERMINED', warn: true);
      }
      _log('   Alert: ${settings.alert}');
      _log('   Badge: ${settings.badge}');
      _log('   Sound: ${settings.sound}');
    } catch (e) {
      _log('❌ Permission request failed: $e', error: true);
    }

    // 3. APNs Token (iOS only) — with retry loop
    if (Platform.isIOS) {
      _log('───── APNs Token (iOS) ─────');
      String? apnsToken;
      int retries = 0;
      const maxRetries = 10;

      while (apnsToken == null && retries < maxRetries) {
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        } catch (e) {
          _log('   APNs error: $e', warn: true);
        }
        if (apnsToken == null) {
          retries++;
          _log('   Retry $retries/$maxRetries — waiting 1s...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (apnsToken == null) {
        _log('❌ APNs Token: NULL after $maxRetries retries', error: true);
        _log('');
        _log('Possible causes:');
        _log('1. Push Notifications capability missing in Xcode');
        _log('2. Background Modes → Remote Notifications not enabled');
        _log('3. APNs Authentication Key not uploaded to Firebase');
        _log('4. Bundle ID mismatch (Xcode ≠ Firebase ≠ Apple Developer)');
        _log('5. Provisioning Profile missing Push Notifications');
        _log('6. App needs full reinstall after capability changes');
        _log('7. Running in Simulator (APNs only works on real device!)');
      } else {
        _log('✅ APNs Token received', ok: true);
        _log('   Length: ${apnsToken.length} chars');
        _log(
            '   Preview: ${apnsToken.substring(0, apnsToken.length > 30 ? 30 : apnsToken.length)}...');
      }
    } else {
      _log('───── APNs Skipped (not iOS) ─────');
    }

    // 4. FCM Token
    _log('───── FCM Token ─────');
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        _log('❌ FCM Token: NULL', error: true);
      } else {
        _log('✅ FCM Token received', ok: true);
        _log('   Length: ${fcmToken.length} chars');
        _log(
            '   Preview: ${fcmToken.substring(0, fcmToken.length > 30 ? 30 : fcmToken.length)}...');
        _log('   Full token copied to clipboard ✓');
        await Clipboard.setData(ClipboardData(text: fcmToken));
      }
    } catch (e) {
      _log('❌ FCM Token error: $e', error: true);
    }

    // 5. Subscribe to topic
    _log('───── Topic Subscription ─────');
    try {
      await FirebaseMessaging.instance.subscribeToTopic('signals');
      _log('✅ Subscribed to topic: signals', ok: true);
      _log('   Note: Topic propagation can take 1-5 minutes');
    } catch (e) {
      _log('❌ Topic subscribe failed: $e', error: true);
    }

    // 6. Foreground presentation options (iOS)
    if (Platform.isIOS) {
      _log('───── Foreground Settings ─────');
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        _log('✅ Foreground presentation: enabled', ok: true);
      } catch (e) {
        _log('❌ Foreground settings failed: $e', error: true);
      }
    }

    // 7. Setup foreground listener
    _log('───── Foreground Listener ─────');
    try {
      FirebaseMessaging.onMessage.listen((message) {
        _log('📬 FOREGROUND MESSAGE RECEIVED', ok: true);
        _log('   Title: ${message.notification?.title}');
        _log('   Body: ${message.notification?.body}');
        _log('   Data: ${message.data}');
      });
      _log('✅ Foreground listener registered', ok: true);
    } catch (e) {
      _log('❌ Listener setup failed: $e', error: true);
    }

    _log('');
    _log('═══ Diagnostic Complete ═══');
    _log('');
    _log('NEXT STEPS:');
    _log('1. Take screenshot of this screen');
    _log('2. Send to developer for review');
    _log('3. Test push from Firebase Console:');
    _log('   - Use copied FCM token (direct test)');
    _log('   - Then test with topic "signals"');

    setState(() => _running = false);
  }

  // ignore: unused_element
  Future<void> _testWithLoopback() async {
    _log('───── Testing local listener ─────');
    _log('Send a test push from Firebase Console now');
    _log('Watch for "📬 FOREGROUND MESSAGE RECEIVED" line');
    _log('Wait time: 30 seconds');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final fg = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Push Debug', style: TextStyle(color: fg)),
        iconTheme: IconThemeData(color: fg),
        actions: [
          if (!_running)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runDiagnostic,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label:
                        Text(_running ? 'Running...' : 'Run Full Diagnostic'),
                    onPressed: _running ? null : _runDiagnostic,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC9A84C),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  color: fg,
                  onPressed: () async {
                    final text = _lines.map((l) => l.message).join('\n');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Log copied to clipboard'),
                            duration: Duration(seconds: 1)),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0A0A0A)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12),
                ),
                padding: const EdgeInsets.all(12),
                child: ListView.builder(
                  itemCount: _lines.length,
                  itemBuilder: (_, i) {
                    final line = _lines[i];
                    Color color = fg;
                    if (line.error) {
                      color = Colors.red;
                    } else if (line.warn) {
                      color = Colors.orange;
                    } else if (line.ok) {
                      color = Colors.green;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        line.message,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'Courier',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugLine {
  final String message;
  final bool ok, error, warn;
  final DateTime timestamp;
  _DebugLine({
    required this.message,
    this.ok = false,
    this.error = false,
    this.warn = false,
    required this.timestamp,
  });
}
