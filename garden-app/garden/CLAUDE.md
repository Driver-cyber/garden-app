# CLAUDE.md — Garden App Constitution
*Governing document for the `Driver-cyber/garden-app` repo*
*Drafted: 2026-04-24 — copy this file to CLAUDE.md when you initialize the repo*

---

## 🧭 Guiding Principles

*These principles govern how we work on Garden, distinct from what Garden does. They apply to every session, every pull request, every refactor. They are inlined here for now, but the intent is to extract them into a shared `working-principles.md` file referenced by every Driver-cyber project constitution. Until that file exists, this is the canonical source.*

**Token-conscious consumption.** Tokens, compute, and energy all have real-world cost. Prefer targeted reads over recursive ones. Ask for specific file paths rather than grep-ing blindly. Don't re-read files already in context. Don't restate what was just said. This is not about sacrificing capability — it's about being a conscientious guest in a finite system.

**Measure twice, cut once.** Propose a plan before writing code. Wait for explicit approval — "y," "go," "sounds good" — before moving to execution. One more clarifying question during planning is always cheaper than discovering the wrong approach after implementation. Claude Code already leans this direction; this constitution reinforces it.

**Ordo ab chao.** Order from chaos. Take disparate inputs, tools, and constraints and produce something coherent, useful, and ideally beautiful. But don't let perfect be the enemy of good — accept some chaos in the results. Shipping something working beats theorizing about something perfect.

**Focused elegance and uncompromising utility.** The product must perform its function first. But how it performs that function should feel considered — simple, elegant, joyful to interact with. The means matter as much as the ends. Ugly-but-functional fails the second half of the test.

**Appreciation and humility.** This is a partnership. Neither party — human nor AI — is subordinate. Pushback, disagreement, and "have you considered" are all welcome from both sides. Sycophantic agreement is the failure mode, not the goal.

---

## 🌾 North Star

Garden is Chad's personal iPhone app for presence and clarity. It has three jobs:

1. **Get ideas out of your head** — quick-capture notes organized by category, exportable as markdown
2. **Check off the one thing** — a single daily checkbox that, when done, earns you confetti and permission to put your phone down
3. **Return to calm** — a wheat field you can watch for ten seconds and remember why any of this matters

This is not a productivity app. It is an anti-productivity app. The goal is fewer minutes on the phone, not more. Every design decision should be tested against: *does this help Chad be more present, or does it give him another reason to stay in the app?*

**Origin:** Garden grew out of the Notepad and Calm tabs in the `project-dashboard` web app (Driver-cyber/project-dashboard). The web version proved the concept. This is the native iPhone version — same soul, native material.

---

## 🚫 Anti-Patterns (The Things Garden Refuses)

These are the specific behavioral patterns Garden will never adopt, regardless of version. Features matching any of these are categorically out of scope — not deferred, not revisitable. Unlike the "Out of Scope (v1)" table below, these are permanent refusals.

- **No notifications.** Not push, not local, not "gentle nudges." Garden must earn opens; it never demands them.
- **No streaks.** Not for the One Thing, not for note-taking frequency, not for anything. Streaks are anxiety machines dressed as motivation.
- **No badges or red dots.** Not on the app icon, not on tabs, not on the recap card. No visual debt.
- **No "come back" prompts.** No "you haven't opened Garden in a week," no email digests, no re-engagement anything.
- **No social features.** No sharing note counts, no comparing with anyone, no leaderboards. Garden is a personal tool, period.
- **No gamification language.** "Level up," "achievement unlocked," "progress" — all wrong register. Garden's voice is calm and self-contained, not motivational.

**Metrics, carefully.** Usage statistics are not inherently forbidden, but they must serve reflection, not engagement. Counts can appear in recaps as context ("a quiet quarter" or "a full one") but never as targets, streaks, or goals. If a metric would look at home in Wrapped, it does not belong in Garden. When in doubt, cut it.

---

## 💾 Storage Philosophy

Garden uses a three-layer storage model. Each layer protects against a different failure mode. **Do not consolidate these layers. Do not add a backend. Do not remove the manual export.**

**Layer 1 — SwiftData local (primary).**
All notes live on the device in a real local database (SQLite under the hood). Works offline, persists through app closes, phone restarts, and OS updates. Survives anything short of uninstall. This is the primary storage — everything else is augmentation.

