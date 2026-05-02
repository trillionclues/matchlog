# Design Document: Verification

## Overview

The verification feature is MatchLog's trust engine. It adds:

1. bet-slip OCR capture
2. bookmaker-specific parsing
3. editable review and local persistence
4. fixture matching and verification status
5. fraud heuristics
6. Truth Score computation and display

This feature sits across Phase 2 and Phase 3 in the product plan, but its architecture is cohesive enough to specify together now.

The key product principle is explicit in the project docs: verified truth over clout. The user should be able to see how a slip was scanned, why it was flagged or verified, and how those outcomes affect Truth Score.

---

## Architecture

### Layering

```text
Presentation  ->  Domain  <-  Data / Services
                   ^          ^
                   |          |
                 Core   ML Kit + Parsers + Drift + Storage + Fixture Matching
```

- `domain/` stays pure Dart and defines slips, extracted bets, Truth Score, failures, and use cases
- `data/` composes OCR, parsers, fixture matching, local persistence, remote sync, and fraud heuristics
- `presentation/` owns scan, review, history, and truth-score screens
- `core/` supplies auth state, sync queue, router, and shared formatting/theme primitives

### File Structure

```text
lib/
├── core/
│   ├── di/
│   │   └── providers.dart
│   └── router/
│       ├── app_router.dart
│       └── routes.dart
│
└── features/
    └── verification/
        ├── data/
        │   ├── ocr_service.dart
        │   ├── verification_repository_impl.dart
        │   ├── verification_firebase_source.dart
        │   └── parsers/
        │       ├── bet9ja_parser.dart
        │       ├── sportybet_parser.dart
        │       ├── betking_parser.dart
        │       └── generic_parser.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── scanned_bet_slip.dart
        │   │   ├── truth_score.dart
        │   │   └── verification_status.dart
        │   ├── failures/
        │   │   └── verification_failure.dart
        │   ├── repositories/
        │   │   └── verification_repository.dart
        │   └── usecases/
        │       ├── calculate_truth_score.dart
        │       ├── flag_suspicious_slip.dart
        │       ├── scan_bet_slip.dart
        │       └── verify_bet_slip.dart
        └── presentation/
            ├── providers/
            │   ├── truth_score_providers.dart
            │   └── verification_providers.dart
            ├── screens/
            │   ├── scan_slip_screen.dart
            │   ├── slip_review_screen.dart
            │   ├── truth_score_screen.dart
            │   └── scanned_slips_screen.dart
            └── widgets/
                ├── ocr_overlay.dart
                ├── slip_card.dart
                ├── truth_score_badge.dart
                └── verification_status_chip.dart
```

---

## Domain Design

### `ScannedBetSlip`

`ScannedBetSlip` is the canonical record for evidence submitted by a user.

Important invariants:

- OCR confidence is always captured as a numeric field
- raw OCR text is preserved for debugging, fallback parsing, and auditability
- fraud flags are additive metadata, not destructive deletes
- local image path and remote image URL may coexist during sync lifecycle

### `ExtractedBet`

Each extracted selection should stay minimal and auditable:

- `matchDescription`
- `prediction`
- `odds`
- optional `fixtureId`

The verification system should not overfit this model to one bookmaker's slip format.

### `TruthScore`

`TruthScore` is a derived model, not user-authored input. It must be computed from verified history using the documented weighted formula and expose both final tier and breakdown.

### `VerificationFailure`

Useful failure variants include:

- `notVerified`
- `noImage`
- `ocrFailed`
- `unsupportedSlip`
- `reviewIncomplete`
- `fixtureMatchFailed`
- `network`
- `storage`
- `unknown`

Each variant should expose presentation-safe copy.

### Repository Contract

The repository API should look roughly like this:

```dart
abstract interface class VerificationRepository {
  Future<Either<VerificationFailure, ScannedBetSlip>> scanBetSlip(File imageFile);
  Future<Either<VerificationFailure, ScannedBetSlip>> saveReviewedSlip(
    ScannedBetSlip reviewedSlip,
  );
  Future<Either<VerificationFailure, ScannedBetSlip>> verifyBetSlip(String slipId);
  Future<TruthScore> getTruthScore(String userId);
  Future<TruthScore> calculateTruthScore(String userId);
  Stream<List<ScannedBetSlip>> getScannedSlips(String userId);
}
```

---

## OCR and Parsing Design

### `OcrService`

The OCR service is ML Kit-first.

Responsibilities:

- process a captured or selected image
- return full recognized text
- compute aggregate confidence
- detect likely bookmaker

ML Kit should remain the default because the docs explicitly prioritize:

- offline support
- low latency
- privacy

### Parser Pipeline

The documented parser architecture should be preserved:

- bookmaker-specific parser list
- `canParse(rawText)`
- `parse(rawText)`

Recommended flow:

```text
OCR text available
  -> detect bookmaker
  -> choose first matching parser
  -> parse structured slip
  -> if parsing remains ambiguous, optionally invoke Gemini-assisted fallback
```

### Review Step

The review step is a hard boundary in the design:

- OCR output is not final truth
- user can correct bookmaker, bets, stake, odds, and other fields
- only confirmed reviewed data is persisted as a scan record

This keeps false OCR positives from silently entering the trust system.

---

## Data Layer Design

### Local Persistence

The foundation already provides:

- `ScannedBetSlips`
- `TruthScores`
- `SyncQueue`

Verification should be offline-first:

