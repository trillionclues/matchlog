# Requirements Document

## Introduction

The Verification feature adds MatchLog's Proof of Stake system: users scan bet slips, review OCR-extracted results, verify those slips against real fixture outcomes, and build a Truth Score based on verified evidence rather than screenshots or claims. This feature spans late Phase 2 into Phase 3, but the architecture, models, and tests are already documented in the project docs and should be specified now as one coherent capability.

This feature builds on work already specified elsewhere:

1. auth already provides verified-email gating for access to verification features
2. betting already defines `BetEntry` and the concept of auto-linking or auto-creating tracked bets from scanned slips
3. match-search already defines fixture lookup contracts that the verification pipeline can reuse for fixture matching
4. Phase 1 foundation already provides local Drift tables for `ScannedBetSlips`, `TruthScores`, and `SyncQueue`
5. security and project docs already position Truth Score as a trust system grounded in verified history, not social clout

This feature must preserve the documented priorities:

1. OCR runs on-device first for speed, privacy, and offline behavior
2. slips are saved locally immediately
3. verification and truth scoring are derived from structured data and fixture cross-checks
4. fraud flags and Truth Score penalties are explicit, testable, and explainable

---

## Glossary

- **ScannedBetSlip**: The domain entity representing a scanned and parsed betting slip.
- **ExtractedBet**: One parsed selection extracted from a scanned slip.
- **TruthScore**: The aggregate trust model computed from verified slip history.
- **TruthScoreBreakdown**: The scored component breakdown used to explain a Truth Score.
- **VerificationStatus**: The state of a scanned slip, such as `pending`, `verified`, `rejected`, or `flagged`.
- **FraudFlag**: A heuristic issue marker such as duplicate image, metadata mismatch, low OCR confidence, unrealistic odds, or statistical anomaly.
- **VerificationRepository**: The abstract domain contract for scanning, reviewing, verifying, and scoring.
- **VerificationRepositoryImpl**: The data-layer implementation that composes OCR, parsing, local persistence, remote sync, and scoring.
- **OcrService**: The on-device ML Kit service that extracts raw OCR text and confidence from an image.
- **BetSlipParser**: A bookmaker-specific parser that converts raw OCR text into structured slip data.
- **ScanSlipScreen**: The capture screen for taking or selecting a slip image.
- **SlipReviewScreen**: The review surface where users correct OCR results before confirmation.
- **TruthScoreScreen**: The screen showing the user's verification profile and Truth Score breakdown.

---

## Requirements

### Requirement 1: Domain Layer Contracts

**User Story:** As a developer, I want clear verification entities, repository contracts, failures, and use cases, so that the trust system stays testable and backend-agnostic.

#### Acceptance Criteria

1. THE verification domain SHALL define a pure Dart `ScannedBetSlip` entity matching [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md): `id`, `userId`, `imageUrl`, `localImagePath`, `bookmaker`, `slipCode`, `extractedBets`, `totalOdds`, `stake`, `potentialPayout`, `currency`, `status`, `verifiedAt`, `won`, `actualPayout`, `linkedBetEntryId`, `ocrConfidence`, `rawOcrText`, `fraudFlags`, `createdAt`, and `updatedAt`.
2. THE verification domain SHALL define a pure Dart `ExtractedBet` entity with `matchDescription`, `prediction`, `odds`, and optional `fixtureId`.
3. THE verification domain SHALL define a pure Dart `TruthScore` and `TruthScoreBreakdown` model matching the documented schema and weights.
4. THE verification domain SHALL reuse the existing enums for `VerificationStatus`, `TruthTier`, and `FraudFlag` from the core/shared model definitions rather than duplicating them.
5. THE verification domain SHALL define a feature-scoped failure type that presentation code can render without inspecting ML Kit, Dio, Firebase, or file-system exceptions directly.
6. THE `VerificationRepository` interface SHALL declare operations for scanning a bet slip, reviewing or saving scan results, verifying a slip against outcomes, calculating Truth Score, and retrieving the user's scanned slips or Truth Score.
7. THE use case surface SHALL include `ScanBetSlip`, `VerifyBetSlip`, `CalculateTruthScore`, and `FlagSuspiciousSlip`.
8. FOR ALL valid `ScannedBetSlip` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.

---

### Requirement 2: Verified-Email Gating

**User Story:** As the app, I want bet-slip scanning and Truth Score features gated behind verified email for email-password users, so that verification trust cannot be gamed by throwaway accounts.

#### Acceptance Criteria

1. THE verification feature SHALL respect the verified-email gating described in [docs/SECURITY.md](../../../docs/SECURITY.md) and [docs/DATA_MODELS.md](../../../docs/DATA_MODELS.md).
2. WHEN an authenticated user has `emailVerified == false`, THE app SHALL prevent access to slip scanning and Truth Score screens or actions.
3. THE verification feature SHALL not implement a separate account-verification model that conflicts with auth's `emailVerified` state.

---

### Requirement 3: OCR Capture and On-Device Processing

**User Story:** As a user, I want bet-slip OCR to work on-device and without immediate network dependency, so that I can scan slips quickly and privately.

#### Acceptance Criteria

