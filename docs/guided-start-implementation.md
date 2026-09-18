# How the guided-start wizard was built

Companion to [`guided-start.md`](./guided-start.md). That document is the
contract — what the wizard promises, on every platform. This one is the
record of how it was actually built on iOS and web, which decisions were
load-bearing, and which traps cost real time. Written 2026-09-18, from the
build itself.

Read the contract first. Nothing here overrides it.

---

## The shape, and why it is a card

The obvious build is a tour: a modal that opens on first launch and walks the
user through the product. We did not build that, and the reason is worth
keeping.

Tours launched from a persistent checklist complete at roughly three times the
rate of auto-triggered standalone tours. Activation-driven onboarding — getting
the user to the one action that predicts retention — beats feature tours
substantially on 90-day retention. And a tour that runs before the user has any
data teaches nothing they can act on: you cannot demonstrate "ask about what you
saved" to someone with an empty vault.

So the wizard is a **persistent card at the top of Home with three items**, each
of which launches a short spotlighted step over the real control. The user saves
a real memory, runs a real compile, asks a real question. It ends with something
in their vault rather than a tour they can recite.

The card never blocks. Skipping a step leaves the item unchecked and changes
nothing else.

---

## The one rule everything else follows from

**The server decides when a step is complete. No client ever writes a
completion latch.**

This is not fastidiousness. iOS capture is offline-queued, so a local "saved" is
not a server "saved" — the bytes may sit on the device for minutes. If the
client latched on its own action, a user who captured on a plane would see step
1 complete and the server would disagree forever.

It also makes two devices agree for free. Both poll the same three booleans, so
finishing step 2 on the phone ticks it on the laptop with no messaging between
them, and the event carries `completed_elsewhere` so the funnel can tell the
difference.

The consequence is that both clients are **pollers**, not state machines with
opinions. Every step ends the same way: the local action happens, the client
nudges a poll, the server's answer arrives, the step closes. The client's own
knowledge of what the user just did is only ever used to poll *sooner*.

Server side this meant the latches had to move into the server, which they
mostly had not: only the compile latch flipped server-side before this work.
`OnboardingLatches` now owns all three, deliberately non-throwing, so a latch
failure can never fail the user action that triggered it. Uploading a file must
not 500 because an onboarding row was locked.

---

## iOS

Eight files under `Features/Home/GuidedStart/`, plus the mascot.

### The coordinator

`GuidedStartCoordinator` is an `@Observable` `@MainActor` class holding a phase
machine — idle, active, celebrating, finished — and the polling schedule. It
takes its onboarding client, its telemetry and its view of app state as
injected dependencies, which is what lets the whole thing be tested without
standing up a network stack or an `AppState`.

Polling backs off (1, 2, 4, 8 seconds, then every 10) with a five-minute cap,
after which the step auto-skips and emits a timed-out event. A local action
resets to an immediate poll.

**A subtlety that produced a wrong fix before a right one.** An early review
found the coordinator could outlive its owner: a polling task held a strong
reference for up to five minutes. The prescribed fix — a `deinit` that cancels
the task — was wrong twice over. `deinit` was unreachable, because the polling
task itself held the last reference; and the test specified for it would have
passed against the broken code, since dropping the reference before the task
started leaves the weak capture already nil. The working fix restructured so the
wait loop lives in the task body over a captured sleep, pinning the coordinator
only while a tick does work and never while it waits. The test parks on a real
sleep, spins until the poll is genuinely suspended, then drops — and was
verified red against a deliberately re-broken build.

The lesson generalises: a lifetime test that does not first reach the state it
claims to test is not a test.

### The spotlight, and the hardest thing in the build

`GuidedAnchors` marks the three real controls with `anchorPreference`.
`GuidedSpotlightOverlay` sits on `MainTabView`'s `TabView`, reads them with
`overlayPreferenceValue`, and punches a hole in a dimming scrim.

A spike ran before any of this was written, and it earned its keep four times:

1. Anchors **do** propagate from rows inside a `List` inside a
   `NavigationStack` inside a `Tab` up to an overlay on the `TabView`, within
   half a point. The single top-level overlay was viable.
2. An unvisited tab publishes nothing, because tab content is lazy — but the
   **previous tab's anchors stay in the preference forever** and keep reporting
   stale geometry. One render drew two spotlights over unrelated rows. The
   overlay must filter anchors by the active tab.
3. The overlay's coordinate space is inset by the safe area, so the dim is
   clipped away from the nav and tab bars unless it takes `.ignoresSafeArea()`.
