import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/design_theme.dart';
import 'auth_layout.dart';

class GoogleSignInSection extends StatelessWidget {
  const GoogleSignInSection({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DividerLabel(text: 'Sign in with'),
        const SizedBox(height: 18),
        Center(
          child: SocialButton(
            tooltip: 'Continue with Google',
            icon: SvgPicture.asset(
              'assets/images/google_mark.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.textColor,
                BlendMode.srcIn,
              ),
            ),
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}
