// Auth über Supabase. Apple und Google wie bisher, nur ohne Firebase Auth.
// Kein Gast-Login mehr: Ohne Konto gibt es kein created_at und damit keinen
// 3-Tage-Zugang.

import "dart:convert";
import "dart:math";
import "package:crypto/crypto.dart";
import "package:flutter/foundation.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:sign_in_with_apple/sign_in_with_apple.dart";
import "package:supabase_flutter/supabase_flutter.dart";

class AuthRepo extends ChangeNotifier {
  final _sb = Supabase.instance.client;

  /// iOS-Client-ID aus der Google Cloud Console (die gleiche wie in Info.plist).
  static const googleIosClientId = "3520181018-74m18lv5vrb9i7ue6i8s1bu5geb8qcko.apps.googleusercontent.com";
  /// Web-Client-ID, die in Supabase unter Auth > Providers > Google eingetragen ist.
  static const googleWebClientId = "3520181018-16qpt8io9m39tvotv93g3ckit9bip48f.apps.googleusercontent.com";

  User? get user => _sb.auth.currentUser;
  bool get signedIn => user != null;
  bool get isAnonymous => user?.isAnonymous ?? true;

  /// Kein Login-Zwang: ohne Sitzung wird still ein anonymer Nutzer angelegt.
  Future<void> ensureSession() async {
    if (_sb.auth.currentUser != null) return;
    await _sb.auth.signInAnonymously();
  }

  AuthRepo() {
    _sb.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  /// Gibt null bei Erfolg, sonst eine Meldung für den Nutzer. Abbruch = null.
  Future<String?> signInWithApple() async {
    try {
      final raw = _nonce();
      final hashed = sha256.convert(utf8.encode(raw)).toString();
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashed,
      );
      final idToken = cred.identityToken;
      if (idToken == null) return "Apple hat kein Token geliefert.";
      await _sb.auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: raw);
      final name = [cred.givenName, cred.familyName].where((s) => s != null && s.isNotEmpty).join(" ");
      if (name.isNotEmpty) await _sb.auth.updateUser(UserAttributes(data: {"name": name}));
      return null;
    } on SignInWithAppleAuthorizationException catch (e) {
      return e.code == AuthorizationErrorCode.canceled ? null : "Apple-Login fehlgeschlagen.";
    } catch (e) {
      return "Apple-Login fehlgeschlagen.";
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final g = GoogleSignIn(clientId: googleIosClientId, serverClientId: googleWebClientId, scopes: ["email"]);
      final acc = await g.signIn();
      if (acc == null) return null;
      final auth = await acc.authentication;
      if (auth.idToken == null) return "Google hat kein Token geliefert.";
      await _sb.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: auth.idToken!, accessToken: auth.accessToken);
      return null;
    } catch (e) {
      return "Google-Login fehlgeschlagen.";
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await _sb.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message.contains("Invalid") ? "E-Mail oder Passwort stimmt nicht." : e.message;
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await _sb.auth.signUp(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() => _sb.auth.signOut();

  /// Löschen läuft über die Edge Function delete-account (Service Role).
  Future<String?> deleteAccount() async {
    try {
      await _sb.functions.invoke("delete-account");
      await _sb.auth.signOut();
      return null;
    } catch (e) {
      return "Konto konnte nicht gelöscht werden.";
    }
  }

  String _nonce([int len = 32]) {
    const chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._";
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
