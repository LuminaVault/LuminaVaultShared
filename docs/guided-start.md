# Guided first capture ("Get started with Hermie")

The canonical contract for the onboarding wizard on iOS, web, and later Android.
Every platform implements the same three steps, the same completion signals, and
the same visibility rule. When the platforms disagree, this file wins.

Nothing here is a new API. The steps hang off latches that already exist on
`OnboardingStateDTO`, plus one new two-way field for dismissal.

## Why it is shaped this way

New users land on Home with an empty vault and no idea what the product does
with a memory once it is saved. The wizard teaches by having them do the real
thing once: **save a memory, let Hermes learn it, ask about it.** That loop is
the product; everything else builds on it.

It is a persistent card whose items launch short steps, not a blocking tour.
Auto-triggered tours complete at roughly a quarter of the rate of the same
steps launched from a checklist, and a tour that runs before the user has any
data teaches nothing they can act on.

## The three steps

| id | Card row | Hermie's line | Spotlight target | Done when |
|---|---|---|---|---|
| `save_memory` | Save a memory | "Type anything you want to remember, then Save." | the Home composer | `firstCaptureCompleted` |
| `sync_learn` | Sync & Learn | "Now let me read it — tap Sync & Learn." | the Sync & Learn row/button | `firstKBCompileCompleted` |
| `ask` | Ask about it | "Ask me anything about what you just saved." | the chat composer | `firstQueryCompleted` |

Card headline: **Get started with Hermie**. Progress reads `n of 3`.
Completion line, with Hermie celebrating: **"That's the whole loop. Everything
you save, I learn."** Skip label: **Skip**. Dismiss is an `×` on the card.

The step id is also the analytics `step` property, so a funnel in PostHog reads
the same across platforms without mapping.

The spotlight target is a separate, smaller vocabulary — `composer`, `sync`,
`chat` — because a target is a place in the UI and a step is a task, and the
two are only one-to-one today. On the web these are the `data-guide` attribute
values; on iOS they are the anchor keys. Two steps pointing at one target later
should not require renaming either the step or the DOM.

## Completion is the server's word, never the client's

A client must **never** set `firstCaptureCompleted`, `firstKBCompileCompleted`,
or `firstQueryCompleted` itself. The server latches all three as a side effect
of the real work:

- capture upload and link capture latch `firstCaptureCompleted`
- `POST /v1/memory-compile` latches `firstKBCompileCompleted`
- finishing a chat reply latches `firstQueryCompleted`

This matters because "saved" on a client is not "saved" on the server. iOS
queues captures offline and drains them later, so a local success can precede
the server row by a long time. Polling the latch is the only signal that means
the thing actually happened.

After the user acts, poll `GET /v1/onboarding` at 1s, 2s, 4s, 8s, then every
10s, giving up after 5 minutes (emit `step_timed_out` and close the step
quietly). Any local signal that the action completed should trigger an
immediate poll rather than waiting for the next tick.

**An empty compile does not count.** The server returns early when there are no
unprocessed rows, so the latch stays false. Step 2 must therefore check that
something is actually pending before it starts; if nothing is, Hermie says
"Save something first — then I'll have something to learn." and the step does
not begin.

## Dismissal

`OnboardingStateDTO.guidedStartDismissedAt` is a nullable timestamp, set and
cleared through `PATCH /v1/onboarding` with `guidedStartDismissed`. It is the
**only** two-way field on that endpoint — the seven completion flags remain
one-way latches and still reject `false`.

It lives on the onboarding row rather than a preferences endpoint so that one
read answers the whole visibility question, and so dismissing on a phone hides
the card on the web too.

## Visibility

```
loaded    := an onboarding snapshot is in hand   (nil or loading → render nothing, no flash)
allDone   := firstCaptureCompleted && firstKBCompileCompleted && firstQueryCompleted
dismissed := guidedStartDismissedAt != nil

visible   := loaded && !allDone && !dismissed
```

There is no separate "has seen it" flag: a fresh account is all-false and
undismissed, so it is visible. That is the auto-show.

- **Dismiss** hides optimistically, then PATCHes; on failure, un-hide and say so.
- **Settings › "Show me around"** clears the dismissal. If everything is already
  done, show the completed card for that session only — do not persist a way to
  re-enter a finished wizard.
- **Starting a step** refreshes first. If that step's latch is already true,
  skip ahead to the first incomplete one instead of spotlighting something the
  user has done.
- **A latch flipping on another device while a step is open** completes the step
  normally, with `completed_elsewhere: true` on the event. The user did the
  thing; where they did it is not interesting.
- **Dismissal arriving from another device** hides the card at the next refresh,
  but only after any open step has finished or been skipped.

At most one step is ever active.

## Sharing Home with other cards

The Get-started card owns the top of Home until it is finished. While it is
visible, other promotional strips on Home — the breaking-news ticker today,
anything similar later — stay hidden, so a first-time user sees exactly one
thing to do. They return once the card is completed or dismissed. In practice
that is one predicate on both platforms: render the strip only when the guided
card is not visible.

## Hermie

Hermie reacts, because a guide that does not respond to what you just did is a
tooltip wearing a costume. The state vocabulary is shared, spelled identically
on every platform: `idle`, `thinking`, `happy`, `sad`, `sleeping`, `learning`,
`celebrating`.

What the wizard drives:

