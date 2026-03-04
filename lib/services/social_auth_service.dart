import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthResult {
  final String idToken;
  final String provider;
  final String? displayName;
  final String? email;

  SocialAuthResult({
    required this.idToken,
    required this.provider,
    this.displayName,
    this.email,
  });
}

class SocialAuthService {
  static final _firebaseAuth = firebase_auth.FirebaseAuth.instance;

  static Future<SocialAuthResult?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseIdToken = await userCredential.user?.getIdToken();
    if (firebaseIdToken == null) return null;

    return SocialAuthResult(
      idToken: firebaseIdToken,
      provider: 'google',
      displayName: googleUser.displayName,
      email: googleUser.email,
    );
  }

  static Future<SocialAuthResult?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = firebase_auth.OAuthProvider(
      'apple.com',
    ).credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(
      oauthCredential,
    );
    final firebaseIdToken = await userCredential.user?.getIdToken();
    if (firebaseIdToken == null) return null;

    String? displayName;
    if (appleCredential.givenName != null) {
      displayName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
    }

    return SocialAuthResult(
      idToken: firebaseIdToken,
      provider: 'apple',
      displayName: displayName ?? userCredential.user?.displayName,
      email: appleCredential.email ?? userCredential.user?.email,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
