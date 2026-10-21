# UPSC Wars — UI Redesign Brief

## How to use this brief (instructions for the designer / LLM)

You are redesigning the UI of **UPSC Wars**, a Flutter mobile app (Android + iOS, phone-first, also runs on tablets/web) for students preparing for the **UPSC Civil Services Prelims** exam in India.

- Keep every feature and flow listed below; redesign how they look and feel, not what they do.
- Output should be implementable in **Flutter (Material 3)**. Prefer: a design-token system (colors, type scale, spacing, radii, elevation), a small component library, then screen mockups.
- Every screen must work in **light and dark mode** and in **English and Hindi** (Devanagari text runs ~20–30% longer and needs taller line-height).
- Audience: 20–30 year-old aspirants, mostly on mid-range Android phones, studying for hours daily. They want to feel **serious, focused progress** — with a competitive, gamified edge (streaks, ranks, battles), but never childish.
- Current pain: the UI is clean but flat and "default-looking" — thin 0.5px borders, few shadows, little hierarchy, little delight. We want it to look premium and memorable.

---

## 1. App structure

**Bottom navigation (4 tabs):**

| Tab | Icon (current) | Screen |
|---|---|---|
| Practice | home | Home / practice hub |
| Stats | insights | Progress & analytics |
| Games | sports_esports | Revision mini-games hub |
| Community | custom + unread dot | Social (needs Google/Apple sign-in; feature-flagged) |

Everything else (tests, results, Daily War, Daily CA, etc.) is pushed as full-screen routes or bottom sheets on top of these tabs.

**Cross-cutting UI patterns today:**
- EN | हि language toggle appears on home, test engine, games, and many feature screens.
- Filters are horizontal **pill/chip rows** (subjects, sort modes).
- Configuration, paywalls, sharing and help are **modal bottom sheets**.
- Three "themed islands" break from the main look: **Daily War** (always dark, crimson), **Revision Games** (cream + teal + mono labels), **Onboarding** (cream).

---

## 2. Major features

### 2.1 Onboarding
- Language picker gate (English / Hindi) first.
- 2-page horizontal pager with step dots + Skip:
  - Page 1 "thesis": the app's core idea — being **Confident & Wrong** is dangerous, **Guess & Right** is luck. Shown with illustrations.
  - Page 2: how deep each question's analysis goes (explanations, traps, confidence tracking).
- CTA finishes onboarding and drops the user on Home with a **demo test** suggested.
- **How it's built now:** fixed cream background (`#F5F0E8`), illustration images, simple pager.

### 2.2 Home (Practice tab)
The daily launchpad. Single vertical scroll.
- **Header row:** circular avatar (photo or initial, tap → profile), greeting ("Good morning" / name), dark-mode toggle button, EN | हि segmented toggle.
- **Meta row:** "X days to Prelims" text, red **Traps** pill (count of trap patterns caught → Trap Patterns screen), **Streak** pill with fire icon (turns red-tinted and bold at ≥ 3 days).
- **Banners (conditional):** app update available, restore backup, notifications denied.
- **Prelims countdown card:** blue info card with a live H:M:S countdown to exam day.
- **Today queue:** list of today's live items — CA Shot, Daily CA test, Daily War, live Open Challenge. Hidden when empty.
- **"Browse topics"** full-width primary button.
- **PYQ by year carousel:** horizontal cards for 2025 → 2020 (138px wide, big circular icon well, year as title, small accent bar).
- **Subject grid:** responsive grid (2+ columns) of GS subjects (Polity, History, Geography, Economy, Environment, Science & Tech, etc.). Each card: tinted accent background, colored border, icon, subject name, "X/Y tests done".
- States: skeleton shimmer while loading, error card if question bank fails, full-screen "update required" overlay.
- Milestone toasts when streak hits 3, 7, etc.
- **How it's built now:** flat cards with 0.5px hairline borders, accent colors cycled from a fixed list (blue, amber, teal, green, red), no shadows.

### 2.3 Subject → Topics → Practice tests
- **Practice test list** (main entry from subject card): progress header (tests done/total, coverage %, accuracy %), links to "Browse topics" and "See stats", then **numbered test rows** (checkmark when done, first incomplete one highlighted). Tap → start / resume / review.
- **Topics list:** subject pills on top, search field, sort menu (**Danger zone** default, Accuracy, A–Z), topic cards with progress and danger hints.
- **Subject detail hub:** subject icon + title, performance summary, "New test" button, insight cards (accuracy, mock-prep readiness, danger zone).
- Practice catalog is organized per **Prelims season** (year); a one-time sheet announces a new season.

