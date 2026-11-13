import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 15);

  AuthProvider({GoTrueClient? auth})
    : _auth = auth ?? Supabase.instance.client.auth {
    _session = _auth.currentSession;
    _subscription = _auth.onAuthStateChange.listen(
      (data) {
        _session = data.session;
        notifyListeners();
      },
      onError: (Object error) {
        _lastError = error is AuthException ? error.message : '$error';
        notifyListeners();
      },
    );
  }

  final GoTrueClient _auth;
  late final StreamSubscription<AuthState> _subscription;

  Session? _session;
  String? _lastError;

  bool get isSignedIn => _session != null;
  User? get user => _session?.user;
  String? get email => user?.email;
  String? get signInMethod => user?.appMetadata['provider'] as String?;

  String? takeLastError() {
    final e = _lastError;
    _lastError = null;
    return e;
  }

  String get _redirectUrl =>
      kIsWeb ? '${Uri.base.origin}/' : SupabaseConfig.authRedirectUrl;

  Future<void> signInWithEmail(String email, String password) async {
    await _auth
        .signInWithPassword(email: email.trim(), password: password)
        .timeout(_timeout);
  }

  Future<bool> signUpWithEmail(String email, String password) async {
    final response = await _auth
        .signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: _redirectUrl,
        )
        .timeout(_timeout);
    return response.session == null;
  }

  Future<void> signInWithGitHub() async {
    await _auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: _redirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
