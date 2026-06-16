# Table Rush

**Table Rush** is a Roblox tabletop/card-game prototype built with Rojo. The current featured table game is **Dungeon Doors**, a cooperative dungeon board/card game where players move through room tiles, reveal events, fight enemies, collect loot, manage equipment, and progress through a multi-room run.

The long-term direction is a social tabletop hub: one Roblox world with multiple table games, quickplay tables, friend-hosted tables, public hosted tables, daily tasks, progression, and future personal table spaces.

## Current Build

**Current version:** `v0.3.0`

Current core features:

- Open Table Rush world with interactive table points
- Dungeon Doors as the first playable table game
- Quick Play and Spectate flow
- Scrollable Play menu structure for:
  - game-made quickplay tables
  - friends’ hosted tables
  - public hosted tables
- Server-owned gameplay state
- Room/tile movement
- Center-screen movement and door choices
- Animated event card pop-ups
- Backpack and equipment system
- Seeded daily tasks with claimable rewards
- 3D tabletop presentation for players and spectators

## Dungeon Doors

Dungeon Doors is the first table game inside Table Rush. It is designed as a cooperative 2-player dungeon board/card game, while still being solo-testable during development.

Current gameplay loop:

1. Join or spectate the Dungeon Doors table.
2. Use action cards to make decisions.
3. Move across room tiles.
4. Reveal events such as enemies, traps, treasure, discoveries, and exits.
5. Fight enemies with Strike.
6. Use Search, Shield, Scheme, and Step.
7. Collect items into a backpack.
8. Equip weapons, armor, and boots.
9. Use consumables.
10. Choose whether to replace existing equipment when finding better gear.
11. Reach exits and choose the next door/room path.
12. Progress through a six-room dungeon scaffold.

The teammate flow is represented in the game state. For development testing, the partner currently catches up automatically so the loop can be tested without needing a second active player every time.

## Project Structure

```text
src/
  ReplicatedStorage/
    TableRush/
      Shared/
        Constants.lua
        DungeonDoorsSpec.lua
        GameCatalog.lua
        Theme.lua
        UIStyle.lua
        Util.lua

  ServerScriptService/
    TableRush/
      Server.server.lua
      WorldBuilder.lua

  StarterPlayer/
    StarterPlayerScripts/
      TableRushClient.client.lua
```

## Main Systems

### Server-Owned Gameplay

The server manages the important gameplay state:

- player profile data
- joined table state
- Dungeon Doors room state
- room and tile data
- player tile position
- enemy HP
- trap, treasure, discovery, and exit outcomes
- backpack inventory
- equipped items
- daily task progress
- reward claiming

The client renders the UI and table presentation from server-sent state.

### Client UI

The client handles:

- PC / compact / mobile-landscape layout
- portrait-phone rotate overlay
- Play menu
- Daily task drawer
- action card hand
- center choice panel
- animated event card pop-ups
- backpack panel
- player status mats
- ticker-style event broadcasts
- 3D tabletop room rendering

The mobile direction is landscape-first because Table Rush is a card/table game and needs horizontal space for the board, action hand, and choice UI.

### Room and Tile System

Dungeon Doors uses room templates with different tile layouts. Tiles can be:

- Start
- Enemy
- Trap
- Treasure
- Discovery
- Exit

Current room scaffold:

1. Dusty Entry
2. Crooked Hall
3. Mimic Storage
4. Lantern Shrine
5. Chained Exit
6. Doorwarden’s Vault

Rooms support different tile counts and branching door choices. The structure is built so procedural rooms, stronger enemy systems, and additional table games can be layered in later.

### Event Cards

Events are presented through animated card pop-ups. These are used for:

- room reveals
- enemy reveals
- trap triggers
- treasure finds
- discoveries
- door choices
- item and equipment events
- run completion events

The goal is to keep gameplay readable for the active player while still giving spectators a clear table presentation.

### Backpack and Equipment

The backpack system supports collected items, equipment slots, and replacement decisions.

Current item categories:

- Weapon
- Armor
- Boots
- Consumable
- Key/passive

Current equipment slots:

- Weapon
- Armor
- Boots

When the player finds an item that would replace an equipped item, the game asks whether to equip the new item or keep the current one.

Example items:

- Rusty Sword
- Iron Sword
- Wool Boots
- Iron Boots
- Leather Armor
- Small Potion
- Brass Key

### Daily Tasks

