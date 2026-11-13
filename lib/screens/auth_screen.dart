import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../providers/auth_provider.dart';
import '../theme/design_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const double _headerHeight = 300;
  static const double _cardOverlap = 36;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;
  bool _obscure = true;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _auth.addListener(_showStreamError);
  }

  @override
  void dispose() {
    _auth.removeListener(_showStreamError);
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _showStreamError() {
    final error = _auth.takeLastError();
    if (error != null && mounted) _showMessage(error, isError: true);
  }

  void _showMessage(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _run(Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message, isError: true);
    } on TimeoutException {
      if (mounted) {
        _showMessage(
          'The request timed out. Check your connection and try again.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) _showMessage('Something went wrong: $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text;
    final password = _password.text;

    if (_isSignUp) {
      await _run(() async {
        final needsConfirmation = await _auth.signUpWithEmail(email, password);
        if (!mounted) return;
        if (needsConfirmation) {
          _showMessage(
            'Account created! Check $email for a confirmation link, '
            'then log in.',
          );
          setState(() {
            _isSignUp = false;
            _confirm.clear();
          });
        }
      });
    } else {
      await _run(() => _auth.signInWithEmail(email, password));
    }
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    setState(() {
      _isSignUp = !_isSignUp;
      _confirm.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesignTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Stack(
                children: [
                  const _Header(height: _headerHeight),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: _headerHeight - _cardOverlap,
                    ),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            _headerHeight +
                            _cardOverlap,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                            child: _buildForm(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignUp ? 'Create Account' : 'Welcome Back',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _isSignUp
                ? 'Join us and start your flower collection.'
                : 'Ready to pick your next bloom?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
          const SizedBox(height: 2),
          Text(
            _isSignUp
                ? 'Handmade crochet blooms await.'
                : 'Your bouquet is right here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _email,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, color: AppColors.textColor),
            decoration: _fieldDecoration('Enter email'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscure,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: _isSignUp
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isSignUp) _submitEmail();
            },
            style: const TextStyle(fontSize: 14, color: AppColors.textColor),
            decoration: _fieldDecoration(
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (_isSignUp && v.length < 6) {
                return 'Use at least 6 characters';
              }
              return null;
            },
          ),

          if (_isSignUp) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitEmail(),
              style: const TextStyle(fontSize: 14, color: AppColors.textColor),
              decoration: _fieldDecoration('Confirm password'),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match' : null,
            ),
          ],
          const SizedBox(height: 28),

          _GradientButton(
            label: _isSignUp ? 'Create Account' : 'Log In',
            loading: _busy,
            onPressed: _busy ? null : _submitEmail,
          ),
          const SizedBox(height: 36),

          const _DividerLabel(text: 'Sign in with'),
          const SizedBox(height: 18),
          Center(
            child: _SocialButton(
              tooltip: 'Continue with GitHub',
              icon: SvgPicture.asset(
                'assets/images/github_mark.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  AppColors.textColor,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: _busy ? null : () => _run(_auth.signInWithGitHub),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp
                    ? 'Already have an account? '
                    : "Don't have an account? ",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textColor,
                ),
              ),
              GestureDetector(
                onTap: _busy ? null : _toggleMode,
                child: Text(
                  _isSignUp ? 'Log In' : 'Sign Up',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hotPink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffix}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.mutedText),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      suffixIcon: suffix,
      border: border(AppColors.subtleBorder),
      enabledBorder: border(AppColors.subtleBorder),
      disabledBorder: border(AppColors.subtleBorder),
      focusedBorder: border(AppColors.hotPink, 1.2),
      errorBorder: border(Colors.red.shade200),
      focusedErrorBorder: border(Colors.red.shade400, 1.2),
    );
  }
}

class _Header extends StatelessWidget {
  final double height;

  const _Header({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppColors.lightPink, AppColors.pink],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _ArcLinesPainter(),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo_color.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Shai's Creation",
                    style: DesignTheme.logoStyle.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArcLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.hotPink.withValues(alpha: 0.12);
    final center = Offset(size.width * 1.1, -size.height * 0.15);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    for (double r = 40; r < maxRadius * 1.3; r += 14) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: onPressed == null && !loading ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.pink, AppColors.hotPink],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.hotPink.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: SizedBox(
              height: 54,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String text;

  const _DividerLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: AppColors.subtleBorder, thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
          ),
        ),
        line,
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.subtleBorder),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(width: 54, height: 54, child: Center(child: icon)),
          ),
        ),
      ),
    );
  }
}
