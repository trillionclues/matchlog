library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:matchlog/features/diary/presentation/widgets/location_map_widget.dart';

import '../../../../core/theme/spacing.dart';
import '../providers/check_in_providers.dart';
import '../providers/diary_providers.dart';

class StadiumCheckInScreen extends ConsumerStatefulWidget {
  final String entryId;

  const StadiumCheckInScreen({super.key, required this.entryId});

  @override
  ConsumerState<StadiumCheckInScreen> createState() =>
      _StadiumCheckInScreenState();
}

class _StadiumCheckInScreenState extends ConsumerState<StadiumCheckInScreen> {
  bool _checkInStarted = false;

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(matchEntryDetailProvider(widget.entryId));

    return entryAsync.when(
      loading: () => _scaffold(
        context,
        child: _LoadingView(message: 'Loading match…'),
      ),
      error: (e, _) => _scaffold(
        context,
        child: _ErrorView(
          message: 'Could not load match entry.',
          onDismiss: () => context.pop(),
        ),
      ),
      data: (entry) {
        if (entry == null) {
          return _scaffold(
            context,
            child: _ErrorView(
              message: 'Match entry not found.',
              onDismiss: () => context.pop(),
            ),
          );
        }

        final userId = entry.userId;
        final checkInState = ref.watch(checkInControllerProvider(userId));
        final controller = ref.read(checkInControllerProvider(userId).notifier);

        if (!_checkInStarted) {
          _checkInStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) controller.startCheckIn(entry);
          });
        }

        ref.listen(checkInControllerProvider(userId), (prev, next) {
          if (mounted) {
            next.whenOrNull(
              verified: () {
                ref.invalidate(matchEntryDetailProvider(widget.entryId));
                final navigator = Navigator.of(context);
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) navigator.pop();
                });
              },
            );
          }
        });

        return _scaffold(
          context,
          child: checkInState.when(
            idle: () => _LoadingView(message: 'Starting check-in…'),
            requestingPermission: () =>
                _LoadingView(message: 'Requesting location permission…'),
            acquiringLocation: () =>
                _LoadingView(message: 'Finding your location…'),
            geocoding: () => _LoadingView(message: 'Finding your location…'),
            locationAcquired: (venueDescription, lat, lng) => _ConfirmView(
              lat: lat,
              lng: lng,
              venueDescription: venueDescription,
              onConfirm: () => controller.confirm(entry),
              onCancel: () {
                controller.cancel();
                context.pop();
              },
            ),
            updatingEntry: () => _LoadingView(message: 'Saving…'),
            verified: () => const _VerifiedView(),
            permissionDenied: (message) => _ErrorView(
              icon: Icons.location_off_outlined,
              message: message ??
                  'Location permission was denied. '
                      'Tap "Check In" again to retry.',
              onDismiss: () {
                controller.reset();
                context.pop();
              },
            ),
            permissionPermanentlyDenied: (message) =>
                _PermissionPermanentlyDeniedView(
              message: message ??
                  'Location permission is permanently denied. '
                      'Open Settings to allow location access.',
              onOpenSettings: () => Geolocator.openAppSettings(),
              onDismiss: () {
                controller.reset();
                context.pop();
              },
            ),
            locationServiceDisabled: (message) => _ErrorView(
              icon: Icons.location_disabled_outlined,
              message: message ??
                  'Location services are disabled. '
                      'Enable them in Settings to check in.',
              onDismiss: () {
                controller.reset();
                context.pop();
              },
            ),
            acquisitionFailed: (message) => _RetryView(
              icon: Icons.gps_off_rounded,
              message: message ?? 'Could not get your location.',
              onRetry: () => controller.startCheckIn(entry),
              onDismiss: () {
                controller.reset();
                context.pop();
              },
            ),
            updateFailed: (message) => _RetryView(
              icon: Icons.cloud_off_rounded,
              message: message ?? 'Could not save check-in.',
              onRetry: () => controller.confirm(entry),
              onDismiss: () {
                controller.reset();
                context.pop();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _scaffold(BuildContext context, {required Widget child}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stadium Check-In'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(child: child),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: MatchLogSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            MatchLogSpacing.gapXl,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmView extends StatelessWidget {
  final String venueDescription;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final double lat;
  final double lng;

  const _ConfirmView({
    required this.venueDescription,
    required this.onConfirm,
    required this.onCancel,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(MatchLogSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: LocationMapWidget(
              latitude: lat,
              longitude: lng,
              locationLabel: venueDescription,
            ),
          ),
          const SizedBox(height: MatchLogSpacing.lg),
          MatchLogSpacing.gapSm,
          Container(
            padding: const EdgeInsets.all(MatchLogSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: MatchLogSpacing.roundedMd,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              venueDescription,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          MatchLogSpacing.gapSm,
          Text(
            '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            textAlign: TextAlign.center,
          ),
          MatchLogSpacing.gapXl,
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MatchLogSpacing.md,
              vertical: MatchLogSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: MatchLogSpacing.roundedSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                MatchLogSpacing.hGapSm,
                Expanded(
                  child: Text(
                    'This check-in is based on your current GPS location. '
                    'By confirming, you\'re verifying you\'re physically at this venue.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.verified_rounded, size: 18),
            label: const Text('Confirm Check-In'),
          ),
          MatchLogSpacing.gapSm,
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: MatchLogSpacing.roundedFull,
              ),
            ),
            child: const Text('Cancel'),
          ),
          MatchLogSpacing.gapMd,
        ],
      ),
    );
  }
}

class _VerifiedView extends StatelessWidget {
  const _VerifiedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: MatchLogSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 40,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            MatchLogSpacing.gapXl,
            Text(
              'You\'re checked in!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            MatchLogSpacing.gapSm,
            Text(
              'Your stadium attendance has been verified.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onDismiss;

  const _ErrorView({
    this.icon = Icons.error_outline_rounded,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(MatchLogSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 56, color: colorScheme.error),
          MatchLogSpacing.gapXl,
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          MatchLogSpacing.gapXxl,
          OutlinedButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _PermissionPermanentlyDeniedView extends StatelessWidget {
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onDismiss;

  const _PermissionPermanentlyDeniedView({
    required this.message,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(MatchLogSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 56,
            color: colorScheme.error,
          ),
          MatchLogSpacing.gapXl,
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          MatchLogSpacing.gapXxl,
          FilledButton.tonal(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
          MatchLogSpacing.gapSm,
          OutlinedButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _RetryView({
    required this.icon,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(MatchLogSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 56, color: colorScheme.error),
          MatchLogSpacing.gapXl,
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          MatchLogSpacing.gapXxl,
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
          MatchLogSpacing.gapSm,
          OutlinedButton(
            onPressed: onDismiss,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
