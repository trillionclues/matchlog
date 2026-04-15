# MatchLog — Design System

> FPL-inspired dark-mode-first design system. Built for data-dense sports content with premium feel.

---

## Design Philosophy

MatchLog's UI draws inspiration from the **Fantasy Premier League (FPL)** app — a dark, data-rich interface that feels authoritative and exciting. But where FPL is a management tool, MatchLog is a **social diary** — so we add warmth, personality, and social engagement patterns from Letterboxd and Strava.

### Design Principles

| Principle | Detail |
|-----------|--------|
| **Dark mode first** | Deep dark backgrounds. Light mode is secondary (or deferred). |
| **Data density** | Sports fans want information. Every screen should feel rich, not sparse. |
| **Scan-friendly** | League tables, leaderboards, bet lists — designed for rapid scanning. |
| **Premium, not corporate** | Gradients, subtle glow effects, rounded cards. Not flat/material-default. |
| **Motion with purpose** | Micro-animations for state changes (bet won/lost, prediction settled). Not decorative. |
| **Sport-aware theming** | Accent colors can adapt per sport context (green for football, orange for basketball). |

---

## Color Palette

### Core Palette (FPL-Inspired)

```dart
// core/theme/colors.dart

class MatchLogColors {
  // Backgrounds
  static const background = Color(0xFF0E0B16);       // Deep dark purple-black
  static const surface = Color(0xFF1A1625);           // Card/surface background
  static const surfaceElevated = Color(0xFF241F31);   // Elevated cards, modals
  static const surfaceBorder = Color(0xFF2D2640);     // Subtle borders

  // Primary (FPL Razzmatazz-inspired — vibrant magenta/pink)
  static const primary = Color(0xFFE90052);           // Primary buttons, CTAs
  static const primaryLight = Color(0xFFFF3378);      // Hover/pressed states
  static const primaryDark = Color(0xFFB80042);       // Active state
  static const primarySurface = Color(0xFF2A0F1D);    // Primary tint on dark bg

  // Secondary (Electric violet accent)
  static const secondary = Color(0xFF963CFF);         // Charts, badges, accents
  static const secondaryLight = Color(0xFFB06FFF);    // Lighter accent
  static const secondaryDark = Color(0xFF7B2DD4);     // Darker accent
  static const secondarySurface = Color(0xFF1A0F2A);  // Secondary tint on dark bg

  // Success (Bet won, correct prediction)
  static const success = Color(0xFF00DC82);           // Green — won/correct
  static const successSurface = Color(0xFF0A1F16);    // Green tint background

  // Error (Bet lost, incorrect prediction)
  static const error = Color(0xFFFF4D6A);             // Red — lost/incorrect
  static const errorSurface = Color(0xFF1F0A10);      // Red tint background

  // Warning (Pending, needs attention)
  static const warning = Color(0xFFFFB800);           // Amber — pending bets
  static const warningSurface = Color(0xFF1F1A0A);    // Amber tint background

  // Text
  static const textPrimary = Color(0xFFFFFFFF);       // Headlines, primary text
  static const textSecondary = Color(0xFFB0A8C0);     // Body text, descriptions
  static const textTertiary = Color(0xFF6B6080);      // Captions, timestamps
  static const textDisabled = Color(0xFF4A4058);      // Disabled states

  // Sport-specific accents (used when sport context is active)
  static const footballAccent = Color(0xFF00DC82);    // Green — the pitch
  static const basketballAccent = Color(0xFFFF8A00);  // Orange — basketball
  static const f1Accent = Color(0xFFE10600);          // Red — F1
  static const mmaAccent = Color(0xFFFF6B35);         // Orange-red — UFC
  static const cricketAccent = Color(0xFF00B4D8);     // Blue — cricket
  static const tennisAccent = Color(0xFFCCFF00);      // Yellow-green — tennis
}
```

### Gradient Definitions

```dart
class MatchLogGradients {
  // Hero/feature card gradient
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF963CFF), Color(0xFFE90052)],
  );

  // Stats dashboard gradient
  static const statsGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF241F31), Color(0xFF0E0B16)],
  );

  // Bet won card overlay
  static const wonGradient = LinearGradient(
    colors: [Color(0x4000DC82), Color(0x00000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bet lost card overlay
  static const lostGradient = LinearGradient(
    colors: [Color(0x40FF4D6A), Color(0x00000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Leaderboard rank background (top 3)
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
  );
  static const silverGradient = LinearGradient(
    colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
  );
  static const bronzeGradient = LinearGradient(
    colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
  );
}
```

