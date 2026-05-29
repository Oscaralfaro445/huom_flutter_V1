import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<void> signInAnonymously() async {
    if (_auth.currentUser != null) return;
    try {
      await _auth.signInAnonymously();
    } catch (_) {
      // Auth is optional — app works offline
    }
  }

  String? get userId => _auth.currentUser?.uid;

  bool get isAuthenticated => _auth.currentUser != null;
}
