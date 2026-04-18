# Subject-Centric Architecture Refactor — Handoff for Claude Code

## Context & Why We're Doing This

**Current Problem**: The app mixes all subjects together. Users see questions from Ancient History, Polity, Geography all jumbled. Insights show aggregated data across all subjects. This doesn't match how UPSC students actually study — they focus on one subject at a time.

**Goal**: Reorganize the entire app so **subject is the primary navigation container**. Each subject becomes its own world with practice options, test history, and insights scoped to that subject only.

**Success Criteria**: A student opens the app, sees 7 subject cards, taps "Ancient History", and everything they see from that point forward is about Ancient History only — until they navigate back and choose a different subject.

---

## Database Foundation (Already Exists)

You already have this hierarchy in the `questions` table:
```
subject → topic → sub_topic
```

**7 Subjects** (these are the only values for the `subject` field):
1. Ancient History
2. Medieval History  
3. Modern History
4. Art & Culture
5. Geography
6. Polity
7. Economy

**Topics vary by subject**. For example:
- Ancient History has: "Indus Valley Civilization", "Vedic Period", "Mauryan Empire", etc.
- Polity has: "Parliament", "Judiciary", "Federalism", etc.

This hierarchy is perfect for subject-centric architecture. You just need to **surface it in the UI** properly.

---

## New Information Architecture (Target State)

```
Home Screen
├─ Subject Cards (7 cards in grid/list)
│  Each card shows:
│  - Subject name + icon
│  - Topics completed: X/Y
│  - Overall accuracy: Z%
│  - Danger Zone indicator: 🔴 High Risk / 🟡 Medium / 🟢 Low
│
├─ Bottom Navigation (or hamburger menu)
│  ├─ Home (subject cards)
│  ├─ Revision Queue (all subjects)
│  ├─ Overall Insights (cross-subject comparison)
│  └─ Settings
│
Tap on a Subject Card ──────> Subject Detail Screen
                              ├─ Header: Subject name, progress ring
                              ├─ Practice Section
                              │  ├─ "Start Random Test" (10/20/50 questions from THIS subject)
                              │  ├─ "Browse Topics" button
                              ├─ History Section
                              │  └─ List of past tests (filtered to THIS subject)
                              ├─ Insights Section (THIS IS YOUR COMPETITIVE MOAT)
                              │  ├─ Danger Zone summary (THIS subject only, last 30 days)
                              │  ├─ Topic Risk Ranking (topics within THIS subject)
                              │  └─ Trap Blind Spots (filtered to THIS subject)
                              
From Subject Detail Screen:
├─ "Browse Topics" ──────> Topics List Screen (THIS subject's topics only)
│                          Tap a topic ──────> Topic Test Screen
│
├─ Tap test in History ──> Test Review Screen (existing)
│
└─ Back button ──────> Returns to Home (subject cards)
```

---

## Screen-by-Screen Requirements

### HOME SCREEN (New/Refactored)

**Layout**: Grid of 7 subject cards (2 columns on mobile, 3-4 on tablet)

**Each Subject Card Shows**:
1. **Subject Icon** (top): 
   - Use emojis or simple icons for now
   - Ancient History: 🏛️
   - Medieval History: ⚔️
   - Modern History: 🏭
   - Art & Culture: 🎨
   - Geography: 🌍
   - Polity: ⚖️
   - Economy: 💰

2. **Subject Name** (below icon): Bold, prominent

3. **Quick Stats** (compact, 2-3 lines):
   - "Topics: 8/12 completed" 
     - Calculate: COUNT(DISTINCT topic) where user has attempted at least 1 question / total topics for this subject
   - "Accuracy: 67%"
     - Calculate: correct attempts / total attempts for this subject
   - **Danger Zone Indicator**:
     - 🔴 "High Risk" if Danger Zone count (last 30 days) >= 8
     - 🟡 "Medium Risk" if count 3-7
     - 🟢 "Low Risk" if count 0-2
     - Show icon + text below stats

4. **Visual State**:
   - Completed subjects (all topics attempted): Show checkmark badge or "Complete" label
   - In-progress subjects: Show progress ring around icon
   - Not started: Gray out slightly

**Interaction**: Tap card → Navigate to Subject Detail Screen for that subject

**Top of Screen**:
- App name/logo
- Maybe: "GS Paper 1 Prep" subtitle
- User profile icon (top-right corner)

