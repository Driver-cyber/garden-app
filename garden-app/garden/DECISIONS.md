# DECISIONS.md — Garden App Living Decision Log

> **For Claude Code:** This file is the journal. `CLAUDE.md` is the constitution — stable, principles, architecture. This file is volatile — current phase, decisions made, open questions, pivots. Read `CLAUDE.md` first for *how we work*; read this file for *where we are*.

---

## 🎯 Current Phase

**Phase:** v1 feature-complete. Pre-deployment.

**What's next:** Test on a real device first (Path A — Xcode direct install, free, 7-day expiry), then enroll in Apple Developer Program, deploy CloudKit schema to production, archive and upload to TestFlight, add Chad's wife as Internal Tester. From there the app is on her phone with a real link.

**Vibe:** The translation phase is done. The web reference shipped to native faithfully — wheat field, One Thing card, two-tab structure, three-layer storage all working in the simulator. Next phase is deployment hygiene: hardware verification, Apple paperwork, and the small polish work the App Store demands (icon variants, listing copy, screenshots).

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
