import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Deep link the Supabase OAuth flow (Google) returns to.
  ///
  /// Must be registered as a redirect URL in the Supabase dashboard and handled
  /// natively via `CFBundleURLTypes` (iOS) / intent-filter (Android).
  static const String oauthRedirectUrl = 'nestroutine://login-callback/';

  Future<AuthResponse> signUp(String email, String password) async {
    return await _auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? get userId => currentUser?.id;

  /// Google sign in through Supabase's hosted OAuth flow.
  ///
  /// Opens the system browser and returns to the app via [oauthRedirectUrl].
  /// The result is NOT returned here: observe [authStateChanges] for the
  /// resulting session.
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: oauthRedirectUrl,
      scopes: 'openid email profile',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Apple sign in.
  ///
  /// On Apple platforms this uses the native AuthenticationServices sheet,
  /// as required by App Store guideline 4.8. On other platforms (Android) it
  /// falls back to Supabase's hosted OAuth flow, which needs the Apple provider
  /// configured in the Supabase dashboard.
  Future<AuthResponse> signInWithApple() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return await _signInWithAppleNative();
    }
    await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    return AuthResponse();
  }

  Future<AuthResponse> _signInWithAppleNative() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw AuthException('No ID Token found.');
    }

    return await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Thrown by [signInWithApple] when the user dismisses Apple's sheet.
  bool isAppleCancellation(Object error) {
    if (error is! SignInWithAppleAuthorizationException) return false;
    return error.code == AuthorizationErrorCode.canceled;
  }

  static String _generateRawNonce() {
    final random = Random.secure();
    return base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
  }
}
