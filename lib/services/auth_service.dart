import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../utils/errors.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  static const Duration _timeout = Duration(seconds: 15);

  GoTrueClient get _auth => _client.auth;

  Session? get currentSession => _auth.currentSession;

  Stream<AuthState> authStateChanges() => _auth.onAuthStateChange;

  String get _redirectUrl =>
      kIsWeb ? '${Uri.base.origin}/' : SupabaseConfig.authRedirectUrl;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth
        .signInWithPassword(email: email.trim(), password: password)
        .timeout(_timeout);
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) async {
    final response = await _auth
        .signUp(
          email: email.trim(),
          password: password,
          emailRedirectTo: _redirectUrl,
          data: {'firstname': firstname.trim(), 'lastname': lastname.trim()},
        )
        .timeout(_timeout);
    final identities = response.user?.identities;
    if (response.session == null && identities != null && identities.isEmpty) {
      throw const AppException(
        'An account with this email already exists. Log in instead.',
      );
    }
    return response.session == null;
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
      queryParams: const {'prompt': 'select_account'},
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
