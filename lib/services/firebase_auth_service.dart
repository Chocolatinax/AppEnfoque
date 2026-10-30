import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Inicio de sesión con Google usando el flujo propio de Firebase Auth
/// (ventana del navegador dentro de la app), sin el paquete google_sign_in:
/// en iOS ese paquete choca de versiones con Firebase.
class FirebaseAuthService extends AuthService {
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _sub;

  FirebaseAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance {
    _sub = _auth.authStateChanges().listen((_) => notifyListeners());
  }

  GoogleAuthProvider get _provider =>
      GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return AppUser(
      uid: u.uid,
      name: u.displayName,
      email: u.email,
      photoUrl: u.photoURL,
    );
  }

  bool _isCancel(FirebaseAuthException e) =>
      e.code.contains('cancel') || e.code == 'web-context-canceled';

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      await _auth.signInWithProvider(_provider);
    } on FirebaseAuthException catch (e) {
      if (_isCancel(e)) throw const SignInCanceled();
      rethrow;
    }
    notifyListeners();
    return currentUser!;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      // Firebase pide haber iniciado sesión hace poco para borrar la cuenta
      if (e.code != 'requires-recent-login') rethrow;
      try {
        await user.reauthenticateWithProvider(_provider);
      } on FirebaseAuthException catch (e) {
        if (_isCancel(e)) throw const SignInCanceled();
        rethrow;
      }
      await user.delete();
    }
    await signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
