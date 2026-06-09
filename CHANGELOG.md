# Table Rush Changelog

## v0.1.3 — Daily Panel Polish + Update Manifest

### Purpose
Focused update to make the Daily tab/panel look cleaner, fit its own content better, and start formal update tracking for exact future reverts.

### Changed
- Bumped `Constants.VERSION` from `v0.1.2` to `v0.1.3`.
- Rebuilt the Daily panel layout:
  - increased panel size from `380x218` to `470x292` on desktop.
  - added a subtitle explaining why dailies matter.
  - task rows increased from `48px` height to `64px`.
  - reward pill increased and separated from task text.
  - added progress bars for each task.
  - added progress fraction text such as `0/1`.
  - descriptions now truncate instead of overflowing/cramping.
- Daily tab behavior changed:
  - opening Daily hides the Play/table selection panel when not in a game.
  - pressing Play closes Daily and reopens the table menu.
- Added `CHANGELOG.md`.
- Added `UPDATE_MANIFEST.md`.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

### Files intentionally unchanged
- `WorldBuilder.lua`
- `Server.server.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`
- `UIStyle.lua`
- `Theme.lua`
- `Util.lua`

### Known limitations
- Daily tasks are still placeholder profile data.
- Tasks are not claimable from this panel yet.
- Daily task progress does not update from real gameplay yet because v0.2 gameplay is not built.
- This is still a renderer/UI foundation update, not a gameplay update.

### Revert instructions
To revert this update exactly, restore v0.1.2:
- `TableRush_v0.1.2_OpenMapPlayDailySpectate.zip`
- This removes the larger Daily panel, progress bars, subtitle, daily/hub visibility behavior, and changelog/manifest files.


## v0.1.4 — Daily Cards Actual Fix

### Purpose
Fix the actual Daily task card spacing problem and restore the Daily tab behavior the user liked from v0.1.2.

### Changed
- Bumped `Constants.VERSION` to `v0.1.4`.
- Rebuilt Daily task cards again, this time changing the internal card structure:
  - each task card is now 86px tall instead of 64px.
  - title gets a full top row.
  - progress count moved into a small top-right pill.
  - description gets its own middle row.
  - progress bar gets its own full-width row.
  - reward pill moved to the bottom row instead of crushing title/description text.
  - bottom helper text added: `Reward on completion` / `Complete — claim later`.
- Restored the Daily panel behavior from v0.1.2:
  - opening Daily no longer hides the Play/table menu.
  - `renderHub()` no longer forces the hub closed when Daily is open.
  - Daily is again a pull-up overlay, not a takeover panel.
- Kept v0.1.3's changelog/manifest tracking files.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `WorldBuilder.lua`
- `Server.server.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`
- `UIStyle.lua`
- `Theme.lua`
- `Util.lua`

### Known limitations
- Daily tasks are still placeholder profile data.
- Tasks are still not claimable from the Daily panel.
- Progress still does not update from real gameplay yet.
- The panel is UI-only polish; gameplay remains for v0.2.

### Revert instructions
- Revert to v0.1.3 to restore the previous larger-but-still-cramped Daily panel that hid the hub when opened.
- Revert to v0.1.2 to restore the first Daily panel and first Play/Daily dock behavior before progress bars/changelog were added.

