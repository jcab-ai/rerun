# [rerun]

A BitLife-style life sim for macOS that turns your real iMessage history into
playable, AI-generated stories. Native SwiftUI, macOS 14+.

Design source of truth: [`design/Rerun_App.html`](design/Rerun_App.html) (11 screens).
Reference renders of individual screens live in [`design/reference/`](design/reference).

## Status

| Piece | State |
| --- | --- |
| Design tokens (`Sources/RerunUI/Design/DesignTokens.swift`) | ✅ colors, type, spacing, radii, strokes, tilts, shadows |
| Shared components (stickers, torn paper, kraft, dot grid, hard-shadow buttons, chips, title bar) | ✅ |
| World map home screen | ✅ first working view |
| Moment detail | 🟡 preview card with real data; evidence props + add-context next |
| Play, People, Moments, Context notes, in-app Settings, onboarding | ⏭ next iterations |
| chat.db reader (read-only snapshot), voice profiler, moment detector, world builder | ✅ with tests |
| Model router + Anthropic / OpenAI / Gemini clients, Keychain keys, story engine | ✅ with tests |
| Energy / turn limits | hook only (`TurnGate`, default `UnlimitedTurns`) |

## Running

```sh
# Quick dev run (no .app bundle):
swift run rerun-dev

# Proper app bundle (needed for a stable Full Disk Access grant):
brew install xcodegen
xcodegen            # generates Rerun.xcodeproj from project.yml
open Rerun.xcodeproj
```

Until you scan Messages, rerun shows the mockup's sample world (Jules's). To use
your own history:

1. Grant **Full Disk Access** to rerun (or to Terminal/Xcode when using `swift run`)
   in System Settings → Privacy & Security.
2. Open **rerun → Settings…** (⌘,), click **Build my world from Messages**.
3. Add at least one API key in the same window to generate stories.

## Privacy model

- rerun **never opens the live Messages database**. It copies `chat.db` (+ WAL) to a
  private temp folder, opens the copy with SQLite's read-only mode, and deletes it
  after the scan (`MessagesSnapshot`). It never writes to or sends through Messages.
- Everything rerun derives — people, moments, voice profiles, context notes, stories,
  settings — is stored locally in `~/Library/Application Support/Rerun/rerun.sqlite`.
- The only network traffic is story-turn requests to the provider you've routed that
  scene to. Prompts contain the moment summary, voice profiles, your context notes and
  (optional, on by default) a capped excerpt of that moment's texts plus a few short
  example texts per person. Both are toggles in `AppSettings`.
- API keys live in the login Keychain (`KeychainSecretStore`).
- The app is not sandboxed: sandboxed apps can't read the Messages library even with
  Full Disk Access.

## Architecture

```
App/                     @main app (used by both SwiftPM and the Xcode target)
Sources/RerunCore/       Foundation + SQLite only; builds & tests on Linux too
  Models/                Person, Moment, ContextNote, StoryRun, AppSettings, WorldMap
  Storage/               SQLite wrapper, RecordStore (one JSON row per record)
  Messages/              MessagesSnapshot, ChatDatabaseReader, attributedBody decoder, contact names
  Voice/                 VoiceProfiler → VoiceProfile (casing, punctuation, emoji, slang, bursts, reply cadence)
  World/                 MomentDetector, WorldLayout, WorldBuilder, DemoWorld (the mockup's data)
  LLM/                   ModelRouter, provider clients, Keychain SecretStore
  Story/                 PromptBuilder, StoryBeatParser, StoryEngine, TurnGate
Sources/RerunUI/
  Design/                DesignTokens.swift, FontRegistry, Components/
  Features/              Shell (window, sidebar), WorldMap, Moment, Settings
Tests/                   RerunCoreTests (Linux + macOS), RerunUITests (snapshots, macOS)
```

### Model routing

Each story turn is routed by its scene tag (`MomentTag`): the moment's tag for the first
turn, then whatever `next_scene` the model reported. The default table sends **romance →
Gemini** and **everything else → Claude (`claude-opus-5-5`)**; every tag can be pointed
at any provider/model in Settings. If the chosen provider has no key, the turn falls back
to one that does. Claude requests opt into server-side refusal fallbacks
(`fallbacks: "default"`). Default OpenAI/Gemini model IDs are editable — check each
provider's docs for their current models.

### Energy hook

`StoryEngine` asks a `TurnGate` before every turn and reports every turn back. The app
uses `UnlimitedTurns`; implement `TurnGate` to add energy/turn limits later.

## Tests & snapshots

```sh
swift test                                   # core tests (also on Linux)
RERUN_SNAPSHOT_DIR=snapshots swift test      # macOS: also writes world-map.png etc.
```

CI (`.github/workflows/ci.yml`) runs the core tests on Linux, builds the package and the
XcodeGen app on macOS, and uploads the screen snapshots as an artifact for comparison
with `design/reference/`.

## Fonts

Fredoka, Caveat and Space Mono are bundled under the SIL Open Font License
(`Sources/RerunUI/Resources/Fonts/OFL-*.txt`).