4. Sheets do not propagate at all. A sheet's anchors never reach the
   `TabView` overlay; guiding inside a sheet needs its own overlay. This does
   not block the wizard, because step 2 spotlights the row on Home rather than
   anything inside the sheet it opens.

**The gotcha that would have cost a day on its own:**
`.coordinateSpace(.named(…))` does not cross the tab or sheet hosting boundary,
and `frame(in: .named(…))` then silently returns *window* coordinates instead —
roughly ninety points of error, with no warning. Build on anchor preferences
only. Never on named coordinate spaces.

### The trap that a review caught and the tests did not

The most serious defect in the whole build was not a crash. Step 2's spotlight
anchored to a row that rendered only when Home's cached "glance" reported
pending work — and that glance loads on appear and pull-to-refresh, never after
a capture. On the wizard's own path (save a memory, step 2 opens) the glance
still held its pre-save zero while the coordinator's live probe correctly saw
work. So no anchor was published, the overlay degraded to "no hole", and the
degraded state returned a **full-screen touch blocker**.

The user could not scroll, could not pull to refresh, and could not tap the
control the bubble was pointing at. Only Skip, or the five-minute timeout.

Two fixes, because there were two bugs:

- A missing anchor now degrades to a dim and a bubble that let **every touch
  through**. A hint, never a modal.
- Step 2's row now renders whenever step 2 is open, independent of the glance
  heuristic. "Is there anything to compile?" and "is this worth recommending
  right now?" are different questions; the step asks the first one directly.

The two paths are mutually exclusive, so the target is never published twice.

### Snapshots, and what pictures catch that diffs do not

The card has eight baselines (four progress states, light and dark) and Home has
four more. They are recorded on CI, because the local toolchain cannot judge
them — see *Environment traps* below.

Recording them found two defects no test had an opinion about, because the cases
had no baseline yet:

- The card and the glance strip **fused into a single white shape with a seam
  across it**. The card draws its own surface on a cleared row while the strip
  takes the List's grouped row background, and two adjacent rows in one section
  get no gutter between them.
- Fixing that exposed a **list separator stranded across the top of the strip's
  card** — the grouped style still drew its separator between the two rows, and
  with the card row's background cleared the hairline came to rest on a card it
  did not belong to.

Neither was visible in a diff. Both were obvious in the image. If a feature is
meant to look considered, someone has to look at it.

---

## Web

The same contract, a different runtime, and a deliberately different
implementation where the platforms differ.

### Pure core, thin shell

- `guided-start-steps.ts` transcribes the contract: ids, copy, targets.
- `guided-start-reducer.ts` is a pure `(state, event) -> state` with effects.
  No DOM, no network, no runes. Exhaustively testable.
- `guided-start.svelte.ts` wraps it in a store with the polling schedule and an
  injected clock and API client.
- `GuidedStartCard.svelte` and `GuidedStepLayer.svelte` are presentation.

### The spotlight is a box-shadow, not a library

No tour library. A library buys a step machine the reducer already provides, a
focus trap we must **not** have, and a second opinion about when a step is
finished — which here is the server's word and nobody else's.

What was actually needed is a rectangle and a bubble. One absolutely-positioned
element the size of the target with a 9999px spread shadow dims everything
except itself. `pointer-events: none` on the whole layer means the button being
taught is still a button — tapping it is the entire point of the step, and an
overlay that swallowed the click would make the step unfinishable.

It is `role="dialog"` **without** `aria-modal`, and nothing pulls focus back.
The control being taught must stay reachable by keyboard. Focus moves to Skip
once on open so the step announces itself and Escape has an obvious home; after
that the user can Tab straight into the composer.

### Three defects review found after it demonstrably worked

The web slice passed its own tests and an end-to-end walk before review found
all three of these. Working is not the same as correct.

**A vault switch could be counted as progress.** The onboarding endpoint is
vault-scoped, but the store is a module singleton deliberately mounted *above*
the boundary that remounts every other Home view model — which is precisely
what lets it survive step 3's navigation to `/chat`. Nothing reset it on a vault
switch, so an open step could outlive its vault and the next load fed the new
vault's latches into the old vault's step state. For a returning multi-vault
user, that fires a completion nobody earned. Fixed by keying the singleton on
the active vault, so a switch hands every reader a store with nothing open.

