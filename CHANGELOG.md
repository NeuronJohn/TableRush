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


## v0.1.5 — Stability + Daily Redesign + First Action Loop

### Purpose
Fix console errors, replace the ugly Daily panel style with a cleaner dark-slate UI shell, and add the first tiny gameplay step so action cards affect a server-owned Dungeon Doors test state.

### Error fixes
- Removed `workspace.FallenPartsDestroyHeight` assignment from `WorldBuilder.lua`.
  - Studio/server scripts can lack permission to write this property, which caused: `lacking capability Plugin`.
- Fixed `TweenService:Create failed because Instance is null`.
  - `stroke()` now returns the created `UIStroke`.
  - hover tweens now check `cardStroke` before tweening.
- Fixed Rojo project mapping for `StarterPlayerScripts`.
  - Old mapping created a nested `StarterPlayerScripts/TableRushClient/TableRushClient` path.
  - New mapping places `TableRushClient.client.lua` directly inside `StarterPlayerScripts`.
  - You should still delete old duplicate Studio scripts/folders once before syncing.

### Daily UI changes
- Recolored the non-card UI shell away from brown/gold into dark slate/blue.
- Kept actual deck/action cards cream-colored.
- Rebuilt Daily as a cleaner side drawer on desktop/compact and bottom sheet on mobile.
- Rebuilt task cards:
  - taller `92px` task rows.
  - title, description, progress, and reward each have their own dedicated space.
  - reward no longer crushes text.
  - progress bar uses blue/green instead of heavy gold/brown.
  - card backgrounds use dark slate instead of brown.

### Gameplay foundation added
- Added `SubmitAction` remote.
- Server now creates a small Dusty Entry / Door Goblin test state when joining Dungeon Doors.
- Action cards now send real action requests:
  - `Step` cycles your zone.
  - `Strike` damages Door Goblin.
  - `Search` gives +1 Light and +25 pouch.
  - `Shield` gives +1 HP in the test loop.
  - `Scheme` adds +50 pot and +1 Threat.
- Door Goblin can be defeated; exit door changes from `LOCKED` to `EXIT`.
- Daily placeholder progress can update for Strike/Search/Shield tasks.

