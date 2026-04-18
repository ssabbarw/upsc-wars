Reading the requirements doc and exploring the codebase in parallel.

Now let me examine a few critical files before finalizing the plan.

Now let me check the catalog providers and history for query details, and verify the `confidence` field.

Let me check a couple more files before writing the plan.

I now have a complete picture. Let me write up the migration plan.

---

## Subject-Centric Refactor — Detailed Migration Plan

### Critical Finding Before We Start

**The `confidence` field doesn't exist in your database.** The requirements document's Insights section (Danger Zone, Trap Blind Spots) is built entirely around `a.confidence = 'very_sure'`, but the `attempts` table only has: `id, session_id, question_uuid, position, selected_option, is_correct, status, time_spent_secs, flagged, attempted_at`. There is no confidence column.

**Decision you need to make**: 
- **Option A (Recommended for now)**: Build Insights using existing data — "Danger Zone" = wrong answers in last 30 days, "Topic Risk" = lowest-accuracy topics. Simpler, ships faster. Confidence ratings can be added later as a separate feature.
- **Option B**: Defer Insights (Phase 2) entirely until you add the confidence rating UI. This is a bigger feature — you'd need a DB migration + new UI affordance in the test engine for users to rate confidence per question.

I'll plan for **Option A** below but call out where it diverges from the spec.

Also: the requirements doc says "7 subjects" but you actually have **8**: Ancient History, Medieval History, Modern History, Art and Culture, Geography, Economy, **Environment**, Polity.

---

### Current State Summary

| What exists | Where |
|---|---|
| Subject list with stats | `subjectTestListProvider` → `SubjectInfo` (accuracy %, question count, topic count) |
| Subject cards (horizontal scroll) | `_SubjectCarousel` inside `HomeScreen` |
| Subject selection → test config | `/subject-test` → `SubjectTestScreen` → `TestConfigBottomSheet` |
| Session history with subject filter | `sessionSummariesProvider(subject:)` |
| Topic list per subject | `topicTestTopicsProvider(subject)` |
| Trap type data | `weakTrapGroupsProvider` (global) |
| Weak areas screen | `/weak-areas` → `WeakAreasHubScreen` |
| Bottom nav | Home \| History \| Progress \| Community |

---

### Phase 1: Subject Grid Home + Subject Detail Screen

**Goal**: Replace the home carousel with a primary subject grid. Create the Subject Detail screen. Wire up navigation. All existing flows remain intact.

#### Files to CREATE

| File | Purpose |
|---|---|
| `lib/features/subject_detail/screens/subject_detail_screen.dart` | The core new screen — header, practice section, history section |
| `lib/features/subject_detail/screens/topics_list_screen.dart` | Topics list filtered to one subject (replaces needing to go through `/topic-test`) |
| `lib/features/subject_detail/providers/subject_detail_providers.dart` | Thin providers wrapping existing `sessionSummariesProvider` and `topicTestTopicsProvider` |

#### Files to MODIFY

| File | What changes |
|---|---|
| `lib/features/home/screens/home_screen.dart` | (1) Replace `_SubjectCarousel` + `_QuickGrid` "Subject test" shortcut with a full `SubjectGrid` widget that uses `subjectTestListProvider`. (2) Keep streak, daily goal, Quick Practice cards (revision/bookmarks), Last Session card. (3) Remove `_HomeReleaseTodoCard` debug card and the debug total-question count card. |
| `lib/core/router/app_router.dart` | Add 2 new routes: `/subject/:name` → `SubjectDetailScreen`, `/subject/:name/topics` → `TopicsListScreen`. Keep `/subject-test` (used by bot battle flow). |
| `lib/core/constants/subject_constants.dart` | Minor: Update comment from "six UPSC subjects" to "eight". No logic change. |

#### Files that STAY UNCHANGED in Phase 1

- `SubjectTestScreen` (still used for bot battle mode via `/subject-test?battleMode=bot`)
- `TopicTestScreen` (reachable from new `TopicsListScreen`)
- `TestEngineScreen`, `SessionReviewScreen`, `ResultsScreen`
- `HistoryScreen` (global, still accessible from bottom nav)
- `WeakAreasHubScreen`, `TrapPatternsScreen`
- All battle, community, revision queue screens
- All providers/repositories/use cases/DAOs