### 2.4 Test configuration sheet
Bottom sheet shown before almost every test.
- Title (subject / topic).
- Question count chips: 10 / 15 / 25.
- Two mode cards: **Exam mode** (timed overall, answers revealed at end) vs **Learning mode** (instant feedback, optional per-question timer, default 60s).
- Start CTA. First-time users get a coach-mark overlay explaining chips and modes.

### 2.5 Test engine (the core screen — most time is spent here)
- **Top bar:** back, EN/HI toggle, topic caption, countdown timer, question-grid icon, red-outlined **Submit**.
- **Question area:** question stem (PYQ year badge when applicable, supports tables and statement-style UPSC questions), 4 options as tappable cards.
- **After answering (learning mode):** correct option green, chosen-wrong option red, **explanation card** slides in.
- **Confidence strip:** after choosing an option the user marks **Sure** or **Educated guess** — this powers the app's "confident & wrong" insights.
- **Bottom bar:** Previous / Next, Flag, Bookmark.
- **Question grid sheet:** counters (attempted / flagged / skipped) + numbered cells color-coded (current = teal, answered = green, flagged = amber, skipped = neutral), jump-to and submit.
- Reading-size setting scales question text.
- **How it's built now:** plain app surfaces, DM Sans 15px with 1.7 line-height for questions, option cards with hairline borders.

### 2.6 Results & review
- **Session summary:** header with share, subject name; score / gauge; an **insight hero** line (e.g. "3 confident-but-wrong answers"); **4 stat tiles** (accuracy, attempted, sure-accuracy, guess-accuracy); best / weakest topics.
- CTAs into review flows:
  - **Mistake review** — intro screen, then swipe pager through wrong answers with explanations.
  - **Danger zone review** — only the questions answered wrong *while marked Sure*.
  - **Confidence tier review** — filter by Sure vs Guess.
  - Review all, add to revision queue.
- **Share sheet:** shareable score card / challenge link.
- Extra blocks for battles and open challenges (opponent score, leaderboard).
- **How it's built now:** coach-style cards — red danger card, blue "next action" card, emerald trend accents, blue CTA buttons (`#2563EB`).

### 2.7 Stats (tab)
- Subject pill row: All + each subject.
- **All subjects:** hero with **3 progress rings** (coverage, accuracy, tests taken) + "X questions answered"; **bar chart** per subject; **Focus card** (up to 3 recommended topics); **Trap card** → traps.
- **Single subject:** same hero, confidence line, focus card, sort chips (weakest / least covered / A–Z), **topic bar chart**, danger-zone summary card.
- Prepared for a future paywall: premium sections blur with an "Unlock" sheet (currently all free).

### 2.8 Weak areas & trap patterns
- **Weak areas hub:** subject pills, list of weak topics (failure count, accuracy, "Practice" CTA).
- **Trap patterns:** "caught X of Y" subtitle, cards for each recurring UPSC trap type (e.g. extreme words, partially-correct statements) → detail with examples.
- **Concept detail:** sub-topic level breakdown.

### 2.9 Revision queue & bookmarks
- **Revision queue:** count header, subject filter chips, list of questions to revise, "Start" button (up to 50 questions in learning mode).
- **Bookmarks:** count, cards with question preview + subject + date, swipe to remove with undo.
- **Session review (history):** read-only replay of a past test with explanations.

### 2.10 PYQ (Previous Year Questions)
- From the home carousel → year screen → list of **packs** with question counts → config sheet → test.

### 2.11 Daily War (flagship competitive event)
A daily all-India live test on one topic.
- **Lobby:** 7-day week strip, today's topic hero (big topic title, subject eyebrow, "LIVE" crimson label), streak/badge hints, start CTA, help + topics sheets.
- **Results:** score, **AIR (All India Rank)**, streak, earned **badges**, share.
- Also: history list + detail + revise, leaderboard, badge gallery.
- **How it's built now — its own theme:** permanently dark (`#131417` surface, `#1C1C1E` raised), crimson accent `#C2103A` / bright `#FF3B5C`, gold `#C9A227`, white text at 45–55% opacity for secondary, uppercase letter-spaced eyebrows, 40px bold hero numbers.

### 2.12 Daily Current Affairs (Daily CA)
- Header with share and "jump to this month".
- Yesterday's leaderboard hero, then a big primary CTA (Take today's test / Waiting for paper / Review).
- **Month calendar** with dots on completed days; tapping a day opens a sheet of actions.
- Results and leaderboard screens.