```text
Scan confirmed
  -> save slip locally
  -> queue remote sync if needed
  -> keep local history visible immediately
```

### Remote Persistence

Relevant remote structures from docs:

- `bet_slip_scans/{scanId}`
- `truth_scores/{userId}`
- storage path `users/{userId}/bet_slips/{scanId}/`

Responsibilities of `VerificationFirebaseSource`:

- upload slip images
- persist reviewed slip data
- read or write Truth Score cache where appropriate
- update verification status after outcome cross-checks

### Fixture Matching

After save, the system should attempt to match extracted bets to real fixtures.

Flow:

```text
Reviewed extracted bets
  -> match-search / fixture repository lookup
  -> attach fixtureId when available
  -> unresolved items remain null and reviewable
```

This keeps verification grounded in real outcomes without requiring perfect parser accuracy on first pass.

### Optional BetEntry Linking

The architecture explicitly allows:

- create `BetEntry` from scanned data

This should stay repository-owned so the UI is not forced to understand betting write semantics. A sensible Phase 2-3 approach is:

- save and verify the slip first
- then link or auto-create a `BetEntry` when the repository is configured to do so

---

## Fraud Detection Design

The fraud system should remain heuristic and explainable.

Documented heuristics:

- duplicate image detection
- EXIF metadata mismatch
- low OCR confidence
- unrealistic odds
- statistical anomaly

Key decisions:

- flags are additive
- multiple flags may coexist on one slip
- flags influence verification outcomes and Truth Score penalty
- flags do not erase the evidence trail

The threshold direction from docs should be preserved:

- low OCR confidence threshold around `0.6`
- unrealistic odds threshold around `50.0+` as a starting heuristic

---

## Truth Score Design

### Formula

The documented weights should be implemented exactly:

- scan consistency: 40%
- volume score: 25%
- recency score: 20%
- flag penalty: 15% subtracted

### Derived Inputs

The calculator needs:

- total scanned slips
- verified slips
- consistent slips
- rejected slips
- flagged slips
- last scan date

The calculator should be pure and deterministic given its input object.

### Tiering

Documented thresholds:

- diamond: `>= 90`
- gold: `>= 75`
- silver: `>= 55`
- bronze: `>= 30`
- unverified: below 30

The final score must be clamped to `[0, 100]`.

### UI Surface

The `TruthScoreScreen` and `truth_score_badge.dart` should render:

- score
- tier
- verified slip count
- verified win rate
- verified ROI
- component breakdown

The breakdown should help users understand why their score changed rather than presenting a black box.

---

## Presentation Design

### `ScanSlipScreen`

Responsibilities:

- camera or gallery entry point
- OCR overlay or scan guidance
- loading state while OCR runs
- clean handoff to review

### `SlipReviewScreen`

Responsibilities:

- editable bookmaker
- editable extracted bets
- editable stake and payout context
- confirmation action

This screen is critical because OCR confidence and parser certainty vary by bookmaker and image quality.

### `ScannedSlipsScreen`

Responsibilities:

- list prior slips
- show status chip and OCR confidence
- allow opening details

### `TruthScoreScreen`

Responsibilities:

- show current score, tier, and verified stats
- explain component breakdown
- link the user's scan history to trust output

The feature may remain compatible with later public tipster rankings without requiring them now.

---

## Provider Design

Expected Riverpod surface:

- `verificationRepositoryProvider`
- `scanBetSlipProvider`
- `saveReviewedSlipProvider`
- `verifyBetSlipProvider`
- `calculateTruthScoreProvider`
- `scannedSlipsProvider`
- `truthScoreProvider`
- `scanSlipControllerProvider`
- `slipReviewControllerProvider`

Design notes:

- derive current user and verification eligibility from auth providers
- keep OCR and parsing out of widgets
- keep Truth Score calculation pure and reusable

---

## Routing Integration

Expected route additions or wiring:

- `Routes.scanSlip`
- `Routes.slipReview`
- `Routes.truthScore`
- `Routes.scannedSlips`

The verification feature should integrate with the existing router and auth-aware route protection rather than adding custom navigation rules inside services.

---

## Security and Privacy

### Verified Access

Slip scanning and Truth Score remain gated for unverified email-password users.

### Image Handling

The user should control when images leave the device:

- capture/select locally
- OCR locally
- review locally
- upload only after confirmation

### Deletion Compatibility

Verification data must remain compatible with account deletion expectations:

- scanned slips
- storage images
- derived Truth Scores
- any linked artifacts

---

## Testing Strategy

### Unit Tests

- `scan_bet_slip_test.dart`
- `verify_bet_slip_test.dart`
- `calculate_truth_score_test.dart`
- `flag_suspicious_slip_test.dart`

### Parser Tests

- `bet9ja_parser_test.dart`
- `sportybet_parser_test.dart`
- `betking_parser_test.dart`
- `generic_parser_test.dart`

### Repository Tests

- local save
- remote sync queueing
- fixture matching behavior
- verification transition behavior
- Truth Score reads and recalculation

### Widget Tests

- `scan_slip_screen_test.dart`
- `slip_review_screen_test.dart`
- `truth_score_screen_test.dart`

### Property-Based Correctness

Properties that should be tested with generated inputs where practical:

1. `ScannedBetSlip` JSON round-trip preserves equality
2. Truth Score remains within `[0, 100]`
3. increasing flags or rejections does not increase score when other inputs are constant
4. more recent activity does not lower the recency component relative to older otherwise-identical input
5. repeated same-image submissions eventually produce `duplicateImage`