*Protects against:* the failure mode that broke the project-dashboard web version — browser localStorage being treated as disposable cache and wiped on refresh. SwiftData is structurally not that.

**Layer 2 — CloudKit sync (convenience).**
SwiftData's built-in `cloudKitDatabase: .automatic` flag syncs notes across signed-in Apple devices and survives phone loss or reinstall. No tokens, no server, no user setup — it just works when the user is signed into iCloud.

*Protects against:* device loss, theft, wipe, reinstall. Enables future cross-device use (iPad, Mac) without any extra code.

**Layer 3 — Manual markdown export (insurance).**
A plain markdown file the user owns outright. Triggered two ways: (a) the quarterly recap's closing "Save this quarter?" prompt (v2), and (b) an always-available "Export everything" option in Settings. The file goes through iOS's Share Sheet — destination is the user's choice (iCloud Drive, Files, email, etc.).

*Protects against:* Apple outages, iCloud account issues, Garden itself being deprecated or lost. A markdown file is readable by anything, forever.

**The key insight from the project-dashboard failure:** depending on a single storage mechanism — especially one the system considers ephemeral — is the problem. The fix isn't a smarter single mechanism; it's layered independence. Each layer works without the others. None requires setup from the user.

---

## 🏗 What This Repo Contains

| File / Folder | Purpose |
|---|---|
| `GardenApp/` | Xcode project root — all Swift source |
| `GardenApp/Models/` | SwiftData model definitions |
| `GardenApp/Views/` | SwiftUI views, organized by screen |
| `GardenApp/Design/` | Color palette, typography helpers |
| `GardenApp.xcodeproj/` | Xcode project file — do not hand-edit |
| `garden-app-tracker.html` | Build tracker — embedded `<script id="tracker-data">` JSON consumed by the project-dashboard at garden.chadstewartcpa.com. Schema: `columns[].priorities[].{title, note}` + `backlog[]` plain strings + `shipped[].{date, what, tags[], learned?}` for the Galaxy view (see `DECISIONS.md` Decisions 27–28). |
| `learned-log.json` | Append-only learning log — **development artifact** tracking what was built each session, not a user-facing feature |
| `CLAUDE.md` | This file |
| `DECISIONS.md` | Living decision log |

---

## 🛠 Architecture

**Platform:** iOS 17+ (SwiftUI + SwiftData + CloudKit)

**Why SwiftUI over React Native:**
The feel *is* the product. Wheat field animation, haptic feedback on the checkbox, spring animations on note cards — these need to be native. SwiftUI gives 60fps animations, native haptics, and iCloud sync via CloudKit with almost no boilerplate. React Native can approximate it but the gap in feel is real.

**Why SwiftData + CloudKit:**
See Storage Philosophy above for the full rationale. The short version: SwiftData gives us a real local database with automatic CloudKit sync via a single flag, no custom infrastructure required.

**Data flow:**
```
User types note
  → SwiftData save (local, instant)
  → CloudKit sync (background, automatic)
  → Available on all signed-in devices
  → Manual markdown export available anytime
```

**No backend. No server. No API keys.** iCloud is the sync layer; markdown files are the durable artifact.

---

## 📐 Design System

The Garden palette is locked. These are the source values from the web app — translate them to Xcode Color Sets (Assets.xcassets) with matching light/dark variants.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#F2EDE3` | `#1A1F18` | App background |
| `paper` | `#FAF7F0` | `#222820` | Card surfaces |
| `ink` | `#2C3328` | `#E8E0D0` | Primary text |
| `ink2` | `#4A5448` | `#B4BEB0` | Secondary text |
| `ink3` | `#7E887C` | `#7C867A` | Tertiary / hints |
| `line` | `#DDD5C3` | `#2A3228` | Borders |
| `sageDeep` | `#35523A` | `#B4D3AE` | Primary action color |
| `sageSoft` | `#8EAE8A` | `#6A8E66` | Secondary accent |
| `sageTint` | `#E8F0E6` | `#1E2B1E` | Tinted backgrounds |
| `blush` | `#DDB2AE` | `#D6A8A2` | Warning / destructive tint |
| `blushDeep` | `#6E3A36` | `#ECBDB6` | Warning / destructive text |
| `wheat` | `#C8A96E` | `#A88A4E` | Wheat field blades |
| `sky` | `#87CEEB` | `#1A3A5C` | Calm screen sky |