### 2.13 CA Shot (FOMO Pulse)
- Bite-sized current-affairs article + one MCQ.
- List of past shots with done state; detail screen = article body + embedded MCQ + share.
- Arrives via Today queue, push notifications and shared links.

### 2.14 1v1 Battles
- Config (pick subject, question settings) → share invite → waiting room (both avatars, room code, host taps start) → same test engine → battle result (head-to-head score breakdown).

### 2.15 Community & chat (tab)
- 3 tabs: **Recent online** (people to challenge), **Open challenge** (public tests anyone can take, with leaderboards), **QOTD** (Question of the Day posts by users).
- App bar actions: Chats (unread dot), Random connect, edit profile.
- **Chat:** thread list (avatar, preview, unread badge) and message thread.

### 2.16 Revision Games (tab)
Six quick revision games:
1. **Memory Pairs** — match concept ↔ fact cards.
2. **Timeline Sorter** — drag events into chronological order.
3. **Odd One Out** — pick the item that doesn't belong.
4. **Fact or Bluff** — true/false rapid fire.
5. **Connect the Dots** — link related items.
6. **1v1 Duel** — featured dark card; real-time quiz duel.
- Hub: title "Revision Games", EN/HI toggle, 6 game cards; each opens a config sheet (subjects, difficulty, language) → intro → game → result.
- **How it's built now — its own theme:** fixed cream page (`#F5F0E8`) in both light and dark, white cards, teal pill CTAs (`#1A7A5E`), **Bricolage Grotesque** for titles/scores, **IBM Plex Mono** uppercase micro-labels for stamps/badges, DM Sans for body.

### 2.17 Test Series (paid)
- One-time purchase per series (RevenueCat).
- Series home with 4 tabs: Overview, Full-Length, Subjects, PYQ & CA.
- Locked tests show premium icon and open a **paywall sheet** (buy, restore, promo code); a pinned **unlock bar** at the bottom when not owned.
- "My Test Series" screen for owned series.

### 2.18 Profile & settings
- **Profile:** sign in with Google / Apple, avatar, name, language, reading size, sign out.
- **Settings:** grouped list — language, dark mode, reading text size, confidence tracking on/off, Prelims date notifications, test series + restore purchases, Telegram / email support, about.

### 2.19 Push spot test
- A single question delivered via push notification → opens directly into a 1-question test → quick result.

---

## 3. Current theme (design tokens)

### 3.1 Typography
- **Primary font:** **DM Sans** (Google Fonts, bundled) — used for everything in the main app.
- **Games-only:** **Bricolage Grotesque** (display titles, big scores) and **IBM Plex Mono** (labels, stamps, scores).
- Weights in use: 400 body, 500 headings/labels, 600–700 for emphasis (headings are fairly light at 500 — one reason the UI feels flat).

| Token | Size | Weight | Line height | Use |
|---|---|---|---|---|
| h1 | 22 | 500 | — | Screen titles |
| h2 | 18 | 500 | — | Section / card titles, dialogs |
| h3 | 16 | 500 | — | Sub-headings |
| body | 15 | 400 | 1.6 | Paragraphs |
| bodyMd | 14 | 400 | 1.55 | Default body |
| bodySm | 13 | 400 | 1.5 | Secondary text |
| label | 14 | 500 | — | Buttons, list titles |
| labelSm | 12 | 500 | — | Chips, small labels |
| caption | 11 | 400 | — | Meta, section eyebrows (uppercase + 0.6 letter-spacing) |
| question | 15 | 400 | 1.7 | Question stem |
| option | 14 | 400 | 1.55 | Answer options |
| navLabel | 10 | 500 | — | Bottom nav |

Daily War extra styles: eyebrow 10/700 with 1.4 tracking, topic title 23/700, hero number 40/700 with −0.5 tracking.

### 3.2 Colors — main app

**Brand / primary (teal-green)**
- primary `#1D9E75`, primaryLight `#E1F5EE`, primaryDark `#0F6E56`, primaryDeep `#085041`
- onPrimary `#FFFFFF`

**Secondary (info blue)** — used for tonal buttons and the countdown card
- info `#185FA5`, infoBg `#E6F1FB`, infoText `#0C447C`
- dark: infoBgDark `#042C53`, infoTextDark `#B5D4F4`

**Semantic** (each has bg / text, light + dark variants)