1. THE verification feature SHALL use Google ML Kit on-device OCR as the primary text-recognition engine, consistent with [docs/API_INTEGRATIONS.md](../../../docs/API_INTEGRATIONS.md).
2. THE OCR pipeline SHALL support camera capture or image selection as input to scanning flows.
3. THE OCR service SHALL return raw recognized text and an aggregate confidence score.
4. THE OCR service SHALL attempt bookmaker detection from raw text before parsing.
5. WHEN OCR completes successfully, THE feature SHALL route the user into an editable review flow instead of auto-publishing results silently.
6. THE OCR pipeline SHALL remain functional offline because ML Kit runs on-device.
7. IF OCR yields no usable text, THEN THE feature SHALL return a recoverable user-safe failure instead of crashing.

---

### Requirement 4: Bookmaker-Specific Parsing and Review

**User Story:** As a user, I want OCR text parsed into structured bets and then reviewed, so that I can correct machine errors before the slip is saved.

#### Acceptance Criteria

1. THE verification feature SHALL support bookmaker-specific parsing through pluggable parsers such as Bet9ja, SportyBet, BetKing, and a generic fallback parser, consistent with [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. EACH parser SHALL expose detection logic and structured parsing behavior for raw OCR text.
3. THE parsing pipeline SHALL extract, when available: bookmaker, slip code, individual bets, total odds, stake, currency, and potential payout.
4. THE parsing pipeline SHALL support OCR-noise correction patterns documented in tests, such as interpreting `l.50` as `1.50` when appropriate.
5. THE feature SHALL present OCR results in a `SlipReviewScreen` or equivalent review flow where the user can edit extracted fields before confirmation.
6. THE feature SHALL not finalize a scanned slip into persistent state until the review step is completed or explicitly confirmed by the user.
7. IF bookmaker detection fails, THEN THE review flow SHALL allow manual bookmaker correction.

---

### Requirement 5: Local Persistence and Sync

**User Story:** As a user on an unreliable connection, I want scanned slips to be saved immediately on my device, so that I do not lose evidence because of network issues.

#### Acceptance Criteria

1. WHEN a reviewed scan is confirmed, THE feature SHALL save the `ScannedBetSlip` to the local Drift `ScannedBetSlips` table immediately.
2. THE feature SHALL queue remote sync work through the existing `SyncQueue` when remote upload or write cannot complete immediately.
3. THE local save path SHALL never depend on network availability to report success on-device.
4. WHEN remote sync succeeds, THE feature SHALL update local slip state with any remote image URL or synchronized metadata.
5. THE verification feature SHALL store and sync original or cropped slip images under the documented Firebase Storage path `users/{userId}/bet_slips/{scanId}/`.
6. THE feature SHALL keep scanned-slip history readable from local storage even when the device is offline.

---

### Requirement 6: Fixture Matching and Bet Linking

**User Story:** As a user, I want scanned slip selections matched against real fixtures, so that verification can be based on actual results instead of OCR text alone.

#### Acceptance Criteria

1. THE verification feature SHALL attempt to match extracted bets against real fixtures using the documented fixture-matching direction in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md).
2. WHEN a fixture match is found, THE corresponding `ExtractedBet.fixtureId` SHALL be populated.
3. WHEN no fixture match is found, THE extracted bet SHALL remain valid but SHALL keep `fixtureId = null` until resolved.
4. THE feature SHALL remain compatible with the match-search or fixture repository abstraction rather than hardcoding fixture lookup logic in widgets.
5. THE verification feature SHALL support linking or auto-creating a `BetEntry` from scanned data when that flow is enabled by repository logic, consistent with the documented architecture direction.

---

### Requirement 7: Verification Status and Fraud Flags

**User Story:** As the app, I want scanned slips evaluated for fraud indicators and verification outcomes, so that Truth Score is grounded in evidence quality as well as result accuracy.

#### Acceptance Criteria

1. THE verification feature SHALL support the documented slip statuses: `pending`, `verified`, `rejected`, and `flagged`.
2. THE fraud-detection logic SHALL support the documented `FraudFlag` values: `duplicateImage`, `metadataMismatch`, `lowOcrConfidence`, `unrealisticOdds`, and `statisticalAnomaly`.
3. THE feature SHALL detect duplicate-image reuse through an image-hash or equivalent deduplication strategy.
4. THE feature SHALL flag metadata mismatches when image metadata and fixture timing materially conflict, where such metadata is available.
5. THE feature SHALL flag slips when OCR confidence is below the documented threshold direction of `0.6`.
6. THE feature SHALL flag unrealistic odds anomalies, such as very high odds values, according to repository or fraud-service rules grounded in the documented heuristics.
7. THE feature SHALL allow a slip to remain saved even if it is flagged, because flags inform verification and Truth Score rather than erasing the record.

---

### Requirement 8: Truth Score Computation

**User Story:** As a user, I want a Truth Score that reflects verified betting history over time, so that trust is earned through data rather than screenshots.

#### Acceptance Criteria

