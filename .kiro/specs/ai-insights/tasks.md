# Implementation Tasks: AI Insights

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/ai-insights/` as the canonical implementation spec for the ai-insights feature
  - [ ] 1.2 Reuse existing Phase 1-3 assets (`UserStats`, `BetEntry`, verification outputs, `YearReview`, share-card infrastructure, auth tier state, and app config) instead of creating duplicate analytics pipelines
  - [ ] 1.3 Keep deterministic aggregation separate from Gemini synthesis from the beginning

- [ ] 2. AI-insights domain layer
  - [ ] 2.1 Reuse the documented `YearReview` entity and its `aiSummary` field
  - [ ] 2.2 Implement `lib/features/ai_insights/domain/entities/betting_insight.dart`
  - [ ] 2.3 Implement `lib/features/ai_insights/domain/entities/match_recommendation.dart` if recommendation surfaces are shipped
  - [ ] 2.4 Implement `lib/features/ai_insights/domain/failures/ai_insights_failure.dart`
  - [ ] 2.5 Implement `lib/features/ai_insights/domain/repositories/ai_insights_repository.dart`
  - [ ] 2.6 Implement use cases for betting insight generation, match recommendations, and year-review summary generation

- [ ] 3. Deterministic aggregation
  - [ ] 3.1 Expand or implement `features/year_review/data/review_generator.dart` to compute all non-AI `YearReview` fields deterministically
  - [ ] 3.2 Aggregate diary, betting, prediction, and optional verification signals into recap data
  - [ ] 3.3 Ensure `YearReview` remains complete and useful when `aiSummary` is absent
  - [ ] 3.4 Build bounded deterministic input slices for betting-pattern analysis from recent bets and aggregate stats

- [ ] 4. Gemini service integration
  - [ ] 4.1 Implement `lib/features/ai_insights/data/ai_insight_service.dart` using Gemini 2.5 Flash
  - [ ] 4.2 Implement structured betting-insight generation with bounded prompt inputs
  - [ ] 4.3 Implement year-review summary generation from deterministic `YearReview` data
  - [ ] 4.4 Implement response validation and malformed-response fallback handling
  - [ ] 4.5 Keep AI requests bounded and avoid repeated identical calls when cached or recent outputs are sufficient

- [ ] 5. Repository and fallback behavior
  - [ ] 5.1 Implement `lib/features/ai_insights/data/ai_insights_repository_impl.dart`
  - [ ] 5.2 Gate AI calls behind user tier entitlement checks before service execution
  - [ ] 5.3 Return deterministic recap data even when AI generation fails
  - [ ] 5.4 Surface insufficient-data states for users without enough betting or watch history
  - [ ] 5.5 Ensure recommendation flows only surface real fixtures from the existing fixture system

- [ ] 6. AI insights UI
  - [ ] 6.1 Implement `lib/features/ai_insights/presentation/screens/ai_insights_screen.dart`
  - [ ] 6.2 Present structured betting insights as cards or modules grounded in user data
  - [ ] 6.3 Add deterministic visualizations derived from existing analytics rather than model-invented charts
  - [ ] 6.4 Implement locked states for non-entitled users and fallback states for AI failures

- [ ] 7. Year in Review UI
  - [ ] 7.1 Upgrade or implement `lib/features/year_review/presentation/screens/year_review_screen.dart` as the full Year in Review experience
  - [ ] 7.2 Integrate AI-written recap copy where available without blocking deterministic slides
  - [ ] 7.3 Reuse existing `review_slide.dart`, `stat_card.dart`, and `share_card_generator.dart` infrastructure instead of duplicating recap rendering
  - [ ] 7.4 Ensure Year in Review remains share-card compatible

- [ ] 8. Riverpod providers and routing
  - [ ] 8.1 Implement `ai_insights_providers.dart`
  - [ ] 8.2 Expose deterministic year-review providers separately from AI-generation providers
  - [ ] 8.3 Expose tier-entitlement providers for premium gating
  - [ ] 8.4 Derive current user and tier state from shared auth/profile providers instead of passing them through widgets
  - [ ] 8.5 Wire routes for AI insights and Year in Review surfaces

- [ ] 9. Security, privacy, and cost controls
  - [ ] 9.1 Send only the minimum required bounded user-history context to Gemini
  - [ ] 9.2 Avoid including secrets, tokens, or unrelated private data in prompts
  - [ ] 9.3 Keep deterministic data authoritative even when AI output exists
  - [ ] 9.4 Keep AI usage aligned with documented low-cost assumptions and explicit user-facing flows

- [ ] 10. Testing
  - [ ] 10.1 Add unit tests for deterministic `YearReview` aggregation
  - [ ] 10.2 Add mocked Gemini tests for betting insight generation and year-review summary generation
  - [ ] 10.3 Add malformed-response and service-failure fallback tests
  - [ ] 10.4 Add widget tests for `AiInsightsScreen` and `YearReviewScreen`
  - [ ] 10.5 Add property-based tests ensuring deterministic recap fields are unchanged by AI success/failure, `aiSummary` does not mutate totals, and locked-state behavior is deterministic for non-entitled tiers

- [ ] 11. Verification and cleanup
  - [ ] 11.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 11.2 Run `flutter test`
  - [ ] 11.3 Run `flutter analyze`
  - [ ] 11.4 Manually verify the core AI flow: open AI insights -> inspect betting insights -> open Year in Review -> confirm recap works with and without AI summary
