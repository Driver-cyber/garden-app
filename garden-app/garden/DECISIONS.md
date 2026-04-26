# DECISIONS.md — Garden App Living Decision Log

> **For Claude Code:** This file is the journal. `CLAUDE.md` is the constitution — stable, principles, architecture. This file is volatile — current phase, decisions made, open questions, pivots. Read `CLAUDE.md` first for *how we work*; read this file for *where we are*.

---

## 🎯 Current Phase

**Phase:** Core functions locked. Ready for App Store submission.

**What's next:** Submission chain only — no more engineering work expected before 1.0. (1) CloudKit Dashboard "Deploy Schema Changes" for production. (2) Host the privacy policy (draft in `app-store-listing.md`). (3) Capture 5 screenshots at 6.7" iPhone size. (4) Create the App Store Connect record + fill in the App Privacy nutrition label as "Data Not Collected." (5) Archive + Distribute → App Store Connect → Upload from Xcode. (6) Submit for App Review. After 1.0 ships, anything Chad notices post-launch goes into 1.1, and only then does the link go to wife and friends.

**Vibe:** Chad signed off the polish pass on 2026-04-26 — "the core functions are there." The Calm screen is final (Breathe. card raised to upper-middle of the screen via 300pt bottom padding); the Notes side is final (edit, search, archive grouping, keyboard dismiss, all working on his iPhone 16e). The repo's 8 local commits are about to be pushed to `origin/main` and the next session opens against the App Store submission gates, not the codebase. Strategy reframe — see Decision 17 — has us going public-listing-first for the practice rep, then 1.1 before sharing with wife/friends.

---

## 🛠 Active Tech Stack

Locked by `CLAUDE.md`. Reproduced here for quick reference:

- **Platform:** iOS 17+
- **UI:** SwiftUI
- **Persistence:** SwiftData (local primary) + CloudKit (automatic sync via `.modelContainer(..., cloudKitDatabase: .automatic)`)
- **Backup:** Manual markdown export via iOS Share Sheet (`ShareLink`)
- **Typography:** Instrument Serif (bundled) + SF Pro (system) + SF Mono (system)
- **Animations:** `.spring(response: 0.35, dampingFraction: 0.72)` as default
- **Reference implementation:** Notepad and Calm tabs in `Driver-cyber/project-dashboard`

**Not in the stack:** no backend, no API, no React Native, no third-party sync layer.

---

## 📝 Decision Log

### 2026-04-26 (latest) — real-device install, polish pass, App-Store-first pivot

**Session summary:** Spanned three threads in one long sitting. (1) Got the app onto Chad's iPhone 16e via Path A — a chain of issues from iOS deployment-target mismatch (26.4 → 17.6) through codesign trust, dyld extraction, and finally a disk-space cleanup (DerivedData + iOS DeviceSupport, ~7.4 GB freed) that unblocked the install. (2) After Chad started testing on the device, ran a polish pass against his live feedback: keyboard "Done" toolbar dismiss, search bar (`.searchable` navigation drawer + scroll-to-dismiss), inline edit on existing notes (pencil button toggles a TextField with Save/Cancel), archive picker grouped by category headers, and a Calm screen redesign that pulls the original web layout into the native card — italic serif "Breathe." headline, "One thing. One breath. One check." subtitle, 96pt rounded checkbox, "Tap when you've done the one thing." footer; wheat blades now pick from a 5-shade brightness palette for texture; confetti slowed from a snappy 0.7s spring to an `.easeOut(1.6)` drift with 2.6s removal. (3) Chad reframed the distribution strategy mid-session — the new path is public App Store submission ASAP, then a 1.1 update before sharing with friends.