**Steps 1 and 2 stranded the spotlight.** The teardown guard could not
distinguish step 3's *designed* navigation from the user simply leaving Home, and
the layer rendered unconditionally on the active step — so the bubble followed
them onto unrelated pages, gave up searching for its target after five seconds,
and then sat there with no hole until the five-minute timeout. The layer now
renders only on the page that teaches the open step. Leaving is explicitly
**not** a skip: the step stays open, keeps polling, and the spotlight returns
when they come back. Emitting a skip for a navigation would be a worse lie than
the stranding.

**The completion event fired at latch time**, not after the celebration, which
the contract forbids because it makes the funnel's final stage look instant. It
now rides the end of the celebration. That costs durability — a tab closed
inside the four-second window loses the event, where before it fired atomically
— and that trade is accepted and argued in the code, along with why the two
obvious repairs are worse. Firing on the latch as well double-counts and
restores the useless timing; beaconing from page-hide reports celebrations
nobody saw.

### Bundle discipline

`/home` is held to a hard gzipped budget. The card and the spotlight layer are
both lazy-imported, so the wiring cost about 0.64 KB and the reactions that came
later cost ten bytes.

The ceiling did move once, from 7.0 to 8.0 KB — and the reason is a lesson in
itself. The measurement recorded in a code comment was **already 1.3 KB stale
before anything was touched**: real headroom was 0.1 KB, not the 1.4 KB the
comment implied. Even the most aggressive alternative breached the old ceiling.
A number asserted in a comment that nothing re-checks will drift, and the budget
becomes the only tripwire. The total-JS figure had drifted the same way.

---

## Where the platforms deliberately differ

| Concern | iOS | Web | Why |
|---|---|---|---|
| Step 3 navigation | Switches tab | `goto('/chat')` | Different navigation models |
| Target → location | Tab + anchor | `data-guide` + route map | Routes are web-only; iOS has tabs, Android a NavController |
| Spotlight geometry | Anchor preferences | `getBoundingClientRect` + box-shadow | Framework-native in each case |
| Store lifetime | Owned by the host view | Module singleton keyed on vault | Web must survive a route change; iOS must not outlive its owner |
| Mascot motion | SwiftUI transforms | CSS keyframes | See below |

The step vocabulary, the copy, the ids, the visibility predicate and the
completion rules are identical by contract. Everything else is allowed to be
native.

---

## Hermie

Hermie had seven states — idle, thinking, happy, sad, sleeping, learning,
celebrating — driven correctly by the app for months, and **none of them did
anything**. The iOS view pushed the state into a Rive input, and there is no
`.riv` file in any repository. There never was. The asset notes described it as
"idle-only", which read as "there is an artboard, it just is not worth wiring",
and that sentence is why seven states rendered one static image for months.

Both platforms now express the states host-side: SwiftUI transforms on iOS, CSS
keyframes on web, from one shared design brief, matched tempo for tempo.

On iOS each reaction is a pure function of a single scalar driven through an
`Animatable` modifier. That is load-bearing rather than elegant: SwiftUI
evaluates a modifier's body per intermediate value, so a non-linear pose is
honoured frame by frame. Animating the transforms directly interpolates
endpoint to endpoint — and a loop whose endpoints are both the resting pose
renders as *nothing at all*.

The animation threshold split in two: Rive stays at 64pt because a render loop
has real per-instance cost, host-side motion drops to 48pt because four affine
transforms cost nothing and the only question is whether it reads. That line
sits between the 32pt chat mascots and the 56pt card and spotlight bubble — the
two places Hermie is most obviously meant to be working, and the two where he
was frozen.

Step 2 maps to `learning` rather than `thinking`, because it is literally
handing Hermie something to read. Web reached that independently; rather than
let code and contract disagree quietly, the contract moved.

`sleeping` is deliberately unreachable from the wizard on both platforms. A
first-time user who has not started should be invited, not asleep. Both carry a
test asserting no wizard input produces it, so nobody wires one up by accident.

### The accessibility defect this uncovered

Web's reduced-motion backstop **never fired**. The media query block meant to
remove the animations lost on specificity, 4 to 2, and media queries carry no
specificity to make up the difference. Verified in a browser rather than argued:
with the gate forced open under an emulated reduce preference, seventeen things
were moving.

The original bob had been safe only because its reset selector was *identical*
to its animation selector, so source order decided it. Changing the selector
shape silently dropped the property that made the pattern work.

The fix inverts the query: every animation now lives inside
`prefers-reduced-motion: no-preference`, so under `reduce` the rules are not in
the cascade at all. No class, no ordering, no future selector and no timing can
revive them, and a user agent matching neither value gets stillness rather than
motion. The guarantee no longer depends on anything being read at the right
moment.