**Bottom Navigation** (or hamburger menu):
- Home (subject cards) — active
- Revision Queue (global, all subjects)
- Overall Insights (cross-subject)
- Settings

**Empty State**: Should never be empty — 7 subjects are hardcoded

**Loading State**: Show skeleton cards while calculating stats

---

### SUBJECT DETAIL SCREEN (New)

**Route**: `/subject/:subjectName` (e.g., `/subject/Ancient%20History`)

**Header Section**:
- **Back button** (top-left): Returns to Home
- **Subject Name** (large, bold): "Ancient History"
- **Subject Icon** (next to name or centered)
- **Progress Indicator**: 
  - Circular progress ring OR horizontal bar
  - Text: "8 of 12 topics completed"
- **Overall Accuracy Badge**: "67% accuracy" in a colored chip
  - Green if >75%
  - Orange if 50-75%
  - Red if <50%

**Body Section** (3 main sections — use tabs OR vertical scroll with section headers):

---

#### SECTION 1: Practice

**"Start Random Test" Card**:
- Primary action button
- Icon: shuffle or random icon
- Text: "Start Random Test"
- Subtitle: "Questions from all topics in Ancient History"
- Tap → Show options modal:
  - 10 questions
  - 20 questions
  - 50 questions
  - Each option shows estimated time (e.g., "~15 mins")
- After selection → Navigate to Question Screen with questions filtered by `subject='Ancient History'`

**"Browse Topics" Card**:
- Secondary button/card
- Icon: list icon
- Text: "Browse Topics"
- Subtitle: "Practice specific topics (12 topics)"
- Tap → Navigate to Topics List Screen (filtered to this subject)

**Visual Layout**:
- Two stacked cards OR two side-by-side buttons
- Make "Start Random Test" more prominent (larger, primary color)

---

#### SECTION 2: History

**Header**: "Test History"

**Filter Options** (chips or tabs):
- All
- Learning Mode
- Test Mode
- Last 7 days / Last 30 days / All time

**List of Past Tests**:
Each test card shows:
- **Test Date**: "2 days ago" or "Jan 15, 2025"
- **Mode Badge**: "Learning" or "Test" (different colors)
- **Score**: "7/10 correct (70%)"
- **Danger Zone Indicator** (if any): "⚠️ 2 Danger Zone questions"
- **Topics Covered**: "Indus Valley, Vedic Period" (if mixed topic test)
- Tap card → Navigate to Test Review Screen (existing functionality)

**Sorting**: Most recent first

**Empty State**: 
- No tests yet for this subject
- Show: "No test history yet. Start your first test!"
- CTA button: "Start Random Test"

**Load More**: If >20 tests, paginate or "Load More" button

---

#### SECTION 3: Insights (Your Competitive Moat)

**This is where your structured question data shines.**

---

##### 3A: Danger Zone Summary

**Card Design**:
- Title: "⚠️ Danger Zone (Last 30 Days)"
- Large Number: "12 questions" where user was Very Sure but Wrong
  - Red if >= 8
  - Orange if 3-7  
  - Green if 0-2
- Subtext: "In a real exam, this would cost you 7.92 marks"
- **Trend Indicator** (optional Phase 2):
  - "↓ Improving" (fewer Danger Zone questions this week vs last week)
  - "→ Stable"
  - "↑ Getting worse"
- **Action Button**: "Review Danger Zone Questions"
  - Tap → Navigate to Danger Zone Review Screen (filtered to this subject)

**Query Logic**:
```
SELECT COUNT(*) 
FROM attempts a 
JOIN questions q ON a.question_uuid = q.uuid
WHERE q.subject = 'Ancient History'
  AND a.confidence = 'very_sure'
  AND a.is_correct = false
  AND a.attempted_at >= (today - 30 days)
```

---

##### 3B: Topic Risk Ranking

**Card Design**:
- Title: "Topic Risk Ranking"
- Subtitle: "Which topics are most dangerous for you in Ancient History"
- **List of Topics** (sorted by Danger Zone count, descending):
  - Each row shows:
    - Risk emoji: 🔴 / 🟡 / 🟢
    - Topic name: "Indus Valley Civilization"
    - Danger Zone count: "5 Danger Zone questions"
    - Risk label: "High Risk" / "Medium Risk" / "Low Risk"
  - Tap topic → Navigate to Topic Detail Screen (shows questions from that topic)