### Files changed
- `default.project.json`
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`
- `Theme.lua`
- `Util.lua`

### Known limitations
- This is not the full room system yet.
- It is a one-room server test loop, not simultaneous two-player action resolution.
- Spectate renders the board but cannot act.
- Daily claiming still does not exist yet.
- Custom/personal tables are still future placeholders.

### Revert instructions
- Revert to v0.1.4 to restore the previous brown/gold shell, centered Daily pull-up, no server action loop, and old Rojo nested mapping.
- Revert to v0.1.2 if you want the first Play/Daily/Spectate version before later Daily experiments.


## v0.1.6 — Play Menu Redesign + Centered Daily Pull-Up

### Purpose
Respond to the screenshot feedback: the Daily panel should stay centered near the bottom button, and the Play popup should stop using the ugly multi-card placeholder layout.

### Play menu changes
- Deleted the two future placeholder cards from the Play popup.
- Replaced the old card grid with a single focused `Dungeon Doors` table ticket.
- New Play popup includes:
  - large Dungeon Doors preview panel
  - small mini-board visual
  - table status chip
  - Room 1 test-loop chip
  - direct `Join Table` button
  - direct `Spectate` button
- Future table slots remain in the 3D world, not in the Play popup.

### Daily changes
- Daily panel is centered again near the Play/Daily dock.
- Removed the right-side drawer behavior from v0.1.5.
- Daily task rows adjusted to fit inside the centered pull-up without bottom clipping.
- Kept the cleaner slate theme and separated title/description/progress/reward layout.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `WorldBuilder.lua`
- `Server.server.lua`
- `UIStyle.lua`
- `Theme.lua`
- `Util.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`

### Known limitations
- Play popup is still a UI menu, not final art.
- Daily tasks still are not claimable.
- Only Dungeon Doors appears in Play popup for now.
- Gameplay remains the v0.1.5 Dusty Entry action test.

### Revert instructions
- Revert to v0.1.5 to restore the right-side Daily drawer and old multi-card Play popup.
- Revert to v0.1.4 to restore the older brown/gold Daily behavior before the slate/action-loop update.


## v0.1.7 — Spacing Lock + PC/Mobile Preview Pass

### Purpose
Fix the current layout problem before adding more gameplay: avoid overlapping UI, make mobile action cards scroll instead of clipping, keep Daily centered near the bottom button, and provide screenshot previews for PC and phone.

### Layout changes
- Action card row now uses a horizontal `ScrollingFrame`.
  - PC still fits all five cards.
  - Mobile/phone can scroll the action cards instead of cutting them off.
- Action card row moved upward when in-game:
  - prevents the bottom Play/Daily dock from sitting on top of the action cards.
- Daily opening now hides action cards while the Daily panel is open.
  - This avoids Daily panel/action-card overlap.
- Play and Daily panels are mutually exclusive.
  - Opening Daily closes the Play popup.
  - Opening Play closes Daily.
- Daily panel stays centered above the bottom dock.
  - Not a right-side drawer.
  - Not far from the Daily button.
- Daily task cards were tightened into a `quest slip` structure:
  - left accent stripe
  - title row
  - description row
  - progress bar row
  - reward row
  - no reward block crushing the body text

### Play popup changes
- Kept the v0.1.6 single Dungeon Doors ticket.
- Removed future game cards from the popup.
- Continued to expose Join and Spectate.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `WorldBuilder.lua`
- `Server.server.lua`
- `UIStyle.lua`
- `Theme.lua`
- `Util.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`

### Known limitations
- Screenshots are layout previews generated from the v0.1.7 dimensions, not live Roblox Studio renders.
- Gameplay remains the v0.1.5 Dusty Entry action test.
- Daily tasks are still not claimable.

### Revert instructions
- Revert to v0.1.6 to restore the old centered Daily sizing and non-scroll action row.
- Revert to v0.1.5 to restore the right-side Daily drawer and old play popup.


## v0.1.8 — Premium Table UI Direction

### Purpose
Replace the functional-but-ugly menu direction with a cleaner tabletop/card-game inspired UI direction.

### Design comparison influence
- Digital card games work best when the screen has one clear focal object and strong card readability.
- Tabletop-style games feel better when UI panels look like slates/tickets/boards instead of generic app grids.
- The Play UI is now one focused table ticket instead of multiple placeholder cards.
- Daily is now a compact quest board, not a cramped task spreadsheet.

### Play menu changes
- Rebuilt the Play popup as one premium `Dungeon Doors` table slate.
- Removed future placeholders from the popup.
- Added cinematic mini board/room tile preview inside the panel.
- Added clean status chips:
  - seated count
  - Room 1 test
  - Join or spectate
- Kept two clear actions:
  - Join Table
  - Spectate

### Daily changes
- Rebuilt Daily as compact quest slips:
  - accent stripe
  - short title
  - short description
  - progress bar
  - small count badge
  - separate reward block
- Reduced wording and visual clutter.
- Kept Daily centered near the bottom dock.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `WorldBuilder.lua`
- `Server.server.lua`
- `Theme.lua`
- `Util.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`

### Known limitations
- These previews still approximate Roblox UI; Studio may need a final spacing pass.
- Gameplay remains the v0.1.5/v0.1.7 Dusty Entry action test.
- Daily tasks are still not claimable yet.

### Revert instructions
- Revert to v0.1.7 to restore the previous spacing-lock UI with generated PC/mobile previews.
- Revert to v0.1.6 to restore the first single-ticket play menu but older Daily style.


## v0.1.9 — Bottom Sheet UI Lock

### Purpose
Fix the v0.1.8 preview problems after visually checking the screenshots: no more giant centered admin modal, no text bleeding into buttons, no phone chips overflowing, and no oversized Daily reward blocks.

### Play UI changes
- Play menu is now a bottom match-ticket sheet near the Play/Daily dock.
- Removed the giant centered empty modal feel.
- Desktop layout uses:
  - left tabletop preview slab.
  - right title/subtitle/status/actions area.
  - no description overlapping buttons.
- Mobile layout uses:
  - vertical bottom sheet.
  - compact tabletop preview.
  - chips resized to fit.
  - Join/Spectate buttons always inside bounds.

### Daily UI changes
- Daily is now a compact bottom quest drawer.
- Task rows reduced and cleaned up:
  - 62px rows.
  - thin accent stripe.
  - title and short description on left.
  - reward block is smaller and darker, not a giant yellow blob.
  - progress/count no longer fights the reward.
- Daily remains centered near the dock.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `Server.server.lua`
- `WorldBuilder.lua`
- `UIStyle.lua`
- `GameCatalog.lua`
- `DungeonDoorsSpec.lua`
- `Theme.lua`
- `Util.lua`
- `default.project.json`

### Known limitations
- Generated previews are still approximations, but the layout logic now directly matches the intended bounds.
- Gameplay remains the Dusty Entry action test.
- Daily claiming is not implemented.

### Revert instructions
- Revert to v0.1.8 to restore the centered single-slate Play modal and quest-slip Daily panel.
- Revert to v0.1.7 to restore the spacing-lock version before the premium UI direction.

## v0.2.0 — Landscape UI Lock + Bounded Button Layout

### Purpose
Lock the phone/tablet direction to landscape and rebuild the Play/Daily UI with strict parent bounds so text and buttons do not hang off cards/panels.

### Orientation decision
- Phone/tablet gameplay is now landscape-first.
- Portrait phones show a `Rotate to play` overlay instead of squeezing the card game into portrait.
- Reason: Table Rush is a board/card game; landscape gives the board center space and keeps the hand/buttons readable.

### Play UI changes
- Rebuilt `TableRushClient.client.lua` around a stricter bottom-sheet layout.
- Play panel is a fixed bottom landscape ticket.
- All child elements use bounded rows:
  - fixed preview area
  - fixed status chip row
  - fixed button row
- Mobile landscape has a separate layout branch.
- Join/Spectate buttons are inside the ticket bounds on both desktop and mobile landscape.
- Removed the previous over-complicated generated UI structure that let chips/text collide.

### Daily UI changes
- Daily panel is a fixed bottom drawer centered above the dock.
- Each task row uses strict columns:
  - left accent stripe
  - title/description/progress area
  - compact reward box
- Rewards are no longer giant yellow blocks.
- Daily and Play panels are mutually exclusive.
- Opening Daily hides action cards to avoid overlap.

### Action card layout changes
- Action cards use a horizontal `ScrollingFrame`.
- Mobile landscape scrolls the hand instead of clipping.
- Action cards stay above the Play/Daily dock.

### Stability
- Keeps the v0.1.5 server Dusty Entry action loop.
- Keeps Join/Spectate prompts and open map.
- Keeps direct StarterPlayerScripts Rojo mapping.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/ReplicatedStorage/TableRush/Shared/GameCatalog.lua`
- `src/ReplicatedStorage/TableRush/Shared/DungeonDoorsSpec.lua`
- `src/ReplicatedStorage/TableRush/Shared/Theme.lua`
- `src/ReplicatedStorage/TableRush/Shared/Util.lua`

