# Bouncer — Production-Readiness Audit

A read-only audit of the `Bouncer` app target, the `smsfilter` extension it depends on,
`Bouncer.xcodeproj`, `Info.plist` and the entitlements. No file was modified.

Scope: 5,274 lines of Swift across 54 files, of which 47 are in a build target. The seven
files that are not in any target are called out in §8.

Findings are ordered most severe first. Severity means:

- **blocker** — ships broken, loses user data, or is rejected by App Store review.
- **should-fix** — produces wrong behaviour or silent failure a user will hit.
- **nice-to-have** — real, but nobody is harmed by it today.

---

## Blockers

### 1. The app tells the user nothing is ever sent to a server, then sends every rule to one — blocker

- `Bouncer/en.lproj/Localizable.strings:186` — `"HELP_PRIVACY" = "Your messages are filtered on your iPhone and are never sent to a server. Not to Bouncer, not to anyone."` — shown on the Help screen (`Bouncer/Views/Help/HelpView.swift:170`).
- `Documentation/PrivacyPolicy.md:9` — "will never collect usage data or track you in any way."
- `Bouncer/Middlewares/FilterMiddleware.swift:57`, `:104`, `:139` — every rule create, update and delete calls `analyticsService.saveEvent(filter:eventType:)`.
- `Bouncer/Models/AnalyticsService/AnalyticsService.swift:117-141` — `FilterAnalyticsEvent(filter: filter, …)` encodes the **whole `Filter`**, `phrase` included, plus the user's locale and a timestamp, and `POST`s it to `https://yqrxbdnqfdthiuegufvd.supabase.co`.

Failure scenario: a user adds a rule of type `.sender` with the phrase `+34600123456` to block a
number that is harassing them. That phone number, plus their locale, leaves the device and is
written to a third-party database — while the Help screen one tap away states in plain language
that this never happens. The same payload goes out again on edit and again on delete.

This is three separate problems at once: a false statement in shipping UI, a privacy policy the
binary contradicts, and an App Store privacy declaration that cannot be accurate (Guideline
5.1.1(i) / App Privacy misrepresentation). A rule phrase is the single most sensitive thing this
app holds — it is, by construction, what the user does not want other people to see.

The decision here is the user's, not mine, but the two states have to agree: either the upload
goes, or the copy and the policy and the App Store declaration change, and the user is asked to
opt in.

**Same data, second channel:** `FilterMiddleware.swift:56`, `:103`, `:138` also `print()` the raw
phrase (`print("Analytics: Saving filter creation event - \(filter.phrase)")`). `print` is not
stripped in Release; it goes to stderr and is visible in Console.app to anything attached to the
device. `FilterStoreFileMigrator.swift:50` — `print(updatedFilter)` — dumps every migrated rule
the same way. There are 24 `print` calls in the shipping app target.

### 2. A live Supabase URL and key are committed to a public repository — blocker

`Bouncer/Config/Config.swift:6-7` holds a real project URL and a real JWT (`role: anon`,
`exp: 2058930943` — 2035). The file is listed in `.gitignore`, but it was committed before that
rule existed and is still tracked (`git ls-files --error-unmatch Bouncer/Config/Config.swift`
succeeds; last touched in `97e1b2f v.2.8.0 bump`), so `.gitignore` hides future edits while the
key stays in `HEAD` and in history.

Failure scenario: anyone who clones the public repo can write to `filter_analytics` at that
project for the next ten years. A Supabase anon key is designed to be publishable *when* row-level
security is configured; I cannot see the RLS policy from here, so I cannot tell you whether the
table is writable by the world. If it is, the analytics data is untrustworthy and the project is
billable by strangers.

Rotate the key, then decide whether the table needs a policy — and if `Config.swift` is meant to
be private, `git rm --cached` it, because the `.gitignore` entry is currently doing nothing.

### 3. A store file the app itself can corrupt hangs both the app and the extension, permanently — blocker

