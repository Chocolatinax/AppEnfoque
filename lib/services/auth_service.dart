import 'package:flutter/widgets.dart';

class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? photoUrl;

  const AppUser({required this.uid, this.name, this.email, this.photoUrl});

  String? get firstName {
    final n = name?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(' ').first;
  }
}

class SignInCanceled implements Exception {
  const SignInCanceled();
}

abstract class AuthService extends ChangeNotifier {
  AppUser? get currentUser;

  bool get isSignedIn => currentUser != null;

  /// Lanza [SignInCanceled] si el usuario cierra la ventana de Google.
  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteAccount();
}

class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService service,
    required super.child,
  }) : super(notifier: service);

  static AuthService? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;

  static AuthService? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AuthScope>()?.notifier;
}
