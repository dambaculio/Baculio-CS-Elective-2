import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../theme/design_theme.dart';
import '../../widgets/dialogs.dart';
import 'auth_layout.dart';
import 'google_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _logIn() {
    if (!_formKey.currentState!.validate()) return;
    _run(
      () => ref
          .read(authControllerProvider)
          .signIn(email: _email.text, password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.hasError && mounted) showErrorSnackBar(context, next.error!);
    });

    return AuthScaffold(
      title: 'Welcome Back',
      subtitle: 'Ready to pick your next bloom?',
      highlight: 'Your bouquet is right here.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              style: authFieldTextStyle,
              decoration: authFieldDecoration('Enter email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _logIn(),
              style: authFieldTextStyle,
              decoration: authFieldDecoration(
                'Password',
                suffix: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.mutedText,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Log In',
              loading: _busy,
              onPressed: _busy ? null : _logIn,
            ),
            const SizedBox(height: 36),
            GoogleSignInSection(
              onPressed: _busy
                  ? null
                  : () =>
                        _run(ref.read(authControllerProvider).signInWithGoogle),
            ),
            const SizedBox(height: 28),
            AuthSwitchLink(
              prompt: "Don't have an account? ",
              action: 'Sign Up',
              onTap: _busy ? null : () => context.go('/signup'),
            ),
          ],
        ),
      ),
    );
  }
}
