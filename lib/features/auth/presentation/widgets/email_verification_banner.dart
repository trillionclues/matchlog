library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/auth_providers.dart';

class EmailVerificationBanner extends ConsumerWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null || authUser.emailVerified) {
      return const SizedBox.shrink();
    }

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use the theme's warning-like color via a semi-transparent primary tint.
    // Since Material ColorScheme doesn't expose warning natively, we derive
    // a warm amber from the tertiary or fall back to a standard amber.
    const warningColor = Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        MatchLogSpacing.lg,
        MatchLogSpacing.lg,
        MatchLogSpacing.lg,
        0,
      ),
      padding: MatchLogSpacing.cardPadding,
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.08),
        borderRadius: MatchLogSpacing.roundedMd,
        border: Border.all(
          color: warningColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            color: warningColor,
          ),
          MatchLogSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your email',
                  style: theme.textTheme.headlineSmall,
                ),
                MatchLogSpacing.gapXs,
                Text(
                  'Social features stay locked until your email address is verified.',
                  style: theme.textTheme.bodyMedium,
                ),
                MatchLogSpacing.gapSm,
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final result = await ref
                              .read(authControllerProvider.notifier)
                              .resendVerificationEmail();
                          if (!context.mounted || result.isCancelled) {
                            return;
                          }
                          final message = result.isSuccess
                              ? 'Verification email sent.'
                              : result.message ?? 'Unable to send email.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: colorScheme.primary,
                  ),
                  child: const Text('Resend email'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