| Role | Main | Bg (light) | Text (light) | Bg (dark) | Text (dark) |
|---|---|---|---|---|---|
| Correct | `#1D9E75` | `#E1F5EE` | `#085041` | `#085041` | `#9FE1CB` |
| Wrong | `#E24B4A` | `#FCEBEB` | `#791F1F` | `#501313` | `#F09595` |
| Warning / flagged | `#BA7517` | `#FAEEDA` | `#633806` | `#412402` | `#FAC775` |
| Info / exam mode | `#185FA5` | `#E6F1FB` | `#0C447C` | `#042C53` | `#B5D4F4` |
| Purple (insights) | `#7C5CE0` | `#F0ECFC` | `#4B33A8` | `#2B2350` | `#D0C6F6` |

- Streak fire: `#E24B4A`
- Gold (medals, test series): `#F2B01E`
- Results-screen extras: CTA blue `#2563EB`, chart blue `#3B82F6`, orange `#F59E0B`, danger red `#DC2626`, emerald trend `#10B981`

**Neutrals (warm grays)**
- gray50 `#F1EFE8`, gray100 `#D3D1C7`, gray200 `#B4B2A9`, gray400 `#888780`, gray600 `#5F5E5A`, gray800 `#444441`, gray900 `#2C2C2A`

**Surfaces**

| | Light | Dark |
|---|---|---|
| Card / app bar / sheet (surface) | `#FFFFFF` | `#1C1C1E` |
| Container low | `#F5F5F3` | `#2C2C2E` |
| Page background (scaffold) | `#EEEEEB` | `#3A3A3C` |
| Text primary | `#1C1C1E` | `#EAEAEA` |
| Text secondary | `#6B6B6B` | `#9A9A9A` |
| Border / divider | black 15% | white 15% |

(Note: in dark mode the page background `#3A3A3C` is *lighter* than cards `#1C1C1E` — an inversion worth reconsidering.)

### 3.3 Colors — themed islands
- **Daily War:** surface `#131417`, raised `#1C1C1E`, crimson `#C2103A`, crimson bright `#FF3B5C`, crimson soft `#FDEBEF`, gold `#C9A227`, ink `#0C0D0F`, text white / 55% / 45%, border white 8%.
- **Revision Games:** page `#F5F0E8` (cream), card `#FFFFFF`, ink `#1C1C1E`, muted `#6B6B63`, teal CTA `#1A7A5E`, tealDeep `#0F6E56`, plus the same correct/wrong/warning semantics.

### 3.4 Spacing, radius, elevation
- **Spacing scale:** 4, 8, 12, 16, 20, 24, 32 (screen padding 16; gap between list cards 10).
- **Radius:** sm 8, md 12 (buttons, inputs, most cards), lg 14 (cards, dialogs), xl 16, pill 100. Games use sm 10.
- **Elevation:** essentially **none** — elevation 0 everywhere; separation comes from 0.5px hairline borders and surface tint changes.
- **Buttons:** filled teal, 12 radius, ~15px vertical padding, label 14/500; outlined = 0.5px border; text buttons teal.
- **Inputs:** filled white, 0.5px border, teal 1px focus border.
- **Snackbars:** floating, dark gray, 12 radius.
- **Bottom nav:** fixed, labels always shown, selected = teal, no elevation.
- **Icons:** Material Icons (outlined / rounded mix).
- **Motion:** minimal — ~160ms toggles, shimmer skeletons, ripple on tap.

---

## 4. What we want from the redesign

1. **A unified design system** — tokens (color, type, spacing, radius, elevation/shadow, motion) and a component set: card, stat tile, progress ring, pill/chip, segmented toggle, option card (default / selected / correct / wrong / disabled), bottom sheet, section header, list row, badge, leaderboard row, empty state, skeleton.
2. **Decide how the themed islands relate** — keep Daily War dark-crimson and Games cream as intentional "modes", but make them clearly part of the same family.
3. **Priority screens to mock up first:**
   1. Home (Practice tab)
   2. Test engine (question, answered-correct, answered-wrong + explanation, question grid sheet)
   3. Results / session summary
   4. Stats tab
   5. Daily War lobby + results
   6. Games hub
   7. Onboarding (2 pages)
4. **Hierarchy & delight:** stronger headings, real depth (soft shadows or layered surfaces), better use of the brand color, satisfying feedback on correct/wrong, celebratory moments (streak milestones, rank, badges) without clutter.
5. **Constraints:** readable long Hindi text; high contrast for long study sessions; works at 360dp width; dark mode is first-class; keep the teal brand unless proposing a clearly better identity (if so, give the full replacement palette).
6. **Deliverables:** token table (light + dark), component specs, screen mockups for the priority screens, and short rationale for each major decision.
