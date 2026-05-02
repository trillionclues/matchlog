library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final result =
        await ref.read(authControllerProvider.notifier).signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
    _showError(result);
  }

  Future<void> _submitGoogleLogin() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    _showError(result);
  }

  Future<void> _submitAppleLogin() async {
    // TODO: Implement Apple Sign-In via FirebaseAuthSource
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In coming soon.')),
    );
  }

  void _showError(AuthActionResult result) {
    if (!mounted || result.isSuccess || result.isCancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Authentication failed.')),
    );
  }

  Future<void> _previewOnboarding() async {
    await ref.read(authControllerProvider.notifier).resetOnboarding();
    if (!mounted) {
      return;
    }
    context.go(Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return AuthForm(
      formKey: _formKey,
      title: 'Welcome Back',
      subtitle:
          'Stay connected by signing in with your email and password to access your account.',
      submitLabel: 'Sign In',
      onSubmit: _submitEmailLogin,
      isLoading: isLoading,
      socialActions: [
        SocialLoginRow(
          onGooglePressed: _submitGoogleLogin,
          onApplePressed: _submitAppleLogin,
          isLoading: isLoading,
        ),
      ],
      fields: [
        const AuthFieldLabel('Email Address'),
        MatchLogSpacing.gapXs,
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(hintText: 'you@example.com'),
          validator: Validators.email,
          enabled: !isLoading,
        ),
        MatchLogSpacing.gapLg,
        const AuthFieldLabel('Password'),
        MatchLogSpacing.gapXs,
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: 'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: Validators.required,
          enabled: !isLoading,
        ),
      ],
      footer: AuthSwitchFooter(
        question: "Don't have an account?",
        actionLabel: 'Sign Up',
        onTap: isLoading ? null : () => context.go(Routes.register),
      ),
      // auxiliaryFooter: kDebugMode
      //     ? TextButton(
      //         onPressed: isLoading ? null : _previewOnboarding,
      //         child: const Text('Replay Onboarding'),
      //       )
      //     : null,
    );
  }
}
