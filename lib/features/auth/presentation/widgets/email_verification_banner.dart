library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/snackbar.dart';
import '../providers/auth_providers.dart';

class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll Firebase every 30s to detect out-of-app verification
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || user.emailVerified) {
      _pollTimer?.cancel();
      return;
    }
    await ref.read(checkEmailVerifiedProvider).call();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null || authUser.emailVerified) {
      return const SizedBox.shrink();
    }

    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Row(
                  children: [
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
                              if (result.isSuccess) {
                                MatchLogSnackBar.success(
                                  context,
                                  'Verification email sent.',
                                );
                              } else {
                                MatchLogSnackBar.error(
                                  context,
                                  result.message ?? 'Unable to send email.',
                                );
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('Resend email'),
                    ),
                    const SizedBox(width: MatchLogSpacing.lg),
                    TextButton(
                      onPressed: isLoading ? null : _checkVerification,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.onSurface,
                      ),
                      child: const Text("I've verified"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