Chasing that further found a live violation unrelated to the wizard — a progress
strip tween that slid for 620ms for users who had asked for stillness — plus a
spring, two smooth scrolls, and two raw `fly` imports sitting in the same import
block as a gated helper, which had passed review. A lint rule now makes
`svelte/transition` and the preference primitive importable only by the motion
module, so the bypass fails in CI rather than depending on a reviewer noticing a
one-word difference.

---

## Testing, per platform

**iOS.** Coordinator tests drive a scripted fake onboarding client through
start, poll, celebrate and idle, plus skip, timeout, completed-elsewhere, the
step-2 guard and the visibility truth table. Step tests pin ids, copy and
targets to the contract. Snapshot tests cover the card in four progress states
across light and dark, and Home with the card present. Motion tests are pure
functions over poses — every state moves, no two trace the same path, and the
frozen frame is identity at every cycle and size.

**Web.** The reducer is swept exhaustively. The store is tested against an
injected clock, so the polling schedule and the celebration window are asserted
rather than waited on. Component tests cover the card and the mascot. End-to-end
specs cover the card's visibility rules, a full step through the composer, the
vault switch, the route-scoped spotlight, and reduced motion.

**A parity test** pins the step ids and copy on web to the canonical table, so
the two platforms cannot drift apart silently.

### Two tests that were worse than nothing

Both passed while the thing they guarded was broken.

The reduced-motion spec asserted two things that were both true on the happy
path: that the markup withheld a class, and that the computed animation was then
`none`. The second only ever ran in the state the first had already established,
so it would have passed forever over a stylesheet that animates the instant
anything opens the gate.

The first draft of its replacement watched the `style` attribute and found
nothing, which looked like a pass — Svelte compiles CSS transitions to
`element.animate()`, so the evidence was in the Web Animations API. Its own
vacuity guard caught that.

**If a test cannot fail while the promise is broken, it is not protecting
anyone.** Verify red before green, and make the red message name the offender.

---

## Environment traps

These cost more time than any of the feature code, and all three are the same
shape: **a tool resolving to a different version in two places, so a check means
different things depending on where it runs.**

- **SwiftFormat and SwiftLint** are pinned in server CI. The local Homebrew
  builds are newer. Judging formatting locally against the wrong version is
  meaningless; download the pinned pair first. CI carries a comment about a
  ten-day red gate caused by exactly this.
- **Prettier** resolves newer locally than CI installs from the lockfile. A
  repo-wide local check reported 155 files; CI flagged one. Reformatting all of
  them to satisfy a version CI does not use would have been a large, wrong
  commit.
- **Playwright 1.61.0 silently drops `reducedMotion` when it arrives as a
  fixture option.** CI installed 1.61.0 from the lockfile; local resolved the
  same caret range to 1.63.0. So a spec asking for the preference that way ran
  with none set at all, and the app was blamed for a premise that was false.
  Now pinned exactly.

**The iOS local toolchain aborts** with `malloc: pointer being freed was not
allocated` on many test cases, repo-wide. It was first read as one transport
test, then as "synchronous methods in a main-actor case". Both too narrow —
async snapshot cases abort too, and the trigger is running the assert. Treat it
as a property of the local toolchain, confirm against untouched code before
blaming a branch, and take snapshot verdicts from CI, which pins a simulator
runtime the local Xcode does not have.

**Recording snapshots re-records everything.** Take only the images you meant to
change and verify the rest came back byte-identical. A run returning 51 of 70
identical is what makes the few that moved believable. One baseline differs by
about 130 bytes on every run while its case passes; that is encoder noise, not a
change.

---

## What was deliberately not built

- **Android.** Documented as an appendix in the contract; no code.
- **Rive.** No artboard exists. Host-side motion ships in its place and is
  meant to hold. If an artboard ever lands, both platforms already send the
  state, so it arrives with no code change and the host motion becomes the
  fallback — at the cost of re-recording twelve baselines. Web should probably
  decline it regardless: roughly 60–90 KB gzipped plus WASM instantiation
  before the first frame, for a small mascot on a budgeted page.
- **Guiding inside a sheet** on iOS. It needs its own overlay; the spike
  established that and the wizard was designed not to need it.

---

## The one thing still missing

**Nobody has walked this on a real account.** Every check so far proves the
parts. The walk — sign in fresh, save a memory, watch step 1 tick from the
server latch, run Sync & Learn, ask a question, see the confetti, reopen from
Settings — is the only thing that exercises the latches, the polling schedule
and the spotlight against real timing together.

Green CI is not a substitute for it, and this document should not be read as
though it were.
