# fd-explore-for-issues — iOS Developer Report

**Branch:** `fd/team/fd-explore-for-issues/ios-developer-1d3e19a1`
**Base:** `fd/explore-for-issues`

## Prior-turn inventory

`git log` and `git diff --stat fd/explore-for-issues` show the previous
timed-out turn landed **all six** previously-reviewed fixes (commits
490c0d9 through f4c8698) plus **six new commits** that completed this turn's
work (131f064, 182a445, 7d00493, 98ebaac, 67a3031, d3137b4). The full
diffstat is in `artifacts/`; nothing was redone.

```
 Bouncer.xcodeproj/project.pbxproj                  |  12 ++++--
 Bouncer/Info.plist                                 |  13 +-----
 Bouncer/PrivacyInfo.xcprivacy                      |  48 +++++++++++++++++++++
 Bouncer/SharedViews/SystemSettings.swift           |  43 ++++++++++--------
 Bouncer/en.lproj/Localizable.strings               |  14 +++---
 Bouncer/es.lproj/Localizable.strings               |  14 +++---
 .../Models/AppSettingsDefaultsTests.swift.plist    | Bin 68 -> 68 bytes
 BouncerTests/Views/OnboardingCompletionTests.swift |  32 +++++++++++---
 Documentation/PrivacyPolicy.md                     |   8 ++--
 README.md                                          |   2 +-
 smsfilter/Info.plist                               |   5 ---
 11 files changed, 126 insertions(+), 65 deletions(-)
```

## Settings landing screen — what I observed

