# Implementation Plan: Calendar Heatmap

## Overview

Implement a GitHub-style activity heatmap embedded in `StatsDashboard`. The work proceeds in five layers: shared streak logic → view-models → provider → painter + widget → integration and tests. Each layer builds on the previous so there is no orphaned code at any step.

`fast_check` is not in `pubspec.yaml`; add it to `dev_dependencies` before writing property tests.

---

## Tasks

- [x] 1. Extract `calculateStreaks` to a shared free function
  - Create `lib/features/diary/domain/utils/streak_calculator.dart`
  - Copy the body of `DiaryRepositoryImpl._calculateStreaks` verbatim into a top-level function `(int current, int longest) calculateStreaks(List<MatchEntry> entries)`
  - Update `DiaryRepositoryImpl._calculateStreaks` to delegate: `return calculateStreaks(entries);`
  - Verify `DiaryRepositoryImpl` still compiles and all existing tests pass
  - _Requirements: 4.2_

- [x] 2. Define view-model classes
  - Create `lib/features/diary/presentation/providers/heatmap_models.dart`
  - Define `IntensityTier` enum with values `none, low, medium, high, peak`
  - Add `extension IntensityTierX on IntensityTier` with:
    - `static IntensityTier fromCount(int count)` — switch on count: 0→none, 1→low, 2→medium, 3→high, ≥4→peak
    - `Color toColor()` — switch on `this` using `MatchLogColors` tokens per the tier table in the design
  - Define `HeatmapDay` (immutable class: `date`, `count`, `tier`)
  - Define `StreakSummary` (immutable class: `currentStreak`, `longestStreak`)
  - Define `HeatmapData` (immutable class: `List<HeatmapDay> days`, `StreakSummary streaks`)
  - All classes are pure Dart with no Flutter dependency except `IntensityTierX.toColor()`
  - _Requirements: 2.1, 2.2, 2.3, 4.1_

  - [ ]* 2.1 Write unit tests for `IntensityTier.fromCount`
    - File: `test/features/diary/domain/utils/intensity_tier_test.dart`
    - Test boundary values: 0→none, 1→low, 2→medium, 3→high, 4→peak, 100→peak
    - _Requirements: 2.1, 2.2_

- [x] 3. Add `kiri_check` dev dependency and implement `heatmapProvider`
  - Add `kiri_check: ^1.2.0` (or latest stable) to `dev_dependencies` in `pubspec.yaml`; run `flutter pub get`
  - Add `_buildHeatmapData`, `_today`, and `_normalise` private functions to `stats_providers.dart` exactly as specified in the design
  - `_buildHeatmapData` must call `calculateStreaks` from `streak_calculator.dart`
  - Add `heatmapProvider` as `StreamProvider.autoDispose<HeatmapData>` in `stats_providers.dart`, watching `diaryEntriesProvider`
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 4.2_

  - [ ]* 3.1 Write unit tests for `heatmapProvider` logic
    - File: `test/features/diary/presentation/providers/heatmap_provider_test.dart`
    - Test: entries on the same date produce correct `HeatmapDay.count`
    - Test: entry exactly on `windowStart` is included; entry one day before is excluded
    - Test: tier thresholds at boundary values 0, 1, 2, 3, 4, 5
    - Test: `StreakSummary` from `heatmapProvider` matches `calculateStreaks` output for the same input
    - _Requirements: 1.3, 1.4, 1.5, 2.1, 2.2, 4.2_

  - [ ]* 3.2 Write unit tests for `calculateStreaks`
    - File: `test/features/diary/domain/utils/streak_calculator_test.dart`
    - Test: empty list → `(0, 0)`
    - Test: single entry today → `(1, 1)`
    - Test: consecutive days → correct current and longest
    - Test: gap in entries → current streak resets
    - _Requirements: 4.2, 4.3_

- [ ] 4. Checkpoint — ensure all tests pass
  - Run `flutter test test/features/diary/domain/` and `flutter test test/features/diary/presentation/providers/`
  - Ensure all tests pass; ask the user if questions arise.

