# Requirements Document

## Introduction

The AI Insights feature adds MatchLog's Phase 3 intelligence layer: Gemini-powered betting insights and the full Year in Review experience. It builds on the earlier analytics, verification, and share-card groundwork to turn raw history into clear summaries, recommendations, and recap narratives.

This feature builds on work already specified elsewhere:

1. betting already defines `BetEntry` and ROI analytics
2. diary already defines `UserStats` and diary-derived habits
3. verification already defines Truth Score and verified-history signals
4. Phase 1.5 extras already establish share-card rendering and year-review-compatible recap infrastructure
5. `AppConfig` already provides `GEMINI_API_KEY`

This feature must follow the product and pricing direction documented in [docs/PROJECT.md](../../../docs/PROJECT.md):

1. AI insights are part of Phase 3
2. AI insights and Year in Review cards are Pro-tier value
3. AI augments the product; it does not replace deterministic analytics

The core rule for this feature is that deterministic app data stays the source of truth. Gemini generates explanation, synthesis, and recommendation layers on top of app-owned stats and histories. If AI is unavailable, the app must still produce deterministic stats and recap data.

---

## Glossary

- **AiInsightService**: The Gemini-backed service that generates structured AI outputs from app-owned context.
- **BettingInsight**: The structured AI summary for betting-history analysis.
- **MatchRecommendation**: An AI-generated or AI-ranked suggestion for upcoming matches based on watch history.
- **YearReview**: The recap aggregate model defined in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md), including the optional `aiSummary`.
- **ReviewGenerator**: The deterministic data aggregation component that prepares Year in Review inputs before any AI copy generation.
- **AiInsightsScreen**: The Phase 3 screen showing insight cards and pattern visualizations.
- **YearReviewScreen**: The recap experience showing wrapped-style slides and shareable year-review content.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want clear AI-facing domain contracts and recap models, so that deterministic aggregation and AI-generated copy stay separable and testable.

#### Acceptance Criteria

1. THE feature SHALL reuse the documented `YearReview` entity from [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md), including its optional `aiSummary` field.
2. THE ai-insights domain SHALL define a pure Dart `BettingInsight` model for Gemini-generated betting analysis with structured fields rather than free-form opaque blobs.
3. THE ai-insights domain MAY define a pure Dart `MatchRecommendation` model if needed for recommendation surfaces, but SHALL keep it separate from core fixture entities.
4. THE ai-insights domain SHALL define a feature-scoped failure type that presentation code can render without inspecting raw HTTP or Gemini API exceptions directly.
5. THE ai-insights repository or service contract SHALL separate deterministic aggregation from AI text generation, so that AI availability does not control access to core stats data.
6. FOR ALL valid `YearReview` instances, JSON serialization followed by deserialization SHALL return an equivalent entity when `aiSummary` is null or present.

---

### Requirement 2: Gemini Integration

**User Story:** As a developer, I want Gemini integration wired cleanly behind a service boundary, so that AI features can evolve without contaminating core analytics logic.

#### Acceptance Criteria