---

## Typography

```dart
// core/theme/typography.dart

// Using Google Fonts: Inter (clean, modern, excellent for data-dense UIs)
// Alternatives: Outfit, DM Sans, or Plus Jakarta Sans

class MatchLogTypography {
  static final headlineXL = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: MatchLogColors.textPrimary,
    letterSpacing: -0.5,
  );

  static final headlineLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: MatchLogColors.textPrimary,
    letterSpacing: -0.3,
  );

  static final headlineMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MatchLogColors.textPrimary,
  );

  static final headlineSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MatchLogColors.textPrimary,
  );

  static final bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MatchLogColors.textSecondary,
    height: 1.5,
  );

  static final bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MatchLogColors.textSecondary,
    height: 1.5,
  );

  static final bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MatchLogColors.textTertiary,
  );

  static final labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: MatchLogColors.textPrimary,
    letterSpacing: 0.5,
  );

  static final labelSmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: MatchLogColors.textTertiary,
    letterSpacing: 0.5,
  );

  // Stat numbers — large, bold, eye-catching
  static final statNumber = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: MatchLogColors.textPrimary,
  );

  // Odds display — monospaced feel
  static final oddsDisplay = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: MatchLogColors.primary,
  );
}
```

---

## Spacing & Layout

```dart
// core/theme/spacing.dart

class MatchLogSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  // Screen padding
  static const screenPadding = EdgeInsets.symmetric(horizontal: 16.0);

  // Card padding
  static const cardPadding = EdgeInsets.all(16.0);
  static const cardPaddingCompact = EdgeInsets.all(12.0);

  // Card radius
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;
  static const radiusFull = 100.0;  // Pill shape
}
```

---

## Component Library

### 1. Match Card (Diary Entry)

```
┌─────────────────────────────────────┐
│  PL  ·  Emirates Stadium  ·  📺 TV │  ← Meta line (league, venue, watch type)
│                                     │
│  ┌────┐                   ┌────┐   │
│  │ 🔴 │  Arsenal   2 - 1  │ 🔵 │   │  ← Team badges + score
│  └────┘                   └────┘   │
│                                     │
│  ⭐⭐⭐⭐☆  "What a game..."       │  ← Rating + truncated review
│                                     │
│  📸 3 photos    📅 Apr 15, 2025    │  ← Photo count + date
└─────────────────────────────────────┘
```

**Design Notes:**
- Dark surface background (`surfaceElevated`)
- Team badges loaded from TheSportsDB API
- Score in `headlineLarge`, bold white
- Star rating in `warning` color (amber)
- Subtle left border in sport accent color (green for football)
- Tap → full entry detail screen

### 2. Bet Card

```
┌─────────────────────────────────────┐
│  ┌──────────────────────────┐       │
│  │ Arsenal to Win  @  2.10  │  WON  │  ← Prediction + odds + result badge
│  └──────────────────────────┘       │
│                                     │
│  Bet9ja  ·  ₦1,000  →  ₦2,100     │  ← Bookmaker, stake, payout
│                                     │
│  Premier League  ·  Apr 15, 2025   │  ← League + date
└─────────────────────────────────────┘
```

**Design Notes:**
- **Won**: Left border `success` green + subtle `wonGradient` overlay
- **Lost**: Left border `error` red + subtle `lostGradient` overlay
- **Pending**: Left border `warning` amber, pulsing dot indicator
- Odds displayed in `oddsDisplay` font (monospaced)
- Payout in `success` color when won

### 3. Stats Dashboard

```
┌─────────────────────────────────────┐
│            YOUR STATS               │
├──────────┬──────────┬───────────────┤
│  45      │  68%     │  +12.5%       │
│  Matches │  Win Rate│  ROI          │
├──────────┴──────────┴───────────────┤
│                                     │
│  ┌─── ROI Over Time ─────────────┐  │
│  │                     ╱╲        │  │
│  │              ╱╲   ╱╱  ╲       │  │
│  │        ╱╲  ╱╱  ╲╱╱     ╲     │  │
│  │  ╱╲  ╱╱  ╲╱               ╲  │  │
│  │╱╱  ╲╱                       ╲│  │
│  │ Jan  Feb  Mar  Apr  May      │  │
│  └──────────────────────────────┘  │
│                                     │
│  Best League: Premier League  +25%  │
│  Best Type:   Home Favorites  +18%  │
│  Worst Book:  1xBet           -12%  │
└─────────────────────────────────────┘
```

