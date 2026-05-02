library;

import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';

// Shared scaffold for login and register screens.
// Layout (top → bottom):
//   Back button (if canPop)
//   Title + subtitle
//   Social login buttons  (optional)
//   ── or ──  divider     (shown when socialActions provided)
//   Form fields
//   Primary CTA button
//   Switch-screen footer link

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
    final canPop = Navigator.of(context).canPop();

    final bgColor = colorScheme.brightness == Brightness.light
        ? colorScheme.surface
        : colorScheme.surface;

    final authInputDecoration = theme.inputDecorationTheme.copyWith(
      filled: false,
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.onSurface, width: 1.5),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 14,
      ),
    );

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: bgColor,
        inputDecorationTheme: authInputDecoration,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (canPop)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: MatchLogSpacing.lg,
                      top: MatchLogSpacing.sm,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colorScheme.onSurface,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MatchLogSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: canPop
                                ? MatchLogSpacing.xxl
                                : MatchLogSpacing.xxxl + MatchLogSpacing.xl,
                          ),
                          Text(
                            title,
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: MatchLogSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MatchLogSpacing.lg,
                            ),
                            child: Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: MatchLogSpacing.xxl),
                          if (hasSocial) ...[
                            ...socialActions!,
                            const SizedBox(height: MatchLogSpacing.xl),
                            _OrDivider(color: colorScheme.outlineVariant),
                            const SizedBox(height: MatchLogSpacing.lg),
                          ],
                          ...fields,
                          const SizedBox(height: MatchLogSpacing.xxl),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.onSurface,
                                foregroundColor: colorScheme.surface,
                                disabledBackgroundColor: colorScheme.onSurface
                                    .withValues(alpha: 0.12),
                                disabledForegroundColor: colorScheme.onSurface
                                    .withValues(alpha: 0.38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: MatchLogSpacing.roundedFull,
                                ),
                                textStyle: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                          const SizedBox(height: MatchLogSpacing.xxl),
                          footer,
                          if (auxiliaryFooter != null) ...[
                            const SizedBox(height: MatchLogSpacing.sm),
                            auxiliaryFooter!,
                          ],
                          const SizedBox(height: MatchLogSpacing.xxl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final Color color;
  const _OrDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MatchLogSpacing.lg),
          child: Text(
            'or',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 0.5)),
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
      ),
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
