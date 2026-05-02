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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final result =
        await ref.read(authControllerProvider.notifier).signUpWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _displayNameController.text.trim(),
            );
    if (!mounted || result.isSuccess || result.isCancelled) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Unable to create account.')),
    );
  }

  Future<void> _submitGoogleLogin() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
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
      title: 'Create Account',
      subtitle: 'Join now to start logging your sports journey.',
      submitLabel: 'Create Account',
      onSubmit: _submit,
      isLoading: isLoading,
      socialActions: [
        SocialLoginButton(
          onPressed: _submitGoogleLogin,
          isLoading: isLoading,
        ),
      ],
      fields: [
        const AuthFieldLabel('Name'),
        MatchLogSpacing.gapXs,
        TextFormField(
          controller: _displayNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
          validator: Validators.displayName,
          enabled: !isLoading,
        ),
        MatchLogSpacing.gapLg,
        const AuthFieldLabel('Email'),
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
          autofillHints: const [AutofillHints.newPassword],
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
          validator: Validators.password,
          enabled: !isLoading,
        ),
      ],
      footer: AuthSwitchFooter(
        question: 'Already have an account?',
        actionLabel: 'Log in',
        onTap: isLoading ? null : () => context.go(Routes.login),
      ),
      auxiliaryFooter: kDebugMode
          ? TextButton(
              onPressed: isLoading ? null : _previewOnboarding,
              child: const Text('Replay onboarding'),
            )
          : null,
    );
  }
}