**Design Notes:**
- Top stats in `statNumber` font with gradient background
- ROI chart is a **CustomPainter** with gradient fill under the line
- Chart line in `primary` color, fill in `primarySurface` with 20% opacity
- Positive ROI in `success` green, negative in `error` red
- Best/worst stats with colored accent bars

### 4. Leaderboard (Bookie Group)

```
┌─────────────────────────────────────┐
│  🏆  MONDAY NIGHT CREW             │
│  PW: 15  ·  8 members              │
├─────────────────────────────────────┤
│  🥇  1.  Excel      78%   142 pts  │  ← Gold gradient bg
│  🥈  2.  Tunde      71%   128 pts  │  ← Silver gradient bg
│  🥉  3.  Chris      65%   115 pts  │  ← Bronze gradient bg
│      4.  Sarah      62%   108 pts  │
│      5.  David      58%    98 pts  │
│ ─────────────────────────────────── │
│  👤  6.  You        55%    92 pts  │  ← Highlighted (your position)
│      7.  James      50%    85 pts  │
│      8.  Mike       45%    72 pts  │
└─────────────────────────────────────┘
```

**Design Notes:**
- Top 3 have gradient backgrounds (gold/silver/bronze)
- Current user's row highlighted with `primarySurface` background
- Win percentage in `success`/`error` color based on threshold (>50% = green)
- Points in `headlineSmall`
- Smooth scrolling, sticky header

### 5. Calendar Heatmap

```
┌─────────────────────────────────────┐
│  📅  MATCH ACTIVITY                 │
│                                     │
│  Mon  ░ ░ █ ░ ░ ▓ ░ ░ ▓ █ ░ ░     │
│  Tue  ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░     │
│  Wed  ░ ▓ ░ ░ █ ░ ░ ░ ░ ▓ ░ ░     │
│  Thu  ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░     │
│  Fri  ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░     │
│  Sat  █ ▓ █ ▓ █ █ ▓ █ ▓ █ █ ▓     │
│  Sun  ▓ █ ▓ █ ▓ ▓ █ ▓ █ ▓ ▓ █     │
│                                     │
│  ░ None  ▓ 1-2 matches  █ 3+ matches│
│                                     │
│  🔥 12-week streak                  │
└─────────────────────────────────────┘
```

**Design Notes:**
- Built with **CustomPainter** — each cell is a rounded rectangle
- Color scale: `surfaceBorder` (none) → `secondary` 30% → `secondary` 70% → `secondary` 100%
- Tap on a cell → show matches from that day
- Current streak highlighted with `primary` underline

### 6. Year in Review Card (Shareable)

```
┌─────────────────────────────────────┐
│                                     │
│    MatchLog                         │
│    YOUR 2025 IN FOOTBALL ⚽         │
│                                     │
│    ┌────────────────────────────┐   │
│    │        156               │   │
│    │     MATCHES WATCHED       │   │
│    └────────────────────────────┘   │
│                                     │
│    🏟️  12 Stadium Visits            │
│    🏆  Arsenal — Your #1 Team      │
│    📊  +18.5% ROI                   │
│    🔥  24 Correct Predictions       │
│    📸  89 Match Day Photos          │
│                                     │
│    ──────────────────────────────   │
│    matchlog.app · @trillionclues    │
│                                     │
└─────────────────────────────────────┘
```

**Design Notes:**
- Background: `heroGradient` (purple → pink)
- Stats in `statNumber` font, white
- Icons add personality
- Bottom watermark for organic sharing
- Generated as PNG via `RepaintBoundary.toImage()`
- Multiple card templates: portrait (Instagram Story), square (feed post), landscape (Twitter)

### 7. Prediction Card

```
┌─────────────────────────────────────┐
│  👤 Excel  ·  🟢 High Confidence   │
│                                     │
│  Arsenal 2 - 1 Chelsea              │
│  ⏰ Kickoff: Sat 15:00              │
│                                     │
│  Status: ✅ CORRECT (+3 pts)        │
│          or                         │
│  Status: ⏳ PENDING                 │
│          or                         │
│  Status: ❌ WRONG (0 pts)           │
└─────────────────────────────────────┘
```

### 8. Bottom Navigation

```
┌─────────────────────────────────────┐
│  📖        🎯        👥        ⚙️  │
│ Diary    Betting   Social    More   │
└─────────────────────────────────────┘
```

| Tab | Screen | Icon | Phase |
|-----|--------|------|-------|
| **Diary** | Match feed + stats | Book/journal | Phase 1 |
| **Betting** | Bet log + ROI | Target/bullseye | Phase 1 |
| **Social** | Feed + Groups | People | Phase 2 |
| **More** | Profile, Settings, Year Review | Gear | Phase 1 |

