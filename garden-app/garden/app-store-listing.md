# Garden — App Store Connect Listing Copy

> Drafted 2026-04-25 for the v1 submission. Paste each section into the matching field in App Store Connect (My Apps → Garden → App Information / Pricing & Availability / iOS App → Version → "App Information"). Field character limits are noted in parentheses; counts shown are conservative.

---

## App Name (30 char max)

```
Garden
```
*6 / 30. Could later become "Garden — Notes & Calm" (22 / 30) if "Garden" is taken; check availability at submission time.*

---

## Subtitle (30 char max)

```
A quiet place for your notes
```
*28 / 30.*

**Alternates:**
- `Notes, one daily check, calm` (28)
- `Quick notes. One small thing.` (29)
- `Notes, presence, a wheat field` (30)

---

## Promotional Text (170 char max — editable anytime without a new build)

```
Garden is a personal place for notes, one daily checkbox, and a wheat field you can watch when the day gets loud. No streaks, no notifications, no telemetry.
```
*157 / 170.*

---

## Description (4000 char max)

```
Garden is a quiet iPhone app for presence and clarity.

It does three things, and only three things:

— Quick-capture notes, organized by the categories you create. A grocery list, a half-formed thought, a thing your kid said, an idea for a side project. Pick a category, type, hit add.

— A single daily checkbox: "I did the one thing today." When you check it, you get a small burst of confetti, a soft haptic, and permission to put your phone down.

— A wheat field on the Calm tab. Eighty blades, gently swaying. Watch it for ten seconds and remember why any of this matters.

That is the whole app.

What Garden won't do
• No notifications. Garden never asks for your attention.
• No streaks. No "you're on a 7-day roll." Streaks are anxiety machines dressed as motivation.
• No badges, red dots, or "come back" prompts.
• No social features. Garden is yours. Nothing leaves your phone unless you choose to share it.
• No accounts, no tracking, no telemetry. Sign in to iCloud and that's it.

Where your notes live
• On your iPhone, in a real local database — works offline, persists through restarts.
• In your iCloud, synced automatically across your signed-in Apple devices.
• Available as a markdown file you can export anytime, to anywhere — Files, iCloud Drive, email, AirDrop. A portable copy you own outright.

Three layers, each protecting against a different way you might lose them. None of them ours.

Designed for fewer minutes, not more
Garden is built on the belief that the best phone app is the one you can put down. The aesthetic is calm: cream paper, sage ink, an Instrument Serif word here and there. Spring animations that feel hand-tuned. Haptics on the moments that matter. No dopamine loops.

If you check the one thing and close the app, Garden has done its job.

Privacy
Garden does not collect, transmit, or sell any data. Your notes sync only through your own iCloud account. Garden has no servers, no analytics, and no third-party SDKs. The privacy nutrition label says "Data Not Collected" because nothing is collected. Read more in the Settings tab and at the privacy URL below.

For who
Garden is a personal tool. It was built for one person and is shared with friends. It is not a productivity app, a journaling app, or a habit tracker. It is closer to a notebook with a window in it.

Made with care, on iPhone, with SwiftUI and SwiftData.
```
*~2,150 / 4,000.*

---

## Keywords (100 char comma-separated, no spaces between commas)

```
notes,minimal,calm,journal,quick,capture,notebook,markdown,offline,private,icloud,daily,focus,quiet
```
*99 / 100. Apple deduplicates against the app name + subtitle, so "garden" is intentionally absent.*

---

## Support URL (required)

Recommended placeholder until a real page exists:
```
https://github.com/Driver-cyber/garden-app
```

If GitHub repo is private, alternatives:
- A simple GitHub Pages site (static HTML, takes 10 minutes)
- An iCloud-published note (Apple accepts iCloud share links)
- A mailto link is **not** accepted; Apple requires a web URL

---

## Marketing URL (optional, leave blank for v1)

```
(leave empty)
```

---

## Privacy Policy URL (required for App Store, optional for TestFlight Internal)

Garden has nothing to disclose, but Apple still requires a hosted page. Minimum-viable text:

> **Garden Privacy Policy**
>
> Garden does not collect, transmit, or sell any user data.
>
> All notes you create in Garden are stored locally on your device using Apple's SwiftData framework, and optionally synced through your personal iCloud account using Apple's CloudKit service. Apple's iCloud privacy policy applies to that sync; we have no access to it.
>
> Garden contains no third-party analytics, advertising, tracking, or SDKs. We have no servers and receive no data from your use of the app.
>
> If you have questions, contact: cstewch@gmail.com.
>
> Last updated: 2026-04-25.