1. THE verification feature SHALL compute Truth Score using the documented weighted breakdown in [docs/ARCHITECTURE.md](../../../docs/ARCHITECTURE.md): scan consistency 40%, volume score 25%, recency score 20%, and flag penalty 15% subtracted.
2. THE Truth Score calculator SHALL clamp the final score to the inclusive range `[0, 100]`.
3. THE Truth Score calculator SHALL assign tiers using the documented thresholds: diamond `>= 90`, gold `>= 75`, silver `>= 55`, bronze `>= 30`, otherwise unverified.
4. THE Truth Score SHALL be derived from verified data, not from unverified self-reported history.
5. THE Truth Score breakdown SHALL expose scan consistency, volume score, recency score, and flag penalty as explicit fields.
6. WHEN no scans or no verified data exist, THE Truth Score system SHALL return safe zero or unverified outputs instead of `NaN` or crashes.
7. THE Truth Score screen SHALL present verified slip count, verified win rate, verified ROI, and the tier badge consistently with the design direction in [docs/DESIGN.md](../../../docs/DESIGN.md).

---

### Requirement 9: Screens and User Flows

**User Story:** As a user, I want clear scan, review, and trust-profile screens, so that verification feels understandable instead of opaque.

#### Acceptance Criteria

1. THE verification feature SHALL provide a `ScanSlipScreen` for camera capture or image import.
2. THE feature SHALL provide a `SlipReviewScreen` for editing OCR results and bookmaker corrections before confirmation.
3. THE feature SHALL provide a `TruthScoreScreen` showing the user's Truth Score, tier, and breakdown.
4. THE feature SHALL provide a scanned-slip history surface so users can inspect their prior submissions and statuses, consistent with the design inventory.
5. THE feature MAY remain compatible with a later public tipster rankings screen, but SHALL not require public rankings to ship in order to deliver the user-owned verification loop.
6. THE verification UI SHALL reuse the existing design tokens, semantic colors, and odds typography defined elsewhere in the app.

---

### Requirement 10: Routing and Riverpod Integration

**User Story:** As a developer, I want verification state and screens wired into the existing provider graph and router, so that the feature behaves consistently with the rest of the app.

#### Acceptance Criteria

1. THE verification feature SHALL expose Riverpod providers for scan state, review state, scanned-slip list state, fraud-flag state, verification status state, and Truth Score state.
2. THE verification feature SHALL expose providers for core use cases such as scanning, verifying, and Truth Score calculation.
3. THE feature SHALL derive the active `userId` and verification eligibility from auth providers instead of passing them through widgets.
4. THE feature SHALL integrate with GoRouter through routes for scan, review, Truth Score, and scanned-slip history surfaces.
5. THE verification feature SHALL keep OCR, parsing, fixture matching, and scoring logic in services, repositories, or providers rather than inside widgets.

---

### Requirement 11: Security, Privacy, and Compliance

**User Story:** As a user, I want sensitive slip images and trust data handled carefully, so that verification improves trust without leaking personal evidence unnecessarily.

#### Acceptance Criteria

1. THE verification feature SHALL keep OCR processing on-device by default, consistent with the documented ML Kit approach.
2. THE feature SHALL not upload raw slip images or extracted verification data before the user confirms the review step.
3. THE feature SHALL only create or update verification records for the authenticated user.
4. THE feature SHALL keep scanned-slip images in the authenticated user's storage namespace.
5. THE feature SHALL remain compatible with account-deletion expectations by ensuring slip data, derived Truth Scores, and related storage artifacts fit the documented deletion model.
6. THE feature SHALL not require Gemini-based OCR assist for baseline functionality; Gemini fallback remains optional and only for ambiguous OCR extraction paths.

---

### Requirement 12: Testing and Correctness Properties

**User Story:** As a developer, I want strong automated coverage for OCR parsing, fraud flags, and Truth Score, so that the trust system behaves predictably under edge cases.

#### Acceptance Criteria

1. THE test suite SHALL include unit tests for `ScanBetSlip`, `VerifyBetSlip`, `CalculateTruthScore`, and `FlagSuspiciousSlip`.
2. THE test suite SHALL include parser tests for bookmaker-specific parsers such as Bet9ja and any other parser shipped in Phase 2-3.
3. THE test suite SHALL include repository tests covering local save, remote sync queuing, fixture matching, verification transitions, and Truth Score reads.
4. THE test suite SHALL include widget tests for `ScanSlipScreen`, `SlipReviewScreen`, and `TruthScoreScreen`.
5. FOR ALL valid `ScannedBetSlip` instances, JSON serialization followed by deserialization SHALL return an equivalent entity.
6. FOR ALL Truth Score inputs, THE final `truthScore` SHALL remain within `[0, 100]`.
7. FOR ALL Truth Score inputs, increasing flagged or rejected slip counts while holding other inputs constant SHALL not increase the final Truth Score.
8. FOR ALL Truth Score inputs, more recent verification activity SHALL not reduce the recency component relative to otherwise identical older activity.
9. FOR ALL repeated image submissions with the same perceptual hash for the same user, THE fraud service SHALL eventually flag `duplicateImage`.
10. FOR ALL OCR-confidence inputs below the configured threshold, THE fraud service SHALL flag `lowOcrConfidence`.
