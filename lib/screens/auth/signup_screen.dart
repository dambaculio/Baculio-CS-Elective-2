import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../theme/design_theme.dart';
import '../../widgets/dialogs.dart';
import 'auth_layout.dart';
import 'google_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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

  void _signUp() {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    _run(() async {
      final needsConfirmation = await ref
          .read(authControllerProvider)
          .signUp(
            email: email,
            password: _password.text,
            firstname: _firstname.text,
            lastname: _lastname.text,
          );
      if (!mounted || !needsConfirmation) return;
      showAppSnackBar(
        context,
        'Account created! Check $email for a confirmation link, then log in.',
      );
      context.go('/login');
    });
  }

  String? _required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    final eye = IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: AppColors.mutedText,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return AuthScaffold(
      title: 'Create Account',
      subtitle: 'Join us and start your flower collection.',
      highlight: 'Handmade crochet blooms await.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstname,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    style: authFieldTextStyle,
                    decoration: authFieldDecoration('First name'),
                    validator: (v) => _required(v, 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastname,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    textInputAction: TextInputAction.next,
                    style: authFieldTextStyle,
                    decoration: authFieldDecoration('Last name'),
                    validator: (v) => _required(v, 'Last name'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.next,
              style: authFieldTextStyle,
              decoration: authFieldDecoration('Password', suffix: eye),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUp(),
              style: authFieldTextStyle,
              decoration: authFieldDecoration('Confirm password'),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Create Account',
              loading: _busy,
              onPressed: _busy ? null : _signUp,
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
              prompt: 'Already have an account? ',
              action: 'Log In',
              onTap: _busy ? null : () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