**Visual**:
- Show top 5 topics only, with "See All Topics" button to expand
- Color-code background or left border by risk level

**Query Logic**:
```
SELECT q.topic, COUNT(*) as danger_count
FROM attempts a
JOIN questions q ON a.question_uuid = q.uuid
WHERE q.subject = 'Ancient History'
  AND a.confidence = 'very_sure'
  AND a.is_correct = false
  AND a.attempted_at >= (today - 30 days)
GROUP BY q.topic
ORDER BY danger_count DESC
```

**Empty State**: "Not enough data yet. Answer more questions to see topic risks."

---

##### 3C: Trap Blind Spots

**Card Design**:
- Title: "Your Trap Blind Spots"
- Subtitle: "Which UPSC trap types fool you most in Ancient History"
- **List of Trap Types** (sorted by status: Danger Zone first):
  - Each row shows:
    - Status icon: ❌ Danger Zone / ⚠️ Needs Attention / ℹ️ Known Gap / ✅ Well Calibrated
    - Trap type name: "Conflation" (formatted from `trap_type` field)
    - Insight text: "You're Very Sure 74% of the time, correct only 31%"
  - Color-coded by status (red/orange/blue/green)
  - Tap → Show detailed explanation of this trap type + list of questions

**Visual**:
- Show top 3-5 trap types only
- "See All Traps" button to expand

**Query Logic**:
```
For each trap_type in this subject:
  - Calculate: % attempts where confidence='very_sure'
  - Calculate: accuracy when very_sure
  - Calculate: % attempts where confidence='guessing'
  - Assign status based on these metrics
```

**Empty State**: "Not enough data yet. Answer more questions with confidence ratings."

---

**Layout of Insights Section**:
- Stack these 3 cards vertically
- Each card is collapsible (optional) OR always visible
- Visual hierarchy: Danger Zone Summary is most prominent (larger, red accent)

---

### TOPICS LIST SCREEN (Refactored)

**Route**: `/subject/:subjectName/topics` (e.g., `/subject/Ancient%20History/topics`)

**Header**:
- Back button → Returns to Subject Detail Screen
- Title: "Ancient History Topics"
- Subtitle: "12 topics"

**List of Topics**:
Each topic card shows:
- **Topic Name**: "Indus Valley Civilization"
- **Progress Indicator**:
  - "Not started" (gray) if 0 attempts
  - "In Progress: 15 questions attempted" (blue)
  - "Completed" (green checkmark) if user has attempted all questions in this topic (or reached some threshold like 50 questions)
- **Accuracy**: "67% accurate" (if attempted)
- **Danger Zone Indicator**: "⚠️ 3 Danger Zone questions" (if any)
- **Action Button**: "Practice" or "Continue"
  - Tap → Navigate to Topic Test Screen (questions filtered by subject + topic)

**Visual**:
- List view (not grid) — easier to scan
- Sort options:
  - Alphabetical (default)
  - By progress (in-progress first)
  - By Danger Zone count (high-risk first)

**Empty State**: Should never be empty — every subject has topics

---

### TOPIC TEST SCREEN (Existing, Minor Updates)

**No major changes needed**, just ensure:
- Questions are filtered by `subject` AND `topic`
- Breadcrumb shows: "Ancient History > Indus Valley Civilization"
- Back button returns to Topics List Screen (not home)

After test completion:
- Session summary shows (existing)
- "Back to Topics" button returns to Topics List
- "Back to Ancient History" button returns to Subject Detail Screen

---

### OVERALL INSIGHTS SCREEN (New)

**Route**: `/insights/overall` (accessible from bottom nav)

**Purpose**: Cross-subject comparison. Shows which subjects are strongest/weakest.

**Header**:
- Title: "Overall Insights"
- Subtitle: "All subjects combined"

**Sections**:

##### 1. Subject Performance Comparison

**Visual**: Horizontal bar chart or table
- Each row = one subject
- Shows:
  - Subject name
  - Accuracy %
  - Danger Zone count (last 30 days)
  - Risk indicator: 🔴/🟡/🟢

**Sorting**: By Danger Zone count (descending) OR by accuracy (descending)

**Insight Callout**:
- "Your weakest subject: Ancient History (58% accuracy, 12 Danger Zone questions)"
- "Your strongest subject: Polity (82% accuracy, 1 Danger Zone question)"

##### 2. Overall Danger Zone Trend (Optional Phase 2)