### Known limitations
- Daily claiming is still not implemented.
- This is still the Dusty Entry / Door Goblin test loop, not the full 6-room run.
- Portrait is intentionally blocked with a rotate prompt.

### Revert instructions
- Revert to v0.1.9 to restore the previous portrait-preview-capable bottom sheet UI.
- Revert to v0.1.8 to restore the previous premium centered slate design.

## v0.2.1 — Play Scroll Sections + Padding Fix

### Purpose
Fix the screenshot issue where Play buttons touched/overlapped the ticket border, improve Daily readability, and lock the future Play tab organization.

### Play tab organization
The Play tab is now ordered as:
1. `Quick Play` — game-made quickplay tables first.
2. `Friends' Hosted Tables` — player-hosted tables from friends second.
3. `Other Hosted Tables` — all other public/player-hosted tables last.

### Play UI changes
- `PlayContent` is now a vertical `ScrollingFrame`.
- The Play panel is slightly larger, but still a bottom sheet.
- Added safe padding inside the scrolling content.
- Rebuilt table tickets with a reusable padded layout.
- Buttons now live inside a dedicated padded button row.
- Join/Spectate no longer touch or hang off the card border.
- Added placeholders proving future scroll order:
  - Next Table Game
  - Friends' tables
  - Public hosted tables

### Daily UI changes
- Kept the closer-to-ready Daily direction.
- Blue side highlight is thinner and inset.
- Task title text increased.
- Task description text increased.
- Reward text increased.
- Row height increased slightly for safer breathing room.
- More padding around title/description/progress/reward.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/ReplicatedStorage/TableRush/Shared/GameCatalog.lua`
- `src/ReplicatedStorage/TableRush/Shared/DungeonDoorsSpec.lua`
- `src/ReplicatedStorage/TableRush/Shared/Theme.lua`
- `src/ReplicatedStorage/TableRush/Shared/Util.lua`

### Known limitations
- Hosted tables are placeholders only.
- Friend/public hosted table filtering is UI-scaffolded but not backed by server matchmaking yet.
- Daily claiming is still not implemented.
- Gameplay is still the Dusty Entry test loop.

### Revert instructions
- Revert to v0.2.0 to restore the previous single-ticket Play panel and previous Daily row sizing.

## v0.2.2 — Daily Tasks Claim + Readability Fix

### Purpose
Fix the Daily UI from the screenshot: text was too small, left highlights were too tall/ugly, rewards could not be claimed, and the task list needed a real seeded daily system.

### Daily UI changes
- Daily task text is larger:
  - title increased to 15
  - description increased to 12
  - reward/claim text increased to 12
- Removed the tall left color bars.
- Replaced the side bar with a small status dot.
- Daily list is now a vertical `ScrollingFrame`.
- Daily panel is slightly larger but remains centered near the dock.
- Task rows are taller with safer padding.
- Reward box is now also the claim button:
  - incomplete tasks show reward value
  - complete tasks show `Claim Reward`
  - claimed tasks show `Claimed`

### Daily system changes
- Added `ClaimDailyTask` remote.
- Server now generates a seeded daily task list:
  - same task list for everyone on the same UTC date
  - 4 easy tasks
  - 2 medium tasks
  - 1 hard task
  - final slot is either medium or a rare high-roll task
- Added a larger task pool with easy, medium, hard, and rare tasks.
- Daily task progress now supports shared tracking keys, so multiple tasks can progress from the same action.
- Claiming a finished task adds coins and tickets to the profile.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/ReplicatedStorage/TableRush/Shared/GameCatalog.lua`
- `src/ReplicatedStorage/TableRush/Shared/DungeonDoorsSpec.lua`
- `src/ReplicatedStorage/TableRush/Shared/Theme.lua`
- `src/ReplicatedStorage/TableRush/Shared/Util.lua`

