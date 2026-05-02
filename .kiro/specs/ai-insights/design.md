# Design Document: AI Insights

## Overview

The ai-insights feature is MatchLog's Phase 3 synthesis layer. It adds:

1. Gemini-powered betting insights
2. optional match recommendations
3. the full Year in Review experience with AI-written recap copy

The core design rule is separation of concerns:

- deterministic aggregation computes the facts
- Gemini synthesizes explanations and narrative copy
- presentation renders both without confusing one for the other

This keeps the app defensible when model output is unavailable, low quality, or changes over time.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data / Services
                   ^          ^
                   |          |
                 Core   Gemini API + Deterministic Aggregators
```

- `domain/` stays pure Dart and defines recap and insight contracts
- `data/` aggregates deterministic context and calls Gemini through a dedicated service
- `presentation/` owns AI insight and year-review screens
- `core/` supplies app config, routing, auth state, and tier gating

### File Structure

```text
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
├── features/
│   ├── ai_insights/
│   │   ├── data/
│   │   │   ├── ai_insight_service.dart
│   │   │   ├── ai_insights_repository_impl.dart
│   │   │   └── prompt_builders.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── betting_insight.dart
│   │   │   │   └── match_recommendation.dart
│   │   │   ├── failures/
│   │   │   │   └── ai_insights_failure.dart
│   │   │   ├── repositories/
│   │   │   │   └── ai_insights_repository.dart
│   │   │   └── usecases/
│   │   │       ├── generate_betting_insight.dart
│   │   │       ├── generate_match_recommendations.dart
│   │   │       └── generate_year_review_summary.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── ai_insights_providers.dart
│   │       └── screens/
│   │           └── ai_insights_screen.dart
│   │
│   └── year_review/
│       ├── data/
│       │   └── review_generator.dart
│       ├── domain/
│       │   └── entities/
│       │       └── year_review.dart
│       └── presentation/
│           ├── screens/
│           │   └── year_review_screen.dart
│           └── widgets/
│               ├── review_slide.dart
│               ├── share_card_generator.dart
│               └── stat_card.dart
```

The final implementation can adapt filenames, but the responsibility split should remain this clear.

---

## Domain Design

### `YearReview`

The existing documented `YearReview` model remains the recap source of truth. AI should only enrich it via the optional `aiSummary` field.

Important rule:

- the model's numeric and ranked fields remain deterministic
- AI only writes narrative text into `aiSummary`

### `BettingInsight`

A betting-insight entity should keep AI output structured. Recommended fields:

- `strength`
- `warning`
- `suggestion`
- optional `generatedAt`

This mirrors the structured JSON response pattern already documented for Gemini.

### `MatchRecommendation`

If recommendation surfaces are shipped in Phase 3, a recommendation entity should be built around real fixtures and lightweight rationale, for example:

- `fixtureId`
- `reason`
- optional `confidenceLabel`

The entity must stay compatible with real fixture data and never represent invented matches.

### `AiInsightsFailure`

Useful failure variants include:

- `notEntitled`
- `insufficientData`
- `network`
- `invalidResponse`
- `rateLimited`
- `unknown`

Each variant should expose presentation-safe copy.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class AiInsightsRepository {
  Future<BettingInsight> generateBettingInsight({
    required String userId,
  });
  Future<List<MatchRecommendation>> generateMatchRecommendations({
    required String userId,
  });
  Future<String> generateYearReviewSummary({
    required YearReview review,
  });
}
```

This repository should depend on deterministic aggregators rather than asking the UI to construct prompt payloads.

---

## Deterministic Aggregation Design

### Betting Context Builder

Inputs:

- recent `BetEntry` list
- aggregate ROI or `UserStats`
- optionally verification-derived trust context

Responsibilities:

- slice recent history to a bounded input set
- expose deterministic ROI and profitability dimensions
- prepare prompt-ready data without making the prompt builder responsible for querying repositories

### Year Review Generator

The existing `review_generator.dart` direction should be preserved and expanded.

Responsibilities:

- aggregate diary, betting, predictions, and optional verification data for a selected year
- compute all non-AI `YearReview` fields deterministically
- expose a fully formed `YearReview` even when `aiSummary` is absent

This deterministic generator is the core of trustworthiness for the recap experience.

---

## Gemini Service Design

### `AiInsightService`

`AiInsightService` is the only layer that talks directly to Gemini.

Responsibilities:

- build request payloads
- send bounded prompt context
- request structured outputs where applicable
- parse and validate model responses

### Prompting Boundaries

For betting insight:

- send recent bets and aggregate stats
- ask for exactly the structured fields required
- do not ask the model to compute authoritative ROI or raw counts

For year-review summary:

- send deterministic `YearReview` fields
- ask for a concise recap paragraph or summary block
- preserve a clean separation between stats and prose

### Fallback Strategy

If Gemini fails:

- deterministic stats still render
- Year Review still loads without `aiSummary`
- AI Insights screen shows a recoverable fallback or retry state

This keeps the app usable and prevents AI from becoming a hard dependency for core recap flows.

---

## Presentation Design

### `AiInsightsScreen`

The AI insights screen is the Phase 3 home for generated analysis.

Primary sections:

- betting insight cards
- pattern or profitability visualizations derived from existing stats
- optional recommendation modules if enough context exists

The screen should feel additive to existing betting analytics, not like a separate chatbot product.

### `YearReviewScreen`

The year-review screen should extend the existing wrapped-style direction with:

- deterministic recap slides
- optional AI-written summary slide or section
- compatibility with share-card generation

The flow should remain compelling even if AI copy fails or is unavailable.

### Locked and Fallback States

Because AI insights and year-review cards are documented as Pro-tier value:

- non-entitled users should see a clear locked or upgrade state
- entitled users with insufficient data should see an insufficient-history state
- entitled users with temporary AI failure should still see deterministic recap content

---

## Provider Design

Expected Riverpod surface:

- `aiInsightsRepositoryProvider`
- `bettingInsightProvider`
- `matchRecommendationsProvider`
- `yearReviewProvider`
- `yearReviewSummaryProvider`
- `aiEntitlementProvider`
- `aiInsightsControllerProvider`

Design notes:

- deterministic review providers should be separate from AI generation providers
- tier gating should happen before expensive AI calls
- current user and tier should come from shared auth/profile providers

---

## Routing Integration

Expected route additions or wiring:

- `Routes.aiInsights`
- existing or upgraded `Routes.yearReview`

Where Phase 1.5 already established review/share infrastructure, Phase 3 should extend it rather than fork a separate route tree.

---

## Tier Gating Design

The project pricing docs explicitly position:

- AI insights as Pro-tier value
- Year in Review cards as Pro-tier value

Implementation decisions:

- use existing user tier state (`free`, `pro`, `crew`)
- gate expensive AI fetches and premium recap affordances before service calls
- keep deterministic non-premium analytics elsewhere intact

---

## Testing Strategy

### Unit Tests

- deterministic year-review aggregation
- prompt builder shaping
- AI response parsing

### Repository/Service Tests

- betting insight generation from mocked Gemini response
- year-review summary generation from mocked Gemini response
- fallback behavior when Gemini fails or returns malformed JSON

### Widget Tests

- `ai_insights_screen_test.dart`
- `year_review_screen_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. deterministic `YearReview` fields are unchanged by AI success/failure
2. `aiSummary` never mutates deterministic totals or rankings
3. users below required tier always resolve to locked-state behavior instead of premium content