Daily tasks are generated from a seeded server-side task pool. Players get the same task list on the same UTC date.

The current task pool includes:

- easy teaching tasks
- medium repeat tasks
- hard challenge tasks
- rare high-roll tasks

Completed tasks can be claimed for coins and tickets.

### Play / Table Structure

The Play menu is organized for the future hosted-table system:

1. **Quick Play**  
   Game-made quickplay tables.

2. **Friends’ Hosted Tables**  
   Player-hosted tables from friends.

3. **Other Hosted Tables**  
   Public/player-hosted tables from everyone else.

The hosted table sections are currently UI scaffolding. Full matchmaking, friend filtering, and persistence are future work.

## Skills Demonstrated

This project shows practical Roblox development across gameplay, UI, server-client architecture, and product design.

### Roblox Engineering

- Rojo project structure
- ModuleScript organization
- ServerScriptService / ReplicatedStorage / StarterPlayerScripts workflow
- RemoteEvent communication
- server-owned gameplay state
- ProximityPrompt table interactions
- dynamic Workspace object generation
- BillboardGui and ScreenGui use
- responsive Roblox UI layouts

### Gameplay Programming

- action-card gameplay loop
- room and tile exploration
- server-validated movement choices
- branching door choices
- enemy encounters
- trap and treasure events
- item drops
- backpack inventory
- equipment slots
- equipment replacement prompts
- consumable item usage
- daily task progression
- reward claiming

### UI / UX Implementation

- bottom navigation
- scrollable table selection
- daily task drawer
- action card hand
- center-screen choice UI
- animated event card pop-ups
- backpack item panel
- player status displays
- event ticker feedback
- portrait rotate overlay for mobile
- spectator-friendly table presentation

### Product and Systems Design

- multi-game tabletop hub direction
- quickplay and hosted-table structure
- social table-game foundation
- progression and daily reward loops
- systems designed for expansion without requiring a full rewrite
- solo-testable gameplay loop for faster iteration

## Version Milestones

Only major milestones are listed here.

### v0.1.0 — Table Rush Foundation

- Fresh Rojo project
- Table Rush world foundation
- Dungeon Doors as the first table game
- Basic table renderer
- First Play/Daily UI structure
- Early table interaction flow

### v0.2.0 — Landscape UI and Table Flow

- Landscape-first phone/tablet direction
- Portrait rotate overlay
- Play/Daily bottom-panel structure
- Scrollable action hand
- Quick Play / hosted-table menu structure
- Claimable seeded daily task foundation

### v0.3.0 — Dungeon Doors Gameplay Loop

- Server-owned room/tile gameplay
- Movement choices
- Door choices
- Enemies, traps, treasure, discovery, and exits
- Animated event cards
- Backpack and equipment system
- Equipment replacement decisions
- Six-room Dungeon Doors scaffold

### v0.4.0 — Adventure Engagement Loop

- Clickable table tiles and doors
- No center movement UI for normal movement
- Stronger room atmosphere through color, material, props, sounds, and danger flashes
- More room types with progressive difficulty weighting
- Event popups reserved for actual game moments
- Enemy counterattacks, traps, treasure finds, discoveries, and boss-route escalation
- Improved action hand spacing and hover behavior

## Current Limitations

This is still an early prototype.

Known limitations:

- Data is in-memory only; DataStore saving is not implemented yet.
- True two-player simultaneous lock-in is not finished.
- Partner catch-up is simulated for solo testing.
- Hosted table matchmaking is UI-scaffolded but not fully implemented.
- Friend-hosted/public-hosted table filtering is not connected yet.
- Final vault/scoring is still placeholder.
- Visual assets are mostly prototype geometry and UI.

## Next Development Targets

Likely next steps:

- real two-player lock-in flow
- proper turn/phase timing
- stronger enemy intents
- more tile events
- better room rewards
- final vault scoring
- hosted table server structure
- DataStore profile saving
- polish pass for table visuals and card art


### v0.4.1 — Reliable Table Movement

- Replaced fragile movement clicking with camera raycast table input
- Click/tap glowing tiles directly on the rendered table
- Movement works with mouse and touch
- Step helps highlight movement, but direct reachable-tile clicks work too
- Doors are selected by clicking glowing rendered table doors


### v0.5.0 — Challenge Adventure Run

