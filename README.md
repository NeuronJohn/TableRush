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
