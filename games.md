# Games Hub — Requirements for Cursor

## Scope

Add a dedicated **Games** screen listing all 5 mini-games, and wire each game in as a fully working screen with placeholder content. This phase is structure + interaction only — no home screen surfacing, no analytics linkage to Danger Zone, no Hindi content yet. Content is intentionally minimal (2-3 sample items per game) so the app is playable end to end; real content gets generated and swapped in later.

Follow existing conventions already in the codebase: Riverpod with `HookConsumerWidget` only, GoRouter for navigation, feature-based folders under `lib/features/`, shared code under `lib/core/`. Do not introduce new state management patterns, new routing libraries, or Firebase for anything in this phase — all 5 games are fully local/offline, including the 1v1 Duel (single device, no networking).

---

## 1. Folder structure

```
lib/features/mini_games/
  hub/
    games_hub_screen.dart
  timeline_sorter/
    timeline_sorter_screen.dart
    timeline_sorter_controller.dart   (Riverpod state)
  odd_one_out/
    odd_one_out_screen.dart
    odd_one_out_controller.dart
  fact_or_bluff/
    fact_or_bluff_screen.dart
    fact_or_bluff_controller.dart
  connect_the_dots/
    connect_the_dots_screen.dart
    connect_the_dots_controller.dart
  duel/
    duel_screen.dart
    duel_controller.dart
  shared/
    mini_game_models.dart        (data classes for all 5 content types below)
    mini_game_content_repository.dart   (loads JSON — see Section 4)

assets/mini_games/
  timeline_sorter.json
  odd_one_out.json
  fact_or_bluff.json
  connect_the_dots.json
  duel.json
```

## 2. Navigation

Add routes under GoRouter (adjust prefix to match existing route naming conventions in the app):

```
/games                    → GamesHubScreen
/games/timeline-sorter    → TimelineSorterScreen
/games/odd-one-out        → OddOneOutScreen
/games/fact-or-bluff      → FactOrBluffScreen
/games/connect-the-dots   → ConnectTheDotsScreen
/games/duel               → DuelScreen
```

`/games` is not linked from anywhere yet in this phase — add a temporary entry point (e.g. a debug menu item or a button on an existing settings/profile screen) so it's reachable for testing. Where it ultimately lives in the main navigation is a decision for the "presentation" phase, not this one.

## 3. Games Hub screen

Simple vertical list, one card per game, in this fixed order:

1. Timeline Sorter
2. Odd One Out
3. Fact or Bluff
4. Connect the Dots
5. 1v1 Duel

Each card: game title, one-line description, tap to navigate to that game's route. No progress indicators, no lock/unlock states, no badges in this phase — just a working list. Visual styling should match the app's existing card components if one already exists in the design system; don't invent a new card style.

Suggested one-line descriptions (placeholder copy, can be refined later):
- Timeline Sorter — "Put events in the right order."
- Odd One Out — "Four items. One doesn't belong."
- Fact or Bluff — "Five seconds. Trust your gut."
- Connect the Dots — "Find the hidden link."
- 1v1 Duel — "One phone, two players, fastest correct answer wins."

## 4. Content loading approach

For this phase, content loads from **local JSON files bundled as Flutter assets** (`assets/mini_games/*.json`), not from Drift/SQLite. This is deliberate — content generation and SQLite integration is separate future work. Structure the repository layer (`mini_game_content_repository.dart`) so that swapping the data source later (JSON asset → Drift query against the question bank) only requires changing the repository implementation, not the controllers or screens. Concretely: controllers should depend on an abstract repository interface per game type, not directly on `rootBundle`/asset loading.

Each JSON file is a flat array of objects. Schemas below. Keep field names exactly as specified — content will be generated in bulk later and should not require reformatting.

---

## 5. Game specs + content schema

### 5.1 Timeline Sorter

**Interaction:** Show N items in shuffled order. User drags and drops an item to their correct positions . User taps "Check" when ready. On check, reveal correct order with each item's year, and show the explanation. Provide a "Play again" / "Next set" action.

**JSON schema** (`timeline_sorter.json`):
```json
[
  {
    "id": "tl_001",
    "subject": "Modern History",
    "theme": "Company Rule Acts",
    "items": [
      { "label": "Battle of Plassey", "year_display": "1757", "sort_key": 1757 },
      { "label": "Battle of Buxar", "year_display": "1764", "sort_key": 1764 },
      { "label": "Regulating Act", "year_display": "1773", "sort_key": 1773 },
      { "label": "Pitt's India Act", "year_display": "1784", "sort_key": 1784 },
      { "label": "Charter Act", "year_display": "1813", "sort_key": 1813 }
    ],
    "explanation": "Plassey (1757) gave the Company its foothold; Buxar (1764) confirmed real power. Parliament then stepped in with the Regulating Act (1773), Pitt's India Act (1784), and the Charter Act (1813)."
  }
]
```

Notes for content generation later:
- `sort_key` is a plain integer used for sorting — the correct order is simply `sort_key` ascending. This avoids parsing "c. 320 CE" / "544 BCE" style strings at runtime. For BCE dates, use negative numbers (e.g. 544 BCE → `-544`).
- `year_display` is what's shown to the user after check — can stay as a human-readable string ("c. 1757", "544 BCE").
- 5 items per set is the sweet spot demonstrated in the prototype; don't exceed 6 (harder to fit on one screen without scrolling).
- Items within a set should share a real theme/category (a dynasty, an Act sequence, a set of battles) — not random unrelated events, or the sort has no conceptual anchor.

### 5.2 Odd One Out