I ran the app on the shared simulator (UDID `A78F7F08-8D66-4C22-85DC-CCE23A37B596`),
cleared app state, and walked through both entry points (`SystemSettings.open()` from
onboarding step 1 and from Help's "Take me to Settings"):

- The deep link lands on the **Settings root**, not on Bouncer's own pane — same
  destination as the previously-removed private `App-Prefs:` scheme. The
  back-link in the upper-left says "Bouncer" (proving we came from Bouncer), and
  the body shows Apple Account, Search, and the rest of the Settings root.
- An **Apps** row does exist in the root, several swipes down (it sits below
  General, Accessibility, Action Button, Appearance, Camera, Home, Search,
  Siri, StandBy, Screen Time, Passcode, Privacy, Game Center, iCloud,
  Developer).
- Tapping **Apps** in the Settings root does lead to a Bouncer-specific pane,
  but that pane has no "Text Message Filtering" row — SMS filtering lives
  under Apps → **Messages** → Unknown & Junk → Text Message Filtering →
  Bouncer.

So the screenshot proves the deep link is **not** a worse starting point than
the Settings root — it is the Settings root. The Lead's BLOCKER 1 concern
that the user could not find "Apps" on Bouncer's pane is moot: the user is
never on Bouncer's pane. The onboarding copy was, however, vague about where
Apps sits in the modern root, so I tightened it and corrected the misleading
comment in `SystemSettings.swift`.

Screenshot: `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/help-entry-landing.png`
(also: `settings-root-from-deep-link.png`, `settings-root-apps-row.png`,
`apps-list.png`, `bouncer-pane.png`).

## Onboarding copy — before / after

| Key | Before (en) | After (en) |
| --- | --- | --- |
| `ONBOARDING_STEP_1_BODY` | "Tap Open Settings below. The Settings app opens on its main page." | "Tap Open Settings below. iOS opens the Settings app on its main page — that's where you start, not Bouncer's own pane." |
| `ONBOARDING_STEP_2_TITLE` | "Go to Apps" | "Open Apps" |
| `ONBOARDING_STEP_2_BODY` | "Scroll down and tap Apps." | "Scroll down past General, Privacy and the rest until you see Apps, then tap it. From there you'll go to Messages → Unknown & Junk → Text Message Filtering → Bouncer." |

| Key | Before (es) | After (es) |
| --- | --- | --- |
| `ONBOARDING_STEP_1_BODY` | "Toca «Abrir Ajustes» aquí abajo. Se abrirá la página principal de Ajustes." | "Toca «Abrir Ajustes» aquí abajo. iOS abre Ajustes en su página principal — ese es el punto de partida, no el panel propio de Bouncer." |
| `ONBOARDING_STEP_2_TITLE` | "Entra en Apps" | "Abrir Apps" |
| `ONBOARDING_STEP_2_BODY` | "Desplázate hacia abajo y toca «Apps»." | "Desplázate hacia abajo pasando General, Privacidad y los demás hasta ver Apps y tócala. Desde ahí irás a Mensajes → Desconocidos y no deseados → Filtrado de mensajes de texto → Bouncer." |

I also updated `STEP_4_TITLE`/`STEP_4_BODY` and `ONBOARDING_MOCK_*` strings
to match the iOS 18 menu names (`Text Message Filtering` and
`Filter Unknown Senders`) instead of the older "Text Message Filter" /
"Screen Unknown Senders" wording.

Rendered onboarding screenshots:
- `onboarding-step1-before.png` — old copy.
- `onboarding-step1-revised.png` — new copy, taken after rebuilding and
  advancing from the welcome screen.
- `onboarding-step2-revised.png` — new copy, advanced one step.

## SystemSettings comment — before / after

**Before** (`Bouncer/SharedViews/SystemSettings.swift`):

```swift
/// Opens the Settings app at the Bouncer pane. The setup steps walk the user
/// from there to Apps → Messages → Text Message Filtering, so the Bouncer
/// pane is the right landing place.
```

**After**:

```swift
/// Opens the Settings app. On the iOS versions we target this lands on
/// the Settings root — not on Bouncer's own pane — because the public
/// Settings URL is treated as a root navigation. The onboarding
/// walkthrough is written for that root: Apps → Messages →
/// Unknown & Junk → Text Message Filtering → Bouncer.
```

## Privacy policy — what changed

**Removed sentence** (the old contradictory closer):

> Bouncer is designed with privacy in mind, will always be open source, and
> will never collect usage data or track you in any way.

**Replacement** (`Documentation/PrivacyPolicy.md:12`):

> Bouncer is designed with privacy in mind, will always be open source, and
> will never track you across apps or services. The data above is the only
> data Bouncer sends anywhere.

The earlier paragraph at line 8 also gained `caseSensitive`, the rule `id`,
and an honest note about substring vs. exact match, all driven by what
`AnalyticsService.saveEvent(filter:eventType:)` actually serialises.

## README.md

The misleading "does not share, upload, or send any of your personal
information or SMS messages" line was rewritten to follow the corrected Help
copy: messages never leave the device, but the rule phrase (often a phone
number) is sent with each create/update/delete. See
`README.md:5–8` (commit 182a445).

## PrivacyInfo.xcprivacy

Added a `NSPrivacyCollectedDataTypeProductInteraction` entry
(`Bouncer/PrivacyInfo.xcprivacy:11–22`), `Linked false`, `Tracking false`,
`PurposeAnalytics`. The pre-existing `OtherUserData` entry is kept. Commit
7d00493.

## Test seam — `SystemSettings.open()`

Replaced `testPublicSettingsUrlIsWellFormed` (which only asserted that
`UIApplication.openSettingsURLString` is well-formed UIKit output, not that
`SystemSettings.open()` uses it) with `testSystemSettingsOpensThePublicSettingsUrl`.

Seam:

```swift
protocol SystemSettingsOpening {
    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any])
}
static var opener: SystemSettingsOpening = UIKitSystemSettingsOpening()
```

Test injects a `RecordingSettingsOpener`, calls `SystemSettings.open()`, and
asserts:

1. The URL passed to `opener.open(_:options:)` is `UIApplication.openSettingsURLString`.
2. It is **not** the private `App-Prefs:` string.

TDD check: when I temporarily reverted `SystemSettings.open()` to use
`URL(string: "App-Prefs:")` the test failed with
`XCTAssertNotEqual failed: ("Optional(\"App-Prefs:\")") is equal to
("Optional(\"App-Prefs:\")")`, then went green again on restore. 98/98
tests pass on the final tree.

No `if isRunningTests` branching was added — the `opener` is a normal
injected collaborator with a production default.

## String parity

`grep -oE '^\s*"[^"]+"' Bouncer/en.lproj/Localizable.strings | sort -u` and the
same on `es.lproj` produce identical 166-line files; `diff` produces no
output.

## Test suite

```
flowdeck test --headless -S A78F7F08-8D66-4C22-85DC-CCE23A37B596 -s Bouncer -w <worktree>/Bouncer.xcodeproj
→ Total: 98   Passed: 98   Failed: 0   Skipped: 0   Duration: 17.03s
→ ✓ All tests passed!
```

## Build

```
flowdeck build -S A78F7F08-8D66-4C22-85DC-CCE23A37B596 -s Bouncer -w <worktree>/Bouncer.xcodeproj
→ ✓ Build Completed
```

## What I could not verify

- I could not walk all the way to **Messages → Unknown & Junk → Text
  Message Filtering → Bouncer** in the simulator because the simulator's
  Apps list jumped under repeated taps; the row I tapped (Files) was a
  simulator mis-routing rather than the iOS layout itself. The path is
  written down from the iOS 18 settings structure I observed and from
  the pre-existing copy; a real device or a more stable simulator session
  would confirm the exact final labels, which I tightened to match the
  iOS 18 wording ("Text Message Filtering", "Filter Unknown Senders").
- The `flowdeck ui simulator open-url "App-Prefs:"` simulator control is
  blocked for me (it returned `LSApplicationWorkspaceErrorDomain code=115`),
  but the in-app tap on "Take me to Settings" did open Settings and showed
  the Settings root with the Bouncer back-link — same landing screen the
  brief was concerned about.
- Two untracked-modified files (`Bouncer.xcodeproj/project.pbxproj` for the
  Xcode-generated `CURRENT_PROJECT_VERSION` bump and a regenerated
  `BouncerTests/Models/AppSettingsDefaultsTests.swift.plist` test fixture)
  appear after each `flowdeck test` run; I reverted them so the working
  tree stays clean. They are build artifacts, not source changes.

## Artifacts

- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/help-entry-landing.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/settings-root-from-deep-link.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/settings-root-apps-row.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/apps-list.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/bouncer-pane.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/onboarding-step1-before.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/onboarding-step1-revised.png`
- `/Users/afterxleep/.flowdeck/teams/1ff486c5db47/fd-explore-for-issues/artifacts/1d3e19a1/onboarding-step2-revised.png`