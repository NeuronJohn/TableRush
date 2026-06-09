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