### Known limitations
- Daily data is still in-memory profile data, not DataStore saved yet.
- Server uses UTC date for daily seed.
- Rare/high-roll tasks can appear before the full game has enough content, but they progress from the current action test loop.
- Hosted table system is still placeholder UI only.

### Revert instructions
- Revert to v0.2.1 to remove claim buttons and return to the previous Daily UI.

## v0.3.0 — Game Loop, Event Cards, Backpack, and Hand Fix

### Purpose
Start turning Dungeon Doors from a UI test into an actual table/card game loop while fixing the hand clipping problem.

### Hand/card fixes
- Action hand has more vertical space.
- Action scroll no longer clips hover scale.
- Cards now sit with a slight fan rotation.
- Hover straightens and subtly scales the card instead of growing into the frame edge.
- Action cards hide when:
  - it is not time to act
  - a move/door choice is open
  - Daily/Play/Backpack is open
  - a pending equipment decision is open

### Gameplay loop added
- Added real room/tile board state on the server.
- Rooms now contain different tile counts and tile types:
  - Start
  - Enemy
  - Trap
  - Treasure
  - Discovery
  - Exit
- Added six-room structure:
  1. Dusty Entry
  2. Crooked Hall
  3. Mimic Storage
  4. Lantern Shrine
  5. Chained Exit
  6. Doorwarden's Vault
- Step now opens a center-screen tile choice UI.
- Movement choices are server-validated.
- Reaching an exit opens a center-screen door choice UI.
- Door choices load the next room.
- Partner catch-up/waiting is represented in the room flow; the test loop auto-catches the partner up so solo testing does not hard-lock.

### Event/card popups
- Added animated event popup cards for:
  - room reveal
  - enemy reveal
  - trap
  - treasure
  - discovery
  - door choice
  - item/equipment
  - victory/test completion
- Phase and event changes still broadcast through the ticker.

### Backpack/equipment added
- Added Backpack button and panel.
- Backpack displays item cards.
- Added item types:
  - Weapon
  - Armor
  - Boots
  - Consumable
  - Key/passive
- Equipment slots:
  - Weapon
  - Armor
  - Boots
- If you find gear for an occupied slot, the game asks whether to equip it or keep the old gear.
- Consumables can be used from the backpack.
- Equipped weapon changes Strike damage.
- Boots reduce trap damage in the current loop.

### Server remotes added
- `SubmitChoice`
- `BackpackAction`

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `README.md`

### Files intentionally unchanged
- `default.project.json`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `src/ReplicatedStorage/TableRush/Shared/UIStyle.lua`
- `src/ReplicatedStorage/TableRush/Shared/GameCatalog.lua`
- `src/ReplicatedStorage/TableRush/Shared/DungeonDoorsSpec.lua`
- `src/ReplicatedStorage/TableRush/Shared/Theme.lua`
- `src/ReplicatedStorage/TableRush/Shared/Util.lua`

### Known limitations
- This is still one-player-testable server state, not full real two-player simultaneous lock-in yet.
- Partner catch-up is simulated for now.
- Final vault is still a placeholder after the Doorwarden room.
- The backpack is in-memory only; no DataStore saving yet.
- Tile visuals are simple 3D tabletop pieces, not final art.

### Revert instructions
- Revert to v0.2.2 to remove the room/tile loop, backpack, event cards, and new hand behavior.

## v0.4.0 — Adventure Engagement + Table-Click Loop

### Purpose
Make Dungeon Doors more interactive and engaging instead of feeling like a flat UI test. Movement and door choice now happen on the actual table, while event cards are reserved for real game moments.

### Interaction changes
- Removed center-screen movement UI for normal tile movement.
- Step now highlights reachable tiles directly on the tabletop.
- Players click glowing table tiles to move.
- Exit doors glow on the actual tabletop and are clicked directly.
- Center choice UI remains only for equipment replacement decisions.

### Engagement and atmosphere
- Added more room types:
  - Whisper Hall
  - Black Candle Room
  - Flooded Crypt
  - Spider Pantry
  - plus the existing dungeon rooms and boss vault
- Added progressive room difficulty weighting.
- Early rooms are more likely to be easy/medium.
- Later rooms increasingly pull harder, scarier, and richer rooms.
- Boss vault remains the late-run endpoint.
- Rooms now carry atmosphere data:
  - table color
  - glow color
  - material
  - room sound hook
  - simple room props

### Vibe and animation
- Event cards are only for real events:
  - enemy reveal
  - trap snap
  - treasure
  - discovery
  - combat
  - equipment
  - room reveal
  - victory