| Situation | State |
|---|---|
| Resting card, nothing open | `idle` |
| Step 1 or step 3 open | `thinking` |
| Step 2 (Sync & Learn) open | `learning` |
| A step just completed | `happy` |
| All three done | `celebrating`, with confetti |
| A save failed, or step 2 refused for nothing pending | `sad` |

Step 2 is `learning` rather than `thinking` because it is literally handing
Hermie something to read, and `learning` already means the absorb pulse for a
compile job. `sleeping` is deliberately unreachable from the wizard: a
first-time user who has not started yet should be invited, not asleep. Both
platforms carry a test asserting no wizard input produces it, so nobody wires
one up by accident.

Precedence, highest first, because these overlap constantly: `celebrating`
beats everything (the last latch raises both), then `sad`, then `happy`, then
an open step. `happy` must outrank `thinking` — a step completes while its own
spotlight is still open, which is the normal path, so a reward that lost to the
step it rewards would never be seen.

### There is no Rive artboard

`lumina_anims.riv` does not exist in any repository. It never did. Earlier
notes describing it as "idle-only" were wrong in a load-bearing way: they read
as "there is an artboard, it just is not worth wiring", which stopped anyone
from making the states real for months.

So the reactions are host-side by deliberate choice — SwiftUI on iOS, CSS on
web — and that is the shipped behaviour, not a placeholder to rip out in a
hurry. If an artboard is ever authored, the state vocabulary and the
motion-off gate are already the shape Rive wants, so it swaps in behind the
same seven names.

Web should probably decline it regardless: the canvas runtime is roughly
60–90 KB gzipped plus WASM instantiation before the first frame, for a small
mascot on a page under a hard size budget. iOS pays no download for a bundled
file and can reasonably decide differently. That asymmetry is fine — the
character is defined by this document, not by the renderer.

## Analytics

Event names, identical on iOS and Android; the web prefixes each with `web_`
because its event union already carries that convention.

```
guided_start_card_shown
guided_start_step_started
guided_start_step_completed
guided_start_step_skipped
guided_start_step_timed_out
guided_start_dismissed
guided_start_reopened
guided_start_completed
```

Which properties go on which event:

| Event | Properties |
|---|---|
| `card_shown` | none |
| `step_started` | `step`, `source` |
| `step_completed` | `step`, `elapsed_ms`, `completed_elsewhere` |
| `step_skipped` | `step`, `elapsed_ms` |
| `step_timed_out` | `step`, `elapsed_ms` |
| `dismissed` | none |
| `reopened` | none |
| `completed` | none |

`step` is one of the three step ids. `source` is `auto` when the user tapped a
row on the card and `settings` when they arrived through "Show me around".
`elapsed_ms` is measured from when the step opened. `completed_elsewhere` is
true when the latch flipped while the step was open without a local action —
the user did it on another device.

`card_shown` fires once per app session, the first time the card renders, not
once per render. `completed` fires once, after the final celebration finishes,
not at the moment the last latch flips — the celebration is part of the step,
and firing early makes the funnel's last stage look instant.

## Two things that will bite an implementer

**The pending count for step 2 must be fresh.** The guard reads how many
captures are waiting to be compiled. If it is handed a cached number from a
screen that loaded minutes ago, the step can start when nothing is pending,
and then poll a latch that cannot possibly flip until the five-minute timeout
expires — a silent dead end with a spotlight sitting on screen. Re-read the
count when the step starts rather than trusting whatever the surrounding view
already had.

**Anchoring a spotlight has platform limits worth knowing before you design
around them.** On iOS, measured: anchor preferences do travel from a row inside
a `List` inside a per-tab `NavigationStack` up to a single overlay on the
`TabView`, accurately. But an unvisited tab reports nothing (its content is
built lazily), the previous tab's anchors linger in the preference and report
stale geometry unless the overlay filters by active tab, the overlay must
ignore safe areas or its dim stops short of the nav and tab bars, and anchors
inside a presented sheet never reach an overlay outside it — a sheet needs its
own. Named coordinate spaces are not a substitute: across a tab or sheet
boundary they silently resolve to window coordinates instead of failing, which
is a large offset and no error. Use anchors.

## Accessibility and motion

The spotlight overlay must not trap focus: the control being taught has to stay
reachable, so the overlay is not modal to assistive technology. Move focus to
Hermie's bubble when a step opens, expose the line as the accessible label, keep
Skip a real button, and let Escape (or the platform's equivalent) skip.

Every transition respects the system's reduced-motion setting, including the
confetti.

## Android, when it happens

The same step ids, copy, latches, and visibility rule apply unchanged — no
server work is needed to add the platform. A repository wraps `GET`/`PATCH
/v1/onboarding`; a view model holds the same phase machine and the same polling
schedule.

Targets register their bounds with `Modifier.onGloballyPositioned`, storing
`boundsInRoot()` per target. The overlay is a full-screen `Box` above the bottom
navigation that draws the scrim in `Modifier.drawWithContent` and punches the
hole with `BlendMode.Clear` inside an offscreen `graphicsLayer`, passing touches
through the hole by hit-testing the stored rect in `pointerInput`. Step 3
navigates with the NavController rather than trying to anchor a bottom-navigation
item, exactly as iOS switches tabs programmatically instead of spotlighting a
tab bar it cannot anchor.

Hermie uses the Rive Android runtime against the same `.riv`; until the artboard
gains a state machine, reactions are Compose-level.
