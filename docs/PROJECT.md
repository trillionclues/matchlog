# MatchLog — Project Overview

> Social Sports Diary + Betting Tracker. Letterboxd meets Strava, but for football.

---

## Vision

MatchLog is a mobile-first platform where sports fans log matches they've watched, track betting performance across bookmakers, follow friends' predictions, and get AI-powered insights. It starts with football and expands to any sport with organized fixtures and betting markets.

**One-liner:** *"The sports diary you'll check more than your betting app."*

---

## Problem Statement

| Gap | Detail |
|-----|--------|
| **No cross-platform betting analytics** | Users bet on Bet9ja, SportyBet, 1xBet, BetKing simultaneously. No tool tracks ROI across all of them. |
| **No match diary exists** | Letterboxd (movies), Untappd (beer), Goodreads (books) — nothing equivalent for sports. |
| **Betting apps are transactional** | They process bets. They don't help you understand your betting patterns or connect with friends. |
| **No social layer for match-going fans** | Stadium check-ins, photo uploads, match reviews — all live in random WhatsApp groups and Instagram stories. |
| **Fake tipsters are unchecked** | "Tipsters" flood Twitter/WhatsApp with photoshopped won tickets. No way to verify a tipster's actual ROI. Users get scammed following unverified predictions. |

---

## Product Principles

1. **Diary first, betting second.** The core value is logging and reflecting on your sports experience. Betting tracking is a feature, not the identity. This keeps us out of regulatory trouble and app store rejections.

2. **Useful solo before social.** The personal tool must be compelling before any social features ship. This is the Strava principle — individual tracking → social amplification.

3. **Sport-agnostic architecture.** Football is Phase 1, but the data model supports basketball, F1, UFC, cricket, and tennis from day one. No schema migration when we expand.

4. **Offline-first.** Target users are in African markets with unreliable connectivity. Every core action works offline and syncs when connected.

5. **Low price, high adoption.** Pro at $1.99/mo and Crew at $2.99/mo — priced to acquire users in price-sensitive markets. Volume over margin.

6. **Verified truth over clout.** Any user can claim a 90% win rate. MatchLog verifies it with scanned bet slips and computed Truth Scores. Trust is earned through data, not screenshots.

---

## Platform

- **Frontend:** Flutter (iOS + Android). No web frontend.
- **Backend (Phase 1-3):** Firebase (Auth, Firestore, Storage, FCM, Cloud Functions)
- **Backend (Phase 4+):** Spring Boot + PostgreSQL + Redis (Java learning project)
- **AI:** Gemini 2.5 Flash for betting insights and notification personalization

---

## Pricing Tiers

| Tier | Price | Key Features |
|------|-------|-------------|
| **Free** | $0 | Unlimited match diary, basic stats, 1 Bookie Group (5 members), 20 bets/mo, 5 photos/mo |
| **Pro** | $1.99/mo · $14.99/yr | Unlimited bets, advanced ROI analytics, AI insights, Year in Review cards, calendar heatmap, CSV/PDF export, ad-free |
| **Crew** | $2.99/mo · $24.99/yr | Everything in Pro + unlimited Bookie Groups, Prediction Leagues, group analytics, priority support |

---

## Revenue Streams

| Stream | When |
|--------|------|
| **Subscriptions** (primary) | Phase 3+ |
| **Betting Affiliates** (Bet9ja 25% rev share) | Phase 2+ |
| **Prediction Tipping** (10-15% platform fee) | Phase 3+ |

---

## Phased Delivery

| Phase | Timeline | Outcome |
|-------|----------|---------|
| **Phase 1** | Weeks 1–6 | Core Flutter + Firebase → Google Play + TestFlight |
| **Phase 1.5** | Weeks 7–8 | Stadium check-in, push notifications, calendar heatmap, social cards |
| **Phase 2** | Weeks 9–12 | Social layer, Bookie Groups, predictions, bet slip OCR scan |
| **Phase 3** | Weeks 13–16 | AI insights, Prediction Leagues, Truth Score system, monetization, polish |
| **Phase 4** | Weeks 17–24 | Spring Boot backend rebuild (Java roadmap) |
| **Phase 5** | Weeks 25+ | Docker orchestration, CI/CD, monitoring |

---

## Related Documentation

| Document | Path |
|----------|------|
| Architecture | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Development Guide | [DEVELOPMENT.md](./DEVELOPMENT.md) |
| API Integrations | [API_INTEGRATIONS.md](./API_INTEGRATIONS.md) |
| Data Models | [DATA_MODELS.md](./DATA_MODELS.md) |
| Security | [SECURITY.md](./SECURITY.md) |
| Git Workflow | [GIT_WORKFLOW.md](./GIT_WORKFLOW.md) |
| Testing Strategy | [TESTING.md](./TESTING.md) |
| Deployment Plan | [DEPLOYMENT.md](./DEPLOYMENT.md) |
| Design System | [DESIGN.md](./DESIGN.md) |

---

## Competitive Landscape

| Tool | What It Does | MatchLog's Edge |
|------|-------------|----------------|
| **Bet9ja / SportyBet** | Place bets | Transactional only. No cross-platform history. No social. |
| **FotMob / LiveScore** | Live scores + stats | No personal diary. No betting tracker. |
| **FPL** | Premier League fantasy | Single league, rigid rules. MatchLog = any league, any sport, flexible scoring. |
| **Strava** | Social fitness tracking | Proven model for sports — we apply it to watching, not running. |
| **Letterboxd** | Social movie diary | Proven model for media — we apply it to sports. |
| **Twitter/WhatsApp tipsters** | Post "won ticket" screenshots | Unverified, easily faked. MatchLog = verified ROI via OCR-scanned bet slips + computed Truth Score. |

---

## Key Risks

| Risk | Mitigation |
|------|-----------|
| App store rejection ("betting app") | Frame as "Sports Diary & Match Journal." Diary is primary, betting is a feature. |
| API rate limits (100 calls/day free tier) | TheSportsDB as primary (30 req/min free). Aggressive Drift caching. Daily pre-fetch. |
| Scope creep | Hard 6-week deadline for Phase 1. Cut anything blocking ship date. |
| Low adoption | Seed with 10-20 friends in WhatsApp groups. Portfolio value = engineering, not DAU. |