- [x] 5. Implement `HeatmapPainter` (`CustomPainter`)
  - Create `lib/features/diary/presentation/widgets/heatmap_painter.dart`
  - Class `HeatmapPainter extends CustomPainter` with fields `List<HeatmapDay> days` and `List<Rect> cellRects` (mutable, populated during `paint`)
  - Layout constants as static consts derived from `MatchLogSpacing` tokens: `cellSize = MatchLogSpacing.md` (12 px), `gap = MatchLogSpacing.xs` (4 px), `step = cellSize + gap` (16 px), `monthLabelHeight = MatchLogSpacing.lg` (16 px)
  - `paint` method:
    - Compute the column offset so column 0 starts on the Sunday of the week containing `days.first.date`
    - Iterate all 364 days; for each compute `col` and `row` (0=Sunday … 6=Saturday)
    - Draw `RRect` at `Rect.fromLTWH(col * step, monthLabelHeight + row * step, cellSize, cellSize)` with radius `MatchLogSpacing.radiusSm / 2` (4 px) filled with `day.tier.toColor()`
    - Populate `cellRects` in the same iteration so index matches `days` index
    - Draw abbreviated month labels (`Jan`, `Feb`, …) above the first column of each new month using `TextPainter` with `theme.textTheme.labelSmall` style; pass `ThemeData` into the painter constructor
  - `shouldRepaint` returns `true` when `old.days != days`
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 6. Implement `DayDetailSheet`
  - Create `lib/features/diary/presentation/widgets/day_detail_sheet.dart`
  - `DayDetailSheet extends StatelessWidget` with fields `HeatmapDay day` and `List<MatchEntry> entries`
  - Header: formatted date string (e.g. "Wednesday, 14 May 2025") using `intl` `DateFormat`
  - If `entries.isEmpty`: render an `EmptyState`-style message ("No matches logged on this day") — do not use the full `EmptyState` widget (it is `Center`-wrapped); use a `Padding` + `Column` with icon and text instead, consistent with the sheet's compact layout
  - If `entries.isNotEmpty`: `ListView.builder` of compact match rows, each showing:
    - Sport icon dot using `MatchLogColors.sportAccent(entry.sport)`
    - `homeTeam` (and `awayTeam` if non-null, separated by " vs ")
    - `score`
    - Star rating row (filled/empty `Icons.star_rounded` / `Icons.star_outline_rounded`, `rating` out of 5)
  - Wrap the sheet content in `SafeArea` with `bottom: true`
  - _Requirements: 5.2, 5.3, 5.4, 5.5_

- [x] 7. Implement `StreakSummaryRow`
  - Create `lib/features/diary/presentation/widgets/streak_summary_row.dart`
  - `StreakSummaryRow extends StatelessWidget` with field `StreakSummary streaks`
  - Render two `StatCard`-style tiles in a `Row` with `Expanded` children:
    - "Current streak" tile: value = `streaks.currentStreak == 0 ? 'No active streak' : '${streaks.currentStreak} days'`, icon `Icons.local_fire_department_outlined`
    - "Longest streak" tile: value = `'${streaks.longestStreak} days'`, icon `Icons.emoji_events_outlined`
  - Use `MatchLogSpacing.hGapSm` between tiles
  - _Requirements: 4.1, 4.4_

- [x] 8. Implement `CalendarHeatmap` `ConsumerWidget` and private state widgets
  - Create `lib/features/diary/presentation/widgets/calendar_heatmap.dart`
  - `CalendarHeatmap extends ConsumerWidget`: watches `heatmapProvider` and delegates to `when`:
    - `loading` → `_HeatmapShimmer`
    - `error` → `_HeatmapError` (uses `ErrorState` with `onRetry: () => ref.invalidate(heatmapProvider)`)
    - `data` → if all days have `count == 0` render `_HeatmapEmpty`, else `_HeatmapContent`
  - `_HeatmapEmpty`: `EmptyState(icon: Icons.calendar_today_outlined, title: 'No activity yet', subtitle: 'Log your first match and it will appear here.')`
  - `_HeatmapShimmer`: `MatchLogShimmer` wrapping a `Column` with a rounded rectangle placeholder sized `step * 53` wide × `monthLabelHeight + 7 * step` tall, plus two small boxes below for streak tiles
  - `_HeatmapError`: `ErrorState` widget with retry callback
  - `_HeatmapContent`: `Column` containing:
    - Section header `Text('Activity', style: theme.textTheme.titleMedium)`
    - `MatchLogSpacing.gapSm`
    - `SingleChildScrollView(scrollDirection: Axis.horizontal)` wrapping a `GestureDetector` + `CustomPaint(painter: _painter, size: _canvasSize)`
    - `MatchLogSpacing.gapMd`
    - `StreakSummaryRow(streaks: data.streaks)`
  - `GestureDetector.onTapUp`: compute `localPosition`, find matching rect in `_painter.cellRects`, call `_onCellTap(context, data.days[idx])`
  - `_onCellTap`: filter `data.days` entries for the tapped day, then call `MatchLogBottomSheet.show` with `DayDetailSheet(day: day, entries: dayEntries)` — always show the sheet regardless of entry count (requirement 5.1, 5.3)
  - `_canvasSize`: `Size(53 * step - gap, monthLabelHeight + 7 * step - gap)`
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.4, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 7.2, 7.3, 7.4, 7.5_

