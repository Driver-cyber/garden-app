# DECISIONS.md — Garden App Living Decision Log

> **For Claude Code:** This file is the journal. `CLAUDE.md` is the constitution — stable, principles, architecture. This file is volatile — current phase, decisions made, open questions, pivots. Read `CLAUDE.md` first for *how we work*; read this file for *where we are*.

---

## 🎯 Current Phase

**Phase:** Founding docs complete. Pre-implementation.

**What's next:** Initialize the `Driver-cyber/garden-app` repo, drop `CLAUDE.md` and this file into it, install Xcode, and begin the project setup checklist in the constitution.

**Vibe:** Measure twice, cut once. This is a native iOS app being built from a working web reference — the concept is proven, the design is locked, the data model is specified. The work ahead is translation, not invention. Prefer careful faithful implementation over clever departures from the reference.

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