#### Phase 1 Implementation Detail

**HomeScreen changes**:
- The new subject grid occupies the top of the scrollable content (below greeting + streak)
- Each subject card (full-width or 2-column) shows: icon, name, question count, accuracy %, topics attempted/total
- Tap card → `context.push('/subject/:name')`
- The `subjectTestListProvider` already provides all needed stats — no new queries

**SubjectDetailScreen** (`/subject/:name`):
- Header: subject icon + name + overall accuracy chip + "X of Y topics touched" progress text
- **Practice section**: Two cards — "Start Random Test" (opens existing `TestConfigBottomSheet` with subject pre-filled) and "Browse Topics" (pushes to `/subject/:name/topics`)
- **History section**: Scrollable list of past sessions for this subject, using existing `sessionSummariesProvider(subject: name)`. Each row shows date, mode badge, score. Tap → `/history/:sessionId`. Empty state with "Start your first test" CTA.
- Back → Home

**TopicsListScreen** (`/subject/:name/topics`):
- Header: subject name + topic count
- List of topics from `topicTestTopicsProvider(name)` — shows topic name, accuracy %, attempt count
- Tap topic → `TestConfigBottomSheet` with subject + topic pre-filled → `/test/:id`
- Back → SubjectDetailScreen

**Navigation update**:
- Subject cards on home → `/subject/:name` (new)
- The existing "Subject test" quick grid card on home → remove (redundant with new grid)
- Keep bottom nav as-is for Phase 1 (Home \| History \| Progress \| Community)

---

### Phase 2: Subject-Scoped Insights