---

## Theme Definition

```dart
// core/theme/app_theme.dart
class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: MatchLogColors.background,
    colorScheme: const ColorScheme.dark(
      primary: MatchLogColors.primary,
      secondary: MatchLogColors.secondary,
      surface: MatchLogColors.surface,
      error: MatchLogColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: MatchLogColors.textPrimary,
      onError: Colors.white,
    ),

    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: MatchLogColors.background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: MatchLogTypography.headlineMedium,
      iconTheme: const IconThemeData(color: MatchLogColors.textPrimary),
    ),

    // Cards
    cardTheme: CardTheme(
      color: MatchLogColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        side: const BorderSide(color: MatchLogColors.surfaceBorder, width: 1),
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MatchLogColors.surface,
      selectedItemColor: MatchLogColors.primary,
      unselectedItemColor: MatchLogColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: MatchLogColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        ),
        textStyle: MatchLogTypography.labelLarge,
        elevation: 0,
      ),
    ),

    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MatchLogColors.primary,
        textStyle: MatchLogTypography.labelLarge,
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MatchLogColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        borderSide: const BorderSide(color: MatchLogColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        borderSide: const BorderSide(color: MatchLogColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        borderSide: const BorderSide(color: MatchLogColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusMd),
        borderSide: const BorderSide(color: MatchLogColors.error),
      ),
      hintStyle: MatchLogTypography.bodyMedium.copyWith(
        color: MatchLogColors.textTertiary,
      ),
      labelStyle: MatchLogTypography.labelSmall,
    ),

    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: MatchLogColors.surfaceElevated,
      selectedColor: MatchLogColors.primarySurface,
      labelStyle: MatchLogTypography.labelSmall,
      side: const BorderSide(color: MatchLogColors.surfaceBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusFull),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: MatchLogColors.surfaceBorder,
      thickness: 1,
      space: 0,
    ),

    // Dialog
    dialogTheme: DialogTheme(
      backgroundColor: MatchLogColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MatchLogSpacing.radiusLg),
      ),
    ),
  );
}
```

---

## Animations & Micro-Interactions

### Flutter Animate Presets

```dart
// shared/widgets/animations.dart

// Card entrance (used in lists)
extension MatchLogAnimations on Widget {
  Widget fadeSlideIn({int index = 0}) {
    return animate()
      .fadeIn(
        duration: 400.ms,
        delay: (50 * index).ms,
        curve: Curves.easeOutCubic,
      )
      .slideY(
        begin: 0.05,
        end: 0,
        duration: 400.ms,
        delay: (50 * index).ms,
        curve: Curves.easeOutCubic,
      );
  }

  // Bet settlement animation (scale + color change)
  Widget betSettled({required bool won}) {
    return animate()
      .scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.0, 1.0),
        duration: 300.ms,
        curve: Curves.elasticOut,
      )
      .then()  // Sequential
      .shimmer(
        duration: 600.ms,
        color: won
          ? MatchLogColors.success.withOpacity(0.3)
          : MatchLogColors.error.withOpacity(0.3),
      );
  }

  // Stat counter animation (count up)
  Widget countUp() {
    return animate()
      .fadeIn(duration: 300.ms)
      .custom(
        duration: 800.ms,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => child, // Use AnimatedCount widget
      );
  }

  // Prediction correct celebration
  Widget celebrateCorrect() {
    return animate()
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: 150.ms,
      )
      .then()
      .scale(
        begin: const Offset(1.05, 1.05),
        end: const Offset(1.0, 1.0),
        duration: 150.ms,
      )
      .then()
      .shimmer(
        duration: 500.ms,
        color: MatchLogColors.success.withOpacity(0.5),
      );
  }
}
```

### When to Animate

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| List item appears | Fade + slide up (staggered) | 400ms |
| Bet settlement | Scale bounce + color shimmer | 900ms |
| Tab switch | Crossfade | 200ms |
| Pull to refresh | Bounce | 300ms |
| Stat number loads | Count up from 0 | 800ms |
| Star rating tap | Scale + color fill | 150ms |
| Prediction correct | Bounce + green shimmer | 650ms |
| Prediction wrong | Gentle shake + red tint | 400ms |
| Card expand | Height animation | 300ms |
| FAB tap | Ripple + screen transition | 250ms |

---

## Icon System

Use **Lucide Icons** (`lucide_icons` package) for consistency:

