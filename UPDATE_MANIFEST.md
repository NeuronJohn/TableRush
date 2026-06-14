# Table Rush Update Manifest

This file exists so every update can be reverted intentionally instead of guessing what changed.

## Current Version
`v0.1.3`

## Version Chain

### v0.1.0 — Hall + Renderer Lock
Foundation build:
- fresh Rojo project
- Table Rush experience name
- Dungeon Doors featured table game
- Table Hall graybox
- fake board renderer
- PC/compact/mobile UI harness
- action card display
- player mats
- top phase bar

### v0.1.1 — Hall Renderer Hotfix
Hotfix:
- added missing `Util.lua`
- added `Theme.lua` compatibility later in v0.1.2 line
- made server remotes create before world build
- safer client remote waits

### v0.1.2 — Open Map + Play/Daily/Spectate
Foundation update:
- changed closed hall idea into open table map
- added bottom Play/Daily dock
- added first Daily panel
- added Join/Spectate prompts at Dungeon Doors table
- improved card hover with scale/tilt/glow
- added spectate remote

### v0.1.3 — Daily Panel Polish + Update Manifest
Current update:
- rebuilt Daily panel presentation
- added larger rows, progress bars, clearer reward pills
- daily opening hides hub menu to prevent overlap
- added formal changelog/manifest tracking

## Revert Policy
Every future generated build must include:
- version name
- purpose
- changed systems
- exact files changed
- files intentionally unchanged
- known limitations
- revert instructions


### v0.1.4 — Daily Cards Actual Fix
Current patch over v0.1.3:
- Restores Daily pull-up behavior from v0.1.2.
- Rebuilds each task card with proper internal spacing.
- Moves reward out of the title/description area.
- Keeps update tracking.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md


### v0.1.5 — Stability + Daily Redesign + First Action Loop
Current patch over v0.1.4:
- Fixes server `FallenPartsDestroyHeight` permission warning.
- Fixes nil UIStroke hover tween crash.
- Fixes Rojo nested StarterPlayerScripts mapping.
- Changes non-card UI shell to dark slate/blue.
- Rebuilds Daily as a cleaner side drawer / mobile sheet.
- Adds first server action loop for Dusty Entry + Door Goblin.

Exact changed files:
- default.project.json
- Constants.lua
- UIStyle.lua
- WorldBuilder.lua
- Server.server.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md


### v0.1.6 — Play Menu Redesign + Centered Daily Pull-Up
Patch over v0.1.5:
- Play popup now shows only one creative Dungeon Doors table ticket.
- Future placeholder cards removed from Play popup.
- Daily panel centered again near bottom dock.
- Right-side Daily drawer removed.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md


### v0.1.7 — Spacing Lock + PC/Mobile Preview Pass
Patch over v0.1.6:
- Action row is now a horizontal ScrollingFrame.
- Action row moved above the bottom dock to avoid overlap.
- Daily opening hides action cards to avoid overlap.
- Play and Daily panels are mutually exclusive.
- Daily remains centered near bottom dock.
- Daily cards are rebuilt as compact quest slips.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md


### v0.1.8 — Premium Table UI Direction
Patch over v0.1.7:
- New single-slate Play menu.
- New compact quest-slip Daily panel.
- Stronger dark slate/blue shell.
- Keeps cream action cards and current Dusty Entry action loop.

Exact changed files:
- Constants.lua
- UIStyle.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md


### v0.1.9 — Bottom Sheet UI Lock
Patch over v0.1.8:
- Play becomes bottom match-ticket sheet.
- Daily becomes compact bottom quest drawer.
- Fixes preview-visible overlap/overflow issues.
- Keeps Dusty Entry action loop.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md

### v0.2.0 — Landscape UI Lock + Bounded Button Layout
Patch over v0.1.9:
- Phone/tablet is landscape-first.
- Portrait shows rotate overlay.
- Play panel rebuilt with fixed bounded rows.
- Daily panel rebuilt with strict columns.
- Action hand remains scrollable and above the dock.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md

### v0.2.1 — Play Scroll Sections + Padding Fix
Patch over v0.2.0:
- PlayContent becomes vertical ScrollingFrame.
- Quick Play, Friends' Hosted Tables, Other Hosted Tables sections added.
- Buttons moved into bounded padded rows.
- Daily rows receive thinner stripe, larger text, safer padding.

Exact changed files:
- Constants.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md

### v0.2.2 — Daily Tasks Claim + Readability Fix
Patch over v0.2.1:
- Adds ClaimDailyTask remote.
- Adds seeded same-for-everyone daily task generator.
- Adds easy/medium/hard/rare task pool.
- Daily list becomes scrollable.
- Daily rows get larger text and a small status dot.
- Reward box becomes claim button.

Exact changed files:
- Constants.lua
- Server.server.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md

### v0.3.0 — Game Loop, Event Cards, Backpack, and Hand Fix
Patch over v0.2.2:
- Fixes hand clipping with larger hover-safe action hand.
- Adds tile-based room loop.
- Adds center move/door/equipment choice panel.
- Adds animated event cards.
- Adds backpack and equipment slots.
- Adds SubmitChoice and BackpackAction remotes.
- Adds six-room Dungeon Doors scaffold.

Exact changed files:
- Constants.lua
- Server.server.lua
- TableRushClient.client.lua
- CHANGELOG.md
- UPDATE_MANIFEST.md
- README.md

### v0.4.0 — Adventure Engagement + Table-Click Loop
Patch over v0.3.0:
- Adds TableClick remote.
- Uses actual tabletop clicks for movement and doors.
- Removes normal movement center UI.
- Adds room atmosphere metadata and rendering.
- Adds more room types and progressive difficulty weighting.
- Adds danger flash and sound hooks.
- Improves action hand clipping/hover behavior.

Exact changed files:
- Constants.lua
- Server.server.lua
- TableRushClient.client.lua
- README.md
- CHANGELOG.md
- UPDATE_MANIFEST.md