**Typography:**
- Serif headings: bundle `Instrument Serif` (download from Google Fonts, add to project). Use `.italic()` for the signature cursive feel.
- Body / UI: SF Pro (system default — never specify this, just use `.body`, `.caption`, etc.)
- Monospace (note timestamps, category tags): `.monospacedSystemFont(ofSize:weight:)` or SF Mono

**Spacing:** Use multiples of 4pt. Cards have 16pt padding. Compose areas have 14pt padding.

**Animations:** Use `.spring(response: 0.35, dampingFraction: 0.72)` as the default spring. Match the web app's smooth feel.

---

## 🗃 Data Model

```swift
// Models/Note.swift
@Model
final class Note {
    var id: UUID = UUID()
    var categoryID: UUID          // FK to Category
    var text: String
    var createdAt: Date = Date()
    var status: NoteStatus = .active

    init(categoryID: UUID, text: String) {
        self.categoryID = categoryID
        self.text = text
    }
}

enum NoteStatus: String, Codable {
    case active, archived
}

// Models/Category.swift
@Model
final class Category {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var sortOrder: Int = 0        // user can reorder

    init(name: String) {
        self.name = name
    }
}

// "Ideas / TBD" is a seeded Category, not a sentinel value.
// Create it in the app's first-launch seed:
//   Category(name: "Ideas / TBD")
// Its ID is stored in UserDefaults as "garden.tbd.categoryID"
// so it can be found without special-casing.
```