| Action | Icon | Usage |
|--------|------|-------|
| Diary | `LucideIcons.bookOpen` | Bottom nav |
| Betting | `LucideIcons.target` | Bottom nav |
| Social | `LucideIcons.users` | Bottom nav |
| Settings | `LucideIcons.settings` | Bottom nav / profile |
| Search | `LucideIcons.search` | Search bar |
| Add/Log | `LucideIcons.plus` | FAB |
| Stadium | `LucideIcons.mapPin` | Check-in |
| Camera | `LucideIcons.camera` | Photo upload |
| Share | `LucideIcons.share2` | Share card |
| Calendar | `LucideIcons.calendar` | Heatmap |
| Trophy | `LucideIcons.trophy` | Leaderboard |
| Star | `LucideIcons.star` | Rating |
| Trend up | `LucideIcons.trendingUp` | Positive ROI |
| Trend down | `LucideIcons.trendingDown` | Negative ROI |
| Filter | `LucideIcons.filter` | Filter controls |
| Bell | `LucideIcons.bell` | Notifications |

---

## Screen Inventory

### Phase 1

| Screen | Key Components | Navigation |
|--------|---------------|-----------|
| **Onboarding** (3 slides) | Illustrations, swipe carousel | → Login |
| **Login** | Social buttons, email form | → Register / Home |
| **Register** | Email/password form, terms | → Home |
| **Diary Feed** | Match card list, filter chips, FAB | Tab 1 (Home) |
| **Log Match** | Search → Select → Rate → Review → Submit | FAB → Modal/Push |
| **Match Detail** | Full entry view, photos, review | Card tap |
| **Betting Feed** | Bet card list, filter (pending/settled), FAB | Tab 2 |
| **Log Bet** | Match → Type → Odds → Stake → Bookmaker | FAB → Modal/Push |
| **Stats Dashboard** | ROI chart, stat cards, breakdowns | Diary → Tab |
| **Profile** | Avatar, stats summary, settings | Tab 4 |
| **Settings** | Notifications, privacy, account, about | Profile → Push |

### Phase 1.5

| Screen | Key Components |
|--------|---------------|
| **Calendar Heatmap** | CustomPainter grid, day detail modal |
| **Stadium Check-In** | Map view, GPS verification, badge |
| **Year in Review** | Wrapped-style carousel, share cards |
| **Notification Settings** | Channel toggles, frequency controls |

### Phase 2

| Screen | Key Components |
|--------|---------------|
| **Activity Feed** | Social cards, infinite scroll |
| **User Profile (Other)** | Stats, recent activity, follow button |
| **Followers/Following** | User list, follow/unfollow actions |
| **User Search** | Search bar, suggested users |
| **Groups List** | Group cards, create button |
| **Group Detail** | Members, predictions, leaderboard tabs |
| **Create Group** | Name, privacy, league focus form |
| **Prediction Board** | Upcoming fixtures, prediction inputs |
| **Leaderboard** | Ranked member list, your position |
| **Join Group** | Invite code input / deep link landing |

### Phase 3

| Screen | Key Components |
|--------|---------------|
| **AI Insights** | Insight cards, pattern visualizations |
| **Prediction League** | Season standings, weekly round |
| **Subscription** | Tier comparison, IAP flow |
| **Share Preview** | Generated card preview, share sheet |

---

## Responsive Layout

```dart
// Breakpoints (primarily for tablets / foldables)
class Breakpoints {
  static const mobile = 600.0;     // < 600: single column
  static const tablet = 900.0;     // 600-900: adaptive
  static const desktop = 1200.0;   // > 900: two column (foldables)
}

// Adaptive layout wrapper
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.tablet && tablet != null) return tablet!;
    return mobile;
  }
}
```

---

## Loading States

```dart
// 1. Shimmer loading (for lists)
class MatchCardShimmer extends StatelessWidget {
  // Uses shimmer package to create a pulsing placeholder
  // matching the exact dimensions of a real MatchCard
}

// 2. Empty state
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaText;
  final VoidCallback? onCta;
  // Centered icon + text + optional CTA button
}

// 3. Error state
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  // Icon + message + retry button
}
```

---

## App Icon & Splash

### App Icon

- **Shape**: Rounded square (Android adaptive icon)
- **Design**: MatchLog "M" monogram on gradient background (`heroGradient`)
- **Package**: `flutter_launcher_icons` for generation

### Splash Screen

- **Background**: `background` color
- **Center**: MatchLog logo (white on dark)
- **Package**: `flutter_native_splash` for native splash generation
