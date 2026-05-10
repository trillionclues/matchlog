# Requirements Document

## Introduction

The Calendar Heatmap is a GitHub-style activity visualization embedded in the MatchLog stats dashboard. It shows match-logging density across a rolling calendar window, giving users an at-a-glance view of their habits, streaks, and quiet periods.

The feature is part of Phase 1.5 Extras. It extends the existing `StatsDashboard` screen at `lib/features/diary/presentation/screens/stats_dashboard.dart` and is derived entirely from `MatchEntry` objects already available through the local Drift database. No new network requests or separate analytics stores are required.

The heatmap must share streak logic with the existing `_calculateStreaks` method in `DiaryRepositoryImpl` so that the stats dashboard and the heatmap never display contradictory streak numbers.

---

## Glossary

- **CalendarHeatmap**: The widget that renders the GitHub-style activity grid on the stats dashboard.
- **HeatmapData**: The computed view-model that maps each calendar date to an entry count and an intensity tier.
- **IntensityTier**: One of five discrete levels — `none`, `low`, `medium`, `high`, `peak` — used to select a cell color.
- **DayCell**: A single rounded rectangle in the heatmap grid representing one calendar day.
- **HeatmapProvider**: The Riverpod provider that transforms `diaryEntriesProvider` output into `HeatmapData`.
- **StreakSummary**: The pair of `currentStreak` and `longestStreak` values surfaced alongside the heatmap.
- **DayDetailSheet**: The bottom sheet shown when the user taps a `DayCell` that had at least one entry.
- **MatchLogColors**: The existing color token class at `lib/core/theme/colors.dart`.
- **MatchLogSpacing**: The existing spacing token class at `lib/core/theme/spacing.dart`.
- **StatsDashboard**: The existing screen at `lib/features/diary/presentation/screens/stats_dashboard.dart` where the heatmap is embedded.
- **diaryEntriesProvider**: The existing `StreamProvider` in `lib/features/diary/presentation/providers/diary_providers.dart` that emits the current user's `MatchEntry` list.

---

## Requirements

### Requirement 1: Heatmap Data Derivation

**User Story:** As a user, I want the heatmap to reflect my actual diary entries, so that the activity grid is always consistent with what I have logged.

#### Acceptance Criteria

1. THE HeatmapProvider SHALL derive all heatmap data exclusively from the output of `diaryEntriesProvider` and SHALL not issue independent database or network queries.
2. WHEN `diaryEntriesProvider` emits a new list, THE HeatmapProvider SHALL recompute `HeatmapData` without requiring a manual refresh action.
3. THE HeatmapProvider SHALL group entries by local calendar date using the `createdAt` field of each `MatchEntry`.
4. THE HeatmapProvider SHALL cover a rolling window of the most recent 52 weeks (364 days) ending on the current local date.
5. FOR ALL diary-entry datasets rendered into the heatmap, THE sum of all `DayCell` entry counts across the rendered window SHALL equal the number of `MatchEntry` objects whose `createdAt` falls within that window.

---

### Requirement 2: Intensity Tier Mapping

**User Story:** As a user, I want the cell colors to reflect how active I was on each day, so that busy days stand out from quiet ones at a glance.

#### Acceptance Criteria

1. THE HeatmapProvider SHALL assign each calendar date exactly one `IntensityTier` based on the entry count for that date.
2. THE HeatmapProvider SHALL use the following tier thresholds:
   - `none`: 0 entries
   - `low`: 1 entry
   - `medium`: 2 entries
   - `high`: 3 entries
   - `peak`: 4 or more entries
3. THE CalendarHeatmap widget SHALL render each `IntensityTier` using the following `MatchLogColors` tokens:
   - `none` → `MatchLogColors.surfaceBorder`
   - `low` → `MatchLogColors.secondary` at 30 % opacity
   - `medium` → `MatchLogColors.secondary` at 55 % opacity
   - `high` → `MatchLogColors.secondary` at 80 % opacity
   - `peak` → `MatchLogColors.secondary` (full opacity)
4. THE CalendarHeatmap widget SHALL not introduce color values outside the `MatchLogColors` token set for tier rendering.

---

### Requirement 3: Grid Layout and Rendering

**User Story:** As a user, I want the heatmap to look like a familiar activity grid, so that I can read it without needing an explanation.

#### Acceptance Criteria

1. THE CalendarHeatmap widget SHALL render day cells in a grid where columns represent weeks and rows represent days of the week (Sunday through Saturday).
2. THE CalendarHeatmap widget SHALL implement cell rendering using `CustomPainter` with rounded rectangles.
3. THE CalendarHeatmap widget SHALL use `MatchLogSpacing` tokens for cell size and gap values and SHALL not hardcode layout constants outside those tokens.
4. THE CalendarHeatmap widget SHALL display abbreviated month labels above the column group where each month begins.
5. THE CalendarHeatmap widget SHALL be horizontally scrollable when the 52-week grid exceeds the available screen width.

