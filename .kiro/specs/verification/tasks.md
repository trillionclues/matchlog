# Implementation Tasks: Verification

## Tasks

- [ ] 1. Spec and dependency alignment
  - [ ] 1.1 Treat `.kiro/specs/verification/` as the canonical implementation spec for the verification feature
  - [ ] 1.2 Reuse existing Phase 1 and later assets (`ScannedBetSlips`, `TruthScores`, `SyncQueue`, auth verification state, match-search fixture matching, and betting linkage contracts) instead of creating duplicate trust infrastructure
  - [ ] 1.3 Keep ML Kit as the default OCR path and Gemini assist as optional fallback only

- [ ] 2. Verification domain layer
  - [ ] 2.1 Implement `lib/features/verification/domain/entities/scanned_bet_slip.dart`
  - [ ] 2.2 Implement `ExtractedBet` and truth-score entities
  - [ ] 2.3 Implement `lib/features/verification/domain/failures/verification_failure.dart`
  - [ ] 2.4 Implement `lib/features/verification/domain/repositories/verification_repository.dart`
  - [ ] 2.5 Implement use cases for `scan_bet_slip`, `verify_bet_slip`, `calculate_truth_score`, and `flag_suspicious_slip`

- [ ] 3. OCR service and parser pipeline
  - [ ] 3.1 Implement `lib/features/verification/data/ocr_service.dart` using Google ML Kit on-device OCR
  - [ ] 3.2 Implement bookmaker detection from raw OCR text
  - [ ] 3.3 Implement parser interfaces and bookmaker-specific parsers for Bet9ja, SportyBet, BetKing, and generic fallback
  - [ ] 3.4 Handle OCR noise corrections documented in tests such as `l.50` -> `1.50`
  - [ ] 3.5 Keep Gemini-assisted extraction optional and only for ambiguous OCR paths

- [ ] 4. Local persistence and sync
  - [ ] 4.1 Implement `lib/features/verification/data/verification_repository_impl.dart`
  - [ ] 4.2 Save reviewed slips locally to `ScannedBetSlips` immediately
  - [ ] 4.3 Queue remote sync work through the existing `SyncQueue` when upload or writes cannot complete immediately
  - [ ] 4.4 Upload confirmed slip images under `users/{userId}/bet_slips/{scanId}/`
  - [ ] 4.5 Keep scanned-slip history readable offline from local state

- [ ] 5. Fixture matching and bet linking
  - [ ] 5.1 Match extracted bets against real fixtures through the existing fixture-search/repository abstraction
  - [ ] 5.2 Populate `fixtureId` when a match is found and preserve null when unresolved
  - [ ] 5.3 Keep fixture matching out of widgets and inside repository/services
  - [ ] 5.4 Implement optional linked or auto-created `BetEntry` behavior in repository-owned logic when enabled

- [ ] 6. Fraud detection and verification outcomes
  - [ ] 6.1 Implement duplicate-image detection
  - [ ] 6.2 Implement metadata mismatch checks where image metadata is available
  - [ ] 6.3 Implement low OCR confidence flagging around the documented threshold direction
  - [ ] 6.4 Implement unrealistic-odds and statistical-anomaly flagging heuristics
  - [ ] 6.5 Keep flagged slips persisted and visible rather than deleting them
  - [ ] 6.6 Implement verification status transitions across pending, verified, rejected, and flagged

- [ ] 7. Truth Score
  - [ ] 7.1 Implement the documented Truth Score weighted formula
  - [ ] 7.2 Clamp the final score to `[0, 100]`
  - [ ] 7.3 Implement tier assignment for unverified, bronze, silver, gold, and diamond
  - [ ] 7.4 Expose explicit breakdown values for scan consistency, volume, recency, and flag penalty
  - [ ] 7.5 Ensure score calculations are based on verified data only

- [ ] 8. Verification UI
  - [ ] 8.1 Implement `lib/features/verification/presentation/screens/scan_slip_screen.dart`
  - [ ] 8.2 Implement `lib/features/verification/presentation/screens/slip_review_screen.dart`
  - [ ] 8.3 Implement `lib/features/verification/presentation/screens/truth_score_screen.dart`
  - [ ] 8.4 Implement scanned-slip history screen if not already present
  - [ ] 8.5 Implement `slip_card.dart`, `truth_score_badge.dart`, `verification_status_chip.dart`, and `ocr_overlay.dart`

- [ ] 9. Riverpod providers and routing
  - [ ] 9.1 Implement `verification_providers.dart` and `truth_score_providers.dart`
  - [ ] 9.2 Expose scanned-slip list state, Truth Score state, scan/review mutation state, and verification state
  - [ ] 9.3 Derive current user and verification eligibility from auth providers instead of passing them through widgets
  - [ ] 9.4 Wire routes for scan, review, Truth Score, and scanned-slip history

- [ ] 10. Security and privacy refinements
  - [ ] 10.1 Gate all scanning and Truth Score access behind verified-email eligibility
  - [ ] 10.2 Ensure OCR and review happen locally before any remote upload
  - [ ] 10.3 Restrict verification data creation and updates to the authenticated user
  - [ ] 10.4 Keep images and derived trust data compatible with account-deletion expectations

- [ ] 11. Testing
  - [ ] 11.1 Add unit tests for `scan_bet_slip`, `verify_bet_slip`, `calculate_truth_score`, and `flag_suspicious_slip`
  - [ ] 11.2 Add parser tests for bookmaker-specific extraction behavior
  - [ ] 11.3 Add repository tests for local save, sync queueing, fixture matching, verification transitions, and Truth Score retrieval
  - [ ] 11.4 Add widget tests for `ScanSlipScreen`, `SlipReviewScreen`, and `TruthScoreScreen`
  - [ ] 11.5 Add property-based tests for score clamping, score penalties, recency monotonicity, duplicate-image detection, and low-confidence flagging

- [ ] 12. Verification and cleanup
  - [ ] 12.1 Run `dart run build_runner build --delete-conflicting-outputs`
  - [ ] 12.2 Run `flutter test`
  - [ ] 12.3 Run `flutter analyze`
  - [ ] 12.4 Manually verify the core verification flow: scan slip -> review -> save -> verify -> inspect Truth Score
