// Accepts optional fixture context via route extras.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/widgets/snackbar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/match_entry.dart' as domain;
import '../providers/diary_providers.dart';
import '../widgets/rating_stars.dart';
import '../widgets/watch_type_selector.dart';

class LogMatchScreen extends ConsumerStatefulWidget {
  const LogMatchScreen({super.key});

  @override
  ConsumerState<LogMatchScreen> createState() => _LogMatchScreenState();
}

class _LogMatchScreenState extends ConsumerState<LogMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _homeTeamController = TextEditingController();
  final _awayTeamController = TextEditingController();
  final _scoreController = TextEditingController();
  final _leagueController = TextEditingController();
  final _venueController = TextEditingController();
  final _reviewController = TextEditingController();

  String _sport = 'football';
  String? _watchType;
  int _rating = 3;

  static const _sports = [
    ('football', 'Football'),
    ('basketball', 'Basketball'),
    ('formula1', 'Formula 1'),
    ('mma', 'MMA'),
    ('cricket', 'Cricket'),
    ('tennis', 'Tennis'),
  ];

  @override
  void dispose() {
    _homeTeamController.dispose();
    _awayTeamController.dispose();
    _scoreController.dispose();
    _leagueController.dispose();
    _venueController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_watchType == null) {
      MatchLogSnackBar.error(context, 'Select how you watched the match.');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final entry = domain.MatchEntry(
      id: const Uuid().v4(),
      userId: user.id,
      sport: _sport,
      fixtureId: '',
      homeTeam: _homeTeamController.text.trim(),
      awayTeam: _awayTeamController.text.trim().isEmpty
          ? null
          : _awayTeamController.text.trim(),
      score: _scoreController.text.trim(),
      league: _leagueController.text.trim(),
      watchType: _watchType!,
      rating: _rating,
      review: _reviewController.text.trim().isEmpty
          ? null
          : _reviewController.text.trim(),
      venue: _venueController.text.trim().isEmpty
          ? null
          : _venueController.text.trim(),
      createdAt: DateTime.now(),
    );

    final result =
        await ref.read(logMatchControllerProvider.notifier).submit(entry);

    if (!mounted) return;
    if (result.isSuccess) {
      MatchLogSnackBar.success(context, 'Match logged.');
      context.pop();
    } else {
      MatchLogSnackBar.error(context, result.message ?? 'Failed to log match.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(logMatchControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Match'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: MatchLogSpacing.lg,
            vertical: MatchLogSpacing.lg,
          ),
          children: [
            
            Text('Sport', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            DropdownButtonFormField<String>(
              value: _sport,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.sports_outlined),
              ),
              items: _sports
                  .map((s) => DropdownMenuItem(
                        value: s.$1,
                        child: Text(s.$2),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sport = v ?? 'football'),
            ),
            MatchLogSpacing.gapXl,

            Text('Teams', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _homeTeamController,
              decoration: const InputDecoration(hintText: 'Home team'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: !isLoading,
            ),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _awayTeamController,
              decoration: const InputDecoration(
                hintText: 'Away team (optional for individual sports)',
              ),
              enabled: !isLoading,
            ),
            MatchLogSpacing.gapXl,

            Text('Score', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _scoreController,
              decoration: const InputDecoration(hintText: 'e.g. 2-1'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: !isLoading,
            ),
            MatchLogSpacing.gapXl,

            Text('League / Competition', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _leagueController,
              decoration:
                  const InputDecoration(hintText: 'e.g. Premier League'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
              enabled: !isLoading,
            ),
            MatchLogSpacing.gapXl,

            Text('How did you watch?', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            WatchTypeSelector(
              selected: _watchType,
              onChanged: (v) => setState(() => _watchType = v),
            ),
            MatchLogSpacing.gapXl,

            Text('Rating', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            RatingStars(
              rating: _rating,
              size: 36,
              onChanged: (v) => setState(() => _rating = v),
            ),
            MatchLogSpacing.gapXl,

            Text('Venue', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _venueController,
              decoration:
                  const InputDecoration(hintText: 'Optional — stadium name'),
              enabled: !isLoading,
            ),
            MatchLogSpacing.gapXl,

            Text('Review', style: theme.textTheme.labelLarge),
            MatchLogSpacing.gapSm,
            TextFormField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'What stood out?',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              enabled: !isLoading,
            ),
            const SizedBox(height: MatchLogSpacing.xxxl),

            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: MatchLogSpacing.md),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Save Match'),
              ),
            ),
            MatchLogSpacing.gapXl,
          ],
        ),
      ),
    );
  }
}