1. THE ai-insights feature SHALL use Gemini 2.5 Flash as the Phase 3 AI model, consistent with [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE Gemini integration SHALL be encapsulated behind an `AiInsightService` or equivalent service boundary rather than called directly from widgets.
3. THE service SHALL use the configured Gemini API key supplied through the existing app configuration flow.
4. THE service SHALL request structured outputs where the docs already define structured JSON-style responses, such as betting-pattern analysis.
5. THE service SHALL treat app-owned stats and histories as input context and SHALL not ask the model to invent authoritative totals, ROI, or counts.
6. IF Gemini is unavailable, rate-limited, or returns invalid output, THEN THE feature SHALL fail gracefully and fall back to deterministic non-AI surfaces where possible.

---

### Requirement 3: Betting Pattern Insights

**User Story:** As a user, I want AI-generated betting insights that explain patterns in my history, so that I can learn from my own data instead of only seeing raw ROI numbers.

#### Acceptance Criteria

1. THE ai-insights feature SHALL provide structured betting-pattern analysis based on recent bet history and aggregate stats, consistent with the Gemini use case documented in [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE betting insight pipeline SHALL consume deterministic inputs such as recent `BetEntry` history and `UserStats` or equivalent ROI aggregates.
3. THE betting insight output SHALL include at minimum a key strength, a warning or pattern to avoid, and one actionable suggestion, aligned with the documented prompt contract.
4. THE feature SHALL not present AI betting insights as guaranteed outcomes, certified advice, or bookmaker recommendations.
5. THE betting insight UI SHALL make it clear that the content is generated from the user's own history and is interpretive, not authoritative prediction.
6. IF the user has insufficient betting history, THEN THE feature SHALL present an understandable insufficient-data state instead of generating low-signal AI output.

---

### Requirement 4: Match Recommendations

**User Story:** As a user, I want AI-driven match recommendations based on my watch history, so that the app can suggest fixtures I might enjoy.

#### Acceptance Criteria

1. THE ai-insights feature SHALL remain compatible with the documented Phase 3 match-recommendation use case in [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE recommendation pipeline SHALL use deterministic watch-history inputs and available upcoming fixture context rather than inventing fixtures.
3. THE feature SHALL only recommend matches that exist in the app's real fixture data layer.
4. IF recommendation context is unavailable or insufficient, THEN THE feature SHALL omit or suppress recommendation modules gracefully rather than invent unsupported results.
5. Match recommendations SHALL remain a supplementary insight surface and SHALL not replace the core match-search feature.

---

### Requirement 5: Year in Review Data Aggregation

**User Story:** As a user, I want a Year in Review that accurately summarizes my year, so that recap slides and share cards feel earned rather than generic.

#### Acceptance Criteria

1. THE ai-insights feature SHALL build on the documented `YearReview` aggregate model in [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. THE deterministic `ReviewGenerator` or equivalent aggregation layer SHALL compute year-review fields from actual app data before any AI copy is generated.
3. THE year-review aggregation SHALL include at minimum the documented fields: `year`, `totalMatches`, `totalBets`, `roi`, `topTeam`, `topLeague`, `stadiumVisits`, `countriesWatched`, `longestStreak`, `bestMonth`, `bestRoi`, `mostWatchedRival`, `predictionsCorrect`, `predictionAccuracy`, and optional verification stats when available.
4. THE year-review aggregation SHALL not depend on Gemini to compute totals or rankings.
5. WHEN data for optional sections is unavailable, THE feature SHALL omit or degrade those sections gracefully instead of fabricating values.

---

### Requirement 6: Year in Review AI Summary

**User Story:** As a user, I want a fun AI-written summary of my year, so that the recap feels personal rather than like a static spreadsheet.

#### Acceptance Criteria

1. THE ai-insights feature SHALL support Gemini-generated year-review copy, consistent with the documented "Year in Review Copy" use case.
2. THE generated year-review summary SHALL be based on deterministic `YearReview` data supplied by the app.
3. THE generated summary SHALL populate the optional `aiSummary` field on `YearReview`.
4. THE year-review experience SHALL remain usable if `aiSummary` is unavailable; deterministic recap slides and share cards SHALL still function without AI text.
5. THE feature SHALL not rewrite or override deterministic stats based on model output.

---

### Requirement 7: AI Insights and Year Review Screens

**User Story:** As a user, I want dedicated AI insight and recap screens, so that generated insights feel like a coherent experience rather than scattered labels on existing screens.

#### Acceptance Criteria

1. THE ai-insights feature SHALL provide an `AiInsightsScreen` consistent with the Phase 3 screen inventory in [docs/DESIGN.md](../../../docs/DESIGN.md).
2. THE `AiInsightsScreen` SHALL present insight cards and pattern visualizations grounded in existing betting and diary data.
3. THE feature SHALL provide a `YearReviewScreen` or upgraded year-review experience that uses deterministic recap data and optional AI summary copy.
4. THE Year in Review experience SHALL remain compatible with the wrapped-style carousel direction already documented in architecture and design.
5. THE feature SHALL remain compatible with existing share-preview and share-card infrastructure rather than duplicating image-generation code.
6. THE AI insights UI SHALL reuse existing design tokens, stat-card patterns, and chart language rather than introducing a disconnected visual system.

---

### Requirement 8: Tier Gating and Product Access

**User Story:** As the app, I want AI insight and recap features gated by subscription tier where required, so that the shipped experience matches the documented pricing model.

#### Acceptance Criteria

1. THE ai-insights feature SHALL respect the documented pricing direction in [docs/PROJECT.md](../../../docs/PROJECT.md), where AI insights and Year in Review cards are Pro-tier value.
2. THE feature SHALL derive tier access from the authenticated user's existing subscription tier state rather than inventing a separate entitlement model.
3. WHEN a user without the required tier reaches an AI-gated surface, THE app SHALL show a clear upgrade or locked-feature state rather than crashing or leaking premium results.
4. Tier-gated UI SHALL not prevent deterministic non-premium stats elsewhere in the app from functioning.

---

### Requirement 9: Routing and Riverpod Integration

**User Story:** As a developer, I want AI insight state and recap flows wired into the existing provider graph and router, so that the final feature set behaves consistently with the rest of the app.

#### Acceptance Criteria

1. THE ai-insights feature SHALL expose Riverpod providers for deterministic review data, betting insight state, recommendation state, and AI-summary generation state.
2. THE feature SHALL expose providers or controllers for AI mutation or fetch flows separately from deterministic aggregate providers.
3. THE feature SHALL derive the active `userId` and tier access from auth or user-profile providers rather than passing them through widgets.
4. THE feature SHALL integrate with GoRouter through routes for AI insights and Year in Review surfaces.
5. THE feature SHALL reuse existing year-review and share-preview routes or infrastructure where possible instead of creating disconnected navigation duplicates.

---

### Requirement 10: Cost, Reliability, and Fallback Behavior

**User Story:** As the app, I want AI features that are cheap, bounded, and resilient, so that the product can expose insights without becoming fragile or expensive.

#### Acceptance Criteria

1. THE ai-insights feature SHALL keep Gemini usage bounded to explicit user-facing flows such as insight fetches and year-review summary generation.
2. THE feature SHALL avoid repeated identical AI requests when existing deterministic context and a recent generated result can be reused safely.
3. THE feature SHALL handle malformed or empty model responses gracefully with user-safe fallback states.
4. THE feature SHALL not block core stats, recap aggregation, or share-card generation on AI availability.
5. THE implementation SHALL remain compatible with the documented cost assumptions in [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md), where AI usage is expected to stay low-cost at realistic scale.

---

### Requirement 11: Security and Privacy

**User Story:** As a user, I want AI features to use my data carefully, so that personal history is summarized without exposing more than necessary.

#### Acceptance Criteria

1. THE ai-insights feature SHALL only send the minimum required user-history context to Gemini needed for the selected AI task.
2. THE feature SHALL use app-owned derived stats and recent-history slices as prompt inputs instead of dumping unnecessary raw data.
3. THE feature SHALL not expose secrets, auth tokens, or unrelated private records in AI prompts.
4. THE feature SHALL remain compatible with account-deletion expectations by ensuring AI-generated summaries and recap artifacts do not create undeletable shadow records outside the app's existing data model.

---

### Requirement 12: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated coverage for AI integration boundaries and deterministic recap generation, so that the feature remains trustworthy even when the model layer changes.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for deterministic year-review aggregation.
2. THE test suite SHALL include service or repository tests for Gemini betting-insight parsing and year-review summary generation using mocked responses.
3. THE test suite SHALL include widget tests for `AiInsightsScreen` and `YearReviewScreen`.
4. THE test suite SHALL use fixture-based mocked Gemini responses such as `test/fixtures/gemini/insight_response.json`; no real Gemini calls SHALL be made in automated tests.
5. FOR ALL deterministic year-review inputs, the non-AI fields of `YearReview` SHALL be identical regardless of whether AI summary generation succeeds or fails.
6. FOR ALL valid AI-summary generations, the resulting `aiSummary` SHALL not alter deterministic totals, rankings, or ROI values.
7. FOR ALL tier states below the required entitlement, AI-gated surfaces SHALL resolve to deterministic locked-state behavior instead of premium content.