- 15-room standard run with secret/special discoveries extending runs up to 18 rooms
- 40-room themed room pool
- Progressive difficulty weighting so later rooms become harder and more dangerous
- One action per turn
- Step is required before movement
- Simulated partner wait/resolution for solo testing
- Fixed top-down table camera for players and spectators
- Larger table hit areas for movement
- Door route voting UI with split-vote wheel animation
- Room-specific search and scheme outcome tables
- More dangerous enemies, traps, counterattacks, and threat pressure


### v0.5.1 — Route Roll and Map Polish

- Route disagreement resolver is now Route Roll
- Route Roll appears only for a new split vote
- 50/50 route wheel uses blue/gold player color coding
- Join/Spectate prompt trigger blocks are invisible
- Table polish adds trim, inset lines, candles, coin props, crates, a mini chest, and arch silhouettes
- Map polish adds walkway detail, floor accents, and small lamp posts


### v0.5.2 — Daily Colors, Teammate Purple, and Silent Sound Hooks

- Daily task color tiers cleaned up for readability
- Hard/yellow Daily tier changed to red
- Claim/reward buttons use safer dark backgrounds and readable text
- Teammate identity color changed from gold to purple
- Route Roll uses blue vs purple
- Gold is kept for coins/treasure instead of teammate identity
- Invalid placeholder sounds removed
- Room/event sound hooks are silent by default until curated Roblox Sound assets are added


### v0.5.3 — Hide Join Prompts During Sessions

- Join/Spectate ProximityPrompts are hidden locally while actively playing or spectating Dungeon Doors
- Prompts return when no active Dungeon Doors table session is being rendered
- Prevents “Press E” join/spectate prompts from appearing over an active game view


### v0.5.4 — Room Action Limits, Enemy Turns, and Tile Detail

- Search is limited to once per room for the whole team
- Scheme is limited to once per room for the whole team
- Search/Scheme limits reset in each new room
- Spent Search/Scheme cards are visually marked and do not burn a turn if clicked
- Surviving enemies now get a separate Enemy Turn scene instead of instant counterattacks
- Tile highlights are visually smaller while the invisible click target stays forgiving
- Room tiles get simple cube/rectangle decor for treasure, traps, discoveries, exits, starts, fog, and clutter


### v0.5.5 — Unique Room Layouts

- Room tiles now carry layout metadata for different simple shapes
- Tiles can be square, wide, tall, thin, split, alcove, entry, gate, or L-shaped
- Connected simple rectangles create more varied room silhouettes
- Visible highlights match the room shape more closely
- Invisible click pads stay forgiving without creating giant visible overlays
- Decorations move to edge/corner zones so P1/P2 tokens do not clip through them
- Clutter count, position, rotation, and size vary per tile


### v0.5.6 — Stable Readable Cards and Door Choice Flow

- Action cards use a stable outer slot so hover scaling does not move/reflow card text
- Hover no longer rotates or shifts labels
- Card text is larger and more readable
- Choice buttons are larger with better label fit
- Exit reached no longer triggers an event popup card
- Door/route options are now the event equivalent when an exit is reached


### v0.5.7 — Delayed Route Roll Resolution

- Split route votes now pause on the current room during the wheel animation
- Winning room/map loads only after the Route Roll finishes
- Route choice UI hides while Route Roll is active
- Route Roll text spacing adjusted so labels do not overlap the pie wheel


### v0.5.8 — Monster Run Away Movement Rule

- If the player is standing on a live enemy tile, Step becomes Run Away behavior
- While a monster is present, movement only allows already-revealed neighboring tiles
- Unknown/undiscovered tiles cannot be entered while a monster is on the current tile
- The rule is enforced server-side
- No-escape situations do not burn the turn


### v0.5.9 — Orthogonal Themed Room Layouts

- Tile and prop rotations snap to 0/90/180/270 degrees
- Start and Exit tiles use normal room layout language instead of special entry/exit styles
- Final boss vault is the only exit-style exception
- Room layouts are theme-aware instead of arbitrary angled clutter
- Added simple orthogonal corridors between connected revealed/clickable rooms
- Props vary by room theme while staying cube/rectangle based


### v0.6.0 — Correct Connected Room Movement

- Room movement is rebuilt from actual orthogonal grid adjacency
- Diagonal-looking rooms are no longer treated as connected
- Middle rooms now correctly connect up/down/left/right when visually adjacent
- Every room layout is normalized into a fluent connected dungeon grid before movement is calculated
- Corridor/floor chunks use theme-fit colors and smoother materials instead of ugly gray stone slabs