- No event card for “choose move” or “your turn.”
- Added danger flash for enemy/trap/combat moments.
- Added room/event sound hooks.
- Added more material/color variation to the table and tiles.
- Added simple prop primitives for room flavor.

### Gameplay changes
- Enemies now increase Threat when revealed.
- Enemies counterattack if not defeated.
- Armor can block counterattacks.
- Boots can reduce trap damage.
- Treasure can trigger equipment replacement.
- Door choices route into different room likelihoods.

### Hand/card fixes
- Increased action hand frame space.
- Reduced hover scale to prevent clipping.
- Kept the fan/straighten hover feel.
- Hand hides when table tile/door choice is active, so it does not distract.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

### Known limitations
- Sound asset IDs are placeholder Roblox sound hooks and may need final curation.
- Clickable table parts are client-rendered ClickDetectors for the current prototype.
- True two-player simultaneous lock-in is still not finished.
- Room art is still primitive-based, but now has stronger material/color/prop direction.

### Revert instructions
- Revert to v0.3.0 to remove table-click movement, room atmosphere, danger flash, expanded room pool, and stronger event flow.

## v0.4.1 — Reliable Table Movement

### Purpose
Fix the v0.4.0 movement issue. Movement now uses client camera raycasting against the rendered table parts instead of fragile ClickDetector-based clicking.

### Changes
- Added camera raycast table input for mouse and touch.
- Rendered table parts now carry click metadata.
- Clicking/tapping glowing tiles sends `TableClick` to the server.
- Clicking/tapping glowing doors sends `TableClick` to the server.
- Direct neighbor tiles glow and can be clicked without needing Step first.
- Step remains as a movement helper/highlighter.
- Server validates reachable movement before moving.
- Event popups remain reserved for actual game events, not movement prompts.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.0 — Challenge Adventure Run

### Purpose
Make Dungeon Doors a harder, longer, more replayable adventure loop with more rooms, one-action turns, room-specific RNG, table camera lock, and route voting.

### Major changes
- 15-room standard run.
- Secret/special discoveries can extend runs up to 18 rooms.
- 40-room themed room pool.
- Progressive difficulty weighting.
- One action per turn.
- Step required before movement.
- Simulated partner wait/resolution for solo testing.
- Locked top-down table camera.
- Larger movement hit areas.
- Door route voting UI.
- Split-vote wheel animation.
- Room-specific Search and Scheme outcome tables.
- Stronger enemy/trap/threat pressure.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.1 — Route Roll and Map Polish

### Purpose
Fix the route resolver and improve the world/table presentation without adding fragile custom assets.

### Route Roll
- Replaced the bad `Route Tie` name with `Route Roll`.
- Route Roll only appears when a new split route vote happens.
- It no longer stays visible or replays on every render/action.
- Rebuilt the resolver as a 50/50 color-coded wheel:
  - blue = active player route
  - gold = teammate route
- The wheel spins once, announces the winning side, then hides.

### Map and tabletop polish
- Join/Spectate trigger parts are now invisible and non-colliding.
- Added safe primitive-only detail:
  - table trim
  - inset/rune lines
  - candles and small flame balls
  - coin cylinders with simple top labels
  - crates
  - mini chest
  - low arch silhouettes
  - walkway/floor detail
  - small lamp posts