**Visual**: Line chart
- X-axis: Time (last 7/30/90 days)
- Y-axis: Danger Zone question count
- Shows trend: improving / stable / getting worse

##### 3. Cross-Subject Trap Patterns (Optional Phase 2)

**Insight**: 
- "You struggle with Conflation traps across all subjects"
- "You're well-calibrated on Temporal-Swap traps"

**This screen is SECONDARY navigation**. Most users won't visit daily — they'll stay in subject screens.

---

## Navigation Flow Examples

### Example 1: Student Wants to Practice Ancient History

```
Home Screen (subject cards)
  ↓ Tap "Ancient History" card
Subject Detail Screen (Ancient History)
  ↓ Tap "Start Random Test"
Modal: Choose 10/20/50 questions
  ↓ Select "20 questions"
Question Screen (20 questions from Ancient History)
  ↓ Answer questions, complete session
Session Summary (shows score, Danger Zone count)
  ↓ Tap "Review Danger Zone Questions"
Danger Zone Review Screen (filtered to Ancient History)
  ↓ Back button
Subject Detail Screen (Ancient History)
  ↓ Back button
Home Screen (subject cards)
```

### Example 2: Student Wants to Practice a Specific Topic

```
Home Screen
  ↓ Tap "Ancient History" card
Subject Detail Screen
  ↓ Tap "Browse Topics"
Topics List Screen (12 Ancient History topics)
  ↓ Tap "Indus Valley Civilization"
Topic Test Screen (questions from this topic only)
  ↓ Complete test
Session Summary
  ↓ "Back to Topics" button
Topics List Screen
  ↓ Back button
Subject Detail Screen
  ↓ Back button
Home Screen
```

### Example 3: Student Checks Overall Progress

```
Home Screen
  ↓ Tap "Overall Insights" in bottom nav
Overall Insights Screen
  ↓ See cross-subject comparison
  ↓ Notice "Ancient History is your weakest"
  ↓ Tap on Ancient History in the chart
Subject Detail Screen (Ancient History)
  ↓ See insights, decide to practice
  ↓ ...
```

---

## Data Queries You'll Need

All existing queries need to be scoped by subject now. Here are the key patterns:

### Subject Card Stats

**For each subject**:

```
Topics Completed:
  - Total topics for this subject: COUNT(DISTINCT topic) FROM questions WHERE subject=X
  - Topics attempted: COUNT(DISTINCT q.topic) FROM attempts a JOIN questions q WHERE q.subject=X

Accuracy:
  - Correct: COUNT(*) FROM attempts a JOIN questions q WHERE q.subject=X AND a.is_correct=true
  - Total: COUNT(*) FROM attempts a JOIN questions q WHERE q.subject=X
  - Accuracy = correct / total

Danger Zone Indicator:
  - Count: WHERE q.subject=X AND a.confidence='very_sure' AND a.is_correct=false AND a.attempted_at >= (today - 30 days)
  - If count >= 8: High Risk (🔴)
  - If count 3-7: Medium Risk (🟡)
  - If count 0-2: Low Risk (🟢)
```

### Subject Detail — Test History

```
SELECT *
FROM sessions s
JOIN attempts a ON s.id = a.session_id
JOIN questions q ON a.question_uuid = q.uuid
WHERE q.subject = 'Ancient History'
GROUP BY s.id
ORDER BY s.created_at DESC
```

### Subject Detail — Danger Zone Summary

```
SELECT COUNT(*)
FROM attempts a
JOIN questions q ON a.question_uuid = q.uuid
WHERE q.subject = 'Ancient History'
  AND a.confidence = 'very_sure'
  AND a.is_correct = false
  AND a.attempted_at >= (today - 30 days)
```

### Subject Detail — Topic Risk Ranking

```
SELECT q.topic, COUNT(*) as danger_count
FROM attempts a
JOIN questions q ON a.question_uuid = q.uuid
WHERE q.subject = 'Ancient History'
  AND a.confidence = 'very_sure'
  AND a.is_correct = false
  AND a.attempted_at >= (today - 30 days)
GROUP BY q.topic
ORDER BY danger_count DESC
LIMIT 5
```

### Subject Detail — Trap Blind Spots