---

### Requirement 4: Streak Summary Display

**User Story:** As a user, I want to see my current and longest streaks near the heatmap, so that I can track my consistency without switching screens.

#### Acceptance Criteria

1. THE CalendarHeatmap widget SHALL display the `currentStreak` and `longestStreak` values from `StreakSummary` in a visible summary row adjacent to the grid.
2. THE HeatmapProvider SHALL compute `StreakSummary` using the same algorithm as `DiaryRepositoryImpl._calculateStreaks` and SHALL not introduce a second independent streak computation.
3. FOR ALL diary-entry datasets, THE `currentStreak` value in `StreakSummary` SHALL be less than or equal to the `longestStreak` value.
4. WHEN `currentStreak` is zero, THE CalendarHeatmap widget SHALL display a neutral label (e.g., "No active streak") rather than showing "0 days".

---

### Requirement 5: Day Cell Tap Interaction

**User Story:** As a user, I want to tap a day cell to see which matches I logged on that day, so that I can quickly revisit specific sessions.

#### Acceptance Criteria

1. THE CalendarHeatmap widget SHALL make every `DayCell` tappable regardless of its `IntensityTier`.
2. WHEN the user taps a `DayCell` whose entry count is greater than zero, THE CalendarHeatmap widget SHALL present a `DayDetailSheet` listing the `MatchEntry` objects logged on that date.
3. WHEN the user taps a `DayCell` whose entry count is zero, THE CalendarHeatmap widget SHALL present a `DayDetailSheet` with an empty-day message rather than silently ignoring the tap.
4. THE `DayDetailSheet` SHALL display at minimum the `homeTeam`, `sport`, `score`, and `rating` fields for each listed `MatchEntry`.
5. THE `DayDetailSheet` SHALL be dismissible by swiping down or tapping outside the sheet.

---

### Requirement 6: Empty State

**User Story:** As a new user with no diary entries, I want the heatmap area to show a helpful message, so that I understand what the grid will look like once I start logging.

#### Acceptance Criteria

1. WHEN `diaryEntriesProvider` emits an empty list, THE CalendarHeatmap widget SHALL render a meaningful empty state instead of an empty or corrupt grid.
2. THE empty state SHALL include a short explanatory message and a visual indicator consistent with the existing empty-state pattern used elsewhere in the app.
3. THE empty state SHALL not crash or throw a layout exception when the entry list is empty.

---

### Requirement 7: Stats Dashboard Integration

**User Story:** As a user, I want the heatmap to appear naturally within my stats screen, so that I do not need to navigate to a separate screen to see my activity grid.

#### Acceptance Criteria

1. THE StatsDashboard widget SHALL embed the `CalendarHeatmap` widget in its scrollable content area below the headline stats grid.
2. THE CalendarHeatmap widget SHALL be a self-contained `ConsumerWidget` that reads from `HeatmapProvider` directly and does not require the parent `StatsDashboard` to pass entry data as constructor arguments.
3. THE CalendarHeatmap widget SHALL follow the same visual language (colors, spacing, typography) as the existing `StatCard` and breakdown widgets already present in `StatsDashboard`.
4. WHEN `diaryEntriesProvider` is in a loading state, THE CalendarHeatmap widget SHALL display a loading indicator consistent with the rest of the stats screen.
5. WHEN `diaryEntriesProvider` emits an error, THE CalendarHeatmap widget SHALL display an inline error message and SHALL not propagate the error to crash the parent `StatsDashboard`.

---

### Requirement 8: Testing and Correctness

**User Story:** As a developer, I want automated tests for the heatmap's data logic and widget behavior, so that regressions in cell counts, streak values, or tap interactions are caught early.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `HeatmapProvider` covering: correct day grouping, correct tier assignment for each threshold boundary, and correct `StreakSummary` values.
2. THE test suite SHALL include a widget test for `CalendarHeatmap` verifying that the empty state renders when the entry list is empty.
3. THE test suite SHALL include a widget test verifying that tapping a populated `DayCell` opens the `DayDetailSheet`.
4. FOR ALL diary-entry datasets generated as test inputs, THE sum of `DayCell` entry counts across the rendered window SHALL equal the number of entries whose `createdAt` falls within that window (property-based test).
5. FOR ALL diary-entry datasets generated as test inputs, THE `currentStreak` SHALL be less than or equal to `longestStreak` (property-based test).
