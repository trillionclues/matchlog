library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/brand_mark.dart';

/// Shared scaffold for login and register screens.

/// Layout (top → bottom):
///   Logo + app name
///   Title + subtitle
///   Social login buttons  (optional)
///   ── or ──  divider     (shown when socialActions provided)
///   Form fields
///   Primary CTA button
///   Switch-screen footer link
///
class AuthForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final Widget footer;
  final Widget? auxiliaryFooter;
  final String title;
  final String subtitle;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool isLoading;

  final List<Widget>? socialActions;

  const AuthForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.footer,
    this.auxiliaryFooter,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    required this.onSubmit,
    required this.isLoading,
    this.socialActions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSocial = socialActions != null && socialActions!.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: MatchLogSpacing.xl,
              vertical: MatchLogSpacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthHeader(),
                    const SizedBox(height: MatchLogSpacing.xxl),
                    Text(
                      title,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MatchLogSpacing.sm),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MatchLogSpacing.xxl),
                    if (hasSocial) ...[
                      ...socialActions!.map((btn) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: MatchLogSpacing.sm),
                            child: btn,
                          )),
                      const SizedBox(height: MatchLogSpacing.lg),
                      _OrDivider(color: colorScheme.outlineVariant),
                      const SizedBox(height: MatchLogSpacing.lg),
                    ],
                    ...fields,
                    const SizedBox(height: MatchLogSpacing.xl),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSubmit,
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.surface,
                                ),
                              )
                            : Text(submitLabel),
                      ),
                    ),
                    const SizedBox(height: MatchLogSpacing.xl),
                    footer,
                    if (auxiliaryFooter != null) ...[
                      const SizedBox(height: MatchLogSpacing.sm),
                      auxiliaryFooter!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: MatchLogSpacing.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const MatchLogBrandMark(
            width: 40,
            height: 36,
          ),
        ),
        const SizedBox(height: MatchLogSpacing.md),
        Text(
          'MatchLog',
          style: theme.textTheme.displayMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final Color color;
  const _OrDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.md),
          child: Text(
            'OR',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class AuthSwitchFooter extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback? onTap;

  const AuthSwitchFooter({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$question ',
          style: theme.textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