### v0.6.1 — Theme Consistent Props and Visible Corridor Previews

- Props and floor chunks are tinted toward the active room theme
- Random gray/blue stone-looking chunks are reduced
- Corridors are now partially visible to undiscovered connected rooms
- Revealed/clickable corridors stay stronger while undiscovered previews stay softer
- Movement logic from v0.6.0 is unchanged


### v0.6.2 — Text, Color, Room Spacing, and Solid Hallways

- Room labels are smaller/staggered to reduce overlap
- Player labels are smaller/higher so they do not cover room names as much
- Removed harsh pale yellow/off-white room tile color
- Tile colors are more tightly tied to the active room theme
- Room tile max sizes are clamped smaller
- Extra L/alcove/split pieces stay inside their own tile lane better
- Room spacing increased slightly to reduce clipping between neighboring rooms
- Route choice panel moved lower to avoid covering active map text
- Real connected hallways now show solid at 0 transparency, including to undiscovered visible rooms


### v0.6.3 — Inset Room Texture

- Restores the layered room-within-room look inside tiles
- Adds a slightly darker inset panel inside each room for better depth and texture
- Keeps the current spacing, hallway, and movement behavior from v0.6.2


### v0.6.4 — Ticker and Card Hover Polish

- Turn/status ticker moved higher so it does not overlap the action cards
- Action cards are grouped closer together
- Hover growth is stronger
- Hover scaling applies to the whole card including icon, body text, and tag
- Hovered card rises above neighbors visually without reflowing the hand


### v0.8.1 — Rollback to Board Figure Direction

v0.8.0 was rejected because full-avatar room exploration ruined the tabletop room detail.

This build rolls back to the good v0.6.4 tabletop-room base and locks the new direction:
- keep the miniature tabletop room/tile world
- do not use full-size avatar walking inside rooms
- WASD is for the miniature board figure, not the real avatar
- keep top-down/table camera feel
- future puzzles should be miniature physical board objects:
  - levers
  - chests
  - bridges
  - locked gates
  - pressure plates
  - shrines
  - cracked walls
  - web cocoons
- cards/hand UI still need a better replacement later, but the board-room world stays


### v0.8.2 — UI Stability Lock

Hard UI cleanup pass:
- Rebuilt action card rendering into a stable padded panel.
- Text no longer animates size/visibility during hover.
- Hover only scales the whole card container.
- Cards/buttons get fixed safe slots so they do not reflow into each other.
- Status/ticker text gets a dedicated safe zone with padding.
- Global text/button safety pass forces padding, wrapping, and minimum heights.
- Route/choice buttons are enlarged and moved away from map text.
- This pass intentionally avoids gameplay changes.


### v0.8.3 — Board Interaction + UI Reframe

- WASD now sends real board movement through TableClick.
- E is now context interact:
  - fights live monster on current tile
  - uses Interact if the tile has a real object
  - otherwise searches current tile if Search is available
- Search is once per tile and shared by the team.
- Scheme is hidden/removed as a generic always-available action.
- Interact only appears when the current tile has a real use.
- Doors/route choices are locked while any revealed monster is alive.
- Action UI is reframed into a shorter command bar, not tall tiny cards.


### v0.8.4 — Client Render Hotfix

- Fixes client crash: `renderLayout()` was missing.
- Fixes next crash: `updateTableCamera()` was missing.
- Adds `cameraViewport()` helper used by the command bar.
- Makes `renderActions()` default to `state.fakeState` if called without an argument.
- `renderAll()` now passes `state.fakeState` into the command bar renderer.


### v0.8.5 — Command Bar Compatibility Hotfix

- Fixes command bar crash at `renderActions`: `clearChildren()` was undefined.
- Adds `clearChildren()` compatibility alias to existing `clear()`.
- Adds `corner()` compatibility alias to existing `round()`.
- Makes `stroke()` accept both old and accidental new argument order.
- Adds defensive nil guard on command submit.


### v0.8.6 — Luau Scope RenderActions Hotfix

- Fixes `renderActions()` crash at line 2332.
- Root cause: `cameraViewport()` was a local function declared later in the file, so Luau treated it as nil from inside `renderActions()`.
- `renderActions()` now uses the earlier existing `viewport()` helper directly.
- Added defensive remote guards for E/context actions.
