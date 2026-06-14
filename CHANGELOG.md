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