- `Bouncer/Models/FilterStore/FilterStoreFile.swift:44-45` — `try JSONEncoder().encode(filters).write(to: url)`. **No `.atomic`.** Every add, update, delete and import rewrites the whole file this way.
- `Bouncer/Models/FilterStore/FilterStoreFile.swift:54-77` — on a failed decode, `decodeData` calls `migrateDatabase()` and subscribes with `.sink(receiveCompletion: { _ in }, receiveValue: …)`. The outer `promise` is only ever called from `receiveValue`.
- `Bouncer/Models/FilterStore/FilterStoreFileMigrator.swift:24-29` — if the data is not decodable as `[FilterV1]` either, `migrateV1` calls `promise(.failure(.loadError))`.

Failure scenario: the user adds a rule; the write is interrupted (killed while backgrounding,
disk full, low-storage reclaim) and `filters.json` is left truncated. On next launch the decode of
`[Filter]` fails, the decode of `[FilterV1]` fails, `migrateV1` completes with `.failure`,
`receiveValue` never fires, and so `decodeData`'s promise — and therefore `fetch()`'s promise — is
**never called at all**. The publisher neither emits nor completes.

In the app: `FilterMiddleware.swift:41` never emits, so no `.fetchComplete` is dispatched, so
`state.filters` stays `[]`. The user sees an empty rule list, no error, no spinner, no way back.
Every subsequent launch does the same thing. Their rules are still on disk and still unreadable.