**Interaction:** Show 4 items in a 2x2 grid. User taps one. Reveal immediately: correct odd-one-out highlighted, wrong tap (if any) marked, explanation shown.

**JSON schema** (`odd_one_out.json`):
```json
[
  {
    "id": "oo_001",
    "subject": "Ancient History",
    "items": ["Nalanda", "Taxila", "Vikramashila", "Ajanta"],
    "odd_index": 3,
    "explanation": "Ajanta is a rock-cut cave site famous for paintings. The other three were residential universities."
  }
]
```

Notes:
- `odd_index` is 0-based, indexing into `items`.
- The explanation should state what the 3 non-odd items have in common AND why the odd one differs — both halves matter for learning value, not just "the answer is X."

### 5.3 Fact or Bluff

**Interaction:** Show one statement. 5-second countdown timer bar. User taps FACT or BLUFF before time runs out (running out counts as wrong, matching real exam pressure). Reveal verdict + explanation. Track a running streak counter across the session (resets on wrong answer or timeout).

**JSON schema** (`fact_or_bluff.json`):
```json
[
  {
    "id": "fb_001",
    "subject": "Ancient History",
    "statement": "Xuanzang's 7th-century account describes Nalanda in a state of ruin.",
    "is_fact": false,
    "explanation": "Bluff. Xuanzang saw Nalanda at its peak. The ruined state was recorded much later, by Dharmasvamin in the 13th century."
  }
]
```

Notes for content generation later:
- This is the cheapest game to generate content for — `is_fact: false` items map directly from a question's `strong_distractor` or a plausible-but-wrong statement drawn from `upsc_trap_explanation` fields already in the question bank. `is_fact: true` items can be true statements pulled straight from `final_explanation` fields.
- Explanation should start with "Fact." or "Bluff." as the first word, matching the tone in the sample — keeps the reveal punchy rather than restating the full analytical explanation.
- No table_data or multi-statement content — keep each item a single, self-contained sentence. Long or compound statements don't fit the 5-second format.

### 5.4 Connect the Dots

**Interaction:** Show 4 short "dot" items (terms, names, articles). Below, show 4 answer options describing the hidden connection. User taps one option. Reveal correct option highlighted, wrong tap marked, explanation shown.

**JSON schema** (`connect_the_dots.json`):
```json
[
  {
    "id": "cd_001",
    "subject": "Polity",
    "dots": ["Article 32", "Article 226", "Mandamus", "Quo Warranto"],
    "options": [
      "Emergency provisions",
      "Constitutional remedies & writs",
      "Amendment procedure",
      "Centre–State relations"
    ],
    "answer_index": 1,
    "explanation": "All four relate to writ jurisdiction: Article 32 (Supreme Court) and Article 226 (High Courts) empower courts to issue writs like Mandamus and Quo Warranto."
  }
]
```

Notes:
- `answer_index` is 0-based, indexing into `options`.
- This is the most content-expensive game — the 4 dots and 4 options must be manually curated to have one real hidden connection, and 3 distractor options need to sound plausible without being correct. It doesn't map cleanly from a single existing question the way Fact or Bluff does. Budget more time for this one when generating content in bulk; consider grouping by `sub_topic` in the SQLite bank to speed up dot selection.

### 5.5 1v1 Duel

**Interaction:** Single device, held flat between two people. Same question renders twice on screen — once right-side up (bottom half, Player 1), once rotated 180° (top half, Player 2). Both players see 2 answer options only (not 4 — deliberately fewer, to keep it a reflex race rather than a reading race, and to make a blind guess a meaningful 50/50 risk). First correct tap wins the point. A wrong tap locks that player out of the current question, but does not end the round — the other player can still answer. If both answer wrong, no point is awarded and the correct answer is revealed. Match length: 5 questions (configurable constant, not user-facing setting in this phase). Running score shown in a center strip between the two halves, visible right-side up to whoever glances at it. End screen shows final score, duplicated top and bottom (rotated) so both players can read the result without turning the phone.

**JSON schema** (`duel.json`):
```json
[
  {
    "id": "dl_001",
    "subject": "Any",
    "question": "Who founded Vikramashila University?",
    "options": ["Dharmapala", "Samudragupta"],
    "answer_index": 0
  }
]
```

Notes:
- Exactly 2 options — this is a hard constraint for this format, not a placeholder. Do not generate 4-option content for Duel.
- No `explanation` field — Duel is a speed format with no reveal-and-learn step. If you want post-match review later, that's a separate feature (e.g. a "review the 5 questions" screen after the match ends), not part of this phase.
- Content for Duel can be generated fastest of all 5 games — take any existing 4-option MCQ, keep the correct option plus one plausible wrong option, discard the other two.

---

## 6. Explicitly out of scope for this phase

- Home screen / navigation placement of the Games entry point (separate "presentation" phase)
- Hindi content and language toggle for any of the 5 games
- Pulling content from Drift/SQLite instead of local JSON assets
- Any progress tracking, XP, streak persistence across app sessions, or Danger Zone linkage
- Firebase, multiplayer, or online leaderboards for Duel or any other game
- Sound effects, haptics, animations beyond basic state transitions

## 7. Acceptance criteria

- `/games` shows all 5 games in the fixed order above and each card navigates correctly.
- Each of the 5 screens is playable start to finish using only the placeholder JSON content included, including a working "next/play again" loop that cycles back to the first item after the last.
- Duel works correctly on a single device with two people physically holding opposite ends — verify the 180° rotation renders legibly and both halves' buttons respond independently.
- No crashes when a content JSON file has only 1 item (should still loop back to itself, not break).