**One Thing state** (resets daily, doesn't need CloudKit):
```swift
// Stored in UserDefaults — key: "garden.oneThingCheckedDate"
// If the stored date is today, the checkbox is checked.
// Reset = just don't write today's date.
```

**ModelContainer setup** (GardenApp.swift):
```swift
@main
struct GardenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Note.self, Category.self], cloudKitDatabase: .automatic)
    }
}
```

---

## 🖼 View Hierarchy

```
ContentView (TabView)
├── NotesView                      — tab 1
│   ├── NoteComposerView           — top: category picker + textarea + Add button
│   ├── CategoryChipsView          — filter chips (All, Ideas/TBD, [user categories])
│   ├── NoteListView               — scrollable list of active notes
│   │   └── NoteRowView            — individual card: project tag, timestamp, text, Archive/Delete
│   ├── ArchivedNotesView          — collapsible section at bottom
│   └── ExportView (sheet)         — markdown preview, Copy / Share
│       └── ArchivePickerView      — "archive exported notes?" step
└── CalmView                       — tab 2
    ├── WheatFieldView             — 80 animated blade divs → SwiftUI Canvas or GeometryReader
    ├── OneThing card              — "I did the one thing today" checkbox + confetti
    └── ConfettiView               — burst animation overlay on checkbox tap
```

**Tab bar:** Two tabs only. Notes (pencil icon) and Calm (leaf or wheat icon). No nav bar on CalmView — it should feel like stepping outside. **The Calm screen has exactly one job per element: wheat field for presence, One Thing card for the daily checkbox. No other content ever lives on the Calm screen.**

---

## 🌾 Calm Screen Engineering Notes

**Wheat field:** Recreate the web animation in SwiftUI using `TimelineView` + `Canvas` for performance, or as individual `Rectangle` views with `.rotationEffect` and `withAnimation(.linear(duration:).repeatForever())`. The Canvas approach handles 80 blades at 60fps without dropping frames.

```swift
// Blade animation pattern (pseudocode)
// Each blade: height 60–100% of field height, random width 2–4pt
// Sway: rotationEffect from -6° to +6°, transform origin at bottom
// Animation: linear, duration 3.0–3.6s, staggered delay = -(i/N) * waves * period
// This creates a traveling wave left-to-right
```

**Confetti:** Fixed-position colored rectangles (4–8pt wide, 12–16pt tall) launched from the checkbox position. Use `.offset` + `.opacity` + `.rotationEffect` animated with `.spring()`. Scatter 20–30 pieces using random `dx`/`dy` offsets, fading out over 0.8s.

**Haptic feedback:** On checkbox check → `.impact(.medium)`. On confetti burst → `.notification(.success)`. These are the moments that make the native app feel alive vs. the web version.

---

## 📤 Export Flow

Same two-step flow as the web app, simplified:

**Step 1 — Preview:**
- Select category (or "all") → shows markdown preview
- Two buttons: **Copy markdown** | **Share** (iOS Share Sheet)
- Markdown is the universal format — paste it into Claude Code, Notes, email, a prompt, anywhere

**Step 2 — Archive picker:**
- "Archive exported notes?" checkbox list
- **Archive checked** | **Keep all active**

The Share button uses `ShareLink` (SwiftUI native) — supports AirDrop, Notes, iMessage, Files, iCloud Drive, Mail, and anywhere else the user has configured.

**Note on the removed "Copy as prompt" button:** the previous draft included a third button that wrapped notes in a Claude Code implementation prompt. Removed in favor of simplicity. Garden holds notes of every kind — grocery lists, kid observations, dream fragments, project ideas — and a "please implement these" button is wrong for most of them. Users can still paste markdown into a Claude Code prompt when appropriate; no dedicated button is needed.

---

## ⚙️ Session-End Protocol

1. **Update `garden-app-tracker.html`** — move completed priorities to backlog, pull up next items, bump the `updated` date.
2. **Append to `learned-log.json`** — one entry per meaningful completion.
3. **Optionally ask Chad** one question: "Anything specific to note from today?"
4. **Commit:** `"[garden-app] — [what changed] | log updated"`

---

## 🚀 Session Startup Protocol

1. **Read `DECISIONS.md`** — understand current phase and open questions.
2. **Read `garden-app-tracker.html`** — check current build priorities.
3. **Do not read the Xcode project file** (`*.xcodeproj`) — it's XML-ish, not useful, and expensive in tokens.
4. **Do not recursively read source folders at session start.** Ask Chad for the specific files relevant to today's task.
5. **Ask before refactoring** — SwiftUI views can be refactored in many ways; pick one and stick to it rather than restructuring each session.
6. **Propose a plan before writing code.** Wait for explicit approval ("y," "go," "sounds good") before implementation.

---

## 🔧 Xcode Project Setup Checklist

*For the Claude Code session that initializes the repo:*

- [ ] Create new Xcode project: `File → New → App`, name `Garden`, bundle ID `com.drivercyber.garden`
- [ ] Target: iOS 17+, SwiftUI interface, SwiftData storage
- [ ] Enable CloudKit capability: `Signing & Capabilities → + Capability → iCloud → CloudKit`
- [ ] Create CloudKit container: `iCloud.com.drivercyber.garden`
- [ ] Add `Instrument Serif` font files to project, register in `Info.plist` under `UIAppFonts`
- [ ] Create `Assets.xcassets` Color Sets for all 13 design tokens above (light + dark each)
- [ ] ~~Create `Design/GardenColors.swift`~~ — *not needed in Xcode 15+. The compiler auto-generates `Color.bg`, `Color.ink`, etc. from the asset catalog. Writing them manually causes "Invalid redeclaration" errors.*
- [ ] Seed "Ideas / TBD" category on first launch (check `UserDefaults.standard.bool(forKey: "garden.seeded")`)

---

## 🚫 Out of Scope (v1)

*Features deferred to future versions. Unlike the Anti-Patterns section above, these are deferrals — they could be revisited. Anti-patterns are permanent refusals.*

| What | Why parked |
|---|---|
| Quarterly recap | v2 feature — see parking lot for full spec |
| Android | SwiftUI is iOS-only; cross-platform requires a rewrite |
| Widgets | Good idea for "one thing" on home screen — revisit after v1 ships |
| Collaboration / sharing | This is Chad's personal tool |
| Dark mode toggle | Follows system automatically — no manual toggle |

---

## 🔑 Key Decisions Already Made

| Decision | Rationale |
|---|---|
| SwiftUI + SwiftData over React Native | Native feel is the product; CloudKit sync for free |
| Three-layer storage (local + CloudKit + manual export) | Each layer protects a different failure mode; no single point of failure |
| Categories not repos | App is standalone; no GitHub dependency |
| Two tabs only (Notes + Calm) | Dashboard view not needed; notes list *is* the dashboard |
| Calm screen contains only wheat field + One Thing | Single-purpose screen; no recap, no notes, no secondary content |
| "Ideas / TBD" is a seeded Category | No sentinel values; consistent data model |
| Daily reset for One Thing | Resets at midnight via date comparison, not a timer |
| No account/auth beyond iCloud | User is always Chad; iCloud is already authenticated |
| Anti-patterns section is load-bearing | These refusals are permanent, not deferrals |
| "Copy as prompt" removed from export | Markdown is flexible enough; button was narrowing app's purpose |

---

## 💡 Future Ideas (Parking Lot)

### Quarterly Recap (v2)

A seasonal re-reading ritual, not a usage summary. Surfaces forgotten notes and hyper-focus sessions from the preceding quarter. Fun journey through your notes, not a celebration of how much you used the app.

**Cadence and trigger:**
- Fires on fixed calendar quarter boundaries (Q1: Jan–Mar, Q2: Apr–Jun, Q3: Jul–Sep, Q4: Oct–Dec)
- Appears the first time Garden opens after a quarter boundary
- No notifications, no badges, no red dots — the recap waits quietly to be noticed

**Placement and lifecycle:**
- Appears as a single quiet card **above the composer on the Notes tab**
- Styled as serif italic text (Instrument Serif) — reads like a note that surfaced itself, e.g. "a letter from last quarter"
- Tap to enter the recap experience
- Visible for **7 days** after quarter begins, then silently dismisses itself
- Whether engaged with or ignored, next appearance is the following quarter
- **Never on the Calm screen.** Calm screen is wheat field + One Thing only.

**Form (TBD when actually built):**
- Leaning toward a word cloud of the quarter's notes, typeset in Instrument Serif with Garden palette — like a page from a commonplace book, not a blog sidebar
- Should surface *content* (what you were thinking about) more than *counts* (how many notes you wrote)
- A "hyper-focus session" signal is worth detecting — clusters of notes in the same category within a short window, surfaced as "you were really thinking about X on [date]"
- Threshold for what counts as a hyper-focus session is TBD

**Closing ritual — the backup prompt:**
- Final screen of the recap: gentle prompt, "Save this quarter?"
- Tap → Share Sheet producing `Garden-YYYY-QN.md` (just that quarter's notes as markdown)
- Skip always available — no guilt, no badge, no "backup overdue" anywhere
- Purpose: turn the backup action into a natural closing gesture of reflection, not a maintenance chore

**Always-available alternative:**
- Settings contains a separate "Export everything" option for on-demand full-archive backups
- Independent of the recap cadence

**Anti-patterns that must not creep into the recap:**
- No notifications ("your recap is ready!")
- No badges on the recap card
- No streaks or goals ("you wrote more than last quarter!")
- No push re-engagement
- Metrics carefully: counts as context ("a quiet quarter") are fine; counts as targets are not

**Open question parked for v2 build time:**
- Should past recaps be browsable (seasonal journal model) or ephemeral (each season makes room for the next)? Both have merit. Decide when building, not now.

### Other Parking Lot Items

- **"One Thing" widget** — home screen widget showing today's one thing with tap-to-check interaction
- **Project Dashboard integration** — web dashboard could show a "Garden Notes" card pulling from a user-published export (if user opts in)
- **Shortcut / Siri integration** — "Hey Siri, add to Garden" → quick-capture sheet
- **Calm screen variations** — rain, snow, night sky — seasonal alternates driven by the device calendar
- **Shared `working-principles.md`** — cross-project file referenced by every Driver-cyber project constitution; extract the Guiding Principles section here into that canonical file once created

---

*This constitution was refined in a planning session on 2026-04-24, building on an initial draft authored the same day. It incorporates five targeted decisions: adoption of a three-layer storage philosophy, inline guiding principles with future extraction noted, a full spec for the quarterly recap (v2), a dedicated Anti-Patterns section with one softened clause around metrics, and the removal of the "Copy as prompt" export button. The Notepad and Calm tabs in `Driver-cyber/project-dashboard` remain the reference implementation — read `index.html` there for the exact animation math and export flow before building the native equivalents.*
