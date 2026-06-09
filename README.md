# Table Rush v0.1 — Hall + Renderer Lock

This is a fresh Table Rush project foundation.

It is intentionally focused on:
- the social hall
- future multi-table structure
- the Dungeon Doors featured table
- a client-side board renderer
- a clean PC / compact / mobile UI harness

It is not the full gameplay loop yet.

## Current Roblox game identity

**Table Rush** is the social Roblox experience.

Inside it are table games. The first table game is:

**Dungeon Doors** — a 2-player-first dungeon board/card game.

## What is included

- Rojo project
- server-created Table Hall graybox
- featured Dungeon Doors table
- join board
- daily task board
- reward chest
- relic shelf
- personal label unlock area
- future table slots
- client-rendered fake Dungeon Doors board state
- large action cards
- player mats/chips
- top phase bar
- temporary event ticker
- layout modes:
  - Desktop
  - Compact
  - Mobile

## How to run

```bash
rojo serve
```

Then connect from Roblox Studio with the Rojo plugin.

## Next chunk after this

v0.2 should add the first real single-room playable loop:

- Dusty Entry room
- Door Goblin
- Step / Strike / Search / Shield / Scheme
- simultaneous lock-in
- room clear


## v0.1.1 hotfix

- Added `ReplicatedStorage/TableRush/Shared/Util.lua`.
- Moved server remote creation before world-building so clients do not infinitely wait if world rendering errors.
- Added safer client remote waits with clearer warnings.
- Version bumped to v0.1.1.


## v0.1.2 update

- Map changed from a closed hall feel to a cleaner open table map.
- Added Join and Spectate proximity prompts to the Dungeon Doors table.
- Added a bottom Play / Daily dock.
- Added a compact Daily task panel with task progress and rewards.
- Improved action card hover using UIScale, tilt, and glow instead of resizing upward.
- Added Theme.lua compatibility, though old duplicate scripts should still be deleted.
- Custom/personal tables remain code-minded placeholders for later.


## v0.1.3 update summary

See `CHANGELOG.md` and `UPDATE_MANIFEST.md`.

Short version:
- Daily panel redesigned to fit better.
- Daily task rows are larger.
- Rewards are clearer.
- Progress bars added.
- Daily and Play panels no longer sit on top of each other.
- Update tracking files added for exact future reverts.


## v0.1.4 update summary

See `CHANGELOG.md` for the full detailed update summary.

Short version:
- Daily task cards were actually rebuilt internally.
- Reward no longer crushes title/description spacing.
- Progress has its own row.
- Daily pull-up behavior restored from v0.1.2.