**Goal**: Add an Insights section to `SubjectDetailScreen`. Uses accuracy-based metrics (not confidence-based, since that field doesn't exist).

#### Files to CREATE

| File | Purpose |
|---|---|
| `lib/features/subject_detail/data/subject_insights_dao.dart` | New Drift DAO with 3 subject-scoped queries |
| `lib/features/subject_detail/domain/entities/subject_insights.dart` | Data model: `SubjectInsights(wrongCount, topicRisks, trapRisks)` |
| `lib/features/subject_detail/data/subject_insights_repository.dart` | Repository wrapping the DAO |
| `lib/features/subject_detail/providers/subject_insights_providers.dart` | Riverpod provider: `subjectInsightsProvider(subject)` |

#### Files to MODIFY

| File | What changes |
|---|---|
| `lib/core/database/user_db.dart` | Add `SubjectInsightsDao` class + register it on the `@DriftDatabase` annotation. **No new table, no migration needed** — queries only use existing `attempts` + `questions` tables. |
| `lib/features/subject_detail/screens/subject_detail_screen.dart` | Add Insights section below History with 3 cards: Wrong Answer Summary, Topic Risk Ranking, Trap Blind Spots. |
| `lib/core/providers/catalog_providers.dart` | Add `subjectInsightsRepositoryProvider` and wire it up. |

#### New DAO Queries (adapted from spec, using `isCorrect` instead of `confidence`)

```
Wrong Answer Summary (last 30 days):
  SELECT COUNT(*) FROM attempts a
  JOIN questions q ON a.question_uuid = q.uuid
  WHERE q.subject = ? AND a.is_correct = false
  AND a.attempted_at >= ?

Topic Risk Ranking:
  SELECT q.topic, COUNT(*) as wrong_count
  FROM attempts a JOIN questions q ON a.question_uuid = q.uuid
  WHERE q.subject = ? AND a.is_correct = false
  AND a.attempted_at >= ?
  GROUP BY q.topic ORDER BY wrong_count DESC LIMIT 5

Trap Blind Spots:
  SELECT q.trap_type,
    COUNT(*) as total,
    COUNT(CASE WHEN a.is_correct=0 THEN 1 END) as wrong_count
  FROM attempts a JOIN questions q ON a.question_uuid = q.uuid
  WHERE q.subject = ? AND q.trap_type IS NOT NULL
  AND a.attempted_at >= ?
  GROUP BY q.trap_type ORDER BY wrong_count DESC
```

**Note on Danger Zone label**: Since there's no `confidence` field, we'll call this "Wrong Answers (Last 30 Days)" rather than "Danger Zone". When confidence ratings are added later, you can upgrade this metric without changing the screen structure.

**Requires**: `dart run build_runner build` after adding the DAO.

#### Files that STAY UNCHANGED in Phase 2

Everything not listed above.

---

### Phase 3: Overall Insights Screen

**Goal**: Cross-subject comparison accessible from the Progress tab (or as its own tab).

#### Files to CREATE

| File | Purpose |
|---|---|
| `lib/features/insights/screens/overall_insights_screen.dart` | Subject comparison table + weakest/strongest callouts |
| `lib/features/insights/providers/overall_insights_providers.dart` | Combines `subjectTestListProvider` with subject-level wrong counts |

#### Files to MODIFY

| File | What changes |
|---|---|
| `lib/core/router/app_router.dart` | Add `/insights` route |
| `lib/features/home/screens/progress_screen.dart` | Add entry point to `/insights` OR replace ProgressScreen with OverallInsightsScreen |

**Recommendation**: Reuse the existing `/progress` tab for this. The current `ProgressScreen` likely shows similar stats — check its content and either extend it or replace it with `OverallInsightsScreen`.

#### Files that STAY UNCHANGED in Phase 3

All battle, community, revision queue, test engine, bookmarks screens.

---

### Phase 4: Polish (Post-Approval)

- Progress ring on subject cards (circular indicator showing topics attempted / total)
- Skeleton loaders for subject cards while stats load
- Index on `questions.subject` in Drift schema for query speed
- Optional subject filter on Revision Queue screen
- "Default Subject" setting in Settings screen

---

### Folder Structure (New Files)

```
lib/features/subject_detail/
├── data/
│   ├── subject_insights_dao.dart       # Phase 2
│   └── subject_insights_repository.dart # Phase 2
├── domain/
│   └── entities/
│       └── subject_insights.dart        # Phase 2
├── providers/
│   ├── subject_detail_providers.dart    # Phase 1
│   └── subject_insights_providers.dart # Phase 2
└── screens/
    ├── subject_detail_screen.dart       # Phase 1
    └── topics_list_screen.dart          # Phase 1

lib/features/insights/
├── providers/
│   └── overall_insights_providers.dart # Phase 3
└── screens/
    └── overall_insights_screen.dart    # Phase 3
```

---

### Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| `confidence` field missing | High | Adapt insights to use `isCorrect` (already planned above) |
| Bot battle flow via `/subject-test` must be preserved | Medium | Keep the route; only change home-screen taps |
| `dart run build_runner build` required for Phase 2 DAO | Low | Standard workflow, run after adding DAO |
| `TopicTestScreen` currently receives subject via `extra` or provider state (not route param) — verify the exact mechanism | Medium | Check `TopicTestScreen` before Phase 1 implementation |
| Home screen currently shows lots of cards (PYQ carousel, quick grid, etc.) — displacement of these with a big subject grid needs careful layout planning | Low | Subject grid goes first, other cards below; user scrolls to them |
| Bottom nav is unchanged in Phase 1-3 — History and Progress tabs remain. If you later want Battles in the nav, that's a separate task | Low | Explicitly deferred |

---

### What I Need from You Before Starting

1. **Confirm the Insights adaptation**: OK with "Wrong Answers (Last 30 days)" instead of "Danger Zone (confidence=very_sure)"? Or do you want to add the confidence field first (bigger scope)?

2. **Bottom nav decision**: Keep current Home \| History \| Progress \| Community for now? Or restructure to include Battles/Revision as top-level tabs in Phase 1?

3. **Home screen layout**: Should the new subject grid *replace* most of the current home content (PYQ carousel, quick-practice section) and become the primary focus? Or should the grid be added alongside existing cards?

4. **Subject cards**: Full-width list (like the current `SubjectTestScreen`) or 2-column grid as the spec describes?

Say "approved, start Phase 1" (or with any of the above answers) and I'll begin implementation.