- [x] 9. Integrate `CalendarHeatmap` into `StatsDashboard`
  - In `lib/features/diary/presentation/screens/stats_dashboard.dart`, add `import` for `CalendarHeatmap`
  - In the `ListView` children (inside the `data` branch), insert after the "Longest streak" `_SectionHeader` and before the league breakdown:
    ```dart
    MatchLogSpacing.gapXl,
    const CalendarHeatmap(),
    MatchLogSpacing.gapXl,
    ```
  - No constructor arguments are passed — `CalendarHeatmap` is self-contained
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 10. Checkpoint — build and analyze
  - Run `flutter pub run build_runner build --delete-conflicting-outputs`
  - Run `flutter analyze`
  - Fix any warnings or errors before proceeding
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Write widget tests for `CalendarHeatmap`
  - File: `test/features/diary/presentation/widgets/calendar_heatmap_test.dart`
  - Use `ProviderScope` overrides to inject mock `heatmapProvider` state
  - Test: empty state renders `EmptyState` widget when all days have count 0 (_Requirements: 6.1_)
  - Test: loading state renders shimmer placeholder (_Requirements: 7.4_)
  - Test: error state renders `ErrorState` widget (_Requirements: 7.5_)
  - Test: tapping a populated cell opens `DayDetailSheet` (_Requirements: 5.2_)
  - Test: tapping an empty cell opens `DayDetailSheet` with empty-day message (_Requirements: 5.3_)
  - Test: `currentStreak == 0` shows "No active streak" label, not "0 days" (_Requirements: 4.4_)
  - Test: `CalendarHeatmap` appears in `StatsDashboard` widget tree (_Requirements: 7.1_)
  - _Requirements: 5.2, 5.3, 4.4, 6.1, 7.1, 7.4, 7.5_

- [ ] 12. Write widget test for `DayDetailSheet`
  - File: `test/features/diary/presentation/widgets/day_detail_sheet_test.dart`
  - Test: for a given `MatchEntry`, the rendered sheet contains `homeTeam`, `sport` (via sport accent color or icon), `score`, and `rating` (_Requirements: 5.4_)
  - Test: sheet with empty entries list shows empty-day message (_Requirements: 5.3_)
  - _Requirements: 5.3, 5.4_

- [ ] 13. Write property-based tests
  - File: `test/features/diary/presentation/providers/heatmap_provider_property_test.dart`
  - Import `kiri_check` and `streak_calculator.dart`

  - [ ]* 13.1 Write property test for entry count conservation
    - **Property 1: Entry count conservation**
    - Generator: arbitrary `List<MatchEntry>` with random `createdAt` spanning ±2 years from today; minimum 100 iterations
    - Assert: sum of `HeatmapDay.count` across all days in `HeatmapData` equals the number of entries whose `createdAt` (normalised) falls within the 364-day window
    - **Validates: Requirements 1.5, 8.4**

  - [ ]* 13.2 Write property test for tier assignment correctness
    - **Property 2: Tier assignment correctness**
    - Generator: arbitrary non-negative integers 0–1000; minimum 100 iterations
    - Assert: `IntensityTierX.fromCount(n)` returns `none` for 0, `low` for 1, `medium` for 2, `high` for 3, `peak` for n ≥ 4
    - **Validates: Requirements 2.1, 2.2**

  - [ ]* 13.3 Write property test for current streak ≤ longest streak
    - **Property 3: currentStreak ≤ longestStreak**
    - Generator: arbitrary `List<MatchEntry>` with random `createdAt` values; minimum 100 iterations
    - Assert: `calculateStreaks(entries).$1 <= calculateStreaks(entries).$2`
    - **Validates: Requirements 4.3, 8.5**

- [ ] 14. Final checkpoint — full test suite
  - Run `flutter test`
  - Run `flutter analyze`
  - Ensure all tests pass and there are no analysis warnings; ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for traceability
- `kiri_check` must be added to `pubspec.yaml` before task 13 (property tests); it is added as part of task 3
- `HeatmapPainter` receives `ThemeData` in its constructor so it can style month labels without a `BuildContext` inside `paint`
- `_HeatmapContent` holds a reference to the `HeatmapPainter` instance so the `GestureDetector` can read `cellRects` after `paint` has run; use a `StatefulWidget` or `ValueNotifier` if needed to trigger a rebuild after the first paint populates `cellRects`
- The `DayDetailSheet` entry list is derived by filtering `HeatmapData.days` — no additional provider call is needed at tap time
- Property tests (tasks 13.1–13.3) require `fast_check` in `dev_dependencies`; if the package API differs from the design's pseudocode, adapt the generator syntax while preserving the property semantics