```
For each trap_type in Ancient History:
  SELECT 
    q.trap_type,
    COUNT(CASE WHEN a.confidence='very_sure' THEN 1 END) as very_sure_count,
    COUNT(CASE WHEN a.confidence='very_sure' AND a.is_correct=true THEN 1 END) as very_sure_correct,
    COUNT(CASE WHEN a.confidence='guessing' THEN 1 END) as guessing_count,
    COUNT(*) as total
  FROM attempts a
  JOIN questions q ON a.question_uuid = q.uuid
  WHERE q.subject = 'Ancient History'
    AND q.trap_type IS NOT NULL
    AND a.attempted_at >= (today - 30 days)
  GROUP BY q.trap_type
```

Then calculate status (Danger Zone / Known Gap / Well Calibrated) based on percentages.

---

## Migration Strategy (Don't Break Existing Functionality)

### Phase 1: Add Subject Cards to Home, Preserve Existing Flows

**Goal**: New home screen with subject cards, but all existing screens still work.

**Steps**:
1. Create new Home Screen with subject cards (calculate stats per subject)
2. Add routing: tap subject card → navigate to new Subject Detail Screen
3. Subject Detail Screen is **new** but links to existing screens:
   - "Start Random Test" → existing Question Screen (just add subject filter to query)
   - "Browse Topics" → existing Topics List Screen (add subject filter)
   - "History" → existing session list (add subject filter)
4. Test: subject cards show correct stats, navigation works

**What stays the same**: Question Screen, Test Review Screen, Topics Screen — just add subject filtering

**What's new**: Home Screen (subject cards), Subject Detail Screen

---

### Phase 2: Add Subject-Scoped Insights

**Goal**: Danger Zone, Topic Risk, Trap Blind Spots filtered by subject.

**Steps**:
1. Create Insights section in Subject Detail Screen
2. Refactor Danger Zone queries to accept subject parameter
3. Refactor Topic Risk queries to filter by subject
4. Refactor Trap Blind Spots queries to filter by subject
5. Test: insights show correct data for each subject

**What stays the same**: Global revision queue, settings

**What's new**: Subject-scoped insights

---

### Phase 3: Add Overall Insights Screen (Cross-Subject)

**Goal**: Secondary navigation for comparing subjects.

**Steps**:
1. Create Overall Insights Screen
2. Add to bottom nav or hamburger menu
3. Build subject comparison charts/tables
4. Test: shows aggregated data correctly

**What's new**: Overall Insights Screen

---

### Phase 4: Polish & Optimize

**Goal**: Refine UX, add animations, optimize queries.

**Steps**:
1. Add progress rings/bars to subject cards
2. Add skeleton loaders for stats
3. Add empty states everywhere
4. Optimize database queries (add indexes on subject field)
5. Test performance with large data sets

---

## Visual Design Guidance

### Color Scheme (Risk Indicators)