**Decision 17: Distribution path is public App Store first, *for the practice rep*; share with wife/friends only after 1.0 → 1.1.**
The earlier plan (Decision 10) was TestFlight Internal first → wife as tester → maybe public listing later. New plan: submit a slightly rough 1.0 to the public App Store as soon as the gates are cleared, treat App Review as the rehearsal, then push a 1.1 update with whatever polish surfaced post-launch *before* sending the link to wife and friends. So friends never see 1.0 — they see 1.1 on a real public listing. Reasoning: TestFlight Internal skips the actual App Store experience (review queue, metadata rejection patterns, ASC submission ergonomics), and Garden is the perfect low-stakes testbed for those skills. The "rough 1.0 → polish in update" rhythm is the standard real-world cadence and worth practicing once on a personal app where nothing depends on the launch. Implications: privacy policy hosting becomes load-bearing (required for public listings, was optional for TestFlight Internal); screenshots are required (5 in 6.7" sizing per `app-store-listing.md`); App Privacy nutrition label fill-in becomes part of the submission step; rejection feedback is *expected*, not a failure mode. TestFlight Internal Tester invites move to a backlog item — possibly used for 1.1 candidate builds before the public update lands, but no longer the primary distribution surface.

**Decision 18: Two-tab simplicity is locked — secondary surfaces go through Settings or a menu.**
Chad reaffirmed mid-session that he loves the Notes + Calm two-screen structure and wants to preserve it. Constitutionally this was already covered by `CLAUDE.md`'s "Two tabs only" rule, but the new framing extends it: it's not just "no third tab right now" — it's *"any new surface (reporting, recap, stats, exports, etc.) routes through Settings or a contextual menu, never as a top-level tab."* Quarterly Recap (v2) already follows this (lives as a card on Notes); future surfaces should too. When proposing a new feature, the entry-point should be specified up front as "reachable from Settings/menu" so this can be sanity-checked before code is written. Treat any "let's add a tab" suggestion as a constitution-level change, not a normal feature decision. Saved as a feedback memory.

**Decision 19: Polish-pass commits stand alone; doc updates land in their own commit.**
Three feature commits this session — `f78b104` (edit + keyboard + search + deployment target), `5d74622` (archive picker grouping), `55974f7` (Calm redesign). Each commit covers one coherent slice of the polish pass; doc updates (this file, the tracker, learned-log, memory) land in a separate commit so the diff is reviewable as documentation, not mixed with feature changes. This is the cleaner default going forward — features and docs in separate commits unless they're tightly coupled.

**Sections of CLAUDE.md updated:** none — the two-tab rule was already in CLAUDE.md; Decision 18 is a refinement, not a new principle. The distribution pivot is decision-level (lives here), not constitution-level.

---

### 2026-04-25 — code review + CloudKit fix

**Session summary:** Chad asked for a code review and honest evaluation of how the v1 build was executing. Read the full Swift surface (~1,300 lines across 20 files) and surfaced two blockers plus a handful of minor cleanups. The two blockers were both about CloudKit, both silent, and both would have shipped to TestFlight without anyone noticing until users with multiple Apple devices reported missing sync. Fixed all three of the immediately-actionable items in one pass.

**Decision 14: ModelConfiguration must explicitly opt into CloudKit; entitlement alone is not enough.**
The CloudKit entitlement was on, the iCloud capability was checked, but `gardenApp.swift` built its `ModelContainer` with `ModelConfiguration(schema:isStoredInMemoryOnly:)` — a constructor that defaults `cloudKitDatabase` to `.none`. Result: SwiftData was a pure local store. The constitution's example used the simpler `.modelContainer(for: [...], cloudKitDatabase: .automatic)` scene-modifier form, which makes the parameter unmissable; the hand-rolled container path doesn't. Fix: pass `cloudKitDatabase: .automatic` to `ModelConfiguration`. Lesson: when a CloudKit-mirrored SwiftData schema is required, the configuration parameter is load-bearing — verify it on every container init, not just at the entitlement layer.

**Decision 15: The CloudKit container ID belongs in the entitlement file, explicitly.**
`garden.entitlements` had `com.apple.developer.icloud-services` set to `CloudKit` but `com.apple.developer.icloud-container-identifiers` as an empty array. Without a container ID listed, the entitlement is effectively decorative. Fix: added `iCloud.com.drivercyber.garden` to the identifiers array. Together with Decision 14, this is what actually wires SwiftData → CloudKit at runtime. Both are five-line fixes that would have been invisible on the simulator and only surfaced when a TestFlight tester signed into a second device.

**Decision 16: Delete the Xcode template's `Item.swift`.**
The default project template generates an `@Model class Item { var timestamp: Date }`. It was never added to the Schema and never referenced by any view, but it sat in the source tree as dead code. Removed. Xcode 16 synchronized folders auto-update the project on next open.

**Other findings noted but deferred** (not blocking TestFlight, captured for a future cleanup pass):
- The string `"garden.tbd.categoryID"` and `"garden.seeded"` appear in three files; one typo away from a silently broken seed. Should become a `DefaultsKeys` enum.
- `NoteRowView` declares `@Bindable var note` but never uses two-way binding; plain `let note: Note` would suffice.
- `seedIfNeeded()` runs in `.task` on `ContentView`, so on first launch the composer/chips render briefly before the seed completes. Today it's invisibly fast; could become visible as a one-frame flash on slow cold starts.

**Sections of CLAUDE.md updated:** none — the constitution's storage section already specified CloudKit-via-`.automatic`. This was implementation drift from the spec, caught and corrected.

**One impact on the deployment plan:** the CloudKit Dashboard "Deploy Schema Changes" step now requires that the app be run *at least once* with the corrected configuration, so SwiftData registers the development schema with CloudKit. Before the fix, the dev schema would have been empty and the production deploy would have had nothing to push.

---

### 2026-04-25 (later) — pre-deployment polish

**Session summary:** Picked up after compact and executed three pre-approved polish items in one pass: a Settings sheet exposing the "Export everything" path required by the constitution's Layer 3 storage philosophy, dark + tinted (iOS 18 luminance) app icon variants generated programmatically, and a complete `app-store-listing.md` with every field App Store Connect will ask for. No new architectural moves; this round was about making the v1 build deployment-ready.

**Decision 11: Settings is a sheet on Notes, not a third tab.**
The constitution explicitly locks the app at two tabs (Notes + Calm). Adding a Settings tab would have violated that rule. Decision: present `SettingsView` from a gear toolbar item on the top-leading edge of `NotesView`, with the existing share button moved to top-trailing. Settings contains three cards — About (app name, tagline, version from Info.plist), Storage ("Export everything" with an archived-notes toggle, Copy, ShareLink), and a small storage-philosophy note explaining the three-layer model in user terms. Rationale: the Calm screen stays untouched (single-purpose), the tab bar stays at two, and the Layer 3 export is now permanently one tap away from anywhere in the app.

**Decision 12: Icon variants are generated programmatically with the same sprig.**
Rather than hand-design three icons, extended the existing Pillow generator (`/tmp/generate_garden_icons.py`) to render the same sage-wheat-sprig silhouette in three palettes: light (cream bg, sage-deep stem), dark (ink-dark bg, cream stem), and tinted (black bg, white stem — iOS 18 tints by luminance). All three saved into `AppIcon.appiconset` with `Contents.json` declaring the appearances. The hand-designed replacement remains a v2 backlog item. Trade-off: programmatic icons are visibly less polished than a designer's icon, but consistent across all three modes and trivially regenerable; for v1 distribution to wife/friends this is right.

**Decision 13: App Store listing copy lives in-repo as a markdown doc.**
Drafted `garden-app/garden/app-store-listing.md` with every field App Store Connect requires: app name, subtitle, promotional text, full description (~2.1k chars), keywords, support URL guidance, privacy policy draft text (ready to host), nutrition-label answer, age rating, category, copyright, "What to Test" notes, a tester invite email, post-upload workflow checklist, and a screenshots backlog. The description is faithful to the constitution: it leans into the anti-patterns ("no notifications, no streaks") rather than softening them. Rationale: keep the source of truth in the repo so it versions with the app; treat ASC as a paste target rather than a place to compose copy. Privacy Policy hosting + screenshots remain backlog items but are isolated from the code.

**Sections of CLAUDE.md updated:** none — the constitution's Settings/Export and Anti-Patterns sections already specified all three of these; this round was implementation against existing spec.

---

### 2026-04-25 — v1 implementation session

**Session summary:** Took Garden from "founding docs only" to "v1 feature-complete, pre-deployment" in one sitting. Built the entire two-tab app on top of the constitution's spec: Instrument Serif fonts, 13 design tokens, SwiftData models with CloudKit, NotesView (composer + chips + list + archive section + export sheet), CalmView (wheat field + One Thing card + confetti + haptics), category management (add/rename/reorder/delete with reassignment to Ideas / TBD), and pre-deployment hardening (app icon, privacy manifest, version numbers). Ended the session at the gate before Apple Developer Program enrollment.

**Decision 7: GardenColors.swift is unnecessary in modern Xcode.**
The constitution's setup checklist called for `Design/GardenColors.swift` defining `extension Color` static vars. In Xcode 15+, the compiler auto-generates these symbols from the asset catalog at build time, so writing them manually causes "Invalid redeclaration" errors. Decision: remove `GardenColors.swift` from the checklist; rely on Xcode's auto-generation. The `Design/` folder remains as a future home for typography helpers if needed. Constitution updated in §Xcode Project Setup Checklist.

**Decision 8: App icon is a sage wheat sprig on cream, generated programmatically.**
Rather than hand-design an icon in Figma/Sketch, generated a 1024×1024 PNG via Python+Pillow: cream background (`#F2EDE3`) with a stylized wheat sprig rendered in `sageDeep` (`#35523A`) — vertical stem with six pairs of grain leaves fanning upward, plus a single apex grain. Reads as both a wheat sprig (the app's namesake imagery) and a quiet nature mark (slim conifer-adjacent). Acceptable v1 placeholder; a hand-designed replacement is a backlog item. Single universal slot only — dark and tinted variants deferred (Apple falls back gracefully).

**Decision 9: Privacy Manifest declares minimum-viable disclosures.**
`PrivacyInfo.xcprivacy` declares: `NSPrivacyTracking = false`, no tracking domains, no collected data types, and `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1` (access info from same app). Garden's "we don't collect anything; CloudKit is user's own iCloud, not us" stance makes the manifest near-empty. This satisfies the May 2024 Apple requirement without committing the project to any disclosures we'd later have to walk back.

**Decision 10: TestFlight Internal Testing is the chosen distribution path.**
Discussed the full distribution landscape (Path A direct-Xcode-install, TestFlight Internal, TestFlight External with Beta App Review, Unlisted App Distribution requiring full review, Ad Hoc UDID provisioning). Chose: do Path A first this week to validate on real hardware, then proceed to TestFlight Internal once Apple Developer Program is active. Wife will be added as Internal Tester via App Store Connect — no review required, builds last 90 days. Public unlisted listing remains a possible future step but isn't load-bearing for "send a link to my wife and friends."

**Sections of CLAUDE.md updated:** §Xcode Project Setup Checklist (removed the `GardenColors.swift` line item).

---

### 2026-04-24 — Founding session

**Session summary:** Refined an existing draft of `garden-app-constitution.md` through five targeted questions. The draft was structurally solid (design system, data model, view hierarchy, Xcode setup) but missing several load-bearing concepts: guiding principles for how we work, a storage philosophy rooted in lessons from the project-dashboard persistence failure, a dedicated anti-patterns section, a full spec for the quarterly recap, and clarity on the removed "Copy as prompt" button.

**Decision 1: Storage philosophy is a dedicated top-level section.**
The project-dashboard web app failed because it depended on browser localStorage, which the browser treated as disposable and cleared on PWA refresh. Fix was a Cloudflare KV + GitHub token sync — creative but complex. Garden avoids the root cause entirely: SwiftData on iOS is a real local database (not cache). But the lesson still applies — *never depend on a single storage mechanism*. Decision: three-layer model with each layer protecting a different failure mode (SwiftData local = primary, CloudKit = convenience sync, manual markdown export = insurance), documented as a top-level section so future Claude Code sessions can't accidentally consolidate the layers or add a backend.

**Decision 2: Guiding principles inlined, flagged for extraction.**
Chad's four principles (token-conscious consumption, measure twice cut once, *Ordo ab chao*, focused elegance and uncompromising utility — plus appreciation/humility as a fifth) govern every project, not just Garden. Repeating them in every project constitution is token waste and creates drift risk. Long-term goal: a shared `working-principles.md` referenced by all Driver-cyber project constitutions. Short-term decision: inline them in Garden's constitution now so nothing is lost, with a parking-lot note to extract later.

**Decision 3: Quarterly recap specified in full, scheduled for v2.**
The original "Annual review" parking lot line was underspecified. Session produced a full spec: quarterly cadence on fixed calendar quarters, lives as a quiet card above the composer in the Notes tab (not the Calm screen), visible for 7 days then silently self-dismisses, closes with a gentle backup prompt producing `Garden-YYYY-QN.md`. Form leans toward a word cloud rendered in Instrument Serif — like a page from a commonplace book, not a Wrapped summary. Detects hyper-focus sessions (note clusters in same category within short window) as a surface-able signal. Whether past recaps are browsable or ephemeral is deliberately parked for v2 build time.

**Decision 4: Anti-Patterns are a dedicated load-bearing section.**
The North Star principle ("does this help Chad be more present, or give him another reason to stay in the app?") is correct but abstract. Abstract principles erode under feature pressure. Decision: name specific anti-patterns the constitution permanently refuses — no notifications, no streaks, no badges/red dots, no "come back" prompts, no social features, no gamification language. These are categorically separate from "Out of Scope (v1)," which contains deferrals. Anti-patterns are refusals.

**Decision 4a (softening): Metrics are not forbidden, but must serve reflection.**
Chad's feedback: total metric prohibition is too strict. Seeing "you wrote a lot this quarter" as honest data is different from gamification. The line: does the metric point *outward* at the content (reflection) or *back* at the behavior (engagement)? Counts can appear in recaps as context; they cannot be targets, streaks, or goals. "If a metric would look at home in Wrapped, it does not belong in Garden."

**Decision 5: "Copy as prompt" button removed from export flow.**
Vestigial feature from when Garden was a Claude Code feeder inside the project-dashboard. Garden as a standalone presence-and-clarity app holds notes of every kind — grocery lists, observations, dreams, ideas. A "please implement these" button is wrong for most of them. Markdown export remains flexible; users can paste into a Claude Code prompt when appropriate. North Star updated from "exportable to Claude Code" to "exportable as markdown."

**Decision 6 (implicit, surfaced mid-session): Calm screen is single-purpose.**
When considering where to place the quarterly recap, Chad rejected the Calm screen immediately — the Calm screen's purpose is wheat field + One Thing only. No secondary content, ever. Elevated to an explicit rule in the View Hierarchy section and added to Key Decisions.

---

## 💭 Open Questions

Parked deliberately. Not to be resolved until their time.

- **Quarterly recap form details** — word cloud is the current lean, but the exact visual design, the hyper-focus detection threshold, and whether prose intro precedes the cloud are all TBD. Decide when building v2.
- **Past recap browsability** — ephemeral (each season makes room for the next) vs. seasonal journal (browsable archive). Both have merit. Decide at v2 build time.
- **Category reordering UX** — the `sortOrder` field exists on the Category model but the UI for reordering isn't specified. Will emerge in v1 build.
- **First-launch experience** — onboarding flow (if any), initial category state beyond "Ideas / TBD", welcoming copy. Will emerge in v1 build.

---

## 💡 Parking Lot (Future Ideas)

These mirror the Future Ideas section in `CLAUDE.md`. Reproduced here because parking-lot items often move between journal and constitution; this file is where new ideas land before being promoted.

- **Quarterly Recap (v2)** — full spec lives in `CLAUDE.md`
- **"One Thing" widget** — home screen widget with tap-to-check
- **Project Dashboard integration** — web dashboard card pulling from user-published export
- **Shortcut / Siri integration** — "Hey Siri, add to Garden"
- **Calm screen variations** — seasonal alternates (rain, snow, night sky)
- **Shared `working-principles.md`** — cross-project constitution reference (not Garden-specific)

---

## 🔄 Maintenance Protocol

Each Claude Code session that meaningfully changes priorities, pivots direction, or completes a phase should append a dated entry to the Decision Log above. Format:

```
### YYYY-MM-DD — [short description of the session or pivot]

**Session summary:** [one paragraph on what happened]

**Decision N: [short title]**
[rationale and specifics]
```

When `CLAUDE.md` changes as a result of a decision, note which section was updated. When a parking-lot item is promoted to v1 scope, remove it from the parking lot and mention the promotion in the day's entry.

**Compact the log if it grows unwieldy.** Entries more than six months old can be summarized into a single "Pre-[date]" block if their specifics are no longer relevant. The goal is readability at session start, not archival completeness — archival lives in git history.
