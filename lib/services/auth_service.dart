// ignore_for_file: unused_field

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AuthService extends ChangeNotifier {
  static const googleProviderClientId =
      '3520181018-16qpt8io9m39tvotv93g3ckit9bip48f.apps.googleusercontent.com';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.uid;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.displayName;

  AuthService() {
    // Listen for auth state changes
    _auth.authStateChanges().listen((user) {
      _wasLoggedIn = user != null;
      notifyListeners();
    });

    // Listen for ID token changes (refreshes every hour)
    // This prevents auto-logout when tokens expire
    _auth.idTokenChanges().listen((user) {
      if (user != null) {
        // Force-refresh ID token to keep session alive
        user.getIdToken(false).catchError((e) {
          debugPrint('⚠️ Token refresh failed: $e');
          return null;
        });
      }
    });
  }

  bool _wasLoggedIn = false;

  /// Validates the current session — call after app foreground/launch
  Future<bool> validateSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.getIdToken(true);
      return true;
    } catch (e) {
      debugPrint('⚠️ Session validation failed: $e');
      return false;
    }
  }

  // ── Sign in with Google (DISABLED — using Apple Sign In only) ──
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser =
          //await GoogleSignIn(clientId: googleProviderClientId).signIn();
          await GoogleSignIn().signIn();
      if (gUser == null) return null;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential googleCredential =
          await _auth.signInWithCredential(credential);

      // Save to Firestore if new user
      final doc =
          await _db.collection('users').doc(googleCredential.user!.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(googleCredential.user!.uid).set({
          'name': googleCredential.user!.displayName ?? 'Pulstrade User',
          'email': googleCredential.user!.email ?? '',
          'subscriptionStatus': 'trial',
          'trialStartedAt': FieldValue.serverTimestamp(),
          'signalsViewed': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'apple',
        });
      }

      notifyListeners();
      return null;
    } catch (e) {
      if (e.toString().contains('canceled')) return 'cancelled';
      return 'Sign in failed. Please try again.';
    }
  }

  // ── Sign in with Apple ────────────────────────────────────────────────────
  Future<String?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);

      final String clientID = 'com.pulstrade.service';
      final String redirectURL =
          'https://pulstrade-fb01a.firebaseapp.com/__/auth/handler';

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        /// Scopes are the values that you are requiring from
        /// Apple Server.
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: Platform.isIOS ? nonce : null,

        /// We are providing Web Authentication for Android Login,
        /// Android uses web browser based login for Apple.
        webAuthenticationOptions: Platform.isIOS
            ? null
            : WebAuthenticationOptions(
                clientId: clientID,
                redirectUri: Uri.parse(redirectURL),
              ),
      );
      final AuthCredential appleAuthCredential =
          OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: Platform.isIOS ? rawNonce : null,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _auth.signInWithCredential(appleAuthCredential);
      final user = userCredential.user!;

      // Save to Firestore if new user
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final name = [appleCredential.givenName, appleCredential.familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');
        await _db.collection('users').doc(user.uid).set({
          'name': name.isEmpty ? 'Pulstrade User' : name,
          'email': user.email ?? appleCredential.email ?? '',
          'subscriptionStatus': 'trial',
          'trialStartedAt': FieldValue.serverTimestamp(),
          'signalsViewed': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'apple',
        });
      }

      notifyListeners();
      return null;
    } catch (e) {
      if (e.toString().contains('canceled')) return 'cancelled';
      return 'Sign in failed. Please try again.';
    }
  }

  // ── Email/Password ────────────────────────────────────────────────────────
  Future<String?> register(String email, String password, String name) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'subscriptionStatus': 'trial',
        'trialStartedAt': FieldValue.serverTimestamp(),
        'signalsViewed': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'email',
      });
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(e.stackTrace.toString());
      return _errorMessage(e.code);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await _auth.signOut();
    await _db.collection('users').doc(_auth.currentUser!.uid).delete();
    await _auth.currentUser?.delete();
    notifyListeners();
  }

  // ── Subscription ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData() async {
    if (userId == null) return null;
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateSubscription(String status) async {
    if (userId == null) return;
    await _db.collection('users').doc(userId).update({
      'subscriptionStatus': status,
      'subscribedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<bool> isSubscribed() async {
    final data = await getUserData();
    return data?['subscriptionStatus'] == 'pro' ||
        data?['subscriptionStatus'] == 'trial';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _generateNonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password too weak (min 6 chars)';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Something went wrong. Try again';
    }
  }

  // ── Sign in local ────────────────────────────────────────────────────

  static Future<AuthResult?> fallbackLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString('user_id', userId);
    await prefs.setBool('is_logged_in', true);
    return AuthResult(userId: userId, name: 'Investor', email: '');
  }

  static Future<void> signOutLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.setBool('is_logged_in', false);
  }

  static Future<bool> isLoggedInLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}

class AuthResult {
  final String userId;
  final String name;
  final String email;
  const AuthResult(
      {required this.userId, required this.name, required this.email});
}