In the extension: `smsfilter/MessageFilterExtension.swift:59` runs the same code, so `completion`
is never called (see #4). Filtering stops silently.

`RuleActivityStore.write` (`RuleActivityStore.swift:170`) gets this right — `options: .atomic` —
so the newer component already knows the rule. `FilterStoreFile` predates it and never got the fix.

### 4. The Message Filter extension has two paths where it never calls `completion` — blocker

- `smsfilter/MessageFilterExtension.swift:29-31` — `guard let sender = queryRequest.sender, let messageBody = queryRequest.messageBody else { return }`. Returns without calling `completion`.
- `smsfilter/MessageFilterExtension.swift:61` — `.sink(receiveCompletion: { _ in }, …)`. If `fetch()` fails (`.loadError` when the app-group container is unavailable) or never resolves (#3), `runFilters` is never reached and `completion` is never called.

Failure scenario: an SMS arrives whose `messageBody` is nil — a message with an attachment and no
text, which is ordinary. `handle` returns, iOS waits for a response that never comes, times out
and kills the extension. The message is delivered unfiltered. This is not a crash the user can
see; it is filtering that stops working for a class of message, forever, with no signal.

`ILMessageFilterQueryHandling` requires the completion handler to be invoked exactly once on
every path, including the ones you decided not to act on. The fix is to complete with an
`ILMessageFilterQueryResponse` whose action is `.none`.

### 5. The V1 migration erases the store before it rebuilds it, one non-atomic write at a time — blocker

`Bouncer/Models/FilterStore/FilterStoreFileMigrator.swift:30-52`:

```
_ = store.reset()                    // writes [] over the user's rules
for filter in filters {              // then adds them back one at a time
    _ = store.add(filter: updatedFilter)   // each one = full read + full non-atomic write
}
```

Failure scenario: a user upgrading from an old version has 60 rules. The migration truncates the
file to `[]`, then performs 60 read-modify-write cycles. Anything that stops the process partway —
being killed while backgrounded, running out of disk — leaves them with however many rules
happened to be written, and no indication that the rest are gone. There is no backup and no
rollback: the only copy of the data was overwritten in step one.

Worse: this runs inside the **Message Filter extension** too. `MessageFilterExtension.swift:13`
constructs its own `FilterStoreFile` and calls `fetch()` on every incoming message, so an upgraded
user whose first post-upgrade event is an incoming SMS runs the migration inside an extension with
a hard time budget, while the app may be doing the same thing in another process, against the same
file, with no coordination.

A migration should build the new state in memory, write it once atomically, and only then consider
the old state replaced.

### 6. Every store failure is silently discarded — the user is never told anything went wrong — blocker

Three layers each drop the error independently:

- `Bouncer/Models/FilterStore/FilterStoreFile.swift:38-41` — `saveToDisk` returns `nil` (its success value) when `fileURL` is nil. A missing app-group container reports **every write as successful**.
- `FilterStoreFile.swift:129`, `:156`, `:193`, `:214` — `add`, `addMany`, `update` and `remove` all subscribe with `.sink(receiveCompletion: { _ in }, …)` and only call `promise` from `receiveValue`. A failed inner `fetch()` means the outer promise is never called.
- `FilterStoreFile.swift:196` — `update` only calls `promise` inside `if let filterIndex = …`. A filter whose id is not found produces no promise call at all.
- `FilterStoreFile.swift:199`, `:218`, `:230` — `if let errorMessage = self?.saveToDisk(…)`. When `self` is nil the optional chain yields `nil`, which this code reads as success.
- `Bouncer/Reducers/FilterReducer.swift:9-31` — handles `.fetchComplete`, `.import`, `.decodeComplete`, `.error`, `.clearError`. `.fetchError`, `.addError`, `.updateError` and `.deleteError` all fall into `default: break`. The middleware carefully constructs those four actions (`FilterMiddleware.swift:46`, `:81`, `:128`, `:164`) and the reducer throws every one of them away.

Failure scenario: a user on a build whose provisioning profile lost the App Group entitlement (a
sideload, an expired profile, a TestFlight build signed with the wrong profile) opens the app, adds
a rule and taps Save. The sheet dismisses. The list is unchanged. No alert, no error, no retry.
They add it again. Same. There is no state in the app that can express "the store is broken",
because the four error actions that would carry it are dropped by the reducer.

`FilterListContainerView.swift:92-94` is the same shape in the UI: `showError(error:)` sets
`shouldDisplayErrorMessage = true`, and that `@State` (`:34`) is never read by anything. A
`fileImporter` failure (`FilterListView.swift:186-187`) therefore produces no visible result at all.

### 7. No privacy manifest — the upload will be rejected — blocker

There is no `PrivacyInfo.xcprivacy` anywhere in the repository (`find . -name '*.xcprivacy'`
returns nothing).

`Bouncer/Models/AppSettings/AppSettingsDefaults.swift:41-47` uses `UserDefaults`, which is a
required-reason API (`NSPrivacyAccessedAPICategoryUserDefaults`). Since 1 May 2024 an upload that
uses a required-reason API without declaring an approved reason in a privacy manifest is rejected
at submission with ITMS-91053 ("Missing API declaration").

Separately, given finding #1, the manifest would also need `NSPrivacyCollectedDataTypes` entries
for the data the analytics call actually sends — or the analytics call needs to go.

### 8. `App-Prefs:` is a private URL scheme — blocker for review

`Bouncer/SharedViews/SystemSettings.swift:18` — `URL(string: "App-Prefs:")`, opened at `:22`.
Called from the onboarding CTA (`OnboardingContainerView.swift:20`) and from Help
(`HelpView.swift:108`).

The code comment is candid that there is no public API for the Settings root, and it does fall
back to `UIApplication.openSettingsURLString` when the open fails. But the call is still made, and
`App-Prefs:` is a documented App Store rejection under Guideline 2.5.1 (non-public API). It is
also not declared in `LSApplicationQueriesSchemes`.

The fallback already works. The honest fix is to drop the private scheme and take the user to the
app's own Settings pane, with the onboarding copy telling them where to go from there.

---

## Should-fix

### 9. A regex rule that does not compile is saved, then silently never matches — should-fix

`Bouncer/Views/FilterDetail/FilterDetailView.swift:260-275` offers a "Use regular expressions"
toggle with no validation of the phrase. `FilterDetailContainerView.swift:87-91` saves on the sole
condition that the phrase is not blank. `Bouncer/Models/SMSFilter/SMSOfflineFilter.swift:124-129`
then catches the `NSRegularExpression` init error and returns `false`.

Failure scenario: a user turns on regex, types `(free|win` (unbalanced paren), and saves. The rule
appears in the list, styled in monospace with slashes around it like a working rule. It matches
nothing, ever. Nothing on any screen says so. Six months later they conclude the app does not work.

The rule editor is the only place this can be caught — validate the pattern on the Save path and
refuse to save an uncompilable one.

### 10. The ReDoS guard rejects ordinary patterns and misses the dangerous ones — should-fix

`Bouncer/Models/SMSFilter/SMSOfflineFilter.swift:61-109`. `isUnsafeRegexPattern` compares the
pattern against a list of literal substrings: `".*.*"`, `"(a+)+"`, `"(a*)*"`, `"(a|a)+"`, …

Failure scenario A (false positive): a user writes `win.*.*prize` — a clumsy but legal pattern.
It contains the literal substring `.*.*`, so it is rejected at `:118`, logged at `:119`, and
`matchRegex` returns `false`. Combined with #9, the rule silently never fires.

Failure scenario B (false negative): a user writes `(win+)+!` — genuinely catastrophic
backtracking, exactly the class the check exists to stop. It is not literally `(a+)+`, so it
passes. It then hits the 100 ms timeout at `:147` on every message.

Literal-substring matching cannot detect nested quantifiers. If the intent is to bound the cost,
the timeout at `:132-150` is the mechanism that actually works — the substring list is doing
nothing but rejecting valid input.

### 11. The regex timeout abandons a thread rather than stopping it — should-fix

`SMSOfflineFilter.swift:132-150`. Work is dispatched to `DispatchQueue.global(qos: .userInitiated)`
and waited on with `group.wait(timeout:)`. On timeout the function returns `false` — but nothing
cancels the dispatched block. `text.range(of:options:.regularExpression)` is not cancellable, so
the worker keeps backtracking on a global-queue thread until it finishes on its own.

Failure scenario: a user saves a pattern that backtracks for minutes (see #10B). Every incoming SMS
starts another one. The Message Filter extension has a small, enforced memory and CPU budget; a
handful of these and it is killed by the system, and messages go unfiltered until it is relaunched.

`NSRegularExpression` with an explicit bounded range, or a length cap on the input, would bound the
work instead of abandoning it.

### 12. The "Health" transaction category silently files messages as "Other" — should-fix

`FilterStore.swift:27` declares `case transactionHealth`, and
`Bouncer/Config/DesignSystem.swift:90` gives it a category. But:

- `SMSOfflineFilter.swift:172-195` — `subAction(for:)` has no `.transactionHealth` case, so it falls to `default` and returns `.transactionalOthers`.
- `smsfilter/MessageFilterExtension.swift:76-79` — `transactionalSubActions` does not include `.transactionalHealth`, so the extension never declares the capability.
- `FilterDetailView.swift:193-194` — the destination picker does not offer it either.

Failure scenario: a rule already stored with `subAction: .transactionHealth` (imported, or written
by an older build) files its matches under Transactions ▸ Other rather than Transactions ▸ Health.
The user cannot see why, and cannot change it because the picker no longer offers the option.

Either wire it up end to end, or take the case out of `FilterDestination` and map existing data
forward. Half-present is the worst of the three.

### 13. `Store.middlewareCancellables` grows for the lifetime of the process — should-fix

`Bouncer/App/AppStore.swift:20`, `:42`. Every `dispatch` subscribes each middleware's returned
publisher and `.store(in: &middlewareCancellables)`. The set is never pruned. Most middlewares
return `Empty()`, which completes immediately — but the `AnyCancellable` object stays in the set.

Failure scenario: adding one rule dispatches `.add`, then `.fetch`, then `.fetchComplete` — three
dispatches × three middlewares = nine entries retained. A long session spent tuning a rule list
accumulates thousands. It is slow growth rather than a spike, which is exactly the kind that never
shows up in a test pass and shows up in a memory report from a heavy user.

The same shape is in `FilterMiddleware.swift:19` (`var cancellables` captured by the returned
closure) and `FilterStoreFile.swift:19` (`var cancellables = [AnyCancellable]()`, appended by
every `add`/`update`/`remove`, never emptied).

### 14. Blocking file IO on the main actor, twice per foreground — should-fix

`Bouncer/Views/FilterList/FilterListView.swift:249` — `refreshActivity()` calls
`RuleActivityStore.shared.load()`, which is `queue.sync { … Data(contentsOf:) … JSONDecoder }`
(`RuleActivityStore.swift:104-120`). It is called from `.task` (`:176`) and from the `scenePhase`
change (`:177-179`), both on the main actor.

Failure scenario: a user with a long history returns to the app on a busy device. The first frame
is blocked on a synchronous read and decode of `activity.json` from the shared container. It is
small today, so this is a hitch rather than a hang — but it is a synchronous disk read on the
main thread in the launch path, and it grows with usage.

### 15. `RunLoop.main` inside the Message Filter extension — should-fix

`smsfilter/MessageFilterExtension.swift:60` — `.receive(on: RunLoop.main)`.

`RunLoop.main` only delivers in the default run loop mode. An app extension's host process makes no
promise about which modes its main run loop is running in, and `RunLoop` scheduling stalls in
tracking modes. If the value is not delivered, `runFilters` is not called and `completion` is never
invoked — the same outcome as #4.

`DispatchQueue.main` has no mode dependency and is what the project's own rules call for.

### 16. `fatalError` on a recoverable condition — should-fix

`Bouncer/Models/ReviewService/RatingServiceDefault.swift:20-21`:

```swift
guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
    else { fatalError("Expected to find a bundle version in the info dictionary") }
```

`requestReview()` is called from `reviewMiddleware` on **every rule add**
(`ReviewMiddleware.swift:14-16`). A missing or non-string `CFBundleVersion` crashes the app at the
moment the user saves a rule. See #18 — the app's `Info.plist` does not use the canonical form for
that key.

Deciding to crash rather than skip a review prompt is not a trade worth making. `return` is the
right answer.

### 17. A read error is treated as "no file", and overwrites the history — should-fix

`Bouncer/Models/RuleActivity/RuleActivityStore.swift:113` —
`guard let data = try? Data(contentsOf: url) else { return .absent }`.

The type's own doc comment (`:95-97`) is explicit that "nothing there yet" and "there is something
there we couldn't understand" have to be told apart, and `:114-118` does exactly that for a decode
failure. But a *read* failure — the file exists and is unreadable — is reported as `.absent`, and
`record(match:)` at `:135` then starts from an empty `RuleActivityLog` and writes it.

Failure scenario: the shared container is briefly unreadable (the device is locked with a
protected-data class, which is precisely when the filter extension runs). The extension reads
`.absent`, builds a fresh log with one entry, and writes it over the user's entire match history.
Every rule's counts and sparklines reset to zero.

Distinguishing `ENOENT` from every other error is a one-line change and the surrounding code
already has the concept.

### 18. `CFBundleVersion` uses a non-canonical variable form — should-fix

`Bouncer/Info.plist:20` — `<string>$CURRENT_PROJECT_VERSION</string>`, without parentheses.
The extension's plist gets it right: `smsfilter/Info.plist:22` is `$(CURRENT_PROJECT_VERSION)`.

If the bare form does not expand, `CFBundleVersion` is the literal string
`"$CURRENT_PROJECT_VERSION"`, which is constant across every release. Then:

- `RatingServiceDefault.swift:32` compares `currentVersion != lastVersionPromptedForReview` — a constant compared against itself. The review prompt is shown once, ever, for the lifetime of the install, and never again on any future version.
- `SystemSettings.swift:38` — `Bundle.displayVersion` renders `2.9.0 ($CURRENT_PROJECT_VERSION)` in the Help footer, which is what a user copies into a support email.

I could not build to read the compiled plist and confirm which way it resolves (see *Not verified*).
Either way the two plists should agree, and `$(…)` is the documented form.

### 19. The extension declares a network filtering service that does not exist — should-fix

`smsfilter/Info.plist:27-28`:

```xml
<key>ILMessageFilterExtensionNetworkURL</key>
<string>https://www.example-sms-filter-application.com/api</string>
```

This is Apple's template placeholder, left in. Declaring it tells iOS (and the reviewer) that the
extension may defer queries to a network service at that address. The code never calls
`deferQueryRequestToNetwork`, so nothing is actually sent — but an app whose entire pitch is
"nothing leaves your device" is shipping a plist key that says the opposite, pointing at a domain
nobody owns. Delete the key.

### 20. `UIRequiredDeviceCapabilities: armv7` on an iOS 26 arm64-only app — should-fix

`Bouncer/Info.plist:44-47` requires `armv7`. `IPHONEOS_DEPLOYMENT_TARGET = 26.0` — every device
that can run this app is arm64, and the binary contains no armv7 slice.

I want to be straight about this one: the app has evidently been submitted with it in place, so it
is clearly not blocking today. But it is a false declaration of what the binary needs, and it is a
long-standing source of "Invalid Bundle" validation failures. Either drop the array or set `arm64`.

### 21. Swift 5 language mode — none of the concurrency in this codebase is checked — should-fix

`SWIFT_VERSION = 5.0` on all four targets, with no `SWIFT_STRICT_CONCURRENCY` setting anywhere in
`project.pbxproj`.

This is the setting that makes several findings above invisible to the compiler:

- `RuleActivityStore: @unchecked Sendable` (`:72`) — the escape hatch is used, and the reasoning is written down honestly in the doc comment, but nothing verifies it.
- `SMSOfflineFilter.matchRegex` (`:133-144`) — `var result` is written on a global queue and read on the waiting thread; on the timeout path the writer outlives the reader's return.
- `filterMiddleware`'s captured `var cancellables` (`FilterMiddleware.swift:19`) is mutated from Combine callbacks.
- `OSLog.subsystem` (`Extensions/OSLog.swift:12`) is a mutable global.

None of these is the most urgent thing on this list, but they are the class of bug that only
appears on a slow device under load, and the compiler will find all of them for free. Turning
`SWIFT_STRICT_CONCURRENCY = complete` on and working through the warnings is the cheapest quality
win available in this project — as a separate change, not bundled with anything.

### 22. Supabase costs five packages and a Keychain library, to POST one row — should-fix

`Bouncer.xcodeproj/project.pbxproj:1153-1158` — `supabase-swift`, `upToNextMajorVersion` from
2.5.1. `Package.resolved` shows what that drags in: `swift-crypto`, `swift-asn1`,
`swift-concurrency-extras`, and `KeychainAccess`.

A privacy-positioned SMS filter now links a third-party keychain library and a crypto stack in
order to send `{filter, eventType, locale, timestamp}` to one table. `URLSession` and
`JSONEncoder` do this in about twenty lines, with no transitive dependencies and no third-party
code touching the Keychain.

The version rule is also `upToNextMajorVersion`, so any 2.x can be resolved. `Package.resolved` is
committed, which holds it in practice — but a CI job that resolves fresh will float.

If finding #1 is resolved by removing the upload, this dependency goes with it.

### 23. A security-scoped resource is leaked when an import fails — should-fix

`FilterStoreFile.swift:238-249`:

```swift
_ = url.startAccessingSecurityScopedResource()
let filters = try JSONDecoder().decode(…)      // throws
url.stopAccessingSecurityScopedResource()      // never reached
```

Failure scenario: the user picks a JSON file that is not a rule list. The decode throws, the
`catch` reports `.decodingError`, and the access is never balanced. Repeat it a few times and the
process holds sandbox extensions it will not release until it exits. `defer` is the fix.

---

## Nice-to-have

### 24. Seven files are in the repository but in no build target

`FilterDummyService.swift`, `FilterListService.swift`, `SMSFilterLocal.swift`,
`SMSFilterLocalService.swift`, `SMSFilterProtocol.swift`, `StoreServiceProtocol.swift`,
`StoreManager/Protocols.swift`.

They are not merely unused — several no longer compile. `FilterDummyService.swift:14` constructs
`Filter(id:type:phrase:exactMatch:)`, an initialiser that does not exist. `SMSFilterLocal.swift:7`
declares a second `final class SMSOfflineFilter`, colliding with the real one, and its
`switch (filter.action)` at `:36` covers three of thirteen cases. `StoreServiceProtocol.swift`
references `StoreManager`, `Product` and `StoreTransactionState`, none of which exist —
`StoreManager/Protocols.swift` is nine lines of comments.

`SMSFiltering.swift` *is* in the app target and declares a protocol nothing conforms to or uses.

Nobody is harmed by this, but it is seven files that read as live architecture and are not. The
next person to look for "how filtering works" will find `SMSFilterLocal.swift` first.

### 25. `break` where `continue` was meant

`Bouncer/App/AppStore.swift:36-38` — `guard let middleware = mw(state, action) else { break }`.
`Middleware` is an optional-returning typealias; a `nil` from any middleware silently skips every
middleware after it in the array, rather than that one. No middleware returns `nil` today, so this
is latent. It is one word.

### 26. `exactMatch` is threaded through four layers and never read

`FilterDetailContainerView.swift:22`, `:38`, `:49`, `:67` → `FilterDetailView.swift:24`. Bound,
passed down, and used by nothing. `Filter` has no `exactMatch` property. It is a leftover of an
older model.

### 27. Shipped resources that are not resources

`Bouncer.xcodeproj/project.pbxproj:676-677` puts two files in the app's Resources build phase:

- `wordlist.filter` — a 289-byte binary plist mock. No code reads it.
- `Config.swift.example` — a Swift source file, shipped inside the `.ipa` as data.

Also tracked in git: `Bouncer/.DS_Store`, `Bouncer/Models/.DS_Store`,
`Bouncer/Assets.xcassets/.DS_Store`, `Documentation/.DS_Store`, and a 62 MB `demo.mov` at the repo
root.

### 28. Target directory case does not match the build setting

`INFOPLIST_FILE = SMSFilter/Info.plist` and `CODE_SIGN_ENTITLEMENTS = SMSFilter/SMSFilter.entitlements`
(pbxproj:813, 808) — the directory on disk is `smsfilter/` and the file is `smsfilter.entitlements`.
macOS is case-insensitive by default so this resolves locally. It will not on a case-sensitive
volume or a Linux checkout.

### 29. Smaller things, listed without ceremony

- `Bouncer/Bouncer.entitlements:5-12` declares `com.apple.developer.icloud-services: CloudDocuments` with **empty** container and ubiquity arrays, and no code uses iCloud. An entitlement the app does not need.
- `CODE_SIGN_IDENTITY = "Apple Development"` is set in the **Release** configuration (pbxproj:1031). Automatic signing normally overrides it for an archive, but a development identity pinned in Release is not what you want in the file.
- `Bouncer/Info.plist:52-58` declares four `~ipad` orientations while `TARGETED_DEVICE_FAMILY = 1` (iPhone only).
- Fixed point sizes on real text, so it does not scale with Dynamic Type: `RuleListComponents.swift:28` (34pt), `:319` (40pt), `HelpView.swift:78` (30pt), and all of `OnboardingIllustrations.swift` (9–13pt with `minimumScaleFactor(0.55)`).
- `FilterListContainerView.swift:55-60` — a hardcoded `DispatchQueue.main.asyncAfter(deadline: .now() + 0.5)` "to allow the File Selection view to dismiss". Timing-based coordination between two sheets; nothing cancels it.
- `ImportFilterListView.swift:27-28` splits new from duplicate using `Filter`'s full `Equatable`, which includes `id`. A list of the same phrases exported from a different install has different ids, so every rule is classified "New" and imported alongside the ones already there. The re-import-your-own-export case is handled correctly and the footer warns about it (`DUPLICATE_FILTERS_FOOTER`), so this is only the cross-install case.
- `FilterStoreFile.swift:31-36` — `fileExists(url:)` shadows its own parameter and ignores it.
- `FilterStoreFile.swift:103-121` — `fetch()` has no `return` after the file-creation branch, so it always falls through to a second read. Correct only because Combine's `Future` honours the first `promise` call and ignores the rest.
- `FilterStoreFile.swift:136-139` — `if !newFilter.useRegex { newFilter.phrase = newFilter.phrase }`. A no-op assignment.
- `AnalyticsService.swift:174-183` — the retry path calls `.sink(…).cancel()` immediately, so the retry's result is never delivered and the promise is never called. On a retried network failure the publisher never completes and its subscription is retained forever in `FilterMiddleware`'s `cancellables`.
- `FilterStoreFile.swift:61` — `// TODO: For future versions, a more robust store might be needed - CoreData?` The only TODO in the app. Findings #3 and #5 are what it is pointing at.

---

## What I looked at and found sound

Areas examined that I have no finding against, so the Lead knows where not to spend effort:

- **Force unwraps and casts.** There are four in the whole app target, and every one is safe: `Bundle.main.bundleIdentifier!` (`AnalyticsService.swift:62`, `OSLog.swift:12`) is non-nil in an app or extension bundle; `Range(match.range, in: pattern)!` (`SMSOfflineFilter.swift:82`) uses a range produced from that same string; `stepNumber!` (`OnboardingPage.swift:44`) is guarded by the `self == .welcome` check on the same line. There is no `try!`, no `as!`, and no unchecked array subscript or string-range arithmetic anywhere. I checked the quantifier parser at `SMSOfflineFilter.swift:86-99` specifically — `numbers[0]` looks like an out-of-bounds waiting to happen, but the pattern `\{\d+,?\d*\}` guarantees a digit immediately after `{`, so the first split element is never empty. The one crash risk in the codebase is the deliberate `fatalError` in #16.
- **The matching engine.** `SMSOfflineFilter.applyFilter/match` (`:22-59`) handles empty and whitespace-only input, trims consistently, and gets allow-before-block precedence right (`:200-213`). It is covered by 832 lines of tests.
- **Localization.** 166 keys in `en.lproj`, 166 in `es.lproj`, zero on either side that the other lacks. Sentences are built from format strings with positional specifiers (`RULE_SENTENCE %1$@ %2$@ %3$@`, `FilterDetailView.swift:152`; `ONBOARDING_STEP_COUNTER %1$d %2$d`, `OnboardingPage.swift:124`) rather than concatenated fragments. This is done properly.
- **Animation.** No `TimelineView(.animation)`, no `repeatForever`, no per-frame timers. Every animation is a finite state transition. `OnboardingIllustrations.swift` is entirely static drawing. The project's rule about continuous animation not driving view invalidation is being followed.
- **Accessibility.** Accessibility identifiers on every interactive element that matters to a flow (`rule.save`, `rule.phrase`, `onboarding.cta.primary`, `import.confirm`, `help.done`, …). Decorative images are `accessibilityHidden`. Selection state is carried as `.isSelected` traits (`RuleListComponents.swift:95`, `FilterDetailView.swift:257`). Tap targets are explicitly sized to clear 44pt with the reasoning written down (`RuleListComponents.swift:79-80`). Dynamic Type is the one gap (#29).
- **Colour and appearance.** Every colour resolves through `Stage.adaptive` or the asset catalogue (`BackgroundView.swift:17-86`, `DesignSystem.swift:15-31`). No hardcoded black or white on a surface that changes with appearance.
- **Empty, error and permission states.** Every lane has an empty state with an explanation and an action (`RuleListComponents.swift:375-405`); search has its own (`:408-425`); the import sheet has one (`ImportFilterListView.swift:75-85`). `MFMailComposeViewController.canSendMail()` is checked before presenting, with a fallback alert, in both places it is used (`HelpView.swift:152-156`, `OnboardingView.swift:182-186`).
- **Onboarding and Help.** Both were clearly reworked recently and the reasoning is in the comments. The `RuleActivityStore` comments in particular (`:64-71`, `:95-97`, `:124-129`) are the standard the rest of the codebase should be held to: they explain the constraint and the trade, not the code. Findings #3 and #17 exist partly because the newer component got things right that the older one did not.
- **Memory and lifetime.** No retain cycles found. `[weak self]` is used consistently in the store's escaping closures; `ContactView.Coordinator` holds a struct, not a class; no observers are registered that would need removing. The unbounded growth in #13 is the only memory finding.
- **Redux layering.** Actions, reducers, middlewares and views are cleanly separated, views are thin over the store, and business logic is not in `body`. `FilterListView.content` (`:266-269`) hoists derived values out of the view builder deliberately, with the reason recorded. The architecture is sound; the failures above are in what it does with errors, not in its shape.
- **Test coverage** exists and is real: 98 test functions over 1,751 lines, with `SMSOfflineFilterTests` carrying most of it. The notable gap is `RuleActivityStore` — the newest component, cross-process, `@unchecked Sendable`, and untested.
- **Secrets, other than #2.** `Scripts/test_sms.sh` uses environment variables with commented-out placeholders; no Twilio credentials are committed. No hardcoded developer filesystem paths anywhere. `danielbernal@hey.com` (`ContactView.swift:22`) is a deliberate support address, not a leak. `DEVELOPMENT_TEAM = J9F8F3PWTV` in the pbxproj is normal.
