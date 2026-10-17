# [rerun]

A BitLife-style life sim for macOS that turns your real iMessage history into
playable, AI-generated stories. Native SwiftUI, macOS 14+ (on-device stories need macOS 26).

Design source of truth: [`design/Rerun_App.html`](design/Rerun_App.html) — 11 screens.
Reference renders of every mockup screen are in [`design/reference/`](design/reference);
CI renders the SwiftUI screens at the same size so they can be compared side by side.

## What's in it

| Screen | |
| --- | --- |
| **Welcome · Privacy · Who's in your world? · Building your world** | First-run flow. Reads Messages only after you allow it, surveys your biggest threads without reading text, lets you pick who's included, then builds the world with live progress (and a notification if you wander off). |
| **World map** | Every moment as a sticker strung to "you": solid lines for played, dotted for not yet, "+N" hubs for more, filter chips, zoom & pan, lines that draw themselves in. |
| **Moment detail** | A torn sheet over the blurred world with an evidence board per moment type — boarding pass (with MISSED stamp), receipt, ticket stub, voice memo, polaroid — plus the people in it, the last run's outcome and **play**. |
| **Play** | The story plays out as a simulated iMessage thread inside the app, never sent anywhere: chapter card, lock-screen polaroid, typing dots and read receipts, a live voice-match score, three choices, "Chapter N unlocked", endings. |
| **People · storylines** | Photo-booth strips for everyone; each person's storyline on a hand-drawn timeline with their texting-voice badges ("LMAOOO (3+ O's)"). |
| **Moments** | A scrapbook of every moment by year, filterable by kind, each year closed out with a little recap receipt (moments, real texts, plays, who was loudest). |
| **Context notes** | A lined notepad for what the texts don't say, pinned to a person or to specific moments. Notes go into story prompts, never back to anyone. |
| **Settings (Contents)** | Who's included, story style, story model (on this Mac or cloud), off-limits topics, rescan, export notes, erase everything. API keys and per-scene model routing live in the ⌘, window. |
| **Empty & error states** | No conversations, Messages locked (Full Disk Access), chapter lost in the mail, no storyteller yet. |

Until you scan Messages, rerun shows the mockup's sample world (Jules, Maya, Dad, the ducks…).
Every sample moment has a hand-written branching story, so the whole thing is playable with no
API key and no setup.

## Running

```sh
# Quick dev run (no .app bundle):
swift run rerun-dev

# Proper app bundle (icon, notifications, a stable Full Disk Access grant):
brew install xcodegen
xcodegen            # generates Rerun.xcodeproj from project.yml
open Rerun.xcodeproj
```

To use your own history:

1. Click **scan my messages →** in the sidebar (or World → Build My World from Messages…).
2. Grant **Full Disk Access** to rerun (or to Terminal/Xcode when using `swift run`)
   in System Settings → Privacy & Security, then **I did it — check again**.
3. Pick who's in your world → **Build my world**.
4. For stories about your real moments, pick a story model in Settings: **On this Mac**
   (macOS 26 with Apple Intelligence; nothing leaves the Mac) or **Cloud** with an API key
   (⌘, → API keys).

Keyboard: ⌘1–5 switch screens, ⌘0 back to the map, ⌘P play the last moment, ⌘⇧R rescan,
1/2/3 pick a choice while playing, ↩ continue, esc closes.

## Privacy model

- rerun **never opens the live Messages database**. It copies `chat.db` (+ WAL) to a
  private temp folder, opens the copy with SQLite's read-only mode, and deletes it
  after the scan (`MessagesSnapshot`). It never writes to or sends through Messages.
- Choosing people happens before any message text is read; excluded people are never read.
- Everything rerun derives — people, moments, voice profiles, context notes, stories,
  settings — is stored locally in `~/Library/Application Support/Rerun/rerun.sqlite`.
  **Erase my world** deletes it all.
- The only network traffic is story-turn requests to the cloud provider you've routed that
  scene to (none at all with the on-device model or the sample stories). Prompts contain the
  moment summary, voice profiles, your context notes and (optional, on by default) a capped
  excerpt of that moment's texts plus a few short example texts per person.
- API keys live in the login Keychain (`KeychainSecretStore`).
- The app is not sandboxed: sandboxed apps can't read the Messages library even with
  Full Disk Access.

## Architecture

```
App/                     @main app + World menu (used by SwiftPM and the Xcode target), app icon
Sources/RerunCore/       Foundation + SQLite only; builds & tests on Linux too
  Models/                Person, Moment (+ Evidence), ContextNote, StoryRun/StoryBeat, AppSettings, WorldMap
  Storage/               SQLite wrapper, RecordStore (one JSON row per record), lenient decoding
  Messages/              MessagesSnapshot, ChatDatabaseReader, attributedBody decoder, contact names
  Voice/                 VoiceProfiler → VoiceProfile (badges, learned lines), VoiceMatcher
  World/                 MomentDetector, WorldLayout, WorldBuilder (survey → build), DemoWorld, DemoStories
  LLM/                   ModelRouter, Anthropic/OpenAI/Gemini clients, on-device FoundationModels, Keychain
  Story/                 PromptBuilder, StoryBeatParser, StoryEngine, ScriptedStoryTeller, TurnGate
Sources/RerunUI/
  Design/                DesignTokens.swift, FontRegistry, AppIcon, Components/ (stickers, paper,
                         props, doodles, buttons, window chrome, snapshot-safe wrappers)
  Features/              Shell, Onboarding, WorldMap, Moment, Play, People, Moments, Notes, Settings
Tests/                   RerunCoreTests (Linux + macOS), RerunUITests (every screen, macOS)
```

### Model routing

Each story turn is routed by its scene tag (`MomentTag`): the moment's tag for the first turn,
then whatever `next_scene` the model reported. The default table sends **romance → Gemini** and
**everything else → Claude (`claude-opus-5-5`)**; every tag can be pointed at any provider/model
in ⌘, Settings, including the on-device model. If the chosen provider has no key, the turn falls
back to one that does. Claude requests opt into server-side refusal fallbacks
(`fallbacks: "default"`). Default OpenAI/Gemini model IDs are editable — check each provider's
docs for their current models. Choosing **On this Mac** in Settings sends every turn to the
on-device model with a slimmer prompt.

### Energy hook

`StoryEngine` asks a `TurnGate` before every turn and reports every turn back. The app uses
`UnlimitedTurns`; implement `TurnGate` to add energy/turn limits later.

## Tests & snapshots

```sh
swift test                                   # core tests (also on Linux)
RERUN_SNAPSHOT_DIR=snapshots swift test      # macOS: also writes a PNG of every screen
```

CI (`.github/workflows/ci.yml`) runs the core tests on Linux, builds the package and the
XcodeGen app on macOS 26, and uploads the screen snapshots as an artifact.

## Fonts

Fredoka, Caveat and Space Mono are bundled under the SIL Open Font License
(`Sources/RerunUI/Resources/Fonts/OFL-*.txt`).