Host this as a single static page (GitHub Pages, iCloud-published note, Notion public page, etc.) and use that URL in the Privacy Policy field.

---

## Privacy Nutrition Label (App Store Connect → App Privacy)

When asked "Do you or your third-party partners collect data from this app?":

```
No, we do not collect data from this app.
```

That's the entire answer. Garden's `PrivacyInfo.xcprivacy` already declares `NSPrivacyTracking = false`, no tracking domains, and no collected data types — the nutrition label form should match.

---

## Age Rating

```
4+
```
No objectionable content of any kind.

---

## Category

```
Primary:    Productivity
Secondary:  Lifestyle
```
*Productivity is the closest fit despite Garden being explicitly anti-productivity. Lifestyle covers the Calm tab.*

---

## Copyright

```
© 2026 Chad Stewart
```

---

## TestFlight — "What to Test" Notes

Paste into App Store Connect → TestFlight → Test Information → "What to Test" before adding testers.

```
Thanks for testing Garden!

This is v1 — quick-capture notes plus a daily checkbox and a wheat field. Try it for a few days and notice if the app earns its place on your home screen.

Things to try
• Add a few notes in different categories. Make a new category if "Ideas / TBD" doesn't fit.
• Open the Calm tab and watch the wheat field for a few seconds.
• Check the "I did the one thing today" box. (Confetti + haptic.)
• Tap the share icon (top-right of Notes) → preview your notes as markdown → Copy or Share.
• Tap the gear icon (top-left of Notes) → "Export everything" — full backup.
• If you have multiple Apple devices signed into the same iCloud, check that notes sync.

What I'd love feedback on
• Does it feel calm? (It should.)
• Anything confusing?
• Any animation that feels off?
• Anything you wish it did — keeping in mind Garden is intentionally narrow?

What it won't ever do
No notifications, no streaks, no accounts. If you find yourself wanting those, that's information; let me know, and I'll explain why they're not coming.

— Chad
```

---

## TestFlight — Tester Email Body (App Store Connect auto-generates the invite, but you can customize)

```
Hi —

I made an iPhone app called Garden. It's a quiet place for notes, a daily one-thing checkbox, and a wheat field you can watch when things get loud.

You're invited to test it via Apple's TestFlight (free, no review process for friends like you). To install:

1. Install "TestFlight" from the App Store if you don't have it.
2. Open the email from Apple titled "TestFlight Invitation: Garden" and tap "View in TestFlight."
3. Tap "Install."

That's it. The build expires in 90 days; I'll send a new one before then.

Thanks for trying it.
— Chad
```

---

## App Store Connect Workflow Checklist (post-upload)

1. **Build appears in TestFlight tab** (~5–30 min after upload finishes)
2. **Export Compliance** prompt — answer: "Does your app use encryption? Yes (HTTPS only)" → "Does it qualify for the exemption? Yes" (CloudKit uses standard HTTPS; this is the standard answer for apps with no custom crypto)
3. **Add Internal Testers** — TestFlight tab → Internal Testing group → add wife + friends by Apple ID email
4. **Paste "What to Test" notes** above
5. **Submit for App Review** *(only when ready for public listing — not needed for Internal Testing)*
   - Demo account: not needed (no auth)
   - Notes for reviewer: "No login required. The app is a personal notebook with local + iCloud storage. No backend, no analytics."
   - Screenshots: 6.7" required (iPhone 15 Pro Max sim) + 6.1" recommended

---

## Screenshots Backlog (not required for TestFlight Internal — needed before public listing)

Apple requires:
- **6.7" iPhone display** — 1290×2796 portrait (iPhone 15 Pro Max / 16 Pro Max). Minimum 3 screenshots, max 10.
- **6.1" iPhone display** — 1179×2556 portrait (iPhone 15 / 16). Optional but recommended.

Suggested set (5 screenshots):
1. Notes tab with several notes across two or three categories — calm-state hero shot
2. Composer with a half-typed note and the category picker open
3. Calm tab showing the wheat field + One Thing card *unchecked*
4. Calm tab with the One Thing *checked* and confetti mid-burst (capture during animation)
5. Settings sheet showing "Export everything" with the markdown share sheet open

Captions can be added to each (small overlaid text in Apple's screenshot studio or ahead of upload). Optional — Apple accepts plain device screenshots.

---

*That's everything App Store Connect will ask for at submission. The TestFlight Internal path needs only the "What to Test" notes and the build itself; the rest applies when promoting to a public listing.*
