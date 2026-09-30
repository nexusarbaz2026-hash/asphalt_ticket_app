import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimal email/password auth. Firestore security rules only allow
/// signed-in users to read/write, so every desktop/web/phone that uses
/// this app needs a login — create accounts for your staff from the
/// Firebase console (Authentication -> Users -> Add user), or wire up
/// a sign-up screen later if you want self-service accounts.
class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign-in failed';
    }
  }

  Future<void> signOut() => _auth.signOut();
}