Use consistent colors across all screens:
- **Red** (#EF4444 or similar): High Risk / Danger Zone / Wrong answers
- **Orange** (#F59E0B): Medium Risk / Needs Attention
- **Green** (#10B981): Low Risk / Correct answers / Well Calibrated
- **Blue** (#3B82F6): Known Gap (this is actually good — student knows they don't know)
- **Gray** (#6B7280): Not Started / Insufficient Data

### Typography Hierarchy

- **Subject Name**: 24-28px, Bold
- **Section Headers**: 18-20px, Semi-bold
- **Card Titles**: 16-18px, Semi-bold
- **Body Text**: 14-16px, Regular
- **Stats/Numbers**: 14-16px, Medium weight
- **Subtitles/Hints**: 12-14px, Regular, Gray color

### Spacing & Layout

- **Subject Cards**: 16px padding inside, 12px margin between cards
- **Sections within Subject Detail**: 24px vertical spacing between sections
- **Card Elevation**: Use subtle shadows for depth (elevation 2-4 in Material Design)
- **Danger Zone Cards**: Use colored left border (4px red) instead of full background color for less visual noise

### Icons

Use consistent icon family (Material Icons or Lucide React):
- Subject icons: Emoji for now (🏛️ 🌍 ⚖️ etc.) — easy to implement
- Action icons: Standard icons (shuffle for random test, list for topics, history clock for test history)
- Status icons: ✅ ❌ ⚠️ ℹ️ (use emoji for simplicity)

---

## Edge Cases & Empty States

### Subject Card Shows "0/0 topics"
- Happens if database has no questions for this subject yet
- Show card but gray it out
- Disable tap (or show "Coming Soon" message)

### Subject Has Topics But User Has 0 Attempts
- Topics Completed: "0/12"
- Accuracy: "No data yet"
- Danger Zone: "🟢 Low Risk" (default, since 0 danger zone questions)

### User Attempts Only 1 Subject
- Home screen still shows all 7 subject cards
- 6 cards will have "Not started" state
- That's okay — it shows the full curriculum scope

### Test History is Empty for a Subject
- Show empty state: "No tests yet. Start practicing!"
- CTA button: "Start Random Test"

### Topic Has No Questions in Database
- Should ideally not happen (topics are derived from questions table)
- If it does, skip that topic in the list OR show but gray out

### Insights Have Insufficient Data
- Danger Zone: Show 0 if no data
- Topic Risk: "Not enough data yet"
- Trap Blind Spots: "Insufficient Data" status for each trap
- Don't hide the sections — show them but with helpful empty states

---

## Performance Considerations

### Subject Card Stats Calculation

Calculating stats for 7 subjects on home screen = 7 database queries minimum (could be 21 if you query topics/accuracy/danger separately per subject).

**Optimization Strategy**:
1. **Single aggregated query**: Get all stats for all subjects in ONE query, then split in UI
2. **Caching**: Cache subject stats for 5 minutes (update when user completes a test)
3. **Background calculation**: Calculate stats in background worker, store in separate table (`subject_stats`)
4. **Lazy loading**: Load stats for 1st subject immediately, load rest in background

For MVP, optimize later. Start with simple queries, measure performance, then optimize if slow.

### Filtering Questions by Subject

Add database index:
```
CREATE INDEX idx_questions_subject ON questions(subject);
```

This makes `WHERE subject='Ancient History'` queries fast even with 32k questions.

---

## Settings & User Preferences

### New Setting: Default Subject

Allow user to set a "default subject" that opens when app launches (instead of home screen).

**Use case**: Student is focusing on Ancient History this week, wants to jump straight to Ancient History screen every time.

**Implementation**:
- Settings screen: Dropdown "Default Subject" (None / Ancient History / Polity / etc.)
- If set, app launch navigates directly to that Subject Detail Screen
- Add "Home" button in Subject Detail Screen to return to subject cards

**Priority**: Phase 3 or later (nice-to-have)

---

## Testing Checklist

### Phase 1 Testing

**Home Screen**:
- [ ] 7 subject cards display correctly
- [ ] Each card shows correct icon and name
- [ ] Stats calculate correctly (topics completed, accuracy, danger zone indicator)
- [ ] Tapping card navigates to Subject Detail Screen with correct subject

**Subject Detail Screen**:
- [ ] Header shows correct subject name and icon
- [ ] "Start Random Test" opens modal with 10/20/50 options
- [ ] Selecting test size navigates to Question Screen with subject-filtered questions
- [ ] "Browse Topics" navigates to Topics List Screen filtered to this subject
- [ ] Back button returns to Home

**Question Flow**:
- [ ] Questions are all from selected subject
- [ ] Session summary shows correct stats
- [ ] Can navigate back to subject screen from summary

---

### Phase 2 Testing

**Subject Detail Insights**:
- [ ] Danger Zone summary shows correct count for this subject
- [ ] Topic Risk Ranking lists only topics from this subject, sorted by danger count
- [ ] Trap Blind Spots filtered to this subject's questions
- [ ] "Review Danger Zone Questions" navigates correctly
- [ ] Empty states show when no data

---

### Phase 3 Testing

**Overall Insights Screen**:
- [ ] Shows all 7 subjects in comparison view
- [ ] Stats aggregate correctly across all subjects
- [ ] Tapping subject in chart navigates to Subject Detail Screen

---

## Known Limitations & Future Enhancements

### Current Scope Does NOT Include:

1. **Cross-Subject Tests**: User can't (yet) create a test mixing Ancient History + Polity questions
   - Deferred to Phase 4 or later
   - Add as "Full Syllabus Mock Test" feature

2. **Subject-Specific Revision Queue**: Revision queue is still global (all subjects mixed)
   - Could add "Revise Ancient History Only" option later

3. **Subject Progress Gamification**: No badges/streaks/achievements per subject
   - Add in Phase 5 if engagement metrics need boost

4. **Customizable Subject Order**: User can't reorder subject cards on home screen
   - Hardcoded order for now
   - Could add drag-to-reorder later

5. **Subject Icons**: Using emoji for now, not custom illustrations
   - Upgrade to proper icons/illustrations in Phase 4

### Technical Debt Created:

1. **No caching of subject stats**: Recalculated every time home screen loads
   - Acceptable for MVP with small data
   - Add caching when performance degrades

2. **N+1 query problem**: Each subject card might trigger separate queries
   - Refactor to bulk queries in Phase 4

3. **No offline support for subject stats**: Requires internet to calculate
   - Add offline caching later if needed

---

## Success Metrics (Post-Launch)

### Engagement Metrics:
- **Subject Card Tap Rate**: Do users engage with subject cards? (Target: >80% of users tap at least one subject card per session)
- **Subject Focus Time**: Average time spent in a single subject screen (Target: >5 minutes per session)
- **Topic Completion Rate**: % of topics with at least 10 attempts per subject (Target: >30% within 30 days)

### Learning Outcome Metrics:
- **Subject-Specific Accuracy Improvement**: Does accuracy increase within a subject over time?
- **Danger Zone Reduction Per Subject**: Do students become less overconfident in their weak subjects?

### Navigation Metrics:
- **Overall Insights Screen Usage**: How many users check cross-subject comparison? (If <10%, consider removing or hiding deeper)
- **Back Button Usage**: Do users get lost? High back-button spam = confusing navigation

---

## Handoff Checklist for Claude Code

When you start working on this:

**Step 1**: Analyze Current Structure
- [ ] Read entire `lib/` folder structure
- [ ] Identify current home screen implementation
- [ ] Identify current navigation patterns (GoRouter? Navigator 2.0?)
- [ ] Identify how questions are currently fetched (provider? use case? repository?)
- [ ] Identify where test history is displayed
- [ ] Map out current folder structure (features-based? screens-based?)

**Step 2**: Propose Detailed Plan
Before writing ANY code, give me:
- [ ] List of files that need to be created (new screens, providers, etc.)
- [ ] List of files that need to be modified (existing screens, queries, etc.)
- [ ] List of files that can stay unchanged
- [ ] Proposed folder structure for new subject-related features
- [ ] Migration steps (Phase 1, 2, 3 with specific tasks per phase)
- [ ] Estimated risk areas (where things might break)

**Step 3**: Get Approval, Then Execute Phase by Phase
- [ ] Wait for my approval of the plan
- [ ] Execute Phase 1 (subject cards + subject detail screen)
- [ ] I test Phase 1
- [ ] Execute Phase 2 (subject-scoped insights)
- [ ] I test Phase 2
- [ ] Execute Phase 3 (overall insights screen)
- [ ] I test Phase 3

**Step 4**: Document What Changed
After each phase:
- [ ] List files created
- [ ] List files modified
- [ ] Note any breaking changes
- [ ] Note any new dependencies added
- [ ] Provide testing instructions specific to that phase

---

## Existing Features That Stay Independent

**IMPORTANT**: The following features already exist in the app and should **NOT** be refactored into subject-centric structure. They operate independently and should remain accessible globally.

### 1. Battles (1v1 Competitive Mode)

**Current State**: Users can challenge each other to competitive question battles.

**How It Integrates**:
- **Keep in bottom navigation** OR as a separate tab/section (NOT nested under subjects)
- Battles can mix questions from all subjects (that's part of the competitive challenge)
- **Do NOT** create "subject-specific battles" (at least not in this refactor)
- Battle history should remain separate from subject-specific test history
- Battle results do NOT contribute to subject-specific insights (Danger Zone, Topic Risk, etc.)
  - Reason: Battle mode is competitive, not learning-focused. Confidence ratings aren't captured in battles.
  - Keep battle stats separate: win/loss record, ranking, etc.

**Navigation**:
```
Bottom Nav:
├─ Home (subject cards)
├─ Battles ← stays as-is, independent
├─ Revision Queue
├─ Overall Insights
└─ Settings
```

**Battle Flow Stays Unchanged**:
```
Battles Screen
├─ Create Battle
├─ Join Battle
├─ Battle History
└─ Leaderboard
```

**What Changes**: Nothing about battles. They remain global, cross-subject, competitive.

---

### 2. Community Features

**Current State**: Users can interact with each other (comments, discussions, sharing, etc.)

**How It Integrates**:
- **Keep as separate section** in bottom nav or hamburger menu
- Community is NOT subject-specific (users discuss all topics together)
- **Do NOT** create per-subject community feeds (at least not now — could be Phase 5)
- Community posts/discussions remain global

**What Changes**: Nothing. Community stays exactly as it is.

**Optional Future Enhancement** (Phase 5, not now):
- Users could optionally tag posts with subject (e.g., "Question about Ancient History")
- But feed remains unified, not split by subject

---

### 3. Revision Queue

**Current State**: Spaced repetition system that surfaces questions for review.

**How It Integrates**:
- **Stays global** (questions from all subjects mixed together)
- Accessible from bottom nav OR dedicated screen
- **Optional future enhancement** (Phase 4):
  - Add filter: "Revise Ancient History only"
  - Add filter: "Revise Danger Zone questions only"
  - But default behavior: global queue across all subjects

**Why It Stays Global**:
- Spaced repetition works better with variety (not drilling one subject continuously)
- Students should interleave subjects for better retention
- Revision queue is a different mental mode than "I'm studying Ancient History today"

**Navigation**:
```
Revision Queue Screen
├─ Questions to review (from all subjects)
├─ Filters (optional):
│  ├─ All subjects (default)
│  ├─ Ancient History only
│  └─ Danger Zone questions only
```

**What Changes**: 
- Nothing in Phase 1-3
- Phase 4: Add optional subject filter to revision queue

---

### 4. Any Other Global Features

If you have:
- **Bookmarks**: Keep global, add optional subject filter later
- **Search**: Keep global, search across all subjects
- **Settings**: Obviously stays global
- **Profile/Stats**: Could show overall stats + breakdown by subject (but profile screen itself is global)

---

## General Principle: Learning vs. Performance Features

**Subject-Centric** (Learning Mode):
- Practice (learning mode, test mode)
- Test History
- Insights (Danger Zone, Topic Risk, Trap Blind Spots)
- Topics browsing
- These are all about **deliberate practice and improvement**

**Global/Independent** (Performance/Social Mode):
- Battles (competitive)
- Community (social)
- Revision Queue (spaced repetition across all content)
- Leaderboards (if exists)
- Achievements/Badges (if exists)
- These are about **engagement, competition, retention**

**Keep these two worlds separate**. Don't force battles into subject structure. Don't force community into subject silos.

---

## Updated Bottom Navigation (Recommendation)

**Option A: 5-item Bottom Nav**
```
Home | Battles | Revision | Community | Profile
```

**Option B: 4-item Bottom Nav + Hamburger**
```
Home | Battles | Revision | More
                              └─ Community
                              └─ Overall Insights
                              └─ Settings
```

**Option C: Tabs on Home**
```
Bottom Nav: Home | Battles | Revision | Profile

Home Screen has two tabs:
├─ Subjects (subject cards) ← default
└─ Community
```

Choose based on your current design. The key: **Battles, Community, Revision remain top-level, not nested under subjects**.

---

## What This Means for Claude Code

When you refactor:

**DO refactor**:
- Home screen → subject cards
- Practice/learning flows → subject-centric
- Test history → subject-scoped
- Insights → subject-scoped

**DO NOT touch**:
- Battles screens
- Community screens
- Revision queue screen (except optional subject filter in Phase 4)
- Any social/competitive features

**Integration points**:
- Navigation structure needs updating (bottom nav stays, but Home changes)
- Database queries for practice/history need subject filtering
- Battles/Community queries stay global (no subject filtering)

---

## Final Notes for Claude Code

**This is a structural refactor, not a rewrite**. You're reorganizing the app's information architecture, not rebuilding everything from scratch.

**Preserve existing functionality**. The Question Screen, Test Review Screen, Revision Queue — these all work fine. You're just adding a subject-based navigation layer on top.

**Data is already structured correctly**. The `questions` table has `subject → topic → sub_topic` hierarchy. You're surfacing this hierarchy in the UI.

**Subject-centric architecture makes the app MORE scalable**, not less. When you add the Danger Zone confidence rating feature later, it will slot perfectly into the Subject Detail Insights section.

**Don't overthink the visual design**. Use standard Material Design components, keep it clean, optimize for clarity over beauty. Design polish is Phase 4.

**Ask questions if anything is unclear**. If you're not sure how to handle a specific case, flag it and ask before proceeding.

Good luck! This refactor will transform the app from "just another question bank" to "a personalized study companion that understands how UPSC students actually study."