- Kept details simple to avoid fragile formatting or broken meshes.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `src/ServerScriptService/TableRush/WorldBuilder.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.2 — Daily Colors, Teammate Purple, and Silent Sound Hooks

### Purpose
Fix Daily task contrast issues, move teammate identity away from gold, and remove invalid/annoying placeholder sounds.

### Daily UI changes
- Cleaned up Daily task tier color contrast.
- Hard tasks now use red instead of gold/yellow.
- Rare tasks use purple.
- Medium tasks use green.
- Easy tasks use blue.
- Incomplete reward buttons use a safer dark button style.
- Complete Claim buttons use a readable green success style.
- Progress counts use readable light text instead of clashing with tier colors.

### Teammate color changes
- Teammate identity color changed from gold to purple.
- Route Roll now uses:
  - blue = active player route
  - purple = teammate route
- Teammate mats/tokens use purple.
- Gold remains reserved for coins, treasure, and reward objects.

### Sound changes
- Removed invalid placeholder sound asset IDs that caused Studio warnings.
- Disabled event sound playback by default.
- Disabled looping room ambience by default.
- Added `SOUND_ASSET_SETUP.md` with Creator Store search terms and safe sound slot guidance.

### Client stability note
- Restored the client from the last complete UI/rendering branch before applying v0.5.2 changes, because the packaged v0.5.1 client was missing some render function definitions.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
- `SOUND_ASSET_SETUP.md`

## v0.5.3 — Hide Join Prompts During Sessions

### Purpose
Stop Join/Spectate prompts from showing while the player is already actively playing or spectating Dungeon Doors.

### Changes
- Added a client-side prompt visibility controller.
- When `state.activeGame == DungeonDoors`, local Join/Spectate ProximityPrompts are disabled.
- When the player is not in an active Dungeon Doors session, the prompts are re-enabled.
- The controller runs during normal render updates and immediately after game render payloads.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.4 — Room Action Limits, Enemy Turns, and Tile Detail

### Purpose
Add real room-level limits for Search/Scheme, make combat feel like a turn exchange, and improve room tile variety using safe simple parts.

### Room action limits
- Search is once per room total, shared by both players.
- Scheme is once per room total, shared by both players.
- If one player uses Search, the teammate cannot Search in that same room.
- If one player uses Scheme, the teammate cannot Scheme in that same room.
- Search/Scheme limits reset when the next room loads.
- Trying to use a spent Search/Scheme does not burn the turn.

### Client UI
- Search/Scheme cards show `USED THIS ROOM` after being spent.
- Spent room cards are visually muted.
- Clicking a spent room card only shows feedback instead of sending the action.
- Visible tile highlight is closer to the room tile size.
- Invisible click pad remains forgiving but no longer creates a giant visible highlight.

### Combat update
- Enemies no longer instantly counterattack inside the Strike card.
- If an enemy survives, the game enters an `Enemy Turn`.
- Enemy attack resolves as its own scene/event.
- After the enemy turn, the simulated teammate wait resolves, then your next turn starts.

### Table room detail
- Added simple block/rectangle details to revealed tiles:
  - treasure chests
  - trap spikes
  - rune/discovery markers
  - exit frames
  - start banners
  - fog slabs on hidden tiles
  - rotated clutter blocks
- Uses simple parts only, no fragile model/mesh dependency.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.5 — Unique Room Layouts

### Purpose
The table rooms were too samey: same square size, same clutter boxes, same positions, and player tokens clipping into decorations. This update rebuilds the room tile renderer around varied simple part layouts.

### Room layout changes
- Each room tile now gets deterministic layout metadata from the server.
- Tiles can render as:
  - square
  - wide
  - tall
  - thin
  - split
  - alcove
  - entry
  - gate
  - L-shaped
- Shapes are built from simple connected rectangular parts only.
- No complex meshes or fragile custom models.

### Decoration changes
- Decorations are now placed in safe edge/corner zones instead of the token center lane.
- P1/P2 tokens should no longer clip through the same box setup every room.
- Clutter count varies per tile.
- Clutter positions vary per tile.
- Clutter rotation varies per tile.
- Clutter sizes vary per tile.
- Hidden tiles use fog slabs that match the tile size.

### Highlight changes
- Visible movement glow follows the tile shape more closely.
- Invisible click pads remain forgiving.
- The giant visible highlight overlay is avoided.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.6 — Stable Readable Cards and Door Choice Flow

### Purpose
Fix action card hover behavior, improve text readability, and remove the unnecessary exit popup card.

### Card fixes
- Action cards now render inside stable outer slots.
- Hover scaling affects the whole card together instead of moving text independently.
- Hover no longer changes card rotation.
- Neighboring cards should not reflow when a card is hovered or selected.
- Card text sizes were increased.
- Action tag labels have more height.
- Card body text has safer spacing.

### Button/text readability
- Door/equipment choice buttons are larger.
- Choice labels are larger and wrapped.
- Choice panel is wider so route options fit better.

### Exit flow
- Reaching an exit no longer shows an event popup card.
- The door/route options are now the event equivalent.
- Client also ignores accidental Door popup payloads.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.7 — Delayed Route Roll Resolution

### Purpose
Fix split route voting so the next room does not load before the Route Roll animation finishes, and clean up overlapping Route Roll text.

### Route Roll timing
- Split route votes now create `RouteWheel` state and stay on the current room.
- The winning route is stored as `PendingRouteChoice`.
- The server sends the Route Roll state first.
- The next room loads after a short delay matching the client wheel animation.
- Route choice UI hides while Route Roll is active.

### Route Roll UI
- Route Roll panel is taller.
- Wheel sits higher with more breathing room.
- Result text moved below the wheel.
- Player/teammate labels moved away from the pie chart.
- Copy updated to make the roll state clearer.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.8 — Monster Run Away Movement Rule

### Purpose
Prevent players from walking deeper into undiscovered rooms while standing on a live monster. If a monster is on the current tile, movement should mean retreating/running away, not exploring forward.

### Changes
- Added server-side `currentTileHasLiveMonster(state)` helper.
- `availableMoves(state)` now checks whether the current tile has a live enemy.
- If a live monster is present:
  - only revealed neighboring tiles are returned as valid movement options
  - unrevealed/unknown neighboring tiles are blocked
  - Step is treated as Run Away behavior
- If no revealed escape tile exists, the turn is not burned.
- Invalid movement feedback now explains the monster movement restriction.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.5.9 — Orthogonal Themed Room Layouts

### Purpose
Redo the table room visuals so the room maps feel more deliberate, fluent, and theme-driven while staying simple and safe.

### Layout changes
- Tile rotations are snapped to 0/90/180/270 degrees.
- Decoration rotations are snapped to 0/90/180/270 degrees.
- Removed special Start/Entry shape styling.
- Removed special Exit/Gate shape styling.
- Start and Exit tiles now use the same room shape language as other tiles.
- The final boss vault is the only exception allowed to look like a special exit/vault.

### Room flow changes
- Added orthogonal corridor slabs between connected revealed/clickable rooms.
- Corridors use straight or L-shaped 90-degree segments.
- This makes the map feel like a connected dungeon instead of detached plates.

### Theme prop changes
- Props now use room theme profiles:
  - candles/ruins
  - mist/stones
  - web/crates
  - spikes/pressure plates
  - coins/crates
  - chains/blocks
  - water/stones
  - mushroom blocks
  - ember blocks
  - bone slabs
  - rune stones
  - metal crates
  - vault blocks
  - holy cache
  - broken floor
- Props stay mostly cubes/rectangles.
- No angled clutter.
- Props stay in edge/corner slots so player tokens do not clip through them.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.6.0 — Correct Connected Room Movement

### Purpose
Fix the mismatch between what the table visually shows and what movement allows. Diagonal-looking rooms were being treated as connected because old template neighbor data was still being used.

### Movement changes
- Added server-side room layout normalization.
- Added server-side orthogonal neighbor rebuilding.
- Movement is now based on adjacent grid positions only:
  - left
  - right
  - up
  - down
- Diagonal tiles are not valid moves.
- A fork only connects to the room physically adjacent to it.
- A center room correctly connects to the up/down/right/left rooms around it when they are physically adjacent.
- Monster run-away movement still respects revealed-only retreat rules.

### Visual cleanup
- Cleaned up gray/stone-looking corridor chunks.
- Corridors now use smoother materials.
- Corridor/floor colors now lerp toward the current room theme/glow color.
- Hidden fog slabs are less chunky and less stone-textured.
- Tile sub-shapes use more consistent theme-fit colors.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.6.1 — Theme Consistent Props and Visible Corridor Previews

### Purpose
Clean up off-theme prop colors and make hallway connections visible before a room is opened.

### Visual color cleanup
- Added theme-tinting for normal prop/decor parts.
- Random gray/blue/stone chunks are pulled toward the active room color/glow.
- Gold treasure accents remain gold.
- Danger/red accents remain readable.
- Hidden fog slabs are softer and less chunky.
- Tile sub-shape contrast is reduced so rooms feel more cohesive.

### Corridor visibility
- Corridors are now visible for all real neighbor connections.
- Revealed-to-revealed corridors are strongest.
- Revealed-to-clickable corridors are medium.
- Revealed-to-hidden corridors are softer previews.
- Hidden-to-hidden corridors are very soft, but still help the map read as connected.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.6.2 — Text, Color, Room Spacing, and Solid Hallways

### Purpose
Fix label overlap, remove ugly off-theme pale yellow slabs, reduce room clipping, and make known hallways solid instead of faint.

### Text/layout fixes
- Room labels are smaller.
- Hidden `?` labels use a smaller footprint.
- Revealed labels are staggered vertically to reduce overlap.
- P1/P2 labels are smaller and lifted above the tokens.
- Player tokens are pulled closer to room center.
- Route choice panel is moved lower so it covers less map text.
- Route choice button text remains readable but less dominant.

### Color fixes
- Replaced harsh pale yellow/off-white tile coloring.
- Start/Exit/safe tiles now use theme-tinted colors.
- Treasure tiles keep a warm accent without turning the room into a pale yellow slab.
- Normal prop chunks are pulled harder toward the active room theme color.

### Room clipping fixes
- Server tile layout max sizes reduced.
- Client clamps old tile layout dimensions defensively.
- L-shape, split, and alcove extra pieces are smaller.
- Room spacing increased slightly.
- Corridors use matching updated spacing.

### Hallway visibility
- Real connected hallways are now fully visible with 0 transparency.
- Hallways to undiscovered visible rooms are solid too.
- Corridor colors are stronger but still tied to the room theme/glow.
- Movement validity is still controlled by the server; visible halls do not bypass movement rules.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.6.3 — Inset Room Texture

### Purpose
Bring back the more appealing layered room look from the earlier approach by adding a slightly darker inner room panel inside each tile.

### Visual changes
- Added an inset inner panel inside each room tile.
- The inset is slightly darker than the outer room color.
- The inset rotates with the room tile and stays inside the tile bounds.
- Clickable/active rooms keep the same inset treatment without changing movement rules.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.6.4 — Ticker and Card Hover Polish

### Purpose
Fix the status/turn ticker overlapping the action cards and make card hover feel better.

### Ticker changes
- Moved the turn/status ticker higher above the action hand.
- Adjusted multiple responsive layout positions so it stays clear of cards.

### Card spacing and hover changes
- Reduced stable slot gutter width.
- Reduced action card list padding.
- Cards now sit closer together.
- Hover scale increased to make cards feel more responsive.
- Selected card scale increased slightly.
- Hover uses `UIScale` on the whole card, so text/icons/tags scale together.
- Hovered card raises its ZIndex so the zoom is visible without forcing hand reflow.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.1 — Rollback to Board Figure Direction

### Purpose
Reject the v0.8.0 full-avatar physical room branch and restore the good tabletop room/tile direction from v0.6.4.

### Direction lock
- The player should control a miniature board figure, not walk their real Roblox avatar around the dungeon.
- Rooms should stay as tabletop tiles/mini-rooms with props and strong visual identity.
- Puzzle objects should be miniature physical board objects placed inside the room/tile world.
- Future interactions should be proximity/position/object based, but still in the board-game miniature style.

### Added
- WASD board-figure movement helper for movement phases.
- WASD attempts to move/select the legal connected board tile in the pressed direction when Move/Run Away is active.
- No full-avatar explorer code is included.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.2 — UI Stability Lock

### Purpose
Fix the broken, overlapping UI before adding more gameplay. This pass is about making the interface stable, readable, and non-flashing.

### UI rules enforced
- No text-size flashing during hover.
- No text-transparency flashing during hover.
- Text is wrapped with padding.
- Text/buttons get minimum heights.
- Cards sit inside stable outer slots.
- Hover only scales the whole card; the text does not independently resize.
- Action area gets a padded safe panel.
- Status ticker gets a padded safe text area.
- Route/choice buttons are larger and moved into safer space.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.3 — Board Interaction + UI Reframe

### Purpose
Fix the pointless WASD helper, remove generic Scheme, make Interact/context actions matter, and reframe the UI away from tiny cards.

### Gameplay fixes
- WASD now fires `TableClick` with the chosen legal connected tile.
- E triggers context interaction:
  - Fight if on a live enemy tile
  - Interact if the current tile has an actual object/use
  - Search if the current tile can be searched
- Search is now once per tile, team-shared.
- Teammate cannot search a tile already searched by the player.
- Scheme is no longer an always-visible command.
- Interact only appears when the current tile actually supports an object/action.
- Route/door choices are locked while any revealed monster is alive.

### UI fixes
- Action area is now a short command bar, not tall cards.
- Buttons are wider and shorter.
- No hover scaling/text flashing.
- Stable padded text inside each command.
- Ticker moved for the shorter command bar.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/ReplicatedStorage/TableRush/Shared/DungeonDoorsSpec.lua`
- `src/ServerScriptService/TableRush/Server.server.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.4 — Client Render Hotfix

### Purpose
Fix the v0.8.3 client crash:
`Players...TableRushClient:2353: attempt to call a nil value`

### Fixes
- Restored missing `renderLayout()`.
- Restored missing `updateTableCamera()`.
- Added missing `cameraViewport()`.
- `renderActions(fake)` now falls back to `state.fakeState`.
- `renderAll()` now calls `renderActions(state.fakeState)`.
- Added defensive render guard so missing render helpers cannot hard-crash.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.5 — Command Bar Compatibility Hotfix

### Purpose
Fix the v0.8.4/v0.8.3 command bar crash:
`TableRushClient:2301: attempt to call a nil value` inside `renderActions`.

### Root cause
The rebuilt command bar called helper names/signatures that did not exist in the original client:
- `clearChildren()` was called, but the original helper is `clear()`.
- `corner()` was called, but the original helper is `round()`.
- Some `stroke()` calls used color/thickness arguments in the wrong order.

### Fixes
- Added `clearChildren(frame)` alias.
- Added `corner(obj, radius)` alias.
- Made `stroke()` support both argument orders.
- Changed `renderActions()` to call `clear(actionLayer)` directly.
- Added defensive nil guard on submit remote in command button click.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`

## v0.8.6 — Luau Scope RenderActions Hotfix

### Purpose
Fix the `renderActions()` crash:
`TableRushClient:2332: attempt to call a nil value`

### Root cause
`renderActions()` called `cameraViewport()`, but `cameraViewport()` was declared later as a local function. In Luau, a later local function is not visible to an earlier function unless it is forward-declared.

### Fixes
- Replaced `cameraViewport()` inside `renderActions()` with the already-existing earlier `viewport()` helper.
- Added a comment warning future patches not to use later local helpers from earlier functions.
- Added defensive submit-remote guards for E/context actions.

### Files changed
- `src/ReplicatedStorage/TableRush/Shared/Constants.lua`
- `src/StarterPlayer/StarterPlayerScripts/TableRushClient.client.lua`
- `README.md`
- `CHANGELOG.md`
- `UPDATE_MANIFEST.md`
