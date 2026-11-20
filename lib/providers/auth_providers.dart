import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'service_providers.dart';

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.hasValue) return authState.value!.session;
  return ref.watch(authServiceProvider).currentSession;
});

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider)?.user.id,
);

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileServiceProvider).fetchProfile(userId);
}, retry: (_, _) => null);

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(currentProfileProvider).value?.isAdmin ?? false,
);

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> signIn({required String email, required String password}) => _ref
      .read(authServiceProvider)
      .signInWithEmail(email: email, password: password);

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
  }) => _ref
      .read(authServiceProvider)
      .signUpWithEmail(
        email: email,
        password: password,
        firstname: firstname,
        lastname: lastname,
      );

  Future<void> signInWithGoogle() =>
      _ref.read(authServiceProvider).signInWithGoogle();

  Future<void> signOut() => _ref.read(authServiceProvider).signOut();
}

final authControllerProvider = Provider<AuthController>(
  (ref) => AuthController(ref),
);
